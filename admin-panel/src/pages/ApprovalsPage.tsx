import { useCallback, useEffect, useMemo, useState } from 'react';
import { IconCheck, IconX } from '../components/Icon';
import { Avatar, Badge, Drawer, FilterChips, InfoRow, PageHeader } from '../components/ui';
import { authFetch } from '../utils/auth';
import { deleteBackendUser } from '../utils/backend';

type RegRole = 'advocate' | 'law_student' | 'law_firm';
type RegStatus = 'onboarding_required' | 'pending_approval' | 'approved' | 'rejected';

interface Registration {
  id: string;
  role: RegRole;
  status: RegStatus;
  phone?: string;
  countryCode?: string;
  createdAt: string;
  onboardedAt?: string;
  reviewedAt?: string;
  rejectionReason?: string;
  profile?: any;
}

const ROLE_TABS: { key: RegRole; label: string }[] = [
  { key: 'advocate', label: 'Advocates' },
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
  if (r.role === 'advocate') return r.profile?.professional?.fullName ?? 'Advocate';
  if (r.role === 'law_student') return r.profile?.fullName ?? 'Law Student';
  return r.profile?.firmName ?? 'Law Firm';
}

function summary(r: Registration): string {
  if (r.role === 'advocate') {
    return `${r.profile?.advocateType === 'senior' ? 'Senior' : 'Junior'} · ${r.profile?.professional?.practiceArea ?? '—'}`;
  }
  if (r.role === 'law_student') return `${r.profile?.college ?? '—'} · ${r.profile?.course ?? '—'}`;
  return `${r.profile?.city ?? '—'} · ${r.profile?.lawyers?.length ?? 0} lawyers listed`;
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
                    <Avatar name={displayName(r)} size={34} square />
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
                    placeholder="e.g. Bar registration number could not be verified"
                    value={rejectReason}
                    onChange={(e) => setRejectReason(e.target.value)}
                    style={{ marginBottom: 10 }}
                  />
                  <div className="row" style={{ gap: 10 }}>
                    <button
                      className="btn-danger"
                      style={{ flex: 1, height: 44, borderRadius: 14 }}
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
                    style={{ flex: 1, height: 44, borderRadius: 14 }}
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
          <div className="row" style={{ gap: 14, marginBottom: 18 }}>
            <Avatar name={displayName(selected)} size={56} square />
            <div>
              <div className="row" style={{ gap: 8 }}>
                <span style={{ fontSize: 17, fontWeight: 800, letterSpacing: -0.3 }}>{displayName(selected)}</span>
                <Badge label={STATUS_LABEL[selected.status]} />
              </div>
              <div className="cell-sub" style={{ fontSize: 12.5 }}>{summary(selected)}</div>
            </div>
          </div>

          <div className="eyebrow" style={{ marginBottom: 4 }}>Account</div>
          <InfoRow k="Phone" v={`${selected.countryCode ?? ''} ${selected.phone ?? '—'}`} />
          <InfoRow k="Registered" v={formatDate(selected.createdAt)} />
          <InfoRow k="Onboarding Submitted" v={formatDate(selected.onboardedAt)} />
          {selected.reviewedAt && <InfoRow k="Reviewed" v={formatDate(selected.reviewedAt)} />}
          {selected.status === 'rejected' && (
            <InfoRow k="Rejection Reason" v={selected.rejectionReason ?? '—'} />
          )}

          {selected.role === 'advocate' && selected.profile && (
            <>
              <div className="eyebrow" style={{ margin: '18px 0 4px' }}>Professional Details</div>
              <InfoRow k="Full Name" v={selected.profile.professional?.fullName ?? '—'} />
              <InfoRow k="Type" v={selected.profile.advocateType === 'senior' ? 'Senior Advocate' : 'Junior Advocate'} />
              {selected.profile.advocateType === 'junior' && (
                <InfoRow k="Senior Advocate" v={selected.profile.professional?.seniorAdvocateName || '—'} />
              )}
              <InfoRow k="Email" v={selected.profile.professional?.email ?? '—'} />
              <InfoRow k="Bar Registration No." v={selected.profile.professional?.barRegistrationNumber ?? '—'} />
              <InfoRow k="Primary Court" v={selected.profile.professional?.primaryCourt ?? '—'} />
              <InfoRow k="Practice Area" v={selected.profile.professional?.practiceArea ?? '—'} />

              <div className="eyebrow" style={{ margin: '18px 0 4px' }}>Practice Location</div>
              <InfoRow k="State" v={selected.profile.location?.state ?? '—'} />
              <InfoRow k="District / City" v={selected.profile.location?.district ?? '—'} />
              <InfoRow k="Office Address" v={selected.profile.location?.officeAddress || '—'} />

              <div className="eyebrow" style={{ margin: '18px 0 4px' }}>Purpose & Schedule</div>
              <InfoRow k="Purposes" v={(selected.profile.purposes ?? []).join(', ') || '—'} />
              <InfoRow k="Working Days" v={(selected.profile.schedule?.workingDays ?? []).join(', ') || '—'} />
              <InfoRow
                k="Available Time"
                v={
                  selected.profile.schedule?.startTime
                    ? `${selected.profile.schedule.startTime} – ${selected.profile.schedule.endTime}`
                    : '—'
                }
              />
            </>
          )}

          {selected.role === 'law_student' && selected.profile && (
            <>
              <div className="eyebrow" style={{ margin: '18px 0 4px' }}>Student Details</div>
              <InfoRow k="Full Name" v={selected.profile.fullName ?? '—'} />
              <InfoRow k="College / University" v={selected.profile.college ?? '—'} />
              <InfoRow k="Course" v={selected.profile.course ?? '—'} />
              <InfoRow k="Academic Year" v={selected.profile.academicYear ?? '—'} />
              <InfoRow k="College ID Card" v={selected.profile.idCardFileName || 'Not uploaded'} />
            </>
          )}

          {selected.role === 'law_firm' && selected.profile && (
            <>
              <div className="eyebrow" style={{ margin: '18px 0 4px' }}>Firm Details</div>
              <InfoRow k="Firm Name" v={selected.profile.firmName ?? '—'} />
              <InfoRow k="Founded" v={selected.profile.foundedYear ?? '—'} />
              <InfoRow k="Contact Person" v={selected.profile.contactPerson ?? '—'} />
              <InfoRow k="Official Email" v={selected.profile.officialEmail ?? '—'} />
              <InfoRow k="Main Phone" v={selected.profile.mainPhone ?? '—'} />
              <InfoRow
                k="Address"
                v={[selected.profile.addressLine1, selected.profile.addressLine2, selected.profile.city, selected.profile.state, selected.profile.zip]
                  .filter(Boolean)
                  .join(', ')}
              />
              <InfoRow k="Total Lawyers" v={selected.profile.totalLawyers || '—'} />

              <div className="eyebrow" style={{ margin: '18px 0 4px' }}>
                Legal Team ({selected.profile.lawyers?.length ?? 0})
              </div>
              {(selected.profile.lawyers ?? []).map((l: any, i: number) => (
                <div key={i} style={{ padding: '10px 0', borderBottom: '1px solid var(--fill-grey)' }}>
                  <div className="cell-strong">{l.fullName || `Lawyer ${i + 1}`}</div>
                  <div className="cell-sub">
                    {[l.designation, l.barLicense, l.yearsExperience ? `${l.yearsExperience} yrs` : '']
                      .filter(Boolean)
                      .join(' · ')}
                  </div>
                  {(l.expertise ?? []).length > 0 && (
                    <div className="cell-sub" style={{ marginTop: 2 }}>{l.expertise.join(', ')}</div>
                  )}
                </div>
              ))}
            </>
          )}
        </Drawer>
      )}
    </div>
  );
}
