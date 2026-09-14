import { useEffect, useMemo, useState } from 'react';
import CaseNotesEditor from '../components/CaseNotesEditor';
import DictionaryPanel from '../components/DictionaryPanel';
import { IconBook, IconFile, IconPlus, IconSearch, IconTrash } from '../components/Icon';
import {
  Badge,
  ChipList,
  DetailGrid,
  DetailSection,
  Drawer,
  FilterChips,
  ListEmpty,
  PageHeader,
  StatCard,
} from '../components/ui';
import {
  createCaseStudy,
  deleteCaseStudy,
  fetchCaseStudies,
  fetchCaseStudy,
  fetchLegalNews,
  fetchNewsSources,
  refreshCaseStudyText,
  refreshLegalNews,
  searchCourtListener,
  updateCaseStudy,
  type CaseStudyCard,
  type CaseStudyLevel,
  type NewsItem,
  type NewsStatus,
  type OpinionSearchHit,
} from '../utils/backend';
import { US_PRACTICE_AREAS } from '../utils/seed';
import { useRealtime } from '../utils/realtime';

const TABS = ['Cases to Read', 'Legal News', 'Legal Dictionary'];
const LEVELS: CaseStudyLevel[] = ['Beginner', 'Intermediate', 'Advanced'];
const TAGS = ['Constitutional Law', 'Civil Rights', ...US_PRACTICE_AREAS];

const COURTS = [
  { id: '', label: 'All courts' },
  { id: 'scotus', label: 'U.S. Supreme Court' },
  { id: 'ca1 ca2 ca3 ca4 ca5 ca6 ca7 ca8 ca9 ca10 ca11 cadc cafc', label: 'Federal Courts of Appeals' },
];

const LANDMARKS = [
  'Marbury v. Madison',
  'Brown v. Board of Education',
  'Miranda v. Arizona',
  'Gideon v. Wainwright',
  'Mapp v. Ohio',
  'Obergefell v. Hodges',
];

const EMPTY_HIT: OpinionSearchHit = {
  clusterId: 0,
  title: '',
  court: '',
  courtId: '',
  dateFiled: '',
  citation: '',
  citations: [],
  docketNumber: '',
  judges: '',
  citeCount: 0,
  snippet: '',
  syllabus: '',
};

type AddDraft = {
  hit: OpinionSearchHit;
  /** Manual entry (not from CourtListener) — court/date/citation are editable. */
  manual?: boolean;
  tag: string;
  level: CaseStudyLevel;
  summary: string;
  principle: string;
  published: boolean;
};

export default function ContentPage() {
  const [tab, setTab] = useState(TABS[0]);

  // Curated list
  const [cases, setCases] = useState<CaseStudyCard[]>([]);
  const [fullTextAvailable, setFullTextAvailable] = useState(false);
  const [loadError, setLoadError] = useState('');
  const [loading, setLoading] = useState(true);

  // Search
  const [query, setQuery] = useState('');
  const [court, setCourt] = useState('scotus');
  const [hits, setHits] = useState<OpinionSearchHit[]>([]);
  const [searching, setSearching] = useState(false);
  const [searchError, setSearchError] = useState('');

  // Legal news
  const [news, setNews] = useState<NewsItem[]>([]);
  const [newsStatus, setNewsStatus] = useState<NewsStatus | null>(null);
  const [newsLoading, setNewsLoading] = useState(false);
  const [newsError, setNewsError] = useState('');
  const [newsTag, setNewsTag] = useState('All');

  // Add / edit drawers
  const [draft, setDraft] = useState<AddDraft | null>(null);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState('');
  const [editing, setEditing] = useState<CaseStudyCard | null>(null);
  const [preview, setPreview] = useState<{ syllabus: string; opinionText: string } | null>(null);

  const load = () =>
    fetchCaseStudies()
      .then((r) => {
        setCases(r.cases);
        setFullTextAvailable(r.fullTextAvailable);
        setLoadError('');
      })
      .catch(() => setLoadError('Could not load cases. Make sure the backend is running.'));

  useEffect(() => {
    load().finally(() => setLoading(false));
  }, []);
  useRealtime(['content'], () => {
    void load();
  });

  const loadNews = async (force = false) => {
    setNewsLoading(true);
    setNewsError('');
    try {
      if (force) {
        const r = await refreshLegalNews();
        setNews(r.news);
        setNewsStatus(r);
      } else {
        const [items, status] = await Promise.all([fetchLegalNews(), fetchNewsSources()]);
        setNews(items);
        setNewsStatus(status);
      }
    } catch (err) {
      setNewsError(err instanceof Error ? err.message : 'Could not load news');
    } finally {
      setNewsLoading(false);
    }
  };

  useEffect(() => {
    if (tab === TABS[1] && news.length === 0 && !newsLoading) void loadNews();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tab]);

  const startManualAdd = () => {
    setSaveError('');
    setDraft({
      hit: { ...EMPTY_HIT },
      manual: true,
      tag: 'Constitutional Law',
      level: 'Intermediate',
      summary: '',
      principle: '',
      published: true,
    });
  };

  const published = cases.filter((c) => c.published).length;
  const totalReads = cases.reduce((s, c) => s + c.reads, 0);
  const addedIds = useMemo(() => new Set(cases.map((c) => c.clusterId)), [cases]);

  const search = async (q = query) => {
    const text = q.trim();
    if (!text) return;
    setQuery(text);
    setSearching(true);
    setSearchError('');
    try {
      const r = await searchCourtListener(text, court);
      setHits(r.results);
      setFullTextAvailable(r.fullTextAvailable);
      if (r.results.length === 0) setSearchError('No opinions matched. Try the case name in quotes.');
    } catch (err) {
      setSearchError(err instanceof Error ? err.message : 'Search failed');
    } finally {
      setSearching(false);
    }
  };

  const startAdd = (hit: OpinionSearchHit) => {
    setSaveError('');
    setDraft({
      hit,
      tag: 'Constitutional Law',
      level: 'Intermediate',
      summary: hit.syllabus || hit.snippet || '',
      principle: '',
      published: true,
    });
  };

  const saveAdd = async () => {
    if (!draft) return;
    if (draft.manual && !draft.hit.title.trim()) {
      setSaveError('Case name is required');
      return;
    }
    setSaving(true);
    setSaveError('');
    try {
      await createCaseStudy({
        ...draft.hit,
        tag: draft.tag,
        level: draft.level,
        summary: draft.summary,
        principle: draft.principle,
        published: draft.published,
      });
      setDraft(null);
      await load();
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Failed to add case');
    } finally {
      setSaving(false);
    }
  };

  const togglePublished = async (c: CaseStudyCard) => {
    const updated = await updateCaseStudy(c.id, { published: !c.published }).catch(() => null);
    if (updated) setCases((prev) => prev.map((x) => (x.id === c.id ? updated : x)));
  };

  const openEdit = async (c: CaseStudyCard) => {
    setEditing({ ...c });
    setPreview(null);
    setSaveError('');
    const full = await fetchCaseStudy(c.id).catch(() => null);
    if (full) setPreview({ syllabus: full.syllabus, opinionText: full.opinionText });
  };

  const saveEdit = async () => {
    if (!editing) return;
    setSaving(true);
    setSaveError('');
    try {
      const updated = await updateCaseStudy(editing.id, {
        title: editing.title,
        tag: editing.tag,
        level: editing.level,
        summary: editing.summary,
        principle: editing.principle,
        published: editing.published,
      });
      setCases((prev) => prev.map((x) => (x.id === updated.id ? updated : x)));
      setEditing(null);
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Failed to save');
    } finally {
      setSaving(false);
    }
  };

  const pullText = async () => {
    if (!editing) return;
    setSaving(true);
    setSaveError('');
    try {
      const updated = await refreshCaseStudyText(editing.id);
      setCases((prev) => prev.map((x) => (x.id === updated.id ? updated : x)));
      setEditing((e) => (e ? { ...e, hasFullText: updated.hasFullText, mins: updated.mins } : e));
      const full = await fetchCaseStudy(updated.id);
      setPreview({ syllabus: full.syllabus, opinionText: full.opinionText });
    } catch (err) {
      setSaveError(err instanceof Error ? err.message : 'Failed to fetch text');
    } finally {
      setSaving(false);
    }
  };

  const remove = async (c: CaseStudyCard) => {
    if (!window.confirm(`Remove "${c.title}" from Cases to Read?`)) return;
    const ok = await deleteCaseStudy(c.id);
    if (ok) {
      setCases((prev) => prev.filter((x) => x.id !== c.id));
      if (editing?.id === c.id) setEditing(null);
    }
  };

  const move = async (c: CaseStudyCard, dir: -1 | 1) => {
    const idx = cases.findIndex((x) => x.id === c.id);
    const j = idx + dir;
    if (idx < 0 || j < 0 || j >= cases.length) return;
    const next = [...cases];
    [next[idx], next[j]] = [next[j], next[idx]];
    setCases(next);
    await Promise.all(next.map((x, i) => updateCaseStudy(x.id, { sortOrder: i }).catch(() => null)));
  };

  return (
    <div>
      <PageHeader
        eyebrow="Content"
        title="Learning Content"
        subtitle="Real court opinions from CourtListener, curated for law students. Only published cases appear in the app."
      />

      <div className="grid-stats" style={{ marginBottom: 22 }}>
        <StatCard icon={<IconBook />} value={String(cases.length)} label="Cases to Read" trend={`${published} published · ${cases.length - published} hidden`} />
        <StatCard icon={<IconBook />} value={totalReads.toLocaleString('en-US')} label="Total Case Reads" trend="Opened by students in the app" />
        <StatCard
          icon={<IconFile />}
          value={fullTextAvailable ? 'On' : 'Off'}
          label="Full Opinion Text"
          trend={fullTextAvailable ? 'CourtListener token set' : 'Add COURTLISTENER_API_TOKEN to backend/.env'}
        />
      </div>

      <div style={{ marginBottom: 16 }}>
        <FilterChips options={TABS} active={tab} onChange={setTab} />
      </div>

      {tab === TABS[2] ? (
        <DictionaryPanel />
      ) : tab === TABS[0] ? (
        <>
          <DetailSection
            title="Find a case on CourtListener"
            aside={
              <button className="btn-pill-grey" onClick={startManualAdd}>
                <IconPlus size={12} /> Add manually
              </button>
            }
            flush
          >
            <div style={{ padding: 14 }}>
              <div className="row" style={{ gap: 10, flexWrap: 'wrap' }}>
                <div className="search-wrap" style={{ flex: 1, minWidth: 260 }}>
                  <IconSearch />
                  <input
                    className="input"
                    placeholder='Case name, e.g. "Brown v. Board of Education"'
                    value={query}
                    onChange={(e) => setQuery(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && search()}
                  />
                </div>
                <select className="input" style={{ width: 220 }} value={court} onChange={(e) => setCourt(e.target.value)}>
                  {COURTS.map((c) => (
                    <option key={c.id} value={c.id}>{c.label}</option>
                  ))}
                </select>
                <button className="btn-primary" onClick={() => search()} disabled={searching || !query.trim()}>
                  {searching ? 'Searching…' : 'Search'}
                </button>
              </div>
              <div className="row" style={{ gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
                <span className="cell-sub" style={{ marginTop: 0, marginRight: 4 }}>Landmark cases:</span>
                {LANDMARKS.map((l) => (
                  <button key={l} className="chip" onClick={() => search(`"${l}"`)}>{l}</button>
                ))}
              </div>
              {searchError && <div className="note-box" style={{ marginTop: 12, marginBottom: 0 }}>{searchError}</div>}
            </div>
            {hits.length > 0 && (
              <div style={{ borderTop: '1px solid var(--divider)' }}>
                {hits.map((h) => {
                  const added = addedIds.has(h.clusterId) || h.alreadyAdded;
                  return (
                    <div key={h.clusterId} className="list-item" style={{ alignItems: 'flex-start' }}>
                      <div className="list-item-main" style={{ flex: 1 }}>
                        <div className="list-item-title" style={{ whiteSpace: 'normal' }}>{h.title}</div>
                        <div className="list-item-sub">
                          {[h.court, h.dateFiled?.slice(0, 4), h.citation, h.citeCount ? `cited ${h.citeCount.toLocaleString('en-US')}×` : '']
                            .filter(Boolean)
                            .join(' · ')}
                        </div>
                        {h.snippet && (
                          <div className="cell-sub" style={{ marginTop: 4, whiteSpace: 'normal', lineHeight: 1.5 }}>
                            {h.snippet.slice(0, 220)}{h.snippet.length > 220 ? '…' : ''}
                          </div>
                        )}
                      </div>
                      {added ? (
                        <Badge label="Added" />
                      ) : (
                        <button className="btn-pill" onClick={() => startAdd(h)}>
                          <IconPlus size={12} /> Add
                        </button>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </DetailSection>

          <div className="table-card">
            <table className="data">
              <thead>
                <tr>
                  <th style={{ width: 40 }}>#</th>
                  <th>Case</th>
                  <th>Court · Year</th>
                  <th>Tag</th>
                  <th>Level</th>
                  <th>Read Time</th>
                  <th>Full Text</th>
                  <th>Reads</th>
                  <th>Visible to Students</th>
                  <th style={{ textAlign: 'center' }}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {cases.map((c, i) => (
                  <tr key={c.id} className="clickable" onClick={() => openEdit(c)}>
                    <td onClick={(e) => e.stopPropagation()}>
                      <div className="row" style={{ gap: 2 }}>
                        <button className="icon-btn" style={{ width: 22, height: 22 }} title="Move up" disabled={i === 0} onClick={() => move(c, -1)}>↑</button>
                        <button className="icon-btn" style={{ width: 22, height: 22 }} title="Move down" disabled={i === cases.length - 1} onClick={() => move(c, 1)}>↓</button>
                      </div>
                    </td>
                    <td>
                      <div className="cell-strong" style={{ whiteSpace: 'normal', lineHeight: 1.4 }}>{c.title}</div>
                      <div className="cell-sub">{c.citation || c.docketNumber || '—'}</div>
                    </td>
                    <td>
                      <div>{c.court}</div>
                      <div className="cell-sub">{c.year}</div>
                    </td>
                    <td>{c.tag}</td>
                    <td><Badge label={c.level} /></td>
                    <td>{c.mins} min</td>
                    <td>{c.hasFullText ? <Badge label="Full" /> : <span className="cell-sub" style={{ marginTop: 0 }}>Summary only</span>}</td>
                    <td>{c.reads > 0 ? c.reads.toLocaleString('en-US') : '—'}</td>
                    <td onClick={(e) => e.stopPropagation()}>
                      <div className="row" style={{ gap: 8 }}>
                        <button
                          type="button"
                          role="switch"
                          aria-checked={c.published}
                          className={`switch${c.published ? ' on' : ''}`}
                          title={c.published ? 'Published — tap to hide' : 'Hidden — tap to publish'}
                          onClick={() => togglePublished(c)}
                        />
                        <span className="cell-sub" style={{ marginTop: 0 }}>{c.published ? 'Published' : 'Hidden'}</span>
                      </div>
                    </td>
                    <td style={{ textAlign: 'center' }} onClick={(e) => e.stopPropagation()}>
                      <div className="row-actions">
                        <button className="icon-btn" title="Edit" onClick={() => openEdit(c)}><IconBook size={15} /></button>
                        <button className="icon-btn icon-btn-danger" title="Remove" onClick={() => remove(c)}><IconTrash /></button>
                      </div>
                    </td>
                  </tr>
                ))}
                {cases.length === 0 && (
                  <tr>
                    <td colSpan={10} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                      {loading ? 'Loading…' : loadError || 'No cases yet. Search CourtListener above and add the ones students should read.'}
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </>
      ) : (
        <>
          <DetailSection
            title="Sources"
            aside={
              <button className="btn-pill-grey" onClick={() => loadNews(true)} disabled={newsLoading}>
                {newsLoading ? 'Refreshing…' : 'Refresh now'}
              </button>
            }
            flush
          >
            {newsStatus ? (
              newsStatus.sources.map((src) => (
                <div key={src.key} className="list-item">
                  <div className="list-item-main">
                    <div className="list-item-title">{src.name}</div>
                    <div className="list-item-sub">
                      {src.url} · default tag {src.defaultTag}
                      {src.error ? ` · ${src.error}` : ''}
                    </div>
                  </div>
                  <div className="row" style={{ gap: 8 }}>
                    <span className="cell-sub" style={{ marginTop: 0 }}>{src.ok ? `${src.items} items` : ''}</span>
                    <Badge label={src.ok ? 'Online' : 'Rejected'} />
                  </div>
                </div>
              ))
            ) : (
              <ListEmpty text={newsError || 'Loading sources…'} />
            )}
            <div style={{ padding: '10px 14px', borderTop: '1px solid var(--divider)' }} className="cell-sub">
              Public RSS feeds, no API key. Cached for 30 minutes on the backend. Items are tagged
              automatically (Supreme Court, Federal Courts, Legislation, Bar Exam, Legal News).
              {newsStatus?.fetchedAt ? ` Last fetched ${new Date(newsStatus.fetchedAt).toLocaleString()}.` : ''}
            </div>
          </DetailSection>

          <div style={{ marginBottom: 12 }}>
            <FilterChips options={['All', ...(newsStatus?.tags ?? [])]} active={newsTag} onChange={setNewsTag} />
          </div>

          <div className="table-card">
            <table className="data">
              <thead>
                <tr>
                  <th style={{ width: '46%' }}>Article</th>
                  <th>Source</th>
                  <th>Tag</th>
                  <th>Published</th>
                  <th>Link</th>
                </tr>
              </thead>
              <tbody>
                {news
                  .filter((n) => newsTag === 'All' || n.tag === newsTag)
                  .map((n) => (
                    <tr key={n.id}>
                      <td>
                        <div className="cell-strong" style={{ whiteSpace: 'normal', lineHeight: 1.4 }}>{n.title}</div>
                        {n.excerpt && (
                          <div className="cell-sub" style={{ whiteSpace: 'normal', lineHeight: 1.45 }}>
                            {n.excerpt.slice(0, 160)}{n.excerpt.length > 160 ? '…' : ''}
                          </div>
                        )}
                      </td>
                      <td>{n.source}</td>
                      <td><Badge label={n.tag} /></td>
                      <td style={{ whiteSpace: 'nowrap' }}>{new Date(n.publishedAt).toLocaleDateString(undefined, { day: 'numeric', month: 'short' })}</td>
                      <td>
                        <a href={n.url} target="_blank" rel="noreferrer" className="btn-pill-grey" style={{ textDecoration: 'none' }}>
                          Open
                        </a>
                      </td>
                    </tr>
                  ))}
                {news.length === 0 && (
                  <tr>
                    <td colSpan={5} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                      {newsLoading ? 'Loading US legal news…' : newsError || 'No articles yet.'}
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </>
      )}

      {draft && (
        <Drawer
          wide
          title="Add Case to Read"
          onClose={() => setDraft(null)}
          footer={
            <div className="row" style={{ gap: 10 }}>
              <button className="btn-secondary" style={{ flex: 1 }} onClick={() => setDraft(null)} disabled={saving}>Cancel</button>
              <button className="btn-primary" style={{ flex: 1 }} onClick={saveAdd} disabled={saving}>
                {saving ? 'Adding…' : draft.published ? 'Add & Publish' : 'Add as Hidden'}
              </button>
            </div>
          }
        >
          {draft.manual ? (
            <DetailSection title="Case details">
              <div style={{ padding: '8px 0', display: 'grid', gap: 12 }}>
                <div>
                  <label className="field-label">Case name *</label>
                  <input className="input" placeholder="e.g. People v. Smith" value={draft.hit.title} onChange={(e) => setDraft({ ...draft, hit: { ...draft.hit, title: e.target.value } })} />
                </div>
                <div className="row" style={{ gap: 10 }}>
                  <div style={{ flex: 1 }}>
                    <label className="field-label">Court</label>
                    <input className="input" placeholder="e.g. California Supreme Court" value={draft.hit.court} onChange={(e) => setDraft({ ...draft, hit: { ...draft.hit, court: e.target.value } })} />
                  </div>
                  <div style={{ width: 150 }}>
                    <label className="field-label">Decided (YYYY-MM-DD)</label>
                    <input className="input" placeholder="1998-05-14" value={draft.hit.dateFiled} onChange={(e) => setDraft({ ...draft, hit: { ...draft.hit, dateFiled: e.target.value } })} />
                  </div>
                </div>
                <div className="row" style={{ gap: 10 }}>
                  <div style={{ flex: 1 }}>
                    <label className="field-label">Citation</label>
                    <input className="input" placeholder="e.g. 18 Cal. 4th 1" value={draft.hit.citation} onChange={(e) => setDraft({ ...draft, hit: { ...draft.hit, citation: e.target.value } })} />
                  </div>
                  <div style={{ flex: 1 }}>
                    <label className="field-label">Judges</label>
                    <input className="input" value={draft.hit.judges} onChange={(e) => setDraft({ ...draft, hit: { ...draft.hit, judges: e.target.value } })} />
                  </div>
                </div>
              </div>
            </DetailSection>
          ) : (
            <DetailSection title="From CourtListener" flush>
              <DetailGrid
                cells={[
                  { k: 'Case', v: draft.hit.title },
                  { k: 'Court', v: draft.hit.court },
                  { k: 'Decided', v: draft.hit.dateFiled || '—' },
                  { k: 'Citation', v: draft.hit.citation || '—' },
                  { k: 'Docket', v: draft.hit.docketNumber || '—' },
                  { k: 'Judges', v: draft.hit.judges || '—' },
                ]}
              />
              <div style={{ padding: '0 14px 12px' }}>
                <div className="cell-sub" style={{ marginTop: 0 }}>
                  {fullTextAvailable
                    ? 'The full opinion text and syllabus will be pulled automatically.'
                    : 'No CourtListener token set: students will see your summary only. Add COURTLISTENER_API_TOKEN to backend/.env to include the full opinion.'}
                </div>
              </div>
            </DetailSection>
          )}

          <DetailSection title="Shown to students">
            <div style={{ padding: '8px 0', display: 'grid', gap: 12 }}>
              <div className="row" style={{ gap: 10 }}>
                <div style={{ flex: 1 }}>
                  <label className="field-label">Tag</label>
                  <select className="input" value={draft.tag} onChange={(e) => setDraft({ ...draft, tag: e.target.value })}>
                    {TAGS.map((t) => <option key={t} value={t}>{t}</option>)}
                  </select>
                </div>
                <div style={{ width: 170 }}>
                  <label className="field-label">Level</label>
                  <select className="input" value={draft.level} onChange={(e) => setDraft({ ...draft, level: e.target.value as CaseStudyLevel })}>
                    {LEVELS.map((l) => <option key={l} value={l}>{l}</option>)}
                  </select>
                </div>
              </div>
              <div>
                <label className="field-label">Summary (plain English, what happened and what the court held)</label>
                <textarea
                  className="input"
                  style={{ height: 140, padding: 12, resize: 'vertical', lineHeight: 1.5 }}
                  value={draft.summary}
                  onChange={(e) => setDraft({ ...draft, summary: e.target.value })}
                />
              </div>
              <div>
                <label className="field-label">Key legal principle (optional)</label>
                <textarea
                  className="input"
                  style={{ height: 80, padding: 12, resize: 'vertical', lineHeight: 1.5 }}
                  placeholder="One or two sentences on the rule this case stands for."
                  value={draft.principle}
                  onChange={(e) => setDraft({ ...draft, principle: e.target.value })}
                />
              </div>
              <div className="row" style={{ gap: 10 }}>
                <button
                  type="button"
                  role="switch"
                  aria-checked={draft.published}
                  className={`switch${draft.published ? ' on' : ''}`}
                  onClick={() => setDraft({ ...draft, published: !draft.published })}
                />
                <span style={{ fontSize: 13, fontWeight: 600 }}>{draft.published ? 'Visible to students' : 'Hidden until you publish'}</span>
              </div>
              {saveError && <div className="note-box" style={{ marginBottom: 0 }}>{saveError}</div>}
            </div>
          </DetailSection>
        </Drawer>
      )}

      {editing && (
        <Drawer
          wide
          title="Edit Case"
          onClose={() => setEditing(null)}
          footer={
            <div className="row" style={{ gap: 10 }}>
              <button className="btn-danger" style={{ height: 44, borderRadius: 14, padding: '0 16px' }} onClick={() => remove(editing)} disabled={saving}>
                <IconTrash />
              </button>
              <button className="btn-secondary" style={{ flex: 1 }} onClick={() => setEditing(null)} disabled={saving}>Cancel</button>
              <button className="btn-primary" style={{ flex: 1 }} onClick={saveEdit} disabled={saving}>{saving ? 'Saving…' : 'Save'}</button>
            </div>
          }
        >
          <DetailSection title="CourtListener record" flush>
            <DetailGrid
              cells={[
                { k: 'Court', v: editing.court },
                { k: 'Decided', v: editing.dateFiled || '—' },
                { k: 'Citation', v: editing.citation || '—' },
                { k: 'Judges', v: editing.judges || '—' },
                { k: 'Read Time', v: `${editing.mins} min` },
                { k: 'Reads', v: editing.reads },
              ]}
            />
            <div className="row" style={{ gap: 10, padding: '0 14px 12px', flexWrap: 'wrap' }}>
              <ChipList items={[editing.hasFullText ? 'Full opinion text' : 'Summary only', editing.hasSyllabus ? 'Syllabus' : 'No syllabus', editing.hasNotes ? 'Study notes' : 'No study notes']} />
              <button className="btn-pill-grey" onClick={pullText} disabled={saving || !fullTextAvailable} title={fullTextAvailable ? '' : 'Needs COURTLISTENER_API_TOKEN'}>
                {editing.hasFullText ? 'Re-fetch text' : 'Fetch full text'}
              </button>
            </div>
          </DetailSection>

          <CaseNotesEditor
            caseId={editing.id}
            onChange={(hasNotes) => {
              setEditing((e) => (e ? { ...e, hasNotes } : e));
              setCases((prev) => prev.map((x) => (x.id === editing.id ? { ...x, hasNotes } : x)));
            }}
          />

          <DetailSection title="Shown to students">
            <div style={{ padding: '8px 0', display: 'grid', gap: 12 }}>
              <div>
                <label className="field-label">Title</label>
                <input className="input" value={editing.title} onChange={(e) => setEditing({ ...editing, title: e.target.value })} />
              </div>
              <div className="row" style={{ gap: 10 }}>
                <div style={{ flex: 1 }}>
                  <label className="field-label">Tag</label>
                  <select className="input" value={editing.tag} onChange={(e) => setEditing({ ...editing, tag: e.target.value })}>
                    {[...new Set([editing.tag, ...TAGS])].map((t) => <option key={t} value={t}>{t}</option>)}
                  </select>
                </div>
                <div style={{ width: 170 }}>
                  <label className="field-label">Level</label>
                  <select className="input" value={editing.level} onChange={(e) => setEditing({ ...editing, level: e.target.value as CaseStudyLevel })}>
                    {LEVELS.map((l) => <option key={l} value={l}>{l}</option>)}
                  </select>
                </div>
              </div>
              <div>
                <label className="field-label">Summary</label>
                <textarea className="input" style={{ height: 140, padding: 12, resize: 'vertical', lineHeight: 1.5 }} value={editing.summary} onChange={(e) => setEditing({ ...editing, summary: e.target.value })} />
              </div>
              <div>
                <label className="field-label">Key legal principle</label>
                <textarea className="input" style={{ height: 80, padding: 12, resize: 'vertical', lineHeight: 1.5 }} value={editing.principle} onChange={(e) => setEditing({ ...editing, principle: e.target.value })} />
              </div>
              <div className="row" style={{ gap: 10 }}>
                <button type="button" role="switch" aria-checked={editing.published} className={`switch${editing.published ? ' on' : ''}`} onClick={() => setEditing({ ...editing, published: !editing.published })} />
                <span style={{ fontSize: 13, fontWeight: 600 }}>{editing.published ? 'Visible to students' : 'Hidden from students'}</span>
              </div>
              {saveError && <div className="note-box" style={{ marginBottom: 0 }}>{saveError}</div>}
            </div>
          </DetailSection>

          {preview && (preview.syllabus || preview.opinionText) && (
            <DetailSection title="Preview" flush>
              {preview.syllabus && (
                <div style={{ padding: '12px 14px', borderBottom: '1px solid var(--divider)' }}>
                  <span className="detail-cell k" style={{ display: 'block', background: 'transparent', padding: 0, marginBottom: 6 }}>Syllabus</span>
                  <div style={{ fontSize: 12.5, lineHeight: 1.6, whiteSpace: 'pre-wrap', maxHeight: 180, overflow: 'auto' }}>{preview.syllabus}</div>
                </div>
              )}
              {preview.opinionText ? (
                <div style={{ padding: '12px 14px' }}>
                  <span className="detail-cell k" style={{ display: 'block', background: 'transparent', padding: 0, marginBottom: 6 }}>Opinion (first 3,000 characters)</span>
                  <div style={{ fontSize: 12.5, lineHeight: 1.6, whiteSpace: 'pre-wrap', maxHeight: 260, overflow: 'auto', color: 'var(--text-grey-555)' }}>
                    {preview.opinionText.slice(0, 3000)}{preview.opinionText.length > 3000 ? '…' : ''}
                  </div>
                </div>
              ) : (
                <ListEmpty text="No opinion text stored for this case." />
              )}
            </DetailSection>
          )}
        </Drawer>
      )}
    </div>
  );
}
