export const API_BASE = 'http://localhost:4000/api';

const SESSION_KEY = 'advok_admin_session';

interface Session {
  token: string;
  email: string;
  name: string;
  expiresAt: number;
}

/**
 * Logs in against the ADVOK backend.
 * Returns null on success, or an error message to show the user.
 */
export async function login(email: string, password: string): Promise<string | null> {
  let res: Response;
  try {
    res = await fetch(`${API_BASE}/auth/admin/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ email: email.trim(), password }),
    });
  } catch {
    return 'Cannot reach the ADVOK backend. Is it running on port 4000?';
  }
  const data = await res.json().catch(() => ({}));
  if (!res.ok) return data.error ?? 'Invalid email or password';

  const session: Session = {
    token: data.token,
    email: data.user?.email ?? email,
    name: data.user?.name ?? 'Admin',
    expiresAt: data.expiresAt ?? Date.now() + 8 * 60 * 60 * 1000,
  };
  localStorage.setItem(SESSION_KEY, JSON.stringify(session));
  return null;
}

export function logout(): void {
  localStorage.removeItem(SESSION_KEY);
}

export function getSession(): Session | null {
  const raw = localStorage.getItem(SESSION_KEY);
  if (!raw) return null;
  try {
    const session = JSON.parse(raw) as Session;
    if (!session.token || typeof session.expiresAt !== 'number' || Date.now() >= session.expiresAt) {
      logout();
      return null;
    }
    return session;
  } catch {
    logout();
    return null;
  }
}

export function isAuthenticated(): boolean {
  return getSession() !== null;
}

/** Fetch with the admin JWT attached. Clears the session on 401 (expired/invalid token). */
export async function authFetch(path: string, init: RequestInit = {}): Promise<Response> {
  const session = getSession();
  const res = await fetch(`${API_BASE}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...(init.headers ?? {}),
      ...(session ? { Authorization: `Bearer ${session.token}` } : {}),
    },
  });
  if (res.status === 401) logout();
  return res;
}
