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
  'High Court',
  'District Court',
  'Family Court',
  'Consumer Court',
  'Tribunal',
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
  'Labour & Employment',
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
