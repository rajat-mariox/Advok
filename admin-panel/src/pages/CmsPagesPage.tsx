import { useEffect, useState } from 'react';
import { IconFile } from '../components/Icon';
import { FilterChips, PageHeader } from '../components/ui';
import { authFetch } from '../utils/auth';

interface CmsSection {
  title: string;
  body: string;
}

interface CmsPage {
  slug: string;
  title: string;
  sections: CmsSection[];
  lastUpdatedLabel: string;
  updatedAt: string;
}

export default function CmsPagesPage() {
  const [pages, setPages] = useState<CmsPage[]>([]);
  const [activeSlug, setActiveSlug] = useState<string | null>(null);
  const [draft, setDraft] = useState<CmsPage | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<{ ok: boolean; text: string } | null>(null);

  useEffect(() => {
    authFetch('/admin/cms')
      .then(async (res) => {
        if (!res.ok) throw new Error();
        const data = await res.json();
        const list: CmsPage[] = data.pages ?? [];
        setPages(list);
        if (list.length > 0) {
          setActiveSlug(list[0].slug);
          setDraft(structuredClone(list[0]));
        }
      })
      .catch(() => setMessage({ ok: false, text: 'Could not load pages. Is the backend running?' }))
      .finally(() => setLoading(false));
  }, []);

  function selectPage(title: string) {
    const page = pages.find((p) => p.title === title) ?? null;
    if (!page) return;
    setActiveSlug(page.slug);
    setDraft(structuredClone(page));
    setMessage(null);
  }

  function updateDraft(patch: Partial<CmsPage>) {
    setDraft((d) => (d ? { ...d, ...patch } : d));
  }

  function updateSection(index: number, patch: Partial<CmsSection>) {
    setDraft((d) => {
      if (!d) return d;
      const sections = d.sections.map((s, i) => (i === index ? { ...s, ...patch } : s));
      return { ...d, sections };
    });
  }

  function addSection() {
    setDraft((d) => (d ? { ...d, sections: [...d.sections, { title: '', body: '' }] } : d));
  }

  function removeSection(index: number) {
    setDraft((d) => (d ? { ...d, sections: d.sections.filter((_, i) => i !== index) } : d));
  }

  function moveSection(index: number, delta: -1 | 1) {
    setDraft((d) => {
      if (!d) return d;
      const target = index + delta;
      if (target < 0 || target >= d.sections.length) return d;
      const sections = [...d.sections];
      [sections[index], sections[target]] = [sections[target], sections[index]];
      return { ...d, sections };
    });
  }

  async function save() {
    if (!draft || !activeSlug) return;
    setSaving(true);
    setMessage(null);
    try {
      const res = await authFetch(`/admin/cms/${activeSlug}`, {
        method: 'PUT',
        body: JSON.stringify({
          title: draft.title,
          sections: draft.sections,
          lastUpdatedLabel: draft.lastUpdatedLabel,
        }),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        setMessage({ ok: false, text: data.error ?? 'Could not save the page.' });
        return;
      }
      const saved: CmsPage = data.page;
      setPages((list) => list.map((p) => (p.slug === saved.slug ? saved : p)));
      setDraft(structuredClone(saved));
      setMessage({ ok: true, text: 'Saved. The app now shows this version.' });
    } catch {
      setMessage({ ok: false, text: 'Could not reach the backend.' });
    } finally {
      setSaving(false);
    }
  }

  const canSave =
    !!draft &&
    !saving &&
    draft.title.trim().length > 0 &&
    draft.sections.length > 0 &&
    draft.sections.every((s) => s.title.trim() && s.body.trim());

  return (
    <div>
      <PageHeader
        eyebrow="Content"
        title="App Pages"
        subtitle="Terms & Conditions, Privacy Policy and other pages shown inside the ADVOK app. Edits go live immediately."
        actions={
          draft && (
            <button className="btn-primary" disabled={!canSave} onClick={save}>
              {saving ? 'Saving…' : 'Save Changes'}
            </button>
          )
        }
      />

      {loading ? (
        <p className="page-subtitle">Loading pages…</p>
      ) : pages.length === 0 ? (
        <p className="page-subtitle">No pages found.</p>
      ) : (
        <>
          <div style={{ marginBottom: 16 }}>
            <FilterChips
              options={pages.map((p) => p.title)}
              active={pages.find((p) => p.slug === activeSlug)?.title ?? ''}
              onChange={selectPage}
            />
          </div>

          {message && (
            <p
              style={{
                marginBottom: 14,
                fontSize: 13,
                fontWeight: 600,
                color: message.ok ? 'var(--text-grey-555)' : 'var(--dark-1a)',
              }}
            >
              {message.text}
            </p>
          )}

          {draft && (
            <div className="card" style={{ padding: 22, maxWidth: 760 }}>
              <div style={{ marginBottom: 16 }}>
                <label className="field-label">Page Title</label>
                <input
                  className="input"
                  value={draft.title}
                  onChange={(e) => updateDraft({ title: e.target.value })}
                />
              </div>

              <div style={{ marginBottom: 20 }}>
                <label className="field-label">Footer Label (shown at the bottom in the app)</label>
                <input
                  className="input"
                  placeholder="e.g. Last updated: January 1, 2025"
                  value={draft.lastUpdatedLabel}
                  onChange={(e) => updateDraft({ lastUpdatedLabel: e.target.value })}
                />
              </div>

              <div className="field-label" style={{ marginBottom: 10 }}>
                Sections
              </div>

              {draft.sections.map((section, i) => (
                <div
                  key={i}
                  style={{
                    border: '1.4px solid var(--border-grey)',
                    borderRadius: 12,
                    padding: 14,
                    marginBottom: 12,
                    background: 'var(--white)',
                  }}
                >
                  <div className="row" style={{ gap: 8, marginBottom: 8 }}>
                    <input
                      className="input"
                      placeholder="Section title"
                      value={section.title}
                      onChange={(e) => updateSection(i, { title: e.target.value })}
                    />
                    <button
                      className="btn-secondary"
                      title="Move up"
                      disabled={i === 0}
                      onClick={() => moveSection(i, -1)}
                      style={{ minWidth: 38, padding: 0 }}
                    >
                      ↑
                    </button>
                    <button
                      className="btn-secondary"
                      title="Move down"
                      disabled={i === draft.sections.length - 1}
                      onClick={() => moveSection(i, 1)}
                      style={{ minWidth: 38, padding: 0 }}
                    >
                      ↓
                    </button>
                    <button
                      className="btn-danger"
                      title="Remove section"
                      disabled={draft.sections.length <= 1}
                      onClick={() => removeSection(i)}
                      style={{ minWidth: 38, padding: 0 }}
                    >
                      ✕
                    </button>
                  </div>
                  <textarea
                    className="input"
                    rows={4}
                    placeholder="Section text"
                    value={section.body}
                    onChange={(e) => updateSection(i, { body: e.target.value })}
                    style={{ height: 'auto', padding: '12px 14px', resize: 'vertical', lineHeight: 1.55 }}
                  />
                </div>
              ))}

              <button className="btn-secondary" onClick={addSection}>
                <IconFile /> Add Section
              </button>

              <p style={{ marginTop: 16, fontSize: 12, color: 'var(--text-grey)' }}>
                Last saved: {new Date(draft.updatedAt).toLocaleString()}
              </p>
            </div>
          )}
        </>
      )}
    </div>
  );
}
