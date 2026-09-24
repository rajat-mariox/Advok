import { useEffect, useMemo, useState } from 'react';
import { IconChat, IconGraduation, IconSearch, IconUsers } from '../components/Icon';
import { Avatar, Badge, Drawer, FilterChips, InfoRow, PageHeader, StatCard } from '../components/ui';
import {
  fetchConnectionThread,
  fetchConnections,
  formatDate,
  type ConnectionCounts,
  type ConnectionMessage,
  type StudentAttorneyConnection,
} from '../utils/backend';
import { useRealtime } from '../utils/realtime';

const FILTERS = ['All', 'Active', 'Awaiting reply'];

function statusLabel(c: StudentAttorneyConnection): string {
  return c.status === 'active' ? 'Active' : 'Awaiting reply';
}

function timeLabel(iso: string): string {
  const d = new Date(iso);
  return Number.isNaN(d.getTime())
    ? iso
    : d.toLocaleString(undefined, { month: 'short', day: 'numeric', hour: 'numeric', minute: '2-digit' });
}

/**
 * Mentorships = conversations between law students and attorneys. A student
 * connects by messaging an attorney from the Attorneys tab in the app; every
 * such pair shows here with the full conversation.
 */
export default function MentorshipsPage() {
  const [connections, setConnections] = useState<StudentAttorneyConnection[]>([]);
  const [counts, setCounts] = useState<ConnectionCounts>({ total: 0, active: 0, awaitingReply: 0, students: 0, attorneys: 0 });
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState('');
  const [filter, setFilter] = useState('All');
  const [query, setQuery] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [thread, setThread] = useState<ConnectionMessage[]>([]);
  const [threadLoading, setThreadLoading] = useState(false);
  const [threadError, setThreadError] = useState('');

  const load = () =>
    fetchConnections()
      .then((r) => {
        setConnections(r.connections);
        setCounts(r.counts);
        setLoadError('');
      })
      .catch((err) => setLoadError(err instanceof Error ? err.message : 'Could not load mentorships from the backend.'))
      .finally(() => setLoading(false));

  const selected = connections.find((c) => c.id === selectedId) ?? null;

  const loadThread = (c: StudentAttorneyConnection) => {
    setThreadLoading(true);
    setThreadError('');
    fetchConnectionThread(c.studentId, c.attorneyId)
      .then(setThread)
      .catch((err) => setThreadError(err instanceof Error ? err.message : 'Could not load the conversation'))
      .finally(() => setThreadLoading(false));
  };

  useEffect(() => {
    void load();
  }, []);

  useRealtime(['mentorships'], () => {
    void load();
    if (selected) loadThread(selected);
  });

  const open = (c: StudentAttorneyConnection) => {
    setSelectedId(c.id);
    setThread([]);
    loadThread(c);
  };

  const list = useMemo(() => {
    const q = query.trim().toLowerCase();
    return connections.filter((c) => {
      const matchesFilter = filter === 'All' || statusLabel(c) === filter;
      const matchesQuery =
        !q ||
        c.studentName.toLowerCase().includes(q) ||
        c.attorneyName.toLowerCase().includes(q) ||
        (c.studentCollege ?? '').toLowerCase().includes(q) ||
        c.attorneySpecialty.toLowerCase().includes(q);
      return matchesFilter && matchesQuery;
    });
  }, [connections, filter, query]);

  return (
    <div>
      <PageHeader
        eyebrow="Operations"
        title="Mentorships"
        subtitle={`${counts.total} student–attorney conversations · ${counts.awaitingReply} awaiting an attorney reply · started when a law student messages an attorney in the app`}
      />

      <div className="grid-stats" style={{ marginBottom: 22 }}>
        <StatCard icon={<IconChat />} value={String(counts.total)} label="Conversations" trend={`${counts.active} active · ${counts.awaitingReply} awaiting reply`} />
        <StatCard icon={<IconGraduation />} value={String(counts.students)} label="Students Reaching Out" trend="Law students who messaged an attorney" />
        <StatCard icon={<IconUsers />} value={String(counts.attorneys)} label="Attorneys Contacted" trend="Attorneys students have messaged" />
      </div>

      <div className="row" style={{ justifyContent: 'space-between', gap: 14, marginBottom: 16, flexWrap: 'wrap' }}>
        <FilterChips options={FILTERS} active={filter} onChange={setFilter} />
        <div className="search-wrap" style={{ width: 280 }}>
          <IconSearch />
          <input
            className="input"
            placeholder="Search student, attorney, college…"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            style={{ height: 40 }}
          />
        </div>
      </div>

      <div className="table-card">
        <table className="data">
          <thead>
            <tr>
              <th>Student</th>
              <th>Attorney</th>
              <th style={{ width: '32%' }}>Last message</th>
              <th>Messages</th>
              <th>Started</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {list.map((c) => (
              <tr key={c.id} className="clickable" onClick={() => open(c)}>
                <td>
                  <div className="row" style={{ gap: 10 }}>
                    <Avatar name={c.studentName} size={32} />
                    <div>
                      <div className="cell-strong">{c.studentName}</div>
                      <div className="cell-sub">{[c.studentCollege, c.studentYear].filter(Boolean).join(' · ') || 'Law student'}</div>
                    </div>
                  </div>
                </td>
                <td>
                  <div className="cell-strong">{c.attorneyName}</div>
                  <div className="cell-sub">{[c.attorneySpecialty, c.attorneyFirm].filter(Boolean).join(' · ') || '—'}</div>
                </td>
                <td>
                  <div className="cell-sub" style={{ whiteSpace: 'normal', lineHeight: 1.4 }}>
                    <strong>{c.lastFrom === 'student' ? 'Student' : 'Attorney'}:</strong>{' '}
                    {c.lastMessage.length > 110 ? `${c.lastMessage.slice(0, 107)}…` : c.lastMessage}
                  </div>
                  <div className="cell-sub">{timeLabel(c.lastMessageAt)}</div>
                </td>
                <td>{c.messageCount}</td>
                <td style={{ whiteSpace: 'nowrap' }}>{formatDate(c.startedAt)}</td>
                <td><Badge label={statusLabel(c)} /></td>
              </tr>
            ))}
            {list.length === 0 && (
              <tr>
                <td colSpan={6} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  {loading
                    ? 'Loading…'
                    : loadError ||
                      (connections.length === 0
                        ? 'No conversations yet. They appear when a law student messages an attorney from the Attorneys tab.'
                        : 'No conversations match this filter.')}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {selected && (
        <Drawer wide title="Mentorship Conversation" onClose={() => setSelectedId(null)}>
          <div className="row" style={{ gap: 14, marginBottom: 14 }}>
            <Avatar name={selected.studentName} size={48} square />
            <div>
              <div className="row" style={{ gap: 8 }}>
                <span style={{ fontSize: 16, fontWeight: 800, letterSpacing: -0.3 }}>{selected.studentName}</span>
                <Badge label={statusLabel(selected)} />
              </div>
              <div className="cell-sub" style={{ fontSize: 12.5 }}>
                → {selected.attorneyName}
                {selected.attorneySpecialty ? ` · ${selected.attorneySpecialty}` : ''}
              </div>
            </div>
          </div>

          <InfoRow k="Student" v={[selected.studentCollege, selected.studentYear].filter(Boolean).join(' · ') || '—'} />
          <InfoRow k="Student phone" v={selected.studentPhone ?? '—'} />
          <InfoRow k="Attorney" v={[selected.attorneyName, selected.attorneyFirm].filter(Boolean).join(' · ')} />
          <InfoRow k="Started" v={timeLabel(selected.startedAt)} />
          <InfoRow k="Messages" v={`${selected.messageCount} (student ${selected.fromStudent} · attorney ${selected.fromAttorney})`} />

          <div className="eyebrow" style={{ margin: '18px 0 10px' }}>Conversation</div>
          {threadLoading && thread.length === 0 ? (
            <div className="cell-sub">Loading…</div>
          ) : threadError ? (
            <div className="note-box">{threadError}</div>
          ) : (
            <div style={{ display: 'grid', gap: 8 }}>
              {thread.map((m) => (
                <div
                  key={m.id}
                  style={{
                    justifySelf: m.system ? 'center' : m.from === 'student' ? 'start' : 'end',
                    maxWidth: m.system ? '100%' : '80%',
                    background: m.system ? 'transparent' : m.from === 'student' ? 'var(--fill-grey, #f2f2f2)' : '#0a0a0a',
                    color: m.system ? 'var(--text-grey)' : m.from === 'student' ? 'var(--text-primary)' : '#fff',
                    border: m.from === 'student' && !m.system ? '1px solid var(--border-grey, #dedede)' : 'none',
                    borderRadius: 14,
                    padding: m.system ? '2px 0' : '9px 12px',
                    fontSize: m.system ? 11.5 : 13,
                    lineHeight: 1.5,
                    whiteSpace: 'pre-wrap',
                  }}
                >
                  {!m.system && (
                    <div style={{ fontSize: 10.5, fontWeight: 700, opacity: 0.7, marginBottom: 2 }}>
                      {m.from === 'student' ? selected.studentName : selected.attorneyName} · {timeLabel(m.sentAt)}
                    </div>
                  )}
                  {m.text}
                </div>
              ))}
              {thread.length === 0 && <div className="cell-sub">No messages.</div>}
            </div>
          )}
          <div className="cell-sub" style={{ marginTop: 14 }}>
            Read-only. Mentoring is career and study guidance between the student and the attorney, not legal advice.
          </div>
        </Drawer>
      )}
    </div>
  );
}
