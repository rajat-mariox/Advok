import { useCallback, useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { fetchAdminNotifications, markAdminNotificationsRead, type AdminNotification } from '../utils/backend';
import { useRealtime } from '../utils/realtime';
import { IconBell } from './Icon';

const DESKTOP_KEY = 'advok_admin_desktop_alerts';

/** Desktop alerts on/off (Settings toggle). Default on. */
export function desktopAlertsEnabled(): boolean {
  try {
    return localStorage.getItem(DESKTOP_KEY) !== 'off';
  } catch {
    return true;
  }
}

export function setDesktopAlertsEnabled(on: boolean): void {
  try {
    localStorage.setItem(DESKTOP_KEY, on ? 'on' : 'off');
  } catch {
    // ignore
  }
  if (on && 'Notification' in window && Notification.permission === 'default') {
    void Notification.requestPermission();
  }
}

function ago(iso: string): string {
  const s = Math.max(0, (Date.now() - new Date(iso).getTime()) / 1000);
  if (s < 60) return 'Just now';
  if (s < 3600) return `${Math.floor(s / 60)} min ago`;
  if (s < 86400) return `${Math.floor(s / 3600)}h ago`;
  return `${Math.floor(s / 86400)}d ago`;
}

/** Header bell: unread badge, dropdown list, mark read, live updates. */
export default function NotificationBell() {
  const navigate = useNavigate();
  const [open, setOpen] = useState(false);
  const [items, setItems] = useState<AdminNotification[]>([]);
  const [unread, setUnread] = useState(0);
  const seen = useRef<Set<string> | null>(null);
  const wrap = useRef<HTMLDivElement>(null);

  const load = useCallback(async () => {
    try {
      const r = await fetchAdminNotifications();
      // Desktop alert for notifications that arrived since the last load,
      // only when the admin isn't looking at the tab.
      if (seen.current && document.hidden && desktopAlertsEnabled() && 'Notification' in window && Notification.permission === 'granted') {
        for (const n of r.notifications.filter((x) => !x.readAt && !seen.current!.has(x.id)).slice(0, 3)) {
          const alert = new Notification(n.title, { body: n.body, tag: n.id });
          alert.onclick = () => {
            window.focus();
            navigate(n.link);
          };
        }
      }
      seen.current = new Set(r.notifications.map((x) => x.id));
      setItems(r.notifications);
      setUnread(r.unread);
    } catch {
      // Bell just keeps its last state.
    }
  }, [navigate]);

  useEffect(() => {
    void load();
    if (desktopAlertsEnabled() && 'Notification' in window && Notification.permission === 'default') {
      void Notification.requestPermission();
    }
  }, [load]);

  useRealtime(['adminNotifications'], () => void load());

  useEffect(() => {
    if (!open) return;
    const onDoc = (e: MouseEvent) => {
      if (wrap.current && !wrap.current.contains(e.target as Node)) setOpen(false);
    };
    document.addEventListener('mousedown', onDoc);
    return () => document.removeEventListener('mousedown', onDoc);
  }, [open]);

  const markAll = async () => {
    await markAdminNotificationsRead().catch(() => undefined);
    void load();
  };

  const openItem = async (n: AdminNotification) => {
    setOpen(false);
    if (!n.readAt) {
      await markAdminNotificationsRead([n.id]).catch(() => undefined);
      void load();
    }
    navigate(n.link);
  };

  return (
    <div ref={wrap} style={{ position: 'relative' }}>
      <button
        className="close-circle"
        aria-label={`Notifications${unread ? ` (${unread} unread)` : ''}`}
        style={{ position: 'relative', background: 'var(--fill-grey)' }}
        onClick={() => setOpen((o) => !o)}
      >
        <IconBell />
        {unread > 0 && (
          <span
            style={{
              position: 'absolute',
              top: 2,
              right: 2,
              minWidth: 16,
              height: 16,
              padding: '0 4px',
              borderRadius: 8,
              background: 'var(--dark-1a)',
              color: 'var(--white)',
              fontSize: 9.5,
              fontWeight: 700,
              lineHeight: '16px',
              textAlign: 'center',
              border: '1.4px solid var(--white)',
            }}
          >
            {unread > 99 ? '99+' : unread}
          </span>
        )}
      </button>

      {open && (
        <div
          style={{
            position: 'absolute',
            right: 0,
            top: 46,
            width: 360,
            maxHeight: 460,
            overflow: 'auto',
            background: 'var(--white)',
            border: '1px solid var(--border-grey, #dedede)',
            borderRadius: 14,
            boxShadow: '0 12px 32px rgba(0,0,0,0.12)',
            zIndex: 50,
          }}
        >
          <div className="row" style={{ justifyContent: 'space-between', padding: '12px 14px', borderBottom: '1px solid var(--divider)' }}>
            <span style={{ fontSize: 14, fontWeight: 800 }}>Notifications</span>
            <button className="btn-pill-grey" onClick={markAll} disabled={unread === 0}>
              Mark all read
            </button>
          </div>
          {items.length === 0 ? (
            <div className="cell-sub" style={{ padding: 24, textAlign: 'center' }}>
              No notifications yet. New registrations, support tickets, legal queries, bookings and student–attorney
              conversations show up here.
            </div>
          ) : (
            items.slice(0, 40).map((n) => (
              <button
                key={n.id}
                onClick={() => openItem(n)}
                style={{
                  display: 'block',
                  width: '100%',
                  textAlign: 'left',
                  padding: '11px 14px',
                  border: 'none',
                  borderBottom: '1px solid var(--divider)',
                  background: n.readAt ? 'transparent' : 'var(--fill-grey)',
                  cursor: 'pointer',
                }}
              >
                <div className="row" style={{ justifyContent: 'space-between', gap: 8 }}>
                  <span style={{ fontSize: 13, fontWeight: n.readAt ? 600 : 800 }}>{n.title}</span>
                  <span className="cell-sub" style={{ whiteSpace: 'nowrap', marginTop: 0 }}>{ago(n.createdAt)}</span>
                </div>
                <div className="cell-sub" style={{ whiteSpace: 'normal', lineHeight: 1.45 }}>{n.body}</div>
              </button>
            ))
          )}
        </div>
      )}
    </div>
  );
}
