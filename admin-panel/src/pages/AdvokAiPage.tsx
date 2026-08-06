import { IconChat, IconSparkle, IconUsers } from '../components/Icon';
import { InfoRow, PageHeader, StatCard } from '../components/ui';
import { AI_SUGGESTIONS } from '../utils/seed';

export default function AdvokAiPage() {
  return (
    <div>
      <PageHeader
        eyebrow="Content"
        title="ADVOK AI"
        subtitle="Legal Assistant · Always On — free for all users, guidance based on US law."
      />

      <div className="grid-stats" style={{ marginBottom: 22 }}>
        <StatCard icon={<IconSparkle />} value="Not Connected" label="AI Backend" trend="Replies are placeholder until connected" />
        <StatCard icon={<IconChat />} value={String(AI_SUGGESTIONS.length)} label="Suggested Prompts" trend="Shown on the empty chat screen" />
        <StatCard icon={<IconUsers />} value="Free" label="Access Tier" trend="AI-POWERED · FREE banner on client home" />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: 16 }}>
        <div className="card" style={{ padding: 20 }}>
          <div className="section-title" style={{ display: 'block', marginBottom: 4 }}>
            Suggested Prompts
          </div>
          <p className="page-subtitle" style={{ marginBottom: 14 }}>
            These chips appear in the app's empty AI chat state.
          </p>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {AI_SUGGESTIONS.map((s, i) => (
              <div key={s} className="card-white row" style={{ padding: '11px 14px', gap: 11 }}>
                <span
                  className="stat-icon"
                  style={{ width: 30, height: 30, marginBottom: 0, borderRadius: 10, fontSize: 12, fontWeight: 700 }}
                >
                  {i + 1}
                </span>
                <span style={{ fontSize: 13, fontWeight: 600 }}>{s}</span>
              </div>
            ))}
          </div>
        </div>

        <div className="card" style={{ padding: 20 }}>
          <div className="section-title" style={{ display: 'block', marginBottom: 4 }}>
            Configuration
          </div>
          <p className="page-subtitle" style={{ marginBottom: 10 }}>
            Current in-app behaviour of the assistant.
          </p>
          <InfoRow k="Assistant Name" v="ADVOK AI" />
          <InfoRow k="Subtitle" v="Legal Assistant · Always On" />
          <InfoRow k="Jurisdiction" v="US law" />
          <InfoRow k="Availability" v="All roles · no verification required" />
          <InfoRow k="Student Tools" v="AI Case Brief · Explain Legal Terms · Case Notes" />
          <InfoRow k="Voice Input" v="Mic shown, not wired" />
          <div
            className="card-white"
            style={{ padding: '11px 14px', marginTop: 14, fontSize: 12, lineHeight: 1.6, color: 'var(--text-grey)' }}
          >
            The app currently returns a placeholder reply: "AI responses will appear here once the ADVOK AI
            backend is connected." Connecting a backend will make this page the home for model settings,
            usage and moderation.
          </div>
        </div>
      </div>
    </div>
  );
}
