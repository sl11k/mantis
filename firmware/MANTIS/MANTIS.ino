// ============================================================================
//  MANTIS - Multimodal Autonomous Non-Invasive Technical Inspection System
//  Firmware for Arduino Nano 33 BLE Sense Rev1 (nRF52840)            v1.1.0
// ----------------------------------------------------------------------------
//  Every analysis window (1024 accelerometer samples, ~1.08 s) the device
//  measures and publishes:
//    vibration  LSM9DS1 accelerometer @ 952 Hz, 1024-point FFT per axis:
//               velocity RMS 10-475 Hz (mm/s) + ISO 10816 zone, acceleration
//               RMS / peak, dominant frequency, 64-band velocity spectrum
//    acoustic   MP34DT05 PDM microphone, A-weighted sound level dB(A) (approx.)
//    internal   HTS221 temperature / humidity, LPS22HB pressure
//    surface    MLX90614 IR thermometer on A4/A5 (optional, hot-plug)
//    contact    piezo disc on an analog pin (optional, see PIEZO_ENABLED)
//
//  Outputs
//    BLE  service 4d414e54-4953-4e53-5045-435400000000 (see BLE PROTOCOL)
//    USB  one JSON line per window @ 115200 baud; lines starting with '#'
//         are human-readable. Commands: "C1".."C4" (ISO class), "I" (identify),
//         "M" (dump 4096 raw microphone samples as "#R" lines, for diagnostics)
//  Libraries: ArduinoBLE (Library Manager); PDM and Wire come with the core.
//
//  BLE PROTOCOL (all little-endian; 0x7FFF / 0xFFFF = not available)
//   ...0001 vibration    read/notify 20 B
//      u16 seq | u16 vel_rms 0.01 mm/s | u16 acc_rms mg | u16 acc_peak mg |
//      u16 dom_freq 0.1 Hz | u16 dom_vel 0.01 mm/s | u16 piezo_peak mV |
//      u16 piezo_rms mV | u16 piezo_impacts | u8 zone 1-4 = A-D (0 = none) |
//      u8 flags (bit0 FIFO overrun, bits1-2 axis 0=X 1=Y 2=Z)
//   ...0002 environment  read/notify 20 B
//      u16 seq | i16 temp 0.01 C | u16 humidity 0.01 % | u16 pressure 0.1 hPa |
//      i16 ir_object 0.01 C | i16 ir_ambient 0.01 C | i16 sound 0.1 dB(A) |
//      u32 uptime s | u8 sensors (bit0 HTS221, 1 LPS22HB, 2 IMU, 3 MIC,
//      4 MLX90614, 5 PIEZO) | u8 iso_class 1-4
//   ...0003 spectrum     notify, 4 chunks x 20 B per window
//      u8 seq & 0xFF | u8 chunk 0-3 | u16 fs 0.1 Hz | 16 x u8 band
//      band b (0-63) = velocity RMS over FFT bins K0 + 7b .. K0 + 7b + 6,
//      encoded 40 * log10(v / 0.001 mm/s), 0 = below 1 um/s
//   ...0004 control      write: [1, class 1-4] ISO 10816 class, [2] identify
//   ...0005 info         read: "fw=..;board=..;n=1024;k0=11;bw=7"
// ============================================================================

#include <ArduinoBLE.h>
#include <PDM.h>
#include <Wire.h>
#include <mbed.h>
using namespace std::chrono_literals;

#define FW_VERSION "1.1.0"

// ---------------------------------------------------------------- settings --
const bool  PIEZO_ENABLED   = false;  // set to true once the piezo disc is wired
const int   PIEZO_PIN       = A0;
const float PIEZO_IMPACT_MV = 300;    // impact = rising edge above this level
uint8_t isoClass = 2;                 // ISO 10816 machine class 1-4

// ISO 10816-1 zone limits A/B, B/C, C/D in mm/s RMS
const float ISO_LIMITS[4][3] = {
  {0.71f, 1.8f, 4.5f},    // I   small machines (< 15 kW)
  {1.12f, 2.8f, 7.1f},    // II  medium machines (15-75 kW)
  {1.8f,  4.5f, 11.2f},   // III large machines, rigid foundation
  {2.8f,  7.1f, 18.0f},   // IV  large machines, flexible foundation
};

// ------------------------------------------------------------- I2C devices --
const uint8_t ADDR_LPS22HB  = 0x5C;   // internal bus (Wire1)
const uint8_t ADDR_HTS221   = 0x5F;
const uint8_t ADDR_LSM9DS1  = 0x6B;
const uint8_t ADDR_MLX90614 = 0x5A;   // external bus (Wire, A4/A5)

bool hasHTS = false, hasLPS = false, hasIMU = false, hasMic = false, hasMLX = false;
bool bleOk = false;

// ------------------------------------------------------- vibration analysis --
const int   FFT_N   = 1024;           // samples per window (power of 2)
const int   K0      = 11;             // first FFT bin used (~10 Hz)
const int   BANDS   = 64;
const int   BAND_W  = 7;              // FFT bins per spectrum band
const float ACC_LSB = 0.122e-3f;      // g per LSB at +/-4 g
const float G0      = 9.80665f;

float bufX[FFT_N], bufY[FFT_N], bufZ[FFT_N];
int   nSamples = 0;
uint32_t overrunCount = 0;

// The accelerometer FIFO (32 samples = 34 ms) is drained by its own thread
// into this ring (1.1 s), so BLE writes or analysis in loop() never lose data
rtos::Thread imuThread(osPriorityAboveNormal, 4096);
rtos::Mutex  wire1Lock;               // Wire1 is shared by the IMU thread and loop()
const int RING_N = 1024;
int16_t ring[RING_N][3];
volatile uint32_t ringHead = 0, ringTail = 0;
volatile bool imuOverrun = false;
float fftRe[FFT_N], fftIm[FFT_N], hann[FFT_N];
float twCos[FFT_N / 2], twSin[FFT_N / 2];
float msv[FFT_N / 2], bestMsv[FFT_N / 2];  // velocity mean square per bin, (mm/s)^2

volatile uint32_t fsSamples = 0, fsStartMs = 0;
float fs = 952.0f;                    // measured accelerometer sample rate

struct {
  float velRms = NAN, accRms = NAN, accPeak = NAN, domFreq = NAN, domVel = NAN;
  uint8_t zone = 0, axis = 0;
  bool overrun = false;
  uint8_t bands[BANDS] = {0};
} vib;

// ------------------------------------------------------------ environment --
struct {
  float temp = NAN, rh = NAN, hPa = NAN, irObj = NAN, irAmb = NAN, sound = NAN;
} env;

float htsT0, htsT1, htsH0, htsH1;
int16_t htsT0out, htsT1out, htsH0out, htsH1out;
uint8_t mlxFails = 0;
uint32_t lastMlxProbe = 0;

// ------------------------------------------------------------- microphone --
// Sound level in dB(A). The MP34DT05 output is dominated by sub-60 Hz drift,
// so it goes through an A-weighting filter (two biquads, bilinear at 16 kHz;
// the 12.2 kHz poles are above Nyquist and omitted) before the RMS.
// Calibration from datasheets: MP34DT05 -26 dBFS @ 94 dB SPL, nRF52840 PDM
// module gain +3.2 dB ("2500 RMS"), Arduino PDM default gain setting -10 dB:
// 94 dB SPL -> -32.35 dBFS, so dB SPL = dBFS + 126.35. Typical accuracy of an
// uncalibrated MEMS mic is +/-3 dB; MIC_CAL_DB trims it against a reference meter.
const float MIC_FS     = 16000.0f;
const float MIC_REF_DB = 126.35f;
const float MIC_CAL_DB = 0.0f;
short micBuf[256];
volatile float micSumSq = 0;
volatile uint32_t micCount = 0;
uint32_t micSettle = 8000;            // skip the filter start-up (0.5 s)
struct Biquad { float b0, b1, b2, a1, a2, z1, z2; };
Biquad aw[2];
float awGain = 1;

// raw capture for diagnostics (USB command "M"): 4096 samples = 256 ms
const int RAW_N = 4096;
int16_t rawMic[RAW_N];
volatile int rawFill = -1;            // -1 idle, 0..RAW_N-1 filling, RAW_N ready

// ------------------------------------------------------------------ piezo --
float pzPeak = 0, pzSumSq = 0;
uint32_t pzCount = 0, pzImpacts = 0;
bool pzArmed = true;
float pzPeakOut = NAN, pzRmsOut = NAN;
uint32_t pzImpactsOut = 0;

// -------------------------------------------------------------------- BLE --
#define MANTIS_UUID(x) "4d414e54-4953-4e53-5045-43540000" x
BLEService        mantisService(MANTIS_UUID("0000"));
BLECharacteristic vibChar (MANTIS_UUID("0001"), BLERead | BLENotify, 20, true);
BLECharacteristic envChar (MANTIS_UUID("0002"), BLERead | BLENotify, 20, true);
BLECharacteristic specChar(MANTIS_UUID("0003"), BLENotify, 20, true);
BLECharacteristic ctrlChar(MANTIS_UUID("0004"), BLEWrite | BLEWriteWithoutResponse, 4, false);
BLEStringCharacteristic infoChar(MANTIS_UUID("0005"), BLERead, 96);

// Notifications go out one per loop pass: a write can wait for a free
// controller buffer, and a burst of six would stall the accelerometer FIFO
uint8_t txVib[20], txEnv[20], txSpec[4][20];
int8_t  txNext = -1;                  // -1 idle, 0 vib, 1 env, 2-5 spectrum chunks

uint16_t seq = 0;
uint32_t identifyUntil = 0;
uint32_t procMs = 0;

// ============================================================ I2C helpers ===
bool probe(TwoWire &bus, uint8_t addr) {
  bus.beginTransmission(addr);
  return bus.endTransmission() == 0;
}

bool writeReg(TwoWire &bus, uint8_t addr, uint8_t reg, uint8_t val) {
  bus.beginTransmission(addr);
  bus.write(reg);
  bus.write(val);
  return bus.endTransmission() == 0;
}

bool readRegs(TwoWire &bus, uint8_t addr, uint8_t reg, uint8_t *buf, uint8_t n) {
  bus.beginTransmission(addr);
  bus.write(reg);
  if (bus.endTransmission(false) != 0) return false;
  if (bus.requestFrom(addr, n) != n) return false;
  for (uint8_t i = 0; i < n; i++) buf[i] = bus.read();
  return true;
}

// ================================================================ sensors ===
bool initIMU() {
  if (!writeReg(Wire1, ADDR_LSM9DS1, 0x22, 0x05)) return false;  // CTRL_REG8: soft reset
  delay(10);
  writeReg(Wire1, ADDR_LSM9DS1, 0x22, 0x44);  // block data update + auto-increment
  writeReg(Wire1, ADDR_LSM9DS1, 0x10, 0x00);  // gyro off -> accelerometer-only FIFO
  writeReg(Wire1, ADDR_LSM9DS1, 0x20, 0xD0);  // CTRL_REG6_XL: 952 Hz, +/-4 g, BW 408 Hz
  writeReg(Wire1, ADDR_LSM9DS1, 0x23, 0x02);  // CTRL_REG9: FIFO enable
  writeReg(Wire1, ADDR_LSM9DS1, 0x2E, 0x00);  // FIFO bypass (clears it)
  return writeReg(Wire1, ADDR_LSM9DS1, 0x2E, 0xC0);  // FIFO continuous mode
}

// IMU thread: drain the FIFO every 10 ms in one burst. In FIFO mode the
// register address wraps from OUT_Z_H_XL (0x2D) back to OUT_X_L_XL (0x28),
// so n samples are read as one 6*n byte transfer.
void imuTask() {
  static uint8_t b[32 * 6];
  while (true) {
    wire1Lock.lock();
    uint8_t src = 0;
    int n = 0;
    if (readRegs(Wire1, ADDR_LSM9DS1, 0x2F, &src, 1)) {
      n = src & 0x3F;
      if (n > 0 && !readRegs(Wire1, ADDR_LSM9DS1, 0x28, b, n * 6)) n = 0;
    }
    wire1Lock.unlock();
    if (src & 0x40) imuOverrun = true;
    for (int i = 0; i < n; i++) {
      uint32_t next = (ringHead + 1) % RING_N;
      if (next == ringTail) {
        imuOverrun = true;
        break;
      }
      const uint8_t *s = b + i * 6;
      ring[ringHead][0] = (int16_t)(s[1] << 8 | s[0]);
      ring[ringHead][1] = (int16_t)(s[3] << 8 | s[2]);
      ring[ringHead][2] = (int16_t)(s[5] << 8 | s[4]);
      ringHead = next;
    }
    if (n > 0) {  // sample-rate clock starts at the first batch
      if (fsStartMs == 0) fsStartMs = millis();
      else fsSamples += n;
    }
    rtos::ThisThread::sleep_for(10ms);
  }
}

// loop(): move samples from the ring into the analysis window
void pollIMU() {
  while (nSamples < FFT_N && ringTail != ringHead) {
    bufX[nSamples] = ring[ringTail][0] * ACC_LSB;
    bufY[nSamples] = ring[ringTail][1] * ACC_LSB;
    bufZ[nSamples] = ring[ringTail][2] * ACC_LSB;
    nSamples++;
    ringTail = (ringTail + 1) % RING_N;
  }
}

bool initHTS221() {
  uint8_t c[16];
  if (!readRegs(Wire1, ADDR_HTS221, 0x30 | 0x80, c, 16)) return false;  // 0x80 = auto-increment
  htsH0 = c[0] / 2.0f;
  htsH1 = c[1] / 2.0f;
  htsT0 = (((uint16_t)(c[5] & 0x03) << 8) | c[2]) / 8.0f;
  htsT1 = (((uint16_t)(c[5] & 0x0C) << 6) | c[3]) / 8.0f;
  htsH0out = (int16_t)(c[7]  << 8 | c[6]);
  htsH1out = (int16_t)(c[11] << 8 | c[10]);
  htsT0out = (int16_t)(c[13] << 8 | c[12]);
  htsT1out = (int16_t)(c[15] << 8 | c[14]);
  return writeReg(Wire1, ADDR_HTS221, 0x20, 0x85);  // power on, BDU, 1 Hz continuous
}

void readHTS221() {
  uint8_t b[4];
  if (!readRegs(Wire1, ADDR_HTS221, 0x28 | 0x80, b, 4)) return;
  int16_t hOut = (int16_t)(b[1] << 8 | b[0]);
  int16_t tOut = (int16_t)(b[3] << 8 | b[2]);
  env.temp = htsT0 + (tOut - htsT0out) * (htsT1 - htsT0) / (float)(htsT1out - htsT0out);
  env.rh = constrain(htsH0 + (hOut - htsH0out) * (htsH1 - htsH0) / (float)(htsH1out - htsH0out), 0.0f, 100.0f);
}

bool initLPS22HB() {
  if (!writeReg(Wire1, ADDR_LPS22HB, 0x11, 0x10)) return false;  // CTRL_REG2: auto-increment
  return writeReg(Wire1, ADDR_LPS22HB, 0x10, 0x12);              // CTRL_REG1: 1 Hz, BDU
}

void readLPS22HB() {
  uint8_t b[3];
  if (!readRegs(Wire1, ADDR_LPS22HB, 0x28, b, 3)) return;
  env.hPa = (((int32_t)b[2] << 16) | ((int32_t)b[1] << 8) | b[0]) / 4096.0f;
}

// MLX90614 RAM register (0x06 = ambient, 0x07 = object)
bool readMLX(uint8_t reg, float &tempC) {
  uint8_t b[3];
  if (!readRegs(Wire, ADDR_MLX90614, reg, b, 3)) return false;
  uint16_t raw = b[0] | (uint16_t)b[1] << 8;  // b[2] = PEC
  if (raw & 0x8000) return false;             // error flag
  tempC = raw * 0.02f - 273.15f;
  return true;
}

void readMLX90614() {
  if (!hasMLX) {  // hot-plug: look for it every 5 s
    if (millis() - lastMlxProbe < 5000) return;
    lastMlxProbe = millis();
    if (!probe(Wire, ADDR_MLX90614)) return;
    hasMLX = true;
    mlxFails = 0;
  }
  float o, a;
  if (readMLX(0x07, o) && readMLX(0x06, a)) {
    env.irObj = o;
    env.irAmb = a;
    mlxFails = 0;
  } else if (++mlxFails >= 3) {
    hasMLX = false;
    env.irObj = env.irAmb = NAN;
  }
}

// Analog high-pass section s^2 / (s^2 + a1 s + a0) -> digital biquad (bilinear)
// (computed in double once: the 20 Hz poles sit at r = 0.992, close to z = 1)
Biquad bilinearHP(double a1, double a0) {
  const double K = 2.0 * MIC_FS, d = K * K + a1 * K + a0;
  return { (float)(K * K / d), (float)(-2 * K * K / d), (float)(K * K / d),
           (float)((2 * a0 - 2 * K * K) / d), (float)((K * K - a1 * K + a0) / d), 0, 0 };
}

float biquadGainAt(const Biquad &q, float f) {
  float w = 2 * PI * f / MIC_FS, c1 = cosf(w), s1 = sinf(w), c2 = cosf(2 * w), s2 = sinf(2 * w);
  float nr = q.b0 + q.b1 * c1 + q.b2 * c2, ni = -(q.b1 * s1 + q.b2 * s2);
  float dr = 1 + q.a1 * c1 + q.a2 * c2, di = -(q.a1 * s1 + q.a2 * s2);
  return sqrtf((nr * nr + ni * ni) / (dr * dr + di * di));
}

void initAWeighting() {
  const double w1 = 2 * PI * 20.598997, w2 = 2 * PI * 107.65265, w3 = 2 * PI * 737.86223;
  aw[0] = bilinearHP(2 * w1, w1 * w1);
  aw[1] = bilinearHP(w2 + w3, w2 * w3);
  awGain = 1 / (biquadGainAt(aw[0], 1000) * biquadGainAt(aw[1], 1000));  // 0 dB at 1 kHz
}

inline float biquadRun(Biquad &q, float x) {  // transposed direct form II
  float y = q.b0 * x + q.z1;
  q.z1 = q.b1 * x - q.a1 * y + q.z2;
  q.z2 = q.b2 * x - q.a2 * y;
  return y;
}

// PDM callback (interrupt context): A-weight every sample, accumulate energy
void onPDMdata() {
  int bytes = PDM.available();
  if (bytes > (int)sizeof(micBuf)) bytes = sizeof(micBuf);
  PDM.read(micBuf, bytes);
  int n = bytes / 2;
  if (n <= 0) return;
  if (rawFill >= 0 && rawFill < RAW_N) {
    int k = min(n, RAW_N - rawFill);
    memcpy(rawMic + rawFill, micBuf, k * sizeof(int16_t));
    rawFill += k;
  }
  float s = 0;
  for (int i = 0; i < n; i++) {
    float y = biquadRun(aw[1], biquadRun(aw[0], micBuf[i])) * awGain;
    s += y * y;
  }
  if (micSettle > 0) {
    micSettle = micSettle > (uint32_t)n ? micSettle - n : 0;
    return;
  }
  micSumSq += s;
  micCount += n;
}

void readMic() {
  noInterrupts();
  float s = micSumSq;
  uint32_t n = micCount;
  micSumSq = 0;
  micCount = 0;
  interrupts();
  env.sound = (n > 0 && s > 0) ? 10.0f * log10f(s / n / (32768.0f * 32768.0f)) + MIC_REF_DB + MIC_CAL_DB : NAN;
}

void pollPiezo() {
  if (!PIEZO_ENABLED) return;
  float mv = analogRead(PIEZO_PIN) * (3300.0f / 4095.0f);
  if (mv > pzPeak) pzPeak = mv;
  pzSumSq += mv * mv;
  pzCount++;
  if (pzArmed && mv > PIEZO_IMPACT_MV) {
    pzImpacts++;
    pzArmed = false;
  } else if (mv < PIEZO_IMPACT_MV / 2) {
    pzArmed = true;
  }
}

void takePiezo() {
  if (!PIEZO_ENABLED) return;
  pzPeakOut = pzPeak;
  pzRmsOut = pzCount ? sqrtf(pzSumSq / pzCount) : NAN;
  pzImpactsOut = pzImpacts;
  pzPeak = pzSumSq = 0;
  pzCount = pzImpacts = 0;
}

// =============================================================== analysis ===
void initTables() {
  for (int i = 0; i < FFT_N / 2; i++) {
    twCos[i] = cosf(2 * PI * i / FFT_N);
    twSin[i] = -sinf(2 * PI * i / FFT_N);
  }
  for (int i = 0; i < FFT_N; i++) hann[i] = 0.5f - 0.5f * cosf(2 * PI * i / FFT_N);  // periodic Hann
}

// In-place iterative radix-2 FFT
void fft(float *re, float *im) {
  for (int i = 1, j = 0; i < FFT_N; i++) {
    int bit = FFT_N >> 1;
    for (; j & bit; bit >>= 1) j ^= bit;
    j ^= bit;
    if (i < j) {
      float t = re[i]; re[i] = re[j]; re[j] = t;
      t = im[i]; im[i] = im[j]; im[j] = t;
    }
  }
  for (int len = 2; len <= FFT_N; len <<= 1) {
    int half = len >> 1, step = FFT_N / len;
    for (int i = 0; i < FFT_N; i += len) {
      for (int k = 0; k < half; k++) {
        float wr = twCos[k * step], wi = twSin[k * step];
        int a = i + k, b = a + half;
        float tr = re[b] * wr - im[b] * wi;
        float ti = re[b] * wi + im[b] * wr;
        re[b] = re[a] - tr;
        im[b] = im[a] - ti;
        re[a] += tr;
        im[a] += ti;
      }
    }
  }
}

// Velocity mean square per bin for one axis; returns velocity RMS in mm/s
float analyzeAxis(const float *buf, float mean, float *out) {
  for (int i = 0; i < FFT_N; i++) {
    fftRe[i] = (buf[i] - mean) * G0 * hann[i];  // m/s^2
    fftIm[i] = 0;
  }
  fft(fftRe, fftIm);
  // one-sided mean square per bin, Hann window: sum(w^2) = 3N/8
  const float norm = 2.0f / (FFT_N * (3.0f * FFT_N / 8.0f));
  const float df = fs / FFT_N;
  float sum = 0;
  for (int k = 0; k < FFT_N / 2; k++) {
    if (k < K0) {
      out[k] = 0;
      continue;
    }
    float w = 2 * PI * k * df;
    float v = (fftRe[k] * fftRe[k] + fftIm[k] * fftIm[k]) * norm / (w * w) * 1e6f;  // (mm/s)^2
    out[k] = v;
    sum += v;
  }
  return sqrtf(sum);
}

void processVibration() {
  vib.overrun = imuOverrun;
  if (imuOverrun) overrunCount++;
  imuOverrun = false;

  if (fsSamples > 3000) {
    float measured = fsSamples * 1000.0f / (millis() - fsStartMs);
    if (measured > 850 && measured < 1050) fs = measured;
  }

  float *bufs[3] = {bufX, bufY, bufZ};
  float mean[3];
  for (int a = 0; a < 3; a++) {
    float s = 0;
    for (int i = 0; i < FFT_N; i++) s += bufs[a][i];
    mean[a] = s / FFT_N;
  }
  float sumSq = 0, peak2 = 0;
  for (int i = 0; i < FFT_N; i++) {
    float dx = bufX[i] - mean[0], dy = bufY[i] - mean[1], dz = bufZ[i] - mean[2];
    float d2 = dx * dx + dy * dy + dz * dz;
    sumSq += d2;
    if (d2 > peak2) peak2 = d2;
  }
  vib.accRms = sqrtf(sumSq / FFT_N);
  vib.accPeak = sqrtf(peak2);

  // ISO 10816 uses the direction with the highest reading
  float best = -1;
  for (int a = 0; a < 3; a++) {
    float v = analyzeAxis(bufs[a], mean[a], msv);
    if (v > best) {
      best = v;
      vib.axis = a;
      memcpy(bestMsv, msv, sizeof(msv));
    }
  }
  vib.velRms = best;

  // dominant frequency (parabolic interpolation on magnitude)
  int kMax = K0;
  for (int k = K0 + 1; k < FFT_N / 2; k++)
    if (bestMsv[k] > bestMsv[kMax]) kMax = k;
  float sumLobe = 0;
  for (int k = kMax - 2; k <= kMax + 2; k++)
    if (k >= K0 && k < FFT_N / 2) sumLobe += bestMsv[k];
  vib.domVel = sqrtf(sumLobe);
  float delta = 0;
  if (kMax > K0 && kMax < FFT_N / 2 - 1) {
    float m1 = sqrtf(bestMsv[kMax - 1]), m2 = sqrtf(bestMsv[kMax]), m3 = sqrtf(bestMsv[kMax + 1]);
    float den = m1 - 2 * m2 + m3;
    if (den < 0) delta = constrain(0.5f * (m1 - m3) / den, -0.5f, 0.5f);
  }
  vib.domFreq = (kMax + delta) * fs / FFT_N;

  for (int b = 0; b < BANDS; b++) {
    float s = 0;
    for (int k = K0 + b * BAND_W; k < K0 + (b + 1) * BAND_W; k++) s += bestMsv[k];
    float v = sqrtf(s);
    float code = v > 0.001f ? 40.0f * log10f(v / 0.001f) : 0;
    vib.bands[b] = (uint8_t)constrain(code + 0.5f, 0.0f, 255.0f);
  }

  const float *lim = ISO_LIMITS[isoClass - 1];
  vib.zone = vib.velRms < lim[0] ? 1 : vib.velRms < lim[1] ? 2 : vib.velRms < lim[2] ? 3 : 4;
}

void readEnvironment() {
  wire1Lock.lock();
  if (hasHTS) readHTS221();
  if (hasLPS) readLPS22HB();
  wire1Lock.unlock();
  if (hasMic) readMic();
  readMLX90614();
  takePiezo();
}

// ================================================================ outputs ===
uint16_t u16(float v) {
  if (isnan(v)) return 0xFFFF;
  return (uint16_t)constrain(v + 0.5f, 0.0f, 65534.0f);
}

int16_t i16(float v) {
  if (isnan(v)) return 0x7FFF;
  return (int16_t)lroundf(constrain(v, -32767.0f, 32766.0f));
}

void put16(uint8_t *p, uint16_t v) {
  p[0] = v & 0xFF;
  p[1] = v >> 8;
}

uint8_t sensorMask() {
  return hasHTS | hasLPS << 1 | hasIMU << 2 | hasMic << 3 | hasMLX << 4 | PIEZO_ENABLED << 5;
}

void publishBLE() {
  uint8_t *p = txVib;
  put16(p, seq);
  put16(p + 2, u16(vib.velRms * 100));
  put16(p + 4, u16(vib.accRms * 1000));
  put16(p + 6, u16(vib.accPeak * 1000));
  put16(p + 8, u16(vib.domFreq * 10));
  put16(p + 10, u16(vib.domVel * 100));
  put16(p + 12, u16(pzPeakOut));
  put16(p + 14, u16(pzRmsOut));
  put16(p + 16, PIEZO_ENABLED ? (uint16_t)(pzImpactsOut > 65534 ? 65534 : pzImpactsOut) : 0xFFFF);
  p[18] = vib.zone;
  p[19] = vib.overrun | vib.axis << 1;

  uint32_t up = millis() / 1000;
  p = txEnv;
  put16(p, seq);
  put16(p + 2, (uint16_t)i16(env.temp * 100));
  put16(p + 4, u16(env.rh * 100));
  put16(p + 6, u16(env.hPa * 10));
  put16(p + 8, (uint16_t)i16(env.irObj * 100));
  put16(p + 10, (uint16_t)i16(env.irAmb * 100));
  put16(p + 12, (uint16_t)i16(env.sound * 10));
  put16(p + 14, up & 0xFFFF);
  put16(p + 16, up >> 16);
  p[18] = sensorMask();
  p[19] = isoClass;

  for (int c = 0; c < 4; c++) {
    p = txSpec[c];
    p[0] = seq & 0xFF;
    p[1] = c;
    put16(p + 2, u16(fs * 10));
    memcpy(p + 4, vib.bands + c * 16, 16);
  }
  txNext = 0;
}

// Called every loop pass; sends at most one characteristic update
void sendPendingBLE() {
  if (txNext < 0) return;
  if (txNext == 0) vibChar.writeValue(txVib, 20);
  else if (txNext == 1) envChar.writeValue(txEnv, 20);
  else if (BLE.connected()) specChar.writeValue(txSpec[txNext - 2], 20);
  txNext = (txNext < 5 && (txNext < 1 || BLE.connected())) ? txNext + 1 : -1;
}

// The line is built in RAM and sent with one write: many small USB writes
// each wait for a transfer and would stall the accelerometer FIFO.
String json;

void jsonNum(const char *key, float v, int dec) {
  json += ",\"";
  json += key;
  json += "\":";
  if (isnan(v)) json += "null";
  else json += String(v, dec);
}

void publishSerial() {
  if (!Serial) return;
  json = "{\"seq\":";
  json += seq;
  jsonNum("up", millis() / 1000, 0);
  jsonNum("vel", vib.velRms, 3);
  jsonNum("arms", vib.accRms * 1000, 1);
  jsonNum("apk", vib.accPeak * 1000, 1);
  jsonNum("f", vib.domFreq, 1);
  jsonNum("fv", vib.domVel, 3);
  jsonNum("axis", vib.axis, 0);
  jsonNum("zone", vib.zone, 0);
  jsonNum("cls", isoClass, 0);
  jsonNum("t", env.temp, 2);
  jsonNum("rh", env.rh, 1);
  jsonNum("p", env.hPa, 1);
  jsonNum("ir", env.irObj, 2);
  jsonNum("ira", env.irAmb, 2);
  jsonNum("snd", env.sound, 1);
  jsonNum("pzp", pzPeakOut, 0);
  jsonNum("pzr", pzRmsOut, 0);
  jsonNum("pzi", PIEZO_ENABLED ? pzImpactsOut : NAN, 0);
  jsonNum("sens", sensorMask(), 0);
  jsonNum("fs", fs, 1);
  jsonNum("ovr", overrunCount, 0);
  jsonNum("proc", procMs, 0);
  jsonNum("ble", BLE.connected(), 0);
  json += ",\"spec\":[";
  for (int b = 0; b < BANDS; b++) {
    if (b) json += ',';
    json += vib.bands[b];
  }
  json += "]}\r\n";
  Serial.write((const uint8_t *)json.c_str(), json.length());
}

void printBanner() {
  Serial.println();
  Serial.println("# MANTIS fw " FW_VERSION " - Arduino Nano 33 BLE Sense Rev1");
  Serial.print("# sensors: IMU=");
  Serial.print(hasIMU);
  Serial.print(" HTS221=");
  Serial.print(hasHTS);
  Serial.print(" LPS22HB=");
  Serial.print(hasLPS);
  Serial.print(" MIC=");
  Serial.print(hasMic);
  Serial.print(" MLX90614=");
  Serial.print(hasMLX);
  Serial.print(" PIEZO=");
  Serial.println(PIEZO_ENABLED);
  Serial.print("# BLE: ");
  Serial.println(bleOk ? "advertising as MANTIS" : "FAILED to start");
}

// ====================================================== commands and LED ===
void runCommand(uint8_t cmd, uint8_t arg) {
  if (cmd == 1 && arg >= 1 && arg <= 4) isoClass = arg;
  else if (cmd == 2) identifyUntil = millis() + 3000;
}

void onControl(BLEDevice, BLECharacteristic chr) {
  const uint8_t *d = chr.value();
  int n = chr.valueLength();
  if (n >= 1) runCommand(d[0], n >= 2 ? d[1] : 0);
}

void handleSerial() {
  static char line[16];
  static uint8_t len = 0;
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n' || c == '\r') {
      line[len] = 0;
      if ((line[0] == 'C' || line[0] == 'c') && len >= 2) runCommand(1, line[1] - '0');
      else if (line[0] == 'I' || line[0] == 'i') runCommand(2, 0);
      else if ((line[0] == 'M' || line[0] == 'm') && rawFill < 0) rawFill = 0;
      len = 0;
    } else if (len < sizeof(line) - 1) {
      line[len++] = c;
    }
  }
}

void setRGB(bool r, bool g, bool b) {  // RGB LED is active-low
  digitalWrite(LEDR, r ? LOW : HIGH);
  digitalWrite(LEDG, g ? LOW : HIGH);
  digitalWrite(LEDB, b ? LOW : HIGH);
}

// zone colour (blue = no data yet); solid when a phone/PC is connected,
// short blink while advertising; white flashing = identify
void updateLed() {
  uint32_t now = millis();
  if (now < identifyUntil) {
    bool on = (now / 100) % 2;
    setRGB(on, on, on);
    return;
  }
  if (!BLE.connected() && now % 1500 > 150) {
    setRGB(false, false, false);
    return;
  }
  switch (vib.zone) {
    case 1: case 2: setRGB(false, true, false); break;
    case 3:         setRGB(true, true, false); break;
    case 4:         setRGB(true, false, false); break;
    default:        setRGB(false, false, true); break;
  }
}

// ================================================================== main ===
void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  digitalWrite(LED_BUILTIN, LOW);
  pinMode(LEDR, OUTPUT);
  pinMode(LEDG, OUTPUT);
  pinMode(LEDB, OUTPUT);
  setRGB(false, false, true);

  Serial.begin(115200);
  json.reserve(1024);
  analogReadResolution(12);
  Wire.begin();
  Wire1.begin();
  Wire1.setClock(400000);
  initTables();

  hasHTS = probe(Wire1, ADDR_HTS221) && initHTS221();
  hasLPS = probe(Wire1, ADDR_LPS22HB) && initLPS22HB();
  hasIMU = probe(Wire1, ADDR_LSM9DS1) && initIMU();
  hasMLX = probe(Wire, ADDR_MLX90614);
  if (hasIMU) imuThread.start(imuTask);

  initAWeighting();
  PDM.onReceive(onPDMdata);
  hasMic = PDM.begin(1, 16000);

  bleOk = BLE.begin();
  if (bleOk) {
    // name + service UUID in the advertisement itself (3 + 18 + 8 = 29 of 31 bytes):
    // ArduinoBLE otherwise puts the name only in the scan response, which
    // passive scanners never see
    BLEAdvertisingData adv;
    adv.setFlags(BLEFlagsGeneralDiscoverable | BLEFlagsBREDRNotSupported);
    adv.setAdvertisedService(mantisService);
    adv.setLocalName("MANTIS");
    BLE.setAdvertisingData(adv);
    BLE.setLocalName("MANTIS");
    BLE.setDeviceName("MANTIS");
    mantisService.addCharacteristic(vibChar);
    mantisService.addCharacteristic(envChar);
    mantisService.addCharacteristic(specChar);
    mantisService.addCharacteristic(ctrlChar);
    mantisService.addCharacteristic(infoChar);
    BLE.addService(mantisService);
    ctrlChar.setEventHandler(BLEWritten, onControl);
    infoChar.writeValue("fw=" FW_VERSION ";board=Nano 33 BLE Sense Rev1;n=1024;k0=11;bw=7");
    BLE.advertise();
  }
}

void loop() {
  static bool wasConnected = false;
  static uint32_t lastPublish = 0;

  if (bleOk) {
    BLE.poll();
    pollIMU();
    sendPendingBLE();
  }
  pollIMU();
  pollPiezo();
  handleSerial();
  updateLed();

  bool usb = Serial;
  if (usb && !wasConnected) printBanner();
  wasConnected = usb;

  if (rawFill == RAW_N) {  // dump the raw capture, 256 samples per '#R' line
    for (int i = 0; i < RAW_N; i += 256) {
      json = "#R ";
      for (int j = i; j < i + 256; j++) {
        if (j > i) json += ',';
        json += rawMic[j];
      }
      json += "\r\n";
      Serial.write((const uint8_t *)json.c_str(), json.length());
    }
    rawFill = -1;
  }

  // publish once per analysis window (or once a second without an IMU)
  bool windowReady = hasIMU ? nSamples >= FFT_N : millis() - lastPublish >= 1000;
  if (!windowReady) return;

  uint32_t t0 = millis();
  if (hasIMU) {
    processVibration();
    nSamples = 0;
  }
  readEnvironment();
  seq++;
  if (bleOk) publishBLE();
  publishSerial();
  procMs = millis() - t0;
  lastPublish = millis();
}
