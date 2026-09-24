# ADVOK

ADVOK is a legal-services platform that connects **clients** with **attorneys (advocates)** and **law firms**, and gives **law students** curated learning content and mentorship access. The project has three parts that talk to one REST API:

| Part | Folder | Stack | Who uses it |
|---|---|---|---|
| Backend API | [`backend/`](backend/) | Node.js 22 · Express 4 · TypeScript · MongoDB (or a JSON file) | Everything below |
| Admin panel | [`admin-panel/`](admin-panel/) | React 18 · Vite · TypeScript · react-router | Platform admins |
| Mobile app | [`advok_app/`](advok_app/) | Flutter (Dart SDK ^3.12) · Android + iOS | Clients, advocates, law firms, law students |

Third-party services: **CourtListener** (US court records: docket lookup, case status/timeline sync, case-law reading material), **Groq** (ADVOK AI legal assistant, case notes, dictionary explanations), **Black's Law Dictionary 2nd ed.** (public-domain text bundled as `backend/data/legal_terms.json`), **RSS legal news** (SCOTUSblog, ABA Journal, Congress.gov), **Google / Apple** sign-in, **AWS S3** (photo and document storage, optional), **MongoDB Atlas** (data, optional).

---

## Table of contents

1. [Quick start](#1-quick-start)
2. [Environment variables](#2-environment-variables)
3. [Architecture](#3-architecture)
4. [Roles and account lifecycle](#4-roles-and-account-lifecycle)
5. [Data models (every field)](#5-data-models-every-field)
6. [API reference (every endpoint)](#6-api-reference-every-endpoint)
7. [Court records integration (CourtListener)](#7-court-records-integration-courtlistener)
8. [Admin panel](#8-admin-panel)
9. [Mobile app](#9-mobile-app)
10. [Deployment notes](#10-deployment-notes)

---

## 1. Quick start

### Backend

```bash
cd backend
npm install
# create backend/.env — see section 2 for every variable (all optional in dev)
npm run dev                 # tsx watch src/index.ts → http://localhost:4000
```

On boot the server prints its LAN URLs and seeds the admin account. Health check: `GET /api/health` → `{ ok: true, service: 'advok-backend' }`.

Seeded admin login: `admin@advok.com` / `Admin@123` (change in `backend/src/config.ts` before production).

Other scripts: `npm run build` (tsc → `dist/`), `npm start` (runs `dist/index.js`).

### Admin panel

```bash
cd admin-panel
npm install
# admin-panel/.env must contain VITE_API_BASE (no trailing slash), e.g.
# VITE_API_BASE=http://192.168.1.34:4000/api
npm run dev                 # http://localhost:5173
npm run build               # tsc -b && vite build → dist/
```

### Mobile app

```bash
cd advok_app
flutter pub get
flutter run
# or point at a specific backend:
flutter run --dart-define=ADVOK_API_URL=http://192.168.1.34:4000/api
```

Without `ADVOK_API_URL` the app uses the LAN IP hard-coded in [`advok_app/lib/Services/api_service.dart`](advok_app/lib/Services/api_service.dart) (`_devMachineLanIp`). The phone or emulator must be on the same Wi-Fi as the backend. Update that IP when your machine's IP changes (`ipconfig`).

Login in development: the OTP is printed to the backend console (`[OTP] +1xxxxxxxxxx -> 123456`) and also returned as `devOtp` in the send-otp response. There is no SMS gateway.

---

## 2. Environment variables

### `backend/.env`

| Variable | Required | Default | Purpose |
|---|---|---|---|
| `PORT` | no | `4000` | Port the API listens on (binds `0.0.0.0`). |
| `JWT_SECRET` | prod | dev secret | Signs admin (8h) and app (30d) tokens. |
| `MONGODB_URI` | no | empty | When set, data lives in MongoDB. Empty → `backend/data/db.json`. On first boot against an empty database, existing `db.json` data is migrated in. |
| `MONGODB_DB` | no | `advok` | Database name. |
| `GOOGLE_CLIENT_ID` | for Google login | empty | OAuth 2.0 *Web application* client ID; the app's ID token is verified against it. |
| `APPLE_BUNDLE_ID` | for Apple login | `com.example.advokApp` | Audience of the Apple identity token; must equal the iOS bundle ID. |
| `AWS_REGION` | no | `ap-south-1` | S3 region. |
| `S3_BUCKET` | no | empty | When set, profile photos and case documents go to S3. Empty → stored inline as base64 data URLs. |
| `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` | with S3 off EC2 | | IAM user keys. On EC2 use an instance role instead. |
| `S3_PUBLIC_URL` | no | bucket URL | CloudFront / custom domain that serves the bucket. |
| `COURTLISTENER_API_TOKEN` | no | empty | Free token from courtlistener.com. Lookup and sync work **without** it (lower rate limit). With it: higher limit, and full opinion text for Learning Content. |
| `COURT_SYNC_INTERVAL_MINUTES` | no | `720` | How often linked open cases are re-synced from court records. `0` disables the scheduler; "Sync Now" in the app still works. |
| `OPENAI_API_KEY` | for ADVOK AI | empty | OpenAI key (platform.openai.com). When set, ADVOK AI, case notes and dictionary explanations use OpenAI. |
| `OPENAI_MODEL` | no | `gpt-4o-mini` | OpenAI model. |
| `GROQ_API_KEY` | fallback | empty | Groq key, used only when `OPENAI_API_KEY` is empty. Without either key the app shows "ADVOK AI is not connected". |
| `GROQ_MODEL` | no | `openai/gpt-oss-120b` | Groq model. |
| `FIREBASE_SERVICE_ACCOUNT` | for push | empty | Path to the Firebase service-account JSON (e.g. `keys/firebase-service-account.json`, gitignored) or the JSON inline. Enables phone push via FCM. |
| `FIREBASE_PROJECT_ID` / `FIREBASE_MESSAGING_SENDER_ID` / `FIREBASE_ANDROID_API_KEY` / `FIREBASE_ANDROID_APP_ID` / `FIREBASE_IOS_API_KEY` / `FIREBASE_IOS_APP_ID` | for push | empty | Public Firebase app settings; served to the app by `GET /auth/config` so no google-services files are bundled. |
| `SMTP_HOST` / `SMTP_PORT` / `SMTP_USER` / `SMTP_PASS` / `MAIL_FROM` | for email | empty / 587 | Any SMTP provider (AWS SES, SendGrid, Gmail). Emails go out for bookings, case assigned, support replies, query answers and account approval. |
| `NEWS_FEEDS` | no | SCOTUSblog, ABA Journal, Congress.gov | Legal-news RSS sources for students, `key\|Name\|url\|Tag` entries separated by `;`. Free, no key. |

### `admin-panel/.env` / `.env.production`

| Variable | Purpose |
|---|---|
| `VITE_API_BASE` | Backend base URL including `/api`, no trailing slash. Required; the panel throws at startup if missing. Vite bakes it in at build time. On Vercel set it in the project's Environment Variables. |

### Mobile app

| Define | Purpose |
|---|---|
| `ADVOK_API_URL` | `--dart-define` override of the backend base URL (with `/api`). |

---

## 3. Architecture

### Backend layout (`backend/src`)

```
index.ts                 Express app: CORS, 16 MB JSON body limit, request logger,
                         /api router, DB init, court-records sync scheduler
config.ts                All env-derived constants (section 2)
routes/                  One router per domain, mounted in routes/index.ts
controllers/             Request handlers (auth, onboarding, admin, booking, case,
                         message, support, settings, ai, learning, news, law-firm…)
services/
  db.service.ts          In-memory DbShape + persistence (MongoDB or db.json)
  court.service.ts       CourtListener client: docket lookup, docket header, entries
  case-sync.service.ts   Sync linked cases from court records + scheduler
  courtlistener.service.ts  Opinion search / full text for Learning Content
  ai.service.ts          Groq chat completion
  notify.service.ts      In-app notifications + system chat messages
  storage.service.ts     S3 upload (or inline base64)
  pricing.service.ts     Consultation pricing rules
  firm.service.ts        Law-firm team / linked attorney helpers
  news.service.ts        Legal-news feed for students
  sms.service.ts         OTP delivery stub (console)
middlewares/             auth.middleware (requireAuth / requireRole), logger
models/                  TypeScript interfaces for every collection (section 5)
validators/              Body validators (e.g. CMS sections)
util/                    publicUser() etc.
data/db.json             File store used when MONGODB_URI is empty
```

**Persistence model.** Every controller works on one in-memory `DbShape` object and calls `saveDb()` after mutating it. With MongoDB configured, `saveDb()` snapshots the state and writes each collection in the background (`replaceOne` upserts + `deleteMany` for removed ids). Without MongoDB the whole state is written to `data/db.json`. The in-memory state is the source of truth while the server runs, so edit data through the API, not directly in the database.

**Live updates (real time).** `GET /api/events` is a Server-Sent Events stream, one per signed-in app session and per admin tab (token in the `Authorization` header, or `?token=` for the browser's EventSource). Controllers call `publishToUser` / `publishToAdmins` / `publishToAll` from [`services/realtime.service.ts`](backend/src/services/realtime.service.ts) right after `saveDb()`, sending a tiny `{ topic, data }` notice such as `bookings`, `cases`, `messages`, `notifications`, `clients`, `queries`, `support`, `account`, `settings`, `registrations`, `users`, `content`. Clients re-fetch the list they show, so every screen reflects other users' actions within about a second; the app falls back to slow polling only if the stream drops. Every `pushNotification` / system chat message is mirrored to the stream automatically. The bus is in-process: it works on a single instance (local, EC2); a serverless or multi-instance deployment would need Redis pub/sub or a hosted channel service.

**Auth.** JWT bearer tokens. `POST /auth/admin/login` issues an 8-hour admin token; OTP / Google / Apple login issue a 30-day app token. `requireAuth` loads the user; `requireRole(...)` additionally checks `user.role`. Suspended accounts are rejected by the middleware.

### Request flow

```
Flutter app / Admin panel ──HTTP JSON──▶ Express /api/* ──▶ controller ──▶ in-memory DbShape
                                                               │                  │
                                                               ▼                  ▼ saveDb()
                                             CourtListener / Groq / S3      MongoDB or db.json
```

---

## 4. Roles and account lifecycle

`Role`: `admin` · `client` · `advocate` · `law_student` · `law_firm`

`UserStatus`:

| Status | Meaning |
|---|---|
| `new` | OTP / social login verified, role not chosen yet. |
| `active` | Client (no onboarding needed) or a fully usable account. |
| `onboarding_required` | Role chosen, onboarding form not submitted. |
| `pending_approval` | Onboarding submitted, waiting for admin review. |
| `approved` | Admin approved (advocate / law student / law firm). |
| `rejected` | Admin rejected, with `rejectionReason`. |
| `suspended` | Admin suspended (any role), with `suspensionReason`; `statusBeforeSuspension` is restored on unsuspend. |

Flow: **Select country → Login (phone OTP / Google / Apple) → Choose role → Onboarding (role-specific) → Pending → Admin approves → Home.** Clients skip onboarding and go straight to `active` after entering their name. A phone number that appears on an approved law firm's team signs in directly as that firm's attorney (`firmId` / `firmName` set on the user).

---

## 5. Data models (every field)

All models live in [`backend/src/models/`](backend/src/models/). Dates are ISO strings unless noted; `'YYYY-MM-DD'` marks calendar days.

### `DbShape` (collections)

| Field | Type | Collection |
|---|---|---|
| `users` | `User[]` | users |
| `otps` | `OtpRecord[]` | otps |
| `cmsPages` | `CmsPage[]` | cmsPages |
| `bookings` | `Booking[]` | bookings |
| `relationships` | `ClientRelationship[]` | relationships |
| `cases` | `CaseRecord[]` | cases |
| `messages` | `ChatMessageRecord[]` | messages |
| `notifications` | `AppNotification[]` | notifications |
| `settings` | `AppSettings[]` | settings (single record id `global`) |
| `supportTickets` | `SupportTicket[]` | supportTickets |
| `caseStudies` | `CaseStudyRecord[]` | caseStudies |
| `legalTerms` | `LegalTermOverride[]` | legalTerms (admin edits + AI explanation cache; the ~11k base terms are read from `data/legal_terms.json`, not the DB) |
| `legalQueries` | `LegalQueryRecord[]` | legalQueries |

### `User`

| Field | Type | Description |
|---|---|---|
| `id` | string | UUID. |
| `role` | `Role \| null` | Null until the user picks a role. |
| `status` | `UserStatus` | See section 4. |
| `phone` | string? | Phone used for OTP login. |
| `countryCode` | string? | e.g. `+1`. |
| `country` | string? | Country chosen at signup (`India`, `United States`); drives the app's India/US flow and which authority the admin verifies against. |
| `email` | string? | Admin email, or the email from Google/Apple login. |
| `googleId` | string? | Google `sub` claim. |
| `appleId` | string? | Apple `sub` claim. |
| `passwordHash` | string? | bcrypt hash (admin only). |
| `name` | string? | Display name (clients, admin). |
| `profile` | `Profile?` | Role-specific profile (below). |
| `rejectionReason` | string? | Set when `status = rejected`. |
| `suspensionReason` | string? | Shown in the app while suspended. |
| `statusBeforeSuspension` | `UserStatus?` | Restored on unsuspend. |
| `firmId` | string? | For attorneys linked to a law firm (phone matched the firm's team). |
| `firmName` | string? | Cached firm name for the above. |
| `createdAt` | string | |
| `onboardedAt` | string? | When onboarding was submitted. |
| `reviewedAt` | string? | When the admin approved/rejected. |

`publicUser()` strips `passwordHash` before anything is returned to a client.

### `AdvocateProfile` (role `advocate`)

| Field | Type | Description |
|---|---|---|
| `advocateType` | `'junior' \| 'senior'` | Junior = under 10 years (India), needs a senior's name. |
| `photo` | string? | S3 URL or base64 data URL. |
| `yearsInPractice` | string? | US only: `0–2 years` … `20+ years`. |
| `firmRole` | string? | US only: Partner, Associate, Of Counsel, Solo Practitioner… |
| `purposes` | string[] | What they want from ADVOK (clients, mentoring…). |
| `location.state` | string | |
| `location.district` | string | District / city. |
| `location.officeAddress` | string | |
| `professional.fullName` | string | |
| `professional.seniorAdvocateName` | string? | Required for juniors in India. |
| `professional.email` | string | |
| `professional.licenseNumber` | string | Bar Registration Number (India) / State Bar License (US). |
| `professional.barRegistrationNumber` | string? | Legacy alias of `licenseNumber` on old records. |
| `professional.primaryCourt` | string | |
| `professional.practiceArea` | string | |
| `professional.barAdmissions` | `BarAdmission[]?` | US only: `{ state, barNumber, licenseStatus }` per admission. |
| `professional.federalCourtAdmissions` | string[]? | US only. |
| `schedule.workingDays` | string[] | e.g. `['Mon','Tue']`. |
| `schedule.startTime` | string | e.g. `09:00 AM`. |
| `schedule.endTime` | string | |

### `LawStudentProfile` (role `law_student`)

| Field | Type | Description |
|---|---|---|
| `fullName` | string | |
| `college` | string | |
| `course` | string | |
| `academicYear` | string | |
| `idCardFileName` | string | Uploaded student ID file name. |
| `photo` | string? | |

### `ClientProfile` (role `client`)

| Field | Type | Description |
|---|---|---|
| `fullName` | string? | |
| `email` | string? | |
| `photo` | string? | |

### `LawFirmProfile` (role `law_firm`)

| Field | Type | Description |
|---|---|---|
| `firmName` | string | |
| `foundedYear` | string | |
| `contactPerson` | string | |
| `logoFileName` | string? | |
| `officialEmail` | string | |
| `mainPhone` | string | |
| `receptionNumber` | string? | |
| `addressLine1` / `addressLine2` | string / string? | |
| `city` / `zip` / `state` | string | |
| `totalLawyers` | string | |
| `lawyers` | `FirmLawyer[]` | The legal team (below). |
| `consultationFee` | number? | Firm's own voice-consultation fee (USD). Unset → platform `law_firm_phone_call` rate. |
| `photo` | string? | Logo. |

`FirmLawyer`: `fullName`, `phone`, `email?`, `barLicense`, `barState?`, `licenseStatus?` (Active · Inactive · Pending Admission · Suspended · Retired), `yearsExperience`, `designation`, `expertise: string[]`.

### `OtpRecord`

`phone`, `countryCode`, `country?`, `otp` (6 digits), `expiresAt` (epoch ms, 5-minute TTL). One record per phone; consumed on verify.

### `Booking`

| Field | Type | Description |
|---|---|---|
| `id` | string | |
| `clientId` | string | The booker: a client, law student or law firm. |
| `advocateId` | string | The provider: an advocate **or** a law firm user id. |
| `providerRole` | `'advocate' \| 'law_firm'?` | Which kind `advocateId` is. |
| `assignedAttorney` | object? | Law-firm bookings: `{ name, designation, phone, email, userId? }` the firm assigned on accept. |
| `requestedAttorney` | object? | Client picked a specific firm attorney: `{ userId, name, designation, index }`. |
| `consultationType` | `'video_call' \| 'phone_call' \| 'office_visit'` | |
| `date` | `'YYYY-MM-DD'` | |
| `time` | string | Slot label, e.g. `10:00 AM`. |
| `durationMinutes` | number | |
| `amount` | number | Total at checkout (consultation + platform fee + tax). |
| `status` | `BookingStatus` | `pending` → `confirmed` / `declined`; `confirmed` → `completed` (by either side, or automatically once the slot has passed) or `cancelled` (by the booker). |
| `createdAt` / `respondedAt?` / `cancelledAt?` / `completedAt?` | string | |

### `ClientRelationship`

Created the moment a provider accepts a consultation. Cases can only be opened for clients with a relationship.

`id`, `advocateId`, `clientId`, `bookingId` (the consultation that created it), `createdAt`.

### `CaseRecord`

| Field | Type | Description |
|---|---|---|
| `id` | string | |
| `advocateId` | string | Attorney managing the case. |
| `clientId` | string | Must have a relationship with the attorney. |
| `title` | string | e.g. `Smith v. Jones`. |
| `caseNumber` | string | Case / docket number as filed. |
| `court` | string | Court name (picker label or the exact name from court records). |
| `practiceArea` | string? | |
| `status` | `'active' \| 'discovery' \| 'hearing' \| 'closed'` | Attorney-managed; set to `closed` automatically when the linked docket is terminated. |
| `priority` | `'high' \| 'medium' \| 'low'?` | |
| `filedDate` | `'YYYY-MM-DD'?` | Auto-filled from court records when linked. |
| `nextHearing` | `'YYYY-MM-DD'?` | Next court event (manual). |
| `timeline` | `CaseEvent[]` | Oldest first. |
| `documents` | `CaseDocument[]?` | |
| `documentRequests` | `DocumentRequest[]?` | |
| `courtRecord` | `CourtRecordLink?` | Link to the CourtListener docket (below). Absent for manual cases. |
| `createdAt` / `updatedAt` | string | |

`CaseEvent`: `id`, `date` (`YYYY-MM-DD`), `title`, `description?`, `source` (`'attorney' \| 'client' \| 'court_api'`), `externalId?` (e.g. `cl-entry-<docketEntryId>`, keeps syncs idempotent), `createdAt`.

`CaseDocument`: `id`, `name`, `url` (S3 or data URL), `sizeBytes?`, `uploadedBy?` (`attorney` / `client`), `uploadedAt`. Max ~10 MB per file.

`DocumentRequest`: `id`, `name` (what the attorney asked for), `note?`, `status` (`pending` / `uploaded`), `requestedAt`, `uploadedAt?`, `documentId?`. Requests appear as a card in the chat thread; the client's upload fulfils them.

`CourtRecordLink`:

| Field | Type | Description |
|---|---|---|
| `provider` | `'courtlistener'` | |
| `docketId` | number | CourtListener docket id. |
| `url` | string | Public docket page. |
| `courtName` | string? | e.g. `District Court, S.D. New York`. |
| `courtId` | string? | e.g. `nysd`. |
| `judge` | string? | Assigned judge. |
| `dateFiled` | string? | |
| `dateTerminated` | string? | Set once the court closed the docket. |
| `natureOfSuit` | string? | PACER nature of suit, e.g. `410 Anti-Trust`. |
| `cause` | string? | e.g. `15:1 Antitrust Litigation`. |
| `jurisdictionType` | string? | `Federal question`, `Diversity`, `U.S. Government Plaintiff`… |
| `parties` | string[]? | Up to 20 named parties. |
| `lastSyncedAt` | string? | |
| `lastSyncError` | string? | Message of the last failed sync; cleared on success. |

### `ChatMessageRecord`

`id`, `fromId`, `toId`, `text` (≤ 4000 chars), `system?` (platform-generated), `meta?` (structured card payload, e.g. `kind: 'consultation_accepted'`, `caseId`, document-request data), `sentAt`, `readAt?`.

### `AppNotification`

`id`, `userId`, `type` (`case_assigned` · `case_update` · `booking_request` · `booking_accepted` · `booking_declined` · `support_reply` · `query_answered`), `title`, `body`, `caseId?`, `bookingId?`, `ticketId?`, `queryId?`, `createdAt`, `readAt?`.

### `AppSettings` (single record, id `global`)

| Field | Type | Description |
|---|---|---|
| `consultationPricing` | `ConsultationPricing` | USD per key: `video_call` (120), `phone_call` (90), `office_visit` (150), `law_firm_phone_call` (150). |
| `support` | `SupportContact?` | `email`, `phone`, `hours`, `responseNote`. |
| `aiSuggestions` | `AiSuggestion[]?` | `{ id, text (≤140 chars), active }`, max 12. Shown as chips on the empty ADVOK AI screen. |
| `updatedAt` | string | |

### `SupportTicket`

| Field | Type | Description |
|---|---|---|
| `id` | string | |
| `userId` / `role` | string / `Role \| null` | Who raised it. |
| `category` | `account` · `booking` · `payment` · `case` · `technical` · `other` | |
| `subject` / `message` | string | |
| `status` | `open` · `in_progress` · `resolved` | |
| `replies` | `SupportReply[]` | `{ id, fromAdmin, text, createdAt }`. |
| `createdAt` / `updatedAt` / `resolvedAt?` | string | |
| `userUnread` / `adminUnread` | number | Unread counters for each side. |

### `LegalQueryRecord` (law student → ADVOK team)

| Field | Type | Description |
|---|---|---|
| `id` | string | |
| `studentId` | string | The law student who asked. |
| `category` | string | One of the app's query categories (Criminal Law, Civil Law, Family Law, …). |
| `question` | string | Max 500 characters. |
| `status` | `pending` · `answered` | |
| `response` | string? | The answer written in the admin panel (max 4000 chars). |
| `responderName` / `responderId` | string? | Shown to the student (default "ADVOK Legal Team") / admin user id. |
| `createdAt` / `answeredAt?` / `updatedAt` | string | |

### `CmsPage`

`slug` (e.g. `terms`, `privacy`), `title`, `sections: { title, body }[]`, `lastUpdatedLabel` (footer text in the app), `updatedAt`. Seeded from `models/cms.seed.ts`.

### `CaseStudyRecord` (Learning Content for students)

| Field | Type | Description |
|---|---|---|
| `id` | string | |
| `clusterId` | number | CourtListener opinion cluster id. |
| `title` / `court` / `courtId` | string | |
| `dateFiled` | `'YYYY-MM-DD'` | |
| `citation` | string | e.g. `384 U.S. 436`. |
| `docketNumber` / `judges` | string | |
| `tag` | string | Practice-area tag on the card. |
| `level` | `Beginner` · `Intermediate` · `Advanced` | |
| `summary` / `principle` | string | Admin-written plain-English summary and key principle. |
| `syllabus?` / `opinionText?` | string | From CourtListener (full text needs a token). |
| `mins` | number | Estimated read time. |
| `published` | boolean | Only published cases are visible to students. |
| `sortOrder` / `reads` | number | |
| `notes` | `CaseNotes?` | Cached IRAC study notes (below); absent until first generated. |
| `addedAt` / `updatedAt` | string | |

`CaseNotes` (Generate Case Notes tool): `facts`, `issue`, `rule`, `holding`, `reasoning`, `significance` (strings), `keyTerms: string[]` (4–8, each links to the dictionary), `generatedAt`, `model` (Groq model id, or `admin` after a manual rewrite), `edited` (admin reviewed). Generated once by ADVOK AI from the syllabus / opinion text / editor summary, then served from cache.

### `LegalTermOverride` (Legal Dictionary)

The base dictionary is **Black's Law Dictionary, 2nd Edition (1910)**, public domain, parsed from the archive.org OCR into `backend/data/legal_terms.json` (`{ slug, term, definition }[]`, ~11,000 entries) and loaded read-only at boot. This record holds what changes:

| Field | Type | Description |
|---|---|---|
| `slug` | string | Key, e.g. `habeas-corpus`; matches the base entry when editing one. |
| `term` | string | |
| `definition` | string? | Admin rewrite; replaces the base text when set. |
| `custom` | boolean | Not in the base dictionary (admin- or AI-added). |
| `aiOnly` | boolean? | Exists only because a student asked ADVOK AI about an unknown term; searchable, not in A–Z browse. |
| `hidden` | boolean? | Removed from the app (bad OCR entry). |
| `plainEnglish` / `plainEnglishAt` | string? | Cached ADVOK AI explanation. |
| `createdAt` / `updatedAt` | string | |

---

## 6. API reference (every endpoint)

Base path: `/api`. Send `Authorization: Bearer <token>` on protected routes. Errors are `{ error: string }` with 4xx/5xx.

### Notifications

- **In-app** (every role): `pushNotification()` stores an `AppNotification`, pushes it live over SSE, and also sends a **phone push** (FCM, when configured) and, for key types, an **email** (SMTP, when configured). New chat messages send a push too.
- **Admin bell**: `AdminNotification` records for new registrations, support tickets/replies, legal queries, bookings and first student–attorney messages. `GET /admin/notifications`, `POST /admin/notifications/read` (`{ ids? }`). Desktop pop-ups while the tab is in the background (Settings → Desktop Alerts).
- **Push devices**: `POST /profile/push-token` `{ token, platform }` on login, `DELETE /profile/push-token` `{ token }` on logout.

### Live updates — `/events`

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/events` | header or `?token=` | SSE stream. Frames: `event: ready` on connect, then `event: change` with `{ topic, data?, at }`; `: ping` heartbeat every 25 s. |
| GET | `/events/status` | — | `{ connections }` (diagnostics). |

### Auth — `/auth`

| Method | Path | Auth | Body / notes |
|---|---|---|---|
| POST | `/admin/login` | — | `{ email, password }` → `{ token, user, expiresAt }` (8h). |
| POST | `/send-otp` | — | `{ phone, countryCode?, country? }` → `{ message, devOtp }`. OTP also logged to console. |
| POST | `/verify-otp` | — | `{ phone, otp }` → `{ token, user }`. Creates the user on first login. |
| POST | `/google` | — | `{ idToken, country? }` → `{ token, user }`. |
| POST | `/apple` | — | `{ identityToken, fullName?, country? }` → `{ token, user }`. |
| POST | `/select-role` | user | `{ role }` — sets role; clients become `active`, others `onboarding_required`. |
| GET | `/me` | user | Current user. |

### Onboarding — `/onboarding`

| Method | Path | Role | Body |
|---|---|---|---|
| POST | `/advocate` | advocate | `AdvocateProfile` fields → status `pending_approval`. |
| POST | `/law-student` | law_student | `LawStudentProfile` fields. |
| POST | `/law-firm` | law_firm | `LawFirmProfile` fields incl. `lawyers[]`. |
| GET | `/status` | any app role | `{ role, status, rejectionReason, … }` — the app polls this on the pending screen. |

### Profile — `/profile`

| Method | Path | Auth | Body |
|---|---|---|---|
| PUT | `/` | user | Partial profile edits (name, email, photo as data URL, schedule…). Photo goes to S3 when configured. |

### Directories

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/advocates` | user | Approved attorneys with public profile, schedule, bar states and fees (search and practice-area filtering happen in the app). |
| GET | `/law-firms` | user | Approved law firms with their teams and fees. |
| GET | `/clients` | advocate | The attorney's client directory: `{ clientId, since, consultationType, openCases, sessions, clientName, clientPhoto, clientPhone }[]`. |

### Bookings — `/bookings`

| Method | Path | Role | Body / notes |
|---|---|---|---|
| POST | `/` | client, law_student, law_firm | `{ advocateId, consultationType, date, time, durationMinutes?, amount? }`. Creates `pending`, notifies the provider. |
| GET | `/` | bookers + advocate | My bookings (as booker or provider). Past confirmed slots auto-complete. |
| POST | `/:id/accept` | advocate, law_firm | Firms: `{ attorneyIndex }` to assign a team member (skipped when the client requested one). Creates the client relationship, sends a chat card. |
| POST | `/:id/decline` | advocate, law_firm | |
| POST | `/:id/cancel` | bookers | |
| POST | `/:id/complete` | bookers + advocate | Marks a confirmed consultation done. |

### Cases — `/cases`

| Method | Path | Role | Body / notes |
|---|---|---|---|
| GET | `/` | client, advocate, law_firm | My cases (advocate: managed; client: opened for me; firm: all its attorneys' cases). Newest update first. |
| POST | `/` | advocate | `{ clientId, title, caseNumber, court, practiceArea?, status?, priority?, filedDate?, nextHearing?, courtDocketId? }`. Client must be a related client. With `courtDocketId` the case is linked and synced immediately. Returns `{ case, sync? }`. |
| GET | `/docket-lookup?caseNumber=` | advocate | Court-records search (section 7). |
| GET | `/:id` | parties + firm | Full case with timeline, documents, requests, `courtRecord`, display names. |
| POST | `/:id/updates` | advocate | `{ title?, description?, date?, status?, priority?, nextHearing? }` — timeline note and/or field change; notifies the client. |
| POST | `/:id/sync` | advocate | Pull latest court records now → `{ case, sync: { changed, newEvents, statusChanged, status, error? } }`. |
| POST | `/:id/documents` | advocate | `{ name, file }` (base64 data URL, ≤ ~10 MB). |
| POST | `/:id/document-requests` | advocate | `{ name, note? }` — asks the client for a document (card in chat). |
| POST | `/:id/document-requests/:requestId/upload` | client | `{ name, file }` — fulfils a request. |
| DELETE | `/:id/documents/:docId` | advocate | |

### Messages & notifications

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/messages/threads` | user | Conversations, latest first, with peer info, last message, unread count. |
| GET | `/messages/with/:userId` | user | Thread with one peer; marks it read. |
| POST | `/messages/with/:userId` | user | `{ text }`. Only between related users (client ↔ provider, firm ↔ its attorneys). |
| GET | `/notifications` | user | My notifications, newest first. |
| POST | `/notifications/read` | user | No body — marks all of my notifications read. |

### Support — `/support`

| Method | Path | Auth | Body |
|---|---|---|---|
| GET | `/tickets` | user | My tickets. |
| POST | `/tickets` | user | `{ category, subject, message }`. |
| GET | `/tickets/:id` | user | One ticket with replies; clears `userUnread`. |
| POST | `/tickets/:id/reply` | user | `{ text }`. |

### Legal Queries — `/queries` (role `law_student`)

| Method | Path | Body / notes |
|---|---|---|
| GET | `/` | My queries, newest first: `{ queries: [{ id, category, question, status, response?, responderName?, createdAt, answeredAt? }] }`. |
| POST | `/` | `{ category, question }` (≤ 500 chars) → `{ query }`. Status starts `pending`. |

### Settings, CMS, AI, Learning (app side)

| Method | Path | Auth | Notes |
|---|---|---|---|
| GET | `/settings/pricing` | user | Consultation pricing. |
| GET | `/settings/support` | user | Help & Support contact. |
| GET | `/cms` | — | All CMS pages. |
| GET | `/cms/:slug` | — | One page. |
| GET | `/ai/status` | user | `{ connected, model }`. |
| GET | `/ai/suggestions` | user | Active suggested prompts. |
| POST | `/ai/chat` | user | `{ messages: [{ role, content }] }` (must end with a user message) → `{ reply }`. |
| GET | `/learning/cases` | user | Published case studies. |
| GET | `/learning/cases/:id` | user | One case study with `syllabus`, `opinionText`, `notes` (increments `reads`). |
| POST | `/learning/cases/:id/notes` | user | Study notes → `{ notes, cached }`. Generated by ADVOK AI on first call (a few seconds), cached after. |
| GET | `/learning/news[?tag=]` | user | Legal news feed. |
| GET | `/learning/dictionary?q=&letter=&limit=&offset=` | user | Ranked search (exact → prefix → word prefix → contains → definition) or A–Z browse → `{ terms: [{ slug, term, preview, source, hasPlainEnglish }], total }`. |
| GET | `/learning/dictionary/letters` | user | `{ letters: [{ letter, count }] }`. |
| GET | `/learning/dictionary/:slug` | user | Full entry: `definition`, `source` (`blacks2` · `admin` · `ai`), `sourceLabel`, `plainEnglish?`. |
| POST | `/learning/dictionary/explain` | user | `{ slug? , term?, regenerate? }` → `{ term, cached }`. Plain-English explanation by ADVOK AI, cached; `term` alone works for words the dictionary lacks. Uses the user's country for context. |

### Admin — `/admin` (role `admin`)

| Method | Path | Notes |
|---|---|---|
| GET | `/registrations?role=&status=` | Advocate / student / firm registrations for review. |
| GET | `/registrations/counts` | Pending counts per role (sidebar badges). |
| POST | `/registrations/:id/approve` · `/reject` (`{ reason? }`) · `/reopen` | Review actions. |
| GET | `/users?role=` | All non-admin users. |
| DELETE | `/users/:id` | Permanently delete a user. |
| POST | `/users/:id/suspend` (`{ reason? }`) · `/unsuspend` | |
| PATCH | `/users/:id/firm-fee` | `{ consultationFee: number \| null }` — a law firm's own fee; null falls back to the platform rate. |
| GET | `/bookings` | Every booking with `clientName` / `advocateName`. |
| GET | `/cases` | Every case with party names. |
| DELETE | `/cases/:id` | Delete a case plus its notifications and chat cards. |
| POST | `/operations/clear` | Wipe bookings, cases, relationships, messages, notifications (users untouched). |
| GET / PUT | `/pricing` | `ConsultationPricing`. |
| GET / PUT | `/support-contact` | `SupportContact`. |
| GET | `/mentorships` | Law student ↔ attorney conversations (a "mentorship" starts when a student messages an attorney): parties, last message, counts, status active / awaiting reply. |
| GET | `/mentorships/:studentId/:attorneyId/messages` | The full conversation (read-only). |
| GET | `/queries?status=&category=` | Law students' legal queries with student name/college/contact, pending first → `{ queries, counts: { total, pending, answered } }`. |
| POST | `/queries/:id/answer` | `{ response, responderName? }` — sends the answer, notifies the student (`query_answered`); calling again updates the reply. |
| DELETE | `/queries/:id` | Removes the query and its notifications. |
| GET | `/support/tickets` · `/support/tickets/:id` | |
| POST | `/support/tickets/:id/reply` | `{ text }`. |
| PATCH | `/support/tickets/:id/status` | `{ status }`. |
| GET | `/ai/status` | Groq connection state. |
| GET / PUT | `/ai/suggestions` | `{ suggestions: [{ id?, text, active }] }`. |
| GET | `/learning/search?q=` | CourtListener opinion search. |
| GET | `/learning/news/sources` · POST `/learning/news/refresh` | News feed sources / refresh. |
| GET / POST | `/learning/cases` | List / add a case study from a search hit. |
| PUT | `/learning/cases/order` | `{ ids }` reorder. |
| GET / PATCH / DELETE | `/learning/cases/:id` | |
| POST | `/learning/cases/:id/refresh-text` | Re-fetch opinion text (needs token). |
| POST / PUT | `/learning/cases/:id/notes` | Generate notes with ADVOK AI / save edited notes (`{ notes }`, `null` clears). |
| GET | `/learning/dictionary?q=&letter=` · `/learning/dictionary/stats` · `/learning/dictionary/:slug` | Dictionary admin view (includes hidden / AI-only). |
| POST | `/learning/dictionary` | `{ term, definition }` — add a custom term. |
| PATCH | `/learning/dictionary/:slug` | `{ term?, definition?, hidden? }` — rewrite a base entry or hide it. |
| DELETE | `/learning/dictionary/:slug` | Custom terms are deleted; base terms are hidden. |
| GET | `/cms` · PUT `/cms/:slug` | `{ title, sections, lastUpdatedLabel }`. |

---

## 7. Court records integration (CourtListener)

Applies to **US federal courts** (PACER / RECAP data via the Free Law Project). State courts have no unified API, so cases there are entered manually and never synced.

### Add Case flow (attorney)

1. Attorney picks a **client** from their client directory (only clients whose consultation they accepted).
2. Types the **docket number** (e.g. `1:20-cv-03010`) and taps *Search Court Records* → `GET /cases/docket-lookup`. The backend queries CourtListener's search API (`type=d`, `docketNumber:"…"`, falling back to a free-text search so a case name works too). Up to 10 matches; the same docket number can exist in several courts.
3. Each match returns:

   | Field | Meaning |
   |---|---|
   | `docketId` | CourtListener docket id; sent back as `courtDocketId` to link the case. |
   | `caseName` | Case title. |
   | `docketNumber` | |
   | `court` / `courtId` | Full court name / short id. |
   | `judge` | Assigned judge. |
   | `dateFiled` | |
   | `dateTerminated` | Present when the court closed the docket. |
   | `natureOfSuit` | PACER nature of suit. |
   | `cause` | Statutory cause of action. |
   | `jurisdictionType` | |
   | `parties` | Named parties (max 20). |
   | `practiceArea` | Suggested from the nature-of-suit code / docket type (see mapping below). |
   | `url` | Public docket page. |

4. Tapping a match **links** the case and auto-fills: title, docket number, court (exact name added to the picker), date filed, practice area. A banner shows case, court, judge, filed, status, nature of suit, cause, jurisdiction and parties. Editing the docket number or tapping *Unlink* removes the link.
5. *Create Case* → `POST /cases` with `courtDocketId`. The backend links the case and runs the first sync right away.

### Sync (status + timeline from the court)

`syncCaseWithCourt()` in [`case-sync.service.ts`](backend/src/services/case-sync.service.ts):

- Fetches the docket header (`type=d`, `docket_id:<id>`) and the 25 most recent docket entries (`type=rd`, newest first; attachments collapsed into their parent entry).
- Updates `courtRecord` (court, judge, filed, terminated, nature of suit, cause, jurisdiction, parties) and fills `filedDate` if empty.
- Adds each new entry to the timeline as a `court_api` event titled `#<entry number> <short description>`; `externalId = cl-entry-<docketEntryId>` prevents duplicates. Timeline is re-sorted by date.
- If `dateTerminated` is set and the case isn't closed → `status = closed` plus a "Case terminated by the court" event.
- Notifies the client (and the attorney on scheduled runs) when something changed.
- Failures never throw: `lastSyncError` is recorded and the next run retries.

Triggers: on create, on *Sync Now* (`POST /cases/:id/sync`, Case Details screen), and by the scheduler every `COURT_SYNC_INTERVAL_MINUTES` (first run 2 minutes after boot, 1.5 s between cases).

What the court does **not** provide: the `active` / `discovery` / `hearing` stages, next hearing date, priority. Those stay attorney-managed.

### Practice-area suggestion

| Nature of suit (PACER code) or docket type | Practice area |
|---|---|
| Docket number contains `-cr-`, `-mj-`, `-po-`, `-tp-`; 510–560 Prisoner; 610–690 Forfeiture/Penalty | Criminal Defense |
| `-bk-` / `-ap-` docket; 422–423 | Bankruptcy |
| 110–196 Contract; 410 Antitrust; 850 Securities | Corporate/Business Law |
| 210–290 Real Property | Real Estate |
| 310–368 Personal-injury torts | Personal Injury |
| 442, 445, 710–791 Labor / employment | Employment Law |
| 460–465 Immigration | Immigration |
| 820, 830, 835, 840, 880 | Intellectual Property |
| 870–871 | Tax Law |
| Any other civil code | Civil Litigation |
| No code: keyword match on the text (immigration, patent, tax, employ, malpractice, foreclosure, habeas, cyber, contract…) | as above |

The app applies the suggestion only if it is one of the country's practice areas.

### Test dockets

`1:20-cv-03010` (US v. Google — open, and Pierre-Louis v. United States — terminated), `2:19-cv-00567`, `1:21-cr-00123`.

---

## 8. Admin panel

Routes in [`admin-panel/src/App.tsx`](admin-panel/src/App.tsx). Login at `/login` (admin email + password → JWT in `localStorage`, key `advok_admin_session`, 8h). `authFetch()` in `utils/auth.ts` attaches the token and clears the session on 401.

| Route | Page | Backed by |
|---|---|---|
| `/` | Dashboard — counts, pending approvals, recent activity | `/admin/*` lists (plus seed helpers for some tiles) |
| `/approvals` | Registration review: advocate / law student / law firm tabs, approve · reject (reason) · reopen, full profile view | `/admin/registrations` |
| `/advocates` | Approved attorneys, suspend / unsuspend / delete | `/admin/users?role=advocate` |
| `/clients` | Clients list and actions | `/admin/users?role=client` |
| `/law-students` | Students list and actions | `/admin/users?role=law_student` |
| `/law-firms` | Firms, their teams, per-firm consultation fee | `/admin/users?role=law_firm`, `/admin/users/:id/firm-fee` |
| `/bookings` | All consultations with filters, detail panel | `/admin/bookings` |
| `/cases` | All cases with parties, status, court | `/admin/cases` |
| `/mentorships` | Student ↔ attorney conversations with filters (active / awaiting reply), search, and a drawer showing the whole conversation | `/admin/mentorships` |
| `/legal-queries` | Law students' legal queries: pending/answered filter, category filter, drawer to write or update the answer (shown as "ADVOK Legal Team" by default), delete | `/admin/queries` |
| `/support` | Support tickets, reply, change status | `/admin/support/tickets` |
| `/revenue` | Revenue overview | Bookings + seed helpers |
| `/content` | Learning Content: **Cases to Read** (search CourtListener opinions, add / edit / publish / reorder, generate & edit study notes), **Legal News** (sources, refresh), **Legal Dictionary** (search, add, rewrite, hide terms; see cached AI explanations) | `/admin/learning/*` |
| `/cms` | Terms, Privacy and other app pages editor | `/admin/cms` |
| `/advok-ai` | Groq connection status, suggested prompts editor | `/admin/ai/*` |
| `/settings` | Consultation pricing, Help & Support contact, "Clear operations" reset | `/admin/pricing`, `/admin/support-contact`, `/admin/operations/clear` |

Key files: `layouts/AdminLayout.tsx` (sidebar + live badges), `components/ui.tsx` (shared table/badge/modal components), `utils/backend.ts` (typed API calls), `utils/realtime.ts` (shared EventSource + `useRealtime(topics, reload)` hook every list page uses), `types/index.ts` (admin-side types).

---

## 9. Mobile app

Source in [`advok_app/lib/`](advok_app/lib/).

```
main.dart / Routes/           App entry and named routes
Services/api_service.dart     All backend calls + Session (token persisted in shared_preferences)
Services/realtime_service.dart  SSE client (auto-connect after login, reconnect with backoff) and the
                              RealtimeRefresh mixin screens use to re-fetch on 'change' events
Services/session_provider.dart, post_login_navigator.dart
                              Auth state and "where to send the user after login"
AppNavigation/                Bottom-tab shells per role
CommonWidgets/                Shared widgets (profile sheets, avatars…)
Utils/CountryData/            CountryCatalog: India vs US terminology, courts, practice areas
Utils/…                       Colors, responsive helpers, toasts, permissions, prefs
Screens/                      All screens (below)
```

### Onboarding screens

| Screen | Purpose |
|---|---|
| `SplashScreen` | Restores a saved session and routes accordingly. |
| `IntroScreens` | First-run intro slides. |
| `SelectCountryScreen` | India / United States — sets terminology, courts, practice areas. |
| `LoginScreen` | Phone + country code, Google, Apple. |
| `OtpScreen` | 6-digit OTP. |
| `ChooseRoleScreen` | Client · Advocate · Law Student · Law Firm. |
| `ClientNameScreen` | Client's name → home. |
| `AdvocateRegistration/*` | Select purpose → Describe yourself (junior/senior, years, firm role) → Professional details (name, email, license, bar admissions, court, practice area) → Practice location → My schedule → Verification submitted. |
| `LawStudentRegistration/*` | Student verification (college, course, year, ID card) → submitted. |
| `LawFirmRegistration/*` | Register firm (details, address, contact) → Add legal team (lawyers) → submitted. |
| `RegistrationStatus/*` | Rejected (with reason) and Suspended screens. |
| `CompleteProfileScreen` | Post-approval profile completion. |

### Client tabs — Home · Search · Messages · Bookings · Profile

- **Home**: welcome, quick actions, upcoming consultation, ADVOK AI entry.
- **Search** (`AdvocateListScreen`, `LawFirmScreen`): browse attorneys and firms, filter by practice area, open profile (`AdvocateProfileScreen`).
- **Booking flow**: `ConsultationTypeScreen` (video / phone / office) → `SelectDatetimeScreen` (attorney's schedule) → `BookingSummaryScreen` (pricing from settings) → `BookingConfirmedScreen`.
- **Messages**: threads and `ChatScreen` (text, system cards, document-request cards with upload).
- **Bookings**: pending / confirmed / completed / cancelled, cancel or mark complete.
- **My Cases** (`ClientCasesScreen`): cases opened for me, read-only Case Details with timeline, documents and court-records card.
- **Profile**: edit profile, Help & Support (`HelpSupportScreen`, `SupportTicketsScreen`), Terms / Privacy (CMS), logout.
- **ADVOK AI** (`AdvokAiScreen`): chat with the Groq-backed assistant; suggested prompts from settings.
- **Notifications** (`NotificationScreen`).

### Advocate tabs — Home · Clients · Messages · Cases · Profile

- **Dashboard**: today's consultations, pending requests (accept / decline), upcoming hearings, stats.
- **Clients**: accepted clients with open-case and session counts.
- **Cases** (`AdvocateCasesScreen`): filter by status; **Add Case** (`AddCaseScreen`, section 7); **Case Details** (`CaseDetailsScreen`): summary, info card (filed, next event, priority, practice area, court, judge), Court Records card (View Docket, Sync Now), timeline (attorney notes + court records), documents (add / remove / request from client), Message Client, Add Update (note, status, priority, next court event).
- **Profile**: edit schedule and details.

### Law firm tabs — Home · Attorneys · Messages · Cases · Firm

- **Dashboard**: consultation requests to the firm; accepting assigns a team attorney.
- **Attorneys** (`FirmLawyersScreen`): the team and which members have linked ADVOK accounts.
- **Cases** (`FirmCasesScreen`, `FirmCaseDetailsScreen`): all cases handled by the firm's attorneys.
- **Firm** (`FirmProfileScreen`): firm details and consultation fee.

### Law student tabs — Home · Advocates/Attorneys · Messages · Queries · Profile

- **Home** (`StudentHomeScreen`): Learning Content (`CaseStudyScreen` reader) and legal news (`NewsArticleScreen`). Tools row:
  - *AI Case Brief* / *Explain Legal Terms* → ADVOK AI chat.
  - *Generate Case Notes* → `CaseNotesPickerScreen` (pick a published case) → `CaseNotesScreen`: IRAC sections (Facts, Issue, Rule, Holding, Reasoning, Significance), tappable key terms, copy-all. Also reachable from a case's reader screen.
  - *Legal Dictionary* → `LegalDictionaryScreen`: search + A–Z browse of ~11k terms → `LegalTermScreen`: historical definition plus "Explain in plain English" by ADVOK AI (cached). Unknown terms go straight to the AI explanation.
  - Internship Portal, Mock Tests, Mentorship Access, Senior Queries: locked until verified (UI only).
- **Attorneys** tab (`AdvocateListScreen`): every verified attorney. On an attorney's profile a law student gets **Message for Guidance** (instead of Book), which opens the chat; the admin sees these conversations under Mentorships.
- **Legal Queries** (`LegalQueriesScreen`): *Ask a Question* (category + question ≤ 500 chars → `POST /queries`) and *My Queries* (pull-to-refresh, Pending/Answered chips, expand to read the ADVOK team's answer). The student is notified when an answer arrives.
- **Profile** (`StudentProfileScreen`).

---

## 10. Deployment notes

- **Backend**: `npm run build && npm start`, or `npm run dev` for hot reload. Bind is `0.0.0.0` so LAN devices can reach it. Set `JWT_SECRET`, `MONGODB_URI`, and (recommended) `S3_BUCKET` in production. The `dist/` build must be rebuilt after source changes when running with `npm start`.
- **Admin panel on Vercel**: env files are gitignored; set `VITE_API_BASE` in the Vercel project and redeploy. The backend has also been deployed at `https://advok-mu.vercel.app/api` (see `admin-panel/.env.production`).
- **CORS** is open (`cors()` default) — restrict origins for production.
- **Real time needs a long-lived server**: the SSE stream works on EC2 / any Node host and behind nginx (`X-Accel-Buffering: no` is set). It does not work on Vercel serverless functions, which cannot hold connections open; there the apps silently fall back to their slow polls / manual refresh.
- **File limits**: JSON body 16 MB (fits a ~10 MB document after base64).
- **CourtListener rate limits**: anonymous access is enough for development; add `COURTLISTENER_API_TOKEN` for production traffic.
