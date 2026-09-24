import { useEffect, useState } from 'react';
import { IconChat, IconPlus, IconSparkle, IconTrash, IconUsers } from '../components/Icon';
import { Badge, DetailGrid, DetailSection, PageHeader, StatCard } from '../components/ui';
import {
  aiChat,
  fetchAiStatus,
  fetchAiSuggestions,
  updateAiSuggestions,
  type AiStatus,
  type AiSuggestion,
} from '../utils/backend';

type Draft = { id?: string; text: string; active: boolean };

export default function AdvokAiPage() {
  const [status, setStatus] = useState<AiStatus | null>(null);
  const [statusError, setStatusError] = useState('');
  const [question, setQuestion] = useState('What is a power of attorney?');
  const [reply, setReply] = useState('');
  const [asking, setAsking] = useState(false);
  const [askError, setAskError] = useState('');

  const [saved, setSaved] = useState<AiSuggestion[]>([]);
  const [drafts, setDrafts] = useState<Draft[]>([]);
  const [saving, setSaving] = useState(false);
  const [saveNote, setSaveNote] = useState('');

  useEffect(() => {
    fetchAiStatus()
      .then(setStatus)
      .catch(() => setStatusError('Could not read AI status from the backend.'));
    fetchAiSuggestions()
      .then((list) => {
        setSaved(list);
        setDrafts(list.map((x) => ({ ...x })));
      })
      .catch(() => setSaveNote('Could not load suggested prompts from the backend.'));
  }, []);

  const connected = status?.connected === true;
  const dirty = JSON.stringify(drafts) !== JSON.stringify(saved.map((x) => ({ ...x })));
  const activeCount = drafts.filter((d) => d.active && d.text.trim()).length;

  const ask = async () => {
    const q = question.trim();
    if (!q || asking) return;
    setAsking(true);
    setAskError('');
    setReply('');
    try {
      setReply(await aiChat([{ role: 'user', content: q }]));
    } catch (err) {
      setAskError(err instanceof Error ? err.message : 'Request failed');
    } finally {
      setAsking(false);
    }
  };

  const setDraft = (i: number, patch: Partial<Draft>) =>
    setDrafts((prev) => prev.map((d, j) => (j === i ? { ...d, ...patch } : d)));

  const addDraft = () => setDrafts((prev) => [...prev, { text: '', active: true }]);

  const removeDraft = (i: number) => setDrafts((prev) => prev.filter((_, j) => j !== i));

  const save = async () => {
    const cleaned = drafts.map((d) => ({ ...d, text: d.text.trim() })).filter((d) => d.text);
    setSaving(true);
    setSaveNote('');
    try {
      const list = await updateAiSuggestions(cleaned);
      setSaved(list);
      setDrafts(list.map((x) => ({ ...x })));
      setSaveNote('Saved — the app shows the new prompts the next time the AI screen opens.');
    } catch (err) {
      setSaveNote(err instanceof Error ? err.message : 'Failed to save');
    } finally {
      setSaving(false);
    }
  };

  const discard = () => {
    setDrafts(saved.map((x) => ({ ...x })));
    setSaveNote('');
  };

  return (
    <div>
      <PageHeader
        eyebrow="Content"
        title="ADVOK AI"
        subtitle="Legal information assistant · free for all users · US law and ADVOK help only."
      />

      <div className="grid-stats" style={{ marginBottom: 22 }}>
        <StatCard
          icon={<IconSparkle />}
          value={status ? (connected ? 'Connected' : 'Not Connected') : statusError ? 'Unknown' : 'Checking…'}
          label="AI Backend"
          trend={
            status
              ? connected
                ? `${status.provider} · ${status.model}`
                : status.keyError || 'Set OPENAI_API_KEY in backend/.env'
              : statusError || 'Reading status from the backend'
          }
        />
        <StatCard
          icon={<IconChat />}
          value={`${activeCount} / ${drafts.length}`}
          label="Suggested Prompts Active"
          trend="Active chips appear on the empty chat screen"
        />
        <StatCard icon={<IconUsers />} value="Free" label="Access Tier" trend="AI-POWERED · FREE banner on client home" />
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '1.4fr 1fr', gap: 16, alignItems: 'start' }}>
        <div>
          <DetailSection
            title="Suggested Prompts"
            aside={
              <button className="btn-pill-grey" onClick={addDraft} disabled={drafts.length >= 12}>
                <IconPlus size={12} /> Add prompt
              </button>
            }
            flush
          >
            {drafts.length === 0 ? (
              <div className="list-empty">No suggested prompts. Add one above.</div>
            ) : (
              drafts.map((d, i) => (
                <div key={d.id ?? `new-${i}`} className="list-item" style={{ gap: 10 }}>
                  <span
                    className="stat-icon"
                    style={{ width: 28, height: 28, marginBottom: 0, borderRadius: 9, fontSize: 11.5, fontWeight: 700, flexShrink: 0 }}
                  >
                    {i + 1}
                  </span>
                  <input
                    className="input"
                    style={{ height: 38, opacity: d.active ? 1 : 0.55 }}
                    value={d.text}
                    maxLength={140}
                    placeholder="e.g. What happens at an arraignment?"
                    onChange={(e) => setDraft(i, { text: e.target.value })}
                  />
                  <button
                    type="button"
                    role="switch"
                    aria-checked={d.active}
                    aria-label={d.active ? 'Deactivate prompt' : 'Activate prompt'}
                    title={d.active ? 'Active — tap to hide in app' : 'Inactive — tap to show in app'}
                    className={`switch${d.active ? ' on' : ''}`}
                    onClick={() => setDraft(i, { active: !d.active })}
                  />
                  <button
                    className="icon-btn icon-btn-danger"
                    aria-label="Delete prompt"
                    title="Delete prompt"
                    onClick={() => removeDraft(i)}
                  >
                    <IconTrash />
                  </button>
                </div>
              ))
            )}
            <div
              className="row"
              style={{ justifyContent: 'space-between', gap: 10, padding: '12px 14px', borderTop: '1px solid var(--divider)', flexWrap: 'wrap' }}
            >
              <span className="cell-sub" style={{ marginTop: 0 }}>
                {saveNote || 'Toggle to show or hide a prompt in the app. Order here is the order in the app. Max 12.'}
              </span>
              <div className="row" style={{ gap: 8 }}>
                <button className="btn-secondary" style={{ height: 36 }} onClick={discard} disabled={!dirty || saving}>
                  Discard
                </button>
                <button className="btn-primary" style={{ height: 36 }} onClick={save} disabled={!dirty || saving}>
                  {saving ? 'Saving…' : 'Save Changes'}
                </button>
              </div>
            </div>
          </DetailSection>

          <DetailSection
            title="Try it"
            aside={<Badge label={connected ? 'Online' : 'Pending'} />}
            flush
          >
            <div style={{ padding: 14 }}>
              <p className="page-subtitle" style={{ marginBottom: 10 }}>
                Sends one question through the same endpoint the app uses. Off-topic questions
                should be declined and steered back to US legal help.
              </p>
              <div className="row" style={{ gap: 10 }}>
                <input
                  className="input"
                  value={question}
                  onChange={(e) => setQuestion(e.target.value)}
                  onKeyDown={(e) => e.key === 'Enter' && ask()}
                  placeholder="Ask a US legal question…"
                  disabled={!connected}
                />
                <button className="btn-primary" style={{ flexShrink: 0 }} onClick={ask} disabled={!connected || asking}>
                  {asking ? 'Asking…' : 'Ask'}
                </button>
              </div>
              {drafts.some((d) => d.active && d.text.trim()) && (
                <div className="row" style={{ gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
                  {drafts
                    .filter((d) => d.active && d.text.trim())
                    .map((d, i) => (
                      <button key={d.id ?? i} className="chip" onClick={() => setQuestion(d.text)}>
                        {d.text}
                      </button>
                    ))}
                </div>
              )}
              {askError && (
                <div className="note-box" style={{ marginTop: 12, marginBottom: 0 }}>
                  <span className="k">Error</span>
                  {askError}
                </div>
              )}
              {reply && (
                <div
                  className="card-white"
                  style={{ padding: '12px 14px', marginTop: 12, fontSize: 13, lineHeight: 1.6, whiteSpace: 'pre-wrap' }}
                >
                  {reply}
                </div>
              )}
            </div>
          </DetailSection>
        </div>

        <div>
          <DetailSection title="Configuration" flush>
            <DetailGrid
              cells={[
                { k: 'Provider', v: status?.provider ?? '—' },
                { k: 'Model', v: status?.model ?? '—' },
                { k: 'Assistant Name', v: 'ADVOK AI' },
                { k: 'Jurisdiction', v: 'US law' },
                { k: 'Availability', v: 'All roles · no verification required' },
                { k: 'Voice Input', v: 'Mic shown, not wired' },
              ]}
            />
          </DetailSection>

          <DetailSection title="Guardrails">
            <div style={{ padding: '8px 0', fontSize: 12.5, lineHeight: 1.6, color: 'var(--text-grey-555)' }}>
              Answers only US legal information questions and questions about using ADVOK.
              Declines coding, trivia, other countries' law and personal advice. Never gives
              legal advice as a lawyer would, never invents statutes or deadlines, and recommends
              booking a verified attorney for specific or urgent situations. Replies are plain
              text, under about 180 words.
              <div style={{ marginTop: 8 }}>
                Rules live in <code>backend/src/services/ai.service.ts</code>. The API key is read
                from <code>GROQ_API_KEY</code> in <code>backend/.env</code> and never leaves the server.
              </div>
            </div>
          </DetailSection>
        </div>
      </div>
    </div>
  );
}
