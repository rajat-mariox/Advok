import type { BarAdmission } from '../models';

/** Names (dot-paths allowed) of required fields missing from the body. */
export function missingFields(body: Record<string, unknown>, fields: string[]): string[] {
  return fields.filter((f) => {
    const value = f.split('.').reduce<unknown>((obj, key) => {
      if (obj && typeof obj === 'object') return (obj as Record<string, unknown>)[key];
      return undefined;
    }, body);
    return value === undefined || value === null || value === '';
  });
}

/** Keeps only complete US state bar admissions (state + bar number + status). */
export function parseBarAdmissions(value: unknown): BarAdmission[] {
  if (!Array.isArray(value)) return [];
  return value
    .filter(
      (a: Record<string, unknown>) =>
        a && typeof a.state === 'string' && a.state &&
        typeof a.barNumber === 'string' && a.barNumber &&
        typeof a.licenseStatus === 'string' && a.licenseStatus,
    )
    .map((a: Record<string, string>) => ({
      state: a.state,
      barNumber: a.barNumber,
      licenseStatus: a.licenseStatus,
    }));
}

/** Keeps only non-empty federal court admission names. */
export function parseFederalCourtAdmissions(value: unknown): string[] {
  if (!Array.isArray(value)) return [];
  return value.filter((c: unknown): c is string => typeof c === 'string' && c !== '');
}
