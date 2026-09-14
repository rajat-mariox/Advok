import { useEffect, useMemo, useState } from 'react';
import { IconCheck, IconFile, IconSearch, IconX } from '../components/Icon';
import {
  Avatar,
  Badge,
  ChipList,
  DetailGrid,
  DetailSection,
  Drawer,
  DrawerHero,
  FilterChips,
  ListEmpty,
  PageHeader,
  RowActions,
} from '../components/ui';
import type { AdminLawFirm, FirmVerificationStatus } from '../types';
import {
  deleteBackendUser,
  setFirmFee,
  fetchBackendUsers,
  hasSubmittedProfile,
  reviewRegistration,
  suspendBackendUser,
  toAdminLawFirm,
  unsuspendBackendUser,
} from '../utils/backend';
import { money } from '../utils/seed';
import { useRealtime } from '../utils/realtime';

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
  useRealtime(['users'], () => {
    void load();
  });

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

  // Firm's own consultation fee, edited in the drawer.

  const [feeDraft, setFeeDraft] = useState('');

  const [feeNote, setFeeNote] = useState('');

  useEffect(() => {

    setFeeDraft(selected?.consultationFee != null ? String(selected.consultationFee) : '');

    setFeeNote('');

    // eslint-disable-next-line react-hooks/exhaustive-deps

  }, [selectedId]);


  const saveFee = async () => {

    if (!selected) return;

    const raw = feeDraft.trim();

    const fee = raw === '' ? null : Number(raw);

    if (fee !== null && (!Number.isFinite(fee) || fee < 0)) {

      setFeeNote('Enter a valid amount, or leave empty for the platform rate.');

      return;

    }

    const ok = await setFirmFee(selected.id, fee);

    if (ok) {

      setFirms((prev) => prev.map((f) => (f.id === selected.id ? { ...f, consultationFee: fee ?? undefined } : f)));

      setFeeNote(fee === null ? 'Cleared — platform law-firm rate applies.' : `Saved — clients see $${fee} for this firm and its attorneys.`);

    } else {

      setFeeNote('Could not save the fee.');

    }

  };

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
              <th>Attorneys</th>
              <th>Active Cases</th>
              <th>Clients</th>
              <th>Revenue (Mo.)</th>
              <th>Approval</th>
              <th style={{ textAlign: 'center' }}>Actions</th>
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
                <td style={{ textAlign: 'center' }}>
                  <RowActions
                    suspended={f.verification === 'Suspended'}
                    onView={() => setSelectedId(f.id)}
                    onSuspend={() => suspendUser(f.id)}
                    onUnsuspend={() => unsuspendUser(f.id)}
                    onDelete={() => deleteUser(f.id)}
                  />
                </td>
              </tr>
            ))}
            {list.length === 0 && (
              <tr>
                <td colSpan={10} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  {loading ? 'Loading firms…' : loadError || 'No firms match this filter.'}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {selected && (
        <Drawer
          wide
          title="Firm Details"
          onClose={() => setSelectedId(null)}
          footer={
            selected.verification === 'Pending Approval' ? (
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
                onClick={() => setVerification(selected.id, 'Pending Approval')}
              >
                Move Back to Review
              </button>
            ) : undefined
          }
        >
          <DrawerHero
            name={selected.firmName}
            photo={selected.photo}
            square
            badge={selected.verification}
            subtitle={`${selected.contactPersonName} · Managing Partner · ${selected.city}, ${selected.state}`}
          />

          {selected.verification === 'Pending Approval' && (
            <div className="note-box">
              <span className="k">While pending</span>
              The firm can use the basic dashboard, lawyer management and case tracking. Approval
              unlocks client requests, premium features and the Verified badge. Check each listed
              attorney's bar license against the state bar before approving.
            </div>
          )}

          <DetailSection title="Firm Profile" flush>
            <DetailGrid
              cells={[
                { k: 'Managing Partner', v: selected.contactPersonName },
                { k: 'Founded', v: selected.foundedYear },
                { k: 'Attorneys at Firm', v: selected.totalLawyers },
                {
                  k: 'Firm Logo',
                  v: selected.logoFileName ? (
                    <span className="row" style={{ gap: 6 }}>
                      <IconFile size={14} /> {selected.logoFileName}
                    </span>
                  ) : (
                    'Not uploaded'
                  ),
                },
                { k: 'Submitted', v: selected.submitted },
              ]}
            />
          </DetailSection>

          <DetailSection title="Consultation Fee">
            <div style={{ padding: '8px 0', display: 'grid', gap: 8 }}>
              <div className="cell-sub" style={{ marginTop: 0 }}>
                Charged when a client books this firm or any of its attorneys. Leave empty to use the
                platform law-firm rate from Settings.
              </div>
              <div className="row" style={{ gap: 8 }}>
                <span style={{ fontWeight: 800, fontSize: 15 }}>$</span>
                <input
                  className="input"
                  type="number"
                  min={0}
                  placeholder="Platform rate"
                  value={feeDraft}
                  onChange={(e) => setFeeDraft(e.target.value)}
                  style={{ width: 140, height: 38, fontWeight: 700 }}
                />
                <span className="cell-sub" style={{ marginTop: 0 }}>/ voice consultation</span>
                <button className="btn-primary" style={{ height: 38, marginLeft: 'auto' }} onClick={saveFee}>
                  Save Fee
                </button>
              </div>
              {feeNote && <div className="cell-sub" style={{ marginTop: 0, fontWeight: 600 }}>{feeNote}</div>}
            </div>
          </DetailSection>

          <DetailSection title="Contact" flush>
            <DetailGrid
              cells={[
                { k: 'Login Phone', v: selected.phone },
                { k: 'Official Email', v: selected.officialEmail },
                { k: 'Main Phone', v: selected.mainPhone },
                { k: 'Reception', v: selected.receptionNumber ?? '—' },
              ]}
            />
          </DetailSection>

          <DetailSection title="Office Address" flush>
            <DetailGrid
              cells={[
                { k: 'City', v: selected.city },
                { k: 'State · ZIP', v: `${selected.state} · ${selected.zipCode}` },
              ]}
            />
            <div style={{ padding: '0 14px 12px' }}>
              <div className="detail-cell">
                <span className="k">Street Address</span>
                <span className="v">
                  {selected.addressLine1}
                  {selected.addressLine2 ? `, ${selected.addressLine2}` : ''}
                </span>
              </div>
            </div>
          </DetailSection>

          <DetailSection
            title="Legal Team"
            aside={<span className="cell-sub" style={{ marginTop: 0 }}>{selected.team.length} listed</span>}
            flush
          >
            {selected.team.length === 0 ? (
              <ListEmpty text="No attorneys added." />
            ) : (
              selected.team.map((l, i) => (
                <div key={i} className="list-item" style={{ alignItems: 'stretch', flexDirection: 'column', gap: 8 }}>
                  <div className="row" style={{ justifyContent: 'space-between', gap: 10 }}>
                    <div className="row" style={{ gap: 10, minWidth: 0 }}>
                      <Avatar name={l.fullName} size={32} square />
                      <div className="list-item-main">
                        <div className="list-item-title">{l.fullName}</div>
                        <div className="list-item-sub">
                          {[l.designation, l.yearsExperience ? `${l.yearsExperience} yrs experience` : '']
                            .filter(Boolean)
                            .join(' · ') || '—'}
                        </div>
                      </div>
                    </div>
                    <Badge label={l.licenseStatus || 'Active'} />
                  </div>
                  <DetailGrid
                    cells={[
                      { k: 'State Bar', v: [l.barState, l.barLicense ? `#${l.barLicense}` : ''].filter(Boolean).join(' ') || '—' },
                      { k: 'License Status', v: l.licenseStatus || 'Active' },
                      { k: 'Email', v: l.email || '—' },
                      { k: 'Phone', v: l.phone || '—' },
                    ]}
                  />
                  {l.expertise.length > 0 && <ChipList items={l.expertise} />}
                </div>
              ))
            )}
          </DetailSection>

          <DetailSection title="Activity" flush>
            <DetailGrid
              cells={[
                { k: 'Active Cases', v: selected.activeCases },
                { k: 'Clients', v: selected.clients },
                { k: 'Revenue · This Month', v: selected.revenueMonth > 0 ? money(selected.revenueMonth) : '—' },
              ]}
            />
          </DetailSection>
        </Drawer>
      )}
    </div>
  );
}
