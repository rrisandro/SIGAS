<template>
  <div class="registros-page">
    <header class="page-banner">
      <div class="banner-copy">
        <span class="banner-eyebrow">
          <span class="pulse-dot" aria-hidden="true" />
          Gestión de calle
        </span>
        <h1>Registros de Familias</h1>
        <p>
          Acepta, modifica o rechaza las solicitudes de registro de tu zona.
          Cada familia puede tener un único Jefe de Familia activo.
        </p>
      </div>
      <button type="button" class="btn-refresh" :disabled="loading" @click="cargarTodo">
        <svg viewBox="0 0 24 24" class="refresh-icon" :class="{ spin: loading }" aria-hidden="true">
          <path fill="currentColor" d="M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6 0 1.01-.25 1.97-.7 2.8l1.46 1.46A7.93 7.93 0 0 0 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6 0-1.01.25-1.97.7-2.8L5.24 7.74A7.93 7.93 0 0 0 4 12c0 4.42 3.58 8 8 8v3l4-4-4-4v3z" />
        </svg>
        {{ loading ? 'Actualizando…' : 'Actualizar' }}
      </button>
    </header>

    <div v-if="!loading && !jefe" class="alert alert--warning" role="alert">
      <strong>No se encontró tu perfil de Jefe de Calle.</strong>
      Pide a un administrador que asocie tu cuenta a una calle para poder gestionar registros.
    </div>

    <div v-if="!loading && jefe && !calleId" class="alert alert--warning" role="alert">
      <strong>Tu perfil aún no tiene una calle asignada.</strong>
      Un administrador debe asignarte una calle para recibir registros y notificaciones.
    </div>

    <div v-if="error && !confirmOpen" class="alert alert--error" role="alert">
      {{ error }}
    </div>

    <div v-if="success" class="alert alert--success" role="status">
      {{ success }}
    </div>

    <template v-if="jefe">
      <section class="stats-grid" aria-label="Resumen de registros">
        <article class="stat-card stat-card--amber">
          <span class="stat-icon" aria-hidden="true">⏳</span>
          <div>
            <p class="stat-label">Pendientes</p>
            <p class="stat-value">{{ pendientes.length }}</p>
          </div>
        </article>
        <article class="stat-card stat-card--green">
          <span class="stat-icon" aria-hidden="true">✓</span>
          <div>
            <p class="stat-label">Aprobados</p>
            <p class="stat-value">{{ aprobados.length }}</p>
          </div>
        </article>
        <article class="stat-card stat-card--red">
          <span class="stat-icon" aria-hidden="true">×</span>
          <div>
            <p class="stat-label">Rechazados</p>
            <p class="stat-value">{{ rechazados.length }}</p>
          </div>
        </article>
        <article class="stat-card stat-card--blue">
          <span class="stat-icon" aria-hidden="true">👤</span>
          <div>
            <p class="stat-label">Jefes de Familia activos</p>
            <p class="stat-value">{{ jefesActivos.length }}</p>
          </div>
        </article>
      </section>

      <div class="view-tabs" role="tablist" aria-label="Vistas de gestión">
        <button
          type="button"
          class="view-tab"
          :class="{ active: vista === 'registros' }"
          role="tab"
          :aria-selected="vista === 'registros'"
          @click="vista = 'registros'"
        >
          Registros
          <span class="tab-count">{{ registros.length }}</span>
        </button>
        <button
          type="button"
          class="view-tab"
          :class="{ active: vista === 'jefes' }"
          role="tab"
          :aria-selected="vista === 'jefes'"
          @click="vista = 'jefes'"
        >
          Jefes de Familia
          <span class="tab-count">{{ jefesFamilia.length }}</span>
        </button>
      </div>

      <template v-if="vista === 'registros'">
        <div class="filter-row" role="group" aria-label="Filtrar registros por estado">
          <button
            v-for="filtroItem in filtros"
            :key="filtroItem.value"
            type="button"
            class="filter-chip"
            :class="{ active: filtro === filtroItem.value }"
            @click="filtro = filtroItem.value"
          >
            {{ filtroItem.label }}
            <span>{{ contarPorEstado(filtroItem.value) }}</span>
          </button>
        </div>

        <div v-if="loading" class="state-panel">
          <span class="spinner" aria-hidden="true" />
          <p>Cargando registros de tu calle…</p>
        </div>

        <div v-else-if="registrosFiltrados.length === 0" class="state-panel state-panel--empty">
          <span class="empty-icon" aria-hidden="true">📭</span>
          <strong>No hay registros en esta categoría</strong>
          <p>Cuando una familia se registre en tu calle aparecerá aquí.</p>
        </div>

        <div v-else class="records-list">
          <article v-for="registro in registrosFiltrados" :key="registro.id" class="record-card">
            <div class="record-head">
              <span class="record-avatar" aria-hidden="true">{{ inicial(registro.nombre_familia) }}</span>
              <div class="record-title">
                <h2>{{ registro.nombre_familia || 'Sin nombre' }}</h2>
                <p>V-{{ registro.id }} · {{ nombreCalle(registro.id_calle) }}</p>
              </div>
              <span class="status-pill" :class="estadoClase(registro.estado)">
                {{ estadoLabel(registro.estado) }}
              </span>
            </div>

            <div class="record-details">
              <div>
                <span>Teléfono</span>
                <strong>{{ registro.telefono || 'No indicado' }}</strong>
              </div>
              <div>
                <span>Personas</span>
                <strong>{{ registro.num_personas || '—' }}</strong>
              </div>
              <div>
                <span>Dirección</span>
                <strong>{{ registro.direccion || 'No indicada' }}</strong>
              </div>
              <div>
                <span>Registrado</span>
                <strong>{{ formatearFecha(registro.created_at) }}</strong>
              </div>
            </div>

            <p v-if="registro.notas_rechazo" class="record-note">
              <strong>Motivo del rechazo:</strong> {{ registro.notas_rechazo }}
            </p>

            <div class="record-actions">
              <template v-if="registro.estado === 'pendiente'">
                <button type="button" class="btn-action btn-action--success" @click="openAprobar(registro)">
                  Aceptar
                </button>
                <button type="button" class="btn-action btn-action--outline" @click="openEditar(registro)">
                  Modificar
                </button>
                <button type="button" class="btn-action btn-action--danger" @click="openRechazar(registro)">
                  Rechazar
                </button>
              </template>
              <template v-else-if="registro.estado === 'rechazado'">
                <button type="button" class="btn-action btn-action--outline" @click="openEditar(registro)">
                  Modificar
                </button>
                <button type="button" class="btn-action btn-action--success" @click="openAprobar(registro)">
                  Reconsiderar
                </button>
              </template>
              <template v-else>
                <button
                  v-if="!tieneJefeActivo(registro)"
                  type="button"
                  class="btn-action btn-action--success"
                  @click="openAprobar(registro)"
                >
                  Asignar Jefe de Familia
                </button>
                <span v-else class="record-approved-hint">
                  Aprobado como Jefe de Familia
                </span>
              </template>
            </div>
          </article>
        </div>
      </template>

      <template v-else>
        <div v-if="loading" class="state-panel">
          <span class="spinner" aria-hidden="true" />
          <p>Cargando Jefes de Familia…</p>
        </div>

        <div v-else-if="jefesFamilia.length === 0" class="state-panel state-panel--empty">
          <span class="empty-icon" aria-hidden="true">👥</span>
          <strong>Aún no hay Jefes de Familia</strong>
          <p>Los jefes de familia se crean al aprobar el registro de una familia.</p>
        </div>

        <div v-else class="records-list">
          <article
            v-for="item in jefesFamilia"
            :key="item.id_jefe_familia"
            class="record-card record-card--head"
          >
            <div class="record-head">
              <span class="record-avatar record-avatar--head" aria-hidden="true">
                {{ inicial(item.nombre) }}
              </span>
              <div class="record-title">
                <h2>{{ item.nombre || 'Sin nombre' }}</h2>
                <p>
                  Familia: {{ familiaDeJefe(item)?.nombre_familia || `ID ${item.id_familia}` }}
                  · {{ nombreCalle(item.id_calle) }}
                </p>
              </div>
              <span class="status-pill" :class="item.activo ? 'is-approved' : 'is-rejected'">
                {{ item.activo ? 'Activo' : 'Inactivo' }}
              </span>
            </div>

            <div class="record-details">
              <div>
                <span>Cédula</span>
                <strong>{{ item.ci || '—' }}</strong>
              </div>
              <div>
                <span>Teléfono</span>
                <strong>{{ item.telefono || 'No indicado' }}</strong>
              </div>
              <div>
                <span>Alta</span>
                <strong>{{ formatearFecha(item.created_at) }}</strong>
              </div>
              <div>
                <span>ID</span>
                <strong>#{{ item.id_jefe_familia }}</strong>
              </div>
            </div>

            <div class="record-actions">
              <button
                v-if="item.activo"
                type="button"
                class="btn-action btn-action--danger"
                @click="openBaja(item)"
              >
                Dar de baja
              </button>
              <span v-else class="record-approved-hint">Sin asignación activa</span>
            </div>
          </article>
        </div>
      </template>
    </template>

    <ConfirmDialog
      v-model="confirmOpen"
      :title="confirmTitle"
      :message="confirmMessage"
      :confirm-text="confirmText"
      :confirm-variant="confirmVariant"
      :tone="confirmTone"
      :loading="accionLoading"
      :error="confirmError"
      @confirm="ejecutarConfirmacion"
    >
      <div v-if="confirmAction === 'rechazar'" class="dialog-field">
        <label for="motivo-rechazo">Motivo del rechazo</label>
        <textarea
          id="motivo-rechazo"
          v-model="motivo"
          rows="3"
          maxlength="500"
          placeholder="Explica brevemente por qué se rechaza el registro…"
        />
        <small>El motivo se enviará al solicitante en una notificación.</small>
      </div>
    </ConfirmDialog>

    <Teleport to="body">
      <div v-if="editOpen" class="edit-modal" @click.self="closeEdit">
        <div class="edit-panel" role="dialog" aria-modal="true" aria-labelledby="edit-title">
          <span class="edit-handle" aria-hidden="true" />
          <div class="edit-head">
            <div>
              <p class="edit-eyebrow">Modificar registro</p>
              <h2 id="edit-title">{{ editForm.nombre || 'Familia' }}</h2>
            </div>
            <button type="button" class="edit-close" aria-label="Cerrar" @click="closeEdit">×</button>
          </div>

          <form class="edit-form" @submit.prevent="guardarEdicion">
            <div class="form-grid">
              <div class="form-field">
                <label for="edit-nombre">Nombre de la familia</label>
                <input id="edit-nombre" v-model="editForm.nombre" type="text" required />
              </div>
              <div class="form-field">
                <label for="edit-telefono">Teléfono</label>
                <input id="edit-telefono" v-model="editForm.telefono" type="tel" placeholder="0414-1234567" />
              </div>
              <div class="form-field">
                <label for="edit-personas">Personas en el hogar</label>
                <input id="edit-personas" v-model="editForm.personas" type="number" min="1" />
              </div>
              <div class="form-field">
                <label for="edit-calle">Calle / sector</label>
                <select id="edit-calle" v-model="editForm.id_calle" disabled>
                  <option v-for="calle in calles" :key="calle.id_calle" :value="calle.id_calle">
                    {{ calle.nombre }}
                  </option>
                </select>
                <small>Solo un administrador puede cambiar la calle.</small>
              </div>
            </div>

            <div class="form-field">
              <label for="edit-direccion">Dirección</label>
              <input id="edit-direccion" v-model="editForm.direccion" type="text" placeholder="Casa #12, referencia…" />
            </div>

            <p v-if="editError" class="edit-error" role="alert">{{ editError }}</p>

            <div class="edit-actions">
              <button type="button" class="btn-action btn-action--outline" :disabled="accionLoading" @click="closeEdit">
                Cancelar
              </button>
              <button type="submit" class="btn-action btn-action--primary" :disabled="accionLoading">
                {{ accionLoading ? 'Guardando…' : 'Guardar cambios' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import ConfirmDialog from '../../components/ui/ConfirmDialog.vue'
import { useRegistrosFamilia } from '../../composables/useRegistrosFamilia.js'

const {
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
  aprobarRegistro,
  rechazarRegistro,
  actualizarRegistro,
  darBajaJefeFamilia,
  familiaDeJefe,
} = useRegistrosFamilia()

const vista = ref('registros')
const filtro = ref('pendiente')
const success = ref('')
let successTimer = null

const filtros = [
  { value: 'pendiente', label: 'Pendientes' },
  { value: 'aprobado', label: 'Aprobados' },
  { value: 'rechazado', label: 'Rechazados' },
  { value: 'todos', label: 'Todos' },
]

const registrosFiltrados = computed(() => {
  if (filtro.value === 'todos') return registros.value
  return registros.value.filter((registro) => (registro.estado || 'pendiente') === filtro.value)
})

const confirmOpen = ref(false)
const confirmAction = ref('')
const selected = ref(null)
const motivo = ref('')
const confirmError = ref('')

const editOpen = ref(false)
const editError = ref('')
const editForm = reactive({
  id: null,
  nombre: '',
  telefono: '',
  direccion: '',
  personas: '',
  id_calle: null,
})

const esReasignacion = computed(
  () => confirmAction.value === 'aprobar' && selected.value?.estado === 'aprobado'
)

const confirmTitle = computed(() => {
  if (confirmAction.value === 'aprobar') {
    return esReasignacion.value ? 'Asignar Jefe de Familia' : 'Aprobar registro de familia'
  }
  if (confirmAction.value === 'rechazar') return 'Rechazar registro de familia'
  if (confirmAction.value === 'baja') return 'Dar de baja al Jefe de Familia'
  return 'Confirmar acción'
})

const confirmMessage = computed(() => {
  if (confirmAction.value === 'aprobar') {
    if (esReasignacion.value) {
      return `¿Asignar un nuevo Jefe de Familia para ${selected.value?.nombre_familia || 'esta familia'}? La familia quedó sin un Jefe de Familia activo.`
    }
    return `¿Aprobar el registro de ${selected.value?.nombre_familia || 'esta familia'}? Se asignará como Jefe de Familia activo de su núcleo.`
  }
  if (confirmAction.value === 'rechazar') {
    return `¿Rechazar el registro de ${selected.value?.nombre_familia || 'esta familia'}? El solicitante recibirá el motivo indicado.`
  }
  if (confirmAction.value === 'baja') {
    return `¿Dar de baja a ${selected.value?.nombre || 'este Jefe de Familia'}? La familia quedará sin un Jefe de Familia activo y podrá asignarse otro después.`
  }
  return ''
})

const confirmText = computed(() => {
  if (confirmAction.value === 'aprobar') {
    return esReasignacion.value ? 'Sí, asignar' : 'Sí, aprobar'
  }
  if (confirmAction.value === 'rechazar') return 'Sí, rechazar'
  if (confirmAction.value === 'baja') return 'Sí, dar de baja'
  return 'Confirmar'
})

const confirmVariant = computed(() => {
  if (confirmAction.value === 'aprobar') return 'success'
  return 'danger'
})

const confirmTone = computed(() => {
  if (confirmAction.value === 'aprobar') return 'success'
  return 'danger'
})

onMounted(cargarTodo)

function contarPorEstado(estado) {
  if (estado === 'todos') return registros.value.length
  return registros.value.filter((registro) => (registro.estado || 'pendiente') === estado).length
}

function inicial(nombre) {
  return String(nombre || 'F').trim().charAt(0).toUpperCase() || 'F'
}

function nombreCalle(idCalle) {
  const calle = calles.value.find((item) => item.id_calle === idCalle)
  return calle?.nombre || `Calle ID ${idCalle || '—'}`
}

function estadoLabel(estado) {
  const map = {
    pendiente: 'Pendiente',
    aprobado: 'Aprobado',
    rechazado: 'Rechazado',
  }
  return map[estado] || 'Pendiente'
}

function estadoClase(estado) {
  if (estado === 'aprobado') return 'is-approved'
  if (estado === 'rechazado') return 'is-rejected'
  return 'is-pending'
}

function tieneJefeActivo(registro) {
  return jefesActivos.value.some(
    (item) => Number(item.id_familia) === Number(registro.id)
  )
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

function mostrarExito(mensaje) {
  success.value = mensaje
  if (successTimer) window.clearTimeout(successTimer)
  successTimer = window.setTimeout(() => {
    success.value = ''
  }, 5000)
}

function openAprobar(registro) {
  selected.value = registro
  confirmAction.value = 'aprobar'
  motivo.value = ''
  confirmError.value = ''
  confirmOpen.value = true
}

function openRechazar(registro) {
  selected.value = registro
  confirmAction.value = 'rechazar'
  motivo.value = ''
  confirmError.value = ''
  confirmOpen.value = true
}

function openBaja(item) {
  selected.value = item
  confirmAction.value = 'baja'
  motivo.value = ''
  confirmError.value = ''
  confirmOpen.value = true
}

async function ejecutarConfirmacion() {
  confirmError.value = ''

  try {
    if (confirmAction.value === 'aprobar') {
      const reasignando = esReasignacion.value
      await aprobarRegistro(selected.value.id)
      confirmOpen.value = false
      mostrarExito(
        reasignando
          ? `Se asignó un nuevo Jefe de Familia para ${selected.value.nombre_familia}.`
          : `Registro de ${selected.value.nombre_familia} aprobado correctamente.`
      )
      filtro.value = 'aprobado'
    } else if (confirmAction.value === 'rechazar') {
      if (!motivo.value.trim()) {
        confirmError.value = 'Indica el motivo del rechazo.'
        return
      }
      await rechazarRegistro(selected.value.id, motivo.value)
      confirmOpen.value = false
      mostrarExito(`Registro de ${selected.value.nombre_familia} rechazado.`)
      filtro.value = 'rechazado'
    } else if (confirmAction.value === 'baja') {
      await darBajaJefeFamilia(selected.value.id_jefe_familia)
      confirmOpen.value = false
      mostrarExito(`Se dio de baja a ${selected.value.nombre}.`)
    }
  } catch (err) {
    confirmError.value =
      err?.message || 'No se pudo completar la acción. Revisa los datos e intenta nuevamente.'
  }
}

function openEditar(registro) {
  editForm.id = registro.id
  editForm.nombre = registro.nombre_familia || ''
  editForm.telefono = registro.telefono || ''
  editForm.direccion = registro.direccion || ''
  editForm.personas = registro.num_personas || ''
  editForm.id_calle = registro.id_calle || calleId.value
  editError.value = ''
  editOpen.value = true
}

function closeEdit() {
  if (accionLoading.value) return
  editOpen.value = false
}

async function guardarEdicion() {
  editError.value = ''
  try {
    await actualizarRegistro(editForm.id, {
      nombre: editForm.nombre,
      telefono: editForm.telefono,
      direccion: editForm.direccion,
      personas: editForm.personas,
      id_calle: editForm.id_calle,
    })
    editOpen.value = false
    mostrarExito('Registro modificado correctamente.')
  } catch (err) {
    editError.value = err?.message || 'No se pudo modificar el registro.'
  }
}
</script>

<style scoped>
.registros-page {
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
  max-width: 680px;
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
.stat-card--green .stat-icon { background: #ecfdf5; color: #047857; }
.stat-card--red .stat-icon { background: #fef2f2; color: #b91c1c; }
.stat-card--blue .stat-icon { background: #eff6ff; color: #1d4ed8; }

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

.view-tabs {
  display: flex;
  gap: 6px;
  padding: 5px;
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  background: #f8fafc;
}

.view-tab {
  display: inline-flex;
  flex: 1;
  align-items: center;
  justify-content: center;
  gap: 7px;
  min-height: 42px;
  padding: 0 10px;
  border: 0;
  border-radius: 10px;
  background: transparent;
  color: #64748b;
  font: inherit;
  font-size: 0.8rem;
  font-weight: 700;
  cursor: pointer;
  transition: background-color 160ms ease, color 160ms ease, box-shadow 160ms ease;
}

.view-tab.active {
  background: #ffffff;
  color: #0369a1;
  box-shadow: 0 1px 4px rgba(15, 23, 42, 0.08);
}

.tab-count {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 20px;
  height: 20px;
  padding: 0 5px;
  border-radius: 999px;
  background: #e2e8f0;
  color: #475569;
  font-size: 0.66rem;
  font-weight: 800;
}

.view-tab.active .tab-count {
  background: #e0f2fe;
  color: #0369a1;
}

.filter-row {
  display: flex;
  gap: 7px;
  overflow-x: auto;
  padding-bottom: 2px;
  scrollbar-width: none;
}

.filter-row::-webkit-scrollbar {
  display: none;
}

.filter-chip {
  display: inline-flex;
  flex-shrink: 0;
  align-items: center;
  gap: 6px;
  min-height: 36px;
  padding: 0 11px;
  border: 1px solid #e2e8f0;
  border-radius: 999px;
  background: #ffffff;
  color: #64748b;
  font: inherit;
  font-size: 0.76rem;
  font-weight: 700;
  cursor: pointer;
}

.filter-chip span {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 18px;
  height: 18px;
  padding: 0 4px;
  border-radius: 999px;
  background: #f1f5f9;
  font-size: 0.64rem;
}

.filter-chip.active {
  border-color: #7dd3fc;
  background: #f0f9ff;
  color: #0369a1;
}

.filter-chip.active span {
  background: #e0f2fe;
  color: #0369a1;
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

.records-list {
  display: grid;
  gap: 12px;
}

.record-card {
  padding: 15px;
  border: 1px solid #e2e8f0;
  border-radius: 17px;
  background: #ffffff;
  box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
  transition: border-color 160ms ease, box-shadow 160ms ease, transform 160ms ease;
}

.record-card:hover {
  border-color: #bae6fd;
  box-shadow: 0 8px 24px -14px rgba(14, 165, 233, 0.35);
  transform: translateY(-1px);
}

.record-card--head {
  border-left: 4px solid #0ea5e9;
}

.record-head {
  display: flex;
  align-items: flex-start;
  gap: 11px;
}

.record-avatar {
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

.record-avatar--head {
  background: #ecfeff;
  color: #0e7490;
}

.record-title {
  min-width: 0;
  flex: 1;
}

.record-title h2 {
  margin: 0;
  overflow: hidden;
  color: #0f172a;
  font-size: 0.95rem;
  font-weight: 800;
  line-height: 1.3;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.record-title p {
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
  border: 1px solid transparent;
  border-radius: 999px;
  font-size: 0.66rem;
  font-weight: 800;
  letter-spacing: 0.02em;
  white-space: nowrap;
}

.status-pill.is-pending {
  border-color: #fde68a;
  background: #fffbeb;
  color: #b45309;
}

.status-pill.is-approved {
  border-color: #a7f3d0;
  background: #ecfdf5;
  color: #047857;
}

.status-pill.is-rejected {
  border-color: #fecaca;
  background: #fef2f2;
  color: #b91c1c;
}

.record-details {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
  margin-top: 13px;
  padding-top: 12px;
  border-top: 1px solid #f1f5f9;
}

.record-details > div {
  min-width: 0;
}

.record-details span {
  display: block;
  color: #94a3b8;
  font-size: 0.65rem;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.record-details strong {
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

.record-note {
  margin: 12px 0 0;
  padding: 9px 11px;
  border: 1px solid #fecaca;
  border-radius: 9px;
  background: #fef2f2;
  color: #991b1b;
  font-size: 0.78rem;
  line-height: 1.45;
}

.record-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 13px;
}

.btn-action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: 40px;
  padding: 0 14px;
  border: 1px solid transparent;
  border-radius: 10px;
  font: inherit;
  font-size: 0.78rem;
  font-weight: 700;
  cursor: pointer;
  transition: filter 150ms ease, background-color 150ms ease, transform 150ms ease;
}

.btn-action:active:not(:disabled) {
  transform: scale(0.98);
}

.btn-action:disabled {
  opacity: 0.6;
  cursor: wait;
}

.btn-action--success {
  border-color: #059669;
  background: #ecfdf5;
  color: #047857;
}

.btn-action--success:hover:not(:disabled) {
  background: #059669;
  color: #ffffff;
}

.btn-action--danger {
  border-color: #dc2626;
  background: #fef2f2;
  color: #b91c1c;
}

.btn-action--danger:hover:not(:disabled) {
  background: #dc2626;
  color: #ffffff;
}

.btn-action--outline {
  border-color: #cbd5e1;
  background: #ffffff;
  color: #475569;
}

.btn-action--outline:hover:not(:disabled) {
  background: #f8fafc;
  border-color: #94a3b8;
}

.btn-action--primary {
  border-color: #0284c7;
  background: #0ea5e9;
  color: #ffffff;
}

.btn-action--primary:hover:not(:disabled) {
  background: #0284c7;
}

.record-approved-hint {
  display: inline-flex;
  align-items: center;
  min-height: 40px;
  color: #047857;
  font-size: 0.78rem;
  font-weight: 700;
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
  font-size: 0.9rem;
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

/* Modal de edición */
.edit-modal {
  position: fixed;
  inset: 0;
  z-index: 1100;
  display: flex;
  align-items: flex-end;
  justify-content: center;
  background: rgba(2, 6, 23, 0.58);
  backdrop-filter: blur(5px);
  -webkit-backdrop-filter: blur(5px);
}

.edit-panel {
  width: 100%;
  max-height: 92dvh;
  padding: 14px 16px calc(20px + var(--safe-bottom));
  overflow-y: auto;
  border-radius: 24px 24px 0 0;
  background: #ffffff;
  box-shadow: 0 -20px 60px rgba(2, 6, 23, 0.3);
  animation: sheetUp 0.22s ease-out;
}

@keyframes sheetUp {
  from { transform: translateY(18px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

.edit-handle {
  display: block;
  width: 42px;
  height: 4px;
  margin: 0 auto 15px;
  border-radius: 999px;
  background: #e2e8f0;
}

.edit-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.edit-eyebrow {
  margin: 0;
  color: #0369a1;
  font-size: 0.68rem;
  font-weight: 800;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

.edit-head h2 {
  margin: 4px 0 0;
  color: #0f172a;
  font-size: 1.2rem;
  font-weight: 800;
}

.edit-close {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 38px;
  height: 38px;
  padding: 0;
  border: 0;
  border-radius: 10px;
  background: #f1f5f9;
  color: #475569;
  font-size: 1.3rem;
  line-height: 1;
  cursor: pointer;
}

.edit-close:hover {
  background: #e2e8f0;
}

.edit-form {
  display: grid;
  gap: 14px;
  margin-top: 18px;
}

.form-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 12px;
}

.form-field {
  display: grid;
  gap: 6px;
}

.form-field label {
  color: #334155;
  font-size: 0.78rem;
  font-weight: 700;
}

.form-field input,
.form-field select {
  width: 100%;
  min-height: 44px;
  padding: 0 12px;
  border: 1px solid #d1d5db;
  border-radius: 11px;
  background: #ffffff;
  color: #0f172a;
  font: inherit;
  font-size: 16px;
  outline: none;
}

.form-field input:focus,
.form-field select:focus {
  border-color: #0ea5e9;
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.14);
}

.form-field select:disabled {
  background: #f8fafc;
  color: #64748b;
  cursor: not-allowed;
}

.form-field small {
  color: #94a3b8;
  font-size: 0.7rem;
  line-height: 1.4;
}

.edit-error {
  margin: 0;
  padding: 10px 12px;
  border: 1px solid #fecaca;
  border-radius: 10px;
  background: #fef2f2;
  color: #b91c1c;
  font-size: 0.8rem;
  line-height: 1.45;
}

.edit-actions {
  display: flex;
  flex-direction: column-reverse;
  gap: 9px;
  margin-top: 4px;
}

.edit-actions .btn-action {
  width: 100%;
  min-height: 44px;
}

@media (min-width: 480px) {
  .record-details {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }

  .form-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (min-width: 640px) {
  .registros-page {
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

  .view-tabs {
    width: fit-content;
  }

  .view-tab {
    flex: 0 0 auto;
    min-width: 160px;
    padding: 0 18px;
  }

  .record-card {
    padding: 18px 20px;
  }

  .record-title h2 {
    font-size: 1rem;
  }

  .edit-modal {
    align-items: center;
    padding: 24px;
  }

  .edit-panel {
    width: 100%;
    max-width: 620px;
    max-height: 88vh;
    padding: 24px;
    border-radius: 20px;
    animation: scaleIn 0.2s ease-out;
  }

  .edit-handle {
    display: none;
  }

  .edit-actions {
    flex-direction: row;
    justify-content: flex-end;
  }

  .edit-actions .btn-action {
    width: auto;
    min-width: 130px;
  }
}

@keyframes scaleIn {
  from { transform: scale(0.96); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}

@media (min-width: 1024px) {
  .page-banner {
    padding: 28px 32px;
  }

  .record-card {
    padding: 20px 24px;
  }
}

@media (prefers-reduced-motion: reduce) {
  .pulse-dot,
  .refresh-icon.spin,
  .spinner,
  .edit-panel {
    animation: none;
  }
}
</style>
