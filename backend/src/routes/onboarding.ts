import { Router } from 'express';
import { saveDb } from '../db';
import { requireRole, type AuthedRequest } from '../middleware/auth';
import type { AdvocateProfile, LawFirmProfile, LawStudentProfile } from '../types';

const router = Router();

function missingFields(body: Record<string, unknown>, fields: string[]): string[] {
  return fields.filter((f) => {
    const value = f.split('.').reduce<unknown>((obj, key) => {
      if (obj && typeof obj === 'object') return (obj as Record<string, unknown>)[key];
      return undefined;
    }, body);
    return value === undefined || value === null || value === '';
  });
}

function submit(req: AuthedRequest, profile: AdvocateProfile | LawStudentProfile | LawFirmProfile) {
  const user = req.user!;
  user.profile = profile;
  user.status = 'pending_approval';
  user.onboardedAt = new Date().toISOString();
  user.rejectionReason = undefined;
  saveDb();
  return user;
}

/** Advocate onboarding — the aggregated data of all 5 registration steps. */
router.post('/advocate', requireRole('advocate'), (req: AuthedRequest, res) => {
  const body = req.body ?? {};
  // Older app builds sent the license as `barRegistrationNumber`.
  if (body.professional && body.professional.licenseNumber == null) {
    body.professional.licenseNumber = body.professional.barRegistrationNumber;
  }
  const missing = missingFields(body, [
    'advocateType',
    'location.state',
    'location.district',
    'professional.fullName',
    'professional.email',
    'professional.licenseNumber',
    'professional.primaryCourt',
    'professional.practiceArea',
  ]);
  if (missing.length) {
    return res.status(400).json({ error: `Missing fields: ${missing.join(', ')}` });
  }
  const profile: AdvocateProfile = {
    advocateType: body.advocateType,
    photo: typeof body.photo === 'string' && body.photo ? body.photo : undefined,
    yearsInPractice: typeof body.yearsInPractice === 'string' ? body.yearsInPractice : undefined,
    firmRole: typeof body.firmRole === 'string' ? body.firmRole : undefined,
    purposes: Array.isArray(body.purposes) ? body.purposes : [],
    location: {
      state: body.location.state,
      district: body.location.district,
      officeAddress: body.location.officeAddress ?? '',
    },
    professional: {
      fullName: body.professional.fullName,
      seniorAdvocateName: body.professional.seniorAdvocateName,
      email: body.professional.email,
      licenseNumber: body.professional.licenseNumber,
      primaryCourt: body.professional.primaryCourt,
      practiceArea: body.professional.practiceArea,
    },
    schedule: {
      workingDays: Array.isArray(body.schedule?.workingDays) ? body.schedule.workingDays : [],
      startTime: body.schedule?.startTime ?? '',
      endTime: body.schedule?.endTime ?? '',
    },
  };
  const user = submit(req, profile);
  return res.json({ status: user.status, message: 'Advocate onboarding submitted for review' });
});

/** Law student onboarding — verification details + ID card. */
router.post('/law-student', requireRole('law_student'), (req: AuthedRequest, res) => {
  const body = req.body ?? {};
  const missing = missingFields(body, ['fullName', 'college', 'course', 'academicYear']);
  if (missing.length) {
    return res.status(400).json({ error: `Missing fields: ${missing.join(', ')}` });
  }
  const profile: LawStudentProfile = {
    fullName: body.fullName,
    college: body.college,
    course: body.course,
    academicYear: body.academicYear,
    idCardFileName: body.idCardFileName ?? '',
  };
  const user = submit(req, profile);
  return res.json({ status: user.status, message: 'Student verification submitted for review' });
});

/** Law firm onboarding — firm details + legal team. */
router.post('/law-firm', requireRole('law_firm'), (req: AuthedRequest, res) => {
  const body = req.body ?? {};
  const missing = missingFields(body, [
    'firmName',
    'foundedYear',
    'contactPerson',
    'officialEmail',
    'mainPhone',
    'addressLine1',
    'city',
    'state',
  ]);
  if (missing.length) {
    return res.status(400).json({ error: `Missing fields: ${missing.join(', ')}` });
  }
  const profile: LawFirmProfile = {
    firmName: body.firmName,
    foundedYear: body.foundedYear,
    contactPerson: body.contactPerson,
    logoFileName: body.logoFileName,
    officialEmail: body.officialEmail,
    mainPhone: body.mainPhone,
    receptionNumber: body.receptionNumber,
    addressLine1: body.addressLine1,
    addressLine2: body.addressLine2,
    city: body.city,
    zip: body.zip ?? '',
    state: body.state,
    totalLawyers: body.totalLawyers ?? '',
    lawyers: Array.isArray(body.lawyers) ? body.lawyers : [],
  };
  const user = submit(req, profile);
  return res.json({ status: user.status, message: 'Firm registration submitted for review' });
});

/** App polls this to know whether the admin has approved/rejected the account. */
router.get('/status', requireRole('advocate', 'law_student', 'law_firm', 'client'), (req: AuthedRequest, res) => {
  const user = req.user!;
  return res.json({
    role: user.role,
    status: user.status,
    rejectionReason: user.rejectionReason ?? null,
  });
});

export default router;
