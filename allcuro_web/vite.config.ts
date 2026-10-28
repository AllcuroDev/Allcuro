import react from '@vitejs/plugin-react'
import { defineConfig, loadEnv } from 'vite'

// https://vite.dev/config/
export default defineConfig(({ mode }) => {
  // SUPABASE_URL / SUPABASE_ANON_KEY come from .env locally and from the
  // host's environment variables on Vercel. Only these two are exposed to the
  // browser — never a secret like SUPABASE_SERVICE_ROLE_KEY.
  const env = loadEnv(mode, process.cwd(), 'SUPABASE_')
  return {
    plugins: [react()],
    define: {
      'import.meta.env.SUPABASE_URL': JSON.stringify(env.SUPABASE_URL ?? ''),
      'import.meta.env.SUPABASE_ANON_KEY': JSON.stringify(env.SUPABASE_ANON_KEY ?? ''),
    },
  }
})
