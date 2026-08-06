import { useMemo, useState } from 'react';
import { Avatar, Badge, Drawer, FilterChips, InfoRow, PageHeader } from '../components/ui';
import { legalQueries, QUERY_CATEGORIES } from '../utils/seed';

const FILTERS = ['All', 'Pending', 'Answered'];

export default function LegalQueriesPage() {
  const [filter, setFilter] = useState('All');
  const [category, setCategory] = useState('All Categories');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const list = useMemo(() => {
    return legalQueries.filter((q) => {
      const matchesFilter = filter === 'All' || q.status === filter;
      const matchesCategory = category === 'All Categories' || q.category === category;
      return matchesFilter && matchesCategory;
    });
  }, [filter, category]);

  const selected = legalQueries.find((q) => q.id === selectedId) ?? null;
  const pending = legalQueries.filter((q) => q.status === 'Pending').length;

  return (
    <div>
      <PageHeader
        eyebrow="Operations"
        title="Legal Queries"
        subtitle={`${legalQueries.length} queries from students · ${pending} pending · senior advocates reply within 24 hours`}
      />

      <div className="row" style={{ justifyContent: 'space-between', gap: 14, marginBottom: 16, flexWrap: 'wrap' }}>
        <FilterChips options={FILTERS} active={filter} onChange={setFilter} />
        <select
          className="input"
          style={{ width: 220, height: 40 }}
          value={category}
          onChange={(e) => setCategory(e.target.value)}
        >
          <option>All Categories</option>
          {QUERY_CATEGORIES.map((c) => (
            <option key={c}>{c}</option>
          ))}
        </select>
      </div>

      <div className="table-card">
        <table className="data">
          <thead>
            <tr>
              <th style={{ width: '44%' }}>Query</th>
              <th>Category</th>
              <th>Asked</th>
              <th>Responder</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {list.map((q) => (
              <tr key={q.id} className="clickable" onClick={() => setSelectedId(q.id)}>
                <td>
                  <div className="cell-strong" style={{ whiteSpace: 'normal', lineHeight: 1.4 }}>
                    {q.question}
                  </div>
                  <div className="cell-sub">{q.student}</div>
                </td>
                <td>{q.category}</td>
                <td>{q.asked}</td>
                <td>{q.responder ?? '—'}</td>
                <td>
                  <Badge label={q.status} />
                </td>
              </tr>
            ))}
            {list.length === 0 && (
              <tr>
                <td colSpan={5} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  No queries match this filter.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {selected && (
        <Drawer title="Legal Query" onClose={() => setSelectedId(null)}>
          <div className="row" style={{ gap: 14, marginBottom: 18 }}>
            <Avatar name={selected.student} size={48} square />
            <div>
              <div className="row" style={{ gap: 8 }}>
                <span style={{ fontSize: 16, fontWeight: 800, letterSpacing: -0.3 }}>{selected.student}</span>
                <Badge label={selected.status} />
              </div>
              <div className="cell-sub" style={{ fontSize: 12.5 }}>
                {selected.category} · Asked {selected.asked}
              </div>
            </div>
          </div>

          <div className="eyebrow" style={{ marginBottom: 8 }}>Question</div>
          <div
            className="card-white"
            style={{ padding: '12px 14px', fontSize: 13, lineHeight: 1.6, color: 'var(--text-primary)', fontWeight: 600 }}
          >
            {selected.question}
          </div>

          {selected.status === 'Answered' && selected.response ? (
            <>
              <div className="eyebrow" style={{ margin: '18px 0 8px' }}>
                Response from {selected.responder}
              </div>
              <div
                className="card-white"
                style={{ padding: '12px 14px', fontSize: 13, lineHeight: 1.6, color: 'var(--text-grey-555)' }}
              >
                {selected.response}
              </div>
            </>
          ) : (
            <div
              className="card-white"
              style={{ padding: '12px 14px', marginTop: 18, fontSize: 12.5, lineHeight: 1.6, color: 'var(--text-grey)' }}
            >
              Awaiting response — senior advocates typically reply within 24 hours.
            </div>
          )}

          <div style={{ marginTop: 18 }}>
            <InfoRow k="Query ID" v={selected.id} />
            <InfoRow k="Category" v={selected.category} />
            <InfoRow k="Responder" v={selected.responder ?? 'Unassigned'} />
          </div>
        </Drawer>
      )}
    </div>
  );
}
