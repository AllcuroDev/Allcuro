import React, { useState } from 'react';
import { Lock, LogOut } from 'lucide-react';
import { supabase } from '../lib/supabase';
import type { AdminStatus } from '../lib/adminAuth';

interface AdminLoginProps {
  status: Exclude<AdminStatus, 'admin'>;
  email?: string;
  onSignOut: () => void;
}

/** Full-page gate in front of the admin panel. */
export const AdminLogin: React.FC<AdminLoginProps> = ({ status, email, onSignOut }) => {
  const [form, setForm] = useState({ email: '', password: '' });
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError(null);
    const { error: err } = await supabase.auth.signInWithPassword(form);
    if (err) setError(err.message);
    setBusy(false);
  };

  return (
    <div className="admin-login-screen">
      <div className="admin-login-card">
        <div className="sidebar-brand-row admin-login-brand">
          <div className="brand-logo-icon">
            <span className="brand-logo-text">C</span>
          </div>
          <div className="brand-text-block">
            <span className="brand-app-name">allcuro.care</span>
            <span className="brand-badge-sub">Control HQ</span>
          </div>
        </div>

        {status === 'unconfigured' ? (
          <p className="admin-login-note">
            Supabase isn&rsquo;t configured. Copy <code>.env.example</code> to <code>.env</code>, add
            your project URL and anon key, then restart <code>npm run dev</code>.
          </p>
        ) : status === 'loading' ? (
          <p className="admin-login-note">Checking your session…</p>
        ) : status === 'not_admin' ? (
          <>
            <h1 className="admin-login-title">Not an admin account</h1>
            <p className="admin-login-note">
              <strong>{email}</strong> is signed in but doesn&rsquo;t have the admin role. Ask an
              existing admin to set <code>profiles.role = 'admin'</code> for this account.
            </p>
            <button className="admin-login-submit is-outline" onClick={onSignOut}>
              <LogOut size={15} /> Sign out
            </button>
          </>
        ) : (
          <form onSubmit={submit}>
            <h1 className="admin-login-title">Admin sign in</h1>
            <p className="admin-login-note">Use the email and password of your admin account.</p>
            <label className="catalog-field">
              <span>Email</span>
              <input
                type="email"
                required
                autoComplete="username"
                value={form.email}
                onChange={(e) => setForm({ ...form, email: e.target.value })}
              />
            </label>
            <label className="catalog-field">
              <span>Password</span>
              <input
                type="password"
                required
                autoComplete="current-password"
                value={form.password}
                onChange={(e) => setForm({ ...form, password: e.target.value })}
              />
            </label>
            {error && <div className="catalog-notice is-error">{error}</div>}
            <button className="admin-login-submit" disabled={busy}>
              <Lock size={15} /> {busy ? 'Signing in…' : 'Sign in'}
            </button>
          </form>
        )}
      </div>
    </div>
  );
};
