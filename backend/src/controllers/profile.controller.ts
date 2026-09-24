import type { Response } from 'express';
import type { AuthedRequest } from '../middlewares/auth.middleware';
import type {
  AdvocateProfile,
  ClientProfile,
  LawFirmProfile,
  LawStudentProfile,
} from '../models';
import { getDb, saveDb } from '../services/db.service';
import { storePhoto } from '../services/storage.service';
import { str } from '../util/string.util';
import { publicUser } from '../util/user.util';
import { addPushToken, removePushToken } from '../services/push.service';

/**
 * Edit Profile for every app role. Only display fields are editable here —
 * admin-verified credentials (bar license, courts, college ID…) are not.
 *
 * Accepted fields per role:
 * - client:      fullName, email, photo
 * - advocate:    fullName, email, practiceArea, photo
 * - law_student: fullName, college, course, photo
 * - law_firm:    firmName, contactPerson, officialEmail, photo
 *
 * photo: '' removes the picture; omit to keep the current one.
 */
export async function updateProfile(req: AuthedRequest, res: Response) {
  const user = req.user!;
  if (user.role === 'admin' || user.role === null) {
    return res.status(403).json({ error: 'This account cannot edit an app profile' });
  }
  const body = req.body ?? {};

  // Upload the photo to S3 (when configured) before touching the profile.
  if (typeof body.photo === 'string' && body.photo) {
    try {
      body.photo = await storePhoto(body.photo, `photos/${user.id}`);
    } catch (err) {
      console.error('Photo upload to S3 failed:', err);
      return res.status(502).json({ error: 'Photo upload failed, try again' });
    }
  }

  if (user.role === 'client') {
    // Clients have no onboarding, so create the profile on first edit.
    const profile = (user.profile ?? {}) as ClientProfile;
    profile.fullName = str(body.fullName) ?? profile.fullName;
    if (typeof body.email === 'string') {
      profile.email = body.email.includes('@') ? body.email.trim() : profile.email;
    }
    if (typeof body.photo === 'string') profile.photo = body.photo || undefined;
    user.profile = profile;
  } else if (user.role === 'advocate') {
    const profile = user.profile as AdvocateProfile | undefined;
    if (!profile?.professional) {
      return res.status(400).json({ error: 'Complete onboarding before editing your profile' });
    }
    profile.professional.fullName = str(body.fullName) ?? profile.professional.fullName;
    if (typeof body.email === 'string' && body.email.includes('@')) {
      profile.professional.email = body.email.trim();
    }
    profile.professional.practiceArea =
      str(body.practiceArea) ?? profile.professional.practiceArea;
    if (typeof body.photo === 'string') profile.photo = body.photo || undefined;
  } else if (user.role === 'law_student') {
    const profile = user.profile as LawStudentProfile | undefined;
    if (!profile) {
      return res.status(400).json({ error: 'Complete onboarding before editing your profile' });
    }
    profile.fullName = str(body.fullName) ?? profile.fullName;
    profile.college = str(body.college) ?? profile.college;
    profile.course = str(body.course) ?? profile.course;
    if (typeof body.photo === 'string') profile.photo = body.photo || undefined;
  } else {
    const profile = user.profile as LawFirmProfile | undefined;
    if (!profile) {
      return res.status(400).json({ error: 'Complete onboarding before editing your profile' });
    }
    profile.firmName = str(body.firmName) ?? profile.firmName;
    profile.contactPerson = str(body.contactPerson) ?? profile.contactPerson;
    if (typeof body.officialEmail === 'string' && body.officialEmail.includes('@')) {
      profile.officialEmail = body.officialEmail.trim();
    }
    if (typeof body.photo === 'string') profile.photo = body.photo || undefined;
  }

  saveDb();
  return res.json({ user: publicUser(user) });
}

/** POST /profile/push-token — body { token, platform }: register this device for push. */
export function registerPushToken(req: AuthedRequest, res: Response) {
  const user = req.user!;
  const token = typeof req.body?.token === 'string' ? req.body.token.trim() : '';
  const platform = typeof req.body?.platform === 'string' ? req.body.platform.trim().slice(0, 20) : 'unknown';
  if (!token || token.length > 4096) return res.status(400).json({ error: 'token is required' });
  const db = getDb();
  // A device belongs to one account at a time (shared phones, re-login).
  removePushToken(db, token);
  addPushToken(user, token, platform);
  saveDb();
  return res.json({ ok: true });
}

/** DELETE /profile/push-token — body { token }: stop pushes to this device (logout). */
export function unregisterPushToken(req: AuthedRequest, res: Response) {
  const token = typeof req.body?.token === 'string' ? req.body.token.trim() : '';
  if (!token) return res.status(400).json({ error: 'token is required' });
  removePushToken(getDb(), token);
  saveDb();
  return res.json({ ok: true });
}
