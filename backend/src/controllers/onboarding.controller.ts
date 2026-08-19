import type { Response } from 'express';
import type { AuthedRequest } from '../middlewares/auth.middleware';
import type {
  AdvocateProfile,
  LawFirmProfile,
  LawStudentProfile,
} from '../models';
import { saveDb } from '../services/db.service';
import { storePhoto } from '../services/storage.service';
import {
  missingFields,
  parseBarAdmissions,
  parseFederalCourtAdmissions,
} from '../validators/onboarding.validator';

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
export async function submitAdvocate(req: AuthedRequest, res: Response) {
  const body = req.body ?? {};
  // Older app builds sent the license as `barRegistrationNumber`.
  if (body.professional && body.professional.licenseNumber == null) {
    body.professional.licenseNumber = body.professional.barRegistrationNumber;
  }
  // US flow: structured state bar admissions (state + bar number + license
  // status) plus optional federal court admissions. The first admission also
  // backfills the legacy licenseNumber/primaryCourt fields if the app didn't.
  const barAdmissions = parseBarAdmissions(body.professional?.barAdmissions);
  const federalCourtAdmissions = parseFederalCourtAdmissions(
    body.professional?.federalCourtAdmissions,
  );
  if (body.professional && barAdmissions.length) {
    if (body.professional.licenseNumber == null) {
      body.professional.licenseNumber = barAdmissions[0].barNumber;
    }
    if (body.professional.primaryCourt == null) {
      body.professional.primaryCourt = `${barAdmissions[0].state} State Bar`;
    }
  }
  if (typeof body.photo === 'string' && body.photo) {
    try {
      body.photo = await storePhoto(body.photo, `photos/${req.user!.id}`);
    } catch (err) {
      console.error('Photo upload to S3 failed:', err);
      return res.status(502).json({ error: 'Photo upload failed, try again' });
    }
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
      barAdmissions: barAdmissions.length ? barAdmissions : undefined,
      federalCourtAdmissions: federalCourtAdmissions.length ? federalCourtAdmissions : undefined,
    },
    schedule: {
      workingDays: Array.isArray(body.schedule?.workingDays) ? body.schedule.workingDays : [],
      startTime: body.schedule?.startTime ?? '',
      endTime: body.schedule?.endTime ?? '',
    },
  };
  const user = submit(req, profile);
  return res.json({ status: user.status, message: 'Advocate onboarding submitted for review' });
}

/** Law student onboarding — verification details + ID card. */
export function submitLawStudent(req: AuthedRequest, res: Response) {
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
}

/** Law firm onboarding — firm details + legal team. */
export function submitLawFirm(req: AuthedRequest, res: Response) {
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
}

/** App polls this to know whether the admin has approved/rejected the account. */
export function onboardingStatus(req: AuthedRequest, res: Response) {
  const user = req.user!;
  return res.json({
    role: user.role,
    status: user.status,
    rejectionReason: user.rejectionReason ?? null,
  });
}
