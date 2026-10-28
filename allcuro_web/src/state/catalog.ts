import { services as bundledServices } from '../data/services'
import type { Service } from '../data/types'
import { supabase } from '../lib/supabase'
import { memoryStore } from '../lib/store'

// The public services catalog. Starts with the bundled list so pages render
// instantly, then swaps in the live rows from Supabase (public.services is
// readable without login — see supabase/services.sql).

interface ServiceRow {
  id: string
  name: string
  category_id: string
  subcategory: string
  description: string
  includes: string
  not_included: string
  duration: string
  professional: string
  price: string
  notes: string
  badge: string
  icon: string
  image_url: string | null
  extra_category_ids: string[] | null
}

const catalog = memoryStore<Service[]>(bundledServices)

export const useServices = () => catalog.use()
export const getServices = () => catalog.get()

async function loadServices() {
  if (!supabase) return
  const { data, error } = await supabase
    .from('services')
    .select(
      'id, name, category_id, subcategory, description, includes, not_included, duration, professional, price, notes, badge, icon, image_url, extra_category_ids',
    )
    .order('sort_order')
  if (error || !data?.length) {
    if (error) console.warn('Services: using bundled catalog —', error.message)
    return
  }
  catalog.set(
    (data as ServiceRow[]).map((r) => ({
      id: r.id,
      name: r.name,
      category: r.category_id,
      subcategory: r.subcategory,
      description: r.description,
      includes: r.includes,
      notIncluded: r.not_included,
      duration: r.duration,
      professional: r.professional,
      price: r.price,
      notes: r.notes,
      badge: r.badge,
      icon: r.icon,
      imageUrl: r.image_url ?? undefined,
      alsoIn: r.extra_category_ids ?? [],
    })),
  )
}

void loadServices()
