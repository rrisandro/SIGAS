import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import {
  limpiarDigitos,
  limpiarEmail,
  limpiarNombre,
  limpiarUuid,
  validarCedula,
  validarEmail,
  validarNombre,
  validarTelefono,
  validarUuid,
} from '../lib/validation.js'

function mensajeError(err, fallback = 'No se pudo completar la acción.') {
  const mensaje = String(err?.message || err?.details || '')
  if (/duplicate key/i.test(mensaje)) {
    return 'Ya existe un registro con esos datos.'
  }
  if (/ya está asignada/i.test(mensaje)) {
    return mensaje
  }
  if (/No tienes permiso|42501|row-level security/i.test(mensaje)) {
    return 'No tienes permisos para gestionar los Jefes de Calle.'
  }
  if (/invalid input syntax for type uuid/i.test(mensaje)) {
    return 'El ID de acceso debe ser un UUID válido.'
  }
  return mensaje || fallback
}

function esRpcInexistente(error) {
  return (
    error?.code === 'PGRST202' ||
    /could not find the function|function .* does not exist/i.test(error?.message || '')
  )
}

function normalizarIds(ids) {
  if (!Array.isArray(ids)) return []
  return [...new Set(ids.map((id) => Number(id)).filter((id) => Number.isFinite(id) && id > 0))]
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

  // Devuelve las calles actualmente vinculadas a un Jefe de Calle.
  function callesDeJefe(jefe) {
    if (!jefe) return []
    const idJefe = Number(jefe.id_jefe_calle)

    const asignadas = calles.value.filter(
      (calle) => Number(calle.id_jefe_calle) === idJefe
    )

    if (asignadas.length > 0) return asignadas

    // Compatibilidad mientras no se haya aplicado la migración multicalle:
    // la relación puede existir solo en jefe_de_calle.id_calle. Se usa únicamente
    // si esa calle no fue tomada por otro Jefe de Calle.
    if (jefe.id_calle) {
      const principal = calles.value.find(
        (calle) => Number(calle.id_calle) === Number(jefe.id_calle)
      )

      if (
        principal &&
        (!principal.id_jefe_calle || Number(principal.id_jefe_calle) === idJefe)
      ) {
        return [principal]
      }
    }

    return []
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

  async function sincronizarCallesFallback(idJefe, idsCalles) {
    const ids = normalizarIds(idsCalles)

    const { data: actuales, error: actualesError } = await supabase
      .from('calles')
      .select('id_calle')
      .eq('id_jefe_calle', idJefe)

    if (actualesError) throw actualesError

    const anteriores = (actuales || []).map((calle) => Number(calle.id_calle))

    for (const idCalle of anteriores) {
      if (!ids.includes(idCalle)) {
        const { error: clearError } = await supabase
          .from('calles')
          .update({ id_jefe_calle: null })
          .eq('id_calle', idCalle)
          .eq('id_jefe_calle', idJefe)

        if (clearError) throw clearError
      }
    }

    for (const idCalle of ids) {
      await sincronizarCalle(idJefe, idCalle)
    }
  }

  async function sincronizarCalles(idJefe, idsCalles) {
    const ids = normalizarIds(idsCalles)

    const { error: rpcError } = await supabase.rpc('asignar_calles_jefe_calle', {
      p_id_jefe_calle: Number(idJefe),
      p_ids_calles: ids,
    })

    if (rpcError) {
      if (!esRpcInexistente(rpcError)) throw rpcError
      await sincronizarCallesFallback(idJefe, ids)
    }
  }

  async function crearJefe(jefe) {
    accionLoading.value = true
    error.value = null

    try {
      const idCalles = normalizarIds(jefe.id_calles)
      const email = limpiarEmail(jefe.email, 254) || null
      const payload = {
        nombre: limpiarNombre(jefe.nombre, 120),
        ci: limpiarDigitos(jefe.ci, 10) || null,
        telefono: limpiarDigitos(jefe.telefono, 12) || null,
        email,
        id_calle: idCalles[0] || (jefe.id_calle ? Number(jefe.id_calle) : null),
        auth_id: limpiarUuid(jefe.auth_id, 36) || null,
        activo: jefe.activo ?? true,
        estado: 'aprobado',
        is_deleted: false,
      }

      const nombreError = validarNombre(payload.nombre, {
        label: 'El nombre del Jefe de Calle',
        max: 120,
      })
      if (nombreError) throw new Error(nombreError)

      const cedulaError = validarCedula(payload.ci, {
        label: 'La cédula',
        required: false,
        min: 5,
        max: 10,
      })
      if (cedulaError) throw new Error(cedulaError)

      const telefonoError = validarTelefono(payload.telefono, {
        label: 'El teléfono',
        required: false,
        min: 7,
        max: 12,
      })
      if (telefonoError) throw new Error(telefonoError)

      const emailError = email
        ? validarEmail(email, { label: 'El correo electrónico' })
        : ''
      if (emailError) throw new Error(emailError)

      const uuidError = validarUuid(payload.auth_id, { required: false })
      if (uuidError) throw new Error(uuidError)

      const { data, error: insertError } = await supabase
        .from('jefe_de_calle')
        .insert([payload])
        .select()
        .single()

      if (insertError) throw insertError

      try {
        await sincronizarCalles(data.id_jefe_calle, idCalles)
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
      const callesAnteriores = callesDeJefe(anterior).map((calle) => calle.id_calle)
      const idCalles = normalizarIds(jefe.id_calles)
      const email = limpiarEmail(jefe.email, 254) || null
      const payload = {
        nombre: limpiarNombre(jefe.nombre, 120),
        ci: limpiarDigitos(jefe.ci, 10) || null,
        telefono: limpiarDigitos(jefe.telefono, 12) || null,
        email,
        id_calle: idCalles[0] || null,
        auth_id: limpiarUuid(jefe.auth_id, 36) || null,
        activo: jefe.activo ?? anterior?.activo ?? true,
      }

      const nombreError = validarNombre(payload.nombre, {
        label: 'El nombre del Jefe de Calle',
        max: 120,
      })
      if (nombreError) throw new Error(nombreError)

      const cedulaError = validarCedula(payload.ci, {
        label: 'La cédula',
        required: false,
        min: 5,
        max: 10,
      })
      if (cedulaError) throw new Error(cedulaError)

      const telefonoError = validarTelefono(payload.telefono, {
        label: 'El teléfono',
        required: false,
        min: 7,
        max: 12,
      })
      if (telefonoError) throw new Error(telefonoError)

      const emailError = email
        ? validarEmail(email, { label: 'El correo electrónico' })
        : ''
      if (emailError) throw new Error(emailError)

      const uuidError = validarUuid(payload.auth_id, { required: false })
      if (uuidError) throw new Error(uuidError)

      const { data, error: updateError } = await supabase
        .from('jefe_de_calle')
        .update(payload)
        .eq('id_jefe_calle', id)
        .select()
        .single()

      if (updateError) throw updateError

      try {
        await sincronizarCalles(id, idCalles)
      } catch (syncError) {
        // Revertimos la calle principal del registro para no dejarlo apuntando
        // a una asignación que no llegó a completarse.
        await supabase
          .from('jefe_de_calle')
          .update({ id_calle: callesAnteriores[0] ?? null })
          .eq('id_jefe_calle', id)

        await sincronizarCalles(id, callesAnteriores).catch((restoreError) => {
          console.error('[SIGAS] No se pudo restaurar la asignación anterior:', restoreError)
        })

        throw syncError
      }

      await Promise.all([fetchJefes(), fetchCalles()])
      return data
    } catch (err) {
      console.error('[SIGAS] Error actualizando Jefe de Calle:', err)
      error.value = mensajeError(err, 'No se pudo actualizar el Jefe de Calle.')
      return null
    } finally {
      accionLoading.value = false
    }
  }

  async function aprobarJefe(id, idsCalles) {
    accionLoading.value = true
    error.value = null

    try {
      const ids = normalizarIds(idsCalles)
      const { data, error: rpcError } = await supabase.rpc('aprobar_jefe_calle', {
        p_id_jefe_calle: Number(id),
        p_ids_calles: ids,
      })

      if (rpcError) {
        if (!esRpcInexistente(rpcError)) throw rpcError

        // Compatibilidad si aún no se aplicó la migración.
        await sincronizarCalles(id, ids)
        const { error: updateError } = await supabase
          .from('jefe_de_calle')
          .update({ estado: 'aprobado', activo: true, deleted_at: null })
          .eq('id_jefe_calle', id)

        if (updateError) throw updateError
      }

      await Promise.all([fetchJefes(), fetchCalles()])
      return data || true
    } catch (err) {
      console.error('[SIGAS] Error aprobando Jefe de Calle:', err)
      error.value = mensajeError(err, 'No se pudo aprobar el Jefe de Calle.')
      return null
    } finally {
      accionLoading.value = false
    }
  }

  async function rechazarJefe(id, motivo) {
    accionLoading.value = true
    error.value = null

    try {
      const { data, error: rpcError } = await supabase.rpc('rechazar_jefe_calle', {
        p_id_jefe_calle: Number(id),
        p_motivo: String(motivo || '').trim() || null,
      })

      if (rpcError) {
        if (!esRpcInexistente(rpcError)) throw rpcError

        await supabase
          .from('calles')
          .update({ id_jefe_calle: null })
          .eq('id_jefe_calle', id)

        const { error: updateError } = await supabase
          .from('jefe_de_calle')
          .update({ estado: 'rechazado', activo: false, id_calle: null })
          .eq('id_jefe_calle', id)

        if (updateError) throw updateError
      }

      await Promise.all([fetchJefes(), fetchCalles()])
      return data || true
    } catch (err) {
      console.error('[SIGAS] Error rechazando Jefe de Calle:', err)
      error.value = mensajeError(err, 'No se pudo rechazar el Jefe de Calle.')
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
      const callesAsignadas = callesDeJefe(jefe).map((calle) => calle.id_calle)

      const { error: updateError } = await supabase
        .from('jefe_de_calle')
        .update({ activo })
        .eq('id_jefe_calle', id)

      if (updateError) throw updateError

      try {
        // Al reactivar se revalida que ninguna de sus calles haya sido tomada
        // por otro Jefe de Calle activo. Al desactivar se conserva la relación;
        // las políticas ya impiden gestionar con activo = false.
        if (activo && callesAsignadas.length > 0) {
          await sincronizarCalles(id, callesAsignadas)
        }
      } catch (syncError) {
        await supabase
          .from('jefe_de_calle')
          .update({ activo: !activo })
          .eq('id_jefe_calle', id)

        throw syncError
      }

      await Promise.all([fetchJefes(), fetchCalles()])
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
      const callesAsignadas = callesDeJefe(jefe).map((calle) => calle.id_calle)

      if (callesAsignadas.length > 0) {
        const { error: clearError } = await supabase
          .from('calles')
          .update({ id_jefe_calle: null })
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
        if (callesAsignadas.length > 0) {
          await sincronizarCalles(id, callesAsignadas).catch(() => {})
        }

        throw updateError
      }

      await Promise.all([fetchJefes(), fetchCalles()])
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
      const callePrincipal = jefe?.id_calle ? [Number(jefe.id_calle)] : []

      // Primero se restaura la ficha: la RPC de calles exige que el Jefe de
      // Calle no esté dado de baja.
      const { error: updateError } = await supabase
        .from('jefe_de_calle')
        .update({
          activo: true,
          is_deleted: false,
          deleted_at: null,
        })
        .eq('id_jefe_calle', id)

      if (updateError) throw updateError

      if (callePrincipal.length > 0) {
        try {
          await sincronizarCalles(id, callePrincipal)
        } catch (syncError) {
          // Si la calle ya fue tomada por otro, se revierte la restauración.
          await supabase
            .from('jefe_de_calle')
            .update({
              activo: false,
              is_deleted: true,
              deleted_at: new Date().toISOString(),
            })
            .eq('id_jefe_calle', id)

          throw syncError
        }
      }

      await Promise.all([fetchJefes(), fetchCalles()])
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
    callesDeJefe,
    crearJefe,
    actualizarJefe,
    aprobarJefe,
    rechazarJefe,
    cambiarActivo,
    darBajaJefe,
    restaurarJefe,
  }
}
