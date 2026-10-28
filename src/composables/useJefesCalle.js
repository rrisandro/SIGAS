import { ref } from 'vue'
import { supabase } from '../lib/supabase'

function mensajeError(err, fallback = 'No se pudo completar la acción.') {
  const mensaje = String(err?.message || err?.details || '')
  if (/duplicate key/i.test(mensaje)) {
    return 'Ya existe un registro con esos datos.'
  }
  if (/No tienes permiso|42501|row-level security/i.test(mensaje)) {
    return 'No tienes permisos para gestionar los Jefes de Calle.'
  }
  if (/invalid input syntax for type uuid/i.test(mensaje)) {
    return 'El ID de acceso debe ser un UUID válido.'
  }
  return mensaje || fallback
}

export function useJefesCalle() {
  const jefes = ref([])
  const calles = ref([])
  const loading = ref(false)
  const accionLoading = ref(false)
  const error = ref(null)

  async function fetchCalles() {
    const { data, error: err } = await supabase
      .from('calles')
      .select('id_calle, nombre, activo, id_jefe_calle')
      .eq('is_deleted', false)
      .order('nombre')

    if (err) {
      console.error('[SIGAS] Error cargando calles:', err)
      return
    }

    calles.value = data || []
  }

  async function fetchJefes({ incluirEliminados = false } = {}) {
    loading.value = true
    error.value = null

    try {
      let query = supabase
        .from('jefe_de_calle')
        .select('*')
        .order('id_jefe_calle', { ascending: false })

      if (!incluirEliminados) {
        query = query.eq('is_deleted', false)
      }

      const { data, error: err } = await query
      if (err) throw err
      jefes.value = data || []
    } catch (err) {
      console.error('[SIGAS] Error cargando jefes de calle:', err)
      error.value = mensajeError(err, 'No se pudieron cargar los Jefes de Calle.')
      jefes.value = []
    } finally {
      loading.value = false
    }
  }

  async function sincronizarCalle(idJefe, idCalle, calleAnterior = null) {
    const anterior = calleAnterior ? Number(calleAnterior) : null
    const nueva = idCalle ? Number(idCalle) : null

    if (anterior && anterior !== nueva) {
      const { error: clearError } = await supabase
        .from('calles')
        .update({ id_jefe_calle: null })
        .eq('id_calle', anterior)
        .eq('id_jefe_calle', idJefe)

      if (clearError) throw clearError
    }

    if (!nueva) return

    const { data: calle, error: calleError } = await supabase
      .from('calles')
      .select('id_calle, id_jefe_calle')
      .eq('id_calle', nueva)
      .maybeSingle()

    if (calleError) throw calleError
    if (!calle) throw new Error('La calle seleccionada no existe.')

    if (calle.id_jefe_calle && Number(calle.id_jefe_calle) !== Number(idJefe)) {
      const { data: ocupante, error: ocupanteError } = await supabase
        .from('jefe_de_calle')
        .select('id_jefe_calle, nombre, activo, is_deleted')
        .eq('id_jefe_calle', calle.id_jefe_calle)
        .maybeSingle()

      if (ocupanteError) throw ocupanteError

      if (ocupante && !ocupante.is_deleted && ocupante.activo) {
        throw new Error(
          `La calle ya está asignada a ${ocupante.nombre || 'otro Jefe de Calle activo'}.`
        )
      }
    }

    const { error: assignError } = await supabase
      .from('calles')
      .update({ id_jefe_calle: idJefe })
      .eq('id_calle', nueva)

    if (assignError) throw assignError
  }

  async function crearJefe(jefe) {
    accionLoading.value = true
    error.value = null

    try {
      const payload = {
        nombre: String(jefe.nombre || '').trim(),
        ci: String(jefe.ci || '').trim() || null,
        telefono: String(jefe.telefono || '').trim() || null,
        id_calle: jefe.id_calle ? Number(jefe.id_calle) : null,
        auth_id: jefe.auth_id ? String(jefe.auth_id).trim() : null,
        activo: jefe.activo ?? true,
        estado: 'aprobado',
        is_deleted: false,
      }

      if (!payload.nombre) throw new Error('El nombre del Jefe de Calle es obligatorio.')

      const { data, error: insertError } = await supabase
        .from('jefe_de_calle')
        .insert([payload])
        .select()
        .single()

      if (insertError) throw insertError

      try {
        await sincronizarCalle(data.id_jefe_calle, payload.id_calle)
      } catch (syncError) {
        // Si no se pudo asignar la calle, no dejamos un Jefe de Calle huérfano.
        const { error: cleanupError } = await supabase
          .from('jefe_de_calle')
          .update({
            activo: false,
            is_deleted: true,
            deleted_at: new Date().toISOString(),
          })
          .eq('id_jefe_calle', data.id_jefe_calle)

        if (cleanupError) {
          console.error('[SIGAS] No se pudo revertir el Jefe de Calle creado:', cleanupError)
        }

        throw syncError
      }

      await fetchJefes()
      return data
    } catch (err) {
      console.error('[SIGAS] Error creando Jefe de Calle:', err)
      error.value = mensajeError(err, 'No se pudo registrar el Jefe de Calle.')
      return null
    } finally {
      accionLoading.value = false
    }
  }

  async function actualizarJefe(id, jefe) {
    accionLoading.value = true
    error.value = null

    try {
      const anterior = jefes.value.find((item) => item.id_jefe_calle === id)
      const payload = {
        nombre: String(jefe.nombre || '').trim(),
        ci: String(jefe.ci || '').trim() || null,
        telefono: String(jefe.telefono || '').trim() || null,
        id_calle: jefe.id_calle ? Number(jefe.id_calle) : null,
        auth_id: jefe.auth_id ? String(jefe.auth_id).trim() : null,
        activo: jefe.activo ?? anterior?.activo ?? true,
      }

      if (!payload.nombre) throw new Error('El nombre del Jefe de Calle es obligatorio.')

      const { data, error: updateError } = await supabase
        .from('jefe_de_calle')
        .update(payload)
        .eq('id_jefe_calle', id)
        .select()
        .single()

      if (updateError) throw updateError

      try {
        await sincronizarCalle(id, payload.id_calle, anterior?.id_calle)
      } catch (syncError) {
        // Revertimos la calle del registro para no dejarlo apuntando a una
        // asignación que no llegó a completarse.
        await supabase
          .from('jefe_de_calle')
          .update({ id_calle: anterior?.id_calle ?? null })
          .eq('id_jefe_calle', id)

        await sincronizarCalle(id, anterior?.id_calle ?? null, payload.id_calle).catch(
          (restoreError) => {
            console.error('[SIGAS] No se pudo restaurar la calle anterior:', restoreError)
          }
        )

        throw syncError
      }

      await fetchJefes()
      return data
    } catch (err) {
      console.error('[SIGAS] Error actualizando Jefe de Calle:', err)
      error.value = mensajeError(err, 'No se pudo actualizar el Jefe de Calle.')
      return null
    } finally {
      accionLoading.value = false
    }
  }

  async function cambiarActivo(id, activo) {
    accionLoading.value = true
    error.value = null

    try {
      const jefe = jefes.value.find((item) => item.id_jefe_calle === id)

      const { error: updateError } = await supabase
        .from('jefe_de_calle')
        .update({ activo })
        .eq('id_jefe_calle', id)

      if (updateError) throw updateError

      try {
        if (!activo && jefe?.id_calle) {
          const { error: clearError } = await supabase
            .from('calles')
            .update({ id_jefe_calle: null })
            .eq('id_calle', jefe.id_calle)
            .eq('id_jefe_calle', id)

          if (clearError) throw clearError
        }

        if (activo && jefe?.id_calle) {
          await sincronizarCalle(id, jefe.id_calle)
        }
      } catch (syncError) {
        await supabase
          .from('jefe_de_calle')
          .update({ activo: !activo })
          .eq('id_jefe_calle', id)

        throw syncError
      }

      await fetchJefes()
      return true
    } catch (err) {
      console.error('[SIGAS] Error cambiando estado del Jefe de Calle:', err)
      error.value = mensajeError(err, 'No se pudo cambiar el estado del Jefe de Calle.')
      return false
    } finally {
      accionLoading.value = false
    }
  }

  async function darBajaJefe(id) {
    accionLoading.value = true
    error.value = null

    try {
      const jefe = jefes.value.find((item) => item.id_jefe_calle === id)

      if (jefe?.id_calle) {
        const { error: clearError } = await supabase
          .from('calles')
          .update({ id_jefe_calle: null })
          .eq('id_calle', jefe.id_calle)
          .eq('id_jefe_calle', id)

        if (clearError) throw clearError
      }

      const { error: updateError } = await supabase
        .from('jefe_de_calle')
        .update({
          activo: false,
          is_deleted: true,
          deleted_at: new Date().toISOString(),
        })
        .eq('id_jefe_calle', id)

      if (updateError) {
        if (jefe?.id_calle) {
          await supabase
            .from('calles')
            .update({ id_jefe_calle: id })
            .eq('id_calle', jefe.id_calle)
        }

        throw updateError
      }

      await fetchJefes()
      return true
    } catch (err) {
      console.error('[SIGAS] Error dando de baja al Jefe de Calle:', err)
      error.value = mensajeError(err, 'No se pudo dar de baja al Jefe de Calle.')
      return false
    } finally {
      accionLoading.value = false
    }
  }

  async function restaurarJefe(id) {
    accionLoading.value = true
    error.value = null

    try {
      const jefe = jefes.value.find((item) => item.id_jefe_calle === id)

      if (jefe?.id_calle) {
        await sincronizarCalle(id, jefe.id_calle)
      }

      const { error: updateError } = await supabase
        .from('jefe_de_calle')
        .update({
          activo: true,
          is_deleted: false,
          deleted_at: null,
        })
        .eq('id_jefe_calle', id)

      if (updateError) {
        if (jefe?.id_calle) {
          await supabase
            .from('calles')
            .update({ id_jefe_calle: null })
            .eq('id_calle', jefe.id_calle)
            .eq('id_jefe_calle', id)
        }

        throw updateError
      }

      await fetchJefes()
      return true
    } catch (err) {
      console.error('[SIGAS] Error restaurando Jefe de Calle:', err)
      error.value = mensajeError(err, 'No se pudo restaurar el Jefe de Calle.')
      return false
    } finally {
      accionLoading.value = false
    }
  }

  return {
    jefes,
    calles,
    loading,
    accionLoading,
    error,
    fetchCalles,
    fetchJefes,
    crearJefe,
    actualizarJefe,
    cambiarActivo,
    darBajaJefe,
    restaurarJefe,
  }
}
