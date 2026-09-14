import type { CSSProperties, MouseEvent, ReactNode } from 'react';
import { IconEye, IconTrash, IconUserRestore, IconUserX, IconX } from './Icon';

// Greyscale status system — same base shades the app uses for its badges.
const STATUS_SHADES: Record<string, string> = {
  Confirmed: '#2a2a2a',
  Active: '#2a2a2a',
  Verified: '#2a2a2a',
  Paid: '#2a2a2a',
  Online: '#2a2a2a',
  Answered: '#2a2a2a',
  Accepted: '#2a2a2a',
  Published: '#2a2a2a',
  Open: '#2a2a2a',
  Completed: '#999999',
  Closed: '#999999',
  Low: '#999999',
  Beginner: '#999999',
  Draft: '#999999',
  Full: '#999999',
  Pending: '#555555',
  'Pending Review': '#555555',
  'Pending Approval': '#555555',
  'Pending Verification': '#555555',
  Requested: '#555555',
  Processing: '#555555',
  Upcoming: '#555555',
  Hearing: '#555555',
  Medium: '#555555',
  Intermediate: '#555555',
  Discovery: '#333333',
  Cancelled: '#1a1a1a',
  Rejected: '#1a1a1a',
  Suspended: '#1a1a1a',
  Declined: '#1a1a1a',
  'On Hold': '#1a1a1a',
  High: '#1a1a1a',
  Advanced: '#1a1a1a',
};

export function Badge({ label }: { label: string }) {
  const shade = STATUS_SHADES[label] ?? '#555555';
  return (
    <span className="badge" style={{ '--badge-base': shade } as CSSProperties}>
      {label}
    </span>
  );
}

export function Avatar({
  name,
  size = 36,
  square = false,
  photo,
}: {
  name: string;
  size?: number;
  square?: boolean;
  /** Profile picture as a data URL (uploaded from the app); falls back to initials. */
  photo?: string;
}) {
  const initials = name
    .split(' ')
    .filter(Boolean)
    .slice(0, 2)
    .map((w) => w[0])
    .join('')
    .toUpperCase();
  return (
    <span
      className={`avatar${square ? ' avatar-sq' : ''}`}
      style={{ width: size, height: size, fontSize: size * 0.36, overflow: 'hidden' }}
    >
      {photo ? (
        <img
          src={photo}
          alt={name}
          style={{ width: '100%', height: '100%', objectFit: 'cover' }}
        />
      ) : (
        initials
      )}
    </span>
  );
}

export function PageHeader({
  eyebrow,
  title,
  subtitle,
  actions,
}: {
  eyebrow?: string;
  title: string;
  subtitle?: string;
  actions?: ReactNode;
}) {
  return (
    <div
      className="row"
      style={{ justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: 22 }}
    >
      <div>
        {eyebrow && <div className="eyebrow" style={{ marginBottom: 6 }}>{eyebrow}</div>}
        <h1 className="page-title">{title}</h1>
        {subtitle && <p className="page-subtitle">{subtitle}</p>}
      </div>
      {actions && <div className="row" style={{ gap: 10 }}>{actions}</div>}
    </div>
  );
}

export function StatCard({
  icon,
  value,
  label,
  trend,
}: {
  icon: ReactNode;
  value: string;
  label: string;
  trend?: string;
}) {
  return (
    <div className="stat-card">
      <div className="stat-icon">{icon}</div>
      <div className="stat-value">{value}</div>
      <div className="stat-label">{label}</div>
      {trend && <div className="stat-trend">{trend}</div>}
    </div>
  );
}

export function Drawer({
  title,
  onClose,
  children,
  footer,
  wide = false,
}: {
  title: string;
  onClose: () => void;
  children: ReactNode;
  footer?: ReactNode;
  /** Wider panel for detail views with grids and lists. */
  wide?: boolean;
}) {
  return (
    <>
      <div className="drawer-overlay" onClick={onClose} />
      <aside className={`drawer${wide ? ' drawer-wide' : ''}`}>
        <div className="drawer-head">
          <span className="section-title">{title}</span>
          <button className="close-circle" onClick={onClose} aria-label="Close">
            <IconX />
          </button>
        </div>
        <div className="drawer-body">{children}</div>
        {footer && (
          <div style={{ padding: '16px 22px', borderTop: '1px solid var(--divider)' }}>
            {footer}
          </div>
        )}
      </aside>
    </>
  );
}

export function InfoRow({ k, v }: { k: string; v: ReactNode }) {
  return (
    <div className="info-row">
      <span className="k">{k}</span>
      <span className="v">{v}</span>
    </div>
  );
}

export function FilterChips({
  options,
  active,
  onChange,
}: {
  options: string[];
  active: string;
  onChange: (v: string) => void;
}) {
  return (
    <div className="row" style={{ gap: 8, flexWrap: 'wrap' }}>
      {options.map((o) => (
        <button
          key={o}
          className={`chip${active === o ? ' active' : ''}`}
          onClick={() => onChange(o)}
        >
          {o}
        </button>
      ))}
    </div>
  );
}

/** Suspend/Reactivate + Delete row shown in every user drawer footer. */
export function AccountActions({
  suspended,
  onSuspend,
  onUnsuspend,
  onDelete,
}: {
  suspended: boolean;
  onSuspend: () => void;
  onUnsuspend: () => void;
  onDelete: () => void;
}) {
  const btn = { flex: 1, height: 44, borderRadius: 14 } as const;
  return (
    <div className="row" style={{ gap: 10 }}>
      {suspended ? (
        <button className="btn-primary" style={btn} onClick={onUnsuspend}>
          Reactivate Account
        </button>
      ) : (
        <button className="btn-secondary" style={btn} onClick={onSuspend}>
          Suspend Account
        </button>
      )}
      <button className="btn-danger" style={btn} onClick={onDelete}>
        Delete Account
      </button>
    </div>
  );
}

export function ComingSoon({
  icon,
  title,
  description,
}: {
  icon: ReactNode;
  title: string;
  description: string;
}) {
  return (
    <div className="coming-soon">
      <div className="coming-icon">{icon}</div>
      <div className="eyebrow" style={{ marginBottom: 8 }}>Coming Soon</div>
      <h2 className="page-title" style={{ fontSize: 20 }}>{title}</h2>
      <p
        className="page-subtitle"
        style={{ maxWidth: 380, lineHeight: 1.6, marginTop: 8 }}
      >
        {description}
      </p>
    </div>
  );
}

// ---------- Detail-drawer building blocks ----------

/** Avatar + name + badge + subtitle block at the top of a detail drawer. */
export function DrawerHero({
  name,
  photo,
  square = false,
  badge,
  subtitle,
}: {
  name: string;
  photo?: string;
  square?: boolean;
  badge?: string;
  subtitle?: ReactNode;
}) {
  return (
    <div className="drawer-hero">
      <Avatar name={name} photo={photo} size={56} square={square} />
      <div style={{ minWidth: 0 }}>
        <div className="row" style={{ gap: 8, flexWrap: 'wrap' }}>
          <span className="drawer-hero-name">{name}</span>
          {badge && <Badge label={badge} />}
        </div>
        {subtitle && <div className="drawer-hero-sub">{subtitle}</div>}
      </div>
    </div>
  );
}

/** Row of up to three number tiles. */
export function DrawerStats({ items }: { items: { value: ReactNode; label: string }[] }) {
  return (
    <div className="drawer-stats" style={{ gridTemplateColumns: `repeat(${items.length}, 1fr)` }}>
      {items.map((it) => (
        <div key={it.label} className="drawer-stat">
          <div className="drawer-stat-value">{it.value}</div>
          <div className="drawer-stat-label">{it.label}</div>
        </div>
      ))}
    </div>
  );
}

/** Titled card. Put InfoRows inside for a label/value list, or pass `grid`
 *  cells for a two-column tile layout, or any custom children. */
export function DetailSection({
  title,
  aside,
  children,
  flush = false,
}: {
  title: string;
  aside?: ReactNode;
  children: ReactNode;
  /** No inner padding — for lists/grids that manage their own spacing. */
  flush?: boolean;
}) {
  return (
    <div className="detail-section">
      <div className="detail-section-head">
        <span className="eyebrow" style={{ color: 'var(--text-grey-555)' }}>{title}</span>
        {aside}
      </div>
      {flush ? children : <div className="detail-section-body">{children}</div>}
    </div>
  );
}

export function DetailGrid({ cells }: { cells: { k: string; v: ReactNode }[] }) {
  return (
    <div className="detail-grid">
      {cells.map((c) => (
        <div key={c.k} className="detail-cell">
          <span className="k">{c.k}</span>
          <span className="v">{c.v ?? '—'}</span>
        </div>
      ))}
    </div>
  );
}

export function ChipList({ items, empty = '—' }: { items: string[]; empty?: string }) {
  if (!items.length) return <span style={{ fontSize: 13, fontWeight: 600, color: 'var(--text-grey)' }}>{empty}</span>;
  return (
    <div className="chip-list">
      {items.map((i) => (
        <span key={i} className="chip-static">{i}</span>
      ))}
    </div>
  );
}

export function ListItem({
  title,
  sub,
  right,
}: {
  title: ReactNode;
  sub?: ReactNode;
  right?: ReactNode;
}) {
  return (
    <div className="list-item">
      <div className="list-item-main">
        <div className="list-item-title">{title}</div>
        {sub && <div className="list-item-sub">{sub}</div>}
      </div>
      {right && <div style={{ flexShrink: 0 }}>{right}</div>}
    </div>
  );
}

export function ListEmpty({ text }: { text: string }) {
  return <div className="list-empty">{text}</div>;
}

/** View / Suspend (or Reactivate) / Delete icon buttons for a table row. */
export function RowActions({
  suspended,
  onView,
  onSuspend,
  onUnsuspend,
  onDelete,
}: {
  suspended: boolean;
  onView: () => void;
  onSuspend: () => void;
  onUnsuspend: () => void;
  onDelete: () => void;
}) {
  const stop = (fn: () => void) => (e: MouseEvent) => {
    e.stopPropagation();
    fn();
  };
  return (
    <div className="row-actions" onClick={(e) => e.stopPropagation()}>
      <button className="icon-btn" aria-label="View details" title="View details" onClick={stop(onView)}>
        <IconEye />
      </button>
      {suspended ? (
        <button
          className="icon-btn"
          aria-label="Reactivate account"
          title="Reactivate account"
          onClick={stop(onUnsuspend)}
        >
          <IconUserRestore />
        </button>
      ) : (
        <button className="icon-btn" aria-label="Suspend account" title="Suspend account" onClick={stop(onSuspend)}>
          <IconUserX />
        </button>
      )}
      <button className="icon-btn icon-btn-danger" aria-label="Delete account" title="Delete account" onClick={stop(onDelete)}>
        <IconTrash />
      </button>
    </div>
  );
}
