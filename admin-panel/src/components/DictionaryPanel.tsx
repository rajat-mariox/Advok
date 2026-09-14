import { useEffect, useState } from 'react';
import {
  createDictionaryTerm,
  deleteDictionaryTerm,
  fetchDictionaryStats,
  fetchDictionaryTerm,
  searchDictionary,
  updateDictionaryTerm,
  type DictionaryStats,
  type DictionaryTerm,
  type DictionaryTermSummary,
} from '../utils/backend';
import { IconBook, IconPlus, IconSearch, IconTrash } from './Icon';
import { Badge, DetailSection, Drawer, ListEmpty, StatCard } from './ui';

const PAGE = 50;
const LETTERS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

type Draft = {
  slug?: string;
  term: string;
  definition: string;
  hidden: boolean;
  custom: boolean;
  edited: boolean;
  aiOnly: boolean;
  plainEnglish?: string;
  sourceLabel?: string;
};

function sourceBadge(t: { source: string; edited: boolean; custom: boolean; aiOnly: boolean; hidden: boolean }) {
  if (t.hidden) return 'Hidden';
  if (t.aiOnly) return 'AI only';
  if (t.custom) return 'Custom';
  if (t.edited) return 'Edited';
  return "Black's 2nd ed.";
}

/** Legal Dictionary tab on the Learning Content page. */
export default function DictionaryPanel() {
  const [stats, setStats] = useState<DictionaryStats | null>(null);
  const [query, setQuery] = useState('');
  const [letter, setLetter] = useState('');
  const [terms, setTerms] = useState<DictionaryTermSummary[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [draft, setDraft] = useState<Draft | null>(null);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState('');

  const load = async (q = query, l = letter, offset = 0) => {
    setLoading(true);
    setError('');
    try {
      const r = await searchDictionary(q, { letter: l, limit: PAGE, offset });
      setTerms((prev) => (offset > 0 ? [...prev, ...r.terms] : r.terms));
      setTotal(r.total);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not load the dictionary');
    } finally {
      setLoading(false);
    }
  };

  const loadStats = () => fetchDictionaryStats().then(setStats).catch(() => setStats(null));

  useEffect(() => {
    void loadStats();
    void load('', '');
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    const t = setTimeout(() => void load(query, query.trim() ? '' : letter), 300);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [query, letter]);

  const openEdit = async (s: DictionaryTermSummary) => {
    setSaveError('');
    const full: DictionaryTerm | null = await fetchDictionaryTerm(s.slug).catch(() => null);
    setDraft({
      slug: s.slug,
      term: full?.term ?? s.term,
      definition: full?.definition ?? '',
      hidden: full?.hidden ?? s.hidden,
      custom: full?.custom ?? s.custom,
      edited: full?.edited ?? s.edited,
      aiOnly: full?.aiOnly ?? s.aiOnly,
      plainEnglish: full?.plainEnglish,
      sourceLabel: full?.sourceLabel,
    });
  };

  const startAdd = () => {
    setSaveError('');
    setDraft({ term: query.trim(), definition: '', hidden: false, custom: true, edited: false, aiOnly: false });
  };

  const save = async () => {
    if (!draft) return;
    if (!draft.term.trim() || !draft.definition.trim()) {
      setSaveError('Term and definition are required.');
      return;
    }
    setSaving(true);
    setSaveError('');
    try {
      if (draft.slug) {
        await updateDictionaryTerm(draft.slug, { term: draft.term, definition: draft.definition, hidden: draft.hidden });
      } else {
        await createDictionaryTerm(draft.term, draft.definition);
      }
      setDraft(null);
      await Promise.all([load(query, letter), loadStats()]);
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Could not save');
    } finally {
      setSaving(false);
    }
  };

  const remove = async (s: { slug: string; term: string; custom: boolean }) => {
    const verb = s.custom ? 'Delete' : 'Hide';
    if (!window.confirm(`${verb} "${s.term}"?${s.custom ? '' : ' Base dictionary entries are hidden, not deleted.'}`)) return;
    const ok = await deleteDictionaryTerm(s.slug);
    if (ok) {
      setDraft(null);
      await Promise.all([load(query, letter), loadStats()]);
    }
  };

  return (
    <>
      <div className="grid-stats" style={{ marginBottom: 22 }}>
        <StatCard icon={<IconBook />} value={stats ? (stats.baseCount + stats.customCount).toLocaleString('en-US') : '—'} label="Dictionary Terms" trend={stats ? `${stats.baseCount.toLocaleString('en-US')} from ${stats.source}` : 'Loading…'} />
        <StatCard icon={<IconBook />} value={stats ? String(stats.customCount + stats.editedCount) : '—'} label="Editorial Entries" trend={stats ? `${stats.customCount} added · ${stats.editedCount} rewritten · ${stats.hiddenCount} hidden` : ''} />
        <StatCard icon={<IconBook />} value={stats ? String(stats.explainedCount) : '—'} label="AI Explanations" trend={stats ? (stats.aiConnected ? 'Cached plain-English explanations' : 'ADVOK AI not connected (GROQ_API_KEY)') : ''} />
      </div>

      <DetailSection
        title="Find a term"
        aside={
          <button className="btn-pill-grey" onClick={startAdd}>
            <IconPlus /> Add term
          </button>
        }
      >
        <div style={{ padding: '8px 0', display: 'grid', gap: 10 }}>
          <div className="row" style={{ gap: 8 }}>
            <IconSearch />
            <input
              className="input"
              placeholder="Search by term or definition, e.g. habeas corpus"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />
          </div>
          <div className="row" style={{ gap: 4, flexWrap: 'wrap' }}>
            {LETTERS.map((l) => (
              <button
                key={l}
                className={`btn-pill-grey${letter === l ? ' active' : ''}`}
                style={{ minWidth: 30, padding: '0 8px', fontWeight: letter === l ? 700 : 500 }}
                onClick={() => {
                  setQuery('');
                  setLetter(letter === l ? '' : l);
                }}
              >
                {l}
              </button>
            ))}
          </div>
          <div className="cell-sub">
            Base text is Black's Law Dictionary, 2nd Edition (1910), public domain, digitised by OCR. Rewrite an
            entry to fix OCR errors or modernise it; hide an entry to remove it from the app; add terms the
            1910 edition lacks (e.g. modern or Indian-law terms). Students can ask ADVOK AI for a plain-English
            explanation of any term — those are cached and shown here as "AI explanation".
          </div>
        </div>
      </DetailSection>

      <div className="table-card">
        <table className="data">
          <thead>
            <tr>
              <th style={{ width: '22%' }}>Term</th>
              <th>Definition</th>
              <th style={{ width: 120 }}>Source</th>
              <th style={{ width: 90 }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {terms.map((t) => (
              <tr key={t.slug}>
                <td>
                  <div className="cell-strong">{t.term}</div>
                  {t.hasPlainEnglish && <div className="cell-sub">AI explanation cached</div>}
                </td>
                <td>
                  <div className="cell-sub" style={{ whiteSpace: 'normal', lineHeight: 1.45 }}>{t.preview}</div>
                </td>
                <td><Badge label={sourceBadge(t)} /></td>
                <td>
                  <div className="row" style={{ gap: 6 }}>
                    <button className="icon-btn" title="Edit" onClick={() => openEdit(t)}><IconBook size={15} /></button>
                    <button className="icon-btn icon-btn-danger" title={t.custom ? 'Delete' : 'Hide from app'} onClick={() => remove(t)}><IconTrash /></button>
                  </div>
                </td>
              </tr>
            ))}
            {terms.length === 0 && (
              <tr>
                <td colSpan={4} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  {loading ? 'Loading…' : error || 'No terms match.'}
                </td>
              </tr>
            )}
          </tbody>
        </table>
        {terms.length < total && (
          <div style={{ padding: 12, textAlign: 'center', borderTop: '1px solid var(--divider)' }}>
            <button className="btn-pill-grey" disabled={loading} onClick={() => load(query, letter, terms.length)}>
              {loading ? 'Loading…' : `Show more (${(total - terms.length).toLocaleString('en-US')} left)`}
            </button>
          </div>
        )}
      </div>

      {draft && (
        <Drawer
          wide
          title={draft.slug ? 'Edit Term' : 'Add Term'}
          onClose={() => setDraft(null)}
          footer={
            <div className="row" style={{ gap: 10 }}>
              {draft.slug && (
                <button className="btn-danger" style={{ height: 44, borderRadius: 14, padding: '0 16px' }} onClick={() => remove({ slug: draft.slug!, term: draft.term, custom: draft.custom })} disabled={saving}>
                  <IconTrash />
                </button>
              )}
              <button className="btn-secondary" style={{ flex: 1 }} onClick={() => setDraft(null)} disabled={saving}>Cancel</button>
              <button className="btn-primary" style={{ flex: 1 }} onClick={save} disabled={saving}>{saving ? 'Saving…' : 'Save'}</button>
            </div>
          }
        >
          <DetailSection title="Entry">
            <div style={{ padding: '8px 0', display: 'grid', gap: 12 }}>
              <div>
                <label className="field-label">Term</label>
                <input className="input" value={draft.term} onChange={(e) => setDraft({ ...draft, term: e.target.value })} />
              </div>
              <div>
                <label className="field-label">Definition{draft.slug && !draft.custom ? ` (rewrites the ${draft.sourceLabel ?? 'dictionary'} text)` : ''}</label>
                <textarea className="input" style={{ height: 180, padding: 12, resize: 'vertical', lineHeight: 1.5 }} value={draft.definition} onChange={(e) => setDraft({ ...draft, definition: e.target.value })} />
              </div>
              {draft.slug && (
                <div className="row" style={{ gap: 10 }}>
                  <button type="button" role="switch" aria-checked={!draft.hidden} className={`switch${!draft.hidden ? ' on' : ''}`} onClick={() => setDraft({ ...draft, hidden: !draft.hidden })} />
                  <span style={{ fontSize: 13, fontWeight: 600 }}>{draft.hidden ? 'Hidden from students' : 'Visible to students'}</span>
                </div>
              )}
              {saveError && <div className="note-box" style={{ marginBottom: 0 }}>{saveError}</div>}
            </div>
          </DetailSection>
          {draft.plainEnglish ? (
            <DetailSection title="AI explanation (as students see it)" flush>
              <div style={{ padding: '12px 14px', fontSize: 12.5, lineHeight: 1.6, whiteSpace: 'pre-wrap', color: 'var(--text-grey-555)' }}>{draft.plainEnglish}</div>
            </DetailSection>
          ) : (
            draft.slug && <ListEmpty text="No AI explanation cached yet — it is generated the first time a student asks." />
          )}
        </Drawer>
      )}
    </>
  );
}
