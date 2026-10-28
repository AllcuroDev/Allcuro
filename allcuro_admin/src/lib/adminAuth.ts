import { useEffect, useState } from 'react';
import type { Session } from '@supabase/supabase-js';
import { isSupabaseConfigured, supabase } from './supabase';

export type AdminStatus = 'unconfigured' | 'loading' | 'signed_out' | 'not_admin' | 'admin';

/**
 * The signed-in Supabase session and whether it belongs to an admin
 * (profiles.role = 'admin', checked server-side by public.is_admin()).
 */
export function useAdminSession() {
  const [session, setSession] = useState<Session | null>(null);
  const [status, setStatus] = useState<AdminStatus>(isSupabaseConfigured ? 'loading' : 'unconfigured');

  useEffect(() => {
    if (!isSupabaseConfigured) return;
    let check = 0;
    // Fires once on subscribe with the stored session, then on every sign-in/out.
    const { data } = supabase.auth.onAuthStateChange((_event, next) => {
      setSession(next);
      const current = ++check;
      if (!next) return setStatus('signed_out');
      setStatus('loading');
      // Supabase calls inside this callback can deadlock the auth lock; defer them.
      setTimeout(async () => {
        const { data: isAdmin } = await supabase.rpc('is_admin');
        if (current === check) setStatus(isAdmin === true ? 'admin' : 'not_admin');
      });
    });
    return () => data.subscription.unsubscribe();
  }, []);

  return { status, session, signOut: () => supabase.auth.signOut() };
}
