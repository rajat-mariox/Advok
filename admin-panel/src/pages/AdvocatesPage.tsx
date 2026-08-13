import { useEffect, useMemo, useState } from 'react';
import { IconCheck, IconSearch, IconX } from '../components/Icon';
import {
  AccountActions,
  Avatar,
  Badge,
  Drawer,
  FilterChips,
  InfoRow,
  PageHeader,
} from '../components/ui';
import type { AdminAdvocate, VerificationStatus } from '../types';
import {
  deleteBackendUser,
  fetchBackendUsers,
  hasSubmittedProfile,
  reviewRegistration,
  suspendBackendUser,
  toAdminAdvocate,
  unsuspendBackendUser,
} from '../utils/backend';

const FILTERS = ['All', 'Junior', 'Senior', 'Pending Review', 'Verified', 'Rejected', 'Suspended'];

export default function AdvocatesPage() {
  const [advocates, setAdvocates] = useState<AdminAdvocate[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState('');
  const [filter, setFilter] = useState('All');
  const [query, setQuery] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const load = () =>
    fetchBackendUsers('advocate')
      .then((users) => setAdvocates(users.filter(hasSubmittedProfile).map(toAdminAdvocate)))
      .catch(() =>
        setLoadError('Could not load advocates. Make sure the backend is running on port 4000.'),
      );

  useEffect(() => {
    load().finally(() => setLoading(false));
  }, []);

  const list = useMemo(() => {
    return advocates.filter((a) => {
      const matchesFilter =
        filter === 'All' ||
        (filter === 'Junior' && a.type === 'Junior Advocate') ||
        (filter === 'Senior' && a.type === 'Senior Advocate') ||
        a.verification === filter;
      const q = query.trim().toLowerCase();
      const matchesQuery =
        !q ||
        a.name.toLowerCase().includes(q) ||
        a.specialty.toLowerCase().includes(q) ||
        a.barRegNo.toLowerCase().includes(q) ||
        a.phone.toLowerCase().includes(q);
      return matchesFilter && matchesQuery;
    });
  }, [advocates, filter, query]);

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
    const ok = await suspendBackendUser(id, reason.trim() || undefined);
    if (ok) {
      setAdvocates((prev) =>
        prev.map((a) => (a.id === id ? { ...a, verification: 'Suspended' } : a)),
      );
    }
  };

  // The backend restores the pre-suspension status, so reload to pick it up.
  const unsuspendUser = async (id: string) => {
    const ok = await unsuspendBackendUser(id);
    if (ok) await load();
  };

  const deleteUser = async (id: string) => {
    if (!window.confirm('Permanently delete this advocate account? This cannot be undone.')) return;
    const ok = await deleteBackendUser(id);
    if (ok) {
      setAdvocates((prev) => prev.filter((a) => a.id !== id));
      setSelectedId(null);
    }
  };

  return (
    <div>
      <PageHeader
        eyebrow="Users"
        title="Advocates"
        subtitle={`${advocates.length} registered · ${advocates.filter((a) => a.verification === 'Pending Review').length} awaiting verification`}
      />

      <div className="row" style={{ justifyContent: 'space-between', gap: 14, marginBottom: 16, flexWrap: 'wrap' }}>
        <FilterChips options={FILTERS} active={filter} onChange={setFilter} />
        <div className="search-wrap" style={{ width: 280 }}>
          <IconSearch />
          <input
            className="input"
            placeholder="Search name, specialty, bar no..."
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
              <th>Advocate</th>
              <th>Phone</th>
              <th>Type</th>
              <th>Bar License / Reg. No.</th>
              <th>Court · Location</th>
              <th>Exp.</th>
              <th>Cases</th>
              <th>Fee</th>
              <th>Verification</th>
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
                      <div className="cell-sub">{a.specialty}</div>
                    </div>
                  </div>
                </td>
                <td style={{ whiteSpace: 'nowrap' }}>{a.phone}</td>
                <td>{a.type}</td>
                <td style={{ fontFamily: 'inherit', fontWeight: 600 }}>{a.barRegNo}</td>
                <td>
                  <div>{a.court}</div>
                  <div className="cell-sub">
                    {a.city}, {a.state}
                  </div>
                </td>
                <td>{a.yearsInPractice ?? (a.experienceYears > 0 ? `${a.experienceYears}+ yrs` : '—')}</td>
                <td>{a.cases}</td>
                <td>
                  {a.pricePerHr > 0 ? (
                    <>
                      <span className="cell-strong">${a.pricePerHr}</span>
                      <span style={{ fontSize: 10, color: 'var(--text-grey)' }}>/hr</span>
                    </>
                  ) : (
                    '—'
                  )}
                </td>
                <td>
                  <Badge label={a.verification} />
                </td>
              </tr>
            ))}
            {list.length === 0 && (
              <tr>
                <td colSpan={9} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  {loading
                    ? 'Loading advocates…'
                    : loadError || 'No advocates match this filter.'}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {selected && (
        <Drawer
          title="Advocate Details"
          onClose={() => setSelectedId(null)}
          footer={
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {selected.verification === 'Pending Review' ? (
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
                    style={{ flex: 1, height: 44, borderRadius: 14 }}
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
              ) : null}
              <AccountActions
                suspended={selected.verification === 'Suspended'}
                onSuspend={() => suspendUser(selected.id)}
                onUnsuspend={() => unsuspendUser(selected.id)}
                onDelete={() => deleteUser(selected.id)}
              />
            </div>
          }
        >
          <div className="row" style={{ gap: 14, marginBottom: 18 }}>
            <Avatar name={selected.name} photo={selected.photo} size={56} square />
            <div>
              <div className="row" style={{ gap: 8 }}>
                <span style={{ fontSize: 17, fontWeight: 800, letterSpacing: -0.3 }}>{selected.name}</span>
                <Badge label={selected.verification} />
              </div>
              <div className="cell-sub" style={{ fontSize: 12.5 }}>
                {selected.type} · {selected.specialty}
              </div>
            </div>
          </div>

          <div className="eyebrow" style={{ marginBottom: 4 }}>Professional Details</div>
          <InfoRow k="Login Phone" v={selected.phone} />
          <InfoRow k="Email Address" v={selected.email} />
          <InfoRow
            k={
              selected.country === 'United States'
                ? 'State Bar License'
                : 'Bar Registration Number'
            }
            v={selected.barRegNo}
          />
          <InfoRow k="Primary Practice Court" v={selected.court} />
          <InfoRow k="Practice Area" v={selected.specialty} />
          {selected.yearsInPractice && (
            <InfoRow k="Years in Practice" v={selected.yearsInPractice} />
          )}
          {selected.type === 'Junior Advocate' && (
            <InfoRow k="Senior Advocate" v={selected.seniorAdvocateName ?? '—'} />
          )}

          <div className="eyebrow" style={{ margin: '18px 0 4px' }}>Practice Location</div>
          <InfoRow k="State" v={selected.state} />
          <InfoRow k="District / City" v={selected.city} />

          <div className="eyebrow" style={{ margin: '18px 0 4px' }}>Schedule</div>
          <InfoRow
            k="Working Days"
            v={
              <span className="row" style={{ gap: 5, justifyContent: 'flex-end', flexWrap: 'wrap' }}>
                {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) => (
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
          <InfoRow k="Available Time" v={selected.availableTime} />

          <div className="eyebrow" style={{ margin: '18px 0 4px' }}>Activity</div>
          <InfoRow k="Total Cases" v={selected.cases} />
          <InfoRow
            k="Experience"
            v={
              selected.yearsInPractice ??
              (selected.experienceYears > 0 ? `${selected.experienceYears}+ years` : '—')
            }
          />
          <InfoRow k="Rating" v={selected.rating ? `★ ${selected.rating}` : 'Not rated yet'} />
          <InfoRow
            k="Consultation Fee"
            v={selected.pricePerHr > 0 ? `$${selected.pricePerHr}/hr` : 'Not set yet'}
          />
          <InfoRow k="Joined" v={selected.joined} />
        </Drawer>
      )}
    </div>
  );
}
