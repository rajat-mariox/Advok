import type {
  AdminAdvocate,
  AdminClient,
  AdminLawFirm,
  AdminStudent,
  FirmTeamLawyer,
} from '../types';
import { authFetch } from './auth';

export interface BackendUser {
  id: string;
  role: 'client' | 'advocate' | 'law_student' | 'law_firm';
  status:
    | 'new'
    | 'active'
    | 'onboarding_required'
    | 'pending_approval'
    | 'approved'
    | 'rejected'
    | 'suspended';
  phone?: string;
  countryCode?: string;
  country?: string;
  createdAt: string;
  onboardedAt?: string;
  reviewedAt?: string;
  rejectionReason?: string;
  profile?: any;
}

export async function fetchBackendUsers(role?: BackendUser['role']): Promise<BackendUser[]> {
  const res = await authFetch(`/admin/users${role ? `?role=${role}` : ''}`);
  if (!res.ok) throw new Error('Failed to load users');
  const data = await res.json();
  return data.users ?? [];
}

/** Maps a verification label chosen in the UI to the backend review action. */
export async function reviewRegistration(
  id: string,
  verification: string,
  reason?: string,
): Promise<boolean> {
  const action =
    verification === 'Verified' ? 'approve' : verification === 'Rejected' ? 'reject' : 'reopen';
  const res = await authFetch(`/admin/registrations/${id}/${action}`, {
    method: 'POST',
    body: JSON.stringify(reason ? { reason } : {}),
  });
  return res.ok;
}

/** Permanently deletes a (non-admin) user account. */
export async function deleteBackendUser(id: string): Promise<boolean> {
  const res = await authFetch(`/admin/users/${id}`, { method: 'DELETE' });
  return res.ok;
}

/** Suspends an account (any role); the app locks the user out until lifted. */
export async function suspendBackendUser(id: string, reason?: string): Promise<boolean> {
  const res = await authFetch(`/admin/users/${id}/suspend`, {
    method: 'POST',
    body: JSON.stringify(reason ? { reason } : {}),
  });
  return res.ok;
}

/** Lifts a suspension, restoring the status the account had before it. */
export async function unsuspendBackendUser(id: string): Promise<boolean> {
  const res = await authFetch(`/admin/users/${id}/unsuspend`, { method: 'POST' });
  return res.ok;
}

export function formatDate(iso?: string): string {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString(undefined, {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  });
}

function verificationLabel(
  status: BackendUser['status'],
  pendingLabel: string,
): 'Verified' | 'Rejected' | 'Suspended' | string {
  if (status === 'approved') return 'Verified';
  if (status === 'rejected') return 'Rejected';
  if (status === 'suspended') return 'Suspended';
  return pendingLabel;
}

/** Only users whose onboarding is actually submitted show up on review pages. */
export function hasSubmittedProfile(u: BackendUser): boolean {
  return (
    !!u.profile &&
    ['pending_approval', 'approved', 'rejected', 'suspended'].includes(u.status)
  );
}

/** The OTP login number, e.g. "+91 9876543210". */
function loginPhone(u: BackendUser): string {
  return `${u.countryCode ?? ''} ${u.phone ?? ''}`.trim() || '—';
}

export function toAdminAdvocate(u: BackendUser): AdminAdvocate {
  const p = u.profile ?? {};
  return {
    id: u.id,
    country: u.country,
    photo: p.photo || undefined,
    name: p.professional?.fullName ?? 'Advocate',
    email: p.professional?.email ?? '—',
    phone: loginPhone(u),
    // US profiles carry a firm role; Junior/Senior is the India classification.
    type: p.firmRole || (p.advocateType === 'senior' ? 'Senior Advocate' : 'Junior Advocate'),
    yearsInPractice: p.yearsInPractice || undefined,
    specialty: p.professional?.practiceArea ?? '—',
    barRegNo: p.professional?.licenseNumber ?? p.professional?.barRegistrationNumber ?? '—',
    court: p.professional?.primaryCourt ?? '—',
    state: p.location?.state ?? '—',
    city: p.location?.district ?? '—',
    experienceYears: p.advocateType === 'senior' ? 10 : 0,
    cases: 0,
    rating: null,
    pricePerHr: 0,
    verification: verificationLabel(u.status, 'Pending Review') as AdminAdvocate['verification'],
    joined: formatDate(u.createdAt),
    workingDays: p.schedule?.workingDays ?? [],
    availableTime: p.schedule?.startTime ? `${p.schedule.startTime} – ${p.schedule.endTime}` : '—',
    seniorAdvocateName: p.professional?.seniorAdvocateName,
  };
}

export function toAdminStudent(u: BackendUser): AdminStudent {
  const p = u.profile ?? {};
  return {
    id: u.id,
    photo: p.photo || undefined,
    fullName: p.fullName ?? 'Law Student',
    email: '—',
    phone: loginPhone(u),
    college: p.college ?? '—',
    course: p.course ?? '—',
    academicYear: p.academicYear,
    idCardFile: p.idCardFileName || undefined,
    location: loginPhone(u),
    casesRead: 0,
    savedItems: 0,
    mentors: 0,
    verification: verificationLabel(u.status, 'Pending Verification') as AdminStudent['verification'],
    submitted: formatDate(u.onboardedAt),
  };
}

export function toAdminLawFirm(u: BackendUser): AdminLawFirm {
  const p = u.profile ?? {};
  const team: FirmTeamLawyer[] = (p.lawyers ?? []).map((l: any) => ({
    fullName: l.fullName ?? '—',
    designation: l.designation || 'Associate',
    barLicense: l.barLicense || undefined,
    yearsExperience: l.yearsExperience ? Number(l.yearsExperience) || undefined : undefined,
    expertise: l.expertise ?? [],
  }));
  return {
    id: u.id,
    photo: p.photo || undefined,
    firmName: p.firmName ?? 'Law Firm',
    phone: loginPhone(u),
    foundedYear: p.foundedYear ?? '—',
    contactPersonName: p.contactPerson ?? '—',
    officialEmail: p.officialEmail ?? '—',
    mainPhone: p.mainPhone ?? '—',
    receptionNumber: p.receptionNumber || undefined,
    addressLine1: p.addressLine1 ?? '—',
    addressLine2: p.addressLine2 || undefined,
    city: p.city ?? '—',
    state: p.state ?? '—',
    zipCode: p.zip ?? '—',
    logoFileName: p.logoFileName || undefined,
    totalLawyers: Number(p.totalLawyers) || team.length,
    team,
    activeCases: 0,
    clients: 0,
    revenueMonth: 0,
    verification: verificationLabel(u.status, 'Pending Approval') as AdminLawFirm['verification'],
    submitted: formatDate(u.onboardedAt),
  };
}

export function toAdminClient(u: BackendUser): AdminClient {
  const p = u.profile ?? {};
  const phone = `${u.countryCode ?? ''} ${u.phone ?? ''}`.trim();
  return {
    id: u.id,
    photo: p.photo || undefined,
    // Clients can set a display name/email from the app's Edit Profile.
    name: p.fullName || phone || 'Client',
    email: p.email || '—',
    location: '—',
    consultations: 0,
    activeCases: 0,
    savedAdvocates: 0,
    status: u.status === 'suspended' ? 'Suspended' : 'Active',
    joined: formatDate(u.createdAt),
  };
}
