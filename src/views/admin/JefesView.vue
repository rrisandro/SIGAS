<template>
  <div class="jefes-page">
    <header class="page-banner">
      <div class="banner-copy">
        <span class="banner-eyebrow">
          <span class="pulse-dot" aria-hidden="true" />
          Líderes Comunales
<<<<<<< HEAD
        </div>
        <h1>Jefes de Calle Registrados</h1>
        <p>Listado de responsables asignados por sector en Supabase (5 por página)</p>
      </div>
      <div class="header-actions">
        <button class="action-btn" @click="abrirModalCrear">+ Nuevo Jefe</button>
        <button class="refresh-btn" @click="cargarJefes" :disabled="loading" title="Actualizar datos">
          <svg viewBox="0 0 24 24" class="icon" :class="{ spin: loading }">
            <path fill="currentColor" d="M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6c0 1.01-.25 1.97-.7 2.8l1.46 1.46A7.93 7.93 0 0 0 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6c0-1.01.25-1.97.7-2.8L5.24 7.74A7.93 7.93 0 0 0 4 12c0 4.42 3.58 8 8 8v3l4-4l-4-4v3z"/>
          </svg>
=======
        </span>
        <h1>Jefes de Calle</h1>
        <p>
          Administra los responsables de cada sector, su acceso al sistema y la
          calle que tienen asignada. Las bajas son lógicas y pueden revertirse.
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
          Nuevo Jefe
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)
        </button>
      </div>
    </header>

<<<<<<< HEAD
    <!-- TARJETA DE TABLA LIMPIA Y MODERNA -->
    <div class="table-card">
      <div class="table-header">
        <div>
          <h2>Directorio de Líderes</h2>
          <p>Asignación de jefes de calle por cada sector registrado</p>
        </div>
        <div class="search-box">
          <svg class="search-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
          <input v-model="filtroBusqueda" type="text" placeholder="Buscar por Cédula o Nombre..." />
        </div>
      </div>

      <div v-if="loading" class="loading-state">
        <div class="spinner"></div>
        <p>Cargando jefes de calle...</p>
      </div>

      <div v-else-if="jefesFiltrados.length === 0" class="empty-state">
        <p>No hay jefes de calle registrados actualmente con esa búsqueda.</p>
      </div>
=======
    <div v-if="error && !modalOpen && !confirmOpen" class="alert alert--error" role="alert">
      {{ error }}
    </div>
    <div v-if="success" class="alert alert--success" role="status">{{ success }}</div>

    <section class="stats-grid" aria-label="Resumen de Jefes de Calle">
      <article class="stat-card stat-card--blue">
        <span class="stat-icon" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <path stroke-linecap="round" stroke-linejoin="round" d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
            <circle cx="9" cy="7" r="4" />
            <path stroke-linecap="round" stroke-linejoin="round" d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" />
          </svg>
        </span>
        <div>
          <p class="stat-label">Total activos</p>
          <p class="stat-value">{{ totalActivos }}</p>
        </div>
      </article>
      <article class="stat-card stat-card--green">
        <span class="stat-icon" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M20 6 9 17l-5-5" />
          </svg>
        </span>
        <div>
          <p class="stat-label">Con calle</p>
          <p class="stat-value">{{ totalConCalle }}</p>
        </div>
      </article>
      <article class="stat-card stat-card--amber">
        <span class="stat-icon" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 21s7-5.4 7-11a7 7 0 1 0-14 0c0 5.6 7 11 7 11z" />
            <circle cx="12" cy="10" r="2.5" />
          </svg>
        </span>
        <div>
          <p class="stat-label">Sin calle</p>
          <p class="stat-value">{{ totalSinCalle }}</p>
        </div>
      </article>
      <article class="stat-card stat-card--red">
        <span class="stat-icon" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <circle cx="12" cy="12" r="9" />
            <path stroke-linecap="round" d="M8 12h8" />
          </svg>
        </span>
        <div>
          <p class="stat-label">Inactivos</p>
          <p class="stat-value">{{ totalInactivos }}</p>
        </div>
      </article>
    </section>
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)

    <section class="toolbar-card" aria-label="Filtros de Jefes de Calle">
      <label class="search-field">
        <span class="sr-only">Buscar Jefe de Calle</span>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" d="m21 21-4.35-4.35M19 11a8 8 0 1 1-16 0 8 8 0 0 1 16 0z" />
        </svg>
        <input v-model="filtroBusqueda" type="search" placeholder="Buscar por cédula, nombre o teléfono…" />
      </label>

      <label class="select-field">
        <span>Calle</span>
        <select v-model="filtroCalle">
          <option value="todas">Todas las calles</option>
          <option value="sin-calle">Sin calle asignada</option>
          <option v-for="calle in calles" :key="calle.id_calle" :value="calle.id_calle">
            {{ calle.nombre }}
          </option>
        </select>
      </label>

      <label class="toggle-field">
        <input v-model="incluirEliminados" type="checkbox" @change="cargar" />
        <span>Mostrar dados de baja</span>
      </label>
    </section>

    <div v-if="loading" class="state-panel">
      <span class="spinner" aria-hidden="true" />
      <p>Cargando Jefes de Calle…</p>
    </div>

    <div v-else-if="jefesFiltrados.length === 0" class="state-panel state-panel--empty">
      <span class="empty-icon" aria-hidden="true">👥</span>
      <strong>No hay Jefes de Calle en esta categoría</strong>
      <p>Registra un nuevo responsable o ajusta los filtros de búsqueda.</p>
    </div>

    <div v-else class="table-card">
      <div class="table-wrapper">
        <table class="custom-table">
          <thead>
            <tr>
              <th>Cédula</th>
<<<<<<< HEAD
              <th>Nombre Completo</th>
              <th>Calle Asignada</th>
              <th>Cargo</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="jefe in jefesPaginados" :key="jefe.id" class="table-row">
              <td class="id-cell" data-label="Cédula">V-{{ jefe.id }}</td>
              <td class="name-cell" data-label="Nombre completo">
                <div class="avatar">{{ jefe.nombre_familia ? jefe.nombre_familia.charAt(0).toUpperCase() : 'J' }}</div>
                <span class="family-name">{{ jefe.nombre_familia || 'Sin nombre' }}</span>
=======
              <th>Nombre completo</th>
              <th>Teléfono</th>
              <th>Calle asignada</th>
              <th>Acceso</th>
              <th>Estado</th>
              <th class="actions-head">Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="jefe in jefesFiltrados"
              :key="jefe.id_jefe_calle"
              class="table-row"
              :class="{ 'is-deleted': jefe.is_deleted }"
            >
              <td class="id-cell" data-label="Cédula">
                {{ jefe.ci ? `V-${jefe.ci}` : '—' }}
              </td>
              <td data-label="Nombre completo">
                <div class="name-cell">
                  <div class="avatar">{{ inicial(jefe.nombre) }}</div>
                  <div class="name-copy">
                    <span class="family-name">{{ jefe.nombre || 'Sin nombre' }}</span>
                    <span v-if="jefe.is_deleted" class="deleted-tag">Dado de baja</span>
                  </div>
                </div>
              </td>
              <td data-label="Teléfono">
                <span class="muted-value">{{ jefe.telefono || 'No indicado' }}</span>
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)
              </td>
              <td data-label="Calle asignada">
                <span class="badge-calle">{{ nombreCalle(jefe.id_calle) }}</span>
              </td>
              <td data-label="Acceso">
                <span class="access-pill" :class="{ linked: Boolean(jefe.auth_id) }">
                  {{ jefe.auth_id ? 'Vinculado' : 'Sin acceso' }}
                </span>
              </td>
              <td data-label="Estado">
                <span class="status-pill" :class="estadoClase(jefe)">
                  {{ estadoLabel(jefe) }}
                </span>
              </td>
              <td data-label="Acciones">
                <div class="row-actions">
                  <template v-if="!jefe.is_deleted">
                    <button type="button" class="btn-row btn-row--edit" @click="abrirEditar(jefe)">
                      Editar
                    </button>
                    <button
                      type="button"
                      class="btn-row"
                      :class="jefe.activo ? 'btn-row--warning' : 'btn-row--success'"
                      @click="abrirConfirmacion(jefe, jefe.activo ? 'desactivar' : 'activar')"
                    >
                      {{ jefe.activo ? 'Desactivar' : 'Activar' }}
                    </button>
                    <button
                      type="button"
                      class="btn-row btn-row--danger"
                      @click="abrirConfirmacion(jefe, 'baja')"
                    >
                      Dar de baja
                    </button>
                  </template>
                  <button
                    v-else
                    type="button"
                    class="btn-row btn-row--success"
                    @click="abrirConfirmacion(jefe, 'restaurar')"
                  >
                    Restaurar
                  </button>
                </div>
              </td>
              <td data-label="Acciones" class="actions-cell">
                <button class="btn-edit" @click="abrirModalEditar(jefe)">
                   Editar
                </button>
                <button class="btn-delete" @click="confirmarEliminacion(jefe)">
                   Eliminar
                </button>
              </td>
            </tr>
          </tbody>
        </table>

        <!-- PAGINADOR A 5 REGISTROS -->
        <div v-if="jefesFiltrados.length > 5" class="pagination-footer">
          <span>Página {{ paginaActual }} de {{ totalPaginas }} ({{ jefesFiltrados.length }} jefes en total)</span>
          <div class="pagination-buttons">
            <button class="btn-page" :disabled="paginaActual === 1" @click="paginaActual--">
              ◀ Anterior
            </button>
            <button class="btn-page" :disabled="paginaActual === totalPaginas" @click="paginaActual++">
              Siguiente ▶
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- MODAL CREAR / EDITAR JEFE DE CALLE -->
    <div v-if="mostrarModal" class="modal-overlay" @click.self="cerrarModal">
      <div class="modal-card" role="dialog" aria-modal="true">
        <span class="modal-sheet-handle" aria-hidden="true"></span>
        <h3>{{ esEdicion ? 'Editar Jefe de Calle' : 'Asignar Nuevo Jefe de Calle' }}</h3>
        
        <form @submit.prevent="guardarJefe" class="modal-form">
          <div class="field">
            <label class="field-label">Nombre del Líder / Jefe</label>
            <input 
              v-model="form.nombre_familia" 
              type="text" 
              placeholder="Ej: Pedro Pérez" 
              required 
              class="input-field" 
            />
          </div>

          <div class="field">
            <label class="field-label">Calle Asignada</label>
            <select v-model="form.id_calle" class="input-field select-field" required>
              <option :value="null" disabled>Selecciona una calle</option>
              <option v-for="calle in calles" :key="calle.id_calle" :value="calle.id_calle">
                {{ calle.nombre }}
              </option>
            </select>
          </div>

          <div class="btn-group">
            <button type="submit" class="button1" :disabled="guardando">
              {{ guardando ? 'Guardando...' : (esEdicion ? 'Actualizar' : 'Guardar') }}
            </button>
            <button type="button" class="button2" @click="cerrarModal">Cancelar</button>
          </div>
        </form>
      </div>

      <div class="mobile-list" role="list">
        <article
          v-for="jefe in jefesFiltrados"
          :key="`card-${jefe.id_jefe_calle}`"
          class="mobile-card"
          :class="{ 'is-deleted': jefe.is_deleted }"
          role="listitem"
        >
          <div class="mobile-card-head">
            <div class="name-cell">
              <div class="avatar">{{ inicial(jefe.nombre) }}</div>
              <div class="name-copy">
                <p class="mobile-name">{{ jefe.nombre || 'Sin nombre' }}</p>
                <p class="mobile-id">{{ jefe.ci ? `V-${jefe.ci}` : 'Sin cédula' }}</p>
              </div>
            </div>
            <span class="status-pill" :class="estadoClase(jefe)">{{ estadoLabel(jefe) }}</span>
          </div>

          <div class="mobile-details">
            <div>
              <span>Calle</span>
              <strong>{{ nombreCalle(jefe.id_calle) }}</strong>
            </div>
            <div>
              <span>Teléfono</span>
              <strong>{{ jefe.telefono || 'No indicado' }}</strong>
            </div>
            <div>
              <span>Acceso</span>
              <strong>{{ jefe.auth_id ? 'Vinculado' : 'Sin acceso' }}</strong>
            </div>
          </div>

          <p v-if="jefe.is_deleted" class="mobile-deleted-note">
            Este Jefe de Calle fue dado de baja lógicamente y no recibe notificaciones.
          </p>

          <div class="mobile-actions">
            <template v-if="!jefe.is_deleted">
              <button type="button" class="btn-row btn-row--edit" @click="abrirEditar(jefe)">
                Editar
              </button>
              <button
                type="button"
                class="btn-row"
                :class="jefe.activo ? 'btn-row--warning' : 'btn-row--success'"
                @click="abrirConfirmacion(jefe, jefe.activo ? 'desactivar' : 'activar')"
              >
                {{ jefe.activo ? 'Desactivar' : 'Activar' }}
              </button>
              <button
                type="button"
                class="btn-row btn-row--danger"
                @click="abrirConfirmacion(jefe, 'baja')"
              >
                Dar de baja
              </button>
            </template>
            <button
              v-else
              type="button"
              class="btn-row btn-row--success"
              @click="abrirConfirmacion(jefe, 'restaurar')"
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
              <p class="modal-eyebrow">{{ modoEdicion ? 'Editar responsable' : 'Nuevo responsable' }}</p>
              <h2>{{ formTitle }}</h2>
            </div>
            <button type="button" class="modal-close" aria-label="Cerrar" @click="cerrarModal">×</button>
          </div>

          <form class="modal-form" @submit.prevent="guardar">
            <div class="form-grid">
              <label class="form-field form-field--full">
                <span>Nombre completo *</span>
                <input v-model="form.nombre" type="text" maxlength="120" placeholder="Nombre y apellido" required />
              </label>

              <label class="form-field">
                <span>Cédula</span>
                <input v-model="form.ci" type="text" maxlength="20" placeholder="Ej. 12345678" />
              </label>

              <label class="form-field">
                <span>Teléfono</span>
                <input v-model="form.telefono" type="tel" maxlength="30" placeholder="0414-1234567" />
              </label>

              <label class="form-field">
                <span>Calle asignada</span>
                <select v-model="form.id_calle">
                  <option value="">Sin calle asignada</option>
                  <option v-for="calle in callesDisponibles" :key="calle.id_calle" :value="calle.id_calle">
                    {{ calle.nombre }}
                  </option>
                </select>
              </label>

              <label class="form-field">
                <span>ID de acceso (opcional)</span>
                <input
                  v-model="form.auth_id"
                  type="text"
                  placeholder="UUID de auth.users"
                  autocomplete="off"
                />
                <small>Vincula esta ficha con una cuenta de Supabase Auth.</small>
              </label>

              <label class="checkbox-field form-field--full">
                <input v-model="form.activo" type="checkbox" />
                <span>Jefe de Calle activo (recibe notificaciones y puede gestionar su calle)</span>
              </label>
            </div>

            <p v-if="formError" class="form-error" role="alert">{{ formError }}</p>

            <div class="modal-actions">
              <button type="button" class="btn-cancel" :disabled="accionLoading" @click="cerrarModal">
                Cancelar
              </button>
              <button type="submit" class="btn-primary" :disabled="accionLoading">
                {{ accionLoading ? 'Guardando…' : modoEdicion ? 'Guardar cambios' : 'Registrar Jefe' }}
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
      :confirm-variant="confirmVariant"
      :tone="confirmTone"
      :loading="accionLoading"
      :error="confirmError"
      @confirm="ejecutarConfirmacion"
    />
  </div>
</template>

<script setup>
<<<<<<< HEAD
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '../../lib/supabase.js' // Ruta ajustada a la librería estándar del proyecto

const jefes = ref([])
const calles = ref([])
const filtroBusqueda = ref('')
const loading = ref(true)
const guardando = ref(false)

// Paginación
const paginaActual = ref(1)
const porPagina = 5

// Estado de Modales
const mostrarModal = ref(false)
const esEdicion = ref(false)
const jefeIdSeleccionado = ref(null)

const form = ref({
  nombre_familia: '',
  id_calle: null
})

async function cargarJefes() {
  loading.value = true
  try {
    const { data: callesData } = await supabase.from('calles').select('*').order('nombre')
    if (callesData) calles.value = callesData

    // Cargo ID 2 = Jefe de Calle
    const { data, error } = await supabase
      .from('familias')
      .select('*')
      .eq('id_cargo', 2)
      .order('id', { ascending: true })
=======
import { computed, onMounted, reactive, ref } from 'vue'
import ConfirmDialog from '../../components/ui/ConfirmDialog.vue'
import { useJefesCalle } from '../../composables/useJefesCalle.js'

const {
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
} = useJefesCalle()

const filtroBusqueda = ref('')
const filtroCalle = ref('todas')
const incluirEliminados = ref(false)
const success = ref('')
let successTimer = null

const modalOpen = ref(false)
const modoEdicion = ref(false)
const formError = ref('')
const form = reactive({
  id_jefe_calle: null,
  nombre: '',
  ci: '',
  telefono: '',
  id_calle: '',
  auth_id: '',
  activo: true,
})
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)

const confirmOpen = ref(false)
const confirmAction = ref('')
const confirmError = ref('')
const seleccionado = ref(null)

const formTitle = computed(() =>
  modoEdicion.value ? 'Editar Jefe de Calle' : 'Registrar Jefe de Calle'
)

const callesDisponibles = computed(() => {
  const jefeActual = Number(form.id_jefe_calle)

  return calles.value.filter((calle) => {
    if (!calle.id_jefe_calle) return true
    if (Number(calle.id_jefe_calle) === jefeActual) return true

    const ocupante = jefes.value.find(
      (jefe) => Number(jefe.id_jefe_calle) === Number(calle.id_jefe_calle)
    )

    return !ocupante || ocupante.is_deleted || !ocupante.activo
  })
})

const jefesActivos = computed(() => jefes.value.filter((jefe) => !jefe.is_deleted))
const totalActivos = computed(() => jefesActivos.value.length)
const totalConCalle = computed(
  () => jefesActivos.value.filter((jefe) => Boolean(jefe.id_calle)).length
)
const totalSinCalle = computed(
  () => jefesActivos.value.filter((jefe) => !jefe.id_calle).length
)
const totalInactivos = computed(
  () => jefesActivos.value.filter((jefe) => !jefe.activo).length
)

const jefesFiltrados = computed(() => {
  const q = filtroBusqueda.value.trim().toLowerCase()

  return jefes.value.filter((jefe) => {
    if (!incluirEliminados.value && jefe.is_deleted) return false
    if (filtroCalle.value === 'sin-calle' && jefe.id_calle) return false
    if (
      filtroCalle.value !== 'todas' &&
      filtroCalle.value !== 'sin-calle' &&
      Number(jefe.id_calle) !== Number(filtroCalle.value)
    ) {
      return false
    }
    if (!q) return true
    return [jefe.nombre, jefe.ci, jefe.telefono]
      .some((value) => String(value || '').toLowerCase().includes(q))
  })
})

const confirmTitle = computed(() => {
  const nombre = seleccionado.value?.nombre || 'este Jefe de Calle'
  const titles = {
    baja: 'Dar de baja al Jefe de Calle',
    restaurar: 'Restaurar Jefe de Calle',
    desactivar: 'Desactivar Jefe de Calle',
    activar: 'Activar Jefe de Calle',
  }
  return titles[confirmAction.value] || `Actualizar a ${nombre}`
})

const confirmMessage = computed(() => {
  const nombre = seleccionado.value?.nombre || 'este Jefe de Calle'
  const calle = nombreCalle(seleccionado.value?.id_calle)

  if (confirmAction.value === 'baja') {
    return `¿Dar de baja a ${nombre}? Dejará de recibir notificaciones y no podrá gestionar ${calle}. La ficha se conservará y podrá restaurarse.`
  }
  if (confirmAction.value === 'restaurar') {
    return `¿Restaurar a ${nombre}? Volverá a estar activo y se le asignará ${calle}.`
  }
  if (confirmAction.value === 'desactivar') {
    return `¿Desactivar a ${nombre}? Su cuenta seguirá existiendo, pero no podrá gestionar ${calle} ni recibir notificaciones.`
  }
  if (confirmAction.value === 'activar') {
    return `¿Activar a ${nombre}? Volverá a gestionar ${calle} y recibirá las notificaciones de su zona.`
  }
  return ''
})

const confirmText = computed(() => {
  const texts = {
    baja: 'Sí, dar de baja',
    restaurar: 'Sí, restaurar',
    desactivar: 'Sí, desactivar',
    activar: 'Sí, activar',
  }
  return texts[confirmAction.value] || 'Confirmar'
})

const confirmVariant = computed(() =>
  ['baja', 'desactivar'].includes(confirmAction.value) ? 'danger' : 'success'
)

const confirmTone = computed(() =>
  ['baja', 'desactivar'].includes(confirmAction.value) ? 'danger' : 'success'
)

onMounted(async () => {
  await Promise.all([fetchCalles(), fetchJefes({ incluirEliminados: false })])
})

async function cargar() {
  await Promise.all([
    fetchCalles(),
    fetchJefes({ incluirEliminados: incluirEliminados.value }),
  ])
}

<<<<<<< HEAD
function abrirModalCrear() {
  esEdicion.value = false
  jefeIdSeleccionado.value = null
  form.value = { nombre_familia: '', id_calle: null }
  mostrarModal.value = true
}

function abrirModalEditar(jefe) {
  esEdicion.value = true
  jefeIdSeleccionado.value = jefe.id
  form.value = {
    nombre_familia: jefe.nombre_familia,
    id_calle: jefe.id_calle
  }
  mostrarModal.value = true
}

function cerrarModal() {
  mostrarModal.value = false
}

async function guardarJefe() {
  guardando.value = true

  if (esEdicion.value) {
    const { error } = await supabase
      .from('familias')
      .update({
        nombre_familia: form.value.nombre_familia,
        id_calle: form.value.id_calle
      })
      .eq('id', jefeIdSeleccionado.value)

    if (!error) {
      cerrarModal()
      await cargarJefes()
    } else {
      alert('Error al actualizar el Jefe de Calle: ' + error.message)
    }
  } else {
    // Inserta asignando directamente el id_cargo = 2
    const { error } = await supabase
      .from('familias')
      .insert([{
        nombre_familia: form.value.nombre_familia,
        id_calle: form.value.id_calle,
        id_cargo: 2,
        activo: true
      }])

    if (!error) {
      cerrarModal()
      await cargarJefes()
    } else {
      alert('Error al registrar Jefe de Calle: ' + error.message)
    }
  }

  guardando.value = false
}

async function confirmarEliminacion(jefe) {
  const confirmacion = confirm(`¿Deseas remover el cargo de Jefe de Calle a "${jefe.nombre_familia}"? Pasará a ser registrado como Familia normal.`)
  
  if (confirmacion) {
    // Cambia el cargo a 3 (Familia), ejecutando el trigger bidireccional en PostgreSQL
    const { error } = await supabase
      .from('familias')
      .update({ id_cargo: 3 })
      .eq('id', jefe.id)

    if (error) {
      alert('Error al remover el cargo de Jefe de Calle: ' + error.message)
    } else {
      await cargarJefes()
    }
  }
}

function obtenerNombreCalle(idCalle) {
  const c = calles.value.find((item) => item.id_calle === idCalle)
  return c ? c.nombre : `Calle ID ${idCalle}`
}

onMounted(cargarJefes)

watch(filtroBusqueda, () => {
  paginaActual.value = 1
})

const jefesFiltrados = computed(() => {
  if (!filtroBusqueda.value.trim()) return jefes.value
  const query = filtroBusqueda.value.toLowerCase().trim()
  return jefes.value.filter(
    (j) =>
      String(j.id).includes(query) ||
      (j.nombre_familia && j.nombre_familia.toLowerCase().includes(query))
  )
})

const totalPaginas = computed(() => {
  return Math.ceil(jefesFiltrados.value.length / porPagina) || 1
})

const jefesPaginados = computed(() => {
  const inicio = (paginaActual.value - 1) * porPagina
  return jefesFiltrados.value.slice(inicio, inicio + porPagina)
})
=======
function abrirCrear() {
  modoEdicion.value = false
  formError.value = ''
  Object.assign(form, {
    id_jefe_calle: null,
    nombre: '',
    ci: '',
    telefono: '',
    id_calle: '',
    auth_id: '',
    activo: true,
  })
  modalOpen.value = true
}

function abrirEditar(jefe) {
  modoEdicion.value = true
  formError.value = ''
  Object.assign(form, {
    id_jefe_calle: jefe.id_jefe_calle,
    nombre: jefe.nombre || '',
    ci: jefe.ci || '',
    telefono: jefe.telefono || '',
    id_calle: jefe.id_calle ?? '',
    auth_id: jefe.auth_id || '',
    activo: Boolean(jefe.activo),
  })
  modalOpen.value = true
}

function cerrarModal() {
  if (accionLoading.value) return
  modalOpen.value = false
}

async function guardar() {
  formError.value = ''

  if (!form.nombre.trim()) {
    formError.value = 'El nombre del Jefe de Calle es obligatorio.'
    return
  }

  if (form.auth_id && !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(form.auth_id.trim())) {
    formError.value = 'El ID de acceso debe ser un UUID válido de Supabase Auth.'
    return
  }

  if (form.id_calle) {
    const calle = calles.value.find(
      (item) => Number(item.id_calle) === Number(form.id_calle)
    )
    const ocupanteId = calle?.id_jefe_calle

    if (ocupanteId && Number(ocupanteId) !== Number(form.id_jefe_calle)) {
      const ocupante = jefes.value.find(
        (jefe) => Number(jefe.id_jefe_calle) === Number(ocupanteId)
      )

      if (ocupante && !ocupante.is_deleted && ocupante.activo) {
        formError.value = 'Esa calle ya está asignada a otro Jefe de Calle activo.'
        return
      }
    }
  }

  const payload = {
    nombre: form.nombre,
    ci: form.ci,
    telefono: form.telefono,
    id_calle: form.id_calle,
    auth_id: form.auth_id,
    activo: form.activo,
  }

  const result = modoEdicion.value
    ? await actualizarJefe(form.id_jefe_calle, payload)
    : await crearJefe(payload)

  if (!result) {
    formError.value = error.value || 'No se pudo guardar el Jefe de Calle.'
    return
  }

  modalOpen.value = false
  mostrarExito(
    modoEdicion.value
      ? `Jefe de Calle ${result.nombre} actualizado correctamente.`
      : `Jefe de Calle ${result.nombre} registrado correctamente.`
  )
  await cargar()
}

function abrirConfirmacion(jefe, accion) {
  seleccionado.value = jefe
  confirmAction.value = accion
  confirmError.value = ''
  confirmOpen.value = true
}

async function ejecutarConfirmacion() {
  if (!seleccionado.value) return
  confirmError.value = ''

  let ok = false
  if (confirmAction.value === 'baja') {
    ok = await darBajaJefe(seleccionado.value.id_jefe_calle)
  } else if (confirmAction.value === 'restaurar') {
    ok = await restaurarJefe(seleccionado.value.id_jefe_calle)
  } else if (confirmAction.value === 'desactivar') {
    ok = await cambiarActivo(seleccionado.value.id_jefe_calle, false)
  } else if (confirmAction.value === 'activar') {
    ok = await cambiarActivo(seleccionado.value.id_jefe_calle, true)
  }

  if (!ok) {
    confirmError.value = error.value || 'No se pudo completar la acción.'
    return
  }

  const nombre = seleccionado.value.nombre
  const mensajes = {
    baja: `Se dio de baja a ${nombre}.`,
    restaurar: `Se restauró a ${nombre}.`,
    desactivar: `${nombre} fue desactivado.`,
    activar: `${nombre} fue activado.`,
  }

  confirmOpen.value = false
  mostrarExito(mensajes[confirmAction.value] || 'Acción completada.')
  seleccionado.value = null
  await cargar()
}

function mostrarExito(mensaje) {
  success.value = mensaje
  if (successTimer) window.clearTimeout(successTimer)
  successTimer = window.setTimeout(() => {
    success.value = ''
  }, 5000)
}

function inicial(nombre) {
  return String(nombre || 'J').trim().charAt(0).toUpperCase() || 'J'
}

function nombreCalle(idCalle) {
  if (!idCalle) return 'sin calle asignada'
  const calle = calles.value.find((item) => Number(item.id_calle) === Number(idCalle))
  return calle?.nombre || `Calle ID ${idCalle}`
}

function estadoLabel(jefe) {
  if (jefe.is_deleted) return 'Dado de baja'
  return jefe.activo ? 'Activo' : 'Inactivo'
}

function estadoClase(jefe) {
  if (jefe.is_deleted) return 'is-deleted'
  return jefe.activo ? 'is-active' : 'is-inactive'
}
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)
</script>

<style scoped>
.jefes-page {
  display: flex;
  flex-direction: column;
<<<<<<< HEAD
  gap: 1.25rem;
  background-color: transparent !important;
  min-height: 0;
  box-sizing: border-box;
=======
  gap: 18px;
  color: #0f172a;
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)
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

<<<<<<< HEAD
.header-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.action-btn { 
=======
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
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)
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

<<<<<<< HEAD
.action-btn:hover:not(:disabled) { 
  background: #005aa3; 
  transform: translateY(-1px); 
}

.refresh-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f1f5f9;
  color: #475569;
  border: 1px solid #cbd5e1;
  padding: 0.75rem;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.refresh-btn:hover:not(:disabled) {
  background: #e2e8f0;
  color: #0f172a;
}

.refresh-btn .icon {
=======
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
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)
  width: 18px;
  height: 18px;
  accent-color: #0ea5e9;
}

<<<<<<< HEAD
.refresh-btn .icon.spin {
  animation: spin 1s linear infinite;
}

@keyframes spin { 
  100% { transform: rotate(360deg); } 
}

.table-card { 
  background: #ffffff; 
  border: 1px solid #e2e8f0; 
  border-radius: 18px; 
  padding: 1.6rem; 
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.03); 
}

.table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  flex-wrap: wrap;
  gap: 1rem;
}

.table-header h2 {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 700;
  color: #0f172a;
}

.table-header p {
  margin: 0.2rem 0 0 0;
  font-size: 0.85rem;
  color: #64748b;
}

.search-box {
  position: relative;
  width: 100%;
  max-width: 300px;
}

.search-box input {
  width: 100%;
  background: #f8fafc;
  border: 1px solid #cbd5e1;
  padding: 0.65rem 1rem 0.65rem 2.4rem;
  border-radius: 10px;
  color: #0f172a;
  outline: none;
  font-family: 'Plus Jakarta Sans', sans-serif;
  font-size: 0.85rem;
  transition: all 0.2s ease;
}

.search-box input::placeholder {
  color: #94a3b8;
}

.search-box input:focus {
  border-color: #0072CE;
  background: #ffffff;
  box-shadow: 0 0 0 3px rgba(0, 114, 206, 0.1);
}

.search-icon {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  width: 16px;
  height: 16px;
  color: #94a3b8;
}

.table-wrapper { 
  overflow-x: auto; 
=======
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
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)
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

.id-cell {
  color: #0369a1;
  font-weight: 700;
  white-space: nowrap;
}

.name-cell {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}

.name-copy {
  display: flex;
  flex-direction: column;
  gap: 3px;
  min-width: 0;
}

.family-name {
  overflow: hidden;
  color: #0f172a;
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.avatar {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 34px;
  height: 34px;
  border-radius: 9px;
  background: #eff6ff;
  color: #1d4ed8;
  font-size: 0.8rem;
  font-weight: 800;
}

.deleted-tag {
  display: inline-flex;
  width: fit-content;
  padding: 2px 7px;
  border: 1px solid #e2e8f0;
  border-radius: 999px;
  background: #f1f5f9;
  color: #64748b;
  font-size: 0.6rem;
  font-weight: 700;
  white-space: nowrap;
}

.badge-calle {
  display: inline-flex;
  padding: 4px 9px;
  border: 1px solid #e2e8f0;
  border-radius: 7px;
  background: #f1f5f9;
  color: #475569;
  font-size: 0.76rem;
  font-weight: 600;
  white-space: nowrap;
}

.access-pill {
  display: inline-flex;
  padding: 3px 8px;
  border: 1px solid #e2e8f0;
  border-radius: 999px;
  background: #f8fafc;
  color: #64748b;
  font-size: 0.66rem;
  font-weight: 700;
  white-space: nowrap;
}

.access-pill.linked {
  border-color: #bfdbfe;
  background: #eff6ff;
  color: #1d4ed8;
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

.status-pill.is-active {
  border-color: #a7f3d0;
  background: #ecfdf5;
  color: #047857;
}

.status-pill.is-inactive {
  border-color: #fde68a;
  background: #fffbeb;
  color: #b45309;
}

.status-pill.is-deleted {
  border-color: #fecaca;
  background: #fef2f2;
  color: #b91c1c;
}

.muted-value {
  color: #64748b;
  font-size: 0.82rem;
  white-space: nowrap;
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

.btn-row--warning {
  border-color: #fde68a;
  background: #fffbeb;
  color: #b45309;
}

.btn-row--warning:hover {
  border-color: #d97706;
  background: #d97706;
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

.mobile-name {
  margin: 0;
  overflow: hidden;
  color: #0f172a;
  font-size: 0.9rem;
  font-weight: 800;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.mobile-id {
  margin: 2px 0 0;
  color: #64748b;
  font-size: 0.72rem;
  font-weight: 600;
}

<<<<<<< HEAD
.actions-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-edit {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  background-color: #f0f9ff;
  color: #0284c7;
  border: 1px solid #bae6fd;
  padding: 5px 11px;
  border-radius: 8px;
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-edit:hover {
  background-color: #0284c7;
  color: #ffffff;
  border-color: #0284c7;
  box-shadow: 0 2px 6px rgba(2, 132, 199, 0.25);
}

.btn-delete {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  background-color: #fef2f2;
  color: #dc2626;
  border: 1px solid #fecaca;
  padding: 5px 11px;
  border-radius: 8px;
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-delete:hover {
  background-color: #dc2626;
  color: #ffffff;
  border-color: #dc2626;
  box-shadow: 0 2px 6px rgba(220, 38, 38, 0.25);
}

.pagination-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 1rem;
  border-top: 1px solid #f1f5f9;
  font-size: 0.85rem;
  color: #64748b;
}

.pagination-buttons {
  display: flex;
  gap: 0.5rem;
}

.btn-page {
  padding: 0.35rem 0.75rem;
  background-color: #f8fafc;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  cursor: pointer;
  font-weight: 500;
  color: #334155;
  transition: all 0.2s ease;
}

.btn-page:hover:not(:disabled) {
  background-color: #e2e8f0;
}

.btn-page:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.field-label {
  font-size: 0.85rem;
  color: #475569;
  font-weight: 500;
  margin-bottom: 0.3rem;
  display: block;
}

.select-field {
  width: 100%;
  padding: 0.75rem 1rem;
  border-radius: 10px;
  background: #f8fafc;
  color: #0f172a;
  border: 1px solid #cbd5e1;
  font-family: 'Plus Jakarta Sans', sans-serif;
  font-size: 0.9rem;
  outline: none;
}

.select-field:focus {
  border-color: #0072CE;
  background: #ffffff;
  box-shadow: 0 0 0 3px rgba(0, 114, 206, 0.1);
}

.loading-state, .empty-state { 
  text-align: center; 
  padding: 3rem; 
  color: #64748b; 
=======
.mobile-details {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 9px;
  margin-top: 12px;
  padding-top: 11px;
  border-top: 1px solid #f1f5f9;
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)
}

.mobile-details span {
  display: block;
  color: #94a3b8;
  font-size: 0.62rem;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

<<<<<<< HEAD
.modal-overlay { 
  position: fixed; 
  inset: 0; 
  background: rgba(0, 0, 0, 0.5); 
  display: flex; 
  justify-content: center; 
  align-items: center; 
  z-index: 100; 
  backdrop-filter: blur(4px); 
}

.modal-card { 
  background: #ffffff; 
  padding: 2rem; 
  border-radius: 20px; 
  width: 400px; 
  border: 1px solid #e2e8f0; 
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1); 
}

.modal-card h3 {
  margin-top: 0;
  color: #0f172a;
  font-size: 1.25rem;
  font-weight: 600;
  margin-bottom: 1.25rem;
  text-align: center;
}

.modal-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.field { 
  margin-bottom: 0.5rem; 
}

.input-field { 
  width: 100%; 
  padding: 0.75rem 1rem; 
  border-radius: 10px; 
  background: #f8fafc; 
  border: 1px solid #cbd5e1; 
  color: #0f172a; 
  outline: none; 
  font-family: 'Plus Jakarta Sans', sans-serif;
  font-size: 0.9rem;
  transition: all 0.2s ease;
}

.input-field:focus {
  border-color: #0072CE;
  background: #ffffff;
  box-shadow: 0 0 0 3px rgba(0, 114, 206, 0.1);
}

.btn-group { 
  display: flex; 
  gap: 10px; 
  margin-top: 0.5rem;
}

.button1 { 
  flex: 1; 
  padding: 0.75rem; 
  border-radius: 10px; 
  border: none; 
  background: #0072CE; 
  color: white; 
  font-weight: 600; 
  font-size: 0.9rem;
  cursor: pointer; 
  transition: background 0.2s ease;
}

.button1:hover {
  background: #005aa3;
}

.button2 { 
  flex: 1; 
  padding: 0.75rem; 
  border-radius: 10px; 
  border: 1px solid #cbd5e1; 
  background: #ffffff; 
  color: #475569; 
  font-weight: 600;
  font-size: 0.9rem;
  cursor: pointer; 
  transition: all 0.2s ease;
}

.button2:hover {
  background: #f1f5f9;
  color: #0f172a;
=======
.mobile-details strong {
  display: block;
  margin-top: 2px;
  overflow: hidden;
  color: #334155;
  font-size: 0.76rem;
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)
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
  flex-wrap: wrap;
  gap: 7px;
  margin-top: 12px;
}

.mobile-actions .btn-row {
  flex: 1 1 90px;
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

.form-field small {
  color: #94a3b8;
  font-size: 0.7rem;
  line-height: 1.4;
}

.form-field--full {
  grid-column: 1 / -1;
}

.checkbox-field {
  display: flex;
  align-items: flex-start;
  gap: 9px;
  color: #475569;
  font-size: 0.8rem;
  line-height: 1.45;
  cursor: pointer;
}

.checkbox-field input {
  width: 18px;
  height: 18px;
  margin-top: 1px;
  flex-shrink: 0;
  accent-color: #0ea5e9;
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
    grid-template-columns: minmax(0, 1fr) auto;
    align-items: end;
  }

<<<<<<< HEAD
  .header-actions {
    flex-direction: column;
    width: 100%;
  }

  .action-btn, .refresh-btn {
    justify-content: center;
    width: 100%;
    min-height: 44px;
=======
  .toggle-field {
    grid-column: 1 / -1;
    justify-self: start;
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)
  }

  .form-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

<<<<<<< HEAD
  .table-header {
    flex-direction: column;
    align-items: stretch;
    margin-bottom: 1rem;
  }

  .search-box {
    max-width: none;
  }

  .modal-overlay {
    align-items: flex-end;
    padding: 0;
  }

  .modal-card {
    width: 100%;
    border-radius: 20px 20px 0 0;
  }

  .btn-group {
    flex-direction: column;
=======
  .modal-actions {
    flex-direction: row;
    justify-content: flex-end;
  }

  .modal-actions .btn-primary,
  .modal-actions .btn-cancel {
    width: auto;
    min-width: 140px;
>>>>>>> 9502f04 (feat: login renovado, registros pendientes y notificaciones)
  }
}

@media (min-width: 640px) {
  .jefes-page {
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

  .modal-overlay {
    align-items: center;
  }

  .modal-card {
    width: 400px;
    border-radius: 18px;
  }
}

@media (min-width: 1024px) {
  .page-banner {
    padding: 28px 32px;
  }

  .toolbar-card {
    grid-template-columns: minmax(260px, 1fr) 220px auto;
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
