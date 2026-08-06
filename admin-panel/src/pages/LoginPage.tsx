import { useState } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { IconShield } from '../components/Icon';
import { isAuthenticated, login } from '../utils/auth';

export default function LoginPage() {
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const canSubmit = email.includes('@') && password.length >= 4 && !submitting;

  if (isAuthenticated()) return <Navigate to="/" replace />;

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!canSubmit) return;
    setSubmitting(true);
    setError('');
    const loginError = await login(email, password);
    setSubmitting(false);
    if (loginError === null) {
      navigate('/', { replace: true });
    } else {
      setError(loginError);
      setPassword('');
    }
  }

  return (
    <div className="login-page">
      <div className="login-card">
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', marginBottom: 28 }}>
          <div className="logo-mark" style={{ width: 52, height: 52, borderRadius: 16, fontSize: 22 }}>
            A
          </div>
          <div className="eyebrow" style={{ marginTop: 16, marginBottom: 6 }}>
            Welcome to Advok
          </div>
          <h1 className="page-title">Admin Panel</h1>
          <p className="page-subtitle">Sign in to manage the ADVOK platform.</p>
        </div>

        <form onSubmit={handleSubmit}>
          <label className="field-label">Email Address</label>
          <input
            className="input"
            type="email"
            placeholder="admin@advok.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            style={{ marginBottom: 14 }}
          />
          <label className="field-label">Password</label>
          <input
            className="input"
            type="password"
            placeholder="••••••••"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            style={{ marginBottom: error ? 12 : 20 }}
          />
          {error && (
            <div
              role="alert"
              style={{
                marginBottom: 16,
                padding: '10px 14px',
                borderRadius: 10,
                background: 'rgba(220, 53, 69, 0.08)',
                color: '#c92a3a',
                fontSize: 12.5,
                fontWeight: 600,
              }}
            >
              {error}
            </div>
          )}
          <button className="btn-primary" style={{ width: '100%', height: 50 }} disabled={!canSubmit}>
            {submitting ? 'Signing In...' : 'Sign In'}
          </button>
        </form>

        <div
          className="row"
          style={{ justifyContent: 'center', gap: 7, marginTop: 20, color: 'var(--text-grey)', fontSize: 11.5, fontWeight: 500 }}
        >
          <IconShield size={14} /> Restricted access · Authorized admins only
        </div>
      </div>
    </div>
  );
}
