import { useCallback, useEffect, useMemo, useRef, useState, type KeyboardEvent } from 'react';

/** Height that makes an element end 20px above the bottom of the viewport. */
function useFillHeight<T extends HTMLElement>() {
  const ref = useRef<T>(null);
  const [height, setHeight] = useState<number>(560);
  useEffect(() => {
    const measure = () => {
      const el = ref.current;
      if (!el) return;
      const top = el.getBoundingClientRect().top + (window.scrollY || 0);
      setHeight(Math.max(420, window.innerHeight - top - 20));
    };
    measure();
    window.addEventListener('resize', measure);
    const t = window.setTimeout(measure, 300); // after fonts/cards settle
    return () => {
      window.removeEventListener('resize', measure);
      window.clearTimeout(t);
    };
  }, []);
  return { ref, height };
}
import { IconBell, IconChat, IconCheck, IconSearch, IconUserCheck } from '../components/Icon';
import { Avatar, Badge, FilterChips, PageHeader, StatCard } from '../components/ui';
import {
  fetchSupportTicket,
  fetchSupportTickets,
  formatDate,
  replySupportTicket,
  roleLabel,
  setSupportTicketStatus,
  ticketCategoryLabel,
  ticketStatusLabel,
  type SupportTicket,
  type SupportTicketCounts,
  type SupportTicketStatus,
} from '../utils/backend';
import { useRealtime } from '../utils/realtime';

const FILTERS = ['All', 'Open', 'In Progress', 'Resolved'] as const;
type Filter = (typeof FILTERS)[number];
const FILTER_TO_STATUS: Record<Filter, SupportTicketStatus | 'all'> = {
  All: 'all',
  Open: 'open',
  'In Progress': 'in_progress',
  Resolved: 'resolved',
};

const EMPTY_COUNTS: SupportTicketCounts = { open: 0, in_progress: 0, resolved: 0, unread: 0 };

function timeAgo(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'now';
  if (mins < 60) return `${mins}m`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h`;
  const days = Math.floor(hours / 24);
  if (days < 7) return `${days}d`;
  return formatDate(iso);
}

function clockLabel(iso: string): string {
  const d = new Date(iso);
  return Number.isNaN(d.getTime()) ? '' : d.toLocaleTimeString(undefined, { hour: 'numeric', minute: '2-digit' });
}

function dayLabel(iso: string): string {
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '';
  const today = new Date();
  const sameDay = (a: Date, b: Date) =>
    a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  if (sameDay(d, today)) return 'Today';
  const yesterday = new Date(today);
  yesterday.setDate(today.getDate() - 1);
  if (sameDay(d, yesterday)) return 'Yesterday';
  return d.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' });
}

/** Last thing said on the ticket, for the inbox preview. */
function lastLine(t: SupportTicket): { text: string; fromAdmin: boolean } {
  const last = t.replies[t.replies.length - 1];
  return last ? { text: last.text, fromAdmin: last.fromAdmin } : { text: t.message, fromAdmin: false };
}

interface Bubble {
  id: string;
  fromAdmin: boolean;
  text: string;
  at: string;
  subject?: string;
}

/**
 * Help & Support inbox: tickets on the left, the conversation on the right,
 * like a chat app. New user messages arrive live (SSE) and replies go out
 * as in-app + push notifications.
 */
export default function SupportPage() {
  const [filter, setFilter] = useState<Filter>('All');
  const [query, setQuery] = useState('');
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [counts, setCounts] = useState<SupportTicketCounts>(EMPTY_COUNTS);
  const [loadError, setLoadError] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [selected, setSelected] = useState<SupportTicket | null>(null);
  const [reply, setReply] = useState('');
  const [busy, setBusy] = useState(false);
  const [note, setNote] = useState('');
  const scrollRef = useRef<HTMLDivElement>(null);
  const fill = useFillHeight<HTMLDivElement>();
  const inputRef = useRef<HTMLTextAreaElement>(null);

  const load = useCallback(async () => {
    try {
      const data = await fetchSupportTickets(FILTER_TO_STATUS[filter]);
      setTickets(data.tickets);
      setCounts(data.counts);
      setLoadError('');
    } catch (err) {
      setLoadError(err instanceof Error ? err.message : 'Failed to load tickets');
    }
  }, [filter]);

  const loadSelected = useCallback(async (id: string) => {
    try {
      setSelected(await fetchSupportTicket(id));
    } catch {
      // keep what we have
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  // A user message or another admin's reply: refresh the inbox and, if the
  // conversation is open, the thread itself.
  useRealtime(['support'], () => {
    void load();
    if (selectedId) void loadSelected(selectedId);
  });

  useEffect(() => {
    if (!selectedId) {
      setSelected(null);
      return;
    }
    setNote('');
    setReply('');
    void loadSelected(selectedId).then(() => void load());
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedId]);

  const bubbles = useMemo<Bubble[]>(() => {
    if (!selected) return [];
    return [
      { id: 'first', fromAdmin: false, text: selected.message, at: selected.createdAt, subject: selected.subject },
      ...selected.replies.map((r) => ({ id: r.id, fromAdmin: r.fromAdmin, text: r.text, at: r.createdAt })),
    ];
  }, [selected]);

  // Stick to the newest message whenever the thread changes.
  useEffect(() => {
    const el = scrollRef.current;
    if (el) el.scrollTop = el.scrollHeight;
  }, [bubbles.length, selectedId]);

  useEffect(() => {
    if (selectedId) inputRef.current?.focus();
  }, [selectedId]);

  const visible = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return tickets;
    return tickets.filter(
      (t) =>
        t.userName.toLowerCase().includes(q) ||
        t.subject.toLowerCase().includes(q) ||
        t.message.toLowerCase().includes(q) ||
        (t.userEmail ?? '').toLowerCase().includes(q) ||
        (t.userPhone ?? '').includes(q),
    );
  }, [tickets, query]);

  const applyUpdate = (updated: SupportTicket) => {
    setSelected(updated);
    void load();
  };

  const sendReply = async (andResolve = false) => {
    const text = reply.trim();
    if (!selected || !text || busy) return;
    setBusy(true);
    setNote('');
    setReply('');
    try {
      applyUpdate(await replySupportTicket(selected.id, text, andResolve ? 'resolved' : undefined));
      setNote(andResolve ? 'Sent · ticket resolved' : 'Sent · user notified');
    } catch (err) {
      setReply(text); // give the draft back
      setNote(err instanceof Error ? err.message : 'Failed to send reply');
    } finally {
      setBusy(false);
      inputRef.current?.focus();
    }
  };

  const changeStatus = async (status: SupportTicketStatus) => {
    if (!selected || busy) return;
    setBusy(true);
    setNote('');
    try {
      applyUpdate(await setSupportTicketStatus(selected.id, status));
      setNote(`Status: ${ticketStatusLabel(status)}`);
    } catch (err) {
      setNote(err instanceof Error ? err.message : 'Failed to update status');
    } finally {
      setBusy(false);
    }
  };

  const onKey = (e: KeyboardEvent<HTMLTextAreaElement>) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      void sendReply(false);
    }
  };

  return (
    <div>
      <PageHeader
        eyebrow="Operations"
        title="Help & Support"
        subtitle="Chat with users who reached out from the app's Help & Support screen. Replies arrive in-app and as a push notification."
      />

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 14, marginBottom: 14 }}>
        <StatCard icon={<IconChat />} label="Open" value={String(counts.open)} />
        <StatCard icon={<IconUserCheck />} label="In Progress" value={String(counts.in_progress)} />
        <StatCard icon={<IconCheck />} label="Resolved" value={String(counts.resolved)} />
        <StatCard icon={<IconBell />} label="Unread Messages" value={String(counts.unread)} />
      </div>

      <div
        ref={fill.ref}
        className="table-card"
        style={{
          display: 'grid',
          gridTemplateColumns: '340px 1fr',
          height: fill.height,
          overflow: 'hidden',
        }}
      >
        {/* ── Inbox ─────────────────────────────────────────────── */}
        <div style={{ display: 'flex', flexDirection: 'column', borderRight: '1px solid var(--divider)', minWidth: 0, minHeight: 0 }}>
          <div style={{ padding: '12px 12px 10px', borderBottom: '1px solid var(--divider)', display: 'flex', flexDirection: 'column', gap: 10 }}>
            <div className="search-wrap">
              <IconSearch />
              <input
                className="input"
                placeholder="Search name, subject, phone…"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
              />
            </div>
            <FilterChips options={[...FILTERS]} active={filter} onChange={(v) => setFilter(v as Filter)} />
          </div>

          <div style={{ overflowY: 'auto', flex: 1, minHeight: 0 }}>
            {visible.map((t) => {
              const last = lastLine(t);
              const active = t.id === selectedId;
              const unread = t.adminUnread > 0;
              return (
                <button
                  key={t.id}
                  type="button"
                  onClick={() => setSelectedId(t.id)}
                  style={{
                    all: 'unset',
                    boxSizing: 'border-box',
                    display: 'grid',
                    gridTemplateColumns: '40px 1fr auto',
                    gap: 10,
                    alignItems: 'start',
                    width: '100%',
                    padding: '12px 14px',
                    cursor: 'pointer',
                    background: active ? 'var(--fill-grey)' : 'transparent',
                    borderBottom: '1px solid var(--divider)',
                    borderLeft: active ? '3px solid var(--text-primary)' : '3px solid transparent',
                  }}
                >
                  <Avatar name={t.userName} size={40} square photo={t.userPhoto ?? undefined} />
                  <div style={{ minWidth: 0 }}>
                    <div className="row" style={{ gap: 6, alignItems: 'baseline' }}>
                      <span
                        style={{
                          fontSize: 13.5,
                          fontWeight: unread ? 800 : 700,
                          color: 'var(--text-primary)',
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                          whiteSpace: 'nowrap',
                        }}
                      >
                        {t.userName}
                      </span>
                      <span className="cell-sub" style={{ fontSize: 11, whiteSpace: 'nowrap' }}>
                        {roleLabel(t.userRole)}
                      </span>
                    </div>
                    <div
                      style={{
                        fontSize: 12.5,
                        fontWeight: 700,
                        color: 'var(--text-primary)',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap',
                        marginTop: 1,
                      }}
                    >
                      {t.subject}
                    </div>
                    <div
                      style={{
                        fontSize: 12,
                        color: unread ? 'var(--text-primary)' : 'var(--text-grey)',
                        fontWeight: unread ? 700 : 500,
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                        whiteSpace: 'nowrap',
                        marginTop: 2,
                      }}
                    >
                      {last.fromAdmin ? 'You: ' : ''}
                      {last.text}
                    </div>
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6 }}>
                    <span className="cell-sub" style={{ fontSize: 11 }}>
                      {timeAgo(t.updatedAt)}
                    </span>
                    {unread ? (
                      <span
                        title={`${t.adminUnread} new`}
                        style={{
                          minWidth: 18,
                          height: 18,
                          padding: '0 5px',
                          borderRadius: 9,
                          background: 'var(--text-primary)',
                          color: '#fff',
                          fontSize: 10.5,
                          fontWeight: 800,
                          display: 'inline-flex',
                          alignItems: 'center',
                          justifyContent: 'center',
                        }}
                      >
                        {t.adminUnread}
                      </span>
                    ) : (
                      <span style={{ fontSize: 10 }}>
                        <Badge label={ticketStatusLabel(t.status)} />
                      </span>
                    )}
                  </div>
                </button>
              );
            })}
            {visible.length === 0 && (
              <div style={{ padding: 32, textAlign: 'center', color: 'var(--text-grey)', fontSize: 13 }}>
                {loadError || (query ? 'No tickets match your search.' : 'No tickets match this filter.')}
              </div>
            )}
          </div>
        </div>

        {/* ── Conversation ──────────────────────────────────────── */}
        {!selected ? (
          <div
            style={{
              display: 'flex',
              flexDirection: 'column',
              alignItems: 'center',
              justifyContent: 'center',
              gap: 8,
              color: 'var(--text-grey)',
              fontSize: 13,
            }}
          >
            <IconChat size={28} />
            <div style={{ fontWeight: 700, color: 'var(--text-primary)' }}>Select a ticket</div>
            <div>The conversation opens here.</div>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', minWidth: 0, minHeight: 0 }}>
            {/* header */}
            <div
              className="row"
              style={{
                gap: 12,
                padding: '12px 18px',
                borderBottom: '1px solid var(--divider)',
                justifyContent: 'space-between',
                flexWrap: 'wrap',
              }}
            >
              <div className="row" style={{ gap: 12, minWidth: 0 }}>
                <Avatar name={selected.userName} size={42} square photo={selected.userPhoto ?? undefined} />
                <div style={{ minWidth: 0 }}>
                  <div className="row" style={{ gap: 8 }}>
                    <span style={{ fontSize: 15, fontWeight: 800, letterSpacing: -0.2 }}>{selected.userName}</span>
                    <Badge label={ticketStatusLabel(selected.status)} />
                  </div>
                  <div className="cell-sub" style={{ fontSize: 12 }}>
                    {roleLabel(selected.userRole)} · {ticketCategoryLabel(selected.category)} · #
                    {selected.id.slice(0, 8).toUpperCase()}
                    {selected.userPhone ? ` · ${selected.userPhone}` : ''}
                    {selected.userEmail ? ` · ${selected.userEmail}` : ''}
                  </div>
                </div>
              </div>
              <div className="row" style={{ gap: 8 }}>
                {selected.status === 'open' && (
                  <button className="btn-secondary" disabled={busy} onClick={() => void changeStatus('in_progress')}>
                    Mark In Progress
                  </button>
                )}
                {selected.status !== 'resolved' ? (
                  <button className="btn-secondary" disabled={busy} onClick={() => void changeStatus('resolved')}>
                    Resolve
                  </button>
                ) : (
                  <button className="btn-secondary" disabled={busy} onClick={() => void changeStatus('open')}>
                    Reopen
                  </button>
                )}
              </div>
            </div>

            {/* messages */}
            <div
              ref={scrollRef}
              style={{
                flex: 1,
                minHeight: 0,
                overflowY: 'auto',
                padding: '18px 18px 8px',
                background: 'var(--off-white)',
                display: 'flex',
                flexDirection: 'column',
                gap: 6,
              }}
            >
              {bubbles.map((b, i) => {
                const prev = bubbles[i - 1];
                const newDay = !prev || dayLabel(prev.at) !== dayLabel(b.at);
                const sameSender = prev && prev.fromAdmin === b.fromAdmin && !newDay;
                return (
                  <div key={b.id} style={{ display: 'flex', flexDirection: 'column' }}>
                    {newDay && (
                      <div
                        style={{
                          alignSelf: 'center',
                          fontSize: 11,
                          fontWeight: 700,
                          color: 'var(--text-grey)',
                          background: '#fff',
                          border: '1px solid var(--divider)',
                          borderRadius: 100,
                          padding: '3px 10px',
                          margin: '6px 0 10px',
                        }}
                      >
                        {dayLabel(b.at)}
                      </div>
                    )}
                    <div
                      style={{
                        alignSelf: b.fromAdmin ? 'flex-end' : 'flex-start',
                        maxWidth: '72%',
                        marginTop: sameSender ? 0 : 6,
                      }}
                    >
                      {!sameSender && (
                        <div
                          className="cell-sub"
                          style={{ fontSize: 11, fontWeight: 700, marginBottom: 3, textAlign: b.fromAdmin ? 'right' : 'left' }}
                        >
                          {b.fromAdmin ? 'ADVOK Support' : selected.userName}
                        </div>
                      )}
                      <div
                        style={{
                          background: b.fromAdmin ? '#0a0a0a' : '#fff',
                          color: b.fromAdmin ? '#fff' : 'var(--text-primary)',
                          border: b.fromAdmin ? 'none' : '1px solid var(--border-grey)',
                          borderRadius: 16,
                          borderTopRightRadius: b.fromAdmin && sameSender ? 6 : 16,
                          borderTopLeftRadius: !b.fromAdmin && sameSender ? 6 : 16,
                          padding: '9px 13px',
                          fontSize: 13.5,
                          lineHeight: 1.55,
                          whiteSpace: 'pre-wrap',
                          wordBreak: 'break-word',
                          boxShadow: '0 1px 1px rgba(0,0,0,0.04)',
                        }}
                      >
                        {b.subject && (
                          <div style={{ fontSize: 11, fontWeight: 800, letterSpacing: 0.3, textTransform: 'uppercase', opacity: 0.7, marginBottom: 4 }}>
                            {b.subject}
                          </div>
                        )}
                        {b.text}
                        <div
                          style={{
                            fontSize: 10.5,
                            opacity: 0.6,
                            marginTop: 4,
                            textAlign: 'right',
                          }}
                        >
                          {clockLabel(b.at)}
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
              {selected.status === 'resolved' && (
                <div style={{ alignSelf: 'center', fontSize: 11.5, color: 'var(--text-grey)', margin: '10px 0 4px', fontWeight: 600 }}>
                  Resolved {selected.resolvedAt ? formatDate(selected.resolvedAt) : ''} · replying will reopen the conversation
                </div>
              )}
            </div>

            {/* composer */}
            <div style={{ borderTop: '1px solid var(--divider)', padding: '12px 18px 14px', background: '#fff' }}>
              <div style={{ display: 'flex', gap: 10, alignItems: 'flex-end' }}>
                <textarea
                  ref={inputRef}
                  className="input"
                  rows={1}
                  placeholder={`Message ${selected.userName}…  (Enter to send, Shift+Enter for a new line)`}
                  value={reply}
                  disabled={busy}
                  onChange={(e) => {
                    setReply(e.target.value);
                    const el = e.target;
                    el.style.height = 'auto';
                    el.style.height = `${Math.min(el.scrollHeight, 160)}px`;
                  }}
                  onKeyDown={onKey}
                  style={{ flex: 1, height: 'auto', minHeight: 44, maxHeight: 160, resize: 'none', lineHeight: 1.5, padding: '11px 14px' }}
                />
                <button className="btn-primary" disabled={busy || !reply.trim()} onClick={() => void sendReply(false)} style={{ whiteSpace: 'nowrap' }}>
                  {busy ? 'Sending…' : 'Send'}
                </button>
              </div>
              <div className="row" style={{ justifyContent: 'space-between', marginTop: 8, gap: 10, flexWrap: 'wrap' }}>
                <span className="cell-sub" style={{ fontSize: 11.5, fontWeight: 600 }}>
                  {note || `Raised ${formatDate(selected.createdAt)} · last activity ${timeAgo(selected.updatedAt)}`}
                </span>
                {selected.status !== 'resolved' && (
                  <button
                    className="btn-secondary"
                    disabled={busy || !reply.trim()}
                    onClick={() => void sendReply(true)}
                    style={{ padding: '6px 12px', fontSize: 12 }}
                  >
                    Send & Resolve
                  </button>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
