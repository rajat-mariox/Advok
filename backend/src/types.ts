export type Role = 'admin' | 'client' | 'advocate' | 'law_student' | 'law_firm';

export type UserStatus =
  | 'new' // OTP verified, role not chosen yet
  | 'active' // client (no onboarding needed) or fully usable account
  | 'onboarding_required' // role chosen, onboarding not submitted yet
  | 'pending_approval' // onboarding submitted, waiting for admin
  | 'approved' // admin approved
  | 'rejected' // admin rejected
  | 'suspended'; // admin suspended the account (any role)

export interface AdvocateProfile {
  advocateType: 'junior' | 'senior';
  /** Profile photo as a base64 data URL. */
  photo?: string;
  /** US-only classification: "0–2 years" … "20+ years". */
  yearsInPractice?: string;
  /** US-only firm role: Partner, Associate, Of Counsel, Solo Practitioner… */
  firmRole?: string;
  purposes: string[];
  location: {
    state: string;
    district: string;
    officeAddress: string;
  };
  professional: {
    fullName: string;
    seniorAdvocateName?: string;
    email: string;
    /** Bar Registration Number (India) / State Bar License (US). */
    licenseNumber: string;
    /** Legacy name for licenseNumber — only present on old saved profiles. */
    barRegistrationNumber?: string;
    primaryCourt: string;
    practiceArea: string;
  };
  schedule: {
    workingDays: string[];
    startTime: string;
    endTime: string;
  };
}

export interface LawStudentProfile {
  fullName: string;
  college: string;
  course: string;
  academicYear: string;
  idCardFileName: string;
  /** Profile photo as a base64 data URL. */
  photo?: string;
}

/** Clients have no onboarding; this holds their optional profile edits. */
export interface ClientProfile {
  fullName?: string;
  email?: string;
  /** Profile photo as a base64 data URL. */
  photo?: string;
}

export interface FirmLawyer {
  fullName: string;
  phone: string;
  barLicense: string;
  yearsExperience: string;
  designation: string;
  expertise: string[];
}

export interface LawFirmProfile {
  firmName: string;
  foundedYear: string;
  contactPerson: string;
  logoFileName?: string;
  officialEmail: string;
  mainPhone: string;
  receptionNumber?: string;
  addressLine1: string;
  addressLine2?: string;
  city: string;
  zip: string;
  state: string;
  totalLawyers: string;
  lawyers: FirmLawyer[];
  /** Firm logo/photo as a base64 data URL. */
  photo?: string;
}

export type Profile =
  | AdvocateProfile
  | LawStudentProfile
  | LawFirmProfile
  | ClientProfile;

export interface User {
  id: string;
  role: Role | null;
  status: UserStatus;
  phone?: string;
  countryCode?: string;
  /** Country chosen at signup (e.g. 'India', 'United States') — drives the
   * India/US flow in the app and tells the admin which authority to verify
   * credentials against. */
  country?: string;
  email?: string;
  passwordHash?: string;
  name?: string;
  profile?: Profile;
  rejectionReason?: string;
  /** Why the admin suspended this account (shown in the app). */
  suspensionReason?: string;
  /** Status to restore when the suspension is lifted. */
  statusBeforeSuspension?: UserStatus;
  createdAt: string;
  onboardedAt?: string;
  reviewedAt?: string;
}

export interface OtpRecord {
  phone: string;
  countryCode: string;
  country?: string;
  otp: string;
  expiresAt: number;
}

export interface CmsSection {
  title: string;
  body: string;
}

/** Admin-editable app page (Terms & Conditions, Privacy Policy, ...). */
export interface CmsPage {
  slug: string;
  title: string;
  sections: CmsSection[];
  /** Label shown at the bottom of the page in the app, e.g. "Last updated: January 1, 2025". */
  lastUpdatedLabel: string;
  updatedAt: string;
}

export interface DbShape {
  users: User[];
  otps: OtpRecord[];
  cmsPages?: CmsPage[];
}
