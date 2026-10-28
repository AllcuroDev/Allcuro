import { supabase } from './supabase';

// Shared helpers for editing the public services catalog.

export const IMAGE_BUCKET = 'service-images';

export const slugify = (s: string) =>
  s.toLowerCase().replace(/&/g, 'and').replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

/** Lowest number in a display price: '₹699–999' → 699, '₹1,299+' → 1299. */
export const priceFrom = (price: string) => {
  const m = price.replace(/,/g, '').match(/\d+/);
  return m ? Number(m[0]) : null;
};

/**
 * Uploads a logo to the public bucket under `<folder>/<name>-<timestamp>.<ext>`
 * and returns its public URL. A new name per upload means CDNs and the apps
 * never serve a stale cached image.
 */
export async function uploadCatalogImage(folder: 'services' | 'categories', name: string, file: File) {
  const ext = file.name.split('.').pop()?.toLowerCase() ?? 'png';
  const path = `${folder}/${name || 'new'}-${Date.now()}.${ext}`;
  const { error } = await supabase.storage
    .from(IMAGE_BUCKET)
    .upload(path, file, { cacheControl: '31536000', contentType: file.type });
  if (error) throw error;
  return supabase.storage.from(IMAGE_BUCKET).getPublicUrl(path).data.publicUrl;
}

/**
 * Best-effort delete of a logo uploaded from this panel. Ignores URLs from
 * elsewhere and the shared `bundled/` artwork (the app's icons, uploaded once),
 * which several services can point at.
 */
export async function removeCatalogImage(url: string | null | undefined) {
  const marker = `/storage/v1/object/public/${IMAGE_BUCKET}/`;
  const at = url?.indexOf(marker) ?? -1;
  if (!url || at < 0 || url.includes('/bundled/')) return;
  await supabase.storage.from(IMAGE_BUCKET).remove([decodeURIComponent(url.slice(at + marker.length))]);
}
