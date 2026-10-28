import { createClient } from '@supabase/supabase-js'

// Public (anon) client. Without VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY the
// site keeps running on the bundled data in src/data.
const url = import.meta.env.VITE_SUPABASE_URL as string | undefined
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined

export const supabase = url && anonKey ? createClient(url, anonKey) : null
