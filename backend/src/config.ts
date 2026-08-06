export const PORT = Number(process.env.PORT ?? 4000);

// Change this in production — set the JWT_SECRET environment variable.
export const JWT_SECRET = process.env.JWT_SECRET ?? 'advok-dev-secret-change-me';

export const ADMIN_TOKEN_TTL = '8h';
export const APP_TOKEN_TTL = '30d';

export const OTP_TTL_MS = 5 * 60 * 1000; // 5 minutes

// Seeded admin account (created on first run if missing).
export const SEED_ADMIN_EMAIL = 'admin@advok.com';
export const SEED_ADMIN_PASSWORD = 'Admin@123';
export const SEED_ADMIN_NAME = 'Admin';
