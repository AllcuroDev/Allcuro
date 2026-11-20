import { createClient } from '@supabase/supabase-js'

// Public (anon) client. Without SUPABASE_URL / SUPABASE_ANON_KEY (see vite.config.ts) the
// site keeps running on the bundled data in src/data.
const url = import.meta.env.SUPABASE_URL as string
const anonKey = import.meta.env.SUPABASE_ANON_KEY as string

/** Base URL of the project's Edge Functions, or '' when built without keys. */
export const functionsUrl = url ? `${url.replace(/\/$/, '')}/functions/v1` : ''
/** The public anon key — Edge Functions require it as a bearer token. */
export const supabaseAnonKey = anonKey ?? ''

export const supabase = url && anonKey ? createClient(url, anonKey) : null

if (!supabase) {
  // These are inlined at build time — on Vercel they must be set as project
  // Environment Variables before the build, not just in a local .env.
  console.warn('Supabase keys missing from this build: showing the bundled catalog and icons.')
}
