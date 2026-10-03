# MANTIS dashboard

Inspection app for the MANTIS machine-inspection device (Arduino Nano 33 BLE Sense).
It shows vibration severity per ISO 10816 (zones A–D), the dominant frequency and the spectrum,
plus surface and internal temperature, humidity, pressure and sound level. The data arrives over
Bluetooth LE, or over USB on a computer.

Four sections (bottom bar on a phone, tabs on a computer):

| Section | What it does |
|---|---|
| **مباشر / Live** | Machine condition, the live sensor tiles, and **Record measurement**: pick the machine, hold the device on it, and a 10/15/30 s steady average is saved to that machine's log |
| **التحليل / Analysis** | Spectrum with 1×/2×/3× running-speed and 2× mains markers, rule-based fault hints (unbalance, misalignment, looseness, electrical, bearings), and the velocity trend |
| **المعدات / Machines** | Machine list sorted worst first, today's route progress, per-machine history against its baseline (first measurement, or any one you pick), PDF report and share |
| **الجهاز / Device** | Connection, device info, alerts, settings (language, theme, measurement length, 50/60 Hz mains, keep screen on, vibrate/sound alerts) and data backup |

Measurements stay in the browser on that phone or computer. Use **Device → Backup** now and then;
**Restore** merges a backup back in. Reports open the print dialog: choose *Save as PDF* to keep or send one.

**Open it:** https://sl11k.github.io/mantis/

| Device | How |
|---|---|
| Android | Chrome → **اتصال بلوتوث / Connect Bluetooth** → pick **MANTIS** |
| Windows / Mac / Linux | Chrome or Edge, same as above (USB also works) |
| iPhone / iPad | Safari has no Web Bluetooth, so open the link in the **Bluefy** browser (App Store) |

- **Install like an app:** browser menu → *Add to Home screen*. After the first visit it opens offline too.
- **No device at hand?** Press **عرض تجريبي / Demo** to see the dashboard with simulated data (demo measurements are tagged as such).
- **Run locally** (USB development): `node serve.js`, then open http://localhost:8765, or double-click `MANTIS.bat` on Windows.

Single static page, no build step and no dependencies. Arabic (RTL) by default, with English and dark mode.
