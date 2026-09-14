// Legal Dictionary: Black's Law Dictionary 2nd ed. (1910, public domain)
// loaded from data/legal_terms.json, merged with the admin's overrides and
// ADVOK AI's cached plain-English explanations from the database.
import fs from 'fs';
import path from 'path';
import type { DbShape, LegalTermOverride } from '../models';
import { completeText, isAiConnected } from './ai.service';
import { getDb, saveDb } from './db.service';

const DATA_FILE = path.join(__dirname, '..', '..', 'data', 'legal_terms.json');

export const DICTIONARY_SOURCE_LABEL = "Black's Law Dictionary, 2nd Edition (1910)";

interface BaseTerm {
  slug: string;
  term: string;
  definition: string;
}

/** A term as the app and admin see it. */
export interface DictionaryTerm {
  slug: string;
  term: string;
  definition: string;
  /** Where the definition text comes from. */
  source: 'blacks2' | 'admin' | 'ai';
  sourceLabel: string;
  /** Base entry whose definition the admin rewrote. */
  edited: boolean;
  custom: boolean;
  aiOnly: boolean;
  hidden: boolean;
  plainEnglish?: string;
  plainEnglishAt?: string;
}

let base: BaseTerm[] = [];
let baseBySlug = new Map<string, BaseTerm>();
let loaded = false;

/** Reads the base dictionary once. Safe to call repeatedly. */
export function loadDictionary(): number {
  if (loaded) return base.length;
  loaded = true;
  try {
    const raw = JSON.parse(fs.readFileSync(DATA_FILE, 'utf-8')) as { terms?: BaseTerm[] };
    base = (raw.terms ?? []).filter((t) => t.slug && t.term && t.definition);
    baseBySlug = new Map(base.map((t) => [t.slug, t]));
    console.log(`Legal dictionary: ${base.length} terms loaded`);
  } catch (err) {
    console.error('Legal dictionary: could not load data/legal_terms.json:', err);
    base = [];
    baseBySlug = new Map();
  }
  return base.length;
}

export function slugify(term: string): string {
  return term
    .toLowerCase()
    .replace(/['’]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

function overrides(db: DbShape): LegalTermOverride[] {
  db.legalTerms ??= [];
  return db.legalTerms;
}

function merge(baseTerm: BaseTerm | undefined, o: LegalTermOverride | undefined): DictionaryTerm | null {
  if (!baseTerm && !o) return null;
  const custom = !baseTerm;
  const definition = o?.definition?.trim() || baseTerm?.definition || '';
  const source: DictionaryTerm['source'] = o?.definition?.trim()
    ? 'admin'
    : baseTerm
      ? 'blacks2'
      : 'ai';
  return {
    slug: (o ?? baseTerm)!.slug,
    term: o?.term?.trim() || baseTerm!.term,
    definition,
    source,
    sourceLabel:
      source === 'blacks2' ? DICTIONARY_SOURCE_LABEL : source === 'admin' ? 'ADVOK editorial' : 'ADVOK AI',
    edited: !!baseTerm && !!o?.definition?.trim(),
    custom,
    aiOnly: !!o?.aiOnly && !o?.definition?.trim(),
    hidden: !!o?.hidden,
    plainEnglish: o?.plainEnglish,
    plainEnglishAt: o?.plainEnglishAt,
  };
}

/** Every term (base + custom) with overrides applied. */
function allTerms(db: DbShape): DictionaryTerm[] {
  loadDictionary();
  const byslug = new Map<string, LegalTermOverride>(overrides(db).map((o) => [o.slug, o]));
  const out: DictionaryTerm[] = [];
  for (const b of base) {
    const t = merge(b, byslug.get(b.slug));
    if (t) out.push(t);
    byslug.delete(b.slug);
  }
  for (const o of byslug.values()) {
    const t = merge(undefined, o);
    if (t) out.push(t);
  }
  return out;
}

export function getTerm(db: DbShape, slug: string): DictionaryTerm | null {
  loadDictionary();
  const o = overrides(db).find((x) => x.slug === slug);
  return merge(baseBySlug.get(slug), o);
}

export interface SearchOptions {
  letter?: string;
  limit?: number;
  offset?: number;
  /** Admin view: include hidden and AI-only entries. */
  includeHidden?: boolean;
}

export interface TermSummary {
  slug: string;
  term: string;
  preview: string;
  source: DictionaryTerm['source'];
  edited: boolean;
  custom: boolean;
  aiOnly: boolean;
  hidden: boolean;
  hasPlainEnglish: boolean;
}

function summarize(t: DictionaryTerm): TermSummary {
  const preview = t.definition.length > 160 ? `${t.definition.slice(0, 157).trimEnd()}…` : t.definition;
  return {
    slug: t.slug,
    term: t.term,
    preview,
    source: t.source,
    edited: t.edited,
    custom: t.custom,
    aiOnly: t.aiOnly,
    hidden: t.hidden,
    hasPlainEnglish: !!t.plainEnglish,
  };
}

/**
 * Ranked search: exact term, then term starts with the query, then a word in
 * the term starts with it, then the term contains it, then (for queries of
 * four+ characters) the definition contains it. With no query, browses A–Z.
 */
export function searchTerms(
  db: DbShape,
  query: string,
  opts: SearchOptions = {},
): { terms: TermSummary[]; total: number } {
  const limit = Math.min(Math.max(opts.limit ?? 50, 1), 200);
  const offset = Math.max(opts.offset ?? 0, 0);
  const q = query.trim().toLowerCase();
  const letter = (opts.letter ?? '').trim().toUpperCase().slice(0, 1);

  // AI-only entries are findable by search but stay out of the A–Z browse.
  let pool = allTerms(db).filter((t) => opts.includeHidden || (!t.hidden && (q ? true : !t.aiOnly)));
  if (letter) pool = pool.filter((t) => t.term.toUpperCase().startsWith(letter));

  let ranked: DictionaryTerm[];
  if (!q) {
    ranked = pool.sort((a, b) => a.term.localeCompare(b.term));
  } else {
    const scored: { t: DictionaryTerm; score: number }[] = [];
    for (const t of pool) {
      const term = t.term.toLowerCase();
      let score = 0;
      if (term === q) score = 5;
      else if (term.startsWith(q)) score = 4;
      else if (term.split(/[\s\-]+/).some((w) => w.startsWith(q))) score = 3;
      else if (term.includes(q)) score = 2;
      else if (q.length >= 4 && t.definition.toLowerCase().includes(q)) score = 1;
      if (score > 0) scored.push({ t, score });
    }
    ranked = scored
      .sort((a, b) => b.score - a.score || a.t.term.length - b.t.term.length || a.t.term.localeCompare(b.t.term))
      .map((s) => s.t);
  }
  return { terms: ranked.slice(offset, offset + limit).map(summarize), total: ranked.length };
}

/** Number of visible terms under each initial letter, for the A–Z strip. */
export function letterCounts(db: DbShape): { letter: string; count: number }[] {
  const counts = new Map<string, number>();
  for (const t of allTerms(db)) {
    if (t.hidden || t.aiOnly) continue;
    const l = t.term.charAt(0).toUpperCase();
    if (!/[A-Z]/.test(l)) continue;
    counts.set(l, (counts.get(l) ?? 0) + 1);
  }
  return [...counts.entries()].sort().map(([letter, count]) => ({ letter, count }));
}

export function dictionaryStats(db: DbShape) {
  loadDictionary();
  const os = overrides(db);
  return {
    source: DICTIONARY_SOURCE_LABEL,
    baseCount: base.length,
    customCount: os.filter((o) => o.custom && !o.aiOnly).length,
    aiOnlyCount: os.filter((o) => o.aiOnly && !o.definition).length,
    editedCount: os.filter((o) => !o.custom && o.definition).length,
    hiddenCount: os.filter((o) => o.hidden).length,
    explainedCount: os.filter((o) => o.plainEnglish).length,
    aiConnected: isAiConnected(),
  };
}

// ------------------------------------------------------------- admin edits

export function upsertOverride(
  db: DbShape,
  slug: string,
  patch: Partial<Pick<LegalTermOverride, 'term' | 'definition' | 'hidden' | 'aiOnly'>>,
): LegalTermOverride {
  loadDictionary();
  const now = new Date().toISOString();
  const list = overrides(db);
  let o = list.find((x) => x.slug === slug);
  if (!o) {
    const b = baseBySlug.get(slug);
    o = {
      slug,
      term: patch.term?.trim() || b?.term || slug,
      custom: !b,
      createdAt: now,
      updatedAt: now,
    };
    list.push(o);
  }
  if (patch.term?.trim()) o.term = patch.term.trim();
  if (patch.definition !== undefined) {
    const d = patch.definition.trim();
    if (d) o.definition = d;
    else delete o.definition;
  }
  if (patch.hidden !== undefined) o.hidden = patch.hidden;
  if (patch.aiOnly !== undefined) o.aiOnly = patch.aiOnly;
  if (o.definition) o.aiOnly = false;
  o.updatedAt = now;
  return o;
}

/** Custom terms are deleted; base terms are hidden instead (the file is read-only). */
export function removeTerm(db: DbShape, slug: string): 'deleted' | 'hidden' | 'missing' {
  loadDictionary();
  const list = overrides(db);
  const idx = list.findIndex((x) => x.slug === slug);
  if (baseBySlug.has(slug)) {
    upsertOverride(db, slug, { hidden: true });
    return 'hidden';
  }
  if (idx === -1) return 'missing';
  list.splice(idx, 1);
  return 'deleted';
}

// ---------------------------------------------------------- AI explanation

const EXPLAIN_SYSTEM = `You are a law-school teaching assistant inside the ADVOK app.
Explain one legal term for a law student in plain English.
Write four short paragraphs, in this order, in plain text with no Markdown and WITHOUT numbering or labels:
- a one-sentence definition in modern language;
- how it is used today (2–3 sentences);
- one concrete example (1–2 sentences);
- if the student's country treats the term differently, or does not use it, one sentence saying so (omit this paragraph if it is used the same way).
Keep it under 170 words. Never invent statutes or case names. Do not repeat the historical dictionary text verbatim.`;

/**
 * Plain-English explanation of a term, cached on its override record. For a
 * term missing from the dictionary the explanation is generated from the
 * term alone and stored as an AI-only entry so the next student gets it
 * instantly.
 */
export async function explainTerm(
  db: DbShape,
  input: { slug?: string; term?: string },
  opts: { country?: string; regenerate?: boolean } = {},
): Promise<{ term: DictionaryTerm; cached: boolean }> {
  loadDictionary();
  let slug = input.slug?.trim() || (input.term ? slugify(input.term) : '');
  if (!slug) throw new Error('term is required');
  let existing = getTerm(db, slug);
  if (!existing && !input.term?.trim()) throw new Error('Term not found');

  if (existing?.plainEnglish && !opts.regenerate) {
    return { term: existing, cached: true };
  }
  if (!isAiConnected()) throw new Error('ADVOK AI is not connected yet');

  const termLabel = existing?.term ?? input.term!.trim();
  const country = opts.country?.trim() || 'United States';
  const user = [
    `Term: ${termLabel}`,
    `Student's country: ${country}`,
    existing?.definition
      ? `Historical dictionary entry (${existing.sourceLabel}, may contain OCR errors):\n${existing.definition.slice(0, 1200)}`
      : 'The term is not in the historical dictionary; explain it from your own knowledge.',
  ].join('\n\n');
  const explanation = await completeText(EXPLAIN_SYSTEM, user, { maxTokens: 400, temperature: 0.2 });

  const now = new Date().toISOString();
  const o = upsertOverride(db, slug, existing ? {} : { term: termLabel, aiOnly: true });
  o.plainEnglish = explanation;
  o.plainEnglishAt = now;
  o.updatedAt = now;
  saveDb();
  existing = getTerm(db, slug);
  return { term: existing!, cached: false };
}

/** Convenience for controllers that don't hold a db reference. */
export function currentDb(): DbShape {
  return getDb();
}
