import { useEffect, useMemo, useState } from 'react';
import { IconSearch } from '../components/Icon';
import { Avatar, Badge, Drawer, FilterChips, InfoRow, PageHeader } from '../components/ui';
import {
  bookingStatusLabel,
  consultationTypeLabel,
  fetchAdminBookings,
  formatDate,
  type BackendBooking,
} from '../utils/backend';
import { money } from '../utils/seed';
import { useRealtime } from '../utils/realtime';

const FILTERS = ['All', 'Pending', 'Confirmed', 'Completed', 'Declined', 'Cancelled'];

const dateTimeLabel = (b: BackendBooking) => `${formatDate(b.date)} · ${b.time}`;

export default function BookingsPage() {
  const [bookings, setBookings] = useState<BackendBooking[]>([]);
  const [loadError, setLoadError] = useState('');
  const [filter, setFilter] = useState('All');
  const [query, setQuery] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const [tick, setTick] = useState(0);
  useRealtime(['bookings'], () => setTick((t) => t + 1));

  useEffect(() => {
    fetchAdminBookings()
      .then(setBookings)
      .catch(() => setLoadError('Could not load bookings from the backend.'));
  }, [tick]);

  const list = useMemo(() => {
    return bookings.filter((b) => {
      const matchesFilter = filter === 'All' || bookingStatusLabel(b.status) === filter;
      const q = query.trim().toLowerCase();
      const matchesQuery =
        !q ||
        b.clientName.toLowerCase().includes(q) ||
        b.advocateName.toLowerCase().includes(q) ||
        b.id.toLowerCase().includes(q);
      return matchesFilter && matchesQuery;
    });
  }, [bookings, filter, query]);

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
            placeholder="Search booking, client, attorney..."
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
              <th>Attorney</th>
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
                  <span className="cell-strong">{b.id.slice(0, 8).toUpperCase()}</span>
                </td>
                <td>
                  <div className="row" style={{ gap: 9 }}>
                    <Avatar name={b.clientName} size={28} />
                    {b.clientName}
                  </div>
                </td>
                <td>{b.advocateName}</td>
                <td>{consultationTypeLabel(b.consultationType)}</td>
                <td>{dateTimeLabel(b)}</td>
                <td>
                  <Badge label={bookingStatusLabel(b.status)} />
                </td>
                <td style={{ textAlign: 'right' }}>
                  <span className="cell-strong">{money(b.amount)}</span>
                </td>
              </tr>
            ))}
            {list.length === 0 && (
              <tr>
                <td colSpan={7} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  {loadError || 'No bookings match this filter.'}
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
              <div style={{ fontSize: 17, fontWeight: 800, letterSpacing: -0.3 }}>
                {selected.id.slice(0, 8).toUpperCase()}
              </div>
              <div className="cell-sub" style={{ fontSize: 12.5 }}>{dateTimeLabel(selected)}</div>
            </div>
            <Badge label={bookingStatusLabel(selected.status)} />
          </div>

          <div className="eyebrow" style={{ marginBottom: 4 }}>Consultation</div>
          <InfoRow k="Client" v={selected.clientName} />
          <InfoRow k="Attorney" v={selected.advocateName} />
          <InfoRow k="Consultation Type" v={consultationTypeLabel(selected.consultationType)} />
          <InfoRow k="Duration" v={`${selected.durationMinutes} minutes`} />
          <InfoRow k="Booked On" v={formatDate(selected.createdAt)} />

          <div className="eyebrow" style={{ margin: '18px 0 4px' }}>Payment</div>
          <InfoRow
            k="Total"
            v={<span style={{ fontSize: 15 }}>{money(selected.amount)}</span>}
          />
        </Drawer>
      )}
    </div>
  );
}
