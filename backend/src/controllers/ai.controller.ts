import type { Request, Response } from 'express';
import type { AuthedRequest } from '../middlewares/auth.middleware';
import { aiStatus, aiStatusLive, chatCompletion, type ChatMessage } from '../services/ai.service';
import type { AiSuggestion } from '../models';
import { createId, getSettings, saveDb } from '../services/db.service';

/** GET /ai/status — whether ADVOK AI is wired to a model (no secrets). */
export async function status(_req: Request, res: Response) {
  // Live check: a set-but-invalid key shows as not connected, with the reason.
  return res.json(await aiStatusLive());
}

/**
 * POST /ai/chat — body: { messages: [{ role: 'user'|'assistant', content }] }
 * The last message must be from the user. Returns { reply }.
 */
export async function chat(req: AuthedRequest, res: Response) {
  const body = req.body as { messages?: ChatMessage[] };
  const messages = Array.isArray(body?.messages) ? body.messages : [];
  const last = messages[messages.length - 1];
  if (!last || last.role !== 'user' || typeof last.content !== 'string' || !last.content.trim()) {
    return res.status(400).json({ error: 'messages must end with a non-empty user message' });
  }
  if (!aiStatus().connected) {
    return res.status(503).json({ error: 'ADVOK AI is not connected yet' });
  }
  try {
    const reply = await chatCompletion(messages);
    return res.json({ reply });
  } catch (err) {
    console.error('[ai] chat failed:', err instanceof Error ? err.message : err);
    return res
      .status(502)
      .json({ error: 'ADVOK AI could not answer right now. Please try again.' });
  }
}

/** GET /ai/suggestions — active prompt chips for the app's empty chat state. */
export function suggestions(_req: Request, res: Response) {
  const list = getSettings().aiSuggestions ?? [];
  return res.json({ suggestions: list.filter((x) => x.active).map((x) => x.text) });
}

/** GET /admin/ai/suggestions — the full list, including inactive ones. */
export function adminListSuggestions(_req: Request, res: Response) {
  return res.json({ suggestions: getSettings().aiSuggestions ?? [] });
}

/**
 * PUT /admin/ai/suggestions — body: { suggestions: [{ id?, text, active }] }
 * Replaces the whole list (order preserved). Max 12 prompts, 140 chars each.
 */
export function adminUpdateSuggestions(req: Request, res: Response) {
  const body = req.body as { suggestions?: Partial<AiSuggestion>[] };
  if (!Array.isArray(body?.suggestions)) {
    return res.status(400).json({ error: 'suggestions must be an array' });
  }
  if (body.suggestions.length > 12) {
    return res.status(400).json({ error: 'At most 12 suggested prompts' });
  }
  const next: AiSuggestion[] = [];
  for (const raw of body.suggestions) {
    const text = typeof raw?.text === 'string' ? raw.text.trim() : '';
    if (!text) return res.status(400).json({ error: 'Every prompt needs text' });
    if (text.length > 140) {
      return res.status(400).json({ error: 'Prompts must be 140 characters or fewer' });
    }
    next.push({
      id: typeof raw.id === 'string' && raw.id ? raw.id : createId(),
      text,
      active: raw.active !== false,
    });
  }
  const settings = getSettings();
  settings.aiSuggestions = next;
  settings.updatedAt = new Date().toISOString();
  saveDb();
  return res.json({ suggestions: next });
}
