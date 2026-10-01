# MANTIS dashboard

Live dashboard for the MANTIS machine-inspection device (Arduino Nano 33 BLE Sense).
It shows vibration severity per ISO 10816 (zones A–D), the dominant frequency and the spectrum,
plus surface and internal temperature, humidity, pressure and sound level. The data arrives over
Bluetooth LE, or over USB on a computer.

**Open it:** https://sl11k.github.io/mantis/

| Device | How |
|---|---|
| Android | Chrome → **اتصال بلوتوث / Connect Bluetooth** → pick **MANTIS** |
| Windows / Mac / Linux | Chrome or Edge, same as above (USB also works) |
| iPhone / iPad | Safari has no Web Bluetooth, so open the link in the **Bluefy** browser (App Store) |

- **Install like an app:** browser menu → *Add to Home screen*. After the first visit it opens offline too.
- **No device at hand?** Press **عرض تجريبي / Demo** to see the dashboard with simulated data.
- **Run locally** (USB development): `node serve.js`, then open http://localhost:8765, or double-click `MANTIS.bat` on Windows.

Single static page, no build step and no dependencies. Arabic (RTL) by default, with English and dark mode.
