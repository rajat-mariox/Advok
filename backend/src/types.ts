export type Role = 'admin' | 'client' | 'advocate' | 'law_student' | 'law_firm';

export type UserStatus =
  | 'new' // OTP verified, role not chosen yet
  | 'active' // client (no onboarding needed) or fully usable account
  | 'onboarding_required' // role chosen, onboarding not submitted yet
  | 'pending_approval' // onboarding submitted, waiting for admin
  | 'approved' // admin approved
  | 'rejected'; // admin rejected

export interface AdvocateProfile {
  advocateType: 'junior' | 'senior';
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
    barRegistrationNumber: string;
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
}

export type Profile = AdvocateProfile | LawStudentProfile | LawFirmProfile;

export interface User {
  id: string;
  role: Role | null;
  status: UserStatus;
  phone?: string;
  countryCode?: string;
  email?: string;
  passwordHash?: string;
  name?: string;
  profile?: Profile;
  rejectionReason?: string;
  createdAt: string;
  onboardedAt?: string;
  reviewedAt?: string;
}

export interface OtpRecord {
  phone: string;
  countryCode: string;
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
