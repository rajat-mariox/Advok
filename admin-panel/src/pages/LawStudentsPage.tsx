import { useEffect, useMemo, useState } from 'react';
import { IconCheck, IconFile, IconSearch, IconX } from '../components/Icon';
import {
  Avatar,
  Badge,
  DetailGrid,
  DetailSection,
  Drawer,
  DrawerHero,
  FilterChips,
  PageHeader,
  RowActions,
} from '../components/ui';
import type { AdminStudent, StudentVerificationStatus } from '../types';
import {
  deleteBackendUser,
  fetchBackendUsers,
  hasSubmittedProfile,
  reviewRegistration,
  suspendBackendUser,
  toAdminStudent,
  unsuspendBackendUser,
} from '../utils/backend';
import { useRealtime } from '../utils/realtime';

const FILTERS = ['All', 'Pending Verification', 'Verified', 'Rejected', 'Suspended'];

export default function LawStudentsPage() {
  const [students, setStudents] = useState<AdminStudent[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState('');
  const [filter, setFilter] = useState('All');
  const [query, setQuery] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const load = () =>
    fetchBackendUsers('law_student')
      .then((users) => setStudents(users.filter(hasSubmittedProfile).map(toAdminStudent)))
      .catch(() =>
        setLoadError('Could not load students. Make sure the backend is running on port 4000.'),
      );

  useEffect(() => {
    load().finally(() => setLoading(false));
  }, []);
  useRealtime(['users'], () => {
    void load();
  });

  const list = useMemo(() => {
    return students.filter((s) => {
      const matchesFilter = filter === 'All' || s.verification === filter;
      const q = query.trim().toLowerCase();
      const matchesQuery =
        !q ||
        s.fullName.toLowerCase().includes(q) ||
        s.college.toLowerCase().includes(q) ||
        s.course.toLowerCase().includes(q) ||
        s.phone.toLowerCase().includes(q);
      return matchesFilter && matchesQuery;
    });
  }, [students, filter, query]);

  const selected = students.find((s) => s.id === selectedId) ?? null;

  const setVerification = async (id: string, verification: StudentVerificationStatus) => {
    const ok = await reviewRegistration(id, verification);
    if (ok) {
      setStudents((prev) => prev.map((s) => (s.id === id ? { ...s, verification } : s)));
    }
  };

  const suspendUser = async (id: string) => {
    const reason = window.prompt('Reason for suspension (optional):');
    if (reason === null) return;
    const ok = await suspendBackendUser(id, reason.trim() || undefined);
    if (ok) {
      setStudents((prev) =>
        prev.map((s) => (s.id === id ? { ...s, verification: 'Suspended' } : s)),
      );
    }
  };

  // The backend restores the pre-suspension status, so reload to pick it up.
  const unsuspendUser = async (id: string) => {
    const ok = await unsuspendBackendUser(id);
    if (ok) await load();
  };

  const deleteUser = async (id: string) => {
    if (!window.confirm('Permanently delete this student account? This cannot be undone.')) return;
    const ok = await deleteBackendUser(id);
    if (ok) {
      setStudents((prev) => prev.filter((s) => s.id !== id));
      setSelectedId(null);
    }
  };

  return (
    <div>
      <PageHeader
        eyebrow="Users"
        title="Law Students"
        subtitle={`${students.length} registered · ${students.filter((s) => s.verification === 'Pending Verification').length} awaiting student ID verification`}
      />

      <div className="row" style={{ justifyContent: 'space-between', gap: 14, marginBottom: 16, flexWrap: 'wrap' }}>
        <FilterChips options={FILTERS} active={filter} onChange={setFilter} />
        <div className="search-wrap" style={{ width: 280 }}>
          <IconSearch />
          <input
            className="input"
            placeholder="Search name, law school, degree..."
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
              <th>Student</th>
              <th>Phone</th>
              <th>Law School</th>
              <th>Degree Program</th>
              <th>Year</th>
              <th>Student ID</th>
              <th>Activity</th>
              <th>Verification</th>
              <th style={{ textAlign: 'center' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {list.map((s) => (
              <tr key={s.id} className="clickable" onClick={() => setSelectedId(s.id)}>
                <td>
                  <div className="row" style={{ gap: 10 }}>
                    <Avatar name={s.fullName} photo={s.photo} size={34} square />
                    <div>
                      <div className="cell-strong">{s.fullName}</div>
                    </div>
                  </div>
                </td>
                <td style={{ whiteSpace: 'nowrap' }}>{s.phone}</td>
                <td>{s.college}</td>
                <td>{s.course}</td>
                <td>{s.academicYear ?? '—'}</td>
                <td>
                  {s.idCardFile ? (
                    <span className="row" style={{ gap: 6 }}>
                      <IconFile size={13} />
                      <span className="cell-sub" style={{ marginTop: 0 }}>{s.idCardFile}</span>
                    </span>
                  ) : (
                    <span className="cell-sub" style={{ marginTop: 0 }}>Not uploaded</span>
                  )}
                </td>
                <td>
                  <div>{s.casesRead} cases read</div>
                  <div className="cell-sub">{s.mentors} mentors · {s.savedItems} saved</div>
                </td>
                <td>
                  <Badge label={s.verification} />
                </td>
                <td style={{ textAlign: 'center' }}>
                  <RowActions
                    suspended={s.verification === 'Suspended'}
                    onView={() => setSelectedId(s.id)}
                    onSuspend={() => suspendUser(s.id)}
                    onUnsuspend={() => unsuspendUser(s.id)}
                    onDelete={() => deleteUser(s.id)}
                  />
                </td>
              </tr>
            ))}
            {list.length === 0 && (
              <tr>
                <td colSpan={9} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  {loading ? 'Loading students…' : loadError || 'No students match this filter.'}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {selected && (
        <Drawer
          wide
          title="Student Verification"
          onClose={() => setSelectedId(null)}
          footer={
            selected.verification === 'Pending Verification' ? (
              <div className="row" style={{ gap: 10 }}>
                <button
                  className="btn-primary"
                  style={{ flex: 1 }}
                  onClick={() => setVerification(selected.id, 'Verified')}
                >
                  <IconCheck /> Verify Student ID
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
                onClick={() => setVerification(selected.id, 'Pending Verification')}
              >
                Move Back to Review
              </button>
            ) : undefined
          }
        >
          <DrawerHero
            name={selected.fullName}
            photo={selected.photo}
            square
            badge={selected.verification}
            subtitle={`${selected.course || 'Law Student'} · ${selected.college}`}
          />

          {selected.verification === 'Pending Verification' && (
            <div className="note-box">
              <span className="k">While pending</span>
              The student can read cases, use the basic AI brief and legal news. Verifying the
              student ID unlocks mentorship, the internship portal, attorney Q&amp;A and certificates.
            </div>
          )}

          <DetailSection title="Account" flush>
            <DetailGrid
              cells={[
                { k: 'Login Phone', v: selected.phone },
                { k: 'Email', v: selected.email },
                { k: 'Submitted', v: selected.submitted },
              ]}
            />
          </DetailSection>

          <DetailSection title="Law School" flush>
            <DetailGrid
              cells={[
                { k: 'Law School', v: selected.college },
                { k: 'Degree Program', v: selected.course },
                { k: 'Year', v: selected.academicYear ?? '—' },
                {
                  k: 'Student ID Card',
                  v: selected.idCardFile ? (
                    <span className="row" style={{ gap: 6 }}>
                      <IconFile size={14} /> {selected.idCardFile}
                    </span>
                  ) : (
                    'Not uploaded'
                  ),
                },
              ]}
            />
          </DetailSection>

          <DetailSection title="Activity" flush>
            <DetailGrid
              cells={[
                { k: 'Cases Read', v: selected.casesRead },
                { k: 'Saved Items', v: selected.savedItems },
                { k: 'Mentors', v: selected.mentors },
              ]}
            />
          </DetailSection>
        </Drawer>
      )}
    </div>
  );
}
