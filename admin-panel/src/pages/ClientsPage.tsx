import { useEffect, useMemo, useState } from 'react';
import { IconSearch } from '../components/Icon';
import { Avatar, Badge, Drawer, FilterChips, InfoRow, PageHeader } from '../components/ui';
import type { AdminClient } from '../types';
import { deleteBackendUser, fetchBackendUsers, toAdminClient } from '../utils/backend';

const FILTERS = ['All', 'Active', 'Suspended'];

export default function ClientsPage() {
  const [clients, setClients] = useState<AdminClient[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadError, setLoadError] = useState('');
  const [filter, setFilter] = useState('All');
  const [query, setQuery] = useState('');
  const [selectedId, setSelectedId] = useState<string | null>(null);

  useEffect(() => {
    fetchBackendUsers('client')
      .then((users) => setClients(users.map(toAdminClient)))
      .catch(() =>
        setLoadError('Could not load clients. Make sure the backend is running on port 4000.'),
      )
      .finally(() => setLoading(false));
  }, []);

  const list = useMemo(() => {
    return clients.filter((c) => {
      const matchesFilter = filter === 'All' || c.status === filter;
      const q = query.trim().toLowerCase();
      const matchesQuery =
        !q || c.name.toLowerCase().includes(q) || c.email.toLowerCase().includes(q);
      return matchesFilter && matchesQuery;
    });
  }, [clients, filter, query]);

  const selected = clients.find((c) => c.id === selectedId) ?? null;

  const toggleStatus = (id: string) => {
    setClients((prev) =>
      prev.map((c) =>
        c.id === id ? { ...c, status: c.status === 'Active' ? 'Suspended' : 'Active' } : c,
      ),
    );
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
            placeholder="Search name or email..."
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
              <th>Location</th>
              <th>Consultations</th>
              <th>Active Cases</th>
              <th>Saved</th>
              <th>Joined</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {list.map((c) => (
              <tr key={c.id} className="clickable" onClick={() => setSelectedId(c.id)}>
                <td>
                  <div className="row" style={{ gap: 10 }}>
                    <Avatar name={c.name} size={34} />
                    <div>
                      <div className="cell-strong">{c.name}</div>
                      <div className="cell-sub">{c.email}</div>
                    </div>
                  </div>
                </td>
                <td>{c.location}</td>
                <td>{c.consultations} sessions</td>
                <td>{c.activeCases} ongoing</td>
                <td>{c.savedAdvocates} favorites</td>
                <td>{c.joined}</td>
                <td>
                  <Badge label={c.status} />
                </td>
              </tr>
            ))}
            {list.length === 0 && (
              <tr>
                <td colSpan={7} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                  {loading ? 'Loading clients…' : loadError || 'No clients match this filter.'}
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {selected && (
        <Drawer
          title="Client Details"
          onClose={() => setSelectedId(null)}
          footer={
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <button
                className={selected.status === 'Active' ? 'btn-secondary' : 'btn-primary'}
                style={{ width: '100%', height: 44, borderRadius: 14 }}
                onClick={() => toggleStatus(selected.id)}
              >
                {selected.status === 'Active' ? 'Suspend Account' : 'Reactivate Account'}
              </button>
              <button
                className="btn-danger"
                style={{ width: '100%', height: 44, borderRadius: 14 }}
                onClick={() => deleteClient(selected.id)}
              >
                Delete Account
              </button>
            </div>
          }
        >
          <div className="row" style={{ gap: 14, marginBottom: 18 }}>
            <Avatar name={selected.name} size={56} />
            <div>
              <div className="row" style={{ gap: 8 }}>
                <span style={{ fontSize: 17, fontWeight: 800, letterSpacing: -0.3 }}>{selected.name}</span>
                <Badge label={selected.status} />
              </div>
              <div className="cell-sub" style={{ fontSize: 12.5 }}>{selected.email}</div>
            </div>
          </div>

          <div className="eyebrow" style={{ marginBottom: 4 }}>My Information</div>
          <InfoRow k="Location" v={selected.location} />
          <InfoRow k="Total Consultations" v={`${selected.consultations} sessions`} />
          <InfoRow k="Active Cases" v={`${selected.activeCases} ongoing`} />
          <InfoRow k="Saved Advocates" v={`${selected.savedAdvocates} favorites`} />
          <InfoRow k="Member Since" v={selected.joined} />
        </Drawer>
      )}
    </div>
  );
}
