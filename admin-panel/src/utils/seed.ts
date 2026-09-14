import type {
  AdminAdvocate,
  AdminBooking,
  AdminCase,
  AdminCaseStudy,
  AdminClient,
  AdminLawFirm,
  AdminNewsArticle,
  AdminStudent,
  LegalQuery,
  MentorshipRequest,
  Payout,
} from '../types';

// Configuration lists mirrored from the advok_app screens. Real records
// (users, bookings, cases, …) come from the backend — the arrays below stay
// empty until their features get backend support.

export const LEGAL_CATEGORIES = [
  'Criminal',
  'Civil',
  'Corporate',
  'Family',
  'Property',
  'Immigration',
  'Employment',
  'Cyber',
];

export const CONSULTATION_TYPES = [
  { title: 'Video Call', subtitle: 'Online via ADVOK', price: 120 },
  { title: 'Phone Call', subtitle: 'Audio consultation', price: 90 },
  { title: 'Office Visit', subtitle: 'In-person meeting', price: 150 },
];

export const COURTS = [
  'Supreme Court',
  'Court of Appeals',
  'District Court',
  'Family Court',
  'Bankruptcy Court',
  'Tax Court',
];

// Expertise options from add_legal_team_screen.dart
export const FIRM_EXPERTISE = [
  'Criminal',
  'Civil',
  'Corporate',
  'Family',
  'Tax',
  'Cyber Crime',
  'Property',
  'Immigration',
  'Labor & Employment',
];

// US legal-system options mirrored from LegalTerms.us in the app's
// country_catalog.dart — drive the admin filters and labels.
export const US_FIRM_ROLES = [
  'Partner',
  'Associate',
  'Senior Associate',
  'Of Counsel',
  'Counsel',
  'Staff Attorney',
  'Solo Practitioner',
];

export const US_YEARS_IN_PRACTICE = ['0–2 years', '3–5 years', '6–10 years', '11–20 years', '20+ years'];

export const US_LICENSE_STATUSES = ['Active', 'Inactive', 'Pending Admission', 'Suspended', 'Retired'];

export const US_FEDERAL_COURTS = [
  'U.S. District Court',
  'U.S. Court of Appeals',
  'U.S. Bankruptcy Court',
  'U.S. Tax Court',
  'U.S. Court of International Trade',
  'U.S. Court of Federal Claims',
  'U.S. Supreme Court',
];

export const US_PRACTICE_AREAS = [
  'Criminal Defense',
  'Family Law',
  'Personal Injury',
  'Immigration',
  'Employment Law',
  'Real Estate',
  'Corporate/Business Law',
  'Bankruptcy',
  'Estate Planning',
  'Intellectual Property',
  'Tax Law',
  'Civil Litigation',
  'Cyber Law',
];

export const ACADEMIC_YEARS = ['1st Year', '2nd Year', '3rd Year', '4th Year', '5th Year', 'Final Year'];

export const SESSION_TYPES = [
  { title: '1-on-1 Video Call', subtitle: '45 min session, video call' },
  { title: 'Case Shadow', subtitle: 'Observe a real case, in-person or virtual' },
  { title: 'Weekly Mentorship', subtitle: 'Ongoing weekly check-ins' },
] as const;

export const QUERY_CATEGORIES = [
  'Criminal Law',
  'Civil Law',
  'Family Law',
  'Corporate Law',
  'Property Law',
  'Employment Law',
  'Immigration Law',
  'Cyber Law',
];

export const AI_SUGGESTIONS = [
  'What are my rights if I am arrested?',
  'How long do criminal cases take?',
  'Can I sue for wrongful termination?',
  'What is a power of attorney?',
];

export const money = (n: number) =>
  `$${n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 })}`;

// ---------- Records: empty until these features have backend support ----------

export const advocates: AdminAdvocate[] = [];
export const clients: AdminClient[] = [];
export const bookings: AdminBooking[] = [];
export const cases: AdminCase[] = [];
export const payouts: Payout[] = [];
export const revenueBars: { month: string; value: number }[] = [];
export const lawFirms: AdminLawFirm[] = [];
export const students: AdminStudent[] = [];
export const mentorshipRequests: MentorshipRequest[] = [];
export const legalQueries: LegalQuery[] = [];
export const caseStudies: AdminCaseStudy[] = [];
export const newsArticles: AdminNewsArticle[] = [];
