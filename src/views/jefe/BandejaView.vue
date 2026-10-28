<template>
<<<<<<< HEAD
  <div class="space-y-6">
    <div>
      <h2 class="text-xl font-medium text-gray-700">Bandeja de Solicitudes</h2>
      <p class="text-sm text-gray-500">Acepta o rechaza solicitudes de tu calle</p>
=======
  <div class="bandeja-page">
    <header class="page-banner">
      <div class="banner-copy">
        <span class="banner-eyebrow">
          <span class="pulse-dot" aria-hidden="true" />
          Gestión de calle
        </span>
        <h1>Bandeja de Solicitudes</h1>
        <p>
          Revisa y responde las solicitudes de bombonas de las familias de
          {{ jefe?.calle?.nombre || 'tu calle' }}. Cada decisión queda registrada.
        </p>
      </div>
      <button type="button" class="btn-refresh" :disabled="loading" @click="cargarTodo">
        <svg viewBox="0 0 24 24" class="refresh-icon" :class="{ spin: loading }" aria-hidden="true">
          <path fill="currentColor" d="M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6 0 1.01-.25 1.97-.7 2.8l1.46 1.46A7.93 7.93 0 0 0 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6 0-1.01.25-1.97.7-2.8L5.24 7.74A7.93 7.93 0 0 0 4 12c0 4.42 3.58 8 8 8v3l4-4-4-4v3" />
        </svg>
        {{ loading ? 'Actualizando…' : 'Actualizar' }}
      </button>
    </header>

    <div v-if="!loading && !jefe" class="alert alert--warning" role="alert">
      <strong>No se encontró tu perfil de Jefe de Calle.</strong>
      Pide a un administrador que asocie tu cuenta a una calle para recibir solicitudes.
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)
    </div>

    <div v-if="!loading && jefe && !calleId" class="alert alert--warning" role="alert">
      <strong>Tu perfil aún no tiene una calle asignada.</strong>
      Un administrador debe asignarte una calle para que puedas gestionar solicitudes.
    </div>

    <div v-if="error && !confirmOpen" class="alert alert--error" role="alert">{{ error }}</div>
    <div v-if="success" class="alert alert--success" role="status">{{ success }}</div>

    <template v-if="jefe && calleId">
      <section class="stats-grid" aria-label="Resumen de solicitudes">
        <article class="stat-card stat-card--amber">
          <span class="stat-icon" aria-hidden="true">⏳</span>
          <div>
            <p class="stat-label">Pendientes</p>
            <p class="stat-value">{{ pendientes.length }}</p>
          </div>
        </article>
        <article class="stat-card stat-card--blue">
          <span class="stat-icon" aria-hidden="true">✓</span>
          <div>
            <p class="stat-label">Aceptadas</p>
            <p class="stat-value">{{ aceptadas.length }}</p>
          </div>
        </article>
        <article class="stat-card stat-card--green">
          <span class="stat-icon" aria-hidden="true">📦</span>
          <div>
            <p class="stat-label">Entregadas</p>
            <p class="stat-value">{{ entregadas.length }}</p>
          </div>
        </article>
        <article class="stat-card stat-card--red">
          <span class="stat-icon" aria-hidden="true">×</span>
          <div>
            <p class="stat-label">Rechazadas</p>
            <p class="stat-value">{{ rechazadas.length }}</p>
          </div>
        </article>
      </section>

      <section class="filter-card" aria-label="Buscar solicitudes">
        <label class="search-field">
          <span class="sr-only">Buscar solicitud</span>
          <svg viewBox="0 0 24 24" aria-hidden="true">
            <path fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" d="m21 21-4.35-4.35M19 11a8 8 0 1 1-16 0 8 8 0 0 1 16 0z" />
          </svg>
          <input
            v-model="filtroBusqueda"
            type="search"
            placeholder="Buscar por familia, tipo de bombona o fecha…"
          />
        </label>
      </section>

      <div v-if="loading" class="state-panel">
        <span class="spinner" aria-hidden="true" />
        <p>Cargando solicitudes de tu calle…</p>
      </div>

      <div v-else-if="pendientesFiltradas.length === 0" class="state-panel state-panel--empty">
        <span class="empty-icon" aria-hidden="true">📭</span>
        <strong>No hay solicitudes pendientes</strong>
        <p>
          {{ filtroBusqueda ? 'Prueba con otra búsqueda.' : 'Cuando una familia de tu calle solicite gas, aparecerá aquí.' }}
        </p>
      </div>

      <div v-else class="requests-list">
        <article v-for="solicitud in pendientesFiltradas" :key="solicitud.id_pedido" class="request-card">
          <div class="request-head">
            <span class="request-avatar" aria-hidden="true">{{ inicial(solicitud.familia) }}</span>
            <div class="request-title">
              <h2>{{ solicitud.familia }}</h2>
              <p>{{ solicitud.calle }} · Solicitud #{{ solicitud.id_pedido }}</p>
            </div>
            <span class="status-pill is-pending">Pendiente</span>
          </div>

          <div class="request-details">
            <div>
              <span>Bombona</span>
              <strong>{{ solicitud.tipo }}</strong>
            </div>
            <div>
              <span>Pico</span>
              <strong>{{ solicitud.pico }}</strong>
            </div>
            <div>
              <span>Fecha</span>
              <strong>{{ solicitud.fecha }}</strong>
            </div>
          </div>

          <div class="request-actions">
            <button type="button" class="btn-action btn-action--success" @click="abrirConfirmacion(solicitud, 'aceptar')">
              Aceptar
            </button>
            <button type="button" class="btn-action btn-action--danger" @click="abrirConfirmacion(solicitud, 'rechazar')">
              Rechazar
            </button>
          </div>
        </article>
      </div>
    </template>

    <ConfirmDialog
      v-model="confirmOpen"
      :title="confirmTitle"
      :message="confirmMessage"
      :confirm-text="confirmText"
      :confirm-variant="confirmAction === 'aceptar' ? 'success' : 'danger'"
      :tone="confirmAction === 'aceptar' ? 'success' : 'danger'"
      :loading="accionLoading"
      :error="confirmError"
      :confirm-disabled="confirmAction === 'rechazar' && !motivo.trim()"
      @confirm="ejecutarConfirmacion"
    >
<<<<<<< HEAD
      <template #cell-estatus="{ row }">
        <StatusBadge :status="row.estatus" />
      </template>
      <template #actions="{ row }">
        <template v-if="row.estatus === 'pendiente'">
          <BaseButton size="sm" variant="success" @click="openAccept(row)">Aceptar</BaseButton>
          <BaseButton size="sm" variant="danger" @click="openReject(row)">Rechazar</BaseButton>
        </template>
        <span v-else-if="row.estatus === 'aceptado'" class="text-xs text-blue-600 font-medium">Aceptado</span>
        <span v-else class="text-xs text-gray-500">Sin acción</span>
      </template>
    </CrudDataTable>

    <!-- Modal para Confirmar Aceptación -->
    <ModalDialog
      v-model="showAccept"
      title="Aceptar solicitud"
      :message="`¿Confirmas que deseas aceptar la solicitud de la familia ${selected?.familia || ''}? Esta acción cambiará el estado a Aceptado y se incluirá en la jornada de distribución.`"
      confirm-text="Aceptar Solicitud"
      confirm-variant="success"
      @confirm="confirmarAceptacion"
    />

    <!-- Modal para Rechazar -->
    <ModalDialog
      v-model="showReject"
      title="Rechazar solicitud"
      message="Indica el motivo del rechazo. Esta acción actualizará el estatus."
      confirm-text="Rechazar"
      confirm-variant="danger"
      @confirm="confirmarRechazo"
    />
=======
      <div v-if="confirmAction === 'rechazar'" class="dialog-field">
        <label for="motivo-rechazo">Motivo del rechazo</label>
        <textarea
          id="motivo-rechazo"
          v-model="motivo"
          rows="3"
          maxlength="500"
          placeholder="Explica brevemente por qué se rechaza la solicitud…"
        />
        <small>El motivo quedará guardado en el pedido y podrá consultarse.</small>
      </div>
    </ConfirmDialog>
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import ConfirmDialog from '../../components/ui/ConfirmDialog.vue'
import { supabase } from '../../lib/supabase.js'
import { usePedidos } from '../../composables/usePedidos.js'

const { pedidos, fetchPedidos, updateStatus, error: errorPedidos } = usePedidos()

<<<<<<< HEAD
const showAccept = ref(false)
const showReject = ref(false)
const selected = ref(null)
=======
const jefe = ref(null)
const calleId = ref(null)
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)
const loading = ref(true)
const accionLoading = ref(false)
const error = ref('')
const success = ref('')
const filtroBusqueda = ref('')
let successTimer = null

const confirmOpen = ref(false)
const confirmAction = ref('')
const confirmError = ref('')
const seleccionada = ref(null)
const motivo = ref('')

const pedidosCalle = computed(() => {
  if (!calleId.value) return []
  return pedidos.value.filter((pedido) => {
    const familia = pedido.familia || pedido.familias
    if (!familia) return false
    if (familia.is_deleted) return false
    return Number(familia.id_calle) === Number(calleId.value)
  })
})

const pendientes = computed(() =>
  pedidosCalle.value.filter((pedido) => String(pedido.status || '').toLowerCase() === 'pendiente')
)
const aceptadas = computed(() =>
  pedidosCalle.value.filter((pedido) => String(pedido.status || '').toLowerCase() === 'aceptado')
)
const entregadas = computed(() =>
  pedidosCalle.value.filter((pedido) => String(pedido.status || '').toLowerCase() === 'entregado')
)
const rechazadas = computed(() =>
  pedidosCalle.value.filter((pedido) => String(pedido.status || '').toLowerCase() === 'rechazado')
)

const pendientesFiltradas = computed(() => {
  const q = filtroBusqueda.value.trim().toLowerCase()
  return pendientes.value
    .map((pedido) => ({
      id_pedido: pedido.id_pedido,
      familia: pedido.familia?.nombre_familia || pedido.familias?.nombre_familia || 'Familia sin nombre',
      calle: nombreCalle(pedido.familia?.id_calle || pedido.familias?.id_calle),
      tipo: `Bombona ${pedido.tipo_bombona || '—'}`,
      pico: pedido.pico || '—',
      fecha: formatearFecha(pedido.fecha_solicitud || pedido.created_at),
      status: pedido.status,
      original: pedido,
    }))
    .filter((solicitud) => {
      if (!q) return true
      return [solicitud.familia, solicitud.tipo, solicitud.pico, solicitud.fecha]
        .some((value) => String(value || '').toLowerCase().includes(q))
    })
})

const confirmTitle = computed(() =>
  confirmAction.value === 'aceptar' ? 'Aceptar solicitud de bombona' : 'Rechazar solicitud de bombona'
)

const confirmMessage = computed(() => {
  const solicitud = seleccionada.value
  if (!solicitud) return ''
  if (confirmAction.value === 'aceptar') {
    return `¿Aceptar la solicitud #${solicitud.id_pedido} de ${solicitud.familia}? La familia podrá continuar con el proceso de entrega.`
  }
  return `¿Rechazar la solicitud #${solicitud.id_pedido} de ${solicitud.familia}? Indica el motivo para dejar constancia.`
})

const confirmText = computed(() =>
  confirmAction.value === 'aceptar' ? 'Sí, aceptar' : 'Sí, rechazar'
)

onMounted(cargarTodo)

async function cargarTodo() {
  loading.value = true
  error.value = ''

  try {
    await Promise.all([cargarContexto(), fetchPedidos()])
    if (errorPedidos.value) throw new Error(errorPedidos.value)
  } catch (err) {
    console.error('[SIGAS] Error cargando bandeja:', err)
    error.value = mensajeError(err, 'No se pudieron cargar las solicitudes.')
  } finally {
    loading.value = false
  }
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
    return
  }

  let idCalle = jefe.value.id_calle || null

  if (!idCalle) {
    const { data: callesData } = await supabase
      .from('calles')
      .select('id_calle, nombre')
      .eq('id_jefe_calle', jefe.value.id_jefe_calle)
      .eq('is_deleted', false)
      .limit(1)

    idCalle = callesData?.[0]?.id_calle || null
    if (callesData?.[0]?.nombre) {
      jefe.value = { ...jefe.value, calle: callesData[0] }
    }
  }

  calleId.value = idCalle

  if (idCalle && !jefe.value.calle) {
    const { data: calleData } = await supabase
      .from('calles')
      .select('id_calle, nombre')
      .eq('id_calle', idCalle)
      .maybeSingle()

    if (calleData) jefe.value = { ...jefe.value, calle: calleData }
  }
}

function abrirConfirmacion(solicitud, accion) {
  seleccionada.value = solicitud
  confirmAction.value = accion
  motivo.value = ''
  confirmError.value = ''
  confirmOpen.value = true
}

async function ejecutarConfirmacion() {
  if (!seleccionada.value) return
  confirmError.value = ''

  if (confirmAction.value === 'rechazar' && !motivo.value.trim()) {
    confirmError.value = 'Indica el motivo del rechazo.'
    return
  }

  accionLoading.value = true

  try {
    const extra = confirmAction.value === 'rechazar'
      ? { motivo_rechazo: motivo.value.trim() }
      : {}

    const result = await updateStatus(
      seleccionada.value.id_pedido,
      confirmAction.value === 'aceptar' ? 'aceptado' : 'rechazado',
      extra
    )

    if (!result) {
      throw new Error(errorPedidos.value || 'No se pudo actualizar la solicitud.')
    }

    const mensaje = confirmAction.value === 'aceptar'
      ? `Solicitud #${seleccionada.value.id_pedido} aceptada.`
      : `Solicitud #${seleccionada.value.id_pedido} rechazada.`

    confirmOpen.value = false
    mostrarExito(mensaje)
    seleccionada.value = null
    await fetchPedidos()
  } catch (err) {
    console.error('[SIGAS] Error actualizando solicitud:', err)
    confirmError.value = mensajeError(err, 'No se pudo actualizar la solicitud.')
  } finally {
    accionLoading.value = false
  }
}

function mostrarExito(mensaje) {
  success.value = mensaje
  if (successTimer) window.clearTimeout(successTimer)
  successTimer = window.setTimeout(() => {
    success.value = ''
  }, 5000)
}

function nombreCalle(idCalle) {
  if (!idCalle) return 'Sin calle'
  if (jefe.value?.calle?.id_calle === idCalle) return jefe.value.calle.nombre
  return `Calle ID ${idCalle}`
}

function inicial(nombre) {
  return String(nombre || 'F').trim().charAt(0).toUpperCase() || 'F'
}

function formatearFecha(fecha) {
  if (!fecha) return '—'
  const date = new Date(fecha)
  if (Number.isNaN(date.getTime())) return '—'
  return date.toLocaleDateString('es-VE', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  })
}

<<<<<<< HEAD
// Abrir modal de aceptación
function openAccept(row) {
  selected.value = row
  showAccept.value = true
}

// Confirmar actualización a 'aceptado'
async function confirmarAceptacion() {
  if (!selected.value) return
  loading.value = true
  await updateStatus(selected.value._original.id_pedido, 'aceptado')
  await fetchPedidos()
  selected.value = null
  loading.value = false
}

// Abrir modal de rechazo
function openReject(row) {
  selected.value = row
  showReject.value = true
}

// Confirmar actualización a 'rechazado'
async function confirmarRechazo() {
  if (!selected.value) return
  loading.value = true
  await updateStatus(selected.value._original.id_pedido, 'rechazado')
  await fetchPedidos()
  selected.value = null
  loading.value = false
=======
function mensajeError(err, fallback = 'No se pudo completar la acción.') {
  const mensaje = String(err?.message || err?.details || '')
  if (/No tienes permiso|42501|row-level security/i.test(mensaje)) {
    return 'No tienes permisos para gestionar esta solicitud.'
  }
  if (/motivo_rechazo/i.test(mensaje) && /column|schema cache/i.test(mensaje)) {
    return 'Falta la columna motivo_rechazo. Ejecuta la migración de SIGAS en Supabase.'
  }
  return mensaje || fallback
}
</script>

<style scoped>
.bandeja-page {
  display: flex;
  flex-direction: column;
  gap: 18px;
  color: #0f172a;
}

.page-banner {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 22px 18px;
  overflow: hidden;
  border: 1px solid #dbeafe;
  border-radius: 20px;
  background:
    radial-gradient(circle at 92% 8%, rgba(34, 211, 238, 0.22), transparent 32%),
    linear-gradient(135deg, #ffffff 0%, #f0f9ff 58%, #e0f2fe 100%);
  box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
}

.banner-eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  width: fit-content;
  padding: 5px 11px;
  border: 1px solid #bfdbfe;
  border-radius: 999px;
  background: #eff6ff;
  color: #0369a1;
  font-size: 0.7rem;
  font-weight: 800;
  letter-spacing: 0.06em;
  text-transform: uppercase;
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)
}

.pulse-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #0ea5e9;
  box-shadow: 0 0 0 4px rgba(14, 165, 233, 0.14);
  animation: pulse 2s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% { transform: scale(0.92); opacity: 0.8; }
  50% { transform: scale(1.18); opacity: 1; }
}

.banner-copy h1 {
  margin: 12px 0 0;
  color: #0f172a;
  font-size: 1.55rem;
  font-weight: 800;
  letter-spacing: -0.025em;
  line-height: 1.2;
}

.banner-copy p {
  max-width: 700px;
  margin: 7px 0 0;
  color: #64748b;
  font-size: 0.88rem;
  line-height: 1.55;
}

.btn-refresh {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  min-height: 44px;
  padding: 0 16px;
  border: 1px solid #bae6fd;
  border-radius: 12px;
  background: #ffffff;
  color: #0369a1;
  font: inherit;
  font-size: 0.84rem;
  font-weight: 700;
  cursor: pointer;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
}

.btn-refresh:hover:not(:disabled) {
  background: #f0f9ff;
}

.btn-refresh:disabled {
  opacity: 0.65;
  cursor: wait;
}

.refresh-icon {
  width: 17px;
  height: 17px;
}

.refresh-icon.spin {
  animation: spin 0.9s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.alert {
  padding: 12px 14px;
  border: 1px solid transparent;
  border-radius: 12px;
  font-size: 0.85rem;
  line-height: 1.5;
}

.alert strong {
  font-weight: 700;
}

.alert--warning {
  border-color: #fde68a;
  background: #fffbeb;
  color: #92400e;
}

.alert--error {
  border-color: #fecaca;
  background: #fef2f2;
  color: #b91c1c;
}

.alert--success {
  border-color: #a7f3d0;
  background: #ecfdf5;
  color: #047857;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
}

.stat-card {
  display: flex;
  align-items: center;
  gap: 11px;
  min-width: 0;
  padding: 13px;
  border: 1px solid #e2e8f0;
  border-radius: 15px;
  background: #ffffff;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.03);
}

.stat-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 38px;
  height: 38px;
  border-radius: 11px;
  background: #f1f5f9;
  font-size: 1rem;
}

.stat-card--amber .stat-icon { background: #fffbeb; color: #b45309; }
.stat-card--blue .stat-icon { background: #eff6ff; color: #1d4ed8; }
.stat-card--green .stat-icon { background: #ecfdf5; color: #047857; }
.stat-card--red .stat-icon { background: #fef2f2; color: #b91c1c; }

.stat-label {
  margin: 0;
  color: #64748b;
  font-size: 0.68rem;
  font-weight: 700;
  letter-spacing: 0.03em;
  line-height: 1.3;
  text-transform: uppercase;
}

.stat-value {
  margin: 2px 0 0;
  color: #0f172a;
  font-size: 1.45rem;
  font-weight: 800;
  line-height: 1.1;
  font-variant-numeric: tabular-nums;
}

.filter-card {
  padding: 13px;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  background: #ffffff;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.03);
}

.search-field {
  position: relative;
  display: flex;
  align-items: center;
}

.search-field svg {
  position: absolute;
  left: 12px;
  width: 17px;
  height: 17px;
  color: #94a3b8;
  pointer-events: none;
}

.search-field input {
  width: 100%;
  min-height: 44px;
  padding: 0 12px 0 38px;
  border: 1px solid #d1d5db;
  border-radius: 11px;
  background: #f8fafc;
  color: #0f172a;
  font: inherit;
  font-size: 16px;
  outline: none;
  transition: border-color 150ms ease, box-shadow 150ms ease, background-color 150ms ease;
}

.search-field input:focus {
  border-color: #0ea5e9;
  background: #ffffff;
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.14);
}

.state-panel {
  display: grid;
  justify-items: center;
  gap: 8px;
  padding: 38px 18px;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  background: #ffffff;
  color: #64748b;
  text-align: center;
}

.state-panel p {
  margin: 0;
  font-size: 0.84rem;
  line-height: 1.5;
}

.state-panel strong {
  color: #0f172a;
  font-size: 0.9rem;
}

.state-panel--empty {
  border-style: dashed;
  background: #f8fafc;
}

.empty-icon {
  font-size: 1.8rem;
}

.spinner {
  width: 28px;
  height: 28px;
  border: 3px solid #e2e8f0;
  border-top-color: #0ea5e9;
  border-radius: 50%;
  animation: spin 0.9s linear infinite;
}

.requests-list {
  display: grid;
  gap: 12px;
}

.request-card {
  padding: 15px;
  border: 1px solid #e2e8f0;
  border-radius: 17px;
  background: #ffffff;
  box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
  transition: border-color 160ms ease, box-shadow 160ms ease, transform 160ms ease;
}

.request-card:hover {
  border-color: #bae6fd;
  box-shadow: 0 8px 24px -14px rgba(14, 165, 233, 0.35);
  transform: translateY(-1px);
}

.request-head {
  display: flex;
  align-items: flex-start;
  gap: 11px;
}

.request-avatar {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 42px;
  height: 42px;
  border-radius: 13px;
  background: #eff6ff;
  color: #1d4ed8;
  font-size: 0.95rem;
  font-weight: 800;
}

.request-title {
  min-width: 0;
  flex: 1;
}

.request-title h2 {
  margin: 0;
  overflow: hidden;
  color: #0f172a;
  font-size: 0.95rem;
  font-weight: 800;
  line-height: 1.3;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.request-title p {
  margin: 3px 0 0;
  overflow: hidden;
  color: #64748b;
  font-size: 0.76rem;
  line-height: 1.4;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.status-pill {
  display: inline-flex;
  flex-shrink: 0;
  align-items: center;
  padding: 4px 9px;
  border: 1px solid #fde68a;
  border-radius: 999px;
  background: #fffbeb;
  color: #b45309;
  font-size: 0.66rem;
  font-weight: 800;
  letter-spacing: 0.02em;
  white-space: nowrap;
}

.request-details {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 10px;
  margin-top: 13px;
  padding-top: 12px;
  border-top: 1px solid #f1f5f9;
}

.request-details span {
  display: block;
  color: #94a3b8;
  font-size: 0.65rem;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.request-details strong {
  display: block;
  margin-top: 2px;
  overflow: hidden;
  color: #334155;
  font-size: 0.8rem;
  font-weight: 600;
  line-height: 1.4;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.request-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 13px;
}

.btn-action {
  display: inline-flex;
  flex: 1 1 130px;
  align-items: center;
  justify-content: center;
  min-height: 44px;
  padding: 0 14px;
  border: 1px solid transparent;
  border-radius: 10px;
  font: inherit;
  font-size: 0.8rem;
  font-weight: 700;
  cursor: pointer;
  transition: background-color 150ms ease, color 150ms ease, border-color 150ms ease,
    transform 150ms ease;
}

.btn-action:active {
  transform: scale(0.98);
}

.btn-action--success {
  border-color: #059669;
  background: #ecfdf5;
  color: #047857;
}

.btn-action--success:hover {
  background: #059669;
  color: #ffffff;
}

.btn-action--danger {
  border-color: #dc2626;
  background: #fef2f2;
  color: #b91c1c;
}

.btn-action--danger:hover {
  background: #dc2626;
  color: #ffffff;
}

.dialog-field {
  display: grid;
  gap: 7px;
}

.dialog-field label {
  color: #334155;
  font-size: 0.8rem;
  font-weight: 700;
}

.dialog-field textarea {
  width: 100%;
  min-height: 96px;
  padding: 11px 12px;
  border: 1px solid #d1d5db;
  border-radius: 11px;
  background: #ffffff;
  color: #0f172a;
  font: inherit;
  font-size: 16px;
  line-height: 1.5;
  resize: vertical;
  outline: none;
}

.dialog-field textarea:focus {
  border-color: #0ea5e9;
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.14);
}

.dialog-field small {
  color: #64748b;
  font-size: 0.72rem;
  line-height: 1.4;
}

.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

@media (min-width: 640px) {
  .bandeja-page {
    gap: 22px;
  }

  .page-banner {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    padding: 26px 28px;
  }

  .banner-copy h1 {
    font-size: 1.85rem;
  }

  .btn-refresh {
    flex-shrink: 0;
  }

  .stats-grid {
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 14px;
  }

  .stat-card {
    padding: 16px;
  }

  .request-card {
    padding: 18px 20px;
  }

  .request-actions {
    justify-content: flex-end;
  }

  .btn-action {
    flex: 0 0 auto;
    min-width: 130px;
  }
}

@media (min-width: 1024px) {
  .page-banner {
    padding: 28px 32px;
  }

  .request-card {
    padding: 20px 24px;
  }
}

@media (prefers-reduced-motion: reduce) {
  .pulse-dot,
  .refresh-icon.spin,
  .spinner,
  .request-card {
    animation: none;
    transition: none;
  }
}
</style>
