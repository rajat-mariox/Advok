import { useCallback, useEffect, useMemo, useState } from 'react';
import { IconCheck, IconX } from '../components/Icon';
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
  ListItem,
  ListEmpty,
  PageHeader,
} from '../components/ui';
import { authFetch } from '../utils/auth';
import { deleteBackendUser } from '../utils/backend';
import { useRealtime } from '../utils/realtime';

type RegRole = 'advocate' | 'law_student' | 'law_firm';
type RegStatus = 'onboarding_required' | 'pending_approval' | 'approved' | 'rejected';

interface Registration {
  id: string;
  role: RegRole;
  status: RegStatus;
  phone?: string;
  countryCode?: string;
  country?: string;
  createdAt: string;
  onboardedAt?: string;
  reviewedAt?: string;
  rejectionReason?: string;
  profile?: any;
}

const ROLE_TABS: { key: RegRole; label: string }[] = [
  { key: 'advocate', label: 'Attorneys' },
  { key: 'law_student', label: 'Law Students' },
  { key: 'law_firm', label: 'Law Firms' },
];

const STATUS_FILTERS = ['Pending', 'Approved', 'Rejected', 'All'];

const STATUS_LABEL: Record<RegStatus, string> = {
  onboarding_required: 'Draft',
  pending_approval: 'Pending Approval',
  approved: 'Approved',
  rejected: 'Rejected',
};

function displayName(r: Registration): string {
  if (r.role === 'advocate') return r.profile?.professional?.fullName ?? 'Attorney';
  if (r.role === 'law_student') return r.profile?.fullName ?? 'Law Student';
  return r.profile?.firmName ?? 'Law Firm';
}

function attorneyType(p: any): string {
  return p?.firmRole || (p?.advocateType === 'senior' ? 'Senior Attorney' : 'Associate Attorney');
}

function summary(r: Registration): string {
  if (r.role === 'advocate') {
    return `${attorneyType(r.profile)} · ${r.profile?.professional?.practiceArea ?? '—'}`;
  }
  if (r.role === 'law_student') return `${r.profile?.college ?? '—'} · ${r.profile?.course ?? '—'}`;
  return `${r.profile?.city ?? '—'} · ${r.profile?.lawyers?.length ?? 0} attorneys listed`;
}

function formatDate(iso?: string): string {
  if (!iso) return '—';
  return new Date(iso).toLocaleString(undefined, {
    day: 'numeric',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

export default function ApprovalsPage() {
  const [registrations, setRegistrations] = useState<Registration[]>([]);
  const [roleTab, setRoleTab] = useState<RegRole>('advocate');
  const [statusFilter, setStatusFilter] = useState('Pending');
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [rejectReason, setRejectReason] = useState('');
  const [rejecting, setRejecting] = useState(false);
  const [loadError, setLoadError] = useState('');
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoadError('');
    try {
      const res = await authFetch('/admin/registrations');
      if (!res.ok) throw new Error();
      const data = await res.json();
      setRegistrations(data.registrations ?? []);
    } catch {
      setLoadError('Could not load registrations. Make sure the backend is running on port 4000.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);
  useRealtime(['registrations', 'users'], () => {
    void load();
  });

  const pendingCount = (role: RegRole) =>
    registrations.filter((r) => r.role === role && r.status === 'pending_approval').length;

  const list = useMemo(() => {
    return registrations.filter((r) => {
      if (r.role !== roleTab) return false;
      if (statusFilter === 'All') return r.status !== 'onboarding_required';
      if (statusFilter === 'Pending') return r.status === 'pending_approval';
      return STATUS_LABEL[r.status] === statusFilter;
    });
  }, [registrations, roleTab, statusFilter]);

  const selected = registrations.find((r) => r.id === selectedId) ?? null;

  const remove = async (id: string) => {
    if (!window.confirm('Permanently delete this registration and its account? This cannot be undone.')) return;
    const ok = await deleteBackendUser(id);
    if (ok) {
      setSelectedId(null);
      await load();
    }
  };

  const act = async (id: string, action: 'approve' | 'reject' | 'reopen', reason?: string) => {
    const res = await authFetch(`/admin/registrations/${id}/${action}`, {
      method: 'POST',
      body: JSON.stringify(reason ? { reason } : {}),
    });
    if (res.ok) {
      setRejecting(false);
      setRejectReason('');
      await load();
    }
  };

  return (
    <div>
      <PageHeader
        eyebrow="System"
        title="Approvals"
        subtitle={`${registrations.filter((r) => r.status === 'pending_approval').length} registrations awaiting review`}
      />

      <div className="row" style={{ gap: 8, marginBottom: 14, flexWrap: 'wrap' }}>
        {ROLE_TABS.map((t) => (
          <button
            key={t.key}
            className={`chip${roleTab === t.key ? ' active' : ''}`}
            onClick={() => setRoleTab(t.key)}
          >
            {t.label}
            {pendingCount(t.key) > 0 && (
              <span style={{ marginLeft: 6, fontWeight: 800 }}>{pendingCount(t.key)}</span>
            )}
          </button>
        ))}
      </div>

      <div style={{ marginBottom: 16 }}>
        <FilterChips options={STATUS_FILTERS} active={statusFilter} onChange={setStatusFilter} />
      </div>

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

      <div className="table-card">
        <table className="data">
          <thead>
            <tr>
              <th>Applicant</th>
              <th>Phone</th>
              <th>Details</th>
              <th>Submitted</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {list.map((r) => (
              <tr key={r.id} className="clickable" onClick={() => { setSelectedId(r.id); setRejecting(false); }}>
                <td>
                  <div className="row" style={{ gap: 10 }}>
                    <Avatar name={displayName(r)} photo={r.profile?.photo} size={34} square />
                    <div className="cell-strong">{displayName(r)}</div>
                  </div>
                </td>
                <td>{r.countryCode ?? ''} {r.phone ?? '—'}</td>
                <td className="cell-sub">{summary(r)}</td>
                <td>{formatDate(r.onboardedAt)}</td>
                <td>
                  <Badge label={STATUS_LABEL[r.status]} />
                </td>
              </tr>
            ))}
            {list.length === 0 && (
              <tr>
                <td colSpan={5} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  {loading ? 'Loading registrations…' : 'No registrations match this filter.'}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {selected && (
        <Drawer
          wide
          title={`${ROLE_TABS.find((t) => t.key === selected.role)?.label.replace(/s$/, '')} Registration`}
          onClose={() => setSelectedId(null)}
          footer={
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {selected.status === 'pending_approval' ? (
                rejecting ? (
                  <div>
                    <label className="field-label">Rejection Reason</label>
                    <input
                      className="input"
                      autoFocus
                      placeholder="e.g. Bar license number could not be verified"
                      value={rejectReason}
                      onChange={(e) => setRejectReason(e.target.value)}
                      style={{ marginBottom: 10 }}
                    />
                    <div className="row" style={{ gap: 10 }}>
                      <button
                        className="btn-danger"
                        style={{ flex: 1, height: 44, borderRadius: 14, fontSize: 13.5 }}
                        disabled={!rejectReason.trim()}
                        onClick={() => act(selected.id, 'reject', rejectReason.trim())}
                      >
                        Confirm Reject
                      </button>
                      <button className="btn-secondary" style={{ flex: 1 }} onClick={() => setRejecting(false)}>
                        Cancel
                      </button>
                    </div>
                  </div>
                ) : (
                  <div className="row" style={{ gap: 10 }}>
                    <button className="btn-primary" style={{ flex: 1 }} onClick={() => act(selected.id, 'approve')}>
                      <IconCheck /> Approve
                    </button>
                    <button
                      className="btn-danger"
                      style={{ flex: 1, height: 44, borderRadius: 14, fontSize: 13.5, gap: 8 }}
                      onClick={() => setRejecting(true)}
                    >
                      <IconX /> Reject
                    </button>
                  </div>
                )
              ) : (
                <button className="btn-secondary" style={{ width: '100%' }} onClick={() => act(selected.id, 'reopen')}>
                  Move Back to Review
                </button>
              )}
              <button
                className="btn-danger"
                style={{ width: '100%', height: 40, borderRadius: 14 }}
                onClick={() => remove(selected.id)}
              >
                Delete Registration
              </button>
            </div>
          }
        >
          <DrawerHero
            name={displayName(selected)}
            photo={selected.profile?.photo}
            square
            badge={STATUS_LABEL[selected.status]}
            subtitle={summary(selected)}
          />

          {selected.status === 'rejected' && (
            <div className="note-box">
              <span className="k">Rejection Reason</span>
              {selected.rejectionReason || 'No reason recorded.'}
            </div>
          )}

          <DetailSection title="Account" flush>
            <DetailGrid
              cells={[
                { k: 'Login Phone', v: `${selected.countryCode ?? ''} ${selected.phone ?? '—'}`.trim() },
                { k: 'Country', v: selected.country ?? '—' },
                { k: 'Registered', v: formatDate(selected.createdAt) },
                { k: 'Submitted', v: formatDate(selected.onboardedAt) },
                ...(selected.reviewedAt ? [{ k: 'Reviewed', v: formatDate(selected.reviewedAt) }] : []),
              ]}
            />
          </DetailSection>

          {selected.role === 'advocate' && selected.profile && (() => {
            const p = selected.profile;
            const pro = p.professional ?? {};
            const bars: any[] = pro.barAdmissions ?? [];
            const federal: string[] = pro.federalCourtAdmissions ?? [];
            return (
              <>
                <DetailSection title="Professional Details" flush>
                  <DetailGrid
                    cells={[
                      { k: 'Full Name', v: pro.fullName ?? '—' },
                      { k: 'Firm Role', v: attorneyType(p) },
                      { k: 'Practice Area', v: pro.practiceArea ?? '—' },
                      { k: 'Email', v: pro.email ?? '—' },
                      ...(p.yearsInPractice ? [{ k: 'Years in Practice', v: p.yearsInPractice }] : []),
                      ...(p.advocateType === 'junior' && !p.firmRole
                        ? [{ k: 'Supervising Attorney', v: pro.seniorAdvocateName || '—' }]
                        : []),
                    ]}
                  />
                </DetailSection>

                <DetailSection
                  title="Bar Admissions"
                  aside={
                    bars.length > 0 ? (
                      <span className="cell-sub" style={{ marginTop: 0 }}>
                        {bars.length} {bars.length > 1 ? 'states' : 'state'}
                      </span>
                    ) : undefined
                  }
                  flush
                >
                  {bars.length > 0 ? (
                    <>
                      {bars.map((a: any, i: number) => (
                        <ListItem
                          key={i}
                          title={a.state || '—'}
                          sub={`Bar #${a.barNumber || '—'}`}
                          right={<Badge label={a.licenseStatus || 'Unknown'} />}
                        />
                      ))}
                      <div style={{ padding: '12px 14px', borderTop: '1px solid var(--divider)' }}>
                        <span className="detail-cell k" style={{ display: 'block', background: 'transparent', padding: 0, marginBottom: 6 }}>
                          Federal Court Admissions
                        </span>
                        <ChipList items={federal} empty="None listed" />
                      </div>
                    </>
                  ) : (
                    <DetailGrid
                      cells={[
                        {
                          k: 'State Bar Number',
                          v: pro.licenseNumber ?? pro.barRegistrationNumber ?? '—',
                        },
                        { k: 'Primary Court', v: pro.primaryCourt ?? '—' },
                      ]}
                    />
                  )}
                </DetailSection>

                <DetailSection title="Practice Location" flush>
                  <DetailGrid
                    cells={[
                      { k: 'State', v: p.location?.state ?? '—' },
                      { k: 'City / County', v: p.location?.district ?? '—' },
                    ]}
                  />
                  <div style={{ padding: '0 14px 12px' }}>
                    <div className="detail-cell">
                      <span className="k">Office Address</span>
                      <span className="v">{p.location?.officeAddress || '—'}</span>
                    </div>
                  </div>
                </DetailSection>

                <DetailSection title="Purpose on Advok">
                  <div style={{ padding: '8px 0' }}>
                    <ChipList items={p.purposes ?? []} empty="Not specified" />
                  </div>
                </DetailSection>

                <DetailSection title="Availability">
                  <InfoRow k="Working Days" v={<ChipList items={p.schedule?.workingDays ?? []} />} />
                  <InfoRow
                    k="Hours"
                    v={p.schedule?.startTime ? `${p.schedule.startTime} – ${p.schedule.endTime}` : '—'}
                  />
                </DetailSection>
              </>
            );
          })()}

          {selected.role === 'law_student' && selected.profile && (
            <DetailSection title="Student Details" flush>
              <DetailGrid
                cells={[
                  { k: 'Full Name', v: selected.profile.fullName ?? '—' },
                  { k: 'Law School', v: selected.profile.college ?? '—' },
                  { k: 'Degree Program', v: selected.profile.course ?? '—' },
                  { k: 'Year', v: selected.profile.academicYear ?? '—' },
                  { k: 'Student ID Card', v: selected.profile.idCardFileName || 'Not uploaded' },
                ]}
              />
            </DetailSection>
          )}

          {selected.role === 'law_firm' && selected.profile && (() => {
            const p = selected.profile;
            const lawyers: any[] = p.lawyers ?? [];
            return (
              <>
                <DetailSection title="Firm Details" flush>
                  <DetailGrid
                    cells={[
                      { k: 'Firm Name', v: p.firmName ?? '—' },
                      { k: 'Founded', v: p.foundedYear ?? '—' },
                      { k: 'Contact Person', v: p.contactPerson ?? '—' },
                      { k: 'Official Email', v: p.officialEmail ?? '—' },
                      { k: 'Main Phone', v: p.mainPhone ?? '—' },
                      { k: 'Reception', v: p.receptionNumber || '—' },
                      { k: 'Total Attorneys', v: p.totalLawyers || lawyers.length || '—' },
                      { k: 'Logo', v: p.logoFileName || 'Not uploaded' },
                    ]}
                  />
                  <div style={{ padding: '0 14px 12px' }}>
                    <div className="detail-cell">
                      <span className="k">Address</span>
                      <span className="v">
                        {[p.addressLine1, p.addressLine2, p.city, p.state, p.zip].filter(Boolean).join(', ') || '—'}
                      </span>
                    </div>
                  </div>
                </DetailSection>

                <DetailSection
                  title="Legal Team"
                  aside={<span className="cell-sub" style={{ marginTop: 0 }}>{lawyers.length} listed</span>}
                  flush
                >
                  {lawyers.length === 0 ? (
                    <ListEmpty text="No attorneys added." />
                  ) : (
                    lawyers.map((l: any, i: number) => (
                      <div key={i} className="list-item" style={{ alignItems: 'stretch', flexDirection: 'column', gap: 8 }}>
                        <div className="row" style={{ justifyContent: 'space-between', gap: 10 }}>
                          <div className="list-item-main">
                            <div className="list-item-title">{l.fullName || `Attorney ${i + 1}`}</div>
                            <div className="list-item-sub">
                              {[l.designation || 'Associate', l.yearsExperience ? `${l.yearsExperience} yrs experience` : '']
                                .filter(Boolean)
                                .join(' · ')}
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
                        {(l.expertise ?? []).length > 0 && <ChipList items={l.expertise} />}
                      </div>
                    ))
                  )}
                </DetailSection>
              </>
            );
          })()}
        </Drawer>
      )}
    </div>
  );
}
