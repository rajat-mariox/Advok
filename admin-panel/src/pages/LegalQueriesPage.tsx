import { useEffect, useMemo, useState } from 'react';
import { IconChat, IconTrash } from '../components/Icon';
import { Avatar, Badge, Drawer, FilterChips, InfoRow, PageHeader, StatCard } from '../components/ui';
import {
  answerLegalQuery,
  deleteLegalQuery,
  fetchLegalQueries,
  formatDate,
  type BackendLegalQuery,
  type LegalQueryCounts,
} from '../utils/backend';
import { QUERY_CATEGORIES } from '../utils/seed';
import { useRealtime } from '../utils/realtime';

const FILTERS = ['All', 'Pending', 'Answered'];
const DEFAULT_RESPONDER = 'ADVOK Legal Team';

function statusLabel(q: BackendLegalQuery): 'Pending' | 'Answered' {
  return q.status === 'answered' ? 'Answered' : 'Pending';
}

/** Legal questions law students ask in the app; the ADVOK team answers here. */
export default function LegalQueriesPage() {
  const [queries, setQueries] = useState<BackendLegalQuery[]>([]);
  const [counts, setCounts] = useState<LegalQueryCounts>({ total: 0, pending: 0, answered: 0 });
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState('');
  const [filter, setFilter] = useState('All');
  const [category, setCategory] = useState('All Categories');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [reply, setReply] = useState('');
  const [responder, setResponder] = useState(DEFAULT_RESPONDER);
  const [sending, setSending] = useState(false);
  const [sendError, setSendError] = useState('');
  const [sentNote, setSentNote] = useState('');

  const load = () =>
    fetchLegalQueries()
      .then((r) => {
        setQueries(r.queries);
        setCounts(r.counts);
        setLoadError('');
      })
      .catch((err) => setLoadError(err instanceof Error ? err.message : 'Could not load legal queries from the backend.'))
      .finally(() => setLoading(false));

  useEffect(() => {
    void load();
  }, []);
  useRealtime(['queries'], () => {
    void load();
  });

  const list = useMemo(
    () =>
      queries.filter((q) => {
        const matchesFilter = filter === 'All' || statusLabel(q) === filter;
        const matchesCategory = category === 'All Categories' || q.category === category;
        return matchesFilter && matchesCategory;
      }),
    [queries, filter, category],
  );

  const categories = useMemo(
    () => [...new Set([...QUERY_CATEGORIES, ...queries.map((q) => q.category)])],
    [queries],
  );

  const selected = queries.find((q) => q.id === selectedId) ?? null;

  const open = (q: BackendLegalQuery) => {
    setSelectedId(q.id);
    setReply(q.response ?? '');
    setResponder(q.responderName ?? DEFAULT_RESPONDER);
    setSendError('');
    setSentNote('');
  };

  // Success note fades and the drawer closes on its own after a moment.
  useEffect(() => {
    if (!sentNote) return;
    const t = setTimeout(() => {
      setSentNote('');
      setSelectedId(null);
    }, 1600);
    return () => clearTimeout(t);
  }, [sentNote]);

  const send = async () => {
    if (!selected || !reply.trim()) return;
    setSending(true);
    setSendError('');
    try {
      const wasPending = selected.status === 'pending';
      const updated = await answerLegalQuery(selected.id, reply.trim(), responder.trim() || undefined);
      setQueries((prev) => prev.map((q) => (q.id === updated.id ? updated : q)));
      setCounts((c) => ({
        ...c,
        pending: wasPending ? Math.max(0, c.pending - 1) : c.pending,
        answered: wasPending ? c.answered + 1 : c.answered,
      }));
      setSentNote(
        wasPending
          ? `Answer sent — ${updated.studentName} has been notified in the app.`
          : `Answer updated — ${updated.studentName} has been notified.`,
      );
    } catch (err) {
      setSendError(err instanceof Error ? err.message : 'Failed to send the answer');
    } finally {
      setSending(false);
    }
  };

  const remove = async (q: BackendLegalQuery) => {
    if (!window.confirm('Delete this query? The student will no longer see it.')) return;
    const ok = await deleteLegalQuery(q.id);
    if (ok) {
      setQueries((prev) => prev.filter((x) => x.id !== q.id));
      setCounts((c) => ({
        total: Math.max(0, c.total - 1),
        pending: q.status === 'pending' ? Math.max(0, c.pending - 1) : c.pending,
        answered: q.status === 'answered' ? Math.max(0, c.answered - 1) : c.answered,
      }));
      if (selectedId === q.id) setSelectedId(null);
    }
  };

  return (
    <div>
      <PageHeader
        eyebrow="Operations"
        title="Legal Queries"
        subtitle={`${counts.total} queries from law students · ${counts.pending} pending · answered by the ADVOK team, students are notified in the app`}
      />

      <div className="grid-stats" style={{ marginBottom: 22 }}>
        <StatCard icon={<IconChat />} value={String(counts.total)} label="Total Queries" trend="Asked from the app's Legal Queries tab" />
        <StatCard icon={<IconChat />} value={String(counts.pending)} label="Pending" trend="Waiting for a reply" />
        <StatCard icon={<IconChat />} value={String(counts.answered)} label="Answered" trend="Reply visible to the student" />
      </div>

      <div className="row" style={{ justifyContent: 'space-between', gap: 14, marginBottom: 16, flexWrap: 'wrap' }}>
        <FilterChips options={FILTERS} active={filter} onChange={setFilter} />
        <select
          className="input"
          style={{ width: 220, height: 40 }}
          value={category}
          onChange={(e) => setCategory(e.target.value)}
        >
          <option>All Categories</option>
          {categories.map((c) => (
            <option key={c}>{c}</option>
          ))}
        </select>
      </div>

      <div className="table-card">
        <table className="data">
          <thead>
            <tr>
              <th style={{ width: '44%' }}>Query</th>
              <th>Category</th>
              <th>Asked</th>
              <th>Responder</th>
              <th>Status</th>
              <th style={{ width: 60 }}></th>
            </tr>
          </thead>
          <tbody>
            {list.map((q) => (
              <tr key={q.id} className="clickable" onClick={() => open(q)}>
                <td>
                  <div className="cell-strong" style={{ whiteSpace: 'normal', lineHeight: 1.4 }}>
                    {q.question}
                  </div>
                  <div className="cell-sub">
                    {q.studentName}
                    {q.studentCollege ? ` · ${q.studentCollege}` : ''}
                  </div>
                </td>
                <td>{q.category}</td>
                <td style={{ whiteSpace: 'nowrap' }}>{formatDate(q.createdAt)}</td>
                <td>{q.responderName ?? '—'}</td>
                <td>
                  <Badge label={statusLabel(q)} />
                </td>
                <td onClick={(e) => e.stopPropagation()}>
                  <button className="icon-btn icon-btn-danger" title="Delete" onClick={() => remove(q)}>
                    <IconTrash />
                  </button>
                </td>
              </tr>
            ))}
            {list.length === 0 && (
              <tr>
                <td colSpan={6} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  {loading
                    ? 'Loading…'
                    : loadError || (queries.length === 0 ? 'No queries yet. Questions students ask in the app appear here.' : 'No queries match this filter.')}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {selected && (
        <Drawer
          title="Legal Query"
          onClose={() => setSelectedId(null)}
          footer={
            <div className="row" style={{ gap: 10 }}>
              <button className="btn-secondary" style={{ flex: 1 }} onClick={() => setSelectedId(null)} disabled={sending}>
                Close
              </button>
              <button className="btn-primary" style={{ flex: 1 }} onClick={send} disabled={sending || !!sentNote || !reply.trim()}>
                {sending ? 'Sending…' : sentNote ? 'Sent ✓' : selected.status === 'answered' ? 'Update Answer' : 'Send Answer'}
              </button>
            </div>
          }
        >
          <div className="row" style={{ gap: 14, marginBottom: 18 }}>
            <Avatar name={selected.studentName} size={48} square />
            <div>
              <div className="row" style={{ gap: 8 }}>
                <span style={{ fontSize: 16, fontWeight: 800, letterSpacing: -0.3 }}>{selected.studentName}</span>
                <Badge label={statusLabel(selected)} />
              </div>
              <div className="cell-sub" style={{ fontSize: 12.5 }}>
                {selected.category} · Asked {formatDate(selected.createdAt)}
                {selected.studentCollege ? ` · ${selected.studentCollege}` : ''}
              </div>
            </div>
          </div>

          <div className="eyebrow" style={{ marginBottom: 8 }}>Question</div>
          <div
            className="card-white"
            style={{ padding: '12px 14px', fontSize: 13, lineHeight: 1.6, color: 'var(--text-primary)', fontWeight: 600, whiteSpace: 'pre-wrap' }}
          >
            {selected.question}
          </div>

          <div className="eyebrow" style={{ margin: '18px 0 8px' }}>
            {selected.status === 'answered' ? `Answer · sent ${formatDate(selected.answeredAt)}` : 'Your answer'}
          </div>
          <div style={{ display: 'grid', gap: 10 }}>
            <textarea
              className="input"
              placeholder="Write a clear, general-information answer. Remind the student this is not legal advice where relevant."
              style={{ height: 180, padding: 12, resize: 'vertical', lineHeight: 1.55 }}
              value={reply}
              onChange={(e) => setReply(e.target.value)}
            />
            <div>
              <label className="field-label">Shown as</label>
              <input className="input" value={responder} onChange={(e) => setResponder(e.target.value)} placeholder={DEFAULT_RESPONDER} />
            </div>
            {sendError && <div className="note-box" style={{ marginBottom: 0 }}>{sendError}</div>}
            {sentNote && (
              <div className="note-box" style={{ marginBottom: 0, borderColor: '#1f7a3f', color: '#1f7a3f', background: '#eef8f1' }}>
                {sentNote}
              </div>
            )}
            <div className="cell-sub">
              The student gets an in-app notification and sees the answer under My Queries. You can edit and resend later.
            </div>
          </div>

          <div style={{ marginTop: 18 }}>
            <InfoRow k="Query ID" v={selected.id} />
            <InfoRow k="Category" v={selected.category} />
            <InfoRow k="Student phone" v={selected.studentPhone ?? '—'} />
            <InfoRow k="Student email" v={selected.studentEmail ?? '—'} />
          </div>
        </Drawer>
      )}
    </div>
  );
}
