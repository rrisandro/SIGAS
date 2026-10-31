import { computed, ref } from 'vue'
import { supabase } from '../lib/supabase.js'
import {
  limpiarDigitos,
  limpiarNombre,
  limpiarTexto,
  validarEntero,
  validarNombre,
  validarTelefono,
  validarTexto,
} from '../lib/validation.js'

function mensajeError(err, fallback = 'No se pudo completar la acción.') {
  const mensaje = String(err?.message || err?.details || '')
  if (/ya tiene un Jefe de Familia activo/i.test(mensaje)) return mensaje
  if (/uq_jefes_familia_activo|duplicate key/i.test(mensaje)) {
    return 'La familia ya tiene un Jefe de Familia activo. Debes darlo de baja antes de asignar otro.'
  }
  if (/No tienes permiso|42501|row-level security/i.test(mensaje)) {
    return 'No tienes permisos para gestionar este registro.'
  }
  if (/no existe|not found/i.test(mensaje)) {
    return 'El registro ya no existe o fue eliminado.'
  }
  return mensaje || fallback
}

function esRpcInexistente(error) {
  return (
    error?.code === 'PGRST202' ||
    /could not find the function|function .* does not exist/i.test(error?.message || '')
  )
}

export function useRegistrosFamilia() {
  const jefe = ref(null)
  const calleId = ref(null)
  const registros = ref([])
  const jefesFamilia = ref([])
  const calles = ref([])
  const loading = ref(false)
  const error = ref('')
  const accionLoading = ref(false)

  const pendientes = computed(() =>
    registros.value.filter((registro) => registro.estado === 'pendiente')
  )
  const aprobados = computed(() =>
    registros.value.filter((registro) => registro.estado === 'aprobado')
  )
  const rechazados = computed(() =>
    registros.value.filter((registro) => registro.estado === 'rechazado')
  )
  const jefesActivos = computed(() =>
    jefesFamilia.value.filter((item) => item.activo && !item.is_deleted)
  )

  async function cargarContexto() {
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser()

    if (authError || !user) {
      throw new Error('Tu sesión expiró. Vuelve a iniciar sesión.')
    }

    const { data: jefesData, error: jefeError } = await supabase
      .from('jefe_de_calle')
      .select('*')
      .eq('auth_id', user.id)
      .eq('activo', true)
      .eq('is_deleted', false)
      .limit(1)

    if (jefeError) throw jefeError
    jefe.value = jefesData?.[0] || null

    if (!jefe.value) {
      calleId.value = null
      return
    }

    let idCalle = jefe.value.id_calle || null

    if (!idCalle) {
      const { data: calleData } = await supabase
        .from('calles')
        .select('id_calle')
        .eq('id_jefe_calle', jefe.value.id_jefe_calle)
        .eq('is_deleted', false)
        .limit(1)
      idCalle = calleData?.[0]?.id_calle || null
    }

    calleId.value = idCalle

    const { data: callesData } = await supabase
      .from('calles')
      .select('id_calle, nombre')
      .eq('is_deleted', false)
      .order('nombre')

    calles.value = callesData || []
  }

  async function cargarRegistros() {
    if (!calleId.value) {
      registros.value = []
      return
    }

    const { data, error: queryError } = await supabase
      .from('familias')
      .select('*')
      .eq('id_calle', calleId.value)
      .eq('id_cargo', 3)
      .eq('is_deleted', false)
      .order('id', { ascending: false })

    if (queryError) throw queryError
    registros.value = data || []
  }

  async function cargarJefesFamilia() {
    if (!calleId.value) {
      jefesFamilia.value = []
      return
    }

    const { data, error: queryError } = await supabase
      .from('jefes_familia')
      .select('*')
      .eq('id_calle', calleId.value)
      .eq('is_deleted', false)
      .order('id_jefe_familia', { ascending: false })

    if (queryError) throw queryError
    jefesFamilia.value = data || []
  }

  async function cargarTodo() {
    loading.value = true
    error.value = ''
    try {
      await cargarContexto()
      if (calleId.value) {
        await Promise.all([cargarRegistros(), cargarJefesFamilia()])
      } else {
        registros.value = []
        jefesFamilia.value = []
      }
    } catch (err) {
      console.error('[SIGAS] Error cargando registros de familias:', err)
      error.value = mensajeError(err, 'No se pudieron cargar los registros.')
    } finally {
      loading.value = false
    }
  }

  async function verificarJefeActivo(idFamilia) {
    const { data, error: queryError } = await supabase
      .from('jefes_familia')
      .select('id_jefe_familia, nombre, activo')
      .eq('id_familia', idFamilia)
      .eq('activo', true)
      .eq('is_deleted', false)
      .limit(1)

    if (queryError) throw queryError
    return data?.[0] || null
  }

  async function aprobarRegistro(idFamilia) {
    accionLoading.value = true
    error.value = ''
    try {
      const activo = await verificarJefeActivo(idFamilia)
      if (activo) {
        throw new Error(
          `La familia ya tiene un Jefe de Familia activo (${activo.nombre || `ID ${activo.id_jefe_familia}`}). ` +
            'Debes darlo de baja antes de asignar otro.'
        )
      }

      const { data, error: rpcError } = await supabase.rpc('aprobar_registro_familia', {
        p_id_familia: idFamilia,
      })

      if (rpcError) {
        if (!esRpcInexistente(rpcError)) throw rpcError
        await aprobarRegistroFallback(idFamilia)
      }

      await Promise.all([cargarRegistros(), cargarJefesFamilia()])
      return data || true
    } catch (err) {
      console.error('[SIGAS] Error aprobando registro:', err)
      error.value = mensajeError(err, 'No se pudo aprobar el registro.')
      throw err
    } finally {
      accionLoading.value = false
    }
  }

  async function aprobarRegistroFallback(idFamilia) {
    const registro = registros.value.find((item) => item.id === idFamilia)
    if (!registro) throw new Error('El registro no está disponible.')

    const { data: nuevoJefe, error: insertError } = await supabase
      .from('jefes_familia')
      .insert([
        {
          id_familia: registro.id,
          auth_id: registro.auth_id,
          id_calle: registro.id_calle,
          nombre: registro.nombre_familia,
          ci: String(registro.id),
          telefono: registro.telefono,
          activo: true,
          estado: 'aprobado',
          is_deleted: false,
        },
      ])
      .select('id_jefe_familia')
      .single()

    if (insertError) throw insertError

    const { error: updateError } = await supabase
      .from('familias')
      .update({
        estado: 'aprobado',
        activo: true,
        notas_rechazo: null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', idFamilia)

    if (updateError) throw updateError

    if (registro.auth_id) {
      await supabase.from('notificaciones').insert([
        {
          destinatario_auth_id: registro.auth_id,
          id_familia: registro.id,
          tipo: 'registro_aprobado',
          titulo: 'Registro aprobado',
          mensaje:
            'Tu registro como Jefe de Familia fue aprobado. Ya puedes iniciar sesión en SIGAS.',
          metadata: { id_familia: registro.id },
        },
      ])
    }

    return nuevoJefe
  }

  async function rechazarRegistro(idFamilia, motivo) {
    accionLoading.value = true
    error.value = ''
    try {
      const motivoLimpio = String(motivo || '').trim()
      if (!motivoLimpio) {
        throw new Error('Indica el motivo del rechazo.')
      }

      const motivoError = validarTexto(motivoLimpio, {
        label: 'El motivo del rechazo',
        max: 500,
        required: true,
      })
      if (motivoError) throw new Error(motivoError)

      const { data, error: rpcError } = await supabase.rpc('rechazar_registro_familia', {
        p_id_familia: idFamilia,
        p_motivo: motivoLimpio,
      })

      if (rpcError) {
        if (!esRpcInexistente(rpcError)) throw rpcError
        await rechazarRegistroFallback(idFamilia, motivoLimpio)
      }

      await cargarRegistros()
      return data || true
    } catch (err) {
      console.error('[SIGAS] Error rechazando registro:', err)
      error.value = mensajeError(err, 'No se pudo rechazar el registro.')
      throw err
    } finally {
      accionLoading.value = false
    }
  }

  async function rechazarRegistroFallback(idFamilia, motivo) {
    const registro = registros.value.find((item) => item.id === idFamilia)
    if (!registro) throw new Error('El registro no está disponible.')

    const { error: updateError } = await supabase
      .from('familias')
      .update({
        estado: 'rechazado',
        activo: false,
        notas_rechazo: motivo,
        updated_at: new Date().toISOString(),
      })
      .eq('id', idFamilia)

    if (updateError) throw updateError

    if (registro.auth_id) {
      await supabase.from('notificaciones').insert([
        {
          destinatario_auth_id: registro.auth_id,
          id_familia: registro.id,
          tipo: 'registro_rechazado',
          titulo: 'Registro rechazado',
          mensaje: `Tu registro fue rechazado. Motivo: ${motivo}`,
          metadata: { id_familia: registro.id, motivo },
        },
      ])
    }
  }

  async function actualizarRegistro(idFamilia, datos) {
    accionLoading.value = true
    error.value = ''
    try {
      const nombre = limpiarNombre(datos.nombre, 120)
      const telefono = limpiarDigitos(datos.telefono, 12)
      const direccion = limpiarTexto(datos.direccion, 200)

      const errores = [
        validarNombre(nombre, { label: 'El nombre', max: 120 }),
        validarTelefono(telefono, { label: 'El teléfono', required: false, min: 7, max: 12 }),
        validarTexto(direccion, { label: 'La dirección', max: 200 }),
        validarEntero(datos.personas, { label: 'El número de personas', min: 1, max: 30 }),
      ]

      const primerError = errores.find(Boolean)
      if (primerError) throw new Error(primerError)

      const payload = {
        p_id_familia: idFamilia,
        p_nombre: nombre,
        p_telefono: telefono || null,
        p_direccion: direccion || null,
        p_personas: datos.personas ? Number(datos.personas) : null,
        p_id_calle: datos.id_calle ? Number(datos.id_calle) : null,
      }

      const { data, error: rpcError } = await supabase.rpc(
        'actualizar_registro_familia',
        payload
      )

      if (rpcError) {
        if (!esRpcInexistente(rpcError)) throw rpcError
        await actualizarRegistroFallback(idFamilia, payload)
      }

      await Promise.all([cargarRegistros(), cargarJefesFamilia()])
      return data || true
    } catch (err) {
      console.error('[SIGAS] Error actualizando registro:', err)
      error.value = mensajeError(err, 'No se pudo modificar el registro.')
      throw err
    } finally {
      accionLoading.value = false
    }
  }

  async function actualizarRegistroFallback(idFamilia, payload) {
    const { error: updateError } = await supabase
      .from('familias')
      .update({
        nombre_familia: payload.p_nombre,
        telefono: payload.p_telefono,
        direccion: payload.p_direccion,
        num_personas: payload.p_personas,
        id_calle: payload.p_id_calle || calleId.value,
        updated_at: new Date().toISOString(),
      })
      .eq('id', idFamilia)

    if (updateError) throw updateError
  }

  async function darBajaJefeFamilia(idJefeFamilia) {
    accionLoading.value = true
    error.value = ''
    try {
      const { data, error: rpcError } = await supabase.rpc('dar_baja_jefe_familia', {
        p_id_jefe_familia: idJefeFamilia,
      })

      if (rpcError) {
        if (!esRpcInexistente(rpcError)) throw rpcError
        const { error: updateError } = await supabase
          .from('jefes_familia')
          .update({
            activo: false,
            is_deleted: true,
            deleted_at: new Date().toISOString(),
            updated_at: new Date().toISOString(),
          })
          .eq('id_jefe_familia', idJefeFamilia)
        if (updateError) throw updateError
      }

      await Promise.all([cargarRegistros(), cargarJefesFamilia()])
      return data || true
    } catch (err) {
      console.error('[SIGAS] Error dando de baja al jefe de familia:', err)
      error.value = mensajeError(err, 'No se pudo dar de baja al Jefe de Familia.')
      throw err
    } finally {
      accionLoading.value = false
    }
  }

  function familiaDeJefe(item) {
    return registros.value.find((registro) => registro.id === item.id_familia) || null
  }

  return {
    jefe,
    calleId,
    registros,
    jefesFamilia,
    calles,
    loading,
    error,
    accionLoading,
    pendientes,
    aprobados,
    rechazados,
    jefesActivos,
    cargarTodo,
    cargarRegistros,
    cargarJefesFamilia,
    verificarJefeActivo,
    aprobarRegistro,
    rechazarRegistro,
    actualizarRegistro,
    darBajaJefeFamilia,
    familiaDeJefe,
  }
}
