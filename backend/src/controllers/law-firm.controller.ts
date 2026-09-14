import type { Response } from 'express';
import type { AuthedRequest } from '../middlewares/auth.middleware';
import type { LawFirmProfile } from '../models';
import { getDb } from '../services/db.service';
import { feeForProvider } from '../services/pricing.service';

/**
 * Verified law firms the requesting user can browse — the client-side
 * "Law Firms" section under Top Attorneys. Same country scoping as
 * /advocates: firms without a country (pre-tracking data) stay visible.
 *
 * Only public-facing firm details are returned; the login phone and the
 * team members' personal phone numbers are not exposed.
 */
export function listLawFirms(req: AuthedRequest, res: Response) {
  const me = req.user!;
  const db = getDb();
  const list = db.users.filter((u) => {
    if (u.role !== 'law_firm' || !u.profile) return false;
    if (u.status !== 'approved' && u.status !== 'active') return false;
    if (me.country && u.country && u.country !== me.country) return false;
    return true;
  });
  return res.json({
    lawFirms: list.map((u) => {
      const p = u.profile as LawFirmProfile;
      const lawyers = p.lawyers ?? [];
      const expertise = Array.from(
        new Set(lawyers.flatMap((l) => l.expertise ?? []).map((e) => e.trim()).filter(Boolean)),
      );
      return {
        id: u.id,
        country: u.country ?? null,
        photo: p.photo ?? null,
        firmName: p.firmName,
        consultationFee: feeForProvider(db, u),
        foundedYear: p.foundedYear ?? null,
        contactPerson: p.contactPerson,
        // Phone / email are not public: the client gets them once the firm
        // accepts a consultation request (same as for an attorney).
        addressLine1: p.addressLine1,
        addressLine2: p.addressLine2 ?? null,
        city: p.city,
        state: p.state,
        zip: p.zip,
        totalLawyers: Number(p.totalLawyers) || lawyers.length,
        expertise,
        lawyers: lawyers.map((l) => ({
          fullName: l.fullName,
          designation: l.designation,
          yearsExperience: l.yearsExperience,
          barState: l.barState ?? null,
          licenseStatus: l.licenseStatus ?? null,
          expertise: l.expertise ?? [],
        })),
      };
    }),
  });
}
