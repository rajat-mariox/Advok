import type { Request, Response } from 'express';
import type { ConsultationPricing, PricingKey, SupportContact } from '../models';
import { DEFAULT_SUPPORT_CONTACT } from '../models';
import { getSettings, saveDb } from '../services/db.service';
import { publishToAdmins, publishToAll, publishToUser, publishToUsers } from '../services/realtime.service';

const CONSULTATION_KINDS: PricingKey[] = [
  'video_call',
  'phone_call',
  'office_visit',
  'law_firm_phone_call',
];

/** Consultation fees per type — read by the app's booking flow. */
export function getPricing(_req: Request, res: Response) {
  return res.json({ pricing: getSettings().consultationPricing });
}

/** Help & Support contact details — read by the app's Help screen. */
export function getSupportContact(_req: Request, res: Response) {
  return res.json({ support: getSettings().support ?? DEFAULT_SUPPORT_CONTACT });
}

const SUPPORT_FIELDS: (keyof SupportContact)[] = ['email', 'phone', 'hours', 'responseNote'];

/** Admin edits the support email / phone / hours shown in the app. */
export function updateSupportContact(req: Request, res: Response) {
  const body = (req.body ?? {}) as Partial<Record<string, unknown>>;
  const settings = getSettings();
  const next: SupportContact = { ...(settings.support ?? DEFAULT_SUPPORT_CONTACT) };
  for (const field of SUPPORT_FIELDS) {
    const value = body[field];
    if (value === undefined) continue;
    if (typeof value !== 'string' || value.trim().length > 200) {
      return res.status(400).json({ error: `${field} must be text (max 200 chars)` });
    }
    next[field] = value.trim();
  }
  if (!next.email.trim() && !next.phone.trim()) {
    return res.status(400).json({ error: 'Provide at least a support email or phone' });
  }
  settings.support = next;
  settings.updatedAt = new Date().toISOString();
  saveDb();
  publishToAll('settings', { what: 'support' });
  return res.json({ support: settings.support });
}

/** Admin sets the consultation fees shown (and charged) in the app. */
export function updatePricing(req: Request, res: Response) {
  const body = (req.body ?? {}) as Partial<Record<string, unknown>>;
  const next: Partial<ConsultationPricing> = {};
  for (const kind of CONSULTATION_KINDS) {
    const value = body[kind];
    if (value === undefined) continue;
    const amount = typeof value === 'number' ? value : Number(value);
    if (!Number.isFinite(amount) || amount < 0 || amount > 100000) {
      return res
        .status(400)
        .json({ error: `${kind} must be a price between 0 and 100000` });
    }
    next[kind] = Math.round(amount * 100) / 100;
  }
  if (Object.keys(next).length === 0) {
    return res.status(400).json({
      error: 'Send at least one of video_call, phone_call, office_visit, law_firm_phone_call',
    });
  }

  const settings = getSettings();
  settings.consultationPricing = { ...settings.consultationPricing, ...next };
  settings.updatedAt = new Date().toISOString();
  saveDb();
  publishToAll('settings', { what: 'pricing' });
  return res.json({ pricing: settings.consultationPricing });
}
