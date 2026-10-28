import { ref } from 'vue'
import { supabase } from '../lib/supabase'

export function useFamilias() {
  const familias = ref([])
  const loading = ref(false)
  const error = ref(null)

  async function fetchFamilias({ incluirEliminadas = false } = {}) {
    loading.value = true
    error.value = null

    try {
      let query = supabase
        .from('familias')
        .select(`
          *,
          calle:calles (id_calle, nombre),
          cargo:cargos (id_cargo, nombre)
        `)
        .order('id', { ascending: false })

      if (!incluirEliminadas) {
        query = query.eq('is_deleted', false)
      }

      const { data, error: err } = await query
      if (err) throw err
      familias.value = data || []
    } catch (err) {
      console.error('[SIGAS] Error cargando familias:', err)
      error.value = err.message
      familias.value = []
    } finally {
      loading.value = false
    }
  }

  async function createFamilia(familia) {
    const { data, error: err } = await supabase
      .from('familias')
      .insert([{
        nombre_familia: familia.nombre_familia,
        id_calle: familia.id_calle,
        id_cargo: familia.id_cargo,
        activo: familia.activo ?? true,
        estado: familia.estado || 'aprobado',
        telefono: familia.telefono || null,
        direccion: familia.direccion || null,
        num_personas: familia.num_personas || null,
        is_deleted: false,
      }])
      .select()
      .single()

    if (err) {
      error.value = err.message
      return null
    }

    await fetchFamilias()
    return data
  }

  async function updateFamilia(id, updates) {
    const { data, error: err } = await supabase
      .from('familias')
      .update(updates)
      .eq('id', id)
      .select()
      .single()

    if (err) {
      error.value = err.message
      return null
    }

    await fetchFamilias()
    return data
  }

  async function darBajaFamilia(id) {
    const { error: err } = await supabase
      .from('familias')
      .update({
        is_deleted: true,
        deleted_at: new Date().toISOString(),
        activo: false,
      })
      .eq('id', id)

    if (err) {
      error.value = err.message
      return false
    }

    await fetchFamilias()
    return true
  }

  async function restaurarFamilia(id) {
    const { data: familia, error: queryError } = await supabase
      .from('familias')
      .select('estado')
      .eq('id', id)
      .maybeSingle()

    if (queryError) {
      error.value = queryError.message
      return false
    }

    const { error: err } = await supabase
      .from('familias')
      .update({
        is_deleted: false,
        deleted_at: null,
        activo: familia?.estado === 'aprobado',
      })
      .eq('id', id)

    if (err) {
      error.value = err.message
      return false
    }

    await fetchFamilias()
    return true
  }

  return {
    familias,
    loading,
    error,
    fetchFamilias,
    createFamilia,
    updateFamilia,
    darBajaFamilia,
    restaurarFamilia,
  }
}
