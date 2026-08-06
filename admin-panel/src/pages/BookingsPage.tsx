import { useMemo, useState } from 'react';
import { IconSearch } from '../components/Icon';
import { Avatar, Badge, Drawer, FilterChips, InfoRow, PageHeader } from '../components/ui';
import { bookings, money } from '../utils/seed';

const FILTERS = ['All', 'Confirmed', 'Pending', 'Completed', 'Cancelled'];

export default function BookingsPage() {
  const [filter, setFilter] = useState('All');
  const [query, setQuery] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const list = useMemo(() => {
    return bookings.filter((b) => {
      const matchesFilter = filter === 'All' || b.status === filter;
      const q = query.trim().toLowerCase();
      const matchesQuery =
        !q ||
        b.client.toLowerCase().includes(q) ||
        b.advocate.toLowerCase().includes(q) ||
        b.id.toLowerCase().includes(q);
      return matchesFilter && matchesQuery;
    });
  }, [filter, query]);

  const selected = bookings.find((b) => b.id === selectedId) ?? null;

  return (
    <div>
      <PageHeader
        eyebrow="Operations"
        title="Bookings"
        subtitle={`${bookings.length} consultations booked through the platform`}
      />

      <div className="row" style={{ justifyContent: 'space-between', gap: 14, marginBottom: 16, flexWrap: 'wrap' }}>
        <FilterChips options={FILTERS} active={filter} onChange={setFilter} />
        <div className="search-wrap" style={{ width: 280 }}>
          <IconSearch />
          <input
            className="input"
            placeholder="Search booking, client, advocate..."
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
              <th>Booking</th>
              <th>Client</th>
              <th>Advocate</th>
              <th>Type</th>
              <th>Date & Time</th>
              <th>Status</th>
              <th style={{ textAlign: 'right' }}>Total</th>
            </tr>
          </thead>
          <tbody>
            {list.map((b) => (
              <tr key={b.id} className="clickable" onClick={() => setSelectedId(b.id)}>
                <td>
                  <span className="cell-strong">{b.id}</span>
                </td>
                <td>
                  <div className="row" style={{ gap: 9 }}>
                    <Avatar name={b.client} size={28} />
                    {b.client}
                  </div>
                </td>
                <td>{b.advocate}</td>
                <td>{b.type}</td>
                <td>{b.dateTime}</td>
                <td>
                  <Badge label={b.status} />
                </td>
                <td style={{ textAlign: 'right' }}>
                  <span className="cell-strong">{money(b.total)}</span>
                </td>
              </tr>
            ))}
            {list.length === 0 && (
              <tr>
                <td colSpan={7} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  No bookings match this filter.
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {selected && (
        <Drawer title="Booking Details" onClose={() => setSelectedId(null)}>
          <div className="row" style={{ justifyContent: 'space-between', marginBottom: 18 }}>
            <div>
              <div style={{ fontSize: 17, fontWeight: 800, letterSpacing: -0.3 }}>{selected.id}</div>
              <div className="cell-sub" style={{ fontSize: 12.5 }}>{selected.dateTime}</div>
            </div>
            <Badge label={selected.status} />
          </div>

          <div className="eyebrow" style={{ marginBottom: 4 }}>Consultation</div>
          <InfoRow k="Client" v={selected.client} />
          <InfoRow k="Advocate" v={selected.advocate} />
          <InfoRow k="Consultation Type" v={selected.type} />
          <InfoRow k="Duration" v="60 minutes" />

          <div className="eyebrow" style={{ margin: '18px 0 4px' }}>Payment Breakdown</div>
          <InfoRow k="Consultation Fee" v={money(selected.fee)} />
          <InfoRow k="Platform Fee" v={money(selected.platformFee)} />
          <InfoRow k="Tax (8.5%)" v={money(selected.tax)} />
          <InfoRow
            k="Total"
            v={<span style={{ fontSize: 15 }}>{money(selected.total)}</span>}
          />
          <InfoRow k="Payment Method" v="Visa ···· 4242" />
        </Drawer>
      )}
    </div>
  );
}
