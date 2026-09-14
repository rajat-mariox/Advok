import type { ConsultationKind } from './booking.model';
import type { SupportContact } from './support.model';

/**
 * Fee keys: one per consultation kind for individual attorneys, plus the
 * voice-consultation rate charged when a client books a law firm (or one
 * of its attorneys). A firm can override that with its own fee.
 */
export type PricingKey = ConsultationKind | 'law_firm_phone_call';

/** Consultation fee per key, in USD, set from the admin panel. */
export type ConsultationPricing = Record<PricingKey, number>;

export const DEFAULT_CONSULTATION_PRICING: ConsultationPricing = {
  video_call: 120,
  phone_call: 90,
  office_visit: 150,
  law_firm_phone_call: 150,
};

/** One suggested prompt chip on the app's empty ADVOK AI chat screen. */
export interface AiSuggestion {
  id: string;
  text: string;
  /** Inactive prompts stay in the admin list but are hidden in the app. */
  active: boolean;
}

export const DEFAULT_AI_SUGGESTIONS: AiSuggestion[] = [
  { id: 'sug_rights_arrest', text: 'What are my rights if I am arrested?', active: true },
  { id: 'sug_case_duration', text: 'How long do criminal cases take?', active: true },
  { id: 'sug_wrongful_termination', text: 'Can I sue for wrongful termination?', active: true },
  { id: 'sug_power_of_attorney', text: 'What is a power of attorney?', active: true },
];

/** Platform-wide settings — a single record with id 'global'. */
export interface AppSettings {
  id: 'global';
  consultationPricing: ConsultationPricing;
  /** Help & Support contact details shown in the app (admin-editable). */
  support?: SupportContact;
  /** Suggested prompts for ADVOK AI (admin-editable, toggle active). */
  aiSuggestions?: AiSuggestion[];
  updatedAt: string;
}
