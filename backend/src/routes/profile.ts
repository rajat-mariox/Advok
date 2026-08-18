import { Router } from 'express';
import { publicUser, saveDb } from '../db';
import { requireAuth, type AuthedRequest } from '../middleware/auth';
import { storePhoto } from '../storage';
import type {
  AdvocateProfile,
  ClientProfile,
  LawFirmProfile,
  LawStudentProfile,
} from '../types';

const router = Router();

const str = (v: unknown): string | undefined =>
  typeof v === 'string' && v.trim() ? v.trim() : undefined;

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
router.put('/', requireAuth, async (req: AuthedRequest, res) => {
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
});

export default router;
