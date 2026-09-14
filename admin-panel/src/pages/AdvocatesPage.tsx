import { useEffect, useMemo, useState } from 'react';
import { IconCheck, IconSearch, IconX } from '../components/Icon';
import {
  Avatar,
  Badge,
  ChipList,
  DetailGrid,
  DetailSection,
  Drawer,
  DrawerHero,
  FilterChips,
  InfoRow,
  ListEmpty,
  ListItem,
  PageHeader,
  RowActions,
} from '../components/ui';
import type { AdminAdvocate, VerificationStatus } from '../types';
import {
  barSummary,
  deleteBackendUser,
  fetchBackendUsers,
  hasSubmittedProfile,
  reviewRegistration,
  suspendBackendUser,
  toAdminAdvocate,
  unsuspendBackendUser,
} from '../utils/backend';
import { US_FIRM_ROLES } from '../utils/seed';
import { useRealtime } from '../utils/realtime';

const STATUS_FILTERS = ['All', 'Pending Review', 'Verified', 'Rejected', 'Suspended'];

const WEEKDAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

export default function AdvocatesPage() {
  const [advocates, setAdvocates] = useState<AdminAdvocate[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState('');
  const [filter, setFilter] = useState('All');
  const [roleFilter, setRoleFilter] = useState('All roles');
  const [stateFilter, setStateFilter] = useState('All states');
  const [query, setQuery] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const load = () =>
    fetchBackendUsers('advocate')
      .then((users) => setAdvocates(users.filter(hasSubmittedProfile).map(toAdminAdvocate)))
      .catch(() =>
        setLoadError('Could not load attorneys. Make sure the backend is running on port 4000.'),
      );

  useEffect(() => {
    load().finally(() => setLoading(false));
  }, []);
  useRealtime(['users'], () => {
    void load();
  });

  // Role and state dropdowns: the US catalog plus anything unusual in the data.
  const roleOptions = useMemo(() => {
    const seen = new Set<string>(US_FIRM_ROLES);
    advocates.forEach((a) => seen.add(a.firmRole));
    return ['All roles', ...Array.from(seen)];
  }, [advocates]);

  const stateOptions = useMemo(() => {
    const seen = new Set<string>();
    advocates.forEach((a) => {
      if (a.state && a.state !== '—') seen.add(a.state);
      a.barAdmissions.forEach((b) => b.state && seen.add(b.state));
    });
    return ['All states', ...Array.from(seen).sort()];
  }, [advocates]);

  const list = useMemo(() => {
    const q = query.trim().toLowerCase();
    return advocates.filter((a) => {
      const matchesStatus = filter === 'All' || a.verification === filter;
      const matchesRole = roleFilter === 'All roles' || a.firmRole === roleFilter;
      const matchesState =
        stateFilter === 'All states' ||
        a.state === stateFilter ||
        a.barAdmissions.some((b) => b.state === stateFilter);
      const matchesQuery =
        !q ||
        a.name.toLowerCase().includes(q) ||
        a.practiceArea.toLowerCase().includes(q) ||
        a.email.toLowerCase().includes(q) ||
        a.city.toLowerCase().includes(q) ||
        barSummary(a).toLowerCase().includes(q) ||
        a.phone.replace(/\s/g, '').includes(q.replace(/\s/g, ''));
      return matchesStatus && matchesRole && matchesState && matchesQuery;
    });
  }, [advocates, filter, roleFilter, stateFilter, query]);

  const selected = advocates.find((a) => a.id === selectedId) ?? null;

  const setVerification = async (id: string, verification: VerificationStatus) => {
    const ok = await reviewRegistration(id, verification);
    if (ok) {
      setAdvocates((prev) => prev.map((a) => (a.id === id ? { ...a, verification } : a)));
    }
  };

  const suspendUser = async (id: string) => {
    const reason = window.prompt('Reason for suspension (optional):');
    if (reason === null) return;
    const trimmed = reason.trim() || undefined;
    const ok = await suspendBackendUser(id, trimmed);
    if (ok) {
      setAdvocates((prev) =>
        prev.map((a) =>
          a.id === id ? { ...a, verification: 'Suspended', suspensionReason: trimmed } : a,
        ),
      );
    }
  };

  // The backend restores the pre-suspension status, so reload to pick it up.
  const unsuspendUser = async (id: string) => {
    const ok = await unsuspendBackendUser(id);
    if (ok) await load();
  };

  const deleteUser = async (id: string) => {
    if (!window.confirm('Permanently delete this attorney account? This cannot be undone.')) return;
    const ok = await deleteBackendUser(id);
    if (ok) {
      setAdvocates((prev) => prev.filter((a) => a.id !== id));
      setSelectedId(null);
    }
  };

  const pending = advocates.filter((a) => a.verification === 'Pending Review').length;

  return (
    <div>
      <PageHeader
        eyebrow="Users"
        title="Attorneys"
        subtitle={`${advocates.length} registered · ${pending} awaiting bar verification`}
      />

      <div className="row" style={{ justifyContent: 'space-between', gap: 14, marginBottom: 16, flexWrap: 'wrap' }}>
        <FilterChips options={STATUS_FILTERS} active={filter} onChange={setFilter} />
        <div className="row" style={{ gap: 10, flexWrap: 'wrap' }}>
          <select
            className="input"
            style={{ height: 40, width: 170 }}
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            aria-label="Filter by firm role"
          >
            {roleOptions.map((r) => (
              <option key={r} value={r}>{r}</option>
            ))}
          </select>
          <select
            className="input"
            style={{ height: 40, width: 160 }}
            value={stateFilter}
            onChange={(e) => setStateFilter(e.target.value)}
            aria-label="Filter by state"
          >
            {stateOptions.map((s) => (
              <option key={s} value={s}>{s}</option>
            ))}
          </select>
          <div className="search-wrap" style={{ width: 260 }}>
            <IconSearch />
            <input
              className="input"
              placeholder="Search name, practice area, bar no..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              style={{ height: 40 }}
            />
          </div>
        </div>
      </div>

      <div className="table-card">
        <table className="data">
          <thead>
            <tr>
              <th>Attorney</th>
              <th>Phone</th>
              <th>Firm Role</th>
              <th>Years in Practice</th>
              <th>Bar Admissions</th>
              <th>Location</th>
              <th>Verification</th>
              <th style={{ textAlign: 'center' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {list.map((a) => (
              <tr key={a.id} className="clickable" onClick={() => setSelectedId(a.id)}>
                <td>
                  <div className="row" style={{ gap: 10 }}>
                    <Avatar name={a.name} photo={a.photo} size={34} square />
                    <div>
                      <div className="cell-strong">{a.name}</div>
                      <div className="cell-sub">{a.practiceArea}</div>
                    </div>
                  </div>
                </td>
                <td style={{ whiteSpace: 'nowrap' }}>{a.phone}</td>
                <td>
                  <div>{a.firmRole}</div>
                  {a.firmName && <div className="cell-sub">at {a.firmName}</div>}
                </td>
                <td>{a.yearsInPractice}</td>
                <td>
                  {a.barAdmissions.length > 0 ? (
                    <div className="row" style={{ gap: 5, flexWrap: 'wrap' }}>
                      {a.barAdmissions.map((b, i) => (
                        <span
                          key={i}
                          className="chip-static"
                          title={`${b.state} · ${b.licenseStatus}`}
                          style={{ height: 22, fontSize: 10.5 }}
                        >
                          {b.state} #{b.barNumber || '—'}
                        </span>
                      ))}
                    </div>
                  ) : (
                    <span style={{ fontWeight: 600 }}>{a.barNumber || '—'}</span>
                  )}
                  {a.federalCourts.length > 0 && (
                    <div className="cell-sub">+ {a.federalCourts.length} federal court{a.federalCourts.length > 1 ? 's' : ''}</div>
                  )}
                </td>
                <td>
                  <div>{a.city}</div>
                  <div className="cell-sub">{a.state}</div>
                </td>
                <td>
                  <Badge label={a.verification} />
                </td>
                <td style={{ textAlign: 'center' }}>
                  <RowActions
                    suspended={a.verification === 'Suspended'}
                    onView={() => setSelectedId(a.id)}
                    onSuspend={() => suspendUser(a.id)}
                    onUnsuspend={() => unsuspendUser(a.id)}
                    onDelete={() => deleteUser(a.id)}
                  />
                </td>
              </tr>
            ))}
            {list.length === 0 && (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  {loading
                    ? 'Loading attorneys…'
                    : loadError || 'No attorneys match this filter.'}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {selected && (
        <Drawer
          wide
          title="Attorney Details"
          onClose={() => setSelectedId(null)}
          footer={
            selected.verification === 'Pending Review' ? (
              <div className="row" style={{ gap: 10 }}>
                <button
                  className="btn-primary"
                  style={{ flex: 1 }}
                  onClick={() => setVerification(selected.id, 'Verified')}
                >
                  <IconCheck /> Approve
                </button>
                <button
                  className="btn-danger"
                  style={{ flex: 1, height: 44, borderRadius: 14, fontSize: 13.5, gap: 8 }}
                  onClick={() => setVerification(selected.id, 'Rejected')}
                >
                  <IconX /> Reject
                </button>
              </div>
            ) : selected.verification !== 'Suspended' ? (
              <button
                className="btn-secondary"
                style={{ width: '100%' }}
                onClick={() => setVerification(selected.id, 'Pending Review')}
              >
                Move Back to Review
              </button>
            ) : undefined
          }
        >
          <DrawerHero
            name={selected.name}
            photo={selected.photo}
            square
            badge={selected.verification}
            subtitle={`${selected.firmRole} · ${selected.practiceArea} · ${selected.yearsInPractice}`}
          />

          {selected.verification === 'Pending Review' && (
            <div className="note-box">
              <span className="k">Verify before approving</span>
              Check each bar number against the state bar's attorney search. Approval unlocks
              client bookings, case management and the Verified badge in the app.
            </div>
          )}
          {selected.verification === 'Rejected' && selected.rejectionReason && (
            <div className="note-box">
              <span className="k">Rejection Reason</span>
              {selected.rejectionReason}
            </div>
          )}
          {selected.verification === 'Suspended' && (
            <div className="note-box">
              <span className="k">Suspension Reason</span>
              {selected.suspensionReason || 'No reason recorded.'}
            </div>
          )}

          <DetailSection title="Account" flush>
            <DetailGrid
              cells={[
                { k: 'Login Phone', v: selected.phone },
                { k: 'Email', v: selected.email },
                { k: 'Country', v: selected.country ?? '—' },
                { k: 'Joined', v: selected.joined },
                { k: 'Submitted', v: selected.submitted },
              ]}
            />
          </DetailSection>

          <DetailSection title="Professional Details" flush>
            <DetailGrid
              cells={[
                { k: 'Firm Role', v: selected.firmRole },
                ...(selected.firmName ? [{ k: 'Law Firm', v: selected.firmName }] : []),
                { k: 'Years in Practice', v: selected.yearsInPractice },
                { k: 'Practice Area', v: selected.practiceArea },
                ...(selected.supervisingAttorney
                  ? [{ k: 'Supervising Attorney', v: selected.supervisingAttorney }]
                  : []),
              ]}
            />
          </DetailSection>

          <DetailSection
            title="Bar Admissions"
            aside={
              selected.barAdmissions.length > 0 ? (
                <span className="cell-sub" style={{ marginTop: 0 }}>
                  {selected.barAdmissions.length} {selected.barAdmissions.length > 1 ? 'states' : 'state'}
                </span>
              ) : undefined
            }
            flush
          >
            {selected.barAdmissions.length > 0 ? (
              selected.barAdmissions.map((b, i) => (
                <ListItem
                  key={i}
                  title={b.state || '—'}
                  sub={`State Bar #${b.barNumber || '—'}`}
                  right={<Badge label={b.licenseStatus || 'Active'} />}
                />
              ))
            ) : selected.barNumber ? (
              <ListItem
                title={selected.state}
                sub={`State Bar #${selected.barNumber}`}
                right={<Badge label="Active" />}
              />
            ) : (
              <ListEmpty text="No bar admission on file." />
            )}
            <div style={{ padding: '12px 14px', borderTop: '1px solid var(--divider)' }}>
              <span className="detail-cell k" style={{ display: 'block', background: 'transparent', padding: 0, marginBottom: 6 }}>
                Federal Court Admissions
              </span>
              <ChipList items={selected.federalCourts} empty="None listed" />
              {selected.primaryCourt && (
                <div className="cell-sub" style={{ marginTop: 8 }}>
                  Court admissions note: {selected.primaryCourt}
                </div>
              )}
            </div>
          </DetailSection>

          <DetailSection title="Practice Location" flush>
            <DetailGrid
              cells={[
                { k: 'State', v: selected.state },
                { k: 'City / County', v: selected.city },
              ]}
            />
            <div style={{ padding: '0 14px 12px' }}>
              <div className="detail-cell">
                <span className="k">Office Address</span>
                <span className="v">{selected.officeAddress || '—'}</span>
              </div>
            </div>
          </DetailSection>

          <DetailSection title="Purpose on ADVOK">
            <div style={{ padding: '8px 0' }}>
              <ChipList items={selected.purposes} empty="Not specified" />
            </div>
          </DetailSection>

          <DetailSection title="Availability">
            <InfoRow
              k="Working Days"
              v={
                <span className="row" style={{ gap: 5, flexWrap: 'wrap' }}>
                  {WEEKDAYS.map((d) => (
                    <span
                      key={d}
                      className={`chip${selected.workingDays.includes(d) ? ' active' : ''}`}
                      style={{ height: 24, padding: '0 9px', fontSize: 10.5 }}
                    >
                      {d}
                    </span>
                  ))}
                </span>
              }
            />
            <InfoRow k="Office Hours" v={selected.availableTime} />
          </DetailSection>
        </Drawer>
      )}
    </div>
  );
}
