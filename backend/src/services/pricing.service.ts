// Which voice-consultation fee applies to a provider.
//
// - Individual attorney → platform `phone_call` rate.
// - Law firm → the firm's own fee when set, else platform `law_firm_phone_call`.
// - Attorney linked to a firm → the firm's fee (the booking is billed to the firm).
import type { DbShape, LawFirmProfile, User } from '../models';
import { getSettings } from './db.service';

export function feeForProvider(db: DbShape, user: User | undefined): number {
  const pricing = getSettings().consultationPricing;
  if (!user) return pricing.phone_call;
  if (user.role === 'law_firm') {
    const fp = user.profile as LawFirmProfile | undefined;
    return typeof fp?.consultationFee === 'number' && fp.consultationFee >= 0
      ? fp.consultationFee
      : pricing.law_firm_phone_call;
  }
  if (user.role === 'advocate' && user.firmId) {
    const firm = db.users.find((u) => u.id === user.firmId);
    if (firm) return feeForProvider(db, firm);
  }
  return pricing.phone_call;
}
