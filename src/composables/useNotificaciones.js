import { computed, ref } from 'vue'
import { supabase } from '../lib/supabase.js'

const TABLE = 'notificaciones'
const LIMIT = 40

function normalizar(notificacion) {
  return {
    ...notificacion,
    leida: Boolean(notificacion.leida),
  }
}

export function useNotificaciones() {
  const notificaciones = ref([])
  const loading = ref(false)
  const error = ref('')
  const realtimeStatus = ref('idle')

  let channel = null
  let authId = null
  let authSubscription = null

  const noLeidas = computed(
    () => notificaciones.value.filter((notificacion) => !notificacion.leida).length
  )

  async function resolverAuthId(force = false) {
    if (authId && !force) return authId
    const { data, error: authError } = await supabase.auth.getUser()
    if (authError) {
      authId = null
      return null
    }
    authId = data?.user?.id || null
    return authId
  }

  async function cargarNotificaciones() {
    loading.value = true
    error.value = ''

    try {
      const id = await resolverAuthId(true)
      if (!id) {
        notificaciones.value = []
        return
      }

      const { data, error: queryError } = await supabase
        .from(TABLE)
        .select('*')
        .eq('destinatario_auth_id', id)
        .eq('is_deleted', false)
        .order('created_at', { ascending: false })
        .limit(LIMIT)

      if (queryError) throw queryError
      notificaciones.value = (data || []).map(normalizar)
    } catch (err) {
      console.error('[SIGAS] Error cargando notificaciones:', err)
      error.value = 'No se pudieron cargar las notificaciones.'
    } finally {
      loading.value = false
    }
  }

  async function marcarLeida(idNotificacion) {
    const id = await resolverAuthId()
    if (!id || !idNotificacion) return false

    const notificacion = notificaciones.value.find(
      (item) => item.id_notificacion === idNotificacion
    )
    if (!notificacion || notificacion.leida) return true

    const anterior = notificacion.leida
    notificacion.leida = true

    const { error: updateError } = await supabase
      .from(TABLE)
      .update({ leida: true, leida_at: new Date().toISOString() })
      .eq('id_notificacion', idNotificacion)
      .eq('destinatario_auth_id', id)

    if (updateError) {
      notificacion.leida = anterior
      console.error('[SIGAS] Error marcando notificación:', updateError)
      error.value = 'No se pudo marcar la notificación como leída.'
      return false
    }

    return true
  }

  async function marcarTodasLeidas() {
    const id = await resolverAuthId()
    if (!id) return false

    const pendientes = notificaciones.value.filter((item) => !item.leida)
    if (!pendientes.length) return true

    const estadosAnteriores = pendientes.map((item) => ({
      item,
      leida: item.leida,
    }))
    pendientes.forEach((item) => {
      item.leida = true
    })

    const { error: updateError } = await supabase
      .from(TABLE)
      .update({ leida: true, leida_at: new Date().toISOString() })
      .eq('destinatario_auth_id', id)
      .eq('leida', false)
      .eq('is_deleted', false)

    if (updateError) {
      estadosAnteriores.forEach(({ item, leida }) => {
        item.leida = leida
      })
      console.error('[SIGAS] Error marcando todas las notificaciones:', updateError)
      error.value = 'No se pudieron marcar las notificaciones como leídas.'
      return false
    }

    return true
  }

  async function eliminarNotificacion(idNotificacion) {
    const id = await resolverAuthId()
    if (!id) return false

    const anterior = notificaciones.value
    notificaciones.value = notificaciones.value.filter(
      (item) => item.id_notificacion !== idNotificacion
    )

    const { error: deleteError } = await supabase
      .from(TABLE)
      .update({ is_deleted: true, deleted_at: new Date().toISOString() })
      .eq('id_notificacion', idNotificacion)
      .eq('destinatario_auth_id', id)

    if (deleteError) {
      notificaciones.value = anterior
      error.value = 'No se pudo eliminar la notificación.'
      return false
    }

    return true
  }

  function aplicarCambio(payload) {
    if (payload.eventType === 'DELETE') {
      const vieja = payload.old || {}
      notificaciones.value = notificaciones.value.filter(
        (item) => item.id_notificacion !== vieja.id_notificacion
      )
      return
    }

    if (!payload?.new) return
    const nueva = normalizar(payload.new)
    const indice = notificaciones.value.findIndex(
      (item) => item.id_notificacion === nueva.id_notificacion
    )

    if (nueva.is_deleted) {
      notificaciones.value = notificaciones.value.filter(
        (item) => item.id_notificacion !== nueva.id_notificacion
      )
      return
    }

    if (indice >= 0) {
      notificaciones.value[indice] = nueva
    } else {
      notificaciones.value.unshift(nueva)
    }

    notificaciones.value.sort(
      (a, b) => new Date(b.created_at || 0).getTime() - new Date(a.created_at || 0).getTime()
    )
  }

  async function suscribir() {
    const id = await resolverAuthId(true)
    if (!id) return

    await desuscribir()

    realtimeStatus.value = 'connecting'
    channel = supabase
      .channel(`sigas-notificaciones-${id}`)
      .on(
        'postgres_changes',
        {
          event: '*',
          schema: 'public',
          table: TABLE,
          filter: `destinatario_auth_id=eq.${id}`,
        },
        (payload) => aplicarCambio(payload)
      )
      .subscribe((status) => {
        realtimeStatus.value = status
      })
  }

  async function desuscribir() {
    if (channel) {
      await supabase.removeChannel(channel)
      channel = null
    }
    realtimeStatus.value = 'idle'
  }

  async function iniciar() {
    await cargarNotificaciones()
    await suscribir()

    // Si Supabase renueva el token o cambia la sesión, reconectamos el canal.
    const { data } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED' || event === 'INITIAL_SESSION') {
        authId = null
        suscribir()
      }
      if (event === 'SIGNED_OUT') {
        notificaciones.value = []
        desuscribir()
      }
    })
    authSubscription = data?.subscription || null
  }

  async function detener() {
    if (authSubscription) {
      authSubscription.unsubscribe()
      authSubscription = null
    }
    await desuscribir()
  }

  return {
    notificaciones,
    noLeidas,
    loading,
    error,
    realtimeStatus,
    cargarNotificaciones,
    marcarLeida,
    marcarTodasLeidas,
    eliminarNotificacion,
    suscribir,
    desuscribir,
    iniciar,
    detener,
  }
}
