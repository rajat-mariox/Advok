export type UserRole = 'client' | 'advocate' | 'lawStudent' | 'lawFirm';

export type AdvocateType = 'Junior Advocate' | 'Senior Advocate';

export type VerificationStatus = 'Verified' | 'Pending Review' | 'Rejected' | 'Suspended';

export interface AdminAdvocate {
  id: string;
  /** Country the account registered with ('India', 'United States', …). */
  country?: string;
  /** Profile photo uploaded from the app, as a data URL. */
  photo?: string;
  name: string;
  email: string;
  phone: string; // OTP login number (countryCode + phone)
  /** India: Junior/Senior Advocate. US: the firm role (Partner, Associate…). */
  type: string;
  /** US-only: "0–2 years" … "20+ years". */
  yearsInPractice?: string;
  specialty: string;
  barRegNo: string;
  court: string;
  state: string;
  city: string;
  experienceYears: number;
  cases: number;
  rating: number | null;
  pricePerHr: number;
  verification: VerificationStatus;
  joined: string;
  workingDays: string[];
  availableTime: string;
  seniorAdvocateName?: string;
}

export type ClientStatus = 'Active' | 'Suspended';

export interface AdminClient {
  id: string;
  /** Profile photo uploaded from the app, as a data URL. */
  photo?: string;
  name: string;
  email: string;
  location: string;
  consultations: number;
  activeCases: number;
  savedAdvocates: number;
  status: ClientStatus;
  joined: string;
}

export type BookingStatus = 'Confirmed' | 'Pending' | 'Completed' | 'Cancelled';
export type ConsultationType = 'Video Call' | 'Phone Call' | 'Office Visit';

export interface AdminBooking {
  id: string;
  client: string;
  advocate: string;
  type: ConsultationType;
  status: BookingStatus;
  dateTime: string;
  fee: number;
  platformFee: number;
  tax: number;
  total: number;
}

export type CaseStatus = 'Active' | 'Hearing' | 'Discovery' | 'Closed';
export type CasePriority = 'High' | 'Medium' | 'Low';

export interface AdminCase {
  number: string;
  title: string;
  client: string;
  advocate: string;
  status: CaseStatus;
  filed: string;
  nextHearing?: string;
  priority?: CasePriority;
  practiceArea: string;
  court: string;
}

export interface Payout {
  id: string;
  advocate: string;
  period: string;
  gross: number;
  platformCut: number;
  net: number;
  status: 'Paid' | 'Processing' | 'On Hold';
}

// ---------- Law Firms (mirrors LawFirmRegistration + Firm screens) ----------

export type FirmVerificationStatus = 'Pending Approval' | 'Verified' | 'Rejected' | 'Suspended';

// Registration designations from add_legal_team_screen.dart
export type FirmDesignation =
  | 'Managing Partner'
  | 'Partner'
  | 'Senior Associate'
  | 'Associate'
  | 'Junior Advocate'
  | 'Consultant'
  | 'Intern';

export interface FirmTeamLawyer {
  fullName: string;
  designation: FirmDesignation;
  barLicense?: string;
  yearsExperience?: number;
  expertise: string[];
}

export interface AdminLawFirm {
  id: string;
  /** Profile photo uploaded from the app, as a data URL. */
  photo?: string;
  firmName: string;
  phone: string; // OTP login number (countryCode + phone), distinct from mainPhone
  foundedYear: string;
  contactPersonName: string; // Managing Partner
  officialEmail: string;
  mainPhone: string;
  receptionNumber?: string;
  addressLine1: string;
  addressLine2?: string;
  city: string;
  state: string;
  zipCode: string;
  logoFileName?: string; // PNG · SVG · Max 2MB
  totalLawyers: number;
  team: FirmTeamLawyer[];
  activeCases: number;
  clients: number;
  revenueMonth: number;
  verification: FirmVerificationStatus;
  submitted: string;
}

// ---------- Law Students (mirrors LawStudentRegistration + Student screens) ----------

export type StudentVerificationStatus =
  | 'Pending Verification'
  | 'Verified'
  | 'Rejected'
  | 'Suspended';

export interface AdminStudent {
  id: string;
  /** Profile photo uploaded from the app, as a data URL. */
  photo?: string;
  fullName: string;
  email: string;
  phone: string; // OTP login number (countryCode + phone)
  college: string;
  course: string; // e.g. J.D., LLB, LLM
  academicYear?: string; // 1st Year … Final Year
  idCardFile?: string; // JPG · PNG · PDF · Max 5MB
  location: string;
  casesRead: number;
  savedItems: number;
  mentors: number;
  verification: StudentVerificationStatus;
  submitted: string;
}

// ---------- Mentorship (mirrors FindMentorsScreen 3-step flow) ----------

export type MentorshipStatus = 'Requested' | 'Accepted' | 'Declined' | 'Completed';
export type SessionType = '1-on-1 Video Call' | 'Case Shadow' | 'Weekly Mentorship';
export type DayPreference = 'Weekdays' | 'Weekends' | 'Any';
export type TimePreference = 'Morning' | 'Afternoon' | 'Evening';

export interface MentorshipRequest {
  id: string;
  student: string;
  mentor: string;
  mentorSpecialty: string;
  sessionType: SessionType;
  preferredDate: string;
  dayPreference: DayPreference;
  timePreference: TimePreference;
  message: string;
  status: MentorshipStatus;
  requested: string;
}

// ---------- Legal Queries (mirrors LegalQueriesScreen) ----------

export type QueryStatus = 'Pending' | 'Answered';

export interface LegalQuery {
  id: string;
  student: string;
  category: string; // one of QUERY_CATEGORIES
  question: string; // max 500 chars in the app
  asked: string;
  status: QueryStatus;
  responder?: string;
  response?: string;
}

// ---------- Learning Content (mirrors StudentHomeScreen case studies + news) ----------

export type ContentLevel = 'Beginner' | 'Intermediate' | 'Advanced';

export interface AdminCaseStudy {
  id: string;
  title: string;
  meta: string; // e.g. "US Supreme Court · 1954"
  tag: string;
  mins: number;
  level: ContentLevel;
  status: 'Published' | 'Draft';
  reads: number;
}

export interface AdminNewsArticle {
  id: string;
  title: string;
  source: string; // Law360, Reuters Legal, …
  tag: string; // Supreme Court, Legislation, High Court, Exam Update
  time: string;
  status: 'Published' | 'Draft';
}
