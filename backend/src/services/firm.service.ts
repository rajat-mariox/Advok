// Law-firm ↔ attorney linking.
//
// A firm lists its attorneys (name, phone, bar number…) at registration.
// When one of those attorneys signs in to ADVOK with the same phone number,
// the account becomes an approved attorney tied to the firm: the profile is
// built from the firm's entry (the firm already vouched for them) and
// `firmId` / `firmName` are set so the app can show "at <Firm>".
import type { AdvocateProfile, DbShape, FirmLawyer, LawFirmProfile, User } from '../models';

/** Digits only, last 10 — so "(555) 000-0000", "+1 5550000000" all match. */
export function phoneKey(raw: string | undefined | null): string {
  const digits = (raw ?? '').replace(/\D/g, '');
  return digits.length > 10 ? digits.slice(-10) : digits;
}

export interface FirmAttorneyMatch {
  firm: User;
  profile: LawFirmProfile;
  entry: FirmLawyer;
  index: number;
}

/** The approved firm whose team lists this phone number, if any. */
export function findFirmForPhone(db: DbShape, phone: string | undefined): FirmAttorneyMatch | null {
  const key = phoneKey(phone);
  if (key.length < 7) return null;
  for (const firm of db.users) {
    if (firm.role !== 'law_firm' || !firm.profile) continue;
    if (firm.status !== 'approved' && firm.status !== 'active') continue;
    const profile = firm.profile as LawFirmProfile;
    const index = (profile.lawyers ?? []).findIndex((l) => phoneKey(l.phone) === key);
    if (index >= 0) return { firm, profile, entry: profile.lawyers[index], index };
  }
  return null;
}

/** Practice area for a firm attorney: first expertise, else the firm's. */
function practiceAreaFor(entry: FirmLawyer, profile: LawFirmProfile): string {
  const own = (entry.expertise ?? []).find((e) => e.trim());
  if (own) return own.trim();
  const any = (profile.lawyers ?? []).flatMap((l) => l.expertise ?? []).find((e) => e.trim());
  return any?.trim() || 'General Practice';
}

/** Builds an attorney profile from what the firm entered for this person. */
export function profileFromFirmEntry(match: FirmAttorneyMatch): AdvocateProfile {
  const { entry, profile, firm } = match;
  const years = Number(entry.yearsExperience) || 0;
  return {
    advocateType: years >= 10 ? 'senior' : 'junior',
    photo: undefined,
    yearsInPractice:
      years >= 20 ? '20+ years' : years >= 11 ? '11–20 years' : years >= 6 ? '6–10 years' : years >= 3 ? '3–5 years' : '0–2 years',
    firmRole: entry.designation || 'Associate',
    purposes: ['Consultations', 'Manage cases'],
    location: {
      state: entry.barState || profile.state || '',
      district: profile.city || '',
      officeAddress: [profile.addressLine1, profile.addressLine2, profile.city, profile.state, profile.zip]
        .filter((x): x is string => !!x && x.trim().length > 0)
        .join(', '),
    },
    professional: {
      fullName: entry.fullName,
      email: entry.email || profile.officialEmail || firm.email || '',
      licenseNumber: entry.barLicense || '',
      primaryCourt: entry.barState ? `${entry.barState} State Bar` : 'State Bar',
      practiceArea: practiceAreaFor(entry, profile),
      barAdmissions: entry.barState || entry.barLicense
        ? [{ state: entry.barState || profile.state || '', barNumber: entry.barLicense || '', licenseStatus: entry.licenseStatus || 'Active' }]
        : [],
      federalCourtAdmissions: [],
    },
    schedule: { workingDays: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'], startTime: '09:00', endTime: '17:00' },
  };
}

/**
 * Called on every phone login. Links the account to its firm when the number
 * is on an approved firm's team:
 * - brand-new account → becomes an approved attorney with a profile from the
 *   firm entry (no onboarding, no admin review: the firm vouched for them);
 * - existing attorney account → just gets firmId/firmName.
 * Returns true when the user record changed.
 */
export function linkFirmAttorney(db: DbShape, user: User): boolean {
  if (user.role === 'admin' || user.firmId) return false;
  const match = findFirmForPhone(db, user.phone);
  if (!match) return false;
  const firmName = match.profile.firmName?.trim() || 'Law Firm';
  if (!user.role || user.status === 'new') {
    user.role = 'advocate';
    user.status = 'approved';
    user.profile = profileFromFirmEntry(match);
    user.name ??= match.entry.fullName;
    user.email ??= match.entry.email || undefined;
    user.onboardedAt ??= new Date().toISOString();
    user.reviewedAt ??= new Date().toISOString();
  } else if (user.role !== 'advocate') {
    return false;
  }
  user.firmId = match.firm.id;
  user.firmName = firmName;
  return true;
}

/** The linked attorney account for a firm team entry, if they have signed in. */
export function findLinkedAttorney(db: DbShape, firmId: string, entry: FirmLawyer): User | undefined {
  const key = phoneKey(entry.phone);
  if (key.length < 7) return undefined;
  return db.users.find(
    (u) => u.role === 'advocate' && u.firmId === firmId && phoneKey(u.phone) === key,
  );
}
