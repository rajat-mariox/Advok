import { useEffect, useMemo, useState } from 'react';
import { IconSearch } from '../components/Icon';
import {
  RowActions,
  Avatar,
  Badge,
  ChipList,
  DetailGrid,
  DetailSection,
  Drawer,
  DrawerHero,
  DrawerStats,
  FilterChips,
  InfoRow,
  ListEmpty,
  ListItem,
  PageHeader,
} from '../components/ui';
import type { AdminClient } from '../types';
import {
  deleteBackendUser,
  fetchAdminBookings,
  fetchAdminCases,
  fetchBackendUsers,
  formatDate,
  suspendBackendUser,
  toAdminClient,
  unsuspendBackendUser,
  type BackendBooking,
  type BackendCase,
} from '../utils/backend';
import { useRealtime } from '../utils/realtime';

const FILTERS = ['All', 'Active', 'Suspended'];

const CONSULTATION_LABEL: Record<BackendBooking['consultationType'], string> = {
  video_call: 'Video Call',
  phone_call: 'Phone Call',
  office_visit: 'Office Visit',
};

const cap = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

export default function ClientsPage() {
  const [clients, setClients] = useState<AdminClient[]>([]);
  const [bookings, setBookings] = useState<BackendBooking[]>([]);
  const [cases, setCases] = useState<BackendCase[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState('');
  const [filter, setFilter] = useState('All');
  const [query, setQuery] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const [tick, setTick] = useState(0);
  useRealtime(['users', 'bookings', 'cases'], () => setTick((t) => t + 1));

  useEffect(() => {
    // Bookings and cases fill in the per-client consultation/case counts and
    // the history lists in the drawer; if either fails the client list still
    // loads with zeros.
    Promise.all([
      fetchBackendUsers('client'),
      fetchAdminBookings().catch(() => [] as BackendBooking[]),
      fetchAdminCases().catch(() => [] as BackendCase[]),
    ])
      .then(([users, allBookings, allCases]) => {
        setBookings(allBookings);
        setCases(allCases);
        setClients(
          users.map((u) => ({
            ...toAdminClient(u),
            consultations: allBookings.filter(
              (b) =>
                b.clientId === u.id &&
                (b.status === 'confirmed' || b.status === 'completed'),
            ).length,
            activeCases: allCases.filter((c) => c.clientId === u.id && c.status !== 'closed')
              .length,
            totalCases: allCases.filter((c) => c.clientId === u.id).length,
          })),
        );
      })
      .catch(() =>
        setLoadError('Could not load clients. Make sure the backend is running on port 4000.'),
      )
      .finally(() => setLoading(false));
  }, [tick]);

  const list = useMemo(() => {
    return clients.filter((c) => {
      const matchesFilter = filter === 'All' || c.status === filter;
      const q = query.trim().toLowerCase();
      const matchesQuery =
        !q ||
        c.name.toLowerCase().includes(q) ||
        c.email.toLowerCase().includes(q) ||
        c.phone.replace(/\s/g, '').includes(q.replace(/\s/g, ''));
      return matchesFilter && matchesQuery;
    });
  }, [clients, filter, query]);

  const selected = clients.find((c) => c.id === selectedId) ?? null;

  const selectedBookings = useMemo(
    () =>
      selected
        ? bookings
            .filter((b) => b.clientId === selected.id)
            .sort((a, b) => `${b.date} ${b.time}`.localeCompare(`${a.date} ${a.time}`))
        : [],
    [bookings, selected],
  );

  const selectedCases = useMemo(
    () =>
      selected
        ? cases
            .filter((c) => c.clientId === selected.id)
            .sort((a, b) => b.updatedAt.localeCompare(a.updatedAt))
        : [],
    [cases, selected],
  );

  const suspendClient = async (id: string) => {
    const reason = window.prompt('Reason for suspension (optional):');
    if (reason === null) return;
    const trimmed = reason.trim() || undefined;
    const ok = await suspendBackendUser(id, trimmed);
    if (ok) {
      setClients((prev) =>
        prev.map((c) =>
          c.id === id ? { ...c, status: 'Suspended', suspensionReason: trimmed } : c,
        ),
      );
    }
  };

  const unsuspendClient = async (id: string) => {
    const ok = await unsuspendBackendUser(id);
    if (ok) {
      setClients((prev) =>
        prev.map((c) =>
          c.id === id ? { ...c, status: 'Active', suspensionReason: undefined } : c,
        ),
      );
    }
  };

  const deleteClient = async (id: string) => {
    if (!window.confirm('Permanently delete this client account? This cannot be undone.')) return;
    const ok = await deleteBackendUser(id);
    if (ok) {
      setClients((prev) => prev.filter((c) => c.id !== id));
      setSelectedId(null);
    }
  };

  return (
    <div>
      <PageHeader
        eyebrow="Users"
        title="Clients"
        subtitle={`${clients.length} registered clients on the platform`}
      />

      <div className="row" style={{ justifyContent: 'space-between', gap: 14, marginBottom: 16, flexWrap: 'wrap' }}>
        <FilterChips options={FILTERS} active={filter} onChange={setFilter} />
        <div className="search-wrap" style={{ width: 280 }}>
          <IconSearch />
          <input
            className="input"
            placeholder="Search name, email or phone..."
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
              <th>Client</th>
              <th>Phone</th>
              <th>Country</th>
              <th>Consultations</th>
              <th>Active Cases</th>
              <th>Joined</th>
              <th>Status</th>
              <th style={{ textAlign: 'center' }}>Actions</th>
            </tr>
          </thead>
          <tbody>
            {list.map((c) => (
              <tr key={c.id} className="clickable" onClick={() => setSelectedId(c.id)}>
                <td>
                  <div className="row" style={{ gap: 10 }}>
                    <Avatar name={c.name} photo={c.photo} size={34} />
                    <div>
                      <div className="cell-strong">{c.name}</div>
                      <div className="cell-sub">{c.email}</div>
                    </div>
                  </div>
                </td>
                <td>{c.phone}</td>
                <td>{c.country}</td>
                <td>{c.consultations} sessions</td>
                <td>{c.activeCases} ongoing</td>
                <td>{c.joined}</td>
                <td>
                  <Badge label={c.status} />
                </td>
                <td style={{ textAlign: 'center' }}>
                  <RowActions
                    suspended={c.status === 'Suspended'}
                    onView={() => setSelectedId(c.id)}
                    onSuspend={() => suspendClient(c.id)}
                    onUnsuspend={() => unsuspendClient(c.id)}
                    onDelete={() => deleteClient(c.id)}
                  />
                </td>
              </tr>
            ))}
            {list.length === 0 && (
              <tr>
                <td colSpan={8} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  {loading ? 'Loading clients…' : loadError || 'No clients match this filter.'}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {selected && (
        <Drawer
          wide
          title="Client Details"
          onClose={() => setSelectedId(null)}
        >
          <DrawerHero
            name={selected.name}
            photo={selected.photo}
            badge={selected.status}
            subtitle={selected.email !== '—' ? selected.email : selected.phone}
          />

          {selected.status === 'Suspended' && (
            <div className="note-box">
              <span className="k">Suspension Reason</span>
              {selected.suspensionReason || 'No reason recorded.'}
            </div>
          )}

          <DrawerStats
            items={[
              { value: selected.consultations, label: 'Consultations' },
              { value: selected.activeCases, label: 'Active Cases' },
              { value: selected.totalCases, label: 'Total Cases' },
            ]}
          />

          <DetailSection title="Contact" flush>
            <DetailGrid
              cells={[
                { k: 'Phone', v: selected.phone },
                { k: 'Email', v: selected.email },
                { k: 'Country', v: selected.country },
                { k: 'Login Method', v: selected.loginMethod },
              ]}
            />
          </DetailSection>

          <DetailSection title="Account">
            <InfoRow k="Client ID" v={<span style={{ fontFamily: 'monospace', fontSize: 12 }}>{selected.id}</span>} />
            <InfoRow k="Member Since" v={selected.joined} />
            <InfoRow k="Status" v={<Badge label={selected.status} />} />
            <InfoRow k="Profile Photo" v={selected.photo ? 'Uploaded' : 'Not set'} />
          </DetailSection>

          <DetailSection
            title="Consultations"
            aside={<span className="cell-sub" style={{ marginTop: 0 }}>{selectedBookings.length} total</span>}
            flush
          >
            {selectedBookings.length === 0 ? (
              <ListEmpty text="No consultations booked yet." />
            ) : (
              selectedBookings.slice(0, 8).map((b) => (
                <ListItem
                  key={b.id}
                  title={b.advocateName}
                  sub={`${CONSULTATION_LABEL[b.consultationType]} · ${formatDate(b.date)} ${b.time} · ${b.durationMinutes} min · $${b.amount}`}
                  right={<Badge label={cap(b.status)} />}
                />
              ))
            )}
          </DetailSection>

          <DetailSection
            title="Cases"
            aside={<span className="cell-sub" style={{ marginTop: 0 }}>{selectedCases.length} total</span>}
            flush
          >
            {selectedCases.length === 0 ? (
              <ListEmpty text="No cases opened for this client." />
            ) : (
              selectedCases.slice(0, 8).map((c) => (
                <ListItem
                  key={c.id}
                  title={c.title}
                  sub={
                    <>
                      {c.caseNumber} · {c.advocateName}
                      {c.court ? ` · ${c.court}` : ''}
                      {c.nextHearing ? ` · Next hearing ${formatDate(c.nextHearing)}` : ''}
                    </>
                  }
                  right={<Badge label={cap(c.status)} />}
                />
              ))
            )}
          </DetailSection>

          {selectedCases.length > 0 && (
            <DetailSection title="Practice Areas">
              <div style={{ padding: '8px 0' }}>
                <ChipList
                  items={Array.from(
                    new Set(selectedCases.map((c) => c.practiceArea?.trim() || 'General Practice')),
                  )}
                />
              </div>
            </DetailSection>
          )}
        </Drawer>
      )}
    </div>
  );
}
