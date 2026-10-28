// Uploads the app's bundled category and service artwork to Supabase Storage
// and points service_categories.image_url / services.image_url at it.
//
//   npm run upload-icons              # upload + update the catalog
//   npm run upload-icons -- --dry-run # show what would change, touch nothing
//   npm run upload-icons -- --force   # also replace logos uploaded by hand in the admin
//
// Reads VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY from .env and signs in as an
// admin (ADMIN_EMAIL / ADMIN_PASSWORD from the environment, or prompted), so RLS
// applies exactly as it does in the admin panel. Safe to re-run: files are named
// by content hash, so unchanged icons are skipped and changed ones get a fresh URL.

import { createHash } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { stdin, stdout } from 'node:process';
import { createInterface } from 'node:readline/promises';
import { fileURLToPath } from 'node:url';
import { createClient } from '@supabase/supabase-js';

const BUCKET = 'service-images';
const ASSETS = join(dirname(fileURLToPath(import.meta.url)), '../../allcuro/assets/images');
const dryRun = process.argv.includes('--dry-run');
const force = process.argv.includes('--force');

const url = process.env.VITE_SUPABASE_URL;
const anonKey = process.env.VITE_SUPABASE_ANON_KEY;
if (!url || !anonKey) {
  console.error('Missing VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY — copy .env.example to .env first.');
  process.exit(1);
}

const supabase = createClient(url, anonKey, { auth: { persistSession: false } });

async function signIn() {
  let email = process.env.ADMIN_EMAIL;
  let password = process.env.ADMIN_PASSWORD;
  if (!email || !password) {
    const rl = createInterface({ input: stdin, output: stdout });
    email ||= (await rl.question('Admin email: ')).trim();
    if (!password) {
      // Hide the password while it's typed.
      const write = rl._writeToOutput.bind(rl);
      rl._writeToOutput = (s) => write(s.startsWith('Admin password') ? s : '');
      password = await rl.question('Admin password: ');
      rl._writeToOutput = write;
      stdout.write('\n');
    }
    rl.close();
  }
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) throw new Error(`Sign-in failed: ${error.message}`);
  const { data: isAdmin } = await supabase.rpc('is_admin');
  if (isAdmin !== true) throw new Error(`${email} is not an admin (profiles.role must be 'admin').`);
}

/** Hand uploads from the admin live at <folder>/<id>-<timestamp>; ours under <folder>/bundled/. */
const isOurs = (imageUrl) => !imageUrl || (imageUrl.includes(`/${BUCKET}/`) && imageUrl.includes('/bundled/'));

const uploaded = new Map();

/** Uploads <folder>/bundled/<key>-<hash>.png once per file and returns its public URL. */
async function upload(folder, key) {
  const file = join(ASSETS, folder, `${key}.png`);
  if (!existsSync(file)) return null;
  if (uploaded.has(file)) return uploaded.get(file);
  const bytes = readFileSync(file);
  const hash = createHash('sha256').update(bytes).digest('hex').slice(0, 8);
  const path = `${folder}/bundled/${key}-${hash}.png`;
  if (!dryRun) {
    const { error } = await supabase.storage
      .from(BUCKET)
      .upload(path, bytes, { contentType: 'image/png', cacheControl: '31536000', upsert: true });
    if (error) throw new Error(`Upload ${path}: ${error.message}`);
  }
  const publicUrl = supabase.storage.from(BUCKET).getPublicUrl(path).data.publicUrl;
  uploaded.set(file, publicUrl);
  return publicUrl;
}

async function sync(table, folder, keyOf, labelOf) {
  const { data: rows, error } = await supabase.from(table).select('*').order('sort_order');
  if (error) throw new Error(`Read ${table}: ${error.message}`);
  const counts = { updated: 0, unchanged: 0, kept: 0, missing: [] };
  for (const row of rows) {
    const key = keyOf(row);
    const imageUrl = await upload(folder, key);
    if (!imageUrl) {
      counts.missing.push(`${labelOf(row)} (${key || 'no key'})`);
      continue;
    }
    if (row.image_url === imageUrl) {
      counts.unchanged++;
      continue;
    }
    if (!force && !isOurs(row.image_url)) {
      counts.kept++;
      continue;
    }
    if (!dryRun) {
      const { error: err } = await supabase.from(table).update({ image_url: imageUrl }).eq('id', row.id);
      if (err) throw new Error(`Update ${table} ${row.id}: ${err.message}`);
    }
    counts.updated++;
    console.log(`  ${dryRun ? 'would set' : 'set'} ${labelOf(row)} → ${folder}/${key}.png`);
  }
  console.log(
    `${table}: ${counts.updated} ${dryRun ? 'to update' : 'updated'}, ${counts.unchanged} already current` +
      (counts.kept ? `, ${counts.kept} kept (logo uploaded by hand — use --force to replace)` : '') +
      (counts.missing.length ? `\n  no artwork for: ${counts.missing.join(', ')}` : ''),
  );
}

try {
  await signIn();
  if (dryRun) console.log('Dry run — nothing will be uploaded or changed.\n');
  // Categories use their illustration key (`art`); services their icon key.
  await sync('service_categories', 'categories', (c) => c.art, (c) => c.label);
  await sync('services', 'services', (s) => s.icon, (s) => s.name);
  console.log(`\n${uploaded.size} image files ${dryRun ? 'would be uploaded to' : 'in'} ${BUCKET}.`);
} catch (e) {
  console.error(e.message);
  process.exit(1);
} finally {
  await supabase.auth.signOut();
}
