import { useCallback, useEffect, useState } from 'react';
import { IconBell, IconChat, IconCheck, IconUserCheck } from '../components/Icon';
import { Avatar, Badge, Drawer, FilterChips, InfoRow, PageHeader, StatCard } from '../components/ui';
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
const FILTER_TO_STATUS: Record<(typeof FILTERS)[number], SupportTicketStatus | 'all'> = {
  All: 'all',
  Open: 'open',
  'In Progress': 'in_progress',
  Resolved: 'resolved',
};

const EMPTY_COUNTS: SupportTicketCounts = { open: 0, in_progress: 0, resolved: 0, unread: 0 };

function timeAgo(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins} min ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  return formatDate(iso);
}

export default function SupportPage() {
  const [filter, setFilter] = useState<(typeof FILTERS)[number]>('All');
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [counts, setCounts] = useState<SupportTicketCounts>(EMPTY_COUNTS);
  const [loadError, setLoadError] = useState('');
  const [selected, setSelected] = useState<SupportTicket | null>(null);
  const [reply, setReply] = useState('');
  const [busy, setBusy] = useState(false);
  const [note, setNote] = useState('');

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

  useEffect(() => {
    void load();
  }, [load]);
  useRealtime(['support'], () => {
    void load();
  });

  const open = async (t: SupportTicket) => {
    setNote('');
    setReply('');
    try {
      setSelected(await fetchSupportTicket(t.id));
      // Opening clears the unread badge — refresh the list counts.
      void load();
    } catch {
      setSelected(t);
    }
  };

  const applyUpdate = (updated: SupportTicket) => {
    setSelected(updated);
    setReply('');
    void load();
  };

  const sendReply = async (andResolve = false) => {
    if (!selected || !reply.trim()) return;
    setBusy(true);
    setNote('');
    try {
      applyUpdate(
        await replySupportTicket(selected.id, reply.trim(), andResolve ? 'resolved' : undefined),
      );
      setNote(andResolve ? 'Reply sent and ticket resolved.' : 'Reply sent — the user has been notified.');
    } catch (err) {
      setNote(err instanceof Error ? err.message : 'Failed to send reply');
    } finally {
      setBusy(false);
    }
  };

  const changeStatus = async (status: SupportTicketStatus) => {
    if (!selected) return;
    setBusy(true);
    setNote('');
    try {
      applyUpdate(await setSupportTicketStatus(selected.id, status));
      setNote(`Status set to ${ticketStatusLabel(status)}.`);
    } catch (err) {
      setNote(err instanceof Error ? err.message : 'Failed to update status');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div>
      <PageHeader
        eyebrow="Operations"
        title="Help & Support"
        subtitle="Tickets raised from the app's Help & Support screen. Replies are delivered in-app with a notification."
      />

      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 14, marginBottom: 18 }}>
        <StatCard icon={<IconChat />} label="Open" value={String(counts.open)} />
        <StatCard icon={<IconUserCheck />} label="In Progress" value={String(counts.in_progress)} />
        <StatCard icon={<IconCheck />} label="Resolved" value={String(counts.resolved)} />
        <StatCard icon={<IconBell />} label="Unread Messages" value={String(counts.unread)} />
      </div>

      <div className="row" style={{ justifyContent: 'space-between', gap: 14, marginBottom: 16, flexWrap: 'wrap' }}>
        <FilterChips options={[...FILTERS]} active={filter} onChange={(v) => setFilter(v as (typeof FILTERS)[number])} />
        <button className="btn-secondary" onClick={() => void load()}>
          Refresh
        </button>
      </div>

      <div className="table-card">
        <table className="data">
          <thead>
            <tr>
              <th style={{ width: '40%' }}>Ticket</th>
              <th>User</th>
              <th>Category</th>
              <th>Last activity</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {tickets.map((t) => (
              <tr key={t.id} className="clickable" onClick={() => void open(t)}>
                <td>
                  <div className="row" style={{ gap: 8 }}>
                    {t.adminUnread > 0 && (
                      <span
                        title="New message"
                        style={{ width: 8, height: 8, borderRadius: '50%', background: 'var(--text-primary)', flexShrink: 0 }}
                      />
                    )}
                    <div className="cell-strong" style={{ whiteSpace: 'normal', lineHeight: 1.4 }}>
                      {t.subject}
                    </div>
                  </div>
                  <div className="cell-sub" style={{ whiteSpace: 'normal' }}>
                    {t.message.length > 90 ? `${t.message.slice(0, 87)}…` : t.message}
                  </div>
                </td>
                <td>
                  <div className="cell-strong">{t.userName}</div>
                  <div className="cell-sub">{roleLabel(t.userRole)}</div>
                </td>
                <td>{ticketCategoryLabel(t.category)}</td>
                <td>{timeAgo(t.updatedAt)}</td>
                <td>
                  <Badge label={ticketStatusLabel(t.status)} />
                </td>
              </tr>
            ))}
            {tickets.length === 0 && (
              <tr>
                <td colSpan={5} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  {loadError || 'No tickets match this filter.'}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {selected && (
        <Drawer
          title="Support Ticket"
          onClose={() => setSelected(null)}
          footer={
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <textarea
                className="input"
                rows={3}
                placeholder="Write a reply to the user…"
                value={reply}
                disabled={busy}
                onChange={(e) => setReply(e.target.value)}
                style={{ height: 'auto', resize: 'vertical' }}
              />
              <div className="row" style={{ gap: 8, flexWrap: 'wrap' }}>
                <button className="btn-primary" disabled={busy || !reply.trim()} onClick={() => void sendReply(false)}>
                  {busy ? 'Sending…' : 'Send Reply'}
                </button>
                <button className="btn-secondary" disabled={busy || !reply.trim()} onClick={() => void sendReply(true)}>
                  Reply & Resolve
                </button>
                {selected.status !== 'resolved' ? (
                  <button className="btn-secondary" disabled={busy} onClick={() => void changeStatus('resolved')}>
                    Mark Resolved
                  </button>
                ) : (
                  <button className="btn-secondary" disabled={busy} onClick={() => void changeStatus('open')}>
                    Reopen
                  </button>
                )}
                {selected.status === 'open' && (
                  <button className="btn-secondary" disabled={busy} onClick={() => void changeStatus('in_progress')}>
                    Mark In Progress
                  </button>
                )}
              </div>
              {note && (
                <div className="cell-sub" style={{ fontWeight: 600 }}>
                  {note}
                </div>
              )}
            </div>
          }
        >
          <div className="row" style={{ gap: 14, marginBottom: 18 }}>
            <Avatar name={selected.userName} size={48} square photo={selected.userPhoto ?? undefined} />
            <div>
              <div className="row" style={{ gap: 8 }}>
                <span style={{ fontSize: 16, fontWeight: 800, letterSpacing: -0.3 }}>{selected.userName}</span>
                <Badge label={ticketStatusLabel(selected.status)} />
              </div>
              <div className="cell-sub" style={{ fontSize: 12.5 }}>
                {roleLabel(selected.userRole)} · {ticketCategoryLabel(selected.category)} · Raised {formatDate(selected.createdAt)}
              </div>
            </div>
          </div>

          <div className="eyebrow" style={{ marginBottom: 8 }}>{selected.subject}</div>
          <div
            className="card-white"
            style={{ padding: '12px 14px', fontSize: 13, lineHeight: 1.6, color: 'var(--text-primary)', fontWeight: 600, whiteSpace: 'pre-wrap' }}
          >
            {selected.message}
          </div>

          {selected.replies.length > 0 && (
            <>
              <div className="eyebrow" style={{ margin: '18px 0 8px' }}>Conversation</div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {selected.replies.map((r) => (
                  <div
                    key={r.id}
                    className="card-white"
                    style={{
                      padding: '10px 14px',
                      fontSize: 13,
                      lineHeight: 1.6,
                      whiteSpace: 'pre-wrap',
                      color: r.fromAdmin ? 'var(--text-primary)' : 'var(--text-grey-555)',
                      borderLeft: r.fromAdmin ? '3px solid var(--text-primary)' : '3px solid var(--border-grey)',
                    }}
                  >
                    <div className="cell-sub" style={{ marginBottom: 2, fontWeight: 700 }}>
                      {r.fromAdmin ? 'ADVOK Support' : selected.userName} · {timeAgo(r.createdAt)}
                    </div>
                    {r.text}
                  </div>
                ))}
              </div>
            </>
          )}

          <div style={{ marginTop: 18 }}>
            <InfoRow k="Ticket ID" v={selected.id.slice(0, 8).toUpperCase()} />
            <InfoRow k="Email" v={selected.userEmail ?? '—'} />
            <InfoRow k="Phone" v={selected.userPhone ?? '—'} />
            <InfoRow k="Last activity" v={formatDate(selected.updatedAt)} />
            {selected.resolvedAt && <InfoRow k="Resolved" v={formatDate(selected.resolvedAt)} />}
          </div>
        </Drawer>
      )}
    </div>
  );
}
