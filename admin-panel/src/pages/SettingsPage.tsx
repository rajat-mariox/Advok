import { useState } from 'react';
import { PageHeader } from '../components/ui';
import { CONSULTATION_TYPES, LEGAL_CATEGORIES } from '../utils/seed';

function Toggle({ on, onClick }: { on: boolean; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      aria-pressed={on}
      style={{
        width: 44,
        height: 26,
        borderRadius: 100,
        background: on ? 'var(--text-primary)' : 'var(--border-grey)',
        position: 'relative',
        transition: 'background 0.15s',
        flexShrink: 0,
      }}
    >
      <span
        style={{
          position: 'absolute',
          top: 3,
          left: on ? 21 : 3,
          width: 20,
          height: 20,
          borderRadius: '50%',
          background: 'var(--white)',
          boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
          transition: 'left 0.15s',
        }}
      />
    </button>
  );
}

function SettingRow({
  title,
  sub,
  on,
  onToggle,
}: {
  title: string;
  sub: string;
  on: boolean;
  onToggle: () => void;
}) {
  return (
    <div className="row" style={{ justifyContent: 'space-between', padding: '13px 0', borderBottom: '1px solid var(--divider)' }}>
      <div>
        <div className="cell-strong" style={{ fontSize: 13.5 }}>{title}</div>
        <div className="cell-sub">{sub}</div>
      </div>
      <Toggle on={on} onClick={onToggle} />
    </div>
  );
}

export default function SettingsPage() {
  const [autoApprove, setAutoApprove] = useState(false);
  const [notifications, setNotifications] = useState(true);
  const [maintenance, setMaintenance] = useState(false);
  const [aiAssistant, setAiAssistant] = useState(true);

  return (
    <div>
      <PageHeader
        eyebrow="System"
        title="Settings"
        subtitle="Platform configuration for the ADVOK app."
      />

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, alignItems: 'start' }}>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div className="card" style={{ padding: 20 }}>
            <div className="section-title" style={{ marginBottom: 6 }}>Platform</div>
            <SettingRow
              title="Auto-approve Verified Bar IDs"
              sub="Skip manual review when bar registry match succeeds"
              on={autoApprove}
              onToggle={() => setAutoApprove(!autoApprove)}
            />
            <SettingRow
              title="Admin Notifications"
              sub="Push & email enabled"
              on={notifications}
              onToggle={() => setNotifications(!notifications)}
            />
            <SettingRow
              title="ADVOK AI Assistant"
              sub="Instant legal answers banner in the client app"
              on={aiAssistant}
              onToggle={() => setAiAssistant(!aiAssistant)}
            />
            <SettingRow
              title="Maintenance Mode"
              sub="Temporarily disable the mobile app"
              on={maintenance}
              onToggle={() => setMaintenance(!maintenance)}
            />
          </div>

          <div className="card" style={{ padding: 20 }}>
            <div className="section-title" style={{ marginBottom: 12 }}>Booking Fees</div>
            <label className="field-label">Platform Fee (per booking)</label>
            <input className="input" defaultValue="$5.00" style={{ marginBottom: 14 }} />
            <label className="field-label">Tax Rate</label>
            <input className="input" defaultValue="8.5%" style={{ marginBottom: 14 }} />
            <label className="field-label">Advocate Commission</label>
            <input className="input" defaultValue="10%" style={{ marginBottom: 18 }} />
            <button className="btn-primary" style={{ width: '100%' }}>Save Changes</button>
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <div className="card" style={{ padding: 20 }}>
            <div className="section-title" style={{ marginBottom: 12 }}>Consultation Types</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {CONSULTATION_TYPES.map((t) => (
                <div key={t.title} className="card-white row" style={{ padding: '12px 14px', justifyContent: 'space-between' }}>
                  <div>
                    <div className="cell-strong">{t.title}</div>
                    <div className="cell-sub">{t.subtitle}</div>
                  </div>
                  <span style={{ fontWeight: 800, fontSize: 15 }}>
                    ${t.price}
                    <span style={{ fontSize: 10, fontWeight: 500, color: 'var(--text-grey)' }}>/session</span>
                  </span>
                </div>
              ))}
            </div>
          </div>

          <div className="card" style={{ padding: 20 }}>
            <div className="section-title" style={{ marginBottom: 12 }}>Legal Categories</div>
            <div className="row" style={{ gap: 8, flexWrap: 'wrap' }}>
              {LEGAL_CATEGORIES.map((c) => (
                <span key={c} className="chip">{c} Law</span>
              ))}
            </div>
          </div>

          <div className="card-dark" style={{ padding: 20 }}>
            <div className="eyebrow" style={{ color: '#b9b9b9', marginBottom: 6 }}>About</div>
            <div style={{ fontSize: 16, fontWeight: 800 }}>ADVOK Admin v0.1.0</div>
            <div style={{ fontSize: 12, color: '#d9d3d3', marginTop: 6, lineHeight: 1.6 }}>
              App v2.1.0 (Build 241) · iOS & Android
              <br />
              ADVOK Technologies Inc. · New York, NY, USA
              <br />
              support@advok.app · www.advok.app
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
