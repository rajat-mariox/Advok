import type { Response } from 'express';
import type { AuthedRequest } from '../middlewares/auth.middleware';
import type { AdvocateProfile, DbShape, User } from '../models';
import { getDb, saveDb } from '../services/db.service';
import { feeForProvider } from '../services/pricing.service';

const isListedAdvocate = (u: User | undefined): u is User =>
  !!u && u.role === 'advocate' && !!u.profile && (u.status === 'approved' || u.status === 'active');

/** The card the app shows for an attorney (list, profile, saved). */
function advocateCard(db: DbShape, u: User) {
  const p = u.profile as AdvocateProfile;
  // Cases this attorney has handled (any status) and consultations held.
  const caseCount = (db.cases ?? []).filter((c) => c.advocateId === u.id).length;
  const consultationCount = (db.bookings ?? []).filter(
    (b) =>
      (b.advocateId === u.id || b.assignedAttorney?.userId === u.id) &&
      (b.status === 'confirmed' || b.status === 'completed'),
  ).length;
  return {
    id: u.id,
    caseCount,
    consultationCount,
    // Firm attorneys charge their firm's rate; solo attorneys the platform rate.
    consultationFee: feeForProvider(db, u),
    country: u.country ?? null,
    photo: p.photo ?? null,
    name: p.professional.fullName,
    advocateType: p.advocateType,
    yearsInPractice: p.yearsInPractice ?? null,
    firmRole: p.firmRole ?? null,
    firmId: u.firmId ?? null,
    firmName: u.firmName ?? null,
    practiceArea: p.professional.practiceArea,
    primaryCourt: p.professional.primaryCourt,
    // States whose bar licensed this attorney (US): the key search filter.
    barStates: (p.professional.barAdmissions ?? [])
      .map((b) => b.state)
      .filter((st): st is string => !!st && st.trim().length > 0),
    federalCourts: p.professional.federalCourtAdmissions ?? [],
    state: p.location.state,
    district: p.location.district,
    workingDays: p.schedule.workingDays,
    startTime: p.schedule.startTime,
    endTime: p.schedule.endTime,
  };
}

/**
 * Verified advocates/attorneys the requesting user can browse.
 *
 * Country-scoped: an Indian client only sees Indian advocates and a US client
 * only sees US attorneys. Accounts saved before country tracking (no country
 * on either side) are not filtered out, so old test data keeps working.
 */
export function listAdvocates(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();
  const list = db.users.filter((u) => {
    if (!isListedAdvocate(u)) return false;
    if (me.country && u.country && u.country !== me.country) return false;
    return true;
  });
  return res.json({ advocates: list.map((u) => advocateCard(db, u)) });
}

/** Attorneys the user saved (hearted), newest first, as full cards. */
export function listSaved(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();
  const ids = [...(me.savedAdvocates ?? [])].reverse();
  const advocates = ids
    .map((id) => db.users.find((u) => u.id === id))
    .filter(isListedAdvocate)
    .map((u) => advocateCard(db, u));
  return res.json({ ids: advocates.map((a) => a.id), advocates });
}

export function saveAdvocate(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();
  const id = req.params.id;
  if (!isListedAdvocate(db.users.find((u) => u.id === id))) {
    return res.status(404).json({ error: 'Attorney not found' });
  }
  me.savedAdvocates ??= [];
  if (!me.savedAdvocates.includes(id)) {
    me.savedAdvocates.push(id);
    saveDb();
  }
  return res.json({ ids: me.savedAdvocates });
}

export function unsaveAdvocate(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const before = me.savedAdvocates?.length ?? 0;
  me.savedAdvocates = (me.savedAdvocates ?? []).filter((x) => x !== req.params.id);
  if (me.savedAdvocates.length !== before) saveDb();
  return res.json({ ids: me.savedAdvocates });
}
