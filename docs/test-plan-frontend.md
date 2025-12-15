# Frontend Test Plan — FederalNet (Admin App)

This document shows manual and automated checks to verify frontend flows.

Prereqs:
- Backend running at `http://127.0.0.1:8080`
- Admin account available (`testadmin`/`adminpass`)
- Admin web app served (example: `http://0.0.0.0:8081`)

Tests:

1) Admin login page
- Enter `testadmin` / `adminpass` → expected to navigate to Dashboard and store JWT in `flutter_secure_storage`.

2) Register customer flow
- From Dashboard, open "Register Customer" → fill required fields including `NRC` and `PPPoE` credentials → press Create.
- Expected: success toast, new customer appears in DB, `radcheck` entry created.

3) Error handling
- Leave `NRC` empty → expected validation message on the form.
- Attempt to create duplicate `pppoe_username` → expected backend 400 response and friendly error.

4) Persistence & navigation
- After successful creation, ensure the app navigates back to Dashboard and JWT persists across reload.

Automated smoke tests (optional):
- Use integration_test or webdriver-driven scripts to automate login and register flows.
