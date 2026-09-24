import { useEffect, useState } from 'react';
import { desktopAlertsEnabled, setDesktopAlertsEnabled } from '../components/NotificationBell';
import { PageHeader } from '../components/ui';
import {
  fetchPricing,
  fetchSupportContact,
  updatePricing,
  updateSupportContact,
  type ConsultationPricing,
  type SupportContact,
} from '../utils/backend';
import { LEGAL_CATEGORIES } from '../utils/seed';

const SUPPORT_FIELDS: { key: keyof SupportContact; label: string; hint: string }[] = [
  { key: 'email', label: 'Support Email', hint: 'Opens the mail app from "Email Us"' },
  { key: 'phone', label: 'Support Phone', hint: 'Dialled from "Call Support"' },
  { key: 'hours', label: 'Support Hours', hint: 'Shown under the support team card' },
  { key: 'responseNote', label: 'Response Note', hint: 'Shown under "Contact Support"' },
];

/** Contact details shown on the app's Help & Support screen. */
function SupportContactCard() {
  const [contact, setContact] = useState<SupportContact | null>(null);
  const [drafts, setDrafts] = useState<SupportContact>({
    email: '',
    phone: '',
    hours: '',
    responseNote: '',
  });
  const [saving, setSaving] = useState(false);
  const [note, setNote] = useState('');

  useEffect(() => {
    fetchSupportContact()
      .then((c) => {
        setContact(c);
        setDrafts(c);
      })
      .catch(() => setNote('Could not load support contact from the backend.'));
  }, []);

  const save = async () => {
    setSaving(true);
    setNote('');
    try {
      const saved = await updateSupportContact(drafts);
      setContact(saved);
      setDrafts(saved);
      setNote('Saved — the app’s Help & Support screen shows the new details immediately.');
    } catch (err) {
      setNote(err instanceof Error ? err.message : 'Failed to save support contact');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="card" style={{ padding: 20 }}>
      <div className="section-title" style={{ marginBottom: 4 }}>Help & Support Contact</div>
      <div className="cell-sub" style={{ marginBottom: 12 }}>
        Contact details shown to every role on the app's Help & Support screen.
      </div>
      {SUPPORT_FIELDS.map((f) => (
        <div key={f.key} style={{ marginBottom: 12 }}>
          <label className="field-label">{f.label}</label>
          <input
            className="input"
            value={drafts[f.key]}
            disabled={!contact}
            placeholder={f.hint}
            onChange={(e) => setDrafts((d) => ({ ...d, [f.key]: e.target.value }))}
          />
          <div className="cell-sub" style={{ marginTop: 3, fontSize: 11 }}>{f.hint}</div>
        </div>
      ))}
      <button
        className="btn-primary"
        style={{ width: '100%', marginTop: 4 }}
        disabled={!contact || saving}
        onClick={save}
      >
        {saving ? 'Saving…' : 'Save Support Contact'}
      </button>
      {note && (
        <div className="cell-sub" style={{ marginTop: 10, fontWeight: 600 }}>
          {note}
        </div>
      )}
    </div>
  );
}

// Clients consult by voice only — video calls and office visits are not
// offered on the platform.
const CONSULTATION_TYPE_INFO = [
  { kind: 'phone_call', title: 'Attorney Voice Call', subtitle: 'Voice consultation with an individual attorney' },
  {
    kind: 'law_firm_phone_call',
    title: 'Law Firm Voice Call',
    subtitle: 'Voice consultation booked with a law firm or one of its attorneys (a firm can set its own rate)',
  },
] as const;

/** Editable consultation fees, loaded from and saved to the backend. */
function ConsultationPricingCard() {
  const [pricing, setPricing] = useState<ConsultationPricing | null>(null);
  const [drafts, setDrafts] = useState<Record<string, string>>({});
  const [saving, setSaving] = useState(false);
  const [note, setNote] = useState('');

  useEffect(() => {
    fetchPricing()
      .then((p) => {
        setPricing(p);
        setDrafts(
          Object.fromEntries(
            CONSULTATION_TYPE_INFO.map((t) => [t.kind, String(p[t.kind])]),
          ),
        );
      })
      .catch(() => setNote('Could not load pricing from the backend.'));
  }, []);

  const save = async () => {
    const next = Object.fromEntries(
      CONSULTATION_TYPE_INFO.map((t) => [t.kind, Number(drafts[t.kind])]),
    ) as Partial<ConsultationPricing>;
    if (Object.values(next).some((v) => !Number.isFinite(v) || v! < 0)) {
      setNote('Prices must be valid numbers.');
      return;
    }
    setSaving(true);
    setNote('');
    try {
      const saved = await updatePricing(next as ConsultationPricing);
      setPricing(saved);
      setNote('Saved — the app shows the new prices immediately.');
    } catch (err) {
      setNote(err instanceof Error ? err.message : 'Failed to save pricing');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="card" style={{ padding: 20 }}>
      <div className="section-title" style={{ marginBottom: 4 }}>Consultation Types</div>
      <div className="cell-sub" style={{ marginBottom: 12 }}>
        Fees shown to clients in the app's booking flow.
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
        {CONSULTATION_TYPE_INFO.map((t) => (
          <div
            key={t.kind}
            className="card-white row"
            style={{ padding: '12px 14px', justifyContent: 'space-between', gap: 12 }}
          >
            <div>
              <div className="cell-strong">{t.title}</div>
              <div className="cell-sub">{t.subtitle}</div>
            </div>
            <div className="row" style={{ gap: 6 }}>
              <span style={{ fontWeight: 800, fontSize: 15 }}>$</span>
              <input
                className="input"
                type="number"
                min={0}
                value={drafts[t.kind] ?? ''}
                disabled={!pricing}
                onChange={(e) =>
                  setDrafts((d) => ({ ...d, [t.kind]: e.target.value }))
                }
                style={{ width: 90, height: 36, textAlign: 'right', fontWeight: 700 }}
              />
              <span style={{ fontSize: 10, fontWeight: 500, color: 'var(--text-grey)' }}>/session</span>
            </div>
          </div>
        ))}
      </div>
      <button
        className="btn-primary"
        style={{ width: '100%', marginTop: 14 }}
        disabled={!pricing || saving}
        onClick={save}
      >
        {saving ? 'Saving…' : 'Save Pricing'}
      </button>
      {note && (
        <div className="cell-sub" style={{ marginTop: 10, fontWeight: 600 }}>
          {note}
        </div>
      )}
    </div>
  );
}

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
  const [notifications, setNotifications] = useState(desktopAlertsEnabled);
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
              sub="Skip manual review when the state bar lookup succeeds"
              on={autoApprove}
              onToggle={() => setAutoApprove(!autoApprove)}
            />
            <SettingRow
              title="Desktop Alerts"
              sub="Browser pop-up for new registrations, tickets, queries and bookings while this tab is in the background (this browser only)"
              on={notifications}
              onToggle={() => {
                setDesktopAlertsEnabled(!notifications);
                setNotifications(!notifications);
              }}
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
            <label className="field-label">Attorney Commission</label>
            <input className="input" defaultValue="10%" style={{ marginBottom: 18 }} />
            <button className="btn-primary" style={{ width: '100%' }}>Save Changes</button>
          </div>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          <ConsultationPricingCard />

          <SupportContactCard />

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
