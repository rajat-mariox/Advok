// Loads backend/.env so secrets like GOOGLE_CLIENT_ID can live in a file.
import 'dotenv/config';

export const PORT = Number(process.env.PORT ?? 4000);

// Change this in production — set the JWT_SECRET environment variable.
export const JWT_SECRET = process.env.JWT_SECRET ?? 'advok-dev-secret-change-me';

export const ADMIN_TOKEN_TTL = '8h';
export const APP_TOKEN_TTL = '30d';

export const OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes

// OAuth 2.0 "Web application" client ID from Google Cloud Console — the app
// requests its ID token for this audience and the backend verifies against it.
export const GOOGLE_CLIENT_ID = process.env.GOOGLE_CLIENT_ID ?? '';

// iOS bundle ID the Apple identity token is issued for (the audience). Must
// match PRODUCT_BUNDLE_IDENTIFIER in the iOS project.
export const APPLE_BUNDLE_ID = process.env.APPLE_BUNDLE_ID ?? 'com.example.advokApp';

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

// Seeded admin account (created on first run if missing).
export const SEED_ADMIN_EMAIL = 'admin@advok.com';
export const SEED_ADMIN_PASSWORD = 'Admin@123';
export const SEED_ADMIN_NAME = 'Admin';
