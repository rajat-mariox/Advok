/** Returns the trimmed string, or undefined for anything empty/non-string. */
export const str = (v: unknown): string | undefined =>
  typeof v === 'string' && v.trim() ? v.trim() : undefined;
