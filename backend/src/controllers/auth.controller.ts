import appleSignin from 'apple-signin-auth';
import bcrypt from 'bcryptjs';
import type { Request, Response } from 'express';
import { OAuth2Client } from 'google-auth-library';
import {
  ADMIN_TOKEN_TTL,
  APPLE_AUDIENCES,
  APP_TOKEN_TTL,
  FIREBASE_ANDROID_API_KEY,
  FIREBASE_ANDROID_APP_ID,
  FIREBASE_IOS_API_KEY,
  FIREBASE_IOS_APP_ID,
  FIREBASE_MESSAGING_SENDER_ID,
  FIREBASE_PROJECT_ID,
  GOOGLE_AUDIENCES,
  GOOGLE_CLIENT_ID,
  GOOGLE_IOS_CLIENT_ID,
  OTP_TTL_MS,
  APP_NAME,
} from '../config';
import { isSmsConfigured, sendSms, toE164 } from '../services/sms.service';
import type { AuthedRequest } from '../middlewares/auth.middleware';
import type { Role } from '../models';
import { createId, getDb, saveDb } from '../services/db.service';
import { signToken } from '../services/token.service';
import { linkFirmAttorney } from '../services/firm.service';
import { publicUser } from '../util/user.util';
import { isValidPhone } from '../validators/auth.validator';

const APP_ROLES: Role[] = ['client', 'advocate', 'law_student', 'law_firm'];

/** Admin panel login: email + password. */
export function adminLogin(req: Request, res: Response) {
  const { email, password } = req.body ?? {};
  if (typeof email !== 'string' || typeof password !== 'string') {
    return res.status(400).json({ error: 'email and password are required' });
  }
  const db = getDb();
  const admin = db.users.find(
    (u) => u.role === 'admin' && u.email?.toLowerCase() === email.trim().toLowerCase(),
  );
  if (!admin?.passwordHash || !bcrypt.compareSync(password, admin.passwordHash)) {
    return res.status(401).json({ error: 'Invalid email or password' });
  }
  const token = signToken(admin.id, ADMIN_TOKEN_TTL);
  return res.json({
    token,
    expiresAt: Date.now() + 8 * 60 * 60 * 1000,
    user: publicUser(admin),
  });
}

/** App login step 1: request an OTP for a phone number. */
export async function sendOtp(req: Request, res: Response) {
  const { phone, countryCode, country } = req.body ?? {};
  if (!isValidPhone(phone)) {
    return res.status(400).json({ error: 'A valid phone number is required' });
  }
  const cc = typeof countryCode === 'string' ? countryCode : '';
  const otp = String(Math.floor(100000 + Math.random() * 900000));

  // With Twilio configured the code goes out by SMS and is never returned
  // to the app. Without it (local/prototype) it is logged and sent back as
  // devOtp so the app can prefill it.
  if (isSmsConfigured()) {
    try {
      await sendSms(
        toE164(cc, phone),
        `${APP_NAME}: your verification code is ${otp}. It expires in ${Math.round(OTP_TTL_MS / 60000)} minutes.`,
      );
    } catch (err) {
      const msg = err instanceof Error ? err.message : 'SMS delivery failed';
      console.error(`[OTP] SMS to ${cc}${phone} failed: ${msg}`);
      return res.status(502).json({ error: `Could not send the SMS: ${msg}` });
    }
  }

  const db = getDb();
  db.otps = db.otps.filter((o) => o.phone !== phone);
  db.otps.push({
    phone,
    countryCode: cc,
    country: typeof country === 'string' ? country : undefined,
    otp,
    expiresAt: Date.now() + OTP_TTL_MS,
  });
  saveDb();
  if (isSmsConfigured()) return res.json({ message: 'OTP sent' });
  console.log(`[OTP] ${cc}${phone} -> ${otp}`);
  return res.json({ message: 'OTP sent', devOtp: otp });
}

/** App login step 2: verify OTP. Creates the user on first login. */
export function verifyOtp(req: Request, res: Response) {
  const { phone, otp } = req.body ?? {};
  if (typeof phone !== 'string' || typeof otp !== 'string') {
    return res.status(400).json({ error: 'phone and otp are required' });
  }
  const db = getDb();
  const record = db.otps.find((o) => o.phone === phone);
  if (!record || record.otp !== otp || Date.now() > record.expiresAt) {
    return res.status(401).json({ error: 'Invalid or expired OTP' });
  }
  db.otps = db.otps.filter((o) => o.phone !== phone);

  let user = db.users.find((u) => u.phone === phone);
  if (!user) {
    user = {
      id: createId(),
      role: null,
      status: 'new',
      phone,
      countryCode: record.countryCode,
      country: record.country,
      createdAt: new Date().toISOString(),
    };
    db.users.push(user);
  } else if (!user.country && record.country) {
    // Backfill accounts created before country tracking; never overwrite an
    // existing country — the account's legal flow must stay stable.
    user.country = record.country;
  }
  // A phone number on an approved law firm's team signs in as that firm's
  // attorney — no onboarding, the firm already vouched for them.
  linkFirmAttorney(db, user);
  saveDb();
  const token = signToken(user.id, APP_TOKEN_TTL);
  return res.json({ token, user: publicUser(user) });
}

const googleClient = new OAuth2Client();

/**
 * App login with Google. The app sends the ID token it got from Google
 * Sign-In; we verify it with Google, then find or create the user — the same
 * outcome as verify-otp, so the app's post-login routing works unchanged.
 */
export async function googleLogin(req: Request, res: Response) {
  const { idToken, country } = req.body ?? {};
  if (typeof idToken !== 'string' || !idToken) {
    return res.status(400).json({ error: 'idToken is required' });
  }
  if (GOOGLE_AUDIENCES.length === 0) {
    return res
      .status(503)
      .json({ error: 'Google login is not configured (set GOOGLE_CLIENT_ID in backend/.env)' });
  }

  let payload;
  try {
    const ticket = await googleClient.verifyIdToken({
      idToken,
      audience: GOOGLE_AUDIENCES,
    });
    payload = ticket.getPayload();
  } catch {
    return res.status(401).json({ error: 'Google sign-in could not be verified' });
  }
  const googleId = payload?.sub;
  const email = payload?.email?.toLowerCase();
  if (!googleId || !email || payload?.email_verified === false) {
    return res.status(401).json({ error: 'Google account has no verified email' });
  }

  const db = getDb();
  // Match by Google ID first, then link by email to an account that signed up
  // another way. Admin accounts stay out of the app login entirely.
  let user =
    db.users.find((u) => u.googleId === googleId) ??
    db.users.find(
      (u) => u.role !== 'admin' && u.email?.toLowerCase() === email,
    );
  if (user?.role === 'admin') {
    return res.status(403).json({ error: 'This account cannot log in to the app' });
  }
  if (!user) {
    user = {
      id: createId(),
      role: null,
      status: 'new',
      googleId,
      email,
      name: typeof payload?.name === 'string' ? payload.name : undefined,
      country: typeof country === 'string' && country ? country : undefined,
      createdAt: new Date().toISOString(),
    };
    db.users.push(user);
  } else {
    user.googleId ??= googleId;
    user.email ??= email;
    if (!user.name && typeof payload?.name === 'string') user.name = payload.name;
    // Same backfill rule as verify-otp: never overwrite an existing country.
    if (!user.country && typeof country === 'string' && country) {
      user.country = country;
    }
  }
  saveDb();
  const token = signToken(user.id, APP_TOKEN_TTL);
  return res.json({ token, user: publicUser(user) });
}

/**
 * App login with Apple. The app sends the identity token from Sign in with
 * Apple; we verify its signature against Apple's public keys and find or
 * create the user. Apple only provides the person's name on the very first
 * sign-in (and only to the app, not inside the token), so the app forwards it
 * as fullName and we store it right away — later logins won't include it.
 */
export async function appleLogin(req: Request, res: Response) {
  const { identityToken, fullName, country } = req.body ?? {};
  if (typeof identityToken !== 'string' || !identityToken) {
    return res.status(400).json({ error: 'identityToken is required' });
  }

  let payload;
  try {
    payload = await appleSignin.verifyIdToken(identityToken, {
      audience: APPLE_AUDIENCES,
      ignoreExpiration: false,
    });
  } catch {
    return res.status(401).json({ error: 'Apple sign-in could not be verified' });
  }
  const appleId = payload.sub;
  if (!appleId) {
    return res.status(401).json({ error: 'Apple sign-in could not be verified' });
  }
  // May be a private relay address (user chose "Hide My Email"), or absent.
  const email =
    typeof payload.email === 'string' ? payload.email.toLowerCase() : undefined;

  const db = getDb();
  // Match by Apple ID first, then link by email to an account that signed up
  // another way. Admin accounts stay out of the app login entirely.
  let user =
    db.users.find((u) => u.appleId === appleId) ??
    (email
      ? db.users.find(
          (u) => u.role !== 'admin' && u.email?.toLowerCase() === email,
        )
      : undefined);
  if (user?.role === 'admin') {
    return res.status(403).json({ error: 'This account cannot log in to the app' });
  }
  if (!user) {
    user = {
      id: createId(),
      role: null,
      status: 'new',
      appleId,
      email,
      name:
        typeof fullName === 'string' && fullName.trim()
          ? fullName.trim()
          : undefined,
      country: typeof country === 'string' && country ? country : undefined,
      createdAt: new Date().toISOString(),
    };
    db.users.push(user);
  } else {
    user.appleId ??= appleId;
    user.email ??= email;
    if (!user.name && typeof fullName === 'string' && fullName.trim()) {
      user.name = fullName.trim();
    }
    // Same backfill rule as verify-otp: never overwrite an existing country.
    if (!user.country && typeof country === 'string' && country) {
      user.country = country;
    }
  }
  saveDb();
  const token = signToken(user.id, APP_TOKEN_TTL);
  return res.json({ token, user: publicUser(user) });
}

/** App login step 3: choose a role (first login only). */
export function selectRole(req: AuthedRequest, res: Response) {
  const { role } = req.body ?? {};
  const user = req.user!;
  if (!APP_ROLES.includes(role)) {
    return res.status(400).json({ error: `role must be one of: ${APP_ROLES.join(', ')}` });
  }
  if (user.role === 'admin') {
    return res.status(403).json({ error: 'Admins cannot select an app role' });
  }
  if (user.role && user.role !== role) {
    return res.status(409).json({ error: `Account is already registered as ${user.role}` });
  }
  user.role = role;
  if (user.status === 'new') {
    // Clients need no onboarding; the other roles must submit onboarding next.
    user.status = role === 'client' ? 'active' : 'onboarding_required';
  }
  saveDb();
  return res.json({ user: publicUser(user) });
}

/** Current authenticated user. */
export function me(req: AuthedRequest, res: Response) {
  return res.json({ user: publicUser(req.user!) });
}

/**
 * GET /auth/config — public sign-in settings the app needs at runtime, so
 * the Google client IDs live only in backend/.env (never in the app build).
 */
export function authConfig(_req: Request, res: Response) {
  return res.json({
    google: {
      enabled: GOOGLE_CLIENT_ID.length > 0,
      webClientId: GOOGLE_CLIENT_ID || null,
      iosClientId: GOOGLE_IOS_CLIENT_ID || null,
    },
    apple: {
      enabled: APPLE_AUDIENCES.length > 0,
    },
    // Public Firebase client options so the app can register for push
    // without bundling google-services files. null → push disabled.
    firebase:
      FIREBASE_PROJECT_ID && FIREBASE_MESSAGING_SENDER_ID
        ? {
            projectId: FIREBASE_PROJECT_ID,
            messagingSenderId: FIREBASE_MESSAGING_SENDER_ID,
            android: FIREBASE_ANDROID_APP_ID ? { apiKey: FIREBASE_ANDROID_API_KEY, appId: FIREBASE_ANDROID_APP_ID } : null,
            ios: FIREBASE_IOS_APP_ID ? { apiKey: FIREBASE_IOS_API_KEY, appId: FIREBASE_IOS_APP_ID } : null,
          }
        : null,
  });
}
