import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  console.error(
    '[SIGAS] Faltan VITE_SUPABASE_URL o VITE_SUPABASE_ANON_KEY. ' +
      'Configúralas en Netlify (Site settings → Environment variables) y en tu .env local.'
  )
}

/**
 * Dominio público de la aplicación.
 *
 * - En producción sobre Netlify usamos el origin real del despliegue
 *   (incluye deploy previews y dominios personalizados).
 * - Si existe VITE_SITE_URL, esa variable manda.
 * - En local nunca usamos localhost para los correos de Supabase; se usa
 *   el dominio público de producción como fallback.
 */
const productionFallback = 'https://sistema-de-gestion-de-gas.netlify.app'
const configuredSiteUrl = String(import.meta.env.VITE_SITE_URL || '').trim()

// Nunca usamos localhost en los correos de recuperación.
const configuredIsLocal = /^(https?:\/\/)?(localhost|127\.0\.0\.1|\[::1\])(:\d+)?(\/|$)/i.test(
  configuredSiteUrl
)

const browserOrigin =
  typeof window !== 'undefined' &&
  window.location.protocol === 'https:' &&
  !/^(localhost|127\.0\.0\.1|\[::1\])$/i.test(window.location.hostname) &&
  !/^\d{1,3}(\.\d{1,3}){3}$/.test(window.location.hostname)
    ? window.location.origin
    : ''

export const SITE_URL = (
  (!configuredIsLocal && configuredSiteUrl) || browserOrigin || productionFallback
).replace(/\/+$/, '')

export const PASSWORD_RESET_REDIRECT = `${SITE_URL}/restablecer-password`

export const supabase = createClient(supabaseUrl || '', supabaseAnonKey || '', {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true,
  },
})
