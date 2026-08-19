import type { CmsSection } from '../models';

/** Every section needs a non-empty title and body. */
export function isValidSections(sections: unknown): sections is CmsSection[] {
  return (
    Array.isArray(sections) &&
    sections.length > 0 &&
    sections.every(
      (s: CmsSection) =>
        s &&
        typeof s.title === 'string' &&
        typeof s.body === 'string' &&
        s.title.trim() !== '' &&
        s.body.trim() !== '',
    )
  );
}
