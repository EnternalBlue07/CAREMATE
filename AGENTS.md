# CAREMATE — Autonomous Loop Engineering & Quality Governance

This document establishes the project rules, verification boundaries, and autonomous cycle controls for CAREMATE.

---

## 1. Project Overview & Architecture
* **Target Repository**: `https://github.com/EnternalBlue07/CAREMATE.git` (`main` branch)
* **Mobile / Companion App**: Flutter / Dart (`caremate_app/`)
* **Physical Hardware Controller**: ESP32 Firmware (`firmware/caremate_esp32_firmware.ino`)
* **Design & Clinical Specifications**: [`DESIGN.md`](./DESIGN.md) & [`PRODUCT.md`](./PRODUCT.md)

---

## 2. Strict Medication Safety Rules (Non-Negotiable)
1. **Never Confuse Software with Physical Confirmation**:
   - `COMMAND_SENT`: Transmitted over BLE.
   - `DISPENSE_CONFIRMED`: Strictly reserved for verified TCRT5000 optical drop pulses.
   - `ACKNOWLEDGED`: Patient or caregiver confirmation at the tray.
   - **Ingestion**: An app button tap is never claimed as proof of bodily drug intake.
2. **Duplicate-Dose Prevention**:
   - Block identical medication drops if another dose is in-flight or if a dose was dispensed within the last 45 minutes.
3. **No Hallucinated Telemetry or Clinical Data**:
   - Demo profiles (e.g. `Ramesh Sharma`) and simulated GATT readings must be explicitly labeled `Simulated Profile` / `Demo Record`.
4. **Fail-Safe Timeout**:
   - Communication losses or BLE command timeouts transition to `DoseStatus.unknown`.
   - Never retry a dispense automatically without manual human inspection of the tray.

---

## 3. Autonomous Quality Gates
Before any commit is considered valid for publication, it must pass the triple-check quality gate:
1. `flutter test` — 100% automated tests passing.
2. `flutter analyze` — 0 errors, 0 warnings, 0 lints.
3. `flutter build apk --debug` — clean compile verification.

---

## 4. Loop Engineering Workflow
```
[ Inspect & Audit ]
       │
       ▼
[ Identify Defect / Improvement ]
       │
       ▼
[ Surgical Implementation ]
       │
       ▼
[ Add Regression Tests ]
       │
       ▼
[ Quality Gate: flutter test + analyze ]
       │
       ▼
[ Git Commit & Push to main ]
```

*Maximum Iterations per Session*: 5 bounded cycles. If any quality gate fails, the loop halts immediately and requests human review.
