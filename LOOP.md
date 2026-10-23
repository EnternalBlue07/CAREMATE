# CAREMATE — Continuous Improvement Loop Guide (LOOP.md)

This playbook defines how each improvement cycle is executed, tested, and published to GitHub.

---

## The Loop Protocol

Each cycle follows a disciplined 5-step cadence:

### Step 1: Inspect & Identify
- Read active code, models, and tests.
- Identify:
  - State machine or edge-case defects.
  - Recovery flaws (disconnection, timeout, app restart).
  - Accessibility and screen responsiveness gaps.
  - Test coverage opportunities.

### Step 2: Implement Small, Focused Solutions
- Apply the minimal necessary edits.
- Preserve existing architectural patterns and APIs.
- Keep comments and docstrings intact.

### Step 3: Automated Regression Testing
- Add corresponding unit or widget tests for every modified flow.
- Run `flutter test` in `caremate_app`.

### Step 4: Static Analysis & Compilation Check
- Run `flutter analyze` in `caremate_app` (ensure 0 issues).
- Periodically verify debug APK compilation (`flutter build apk --debug`).

### Step 5: Verified Commit & Push
- Create descriptive, semantic Git commits (e.g. `fix: ...`, `test: ...`, `refactor: ...`).
- Push commits to `origin main` using account-linked credentials.

---

## Safety Circuit-Breaker
- **Stop Condition**: If any test fails, analysis yields errors, or a physical hardware hazard is identified, stop execution immediately. Do not push broken code.
