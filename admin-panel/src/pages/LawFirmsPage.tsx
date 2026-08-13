import { useEffect, useMemo, useState } from 'react';
import { IconCheck, IconFile, IconSearch, IconX } from '../components/Icon';
import {
  AccountActions,
  Avatar,
  Badge,
  Drawer,
  FilterChips,
  InfoRow,
  PageHeader,
} from '../components/ui';
import type { AdminLawFirm, FirmVerificationStatus } from '../types';
import {
  deleteBackendUser,
  fetchBackendUsers,
  hasSubmittedProfile,
  reviewRegistration,
  suspendBackendUser,
  toAdminLawFirm,
  unsuspendBackendUser,
} from '../utils/backend';
import { money } from '../utils/seed';

const FILTERS = ['All', 'Pending Approval', 'Verified', 'Rejected', 'Suspended'];

export default function LawFirmsPage() {
  const [firms, setFirms] = useState<AdminLawFirm[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState('');
  const [filter, setFilter] = useState('All');
  const [query, setQuery] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const load = () =>
    fetchBackendUsers('law_firm')
      .then((users) => setFirms(users.filter(hasSubmittedProfile).map(toAdminLawFirm)))
      .catch(() =>
        setLoadError('Could not load firms. Make sure the backend is running on port 4000.'),
      );

  useEffect(() => {
    load().finally(() => setLoading(false));
  }, []);

  const list = useMemo(() => {
    return firms.filter((f) => {
      const matchesFilter = filter === 'All' || f.verification === filter;
      const q = query.trim().toLowerCase();
      const matchesQuery =
        !q ||
        f.firmName.toLowerCase().includes(q) ||
        f.contactPersonName.toLowerCase().includes(q) ||
        f.city.toLowerCase().includes(q) ||
        f.phone.toLowerCase().includes(q);
      return matchesFilter && matchesQuery;
    });
  }, [firms, filter, query]);

  const selected = firms.find((f) => f.id === selectedId) ?? null;

  const setVerification = async (id: string, verification: FirmVerificationStatus) => {
    const ok = await reviewRegistration(id, verification);
    if (ok) {
      setFirms((prev) => prev.map((f) => (f.id === id ? { ...f, verification } : f)));
    }
  };

  const suspendUser = async (id: string) => {
    const reason = window.prompt('Reason for suspension (optional):');
    if (reason === null) return;
    const ok = await suspendBackendUser(id, reason.trim() || undefined);
    if (ok) {
      setFirms((prev) => prev.map((f) => (f.id === id ? { ...f, verification: 'Suspended' } : f)));
    }
  };

  // The backend restores the pre-suspension status, so reload to pick it up.
  const unsuspendUser = async (id: string) => {
    const ok = await unsuspendBackendUser(id);
    if (ok) await load();
  };

  const deleteUser = async (id: string) => {
    if (!window.confirm('Permanently delete this firm account? This cannot be undone.')) return;
    const ok = await deleteBackendUser(id);
    if (ok) {
      setFirms((prev) => prev.filter((f) => f.id !== id));
      setSelectedId(null);
    }
  };

  return (
    <div>
      <PageHeader
        eyebrow="Users"
        title="Law Firms"
        subtitle={`${firms.length} registered · ${firms.filter((f) => f.verification === 'Pending Approval').length} awaiting approval`}
      />

      <div className="row" style={{ justifyContent: 'space-between', gap: 14, marginBottom: 16, flexWrap: 'wrap' }}>
        <FilterChips options={FILTERS} active={filter} onChange={setFilter} />
        <div className="search-wrap" style={{ width: 280 }}>
          <IconSearch />
          <input
            className="input"
            placeholder="Search firm, partner, city..."
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
              <th>Firm</th>
              <th>Phone</th>
              <th>Location</th>
              <th>Founded</th>
              <th>Lawyers</th>
              <th>Active Cases</th>
              <th>Clients</th>
              <th>Revenue (Mo.)</th>
              <th>Approval</th>
            </tr>
          </thead>
          <tbody>
            {list.map((f) => (
              <tr key={f.id} className="clickable" onClick={() => setSelectedId(f.id)}>
                <td>
                  <div className="row" style={{ gap: 10 }}>
                    <Avatar name={f.firmName} photo={f.photo} size={34} square />
                    <div>
                      <div className="cell-strong">{f.firmName}</div>
                      <div className="cell-sub">{f.contactPersonName} · Managing Partner</div>
                    </div>
                  </div>
                </td>
                <td style={{ whiteSpace: 'nowrap' }}>{f.phone}</td>
                <td>
                  <div>{f.city}</div>
                  <div className="cell-sub">{f.state} {f.zipCode}</div>
                </td>
                <td>{f.foundedYear}</td>
                <td>{f.totalLawyers}</td>
                <td>{f.activeCases}</td>
                <td>{f.clients}</td>
                <td>
                  {f.revenueMonth > 0 ? <span className="cell-strong">{money(f.revenueMonth)}</span> : '—'}
                </td>
                <td>
                  <Badge label={f.verification} />
                </td>
              </tr>
            ))}
            {list.length === 0 && (
              <tr>
                <td colSpan={9} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  {loading ? 'Loading firms…' : loadError || 'No firms match this filter.'}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {selected && (
        <Drawer
          title="Firm Details"
          onClose={() => setSelectedId(null)}
          footer={
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {selected.verification === 'Pending Approval' ? (
                <div className="row" style={{ gap: 10 }}>
                  <button
                    className="btn-primary"
                    style={{ flex: 1 }}
                    onClick={() => setVerification(selected.id, 'Verified')}
                  >
                    <IconCheck /> Approve Firm
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
                  onClick={() => setVerification(selected.id, 'Pending Approval')}
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
            <Avatar name={selected.firmName} photo={selected.photo} size={56} square />
            <div>
              <div className="row" style={{ gap: 8 }}>
                <span style={{ fontSize: 17, fontWeight: 800, letterSpacing: -0.3 }}>{selected.firmName}</span>
                <Badge label={selected.verification} />
              </div>
              <div className="cell-sub" style={{ fontSize: 12.5 }}>
                Law Firm · Founded {selected.foundedYear} · Submitted {selected.submitted}
              </div>
            </div>
          </div>

          {selected.verification === 'Pending Approval' && (
            <div
              className="card-white"
              style={{ padding: '10px 14px', marginBottom: 16, fontSize: 12, color: 'var(--text-grey-555)', lineHeight: 1.5 }}
            >
              While pending, the firm can use Basic Dashboard, Lawyer Management and Case Tracking.
              Approval unlocks Client Requests, Premium Features and the Verified Badge.
            </div>
          )}

          <div className="eyebrow" style={{ marginBottom: 4 }}>Firm Profile</div>
          <InfoRow k="Managing Partner" v={selected.contactPersonName} />
          <InfoRow k="Founded Year" v={selected.foundedYear} />
          <InfoRow
            k="Firm Logo"
            v={
              selected.logoFileName ? (
                <span className="row" style={{ gap: 6, justifyContent: 'flex-end' }}>
                  <IconFile size={14} /> {selected.logoFileName}
                </span>
              ) : (
                'Not uploaded'
              )
            }
          />

          <div className="eyebrow" style={{ margin: '18px 0 4px' }}>Contact Information</div>
          <InfoRow k="Login Phone" v={selected.phone} />
          <InfoRow k="Official Email" v={selected.officialEmail} />
          <InfoRow k="Main Phone" v={selected.mainPhone} />
          <InfoRow k="Reception Number" v={selected.receptionNumber ?? '—'} />

          <div className="eyebrow" style={{ margin: '18px 0 4px' }}>Office Address</div>
          <InfoRow k="Address" v={`${selected.addressLine1}${selected.addressLine2 ? ', ' + selected.addressLine2 : ''}`} />
          <InfoRow k="City" v={selected.city} />
          <InfoRow k="State · ZIP" v={`${selected.state} · ${selected.zipCode}`} />

          <div className="eyebrow" style={{ margin: '18px 0 8px' }}>
            Legal Team · {selected.totalLawyers} lawyers at firm
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {selected.team.map((l) => (
              <div key={l.fullName} className="card-white" style={{ padding: '10px 12px' }}>
                <div className="row" style={{ gap: 10 }}>
                  <Avatar name={l.fullName} size={32} square />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div className="cell-strong">{l.fullName}</div>
                    <div className="cell-sub">
                      {l.designation}
                      {l.yearsExperience ? ` · ${l.yearsExperience} yrs` : ''}
                      {l.barLicense ? ` · ${l.barLicense}` : ''}
                    </div>
                  </div>
                </div>
                {l.expertise.length > 0 && (
                  <div className="row" style={{ gap: 5, marginTop: 8, flexWrap: 'wrap' }}>
                    {l.expertise.map((e) => (
                      <span key={e} className="chip" style={{ height: 22, padding: '0 9px', fontSize: 10.5 }}>
                        {e}
                      </span>
                    ))}
                  </div>
                )}
              </div>
            ))}
          </div>

          <div className="eyebrow" style={{ margin: '18px 0 4px' }}>Activity</div>
          <InfoRow k="Active Cases" v={selected.activeCases} />
          <InfoRow k="Clients" v={selected.clients} />
          <InfoRow k="Revenue · This Month" v={selected.revenueMonth > 0 ? money(selected.revenueMonth) : '—'} />
        </Drawer>
      )}
    </div>
  );
}
