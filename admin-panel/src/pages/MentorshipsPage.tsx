import { useMemo, useState } from 'react';
import { IconSearch } from '../components/Icon';
import { Avatar, Badge, Drawer, FilterChips, InfoRow, PageHeader } from '../components/ui';
import { mentorshipRequests } from '../utils/seed';

const FILTERS = ['All', 'Requested', 'Accepted', 'Completed', 'Declined'];

export default function MentorshipsPage() {
  const [filter, setFilter] = useState('All');
  const [query, setQuery] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const list = useMemo(() => {
    return mentorshipRequests.filter((m) => {
      const matchesFilter = filter === 'All' || m.status === filter;
      const q = query.trim().toLowerCase();
      const matchesQuery =
        !q ||
        m.student.toLowerCase().includes(q) ||
        m.mentor.toLowerCase().includes(q) ||
        m.sessionType.toLowerCase().includes(q);
      return matchesFilter && matchesQuery;
    });
  }, [filter, query]);

  const selected = mentorshipRequests.find((m) => m.id === selectedId) ?? null;

  return (
    <div>
      <PageHeader
        eyebrow="Operations"
        title="Mentorships"
        subtitle={`${mentorshipRequests.length} requests · mentors respond within 24 hours`}
      />

      <div className="row" style={{ justifyContent: 'space-between', gap: 14, marginBottom: 16, flexWrap: 'wrap' }}>
        <FilterChips options={FILTERS} active={filter} onChange={setFilter} />
        <div className="search-wrap" style={{ width: 280 }}>
          <IconSearch />
          <input
            className="input"
            placeholder="Search student, mentor..."
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
              <th>Mentor</th>
              <th>Session Type</th>
              <th>Preferred Date</th>
              <th>Preference</th>
              <th>Requested</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {list.map((m) => (
              <tr key={m.id} className="clickable" onClick={() => setSelectedId(m.id)}>
                <td>
                  <div className="row" style={{ gap: 10 }}>
                    <Avatar name={m.student} size={32} />
                    <span className="cell-strong">{m.student}</span>
                  </div>
                </td>
                <td>
                  <div className="cell-strong">{m.mentor}</div>
                  <div className="cell-sub">{m.mentorSpecialty}</div>
                </td>
                <td>{m.sessionType}</td>
                <td>{m.preferredDate}</td>
                <td>
                  <div>{m.dayPreference}</div>
                  <div className="cell-sub">{m.timePreference}</div>
                </td>
                <td>{m.requested}</td>
                <td>
                  <Badge label={m.status} />
                </td>
              </tr>
            ))}
            {list.length === 0 && (
              <tr>
                <td colSpan={7} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  No mentorship requests match this filter.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {selected && (
        <Drawer title="Mentorship Request" onClose={() => setSelectedId(null)}>
          <div className="row" style={{ gap: 14, marginBottom: 18 }}>
            <Avatar name={selected.student} size={56} square />
            <div>
              <div className="row" style={{ gap: 8 }}>
                <span style={{ fontSize: 17, fontWeight: 800, letterSpacing: -0.3 }}>{selected.student}</span>
                <Badge label={selected.status} />
              </div>
              <div className="cell-sub" style={{ fontSize: 12.5 }}>
                → {selected.mentor} · {selected.mentorSpecialty}
              </div>
            </div>
          </div>

          <div className="eyebrow" style={{ marginBottom: 4 }}>Session</div>
          <InfoRow k="Session Type" v={selected.sessionType} />
          <InfoRow k="Preferred Date" v={selected.preferredDate} />
          <InfoRow k="Day Preference" v={selected.dayPreference} />
          <InfoRow k="Time Preference" v={selected.timePreference} />
          <InfoRow k="Requested" v={selected.requested} />

          <div className="eyebrow" style={{ margin: '18px 0 8px' }}>Student's Message</div>
          <div
            className="card-white"
            style={{ padding: '12px 14px', fontSize: 13, lineHeight: 1.6, color: 'var(--text-grey-555)' }}
          >
            {selected.message}
          </div>
        </Drawer>
      )}
    </div>
  );
}
