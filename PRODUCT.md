# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

1. **Family Caregivers & Healthcare Proxies:** Managing elderly parents or chronic patients remotely or at home. Needs verified medication schedules, adherence analytics, missed-dose alerts, robot error notifications, and honest dispensing records.
2. **Elderly Patients / Individuals with Chronic Conditions:** Need zero-friction, accessible reminders with high-contrast typography, plain-language guidance, and immediate physical reassurance (optical pill delivery confirmation and large one-tap acknowledgment).
3. **Primary Care Clinicians / Prescribing Doctors (Audience):** Reviewing truthful compliance records, validated vitals (blood pressure, heart rate, blood glucose), and drug reconciliation data during appointments.

## Product Purpose

CAREMATE is an advanced home healthcare companion ecosystem combining assistive robotics (ESP32 DevKit V1), intelligent medication management, clinical reference information, and a conversational AI assistant. It bridges the gap between digital scheduling and physical medication consumption, preventing missed doses and double dosing through truthful hardware state verification.

Success means:
- Zero false "medicine delivered" reports: A scheduled dose is distinct from a dispensed dose, and dispensing is never confused with patient ingestion.
- Resilient offline-first operation: All schedules, historical audit logs, and robot commands function seamlessly without cloud dependency.
- High accessibility: Low cognitive load for senior patients with conversational healthcare guidance and emergency clinical triage.

## Positioning

Unlike conventional medication reminder apps that only trigger passive notifications, CAREMATE integrates directly with an assistive physical robot over Bluetooth Low Energy (BLE). It enforces a strict, truthful state machine backed by physical optical IR drop sensors, preventing accidental double dosing and reporting mechanical faults (jams, empty slots, disconnections) with complete clinical honesty.

## Operating Context

- **Home Healthcare Setting:** Daily patient routine in living room or bedroom where the physical CAREMATE robot is placed on a nightstand or kitchen counter.
- **Hardware Integration:** ESP32 DevKit V1 controlling a 6-slot circular carousel servo (0°-300°), a dispensing trapdoor servo (0°-85°), an active-LOW optical IR drop sensor, and a piezo buzzer.
- **Communication Layer:** Low-latency BLE GATT protocol (`4fafc201-1fb5-459e-8fcc-c5c9c331914b`) with periodic telemetry heartbeats and bidirectional notifications.
- **Clinical Review:** Routine caregiver check-ins reviewing daily compliance percentage, audit timestamps, and connected vitals provenance (e.g. Omron Platinum BLE blood pressure cuffs).

## Capabilities and Constraints

- **Truthful State Machine:** Every dose transitions strictly through `SCHEDULED` ➔ `COMMAND_SENT` ➔ `DISPENSE_CONFIRMED` ➔ `ACKNOWLEDGED`, or reports `FAILED` / `UNKNOWN`.
- **Double-Dose Prevention:** Duplicate dispense requests for the same prescription are blocked for 45 minutes after an active or confirmed cycle.
- **Hardware Simulation & Fault Injection:** Dual-engine architecture allows instant testing of real ESP32 BLE hardware alongside a high-fidelity simulator that models mechanical jams, empty drops, and motor transit delays.
- **AI Health Companion:** Context-aware assistant providing plain-language explanations of medication instructions and food interactions (bilingual English & Hindi/Hinglish), backed by strict emergency red-flag clinical triage (chest pain, shortness of breath, stroke symptoms).
- **Medical Reference Layer:** Searchable drug monographs (indications, black box warnings, renal adjustments, food interactions) with authorized clinical attribution (Medscape Reference / FDA Labels) and multi-drug interaction checking.
- **Offline-First Persistence:** Local storage for all medications, history, vitals, alerts, and settings.
- **Hardware Constraints:** 6-compartment limit per reload cycle; physical tablet drop confirmation relies on line-of-sight optical beam crossing within a 2.5-second timeout window.

## Brand Commitments

- **Name:** CAREMATE.
- **Tone of Voice:** Calm, reassuring, clinically precise, transparent, and respectful.
- **Design Personality:** Medical-grade modern elegance (deep teal `#0D9488`, clean slate neutrals, high-legibility typography, clear status color coding).
- **Integrity Promise:** The system will never fabricate sensor readings, fake delivery success, or claim clinical outcomes without actual hardware or measurement device validation.

## Evidence on Hand

- **Built & Signed Android APK:** `d:\CAREMATE\outputs\caremate-app.apk` (verified with APK Signature Schemes v1 & v2).
- **Working Application Codebase:** `d:\CAREMATE\caremate_app/` (Flutter 3.24.3, 0 analyzer issues, 5/5 automated unit and safety test suites passing).
- **Production ESP32 Firmware:** `d:\CAREMATE\firmware\caremate_esp32_firmware.ino` (tested BLE GATT Server, PWM servos, and optical drop detection logic).
- **Verified Vitals Data:** Sample validated readings from Omron Platinum and Masimo MightySat BLE profiles.
- **Absence:** Live physical cloud backend (Firebase / AWS) is deferred to Phase 2 to ensure absolute offline-first reliability during initial field trials.

## Product Principles

1. **Truth Over Assumption:** Never conflate scheduled with dispensed, or dispensed with consumed. Report every state transition with physical evidence or fail safely.
2. **Fail-Safe by Default:** A disconnected robot, an empty slot, or a jammed carousel must trigger an immediate honest alert, never a silent failure or false success.
3. **Accessibility Without Infantilization:** Senior patients deserve dignity, large legible typography, simple one-touch affordances, and zero jargon without feeling like the product is a toy.
4. **Offline Resilience:** Healthcare at home cannot depend on a continuous cloud connection. Local schedules, local hardware BLE, and local storage must always work.
5. **Clinical Guardrails First:** AI companions must recognize their limits, never diagnose acute conditions, and immediately route red-flag symptoms to emergency services.

## Accessibility & Inclusion

- **Dual Personas:** Instant switching between comprehensive Caregiver Oversight and simplified, high-visibility Patient Mode.
- **High-Contrast Theme:** High-contrast accessible mode with reinforced borders and scaled typography for elderly and visually impaired users.
- **Minimum Touch Targets:** Minimum 48x48 dp touch targets across all buttons and controls.
- **Multilingual Support:** Conversational support and instructions in English and Hindi/Hinglish.
