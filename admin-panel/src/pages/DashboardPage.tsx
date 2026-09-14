import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  IconBuilding,
  IconCalendar,
  IconChevronRight,
  IconDollar,
  IconGraduation,
  IconScale,
  IconUsers,
} from '../components/Icon';
import { Avatar, Badge, PageHeader, StatCard } from '../components/ui';
import {
  bookingStatusLabel,
  consultationTypeLabel,
  fetchAdminBookings,
  fetchAdminCases,
  fetchBackendUsers,
  formatDate,
  type BackendBooking,
  type BackendCase,
  type BackendUser,
} from '../utils/backend';
import { money } from '../utils/seed';
import { useRealtime } from '../utils/realtime';

function queueEntry(u: BackendUser) {
  const p: any = u.profile ?? {};
  if (u.role === 'advocate') {
    return {
      key: u.id,
      name: p.professional?.fullName ?? 'Attorney',
      sub: p.professional?.practiceArea ?? '—',
      role: 'Attorney',
      to: '/advocates',
      badge: 'Pending Review',
    };
  }
  if (u.role === 'law_student') {
    return {
      key: u.id,
      name: p.fullName ?? 'Law Student',
      sub: `${p.college ?? '—'} · ${p.course ?? '—'}`,
      role: 'Student',
      to: '/law-students',
      badge: 'Pending Verification',
    };
  }
  return {
    key: u.id,
    name: p.firmName ?? 'Law Firm',
    sub: `${p.contactPerson ?? '—'} · ${p.city ?? '—'}`,
    role: 'Law Firm',
    to: '/law-firms',
    badge: 'Pending Approval',
  };
}

function EmptyNote({ text }: { text: string }) {
  return (
    <div className="cell-sub" style={{ padding: 12 }}>
      {text}
    </div>
  );
}

export default function DashboardPage() {
  const [users, setUsers] = useState<BackendUser[]>([]);
  const [bookings, setBookings] = useState<BackendBooking[]>([]);
  const [cases, setCases] = useState<BackendCase[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState('');

  const [tick, setTick] = useState(0);
  useRealtime(['users', 'bookings', 'cases', 'registrations'], () => setTick((t) => t + 1));

  useEffect(() => {
    Promise.all([
      fetchBackendUsers(),
      fetchAdminBookings().catch(() => []),
      fetchAdminCases().catch(() => []),
    ])
      .then(([userList, bookingList, caseList]) => {
        setUsers(userList);
        setBookings(bookingList);
        setCases(caseList);
      })
      .catch(() =>
        setLoadError('Could not reach the backend on port 4000 — stats show zero until it is running.'),
      )
      .finally(() => setLoading(false));
  }, [tick]);

  const count = (role: BackendUser['role']) => users.filter((u) => u.role === role).length;
  const pendingOf = (role: BackendUser['role']) =>
    users.filter((u) => u.role === role && u.status === 'pending_approval').length;
  const reviewQueue = users.filter((u) => u.status === 'pending_approval').map(queueEntry);

  const monthKey = new Date().toISOString().slice(0, 7);
  const monthRevenue = bookings
    .filter(
      (b) =>
        (b.status === 'confirmed' || b.status === 'completed') &&
        b.date.startsWith(monthKey),
    )
    .reduce((sum, b) => sum + b.amount, 0);
  const pendingBookings = bookings.filter((b) => b.status === 'pending').length;
  const recentBookings = bookings.slice(0, 4);
  const activeCases = cases.filter((c) => c.status !== 'closed').slice(0, 4);

  return (
    <div>
      <PageHeader
        eyebrow="Overview"
        title="Dashboard"
        subtitle="What's happening across the ADVOK platform."
      />

      {loadError && (
        <div
          style={{
            padding: '12px 16px',
            borderRadius: 12,
            background: 'rgba(220, 53, 69, 0.08)',
            color: '#c92a3a',
            fontSize: 13,
            fontWeight: 600,
            marginBottom: 16,
          }}
        >
          {loadError}
        </div>
      )}

      <div className="grid-stats" style={{ marginBottom: 22 }}>
        <StatCard
          icon={<IconScale />}
          value={String(count('advocate'))}
          label="Attorneys"
          trend={`${pendingOf('advocate')} awaiting review`}
        />
        <StatCard icon={<IconUsers />} value={String(count('client'))} label="Clients" trend="Registered via app" />
        <StatCard
          icon={<IconBuilding />}
          value={String(count('law_firm'))}
          label="Law Firms"
          trend={`${pendingOf('law_firm')} awaiting approval`}
        />
        <StatCard
          icon={<IconGraduation />}
          value={String(count('law_student'))}
          label="Law Students"
          trend={`${pendingOf('law_student')} awaiting verification`}
        />
        <StatCard
          icon={<IconCalendar />}
          value={String(bookings.length)}
          label="Bookings"
          trend={`${pendingBookings} awaiting response`}
        />
        <StatCard
          icon={<IconDollar />}
          value={money(monthRevenue)}
          label="Revenue · This Month"
          trend="Confirmed consultations"
        />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1.6fr 1fr', gap: 16, marginBottom: 22 }}>
        <div className="card" style={{ padding: 20 }}>
          <div className="row" style={{ justifyContent: 'space-between', marginBottom: 4 }}>
            <span className="section-title">Revenue Overview</span>
          </div>
          <div style={{ fontSize: 26, fontWeight: 800, letterSpacing: -0.5, marginBottom: 16 }}>
            {money(monthRevenue)}
            <span style={{ fontSize: 12, fontWeight: 500, color: 'var(--text-grey)' }}> /this month</span>
          </div>
          {recentBookings.length === 0 ? (
            <div
              className="cell-sub"
              style={{
                height: 120,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                textAlign: 'center',
              }}
            >
              Revenue appears here once consultations are booked.
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {recentBookings.map((b) => (
                <div key={b.id} className="row" style={{ justifyContent: 'space-between', gap: 10 }}>
                  <span className="cell-sub" style={{ minWidth: 0, overflow: 'hidden', textOverflow: 'ellipsis' }}>
                    {b.clientName} → {b.advocateName} · {consultationTypeLabel(b.consultationType)}
                  </span>
                  <span className="cell-strong">{money(b.amount)}</span>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Unified review queue: advocates + firms + students */}
        <div className="card" style={{ padding: 20, display: 'flex', flexDirection: 'column' }}>
          <div className="row" style={{ justifyContent: 'space-between', marginBottom: 14 }}>
            <span className="section-title">Verification Queue</span>
            <span className="badge-solid">{reviewQueue.length} Pending</span>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10, flex: 1, overflowY: 'auto' }}>
            {reviewQueue.map((item) => (
              <Link key={item.key} to={item.to} className="card-white row" style={{ padding: '10px 12px', gap: 11 }}>
                <Avatar name={item.name} size={36} square />
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div className="cell-strong">{item.name}</div>
                  <div className="cell-sub">
                    {item.role} · {item.sub}
                  </div>
                </div>
                <Badge label={item.badge} />
              </Link>
            ))}
            {reviewQueue.length === 0 && (
              <EmptyNote text={loading ? 'Loading…' : 'No registrations awaiting review.'} />
            )}
          </div>
          <Link to="/approvals" className="btn-secondary" style={{ marginTop: 14, height: 40 }}>
            Open Approvals <IconChevronRight size={13} />
          </Link>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        <div className="card" style={{ padding: 20 }}>
          <div className="row" style={{ justifyContent: 'space-between', marginBottom: 14 }}>
            <span className="section-title">Recent Bookings</span>
            <Link to="/bookings" className="btn-pill-grey" style={{ height: 26 }}>
              View All
            </Link>
          </div>
          {recentBookings.length === 0 ? (
            <EmptyNote text={loading ? 'Loading…' : 'No bookings yet.'} />
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {recentBookings.map((b) => (
                <div key={b.id} className="card-white row" style={{ padding: '10px 12px', gap: 11 }}>
                  <Avatar name={b.clientName} size={36} square />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div className="cell-strong">{b.clientName}</div>
                    <div className="cell-sub">
                      {consultationTypeLabel(b.consultationType)} with {b.advocateName} · {formatDate(b.date)} {b.time}
                    </div>
                  </div>
                  <Badge label={bookingStatusLabel(b.status)} />
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="card" style={{ padding: 20 }}>
          <div className="row" style={{ justifyContent: 'space-between', marginBottom: 14 }}>
            <span className="section-title">Active Cases</span>
            <Link to="/cases" className="btn-pill-grey" style={{ height: 26 }}>
              View All
            </Link>
          </div>
          {activeCases.length === 0 ? (
            <EmptyNote text={loading ? 'Loading…' : 'No active cases yet.'} />
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {activeCases.map((c) => (
                <div key={c.id} className="card-white row" style={{ padding: '10px 12px', gap: 11 }}>
                  <Avatar name={c.title} size={36} square />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div className="cell-strong">{c.title}</div>
                    <div className="cell-sub">
                      {c.caseNumber.toUpperCase()} · {c.clientName} · {c.advocateName}
                    </div>
                  </div>
                  <Badge label={c.status.charAt(0).toUpperCase() + c.status.slice(1)} />
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
