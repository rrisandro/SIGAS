import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://mmrhawezilptrlixgmno.supabase.co'
const supabaseAnonKey = 'sb_publishable_D_MFZXE1Sq6tARzAs72Daw_PkozXOwD'

export const supabase = createClient(supabaseUrl, supabaseAnonKey)