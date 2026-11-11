import { computed, ref } from 'vue'
import { supabase } from '../lib/supabase.js'
import {
  limpiarDigitos,
  limpiarEmail,
  limpiarNombre,
  limpiarTexto,
  validarEmail,
  validarEntero,
  validarNombre,
  validarTelefono,
  validarTexto,
} from '../lib/validation.js'

function mensajeError(err, fallback = 'No se pudo completar la acción.') {
  const mensaje = String(err?.message || err?.details || '')
  if (/ya tiene un Jefe de Familia activo/i.test(mensaje)) return mensaje
  if (/ya tiene una cuenta de acceso/i.test(mensaje)) return mensaje
  if (/ya está vinculada a otra familia/i.test(mensaje)) return mensaje
  if (/ya es Jefe de Familia de otra familia/i.test(mensaje)) return mensaje
  if (/El correo no coincide/i.test(mensaje)) return mensaje
  if (/uq_jefes_familia_activo|uq_familias_auth_activo|duplicate key/i.test(mensaje)) {
    return 'La familia o la cuenta ya están vinculadas a otro registro. Revisa los datos e intenta nuevamente.'
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
  const callesIds = ref([])
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

  // Familias de la calle que pueden recibir un nuevo Jefe de Familia:
  // sin jefe registrado, o con un jefe inactivo/rechazado que puede
  // reemplazarse. Un jefe activo o pendiente de cuenta ya ocupa el registro.
  const familiasSinJefe = computed(() =>
    registros.value.filter((familia) => {
      if (familia.is_deleted) return false

      const jefe = jefesFamilia.value.find(
        (item) => Number(item.id_familia) === Number(familia.id) && !item.is_deleted
      )

      if (!jefe) return true
      if (jefe.activo) return false
      return jefe.estado !== 'pendiente'
    })
  )

  function jefeDeFamilia(familia) {
    if (!familia) return null
    return (
      jefesFamilia.value.find(
        (jefe) => Number(jefe.id_familia) === Number(familia.id) && !jefe.is_deleted
      ) || null
    )
  }

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
      callesIds.value = []
      return
    }

    // Todas las calles asignadas viven en calles.id_jefe_calle. Se conserva
    // jefe_de_calle.id_calle como calle principal y fallback de compatibilidad.
    const { data: callesAsignadas } = await supabase
      .from('calles')
      .select('id_calle, nombre')
      .eq('id_jefe_calle', jefe.value.id_jefe_calle)
      .eq('is_deleted', false)
      .order('nombre')

    let ids = (callesAsignadas || []).map((calle) => Number(calle.id_calle))

    if (ids.length === 0 && jefe.value.id_calle) {
      ids = [Number(jefe.value.id_calle)]
    }

    callesIds.value = ids
    calleId.value = ids[0] || null

    const { data: callesData } = await supabase
      .from('calles')
      .select('id_calle, nombre')
      .eq('is_deleted', false)
      .order('nombre')

    calles.value = callesData || []
  }

  async function cargarRegistros() {
    if (callesIds.value.length === 0) {
      registros.value = []
      return
    }

    const { data, error: queryError } = await supabase
      .from('familias')
      .select('*')
      .in('id_calle', callesIds.value)
      // Familias censadas antes de que existiera id_cargo quedaron con
      // id_cargo nulo. Deben seguir apareciendo para poder registrar a su
      // Jefe de Familia.
      .or('id_cargo.eq.3,id_cargo.is.null')
      .eq('is_deleted', false)
      .order('id', { ascending: false })

    if (queryError) throw queryError
    registros.value = data || []
  }

  async function cargarJefesFamilia() {
    if (callesIds.value.length === 0) {
      jefesFamilia.value = []
      return
    }

    const { data, error: queryError } = await supabase
      .from('jefes_familia')
      .select('*')
      .in('id_calle', callesIds.value)
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
      if (callesIds.value.length > 0) {
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

    const { data: jefeExistente, error: jefeError } = await supabase
      .from('jefes_familia')
      .select('*')
      .eq('id_familia', idFamilia)
      .eq('is_deleted', false)
      .order('activo', { ascending: false })
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (jefeError) throw jefeError
    if (jefeExistente?.activo) return jefeExistente

    const datosJefe = {
      id_familia: registro.id,
      auth_id: registro.auth_id || jefeExistente?.auth_id || null,
      id_calle: registro.id_calle,
      nombre: jefeExistente?.nombre || registro.nombre_familia,
      ci: jefeExistente?.ci || String(registro.id),
      telefono: jefeExistente?.telefono || registro.telefono,
      activo: true,
      estado: 'aprobado',
      is_deleted: false,
    }

    let nuevoJefe = null
    if (jefeExistente) {
      const { data, error: updateJefeError } = await supabase
        .from('jefes_familia')
        .update(datosJefe)
        .eq('id_jefe_familia', jefeExistente.id_jefe_familia)
        .select('id_jefe_familia')
        .single()
      if (updateJefeError) throw updateJefeError
      nuevoJefe = data
    } else {
      const { data, error: insertError } = await supabase
        .from('jefes_familia')
        .insert([datosJefe])
        .select('id_jefe_familia')
        .single()
      if (insertError) throw insertError
      nuevoJefe = data
    }

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

  async function registrarJefeFamilia(datos) {
    accionLoading.value = true
    error.value = ''
    try {
      const nombre = limpiarNombre(datos.nombre, 120)
      const telefono = limpiarDigitos(datos.telefono, 12)
      const email = limpiarEmail(datos.email, 254)

      const errores = [
        validarNombre(nombre, { label: 'El nombre del Jefe de Familia', max: 120 }),
        validarTelefono(telefono, { label: 'El teléfono', required: false, min: 7, max: 12 }),
        validarEmail(email, { label: 'El correo electrónico' }),
      ]

      const primerError = errores.find(Boolean)
      if (primerError) throw new Error(primerError)

      if (!datos.id_familia) {
        throw new Error('Selecciona la familia a la que pertenece el Jefe de Familia.')
      }

      const payload = {
        p_id_familia: Number(datos.id_familia),
        p_nombre: nombre,
        p_telefono: telefono || null,
        p_email: email,
        p_auth_id: null,
      }

      const { data, error: rpcError } = await supabase.rpc('registrar_jefe_familia', payload)

      if (rpcError) {
        if (!esRpcInexistente(rpcError)) throw rpcError
        await registrarJefeFamiliaFallback(payload)
      }

      await Promise.all([cargarRegistros(), cargarJefesFamilia()])
      return data || true
    } catch (err) {
      console.error('[SIGAS] Error registrando Jefe de Familia:', err)
      error.value = mensajeError(err, 'No se pudo registrar el Jefe de Familia.')
      throw err
    } finally {
      accionLoading.value = false
    }
  }

  async function registrarJefeFamiliaFallback(payload) {
    const registro = registros.value.find(
      (item) => Number(item.id) === Number(payload.p_id_familia)
    )
    if (!registro) throw new Error('La familia no está disponible.')

    const { data: jefeExistente, error: jefeError } = await supabase
      .from('jefes_familia')
      .select('*')
      .eq('id_familia', registro.id)
      .eq('is_deleted', false)
      .order('activo', { ascending: false })
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (jefeError) throw jefeError
    if (jefeExistente?.activo) {
      throw new Error('La familia ya tiene un Jefe de Familia activo.')
    }

    const datosJefe = {
      id_familia: registro.id,
      // Si el registro previo ya tenía una cuenta vinculada, no se pierde al
      // reemplazar los datos de contacto.
      auth_id: jefeExistente?.auth_id ?? null,
      id_calle: registro.id_calle,
      nombre: payload.p_nombre,
      ci: String(registro.id),
      telefono: payload.p_telefono,
      activo: false,
      estado: 'pendiente',
      is_deleted: false,
    }

    if (jefeExistente) {
      const { error: updateError } = await supabase
        .from('jefes_familia')
        .update(datosJefe)
        .eq('id_jefe_familia', jefeExistente.id_jefe_familia)
      if (updateError) throw updateError
    } else {
      const { error: insertError } = await supabase
        .from('jefes_familia')
        .insert([datosJefe])
      if (insertError) throw insertError
    }

    if (payload.p_email) {
      const { error: emailError } = await supabase
        .from('familias')
        .update({ email: payload.p_email, updated_at: new Date().toISOString() })
        .eq('id', registro.id)
        .is('auth_id', null)
      if (emailError) throw emailError
    }

    return true
  }

  async function actualizarJefeFamilia(datos) {
    accionLoading.value = true
    error.value = ''
    try {
      const nombre = limpiarNombre(datos.nombre, 120)
      const telefono = limpiarDigitos(datos.telefono, 12)
      const email = limpiarEmail(datos.email, 254)

      const errores = [
        validarNombre(nombre, { label: 'El nombre del Jefe de Familia', max: 120 }),
        validarTelefono(telefono, { label: 'El teléfono', required: false, min: 7, max: 12 }),
        validarEmail(email, { label: 'El correo electrónico' }),
      ]

      const primerError = errores.find(Boolean)
      if (primerError) throw new Error(primerError)

      if (!datos.id_jefe_familia) {
        throw new Error('No se identificó al Jefe de Familia.')
      }

      const payload = {
        p_id_jefe_familia: Number(datos.id_jefe_familia),
        p_nombre: nombre,
        p_telefono: telefono || null,
        p_email: email,
      }

      const { data, error: rpcError } = await supabase.rpc(
        'actualizar_jefe_familia',
        payload
      )

      if (rpcError) {
        if (!esRpcInexistente(rpcError)) throw rpcError
        await actualizarJefeFamiliaFallback(payload, datos.id_familia)
      }

      await Promise.all([cargarRegistros(), cargarJefesFamilia()])
      return data || true
    } catch (err) {
      console.error('[SIGAS] Error actualizando Jefe de Familia:', err)
      error.value = mensajeError(err, 'No se pudo actualizar el Jefe de Familia.')
      throw err
    } finally {
      accionLoading.value = false
    }
  }

  async function actualizarJefeFamiliaFallback(payload, idFamilia) {
    const { error: jefeError } = await supabase
      .from('jefes_familia')
      .update({
        nombre: payload.p_nombre,
        telefono: payload.p_telefono,
        updated_at: new Date().toISOString(),
      })
      .eq('id_jefe_familia', payload.p_id_jefe_familia)

    if (jefeError) throw jefeError

    if (idFamilia) {
      const { error: familiaError } = await supabase
        .from('familias')
        .update({
          email: payload.p_email,
          updated_at: new Date().toISOString(),
        })
        .eq('id', idFamilia)

      if (familiaError) throw familiaError
    }
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
    if (!item) return null
    return (
      registros.value.find(
        (registro) => Number(registro.id) === Number(item.id_familia)
      ) || null
    )
  }

  return {
    jefe,
    calleId,
    callesIds,
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
    familiasSinJefe,
    cargarTodo,
    cargarRegistros,
    cargarJefesFamilia,
    verificarJefeActivo,
    aprobarRegistro,
    rechazarRegistro,
    actualizarRegistro,
    registrarJefeFamilia,
    actualizarJefeFamilia,
    darBajaJefeFamilia,
    familiaDeJefe,
    jefeDeFamilia,
  }
}
