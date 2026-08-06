import { useMemo, useState } from 'react';
import { IconSearch } from '../components/Icon';
import { Badge, FilterChips, PageHeader } from '../components/ui';
import { cases } from '../utils/seed';

const FILTERS = ['All', 'Active', 'Hearing', 'Discovery', 'Closed'];

export default function CasesPage() {
  const [filter, setFilter] = useState('All');
  const [query, setQuery] = useState('');

  const list = useMemo(() => {
    return cases.filter((c) => {
      const matchesFilter = filter === 'All' || c.status === filter;
      const q = query.trim().toLowerCase();
      const matchesQuery =
        !q ||
        c.number.toLowerCase().includes(q) ||
        c.title.toLowerCase().includes(q) ||
        c.client.toLowerCase().includes(q) ||
        c.advocate.toLowerCase().includes(q);
      return matchesFilter && matchesQuery;
    });
  }, [filter, query]);

  return (
    <div>
      <PageHeader
        eyebrow="Operations"
        title="Cases"
        subtitle={`${cases.length} cases being managed on the platform`}
      />

      <div className="row" style={{ justifyContent: 'space-between', gap: 14, marginBottom: 16, flexWrap: 'wrap' }}>
        <FilterChips options={FILTERS} active={filter} onChange={setFilter} />
        <div className="search-wrap" style={{ width: 280 }}>
          <IconSearch />
          <input
            className="input"
            placeholder="Search case no, client, advocate..."
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
              <th>Case</th>
              <th>Client</th>
              <th>Advocate</th>
              <th>Court</th>
              <th>Filed</th>
              <th>Next Hearing</th>
              <th>Priority</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {list.map((c) => (
              <tr key={c.number}>
                <td>
                  <div className="cell-strong" style={{ textTransform: 'uppercase' }}>{c.number}</div>
                  <div className="cell-sub">{c.title} · {c.practiceArea}</div>
                </td>
                <td>{c.client}</td>
                <td>{c.advocate}</td>
                <td>{c.court}</td>
                <td>{c.filed}</td>
                <td>{c.nextHearing ?? '—'}</td>
                <td>{c.priority ? <Badge label={c.priority} /> : '—'}</td>
                <td>
                  <Badge label={c.status} />
                </td>
              </tr>
            ))}
            {list.length === 0 && (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  No cases match this filter.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}
