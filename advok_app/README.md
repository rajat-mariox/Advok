 # Advok App

Advok is a Flutter mobile app that connects **clients** with legal professionals — **advocates**, **law students**, and **law firms**. Clients can search advocates, book consultations, and chat; professionals register, get verified by an admin, and then get a role-specific dashboard.

The app talks to the Node/Express backend in [`../backend`](../backend), and registrations are approved/rejected from the React admin panel in [`../admin-panel`](../admin-panel).

## Tech stack

- **App:** Flutter (Material 3, Inter font), plain `http` for networking — no state-management package; an in-memory `Session` holds the auth token and user.
- **Backend:** Express + TypeScript, JWT auth, JSON-file database (`backend/data`). Runs on port **4000**.
- **Admin panel:** React + Vite + TypeScript.

## App flow (high level)

```
SplashScreen
   │
   ▼
SelectCountryScreen ──► LoginScreen (phone) ──► OtpScreen (6-digit OTP)
                                                     │
                                                     ▼
                                          PostLoginNavigator decides:
                                                     │
        ┌───────────────┬────────────────┬───────────┴──────────┬───────────────┐
        ▼               ▼                ▼                      ▼               ▼
   status: new     role: client    status: pending       status: rejected   status: approved
   (first login)   (no approval    approval              RegistrationRe-    / active
        │           needed)             │                jectedScreen            │
        ▼               ▼               ▼                (shows admin's          ▼
  ChooseRoleScreen  ClientNavScreen  "Submitted"          reason, can       Role dashboard
        │                            waiting screen       re-apply)         (see below)
        ▼                            (polls status
  Role onboarding                    every 8s)
  (see below)
```

### 1. Login (OTP)

1. **Splash → Select Country → Login:** user picks a country code and enters a phone number.
2. `POST /api/auth/send-otp` — this is a prototype, so there is no SMS gateway: the OTP is printed in the backend console and returned as `devOtp` (the app can show it for testing).
3. **OtpScreen** verifies via `POST /api/auth/verify-otp`. On first login the backend **creates the user** with `role: null, status: 'new'` and returns a JWT + user object, stored in the in-memory `Session`.
4. [`PostLoginNavigator`](lib/Services/post_login_navigator.dart) then routes based on `Session.role` + `Session.status` (see diagram above). If the role was chosen earlier but the form never submitted (`onboarding_required`), the registration flow restarts.

### 2. Choose role & onboarding

On **ChooseRoleScreen** (`POST /api/auth/select-role`) the user picks one of four roles:

| Role | Onboarding | Approval needed? |
|---|---|---|
| **Client** | None — goes straight to `ClientNavScreen` | No |
| **Advocate** | Describe Yourself → Select Purpose → Professional Details → Practice Location → My Schedule → submit | Yes |
| **Law Student** | Student Verification form (college/ID details) → submit | Yes |
| **Law Firm** | Register Firm → Add Legal Team → submit | Yes |

- Advocate onboarding data collects across steps in `AdvocateOnboardingData` and submits once at the end via `POST /api/onboarding/advocate` (similarly `/law-student`, `/law-firm`).
- After submit the user lands on a **"Verification Submitted"** screen and their status becomes `pending_approval`.

### 3. Admin approval

- The admin logs into the **admin panel** (`POST /api/auth/admin/login`) and sees pending registrations (`GET /api/admin/registrations`), then **approves**, **rejects** (with a reason), or **reopens** them.
- Meanwhile the app's [`ApprovalStatusPoller`](lib/Services/approval_status_poller.dart) polls `GET /api/onboarding/status` every **8 seconds**:
  - **approved** → refreshes the profile (`GET /api/auth/me`) and unlocks the dashboard automatically.
  - **rejected** → shows `RegistrationRejectedScreen` with the admin's reason; the user can re-apply.

### 4. Role dashboards (bottom navigation)

Each role gets its own nav shell with 5 tabs (`IndexedStack`):

| Role | Tabs |
|---|---|
| **Client** (`ClientNavScreen`) | Home · Search (advocate list) · Messages · Bookings · Profile |
| **Advocate** (`AdvocateNavScreen`) | Home (dashboard) · Clients · Messages · Cases · Profile |
| **Law Student** (`StudentNavScreen`) | Home · Advocates (find mentors) · Messages · Queries · Profile |
| **Law Firm** (`FirmNavScreen`) | Home (dashboard) · Lawyers · Messages · Cases · Firm profile |

Key in-app flows from the dashboards:

- **Client booking:** Advocate list → Advocate profile → Consultation type → Select date/time → Booking summary → Booking confirmed (appears under the Bookings tab).
- **Student mentorship:** Find Mentors → Request Mentorship → Availability → Message → Request Sent. Students also get news articles, case studies, and legal queries.
- **Advok AI:** an AI assistant screen available from the home screens.
- **Messaging:** Messages tab → Chat screen (all roles).
- **Help & Support / CMS:** static pages are served from the backend CMS (`GET /api/cms/:slug`), editable from the admin panel.

## Country-aware flow (India vs US)

The country picked on **SelectCountryScreen** drives the whole legal flow via
[`CountryCatalog`](lib/Utils/CountryData/country_catalog.dart): each
`CountryProfile` carries a `LegalTerms` config (terminology, courts, license
labels, advocate tiers). Defaults are the Indian system; the US overrides them:

| | India | United States |
|---|---|---|
| Role name | Advocate | Attorney |
| Tiers | Junior / Senior Advocate | Associate / Senior Attorney |
| License field | Bar Registration Number | State Bar Number |
| Senior/mentor name | Mandatory for juniors | Optional (supervising attorney) |
| Courts | Supreme / High / District Court… | State & Federal courts… |
| Verification | Bar Council records | State bar records |

The chosen country is sent with `send-otp`, stored on the user by the backend,
and re-synced into `CountryCatalog` on every login (`fetchMe`) — so a returning
user always gets the flow they registered with, and the admin knows which
authority to verify against. Other countries keep the default (Indian-style)
wording until they get their own `LegalTerms`.

## Project structure

```
lib/
├── main.dart                    # App entry — theme, global text scaling, SplashScreen
├── AppNavigation/               # Bottom-nav shells: client / advocate / student / firm
├── CommonWidgets/               # Shared UI (back button, social login, profile sheets)
├── Screens/
│   ├── SplashScreen/ SelectCountryScreen/ LoginScreen/ OtpScreen/
│   ├── ChooseRoleScreen/        # Role picker after first login
│   ├── AdvocateRegistration/    # 5-step advocate onboarding + submitted screen
│   ├── LawStudentRegistration/  # Student verification + submitted screen
│   ├── LawFirmRegistration/     # Firm registration + legal team + submitted screen
│   ├── RegistrationStatus/      # Rejected screen (with admin reason)
│   └── Screens/                 # All post-login screens per role (home, bookings,
│                                #   cases, mentors, messages, profile, Advok AI…)
├── Services/
│   ├── api_service.dart         # Session + all backend calls, auto base-URL discovery
│   ├── post_login_navigator.dart# Routes user after OTP based on role/status
│   └── approval_status_poller.dart # 8s polling while pending approval
└── Utils/                       # AppColors, Responsive helpers, country catalog
```

## Backend API used by the app

| Endpoint | Purpose |
|---|---|
| `POST /api/auth/send-otp` | Send (log + return) OTP for a phone |
| `POST /api/auth/verify-otp` | Verify OTP → JWT + user (created on first login) |
| `POST /api/auth/select-role` | Save chosen role (`client` / `advocate` / `law_student` / `law_firm`) |
| `GET  /api/auth/me` | Refresh current user + submitted profile |
| `POST /api/onboarding/advocate` / `law-student` / `law-firm` | Submit onboarding form → `pending_approval` |
| `GET  /api/onboarding/status` | Poll approval status (+ rejection reason) |
| `GET  /api/cms/:slug` | CMS pages (help, terms, etc.) |

### User status lifecycle

```
new ──select-role──► onboarding_required ──submit form──► pending_approval
                                                              │
                                            admin approves ◄──┴──► admin rejects
                                                 │                     │
                                              approved              rejected ──re-apply──► pending_approval
```

(Clients skip the approval part entirely — they are active right after choosing the role.)

## Running the app

1. **Start the backend** (from `../backend`):

   ```bash
   npm install
   npm run dev        # http://localhost:4000
   ```

2. **Run the Flutter app** (from this folder):

   ```bash
   flutter pub get
   flutter run
   ```

   The app auto-discovers the backend by probing `/health` on, in order: `localhost:4000` (desktop/web, or USB phone after `adb reverse tcp:4000 tcp:4000`), `10.0.2.2:4000` (Android emulator), and the dev machine's LAN IP (physical phone on the same Wi-Fi — update `_devMachineLanIp` in [api_service.dart](lib/Services/api_service.dart) if your Wi-Fi IP changes, check with `ipconfig`).

   To point at a specific server instead:

   ```bash
   flutter run --dart-define=ADVOK_API_URL=http://<host>:4000/api
   ```

3. **(Optional) Admin panel** for approving registrations (from `../admin-panel`):

   ```bash
   npm install
   npm run dev
   ```

> **Note:** OTPs are printed in the backend console (`[OTP] <phone> -> <code>`) and returned as `devOtp` — no real SMS is sent in this prototype.
