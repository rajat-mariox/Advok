import bcrypt from 'bcryptjs';
import { Router } from 'express';
import jwt from 'jsonwebtoken';
import { ADMIN_TOKEN_TTL, APP_TOKEN_TTL, JWT_SECRET, OTP_TTL_MS } from '../config';
import { createId, getDb, publicUser, saveDb } from '../db';
import { requireAuth, type AuthedRequest } from '../middleware/auth';
import type { Role } from '../types';

const router = Router();

const APP_ROLES: Role[] = ['client', 'advocate', 'law_student', 'law_firm'];

function signToken(userId: string, ttl: string): string {
  return jwt.sign({ sub: userId }, JWT_SECRET, { expiresIn: ttl } as jwt.SignOptions);
}

/** Admin panel login: email + password. */
router.post('/admin/login', (req, res) => {
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
});

/** App login step 1: request an OTP for a phone number. */
router.post('/send-otp', (req, res) => {
  const { phone, countryCode, country } = req.body ?? {};
  if (typeof phone !== 'string' || phone.replace(/\D/g, '').length < 6) {
    return res.status(400).json({ error: 'A valid phone number is required' });
  }
  const db = getDb();
  const otp = String(Math.floor(100000 + Math.random() * 900000));
  db.otps = db.otps.filter((o) => o.phone !== phone);
  db.otps.push({
    phone,
    countryCode: typeof countryCode === 'string' ? countryCode : '',
    country: typeof country === 'string' ? country : undefined,
    otp,
    expiresAt: Date.now() + OTP_TTL_MS,
  });
  saveDb();
  // No SMS gateway in this prototype — the OTP is logged and returned as devOtp.
  console.log(`[OTP] ${countryCode ?? ''}${phone} -> ${otp}`);
  return res.json({ message: 'OTP sent', devOtp: otp });
});

/** App login step 2: verify OTP. Creates the user on first login. */
router.post('/verify-otp', (req, res) => {
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
  saveDb();
  const token = signToken(user.id, APP_TOKEN_TTL);
  return res.json({ token, user: publicUser(user) });
});

/** App login step 3: choose a role (first login only). */
router.post('/select-role', requireAuth, (req: AuthedRequest, res) => {
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
});

/** Current authenticated user. */
router.get('/me', requireAuth, (req: AuthedRequest, res) => {
  return res.json({ user: publicUser(req.user!) });
});

export default router;
