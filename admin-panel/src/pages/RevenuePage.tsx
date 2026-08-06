import { IconDollar, IconTrendUp } from '../components/Icon';
import { Avatar, Badge, PageHeader, StatCard } from '../components/ui';
import { money, payouts } from '../utils/seed';

export default function RevenuePage() {
  const gross = payouts.reduce((s, p) => s + p.gross, 0);
  const cut = payouts.reduce((s, p) => s + p.platformCut, 0);

  return (
    <div>
      <PageHeader
        eyebrow="Operations"
        title="Revenue"
        subtitle="Platform earnings, fees and advocate payouts."
      />

      <div className="grid-stats" style={{ marginBottom: 22 }}>
        <StatCard icon={<IconDollar />} value={money(gross)} label="Gross Volume" trend="Not live yet" />
        <StatCard icon={<IconTrendUp />} value={money(cut)} label="Platform Fees (10%)" trend="Not live yet" />
        <StatCard icon={<IconDollar />} value="$5.00" label="Booking Platform Fee" />
        <StatCard icon={<IconDollar />} value="8.5%" label="Tax Applied on Bookings" />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1.4fr', gap: 16 }}>
        {/* Monthly revenue chart */}
        <div className="card" style={{ padding: 20 }}>
          <div className="section-title" style={{ marginBottom: 4 }}>Monthly Volume</div>
          <div style={{ fontSize: 26, fontWeight: 800, letterSpacing: -0.5, marginBottom: 16 }}>
            {money(gross)}
            <span style={{ fontSize: 12, fontWeight: 500, color: 'var(--text-grey)' }}> /this month</span>
          </div>
          <div
            className="cell-sub"
            style={{
              height: 140,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              textAlign: 'center',
            }}
          >
            Revenue data will appear here once bookings and payments go live.
          </div>
        </div>

        {/* Payouts table */}
        <div className="table-card">
          <div className="row" style={{ padding: '16px 16px 12px' }}>
            <span className="section-title">Advocate Payouts</span>
          </div>
          <table className="data">
            <thead>
              <tr>
                <th>Advocate</th>
                <th>Gross</th>
                <th>Platform Cut</th>
                <th>Net Payout</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {payouts.map((p) => (
                <tr key={p.id}>
                  <td>
                    <div className="row" style={{ gap: 9 }}>
                      <Avatar name={p.advocate} size={28} square />
                      <span className="cell-strong">{p.advocate}</span>
                    </div>
                  </td>
                  <td>{money(p.gross)}</td>
                  <td>{money(p.platformCut)}</td>
                  <td>
                    <span className="cell-strong">{money(p.net)}</span>
                  </td>
                  <td>
                    <Badge label={p.status} />
                  </td>
                </tr>
              ))}
              {payouts.length === 0 && (
                <tr>
                  <td colSpan={5} style={{ textAlign: 'center', padding: 32, color: 'var(--text-grey)' }}>
                    No payouts yet — payments are not live.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
