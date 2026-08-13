import type { CSSProperties, ReactNode } from 'react';
import { IconX } from './Icon';

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
}: {
  title: string;
  onClose: () => void;
  children: ReactNode;
  footer?: ReactNode;
}) {
  return (
    <>
      <div className="drawer-overlay" onClick={onClose} />
      <aside className="drawer">
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
