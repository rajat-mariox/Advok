import type {
  AdminAdvocate,
  AdminCase,
  AdminClient,
  AdminLawFirm,
  AdminStudent,
  BarAdmission,
  FirmTeamLawyer,
} from '../types';
import { authFetch } from './auth';

/** A consultation booking as the backend stores it, plus display names. */
export interface BackendBooking {
  id: string;
  clientId: string;
  advocateId: string;
  consultationType: 'video_call' | 'phone_call' | 'office_visit';
  date: string;
  time: string;
  durationMinutes: number;
  amount: number;
  status: 'pending' | 'confirmed' | 'completed' | 'declined' | 'cancelled';
  createdAt: string;
  clientName: string;
  advocateName: string;
}

/** A case as the backend stores it, plus display names. */
export interface BackendCase {
  id: string;
  clientId: string;
  advocateId: string;
  title: string;
  caseNumber: string;
  court: string;
  practiceArea?: string;
  status: 'active' | 'discovery' | 'hearing' | 'closed';
  priority?: 'high' | 'medium' | 'low';
  filedDate?: string;
  nextHearing?: string;
  createdAt: string;
  updatedAt: string;
  clientName: string;
  advocateName: string;
}

export async function fetchAdminBookings(): Promise<BackendBooking[]> {
  const res = await authFetch('/admin/bookings');
  if (!res.ok) throw new Error('Failed to load bookings');
  const data = await res.json();
  return data.bookings ?? [];
}

export async function fetchAdminCases(): Promise<BackendCase[]> {
  const res = await authFetch('/admin/cases');
  if (!res.ok) throw new Error('Failed to load cases');
  const data = await res.json();
  return data.cases ?? [];
}

/** Consultation fee per type, USD — set from the Settings page. */
export type ConsultationPricing = {
  video_call: number;
  phone_call: number;
  office_visit: number;
  /** Voice consultation booked with a law firm or one of its attorneys. */
  law_firm_phone_call: number;
};

export async function fetchPricing(): Promise<ConsultationPricing> {
  const res = await authFetch('/admin/pricing');
  if (!res.ok) throw new Error('Failed to load pricing');
  const data = await res.json();
  return data.pricing;
}

export async function updatePricing(
  pricing: ConsultationPricing,
): Promise<ConsultationPricing> {
  const res = await authFetch('/admin/pricing', {
    method: 'PUT',
    body: JSON.stringify(pricing),
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.error ?? 'Failed to save pricing');
  }
  const data = await res.json();
  return data.pricing;
}

// ---------------------------------------------------------- Help & Support

/** Contact details shown on the app's Help & Support screen. */
export type SupportContact = {
  email: string;
  phone: string;
  hours: string;
  responseNote: string;
};

export async function fetchSupportContact(): Promise<SupportContact> {
  const res = await authFetch('/admin/support-contact');
  if (!res.ok) throw new Error('Failed to load support contact');
  const data = await res.json();
  return data.support;
}

export async function updateSupportContact(
  contact: SupportContact,
): Promise<SupportContact> {
  const res = await authFetch('/admin/support-contact', {
    method: 'PUT',
    body: JSON.stringify(contact),
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.error ?? 'Failed to save support contact');
  }
  const data = await res.json();
  return data.support;
}

export type SupportTicketStatus = 'open' | 'in_progress' | 'resolved';

export interface SupportReply {
  id: string;
  fromAdmin: boolean;
  text: string;
  createdAt: string;
}

/** A help request raised from the app, plus the user's display details. */
export interface SupportTicket {
  id: string;
  userId: string;
  role: BackendUser['role'] | null;
  category: 'account' | 'booking' | 'payment' | 'case' | 'technical' | 'other';
  subject: string;
  message: string;
  status: SupportTicketStatus;
  replies: SupportReply[];
  createdAt: string;
  updatedAt: string;
  resolvedAt?: string;
  userUnread: number;
  adminUnread: number;
  userName: string;
  userEmail: string | null;
  userPhone: string | null;
  userPhoto: string | null;
  userRole: BackendUser['role'] | null;
}

export interface SupportTicketCounts {
  open: number;
  in_progress: number;
  resolved: number;
  unread: number;
}

export async function fetchSupportTickets(
  status: SupportTicketStatus | 'all' = 'all',
): Promise<{ tickets: SupportTicket[]; counts: SupportTicketCounts }> {
  const res = await authFetch(`/admin/support/tickets?status=${status}`);
  if (!res.ok) throw new Error('Failed to load support tickets');
  return res.json();
}

/** Opening a ticket clears its unread badge for the admin. */
export async function fetchSupportTicket(id: string): Promise<SupportTicket> {
  const res = await authFetch(`/admin/support/tickets/${id}`);
  if (!res.ok) throw new Error('Failed to load ticket');
  const data = await res.json();
  return data.ticket;
}

export async function replySupportTicket(
  id: string,
  text: string,
  status?: SupportTicketStatus,
): Promise<SupportTicket> {
  const res = await authFetch(`/admin/support/tickets/${id}/reply`, {
    method: 'POST',
    body: JSON.stringify(status ? { text, status } : { text }),
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.error ?? 'Failed to send reply');
  }
  const data = await res.json();
  return data.ticket;
}

export async function setSupportTicketStatus(
  id: string,
  status: SupportTicketStatus,
): Promise<SupportTicket> {
  const res = await authFetch(`/admin/support/tickets/${id}/status`, {
    method: 'PATCH',
    body: JSON.stringify({ status }),
  });
  if (!res.ok) {
    const data = await res.json().catch(() => ({}));
    throw new Error(data.error ?? 'Failed to update status');
  }
  const data = await res.json();
  return data.ticket;
}

export const ticketStatusLabel = (s: SupportTicketStatus) =>
  s === 'in_progress' ? 'In Progress' : s === 'resolved' ? 'Resolved' : 'Open';

export const ticketCategoryLabel = (c: SupportTicket['category']) =>
  ({
    account: 'Account',
    booking: 'Booking',
    payment: 'Payment',
    case: 'Case',
    technical: 'Technical',
    other: 'Other',
  })[c] ?? 'Other';

export const roleLabel = (r: BackendUser['role'] | null | undefined) =>
  ({
    client: 'Client',
    advocate: 'Attorney',
    law_student: 'Law Student',
    law_firm: 'Law Firm',
  })[r ?? 'client'] ?? '—';

export const consultationTypeLabel = (t: BackendBooking['consultationType']) =>
  t === 'office_visit' ? 'Office Visit' : t === 'phone_call' ? 'Phone Call' : 'Video Call';

export const bookingStatusLabel = (s: BackendBooking['status']) =>
  s.charAt(0).toUpperCase() + s.slice(1);

export function toAdminCase(c: BackendCase): AdminCase {
  const cap = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);
  return {
    number: c.caseNumber,
    title: c.title,
    client: c.clientName,
    advocate: c.advocateName,
    status: cap(c.status) as AdminCase['status'],
    filed: formatDate(c.filedDate ?? c.createdAt),
    nextHearing: c.nextHearing ? formatDate(c.nextHearing) : undefined,
    priority: c.priority ? (cap(c.priority) as AdminCase['priority']) : undefined,
    practiceArea: c.practiceArea?.trim() || 'General Practice',
    court: c.court,
  };
}

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
  /** Account email from Google/Apple login (clients may also set one in-app). */
  email?: string;
  /** Display name from Google/Apple login. */
  name?: string;
  googleId?: string;
  appleId?: string;
  firmId?: string;
  firmName?: string;
  createdAt: string;
  onboardedAt?: string;
  reviewedAt?: string;
  rejectionReason?: string;
  suspensionReason?: string;
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

/** Sets or clears (null) a law firm's own voice-consultation fee. */
export async function setFirmFee(id: string, consultationFee: number | null): Promise<boolean> {
  const res = await authFetch(`/admin/users/${id}/firm-fee`, {
    method: 'PATCH',
    body: JSON.stringify({ consultationFee }),
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

export interface AiStatus {
  connected: boolean;
  provider: string;
  model: string;
}

/** Whether ADVOK AI is wired to a model on the backend (no secrets returned). */
export async function fetchAiStatus(): Promise<AiStatus> {
  const res = await authFetch('/admin/ai/status');
  if (!res.ok) throw new Error('Failed to load AI status');
  return res.json();
}

export interface AiSuggestion {
  id: string;
  text: string;
  active: boolean;
}

export async function fetchAiSuggestions(): Promise<AiSuggestion[]> {
  const res = await authFetch('/admin/ai/suggestions');
  if (!res.ok) throw new Error('Failed to load suggested prompts');
  return (await res.json()).suggestions ?? [];
}

/** Replaces the whole list; order is what the app shows. */
export async function updateAiSuggestions(
  suggestions: { id?: string; text: string; active: boolean }[],
): Promise<AiSuggestion[]> {
  const res = await authFetch('/admin/ai/suggestions', {
    method: 'PUT',
    body: JSON.stringify({ suggestions }),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error ?? 'Failed to save suggested prompts');
  return data.suggestions ?? [];
}

/** Sends one test question through the same endpoint the app uses. */
export async function aiChat(messages: { role: 'user' | 'assistant'; content: string }[]): Promise<string> {
  const res = await authFetch('/ai/chat', { method: 'POST', body: JSON.stringify({ messages }) });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error ?? 'ADVOK AI request failed');
  return data.reply ?? '';
}

// ------------------------------------------------ Learning: Cases to Read

export type CaseStudyLevel = 'Beginner' | 'Intermediate' | 'Advanced';

export interface CaseStudyCard {
  id: string;
  clusterId: number;
  title: string;
  court: string;
  courtId: string;
  dateFiled: string;
  year: string;
  citation: string;
  docketNumber: string;
  judges: string;
  tag: string;
  level: CaseStudyLevel;
  summary: string;
  principle: string;
  hasFullText: boolean;
  hasSyllabus: boolean;
  /** True once study notes (Generate Case Notes tool) are cached. */
  hasNotes: boolean;
  mins: number;
  published: boolean;
  sortOrder: number;
  reads: number;
  addedAt: string;
  updatedAt: string;
}

export interface OpinionSearchHit {
  clusterId: number;
  title: string;
  court: string;
  courtId: string;
  dateFiled: string;
  citation: string;
  citations: string[];
  docketNumber: string;
  judges: string;
  citeCount: number;
  snippet: string;
  syllabus: string;
  opinionId?: number;
  alreadyAdded?: boolean;
}

export async function searchCourtListener(
  q: string,
  court = '',
): Promise<{ results: OpinionSearchHit[]; fullTextAvailable: boolean }> {
  const params = new URLSearchParams({ q });
  if (court) params.set('court', court);
  const res = await authFetch(`/admin/learning/search?${params.toString()}`);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error ?? 'Search failed');
  return { results: data.results ?? [], fullTextAvailable: !!data.fullTextAvailable };
}

export async function fetchCaseStudies(): Promise<{ cases: CaseStudyCard[]; fullTextAvailable: boolean }> {
  const res = await authFetch('/admin/learning/cases');
  if (!res.ok) throw new Error('Failed to load cases');
  const data = await res.json();
  return { cases: data.cases ?? [], fullTextAvailable: !!data.fullTextAvailable };
}

export async function fetchCaseStudy(
  id: string,
): Promise<CaseStudyCard & { syllabus: string; opinionText: string; notes: CaseNotes | null }> {
  const res = await authFetch(`/admin/learning/cases/${id}`);
  if (!res.ok) throw new Error('Failed to load case');
  return (await res.json()).case;
}

/** IRAC study notes generated by ADVOK AI for a case (the app's "Generate Case Notes" tool). */
export interface CaseNotes {
  facts: string;
  issue: string;
  rule: string;
  holding: string;
  reasoning: string;
  significance: string;
  keyTerms: string[];
  generatedAt: string;
  model: string;
  edited: boolean;
}

export async function generateCaseNotes(id: string): Promise<CaseNotes> {
  const res = await authFetch(`/admin/learning/cases/${id}/notes`, { method: 'POST' });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error ?? 'Failed to generate notes');
  return data.notes;
}

/** Pass null to clear the notes. */
export async function updateCaseNotes(id: string, notes: Partial<CaseNotes> | null): Promise<CaseNotes | null> {
  const res = await authFetch(`/admin/learning/cases/${id}/notes`, { method: 'PUT', body: JSON.stringify({ notes }) });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error ?? 'Failed to save notes');
  return data.notes ?? null;
}

// ------------------------------------------------ Learning: Legal Dictionary

export interface DictionaryTermSummary {
  slug: string;
  term: string;
  preview: string;
  source: 'blacks2' | 'admin' | 'ai';
  edited: boolean;
  custom: boolean;
  aiOnly: boolean;
  hidden: boolean;
  hasPlainEnglish: boolean;
}

export interface DictionaryTerm {
  slug: string;
  term: string;
  definition: string;
  source: 'blacks2' | 'admin' | 'ai';
  sourceLabel: string;
  edited: boolean;
  custom: boolean;
  aiOnly: boolean;
  hidden: boolean;
  plainEnglish?: string;
  plainEnglishAt?: string;
}

export interface DictionaryStats {
  source: string;
  baseCount: number;
  customCount: number;
  aiOnlyCount: number;
  editedCount: number;
  hiddenCount: number;
  explainedCount: number;
  aiConnected: boolean;
}

export async function searchDictionary(
  q: string,
  opts: { letter?: string; limit?: number; offset?: number } = {},
): Promise<{ terms: DictionaryTermSummary[]; total: number }> {
  const params = new URLSearchParams();
  if (q.trim()) params.set('q', q.trim());
  if (opts.letter) params.set('letter', opts.letter);
  params.set('limit', String(opts.limit ?? 50));
  params.set('offset', String(opts.offset ?? 0));
  const res = await authFetch(`/admin/learning/dictionary?${params.toString()}`);
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error ?? 'Failed to load the dictionary');
  return { terms: data.terms ?? [], total: data.total ?? 0 };
}

export async function fetchDictionaryStats(): Promise<DictionaryStats> {
  const res = await authFetch('/admin/learning/dictionary/stats');
  if (!res.ok) throw new Error('Failed to load dictionary stats');
  return (await res.json()).stats;
}

export async function fetchDictionaryTerm(slug: string): Promise<DictionaryTerm> {
  const res = await authFetch(`/admin/learning/dictionary/${encodeURIComponent(slug)}`);
  if (!res.ok) throw new Error('Failed to load term');
  return (await res.json()).term;
}

export async function createDictionaryTerm(term: string, definition: string): Promise<DictionaryTerm> {
  const res = await authFetch('/admin/learning/dictionary', { method: 'POST', body: JSON.stringify({ term, definition }) });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error ?? 'Failed to add term');
  return data.term;
}

export async function updateDictionaryTerm(
  slug: string,
  patch: { term?: string; definition?: string; hidden?: boolean },
): Promise<DictionaryTerm> {
  const res = await authFetch(`/admin/learning/dictionary/${encodeURIComponent(slug)}`, { method: 'PATCH', body: JSON.stringify(patch) });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error ?? 'Failed to save term');
  return data.term;
}

/** Custom terms are deleted; base dictionary terms are hidden from the app. */
export async function deleteDictionaryTerm(slug: string): Promise<boolean> {
  const res = await authFetch(`/admin/learning/dictionary/${encodeURIComponent(slug)}`, { method: 'DELETE' });
  return res.ok;
}

export async function createCaseStudy(
  body: Partial<OpinionSearchHit> & {
    tag: string;
    level: CaseStudyLevel;
    summary: string;
    principle: string;
    published: boolean;
  },
): Promise<CaseStudyCard> {
  const res = await authFetch('/admin/learning/cases', { method: 'POST', body: JSON.stringify(body) });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error ?? 'Failed to add case');
  return data.case;
}

export async function updateCaseStudy(
  id: string,
  patch: Partial<Pick<CaseStudyCard, 'title' | 'tag' | 'level' | 'summary' | 'principle' | 'published' | 'sortOrder'>>,
): Promise<CaseStudyCard> {
  const res = await authFetch(`/admin/learning/cases/${id}`, { method: 'PATCH', body: JSON.stringify(patch) });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error ?? 'Failed to save case');
  return data.case;
}

export async function refreshCaseStudyText(id: string): Promise<CaseStudyCard> {
  const res = await authFetch(`/admin/learning/cases/${id}/refresh-text`, { method: 'POST' });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error ?? 'Failed to fetch opinion text');
  return data.case;
}

export async function deleteCaseStudy(id: string): Promise<boolean> {
  const res = await authFetch(`/admin/learning/cases/${id}`, { method: 'DELETE' });
  return res.ok;
}

// ------------------------------------------------ Legal Queries (law students)

export type LegalQueryStatus = 'pending' | 'answered';

export interface BackendLegalQuery {
  id: string;
  studentId: string;
  category: string;
  question: string;
  status: LegalQueryStatus;
  response?: string;
  responderName?: string;
  responderId?: string;
  createdAt: string;
  answeredAt?: string;
  updatedAt: string;
  studentName: string;
  studentCollege: string | null;
  studentPhoto: string | null;
  studentPhone: string | null;
  studentEmail: string | null;
}

export interface LegalQueryCounts {
  total: number;
  pending: number;
  answered: number;
}

export async function fetchLegalQueries(): Promise<{ queries: BackendLegalQuery[]; counts: LegalQueryCounts }> {
  const res = await authFetch('/admin/queries');
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error ?? 'Failed to load legal queries');
  return { queries: data.queries ?? [], counts: data.counts ?? { total: 0, pending: 0, answered: 0 } };
}

export async function answerLegalQuery(id: string, response: string, responderName?: string): Promise<BackendLegalQuery> {
  const res = await authFetch(`/admin/queries/${id}/answer`, {
    method: 'POST',
    body: JSON.stringify({ response, responderName }),
  });
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data.error ?? 'Failed to send the answer');
  return data.query;
}

export async function deleteLegalQuery(id: string): Promise<boolean> {
  const res = await authFetch(`/admin/queries/${id}`, { method: 'DELETE' });
  return res.ok;
}

// ------------------------------------------------ Learning: Legal News

export interface NewsItem {
  id: string;
  title: string;
  source: string;
  url: string;
  publishedAt: string;
  tag: string;
  excerpt: string;
}

export interface NewsSourceStatus {
  key: string;
  name: string;
  url: string;
  defaultTag: string;
  ok: boolean;
  items: number;
  error?: string;
  fetchedAt?: string;
}

export interface NewsStatus {
  sources: NewsSourceStatus[];
  fetchedAt: string | null;
  total: number;
  tags: string[];
}

export async function fetchNewsSources(): Promise<NewsStatus> {
  const res = await authFetch('/admin/learning/news/sources');
  if (!res.ok) throw new Error('Failed to load news sources');
  return res.json();
}

export async function fetchLegalNews(): Promise<NewsItem[]> {
  const res = await authFetch('/learning/news');
  if (!res.ok) throw new Error('Failed to load news');
  return (await res.json()).news ?? [];
}

export async function refreshLegalNews(): Promise<NewsStatus & { news: NewsItem[] }> {
  const res = await authFetch('/admin/learning/news/refresh', { method: 'POST' });
  if (!res.ok) throw new Error('Failed to refresh news');
  return res.json();
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

/** The OTP login number, e.g. "+1 4155550123". */
function loginPhone(u: BackendUser): string {
  return `${u.countryCode ?? ''} ${u.phone ?? ''}`.trim() || '—';
}

export function toAdminAdvocate(u: BackendUser): AdminAdvocate {
  const p = u.profile ?? {};
  const pro = p.professional ?? {};
  const barAdmissions: BarAdmission[] = (pro.barAdmissions ?? [])
    .filter((a: any) => a && (a.state || a.barNumber))
    .map((a: any) => ({
      state: a.state ?? '',
      barNumber: a.barNumber ?? '',
      licenseStatus: a.licenseStatus ?? 'Active',
    }));
  const federalCourts: string[] = pro.federalCourtAdmissions ?? [];
  return {
    id: u.id,
    country: u.country,
    photo: p.photo || undefined,
    name: pro.fullName ?? 'Attorney',
    email: pro.email ?? '—',
    phone: loginPhone(u),
    // US onboarding stores a firm role; older tier-only profiles fall back
    // to the US tier titles from the app's catalog.
    firmRole: p.firmRole || (p.advocateType === 'senior' ? 'Senior Attorney' : 'Associate Attorney'),
    yearsInPractice:
      p.yearsInPractice || (p.advocateType === 'senior' ? '10+ years' : 'Under 10 years'),
    practiceArea: pro.practiceArea?.trim() || 'General Practice',
    barAdmissions,
    barNumber: pro.licenseNumber ?? pro.barRegistrationNumber ?? '',
    federalCourts,
    primaryCourt: pro.primaryCourt ?? '',
    state: p.location?.state ?? '—',
    city: p.location?.district ?? '—',
    officeAddress: p.location?.officeAddress ?? '',
    purposes: p.purposes ?? [],
    verification: verificationLabel(u.status, 'Pending Review') as AdminAdvocate['verification'],
    joined: formatDate(u.createdAt),
    submitted: formatDate(u.onboardedAt),
    workingDays: p.schedule?.workingDays ?? [],
    availableTime: p.schedule?.startTime ? `${p.schedule.startTime} – ${p.schedule.endTime}` : '—',
    supervisingAttorney: pro.seniorAdvocateName || undefined,
    firmName: u.firmName || undefined,
    rejectionReason: u.rejectionReason || undefined,
    suspensionReason: u.suspensionReason || undefined,
  };
}

/** "CA #123456 · NY #789" for tables; falls back to the single bar number. */
export function barSummary(a: AdminAdvocate): string {
  if (a.barAdmissions.length > 0) {
    return a.barAdmissions.map((b) => `${b.state} #${b.barNumber || '—'}`).join(' · ');
  }
  return a.barNumber || '—';
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
    phone: l.phone || undefined,
    email: l.email || undefined,
    barLicense: l.barLicense || undefined,
    barState: l.barState || undefined,
    licenseStatus: l.licenseStatus || undefined,
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
    consultationFee: typeof p.consultationFee === 'number' ? p.consultationFee : undefined,
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
    // Clients can set a display name/email from the app's Edit Profile;
    // Google/Apple logins also carry a name/email on the account itself.
    name: p.fullName || u.name || phone || u.email || 'Client',
    email: p.email || u.email || '—',
    phone: phone || '—',
    country: u.country || '—',
    loginMethod: u.googleId ? 'Google' : u.appleId ? 'Apple' : 'Phone OTP',
    consultations: 0,
    activeCases: 0,
    totalCases: 0,
    status: u.status === 'suspended' ? 'Suspended' : 'Active',
    suspensionReason: u.suspensionReason || undefined,
    joined: formatDate(u.createdAt),
  };
}
