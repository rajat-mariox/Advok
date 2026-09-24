// Loads backend/.env so secrets like GOOGLE_CLIENT_ID can live in a file.
import 'dotenv/config';

export const PORT = Number(process.env.PORT ?? 4000);

// Change this in production — set the JWT_SECRET environment variable.
export const JWT_SECRET = process.env.JWT_SECRET ?? 'advok-dev-secret-change-me';

export const ADMIN_TOKEN_TTL = '8h';
export const APP_TOKEN_TTL = '30d';

export const OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes

// ---- Google Sign-In ----
// GOOGLE_CLIENT_ID: OAuth 2.0 "Web application" client ID. The app asks
// Google for an ID token issued to this audience (serverClientId) and the
// backend verifies against it. The app reads it from GET /auth/config, so it
// only has to be set here.
// GOOGLE_IOS_CLIENT_ID: the "iOS" OAuth client (needed by the iOS app).
// GOOGLE_ANDROID_CLIENT_ID: the "Android" OAuth client (package name + SHA-1);
// Google only needs it to exist, but it is also accepted as a token audience.
const list = (v: string | undefined) =>
  (v ?? '')
    .split(',')
    .map((x) => x.trim())
    .filter(Boolean);
export const GOOGLE_CLIENT_ID = (process.env.GOOGLE_CLIENT_ID ?? '').trim();
export const GOOGLE_IOS_CLIENT_ID = (process.env.GOOGLE_IOS_CLIENT_ID ?? '').trim();
export const GOOGLE_ANDROID_CLIENT_ID = (process.env.GOOGLE_ANDROID_CLIENT_ID ?? '').trim();
/** Every client ID a Google ID token may be issued to. */
export const GOOGLE_AUDIENCES = [GOOGLE_CLIENT_ID, GOOGLE_IOS_CLIENT_ID, GOOGLE_ANDROID_CLIENT_ID, ...list(process.env.GOOGLE_EXTRA_CLIENT_IDS)].filter(Boolean);

// ---- Sign in with Apple ----
// APPLE_BUNDLE_ID: the iOS app's bundle ID (identity tokens from the iPhone
// app are issued to it). APPLE_SERVICE_ID: optional Services ID, only for
// Apple login on web/Android. APPLE_TEAM_ID is informational.
export const APPLE_BUNDLE_ID = (process.env.APPLE_BUNDLE_ID ?? 'com.example.advokApp').trim();
export const APPLE_SERVICE_ID = (process.env.APPLE_SERVICE_ID ?? '').trim();
export const APPLE_TEAM_ID = (process.env.APPLE_TEAM_ID ?? '').trim();
export const APPLE_AUDIENCES = [APPLE_BUNDLE_ID, APPLE_SERVICE_ID].filter(Boolean);

// MongoDB — set MONGODB_URI to store data in MongoDB (Atlas or self-hosted).
// Without it, data lives in backend/data/db.json exactly as before.
export const MONGODB_URI = process.env.MONGODB_URI ?? '';
export const MONGODB_DB = process.env.MONGODB_DB ?? 'advok';

// S3 photo storage — set S3_BUCKET to upload profile photos to S3 instead of
// keeping them as base64 inside db.json. Credentials come from the standard
// AWS env vars (AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY) or, on EC2, the
// instance's IAM role — the SDK picks them up automatically.
export const AWS_REGION = process.env.AWS_REGION ?? 'ap-south-1';
export const S3_BUCKET = process.env.S3_BUCKET ?? '';

// Optional: base URL the uploaded files are served from (CloudFront or a
// custom domain). Defaults to the bucket's own S3 URL.
export const S3_PUBLIC_URL = (process.env.S3_PUBLIC_URL ?? '').replace(/\/+$/, '');

// CourtListener (Free Law Project) — docket lookup on Add Case and the
// court-records sync that keeps linked cases' status/timeline up to date.
// The search API works without a token (lower rate limit); a free token from
// courtlistener.com raises the limit. Optional.
export const COURTLISTENER_API_TOKEN = (process.env.COURTLISTENER_API_TOKEN ?? '').trim();
// How often (minutes) linked open cases are re-synced from court records.
// Default 12h; 0 disables the scheduler (manual "Sync Now" still works).
export const COURT_SYNC_INTERVAL_MINUTES = Number(
  process.env.COURT_SYNC_INTERVAL_MINUTES ?? 720,
);

// ADVOK AI — the in-app legal assistant, case notes and dictionary
// explanations. Two OpenAI-compatible providers are supported; the first key
// found wins:
//   OPENAI_API_KEY  -> OpenAI (platform.openai.com), default model gpt-4o-mini
//   GROQ_API_KEY    -> Groq (console.groq.com), default model openai/gpt-oss-120b
// Without either the app shows the "not connected" placeholder.
export const OPENAI_API_KEY = (process.env.OPENAI_API_KEY ?? '').trim();
export const OPENAI_MODEL = process.env.OPENAI_MODEL ?? 'gpt-4o-mini';
export const GROQ_API_KEY = (process.env.GROQ_API_KEY ?? '').trim();
export const GROQ_MODEL = process.env.GROQ_MODEL ?? 'openai/gpt-oss-120b';

export type AiProvider = 'openai' | 'groq' | 'none';
export const AI_PROVIDER: AiProvider = OPENAI_API_KEY ? 'openai' : GROQ_API_KEY ? 'groq' : 'none';
export const AI_API_KEY = AI_PROVIDER === 'openai' ? OPENAI_API_KEY : GROQ_API_KEY;
export const AI_MODEL = AI_PROVIDER === 'openai' ? OPENAI_MODEL : GROQ_MODEL;
export const AI_API_URL =
  AI_PROVIDER === 'openai'
    ? 'https://api.openai.com/v1/chat/completions'
    : 'https://api.groq.com/openai/v1/chat/completions';

// Seeded admin account (created on first run if missing).
export const SEED_ADMIN_EMAIL = 'admin@advok.com';
export const SEED_ADMIN_PASSWORD = 'Admin@123';
export const SEED_ADMIN_NAME = 'Admin';

// ---- Notifications ----
export const APP_NAME = (process.env.APP_NAME ?? 'ADVOK').trim();
// Push (FCM): path to the Firebase service-account JSON, or the JSON inline.
export const FIREBASE_SERVICE_ACCOUNT = (process.env.FIREBASE_SERVICE_ACCOUNT ?? '').trim();
// Firebase client options for the app (public values from the Firebase
// console's app settings). Served to the app by GET /auth/config.
export const FIREBASE_PROJECT_ID = (process.env.FIREBASE_PROJECT_ID ?? '').trim();
export const FIREBASE_MESSAGING_SENDER_ID = (process.env.FIREBASE_MESSAGING_SENDER_ID ?? '').trim();
export const FIREBASE_ANDROID_API_KEY = (process.env.FIREBASE_ANDROID_API_KEY ?? '').trim();
export const FIREBASE_ANDROID_APP_ID = (process.env.FIREBASE_ANDROID_APP_ID ?? '').trim();
export const FIREBASE_IOS_API_KEY = (process.env.FIREBASE_IOS_API_KEY ?? '').trim();
export const FIREBASE_IOS_APP_ID = (process.env.FIREBASE_IOS_APP_ID ?? '').trim();
// Email over SMTP (AWS SES, SendGrid, Gmail…).
export const SMTP_HOST = (process.env.SMTP_HOST ?? '').trim();
export const SMTP_PORT = Number(process.env.SMTP_PORT ?? 587);
export const SMTP_SECURE = (process.env.SMTP_SECURE ?? '').trim() === 'true' || Number(process.env.SMTP_PORT) === 465;
export const SMTP_USER = (process.env.SMTP_USER ?? '').trim();
export const SMTP_PASS = (process.env.SMTP_PASS ?? '').trim();
export const MAIL_FROM = (process.env.MAIL_FROM ?? '').trim();
