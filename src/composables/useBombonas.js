import { ref } from 'vue'
import { supabase } from '../lib/supabase.js'

function mensajeError(err, fallback = 'No se pudo completar la acción.') {
  const mensaje = String(err?.message || err?.details || '')
  if (/duplicate key|bombonas_codigo_key|uq_bombonas_codigo/i.test(mensaje)) {
    return 'Ya existe una bombona registrada con ese código.'
  }
  if (/bombonas_tipo_check/i.test(mensaje)) {
    return 'El tipo de bombona debe ser 10kg, 18kg o 43kg.'
  }
  if (/bombonas_estado_check/i.test(mensaje)) {
    return 'El estado seleccionado no es válido.'
  }
  if (/No tienes permiso|42501|row-level security/i.test(mensaje)) {
    return 'No tienes permisos para gestionar el inventario.'
  }
  if (/relation .*bombonas.* does not exist|schema cache/i.test(mensaje)) {
    return 'La tabla de bombonas no existe. Ejecuta la migración de SIGAS en Supabase.'
  }
  return mensaje || fallback
}

function normalizarBombona(payload) {
  return {
    codigo: String(payload.codigo || '').trim().toUpperCase(),
    tipo_bombona: payload.tipo_bombona,
    peso_kg: payload.peso_kg === '' || payload.peso_kg === null || payload.peso_kg === undefined
      ? null
      : Number(payload.peso_kg),
    estado: payload.estado || 'disponible',
    id_calle: payload.id_calle ? Number(payload.id_calle) : null,
    observaciones: String(payload.observaciones || '').trim() || null,
  }
}

export function useBombonas() {
  const bombonas = ref([])
  const calles = ref([])
  const loading = ref(false)
  const accionLoading = ref(false)
  const error = ref('')

  async function fetchCalles() {
    const { data, error: queryError } = await supabase
      .from('calles')
      .select('id_calle, nombre')
      .eq('is_deleted', false)
      .order('nombre')

    if (queryError) {
      console.error('[SIGAS] Error cargando calles para bombonas:', queryError)
      return
    }

    calles.value = data || []
  }

  async function fetchBombonas({ incluirEliminadas = false } = {}) {
    loading.value = true
    error.value = ''

    try {
      let query = supabase
        .from('bombonas')
        .select('*, calle:calles(id_calle, nombre)')
        .order('created_at', { ascending: false })

      if (!incluirEliminadas) {
        query = query.eq('is_deleted', false)
      }

      const { data, error: queryError } = await query
      if (queryError) throw queryError
      bombonas.value = data || []
    } catch (err) {
      console.error('[SIGAS] Error cargando bombonas:', err)
      error.value = mensajeError(err, 'No se pudo cargar el inventario de bombonas.')
      bombonas.value = []
    } finally {
      loading.value = false
    }
  }

  async function crearBombona(payload) {
    accionLoading.value = true
    error.value = ''

    try {
      const datos = normalizarBombona(payload)
      if (!datos.codigo) throw new Error('El código de la bombona es obligatorio.')
      if (!datos.tipo_bombona) throw new Error('Selecciona el tipo de bombona.')

      const { data, error: insertError } = await supabase
        .from('bombonas')
        .insert([{ ...datos, is_deleted: false }])
        .select()
        .single()

      if (insertError) throw insertError
      return data
    } catch (err) {
      console.error('[SIGAS] Error creando bombona:', err)
      error.value = mensajeError(err, 'No se pudo registrar la bombona.')
      return null
    } finally {
      accionLoading.value = false
    }
  }

  async function actualizarBombona(id, payload) {
    accionLoading.value = true
    error.value = ''

    try {
      const datos = normalizarBombona(payload)
      if (!datos.codigo) throw new Error('El código de la bombona es obligatorio.')
      if (!datos.tipo_bombona) throw new Error('Selecciona el tipo de bombona.')

      const { data, error: updateError } = await supabase
        .from('bombonas')
        .update(datos)
        .eq('id_bombona', id)
        .select()
        .single()

      if (updateError) throw updateError
      return data
    } catch (err) {
      console.error('[SIGAS] Error actualizando bombona:', err)
      error.value = mensajeError(err, 'No se pudo actualizar la bombona.')
      return null
    } finally {
      accionLoading.value = false
    }
  }

  async function darBajaBombona(id) {
    accionLoading.value = true
    error.value = ''

    try {
      const { error: updateError } = await supabase
        .from('bombonas')
        .update({
          is_deleted: true,
          deleted_at: new Date().toISOString(),
          estado: 'mantenimiento',
        })
        .eq('id_bombona', id)

      if (updateError) throw updateError
      return true
    } catch (err) {
      console.error('[SIGAS] Error dando de baja la bombona:', err)
      error.value = mensajeError(err, 'No se pudo dar de baja la bombona.')
      return false
    } finally {
      accionLoading.value = false
    }
  }

  async function restaurarBombona(id) {
    accionLoading.value = true
    error.value = ''

    try {
      const { error: updateError } = await supabase
        .from('bombonas')
        .update({
          is_deleted: false,
          deleted_at: null,
          estado: 'disponible',
        })
        .eq('id_bombona', id)

      if (updateError) throw updateError
      return true
    } catch (err) {
      console.error('[SIGAS] Error restaurando bombona:', err)
      error.value = mensajeError(err, 'No se pudo restaurar la bombona.')
      return false
    } finally {
      accionLoading.value = false
    }
  }

  return {
    bombonas,
    calles,
    loading,
    accionLoading,
    error,
    fetchCalles,
    fetchBombonas,
    crearBombona,
    actualizarBombona,
    darBajaBombona,
    restaurarBombona,
  }
}
