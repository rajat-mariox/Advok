// Live updates for the admin panel over Server-Sent Events. One shared
// EventSource per tab (opened lazily, reconnects on its own); pages call
// useRealtime(topics, reload) and re-fetch when the backend reports a change.
import { useEffect, useRef } from 'react';
import { API_BASE, getSession } from './auth';

export type RealtimeTopic =
  | 'notifications'
  | 'messages'
  | 'bookings'
  | 'cases'
  | 'clients'
  | 'queries'
  | 'mentorships'
  | 'adminNotifications'
  | 'support'
  | 'account'
  | 'settings'
  | 'registrations'
  | 'users'
  | 'content';

export interface RealtimeEvent {
  topic: RealtimeTopic;
  data?: Record<string, unknown>;
  at: string;
}

type Listener = (event: RealtimeEvent) => void;

const listeners = new Set<Listener>();
let source: EventSource | null = null;
let sourceToken: string | null = null;

function ensureConnected(): void {
  const token = getSession()?.token ?? null;
  if (!token) return;
  if (source && sourceToken === token) return;
  source?.close();
  sourceToken = token;
  // EventSource cannot set headers, so the token travels as a query param.
  source = new EventSource(`${API_BASE}/events?token=${encodeURIComponent(token)}`);
  source.addEventListener('change', (e) => {
    try {
      const event = JSON.parse((e as MessageEvent).data) as RealtimeEvent;
      for (const l of listeners) l(event);
    } catch {
      // ignore malformed frames
    }
  });
  source.onerror = () => {
    // The browser retries automatically (retry: 3000 from the server). If
    // the token was revoked, the next connect returns 401 and stays closed
    // until a new session appears.
    if (source?.readyState === EventSource.CLOSED) {
      source = null;
      sourceToken = null;
    }
  };
}

/** Closes the stream (call on logout). */
export function disconnectRealtime(): void {
  source?.close();
  source = null;
  sourceToken = null;
}

export function subscribeRealtime(listener: Listener): () => void {
  listeners.add(listener);
  ensureConnected();
  return () => {
    listeners.delete(listener);
  };
}

/**
 * Re-runs `onChange` whenever the backend reports a change on one of
 * `topics`. Bursts within 300 ms collapse into one call. The latest
 * `onChange` is always used, so pages can pass a plain closure.
 */
export function useRealtime(topics: RealtimeTopic[], onChange: (event: RealtimeEvent) => void): void {
  const cb = useRef(onChange);
  cb.current = onChange;
  const key = topics.join(',');
  useEffect(() => {
    const wanted = new Set(key.split(',').filter(Boolean));
    let timer: number | undefined;
    let last: RealtimeEvent | null = null;
    const off = subscribeRealtime((event) => {
      if (!wanted.has(event.topic)) return;
      last = event;
      window.clearTimeout(timer);
      timer = window.setTimeout(() => {
        if (last) cb.current(last);
      }, 300);
    });
    return () => {
      window.clearTimeout(timer);
      off();
    };
  }, [key]);
}
