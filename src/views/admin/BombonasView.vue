<template>
  <div class="bombonas-page">
    <header class="page-banner">
      <div class="banner-copy">
        <span class="banner-eyebrow">
          <span class="pulse-dot" aria-hidden="true" />
          Inventario
        </span>
        <h1>Gestión de Bombonas</h1>
        <p>
          Controla el inventario de cilindros, su ubicación y estado operativo.
          Las bombonas dadas de baja se conservan en el historial y pueden restaurarse.
        </p>
      </div>

      <div class="banner-actions">
        <button type="button" class="btn-refresh" :disabled="loading" @click="cargar">
          <svg viewBox="0 0 24 24" class="refresh-icon" :class="{ spin: loading }" aria-hidden="true">
            <path fill="currentColor" d="M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6 0 1.01-.25 1.97-.7 2.8l1.46 1.46A7.93 7.93 0 0 0 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6 0-1.01.25-1.97.7-2.8L5.24 7.74A7.93 7.93 0 0 0 4 12c0 4.42 3.58 8 8 8v3l4-4-4-4v3" />
          </svg>
          {{ loading ? 'Actualizando…' : 'Actualizar' }}
        </button>
        <button type="button" class="btn-primary" @click="abrirCrear">
          <span aria-hidden="true">+</span>
          Nueva bombona
        </button>
      </div>
    </header>

    <div v-if="error && !modalOpen && !confirmOpen" class="alert alert--error" role="alert">
      {{ error }}
    </div>
    <div v-if="success" class="alert alert--success" role="status">{{ success }}</div>

    <section class="stats-grid" aria-label="Resumen del inventario">
      <article class="stat-card stat-card--blue">
        <span class="stat-icon" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 3v18m5-18v18M7 3v18M4 7h16M4 17h16" />
          </svg>
        </span>
        <div>
          <p class="stat-label">Total activas</p>
          <p class="stat-value">{{ totalActivas }}</p>
        </div>
      </article>
      <article class="stat-card stat-card--green">
        <span class="stat-icon" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M20 6 9 17l-5-5" />
          </svg>
        </span>
        <div>
          <p class="stat-label">Disponibles</p>
          <p class="stat-value">{{ totalDisponibles }}</p>
        </div>
      </article>
      <article class="stat-card stat-card--amber">
        <span class="stat-icon" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <path stroke-linecap="round" stroke-linejoin="round" d="M3 7h18v12H3zM8 7V5h8v2M8 12h8" />
          </svg>
        </span>
        <div>
          <p class="stat-label">En uso</p>
          <p class="stat-value">{{ totalEnUso }}</p>
        </div>
      </article>
      <article class="stat-card stat-card--red">
        <span class="stat-icon" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v4m0 4h.01M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
          </svg>
        </span>
        <div>
          <p class="stat-label">Mantenimiento</p>
          <p class="stat-value">{{ totalMantenimiento }}</p>
        </div>
      </article>
    </section>

    <section class="toolbar-card" aria-label="Filtros de bombonas">
      <label class="search-field">
        <span class="sr-only">Buscar bombona</span>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" d="m21 21-4.35-4.35M19 11a8 8 0 1 1-16 0 8 8 0 0 1 16 0z" />
        </svg>
        <input v-model="filtroBusqueda" type="search" placeholder="Buscar por código u observaciones…" />
      </label>

      <label class="select-field">
        <span>Estado</span>
        <select v-model="filtroEstado">
          <option value="todos">Todos los estados</option>
          <option value="disponible">Disponible</option>
          <option value="asignada">Asignada</option>
          <option value="entregada">Entregada</option>
          <option value="mantenimiento">Mantenimiento</option>
          <option value="perdida">Perdida</option>
        </select>
      </label>

      <label class="select-field">
        <span>Calle</span>
        <select v-model="filtroCalle">
          <option value="todas">Todas las calles</option>
          <option v-for="calle in calles" :key="calle.id_calle" :value="calle.id_calle">
            {{ calle.nombre }}
          </option>
        </select>
      </label>

      <label class="toggle-field">
        <input v-model="incluirEliminadas" type="checkbox" @change="cargar" />
        <span>Mostrar dadas de baja</span>
      </label>
    </section>

    <div v-if="loading" class="state-panel">
      <span class="spinner" aria-hidden="true" />
      <p>Cargando inventario de bombonas…</p>
    </div>

    <div v-else-if="bombonasFiltradas.length === 0" class="state-panel state-panel--empty">
      <span class="empty-icon" aria-hidden="true">🛢️</span>
      <strong>No hay bombonas en esta categoría</strong>
      <p>Registra una nueva bombona o ajusta los filtros de búsqueda.</p>
    </div>

    <div v-else class="table-card">
      <div class="table-wrapper">
        <table class="custom-table">
          <thead>
            <tr>
              <th>Código</th>
              <th>Tipo</th>
              <th>Estado</th>
              <th>Calle asignada</th>
              <th>Peso</th>
              <th>Registro</th>
              <th class="actions-head">Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="bombona in bombonasFiltradas"
              :key="bombona.id_bombona"
              class="table-row"
              :class="{ 'is-deleted': bombona.is_deleted }"
            >
              <td class="code-cell" data-label="Código">
                <span class="code-badge">{{ bombona.codigo }}</span>
                <span v-if="bombona.is_deleted" class="deleted-tag">Dada de baja</span>
              </td>
              <td data-label="Tipo">
                <span class="type-badge">{{ etiquetaTipo(bombona.tipo_bombona) }}</span>
              </td>
              <td data-label="Estado">
                <span class="status-pill" :class="`is-${bombona.estado}`">
                  {{ etiquetaEstado(bombona.estado) }}
                </span>
              </td>
              <td data-label="Calle asignada">
                <span class="muted-value">{{ nombreCalle(bombona.id_calle) }}</span>
              </td>
              <td data-label="Peso">
                <span class="muted-value">{{ bombona.peso_kg ? `${bombona.peso_kg} kg` : '—' }}</span>
              </td>
              <td data-label="Registro">
                <span class="muted-value">{{ formatearFecha(bombona.created_at) }}</span>
              </td>
              <td data-label="Acciones">
                <div class="row-actions">
                  <button
                    v-if="!bombona.is_deleted"
                    type="button"
                    class="btn-row btn-row--edit"
                    @click="abrirEditar(bombona)"
                  >
                    Editar
                  </button>
                  <button
                    v-if="!bombona.is_deleted"
                    type="button"
                    class="btn-row btn-row--danger"
                    @click="abrirConfirmacion(bombona, 'eliminar')"
                  >
                    Dar de baja
                  </button>
                  <button
                    v-else
                    type="button"
                    class="btn-row btn-row--success"
                    @click="abrirConfirmacion(bombona, 'restaurar')"
                  >
                    Restaurar
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="mobile-list" role="list">
        <article
          v-for="bombona in bombonasFiltradas"
          :key="`card-${bombona.id_bombona}`"
          class="mobile-card"
          :class="{ 'is-deleted': bombona.is_deleted }"
          role="listitem"
        >
          <div class="mobile-card-head">
            <div>
              <p class="mobile-code">{{ bombona.codigo }}</p>
              <p class="mobile-type">{{ etiquetaTipo(bombona.tipo_bombona) }}</p>
            </div>
            <span class="status-pill" :class="`is-${bombona.estado}`">
              {{ etiquetaEstado(bombona.estado) }}
            </span>
          </div>

          <div class="mobile-details">
            <div>
              <span>Calle</span>
              <strong>{{ nombreCalle(bombona.id_calle) }}</strong>
            </div>
            <div>
              <span>Peso</span>
              <strong>{{ bombona.peso_kg ? `${bombona.peso_kg} kg` : '—' }}</strong>
            </div>
            <div>
              <span>Registro</span>
              <strong>{{ formatearFecha(bombona.created_at) }}</strong>
            </div>
          </div>

          <p v-if="bombona.is_deleted" class="mobile-deleted-note">
            Esta bombona está dada de baja y no aparece en los conteos activos.
          </p>

          <div class="mobile-actions">
            <button
              v-if="!bombona.is_deleted"
              type="button"
              class="btn-row btn-row--edit"
              @click="abrirEditar(bombona)"
            >
              Editar
            </button>
            <button
              v-if="!bombona.is_deleted"
              type="button"
              class="btn-row btn-row--danger"
              @click="abrirConfirmacion(bombona, 'eliminar')"
            >
              Dar de baja
            </button>
            <button
              v-else
              type="button"
              class="btn-row btn-row--success"
              @click="abrirConfirmacion(bombona, 'restaurar')"
            >
              Restaurar
            </button>
          </div>
        </article>
      </div>
    </div>

    <Teleport to="body">
      <div v-if="modalOpen" class="modal-overlay" @click.self="cerrarModal">
        <div class="modal-panel" role="dialog" aria-modal="true" :aria-label="formTitle">
          <span class="modal-handle" aria-hidden="true" />

          <div class="modal-head">
            <div>
              <p class="modal-eyebrow">{{ modoEdicion ? 'Editar inventario' : 'Nueva bombona' }}</p>
              <h2>{{ formTitle }}</h2>
            </div>
            <button type="button" class="modal-close" aria-label="Cerrar" @click="cerrarModal">×</button>
          </div>

          <form class="modal-form" @submit.prevent="guardar">
            <div class="form-grid">
              <label class="form-field">
                <span>Código de la bombona *</span>
                <input
                  v-model="form.codigo"
                  type="text"
                  maxlength="60"
                  placeholder="Ej. BOM-0001"
                  autocomplete="off"
                  required
                />
              </label>

              <label class="form-field">
                <span>Tipo *</span>
                <select v-model="form.tipo_bombona" required>
                  <option value="">Selecciona un tipo</option>
                  <option value="10kg">10 kg</option>
                  <option value="18kg">18 kg</option>
                  <option value="43kg">43 kg</option>
                </select>
              </label>

              <label class="form-field">
                <span>Estado *</span>
                <select v-model="form.estado" required>
                  <option value="disponible">Disponible</option>
                  <option value="asignada">Asignada</option>
                  <option value="entregada">Entregada</option>
                  <option value="mantenimiento">Mantenimiento</option>
                  <option value="perdida">Perdida</option>
                </select>
              </label>

              <label class="form-field">
                <span>Peso (kg)</span>
                <input v-model="form.peso_kg" type="number" min="0" step="0.01" placeholder="Opcional" />
              </label>

              <label class="form-field form-field--full">
                <span>Calle asignada</span>
                <select v-model="form.id_calle">
                  <option value="">Sin calle asignada</option>
                  <option v-for="calle in calles" :key="calle.id_calle" :value="calle.id_calle">
                    {{ calle.nombre }}
                  </option>
                </select>
              </label>

              <label class="form-field form-field--full">
                <span>Observaciones</span>
                <textarea
                  v-model="form.observaciones"
                  rows="3"
                  maxlength="500"
                  placeholder="Detalles del cilindro, daños, ubicación interna…"
                />
              </label>
            </div>

            <p v-if="formError" class="form-error" role="alert">{{ formError }}</p>

            <div class="modal-actions">
              <button type="button" class="btn-cancel" :disabled="accionLoading" @click="cerrarModal">
                Cancelar
              </button>
              <button type="submit" class="btn-primary" :disabled="accionLoading">
                {{ accionLoading ? 'Guardando…' : modoEdicion ? 'Guardar cambios' : 'Registrar bombona' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>

    <ConfirmDialog
      v-model="confirmOpen"
      :title="confirmTitle"
      :message="confirmMessage"
      :confirm-text="confirmText"
      :confirm-variant="confirmAction === 'eliminar' ? 'danger' : 'success'"
      :tone="confirmAction === 'eliminar' ? 'danger' : 'success'"
      :loading="accionLoading"
      :error="confirmError"
      @confirm="ejecutarConfirmacion"
    />
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import ConfirmDialog from '../../components/ui/ConfirmDialog.vue'
import { useBombonas } from '../../composables/useBombonas.js'

const {
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
} = useBombonas()

const filtroBusqueda = ref('')
const filtroEstado = ref('todos')
const filtroCalle = ref('todas')
const incluirEliminadas = ref(false)
const success = ref('')
let successTimer = null

const modalOpen = ref(false)
const modoEdicion = ref(false)
const formError = ref('')
const form = reactive({
  id_bombona: null,
  codigo: '',
  tipo_bombona: '',
  estado: 'disponible',
  peso_kg: '',
  id_calle: '',
  observaciones: '',
})

const confirmOpen = ref(false)
const confirmAction = ref('')
const confirmError = ref('')
const seleccionada = ref(null)

const formTitle = computed(() =>
  modoEdicion.value ? 'Editar bombona' : 'Registrar nueva bombona'
)

const bombonasActivas = computed(() => bombonas.value.filter((b) => !b.is_deleted))
const totalActivas = computed(() => bombonasActivas.value.length)
const totalDisponibles = computed(
  () => bombonasActivas.value.filter((b) => b.estado === 'disponible').length
)
const totalEnUso = computed(
  () => bombonasActivas.value.filter((b) => ['asignada', 'entregada'].includes(b.estado)).length
)
const totalMantenimiento = computed(
  () => bombonasActivas.value.filter((b) => ['mantenimiento', 'perdida'].includes(b.estado)).length
)

const bombonasFiltradas = computed(() => {
  const q = filtroBusqueda.value.trim().toLowerCase()

  return bombonas.value.filter((bombona) => {
    if (!incluirEliminadas.value && bombona.is_deleted) return false
    if (filtroEstado.value !== 'todos' && bombona.estado !== filtroEstado.value) return false
    if (
      filtroCalle.value !== 'todas' &&
      Number(bombona.id_calle) !== Number(filtroCalle.value)
    ) {
      return false
    }
    if (!q) return true
    return [bombona.codigo, bombona.observaciones, bombona.tipo_bombona]
      .some((value) => String(value || '').toLowerCase().includes(q))
  })
})

const confirmTitle = computed(() =>
  confirmAction.value === 'eliminar' ? 'Dar de baja la bombona' : 'Restaurar bombona'
)

const confirmMessage = computed(() => {
  const codigo = seleccionada.value?.codigo || 'esta bombona'
  if (confirmAction.value === 'eliminar') {
    return `¿Dar de baja ${codigo}? Dejará de aparecer en los conteos activos, pero se conservará en el historial y podrá restaurarse.`
  }
  return `¿Restaurar ${codigo}? Volverá al inventario activo con estado disponible.`
})

const confirmText = computed(() =>
  confirmAction.value === 'eliminar' ? 'Sí, dar de baja' : 'Sí, restaurar'
)

onMounted(async () => {
  await Promise.all([fetchCalles(), fetchBombonas({ incluirEliminadas: false })])
})

async function cargar() {
  await fetchBombonas({ incluirEliminadas: incluirEliminadas.value })
}

function abrirCrear() {
  modoEdicion.value = false
  formError.value = ''
  Object.assign(form, {
    id_bombona: null,
    codigo: '',
    tipo_bombona: '',
    estado: 'disponible',
    peso_kg: '',
    id_calle: '',
    observaciones: '',
  })
  modalOpen.value = true
}

function abrirEditar(bombona) {
  modoEdicion.value = true
  formError.value = ''
  Object.assign(form, {
    id_bombona: bombona.id_bombona,
    codigo: bombona.codigo || '',
    tipo_bombona: bombona.tipo_bombona || '',
    estado: bombona.estado || 'disponible',
    peso_kg: bombona.peso_kg ?? '',
    id_calle: bombona.id_calle ?? '',
    observaciones: bombona.observaciones || '',
  })
  modalOpen.value = true
}

function cerrarModal() {
  if (accionLoading.value) return
  modalOpen.value = false
}

async function guardar() {
  formError.value = ''
  if (!form.codigo.trim()) {
    formError.value = 'El código de la bombona es obligatorio.'
    return
  }
  if (!form.tipo_bombona) {
    formError.value = 'Selecciona el tipo de bombona.'
    return
  }
  if (form.peso_kg !== '' && Number(form.peso_kg) < 0) {
    formError.value = 'El peso no puede ser negativo.'
    return
  }

  const payload = {
    codigo: form.codigo,
    tipo_bombona: form.tipo_bombona,
    estado: form.estado,
    peso_kg: form.peso_kg,
    id_calle: form.id_calle,
    observaciones: form.observaciones,
  }

  const result = modoEdicion.value
    ? await actualizarBombona(form.id_bombona, payload)
    : await crearBombona(payload)

  if (!result) {
    formError.value = error.value || 'No se pudo guardar la bombona.'
    return
  }

  modalOpen.value = false
  mostrarExito(
    modoEdicion.value
      ? `Bombona ${result.codigo} actualizada correctamente.`
      : `Bombona ${result.codigo} registrada correctamente.`
  )
  await cargar()
}

function abrirConfirmacion(bombona, accion) {
  seleccionada.value = bombona
  confirmAction.value = accion
  confirmError.value = ''
  confirmOpen.value = true
}

async function ejecutarConfirmacion() {
  if (!seleccionada.value) return
  confirmError.value = ''

  const ok =
    confirmAction.value === 'eliminar'
      ? await darBajaBombona(seleccionada.value.id_bombona)
      : await restaurarBombona(seleccionada.value.id_bombona)

  if (!ok) {
    confirmError.value = error.value || 'No se pudo completar la acción.'
    return
  }

  const codigo = seleccionada.value.codigo
  confirmOpen.value = false
  mostrarExito(
    confirmAction.value === 'eliminar'
      ? `La bombona ${codigo} fue dada de baja.`
      : `La bombona ${codigo} fue restaurada.`
  )
  seleccionada.value = null
  await cargar()
}

function mostrarExito(mensaje) {
  success.value = mensaje
  if (successTimer) window.clearTimeout(successTimer)
  successTimer = window.setTimeout(() => {
    success.value = ''
  }, 5000)
}

function nombreCalle(idCalle) {
  if (!idCalle) return 'Sin asignar'
  const calle = calles.value.find((item) => Number(item.id_calle) === Number(idCalle))
  return calle?.nombre || `Calle ID ${idCalle}`
}

function etiquetaTipo(tipo) {
  const map = { '10kg': '10 kg', '18kg': '18 kg', '43kg': '43 kg' }
  return map[tipo] || tipo || '—'
}

function etiquetaEstado(estado) {
  const map = {
    disponible: 'Disponible',
    asignada: 'Asignada',
    entregada: 'Entregada',
    mantenimiento: 'Mantenimiento',
    perdida: 'Perdida',
  }
  return map[estado] || estado || '—'
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
</script>

<style scoped>
.bombonas-page {
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
  max-width: 700px;
  margin: 7px 0 0;
  color: #64748b;
  font-size: 0.88rem;
  line-height: 1.55;
}

.banner-actions {
  display: flex;
  flex-direction: column;
  gap: 9px;
}

.btn-refresh,
.btn-primary,
.btn-cancel,
.btn-row {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  min-height: 44px;
  padding: 0 16px;
  border-radius: 12px;
  font: inherit;
  font-size: 0.84rem;
  font-weight: 700;
  cursor: pointer;
  transition: background-color 150ms ease, border-color 150ms ease, color 150ms ease,
    transform 150ms ease, box-shadow 150ms ease;
}

.btn-refresh {
  border: 1px solid #bae6fd;
  background: #ffffff;
  color: #0369a1;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
}

.btn-refresh:hover:not(:disabled) {
  background: #f0f9ff;
}

.btn-primary {
  border: 1px solid #0284c7;
  background: #0ea5e9;
  color: #ffffff;
  box-shadow: 0 6px 16px -8px rgba(14, 165, 233, 0.7);
}

.btn-primary:hover:not(:disabled) {
  background: #0284c7;
  border-color: #0369a1;
}

.btn-refresh:disabled,
.btn-primary:disabled,
.btn-cancel:disabled,
.btn-row:disabled {
  opacity: 0.6;
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
}

.stat-icon svg {
  width: 20px;
  height: 20px;
}

.stat-card--blue .stat-icon { background: #eff6ff; color: #1d4ed8; }
.stat-card--green .stat-icon { background: #ecfdf5; color: #047857; }
.stat-card--amber .stat-icon { background: #fffbeb; color: #b45309; }
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

.toolbar-card {
  display: grid;
  gap: 10px;
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

.select-field {
  display: grid;
  gap: 5px;
}

.select-field > span {
  color: #64748b;
  font-size: 0.68rem;
  font-weight: 700;
  letter-spacing: 0.03em;
  text-transform: uppercase;
}

.select-field select {
  width: 100%;
  min-height: 44px;
  padding: 0 10px;
  border: 1px solid #d1d5db;
  border-radius: 11px;
  background: #ffffff;
  color: #0f172a;
  font: inherit;
  font-size: 16px;
  outline: none;
}

.select-field select:focus {
  border-color: #0ea5e9;
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.14);
}

.toggle-field {
  display: inline-flex;
  align-items: center;
  gap: 9px;
  min-height: 44px;
  padding: 0 4px;
  color: #475569;
  font-size: 0.82rem;
  font-weight: 600;
  cursor: pointer;
}

.toggle-field input {
  width: 18px;
  height: 18px;
  accent-color: #0ea5e9;
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

.table-card {
  overflow: hidden;
  border: 1px solid #e2e8f0;
  border-radius: 18px;
  background: #ffffff;
  box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
}

.table-wrapper {
  display: none;
  overflow-x: auto;
}

.custom-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.custom-table th {
  padding: 12px 14px;
  border-bottom: 1px solid #e2e8f0;
  background: #f8fafc;
  color: #64748b;
  font-size: 0.7rem;
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  white-space: nowrap;
}

.custom-table td {
  padding: 13px 14px;
  border-bottom: 1px solid #f1f5f9;
  color: #334155;
  font-size: 0.84rem;
  vertical-align: middle;
}

.custom-table tbody tr:last-child td {
  border-bottom: 0;
}

.table-row:hover {
  background: #f8fafc;
}

.table-row.is-deleted {
  background: #fafafa;
}

.table-row.is-deleted td {
  color: #94a3b8;
}

.code-cell {
  min-width: 150px;
}

.code-badge {
  display: inline-flex;
  align-items: center;
  padding: 4px 9px;
  border: 1px solid #bfdbfe;
  border-radius: 7px;
  background: #eff6ff;
  color: #1d4ed8;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-size: 0.78rem;
  font-weight: 700;
  letter-spacing: 0.02em;
}

.deleted-tag {
  display: inline-flex;
  margin-left: 7px;
  padding: 3px 7px;
  border: 1px solid #e2e8f0;
  border-radius: 999px;
  background: #f1f5f9;
  color: #64748b;
  font-size: 0.62rem;
  font-weight: 700;
  white-space: nowrap;
}

.type-badge {
  display: inline-flex;
  align-items: center;
  padding: 4px 9px;
  border: 1px solid #e2e8f0;
  border-radius: 7px;
  background: #f8fafc;
  color: #475569;
  font-size: 0.76rem;
  font-weight: 700;
  white-space: nowrap;
}

.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 4px 9px;
  border: 1px solid transparent;
  border-radius: 999px;
  font-size: 0.68rem;
  font-weight: 800;
  letter-spacing: 0.02em;
  white-space: nowrap;
}

.status-pill.is-disponible {
  border-color: #a7f3d0;
  background: #ecfdf5;
  color: #047857;
}

.status-pill.is-asignada,
.status-pill.is-entregada {
  border-color: #bfdbfe;
  background: #eff6ff;
  color: #1d4ed8;
}

.status-pill.is-mantenimiento {
  border-color: #fde68a;
  background: #fffbeb;
  color: #b45309;
}

.status-pill.is-perdida {
  border-color: #fecaca;
  background: #fef2f2;
  color: #b91c1c;
}

.muted-value {
  color: #64748b;
  font-size: 0.82rem;
}

.actions-head {
  text-align: right;
}

.row-actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 6px;
}

.btn-row {
  min-height: 36px;
  padding: 0 11px;
  border: 1px solid transparent;
  border-radius: 9px;
  font-size: 0.75rem;
}

.btn-row--edit {
  border-color: #cbd5e1;
  background: #ffffff;
  color: #475569;
}

.btn-row--edit:hover {
  border-color: #94a3b8;
  background: #f8fafc;
}

.btn-row--danger {
  border-color: #fecaca;
  background: #fef2f2;
  color: #b91c1c;
}

.btn-row--danger:hover {
  border-color: #dc2626;
  background: #dc2626;
  color: #ffffff;
}

.btn-row--success {
  border-color: #a7f3d0;
  background: #ecfdf5;
  color: #047857;
}

.btn-row--success:hover {
  border-color: #059669;
  background: #059669;
  color: #ffffff;
}

.mobile-list {
  display: grid;
  gap: 10px;
  padding: 12px;
}

.mobile-card {
  padding: 14px;
  border: 1px solid #e2e8f0;
  border-radius: 15px;
  background: #ffffff;
}

.mobile-card.is-deleted {
  background: #fafafa;
}

.mobile-card-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 10px;
}

.mobile-code {
  margin: 0;
  color: #1d4ed8;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-size: 0.92rem;
  font-weight: 800;
  overflow-wrap: anywhere;
}

.mobile-type {
  margin: 3px 0 0;
  color: #64748b;
  font-size: 0.76rem;
  font-weight: 600;
}

.mobile-details {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 9px;
  margin-top: 12px;
  padding-top: 11px;
  border-top: 1px solid #f1f5f9;
}

.mobile-details span {
  display: block;
  color: #94a3b8;
  font-size: 0.62rem;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.mobile-details strong {
  display: block;
  margin-top: 2px;
  overflow: hidden;
  color: #334155;
  font-size: 0.76rem;
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.mobile-deleted-note {
  margin: 11px 0 0;
  padding: 8px 10px;
  border: 1px solid #e2e8f0;
  border-radius: 9px;
  background: #f1f5f9;
  color: #64748b;
  font-size: 0.72rem;
  line-height: 1.45;
}

.mobile-actions {
  display: flex;
  gap: 7px;
  margin-top: 12px;
}

.mobile-actions .btn-row {
  flex: 1;
  min-height: 42px;
}

.modal-overlay {
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

.modal-panel {
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

.modal-handle {
  display: block;
  width: 42px;
  height: 4px;
  margin: 0 auto 15px;
  border-radius: 999px;
  background: #e2e8f0;
}

.modal-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.modal-eyebrow {
  margin: 0;
  color: #0369a1;
  font-size: 0.68rem;
  font-weight: 800;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

.modal-head h2 {
  margin: 4px 0 0;
  color: #0f172a;
  font-size: 1.2rem;
  font-weight: 800;
}

.modal-close {
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

.modal-close:hover {
  background: #e2e8f0;
}

.modal-form {
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

.form-field > span {
  color: #334155;
  font-size: 0.78rem;
  font-weight: 700;
}

.form-field input,
.form-field select,
.form-field textarea {
  width: 100%;
  min-height: 44px;
  padding: 10px 12px;
  border: 1px solid #d1d5db;
  border-radius: 11px;
  background: #ffffff;
  color: #0f172a;
  font: inherit;
  font-size: 16px;
  line-height: 1.4;
  outline: none;
}

.form-field textarea {
  min-height: 92px;
  resize: vertical;
}

.form-field input:focus,
.form-field select:focus,
.form-field textarea:focus {
  border-color: #0ea5e9;
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.14);
}

.form-field--full {
  grid-column: 1 / -1;
}

.form-error {
  margin: 0;
  padding: 10px 12px;
  border: 1px solid #fecaca;
  border-radius: 10px;
  background: #fef2f2;
  color: #b91c1c;
  font-size: 0.8rem;
  line-height: 1.45;
}

.modal-actions {
  display: flex;
  flex-direction: column-reverse;
  gap: 9px;
  margin-top: 4px;
}

.btn-cancel {
  border: 1px solid #cbd5e1;
  background: #ffffff;
  color: #475569;
}

.btn-cancel:hover:not(:disabled) {
  background: #f8fafc;
}

.modal-actions .btn-primary,
.modal-actions .btn-cancel {
  width: 100%;
  min-height: 44px;
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

@media (min-width: 560px) {
  .banner-actions {
    flex-direction: row;
  }

  .toolbar-card {
    grid-template-columns: minmax(0, 1fr) auto auto;
    align-items: end;
  }

  .toggle-field {
    grid-column: 1 / -1;
    justify-self: start;
  }

  .form-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .modal-actions {
    flex-direction: row;
    justify-content: flex-end;
  }

  .modal-actions .btn-primary,
  .modal-actions .btn-cancel {
    width: auto;
    min-width: 140px;
  }
}

@media (min-width: 640px) {
  .bombonas-page {
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

  .stats-grid {
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 14px;
  }

  .stat-card {
    padding: 16px;
  }

  .mobile-list {
    display: none;
  }

  .table-wrapper {
    display: block;
  }

  .modal-overlay {
    align-items: center;
    padding: 24px;
  }

  .modal-panel {
    width: 100%;
    max-width: 620px;
    max-height: 88vh;
    padding: 24px;
    border-radius: 20px;
    animation: scaleIn 0.2s ease-out;
  }

  .modal-handle {
    display: none;
  }
}

@media (min-width: 1024px) {
  .page-banner {
    padding: 28px 32px;
  }

  .toolbar-card {
    grid-template-columns: minmax(240px, 1fr) 180px 200px auto;
    align-items: center;
  }

  .toggle-field {
    grid-column: auto;
    justify-self: end;
  }
}

@keyframes scaleIn {
  from { transform: scale(0.96); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}

@media (prefers-reduced-motion: reduce) {
  .pulse-dot,
  .refresh-icon.spin,
  .spinner,
  .modal-panel {
    animation: none;
  }
}
</style>
