import { categories } from '../data/categories'
import type { Service } from '../data/types'
import { servicesStoreRef, useContentStatus } from './content'

// The public services catalog, loaded from Supabase by state/content.ts
// (public.services is readable without login — see supabase/services.sql).
// Until a logo loads, tiles show the SVG care icon for the row's `icon` key.

export const useServices = () => servicesStoreRef.use()
export const getServices = (): Service[] => servicesStoreRef.get()

/** Category id → logo URL in Supabase Storage. */
export function useCategoryImages(): Record<string, string> {
  useContentStatus()
  return Object.fromEntries(categories.filter((c) => c.imageUrl).map((c) => [c.id, c.imageUrl!]))
}
