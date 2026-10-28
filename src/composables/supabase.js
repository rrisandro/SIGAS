// Compatibilidad: el cliente único vive en src/lib/supabase.js.
// Evita crear dos instancias de Supabase con claves distintas.
export { supabase, SITE_URL, PASSWORD_RESET_REDIRECT } from '../lib/supabase.js'
