<template>
  <div class="admin-dashboard">
    <!-- CABECERA PRINCIPAL -->
    <header class="header-banner">
      <div class="banner-content">
        <div class="badge">
          <span class="pulse-dot"></span>
          Panel de Control General
        </div>
        <h1>Gestión de Administración — SIGAS</h1>
        <p>Monitoreo del ciclo activo y control centralizado del sistema</p>
      </div>
      <button class="refresh-btn" @click="cargarDatos" :disabled="loading">
        <svg viewBox="0 0 24 24" class="icon" :class="{ spin: loading }">
          <path fill="currentColor" d="M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6c0 1.01-.25 1.97-.7 2.8l1.46 1.46A7.93 7.93 0 0 0 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6c0-1.01.25-1.97.7-2.8L5.24 7.74A7.93 7.93 0 0 0 4 12c0 4.42 3.58 8 8 8v3l4-4l-4-4v3z"/>
        </svg>
        Actualizar Datos
      </button>
    </header>

    <!-- BANNER SI NO HAY CICLO ACTIVO -->
    <div v-if="!loading && !cicloActivo" class="alert-banner">
      ⚠️ <strong>Atención:</strong> No hay un ciclo de distribución activo en este momento. La información mostrada corresponde al último estado del sistema.
    </div>

    <!-- TARJETAS DE MÉTRICAS (DEL CICLO ACTIVO) -->
    <div class="metrics-grid">
      <div class="metric-card border-blue">
        <div class="card-icon blue">
          <svg viewBox="0 0 24 24"><path fill="currentColor" d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05c1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"/></svg>
        </div>
        <div class="metric-info">
          <h3>Ciclo Actual</h3>
          <p class="number-text">{{ cicloActivo?.nombre_ciclo || 'Sin Ciclo' }}</p>
          <span class="subtext">Jornada en curso</span>
        </div>
      </div>

      <div class="metric-card border-cyan">
        <div class="card-icon cyan">
          <svg viewBox="0 0 24 24"><path fill="currentColor" d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-2 10h-4v4h-2v-4H7v-2h4V7h2v4h4v2z"/></svg>
        </div>
        <div class="metric-info">
          <h3>Total Solicitudes</h3>
          <p class="number">{{ pedidosCiclo.length }}</p>
          <span class="subtext">Pedidos en este ciclo</span>
        </div>
      </div>

      <div class="metric-card border-amber">
        <div class="card-icon amber">
          <svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 15h-2v-6h2v6zm0-8h-2V7h2v2z"/></svg>
        </div>
        <div class="metric-info">
          <h3>Pendientes</h3>
          <p class="number">{{ totalPendientes }}</p>
          <span class="subtext">Por entregar</span>
        </div>
      </div>

      <div class="metric-card border-green">
        <div class="card-icon green">
          <svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 2A10 10 0 0 0 2 12a10 10 0 0 0 10 10a10 10 0 0 0 10-10A10 10 0 0 0 12 2zm-2 15l-5-5l1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>
        </div>
        <div class="metric-info">
          <h3>Entregadas</h3>
          <p class="number">{{ totalEntregados }}</p>
          <span class="subtext">Despachadas con éxito</span>
        </div>
      </div>
    </div>

    <!-- TABLA DE SOLICITUDES DEL CICLO ACTIVO (LIMITADO A 5 REGISTROS POR PÁGINA) -->
    <div class="table-card">
      <div class="table-header">
        <div>
          <h2>Solicitudes del Ciclo Activo</h2>
          <p>Mostrando los primeros 5 registros por vista</p>
        </div>
        <div class="search-box">
          <svg class="search-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
          <input
            v-model="filtroBusqueda"
            v-restrict="{ tipo: 'busqueda', max: 100 }"
            type="text"
            maxlength="100"
            placeholder="Buscar por Familia o Calle..."
          />
        </div>
      </div>

      <div v-if="loading" class="loading-state">
        <div class="spinner"></div>
        <p>Cargando información desde Supabase...</p>
      </div>

      <div v-else-if="pedidosPaginados.length === 0" class="empty-state">
        <p>No hay solicitudes registradas para el ciclo activo actual.</p>
      </div>

      <div v-else class="table-wrapper">
        <table class="custom-table">
          <thead>
            <tr>
              <th># ID</th>
              <th>Familia</th>
              <th>Calle</th>
              <th>Tipo Bombona</th>
              <th>Pico</th>
              <th>Estatus</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="pedido in pedidosPaginados" :key="pedido.id_pedido" class="table-row">
              <td class="id-cell" data-label="ID">#{{ pedido.id_pedido }}</td>
              <td class="name-cell" data-label="Familia">
                <span class="family-name">{{ pedido.familias?.nombre_familia || 'Familia' }}</span>
              </td>
              <td data-label="Calle">
                <span class="badge-calle">{{ pedido.familias?.calles?.nombre || 'Sin calle' }}</span>
              </td>
              <td data-label="Tipo Bombona">{{ pedido.tipo_bombona }}</td>
              <td data-label="Pico">{{ pedido.pico }}</td>
              <td data-label="Estatus">
                <span class="status-indicator" :class="{ active: pedido.status === 'entregado', pending: pedido.status === 'pendiente' || pedido.status === 'aceptado' }">
                  <span class="status-dot"></span>
                  {{ pedido.status }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>

        <!-- PAGINADOR A 5 REGISTROS -->
        <div v-if="pedidosFiltrados.length > 5" class="pagination-footer">
          <span>Página {{ paginaActual }} de {{ totalPaginas }} ({{ pedidosFiltrados.length }} solicitudes en total)</span>
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

    <!-- TABLA DE GESTIÓN DE USUARIOS Y ROLES -->
    <div class="table-card">
      <div class="table-header">
        <div>
          <h2>Gestión de Usuarios y Roles</h2>
          <p>Modifica los permisos y roles de los usuarios directamente sobre la base de datos</p>
        </div>
      </div>

      <div v-if="loading" class="loading-state">
        <div class="spinner"></div>
        <p>Cargando registros de usuarios...</p>
      </div>

      <div v-else class="table-wrapper">
        <table class="custom-table">
          <thead>
            <tr>
              <th>Cédula (ID)</th>
              <th>Nombre de la Familia</th>
              <th>Calle</th>
              <th>Rol / Cargo (Editable)</th>
              <th>Estado</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="familia in familias" :key="familia.id" class="table-row">
              <td class="id-cell" data-label="Cédula (ID)">V-{{ familia.id }}</td>
              <td class="name-cell" data-label="Familia">
                <div class="avatar">{{ familia.nombre_familia ? familia.nombre_familia.charAt(0).toUpperCase() : 'F' }}</div>
                <span class="family-name">{{ familia.nombre_familia || 'Sin nombre' }}</span>
              </td>
              <td data-label="Calle">
                <span class="badge-calle">{{ obtenerNombreCalle(familia.id_calle) }}</span>
              </td>
              <td data-label="Rol / Cargo">
                <select
                  v-model.number="familia.id_cargo"
                  @change="actualizarRol(familia)"
                  class="role-select"
                  :class="'role-' + familia.id_cargo"
                >
                  <option :value="1">Administrador</option>
                  <option :value="2">Jefe de Calle</option>
                  <option :value="3">Familia</option>
                </select>
              </td>
              <td data-label="Estado">
                <span class="status-indicator" :class="{ active: familia.activo }">
                  <span class="status-dot"></span>
                  {{ familia.activo ? 'Activo' : 'Inactivo' }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../composables/supabase.js'

const familias = ref([])
const calles = ref([])
const cargos = ref([])
const cicloActivo = ref(null)
const pedidosCiclo = ref([])
const filtroBusqueda = ref('')
const loading = ref(true)

// Controles de Paginación (5 por vista)
const paginaActual = ref(1)
const porPagina = 5

const totalPendientes = computed(() => {
  return pedidosCiclo.value.filter(p => p.status === 'pendiente' || p.status === 'aceptado').length
})

const totalEntregados = computed(() => {
  return pedidosCiclo.value.filter(p => p.status === 'entregado').length
})

const pedidosFiltrados = computed(() => {
  if (!filtroBusqueda.value.trim()) return pedidosCiclo.value
  const query = filtroBusqueda.value.toLowerCase().trim()
  return pedidosCiclo.value.filter(p => {
    const familiaNombre = p.familias?.nombre_familia?.toLowerCase() || ''
    const calleNombre = p.familias?.calles?.nombre?.toLowerCase() || ''
    return familiaNombre.includes(query) || calleNombre.includes(query)
  })
})

const totalPaginas = computed(() => {
  return Math.ceil(pedidosFiltrados.value.length / porPagina) || 1
})

// Recorte exacto para 5 registros por vista
const pedidosPaginados = computed(() => {
  const inicio = (paginaActual.value - 1) * porPagina
  return pedidosFiltrados.value.slice(inicio, inicio + porPagina)
})

async function cargarDatos() {
  loading.value = true
  paginaActual.value = 1
  try {
    const { data: callesData } = await supabase
      .from('calles')
      .select('*')
      .eq('activo', true)
      .eq('is_deleted', false)
    if (callesData) calles.value = callesData

    const { data: cargosData } = await supabase.from('cargos').select('*')
    if (cargosData) cargos.value = cargosData

    const { data: familiasData, error } = await supabase
      .from('familias')
      .select('*')
      .eq('is_deleted', false)
    if (!error && familiasData) {
      familias.value = familiasData
    }

    // 1. Consultar el ciclo que esté activo
    const { data: ciclos } = await supabase
      .from('ciclos_distribucion')
      .select('*')
      .eq('estado', 'activo')
      .order('id_ciclo', { ascending: false })
      .limit(1)

    if (ciclos && ciclos.length > 0) {
      cicloActivo.value = ciclos[0]

      // 2. Traer únicamente los pedidos del ciclo activo
      const { data: pedidosData } = await supabase
        .from('pedidos')
        .select(`
          *,
          familias (
            id,
            nombre_familia,
            calles (id_calle, nombre)
          )
        `)
        .eq('id_ciclo', cicloActivo.value.id_ciclo)
        .order('id_pedido', { ascending: false })

      pedidosCiclo.value = pedidosData || []
    } else {
      cicloActivo.value = null
      pedidosCiclo.value = []
    }
  } catch (e) {
    console.error('Error cargando datos de Supabase:', e)
  } finally {
    loading.value = false
  }
}

async function actualizarRol(familia) {
  try {
    const { error } = await supabase
      .from('familias')
      .update({ id_cargo: familia.id_cargo })
      .eq('id', familia.id)

    if (error) {
      console.error('Error al actualizar el rol:', error.message)
      alert('Hubo un error al actualizar el rol.')
      cargarDatos()
    }
  } catch (e) {
    console.error('Excepción al actualizar rol:', e)
  }
}

function obtenerNombreCalle(idCalle) {
  const c = calles.value.find((item) => item.id_calle === idCalle)
  return c ? c.nombre : `Calle ID ${idCalle}`
}

onMounted(() => {
  cargarDatos()
})
</script>

<style scoped>
/* Estilos extras para la alerta y paginación manteniendo tu diseño original */
.alert-banner {
  padding: 1rem;
  background-color: #fffbebf5;
  border: 1px solid #fef08a;
  border-radius: 0.75rem;
  color: #854d0e;
  font-size: 0.9rem;
}

.number-text {
  font-size: 1.1rem;
  font-weight: 700;
  color: #1f2937;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.pagination-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 1rem;
  border-top: 1px solid #f3f4f6;
  font-size: 0.85rem;
  color: #6b7280;
}

.pagination-buttons {
  display: flex;
  gap: 0.5rem;
}

.btn-page {
  padding: 0.35rem 0.75rem;
  background-color: #f3f4f6;
  border: 1px solid #e5e7eb;
  border-radius: 0.375rem;
  cursor: pointer;
  font-weight: 500;
  color: #374151;
  transition: all 0.2s;
}

.btn-page:hover:not(:disabled) {
  background-color: #e5e7eb;
}

.btn-page:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap');

/* CONTENEDOR PRINCIPAL DEL DASHBOARD */
.admin-dashboard {
  font-family: 'Plus Jakarta Sans', sans-serif;
  color: #0f172a;
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
  background-color: transparent !important; /* El layout aporta el fondo y el padding */
  min-height: 0;
  box-sizing: border-box;
}

/* BANNER HEADER CORPORATIVO CLARO */
.header-banner {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-left: 6px solid #0072CE;
  border-radius: 18px;
  padding: 2rem 2.2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.04);
}

.badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: #eff6ff;
  color: #0072CE;
  border: 1px solid #dbeafe;
  padding: 5px 12px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
}

.pulse-dot {
  width: 7px;
  height: 7px;
  background-color: #0072CE;
  border-radius: 50%;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% { transform: scale(0.95); opacity: 0.8; }
  50% { transform: scale(1.3); opacity: 1; }
  100% { transform: scale(0.95); opacity: 0.8; }
}

.banner-content h1 {
  margin: 0;
  font-size: 1.8rem;
  font-weight: 700;
  color: #0f172a;
  letter-spacing: -0.02em;
}

.banner-content p {
  margin: 0.3rem 0 0 0;
  color: #64748b;
  font-size: 0.9rem;
}

.refresh-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #0072CE;
  color: #ffffff;
  border: none;
  padding: 0.75rem 1.4rem;
  border-radius: 12px;
  font-weight: 600;
  font-size: 0.88rem;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
}

.refresh-btn:hover:not(:disabled) {
  background: #005aa3;
  transform: translateY(-1px);
}

.refresh-btn .icon {
  width: 18px;
  height: 18px;
}

.refresh-btn .icon.spin {
  animation: spin 1s linear infinite;
}

@keyframes spin {
  100% { transform: rotate(360deg); }
}

/* MÉTRICAS GRID */
.metrics-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
  gap: 1.25rem;
}

.metric-card {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  padding: 1.35rem 1.5rem;
  display: flex;
  align-items: center;
  gap: 1.25rem;
  transition: all 0.25s cubic-bezier(0.175, 0.885, 0.32, 1.275);
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.03);
}

.metric-card.border-blue { border-left: 4px solid #0072CE; }
.metric-card.border-cyan { border-left: 4px solid #06b6d4; }
.metric-card.border-amber { border-left: 4px solid #f59e0b; }
.metric-card.border-green { border-left: 4px solid #10b981; }

.metric-card:hover {
  transform: translateY(-3px);
  box-shadow: 0 10px 20px -5px rgba(0, 114, 206, 0.12);
}

.card-icon {
  width: 50px;
  height: 50px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.card-icon svg {
  width: 24px;
  height: 24px;
}

.card-icon.blue { background: #eff6ff; color: #0072CE; }
.card-icon.cyan { background: #ecfeff; color: #0891b2; }
.card-icon.amber { background: #fffbeb; color: #d97706; }
.card-icon.green { background: #ecfdf5; color: #059669; }

.metric-info h3 {
  margin: 0;
  font-size: 0.75rem;
  color: #64748b;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.metric-info .number {
  margin: 0.2rem 0;
  font-size: 1.75rem;
  font-weight: 700;
  color: #0f172a;
}

.metric-info .subtext {
  font-size: 0.75rem;
  color: #94a3b8;
}

/* TABLAS CLARAS Y LIMPIAS */
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
}

.custom-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.custom-table th {
  padding: 0.85rem 1rem;
  font-size: 0.72rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #64748b;
  background-color: #f8fafc;
  border-bottom: 1px solid #e2e8f0;
  font-weight: 600;
}

.custom-table td {
  padding: 1rem;
  border-bottom: 1px solid #f1f5f9;
  font-size: 0.88rem;
  color: #334155;
}

.table-row:hover {
  background-color: #f8fafc;
}

.id-cell {
  font-weight: 600;
  color: #0072CE;
}

.name-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.family-name {
  font-weight: 500;
  color: #0f172a;
}

.avatar {
  width: 32px;
  height: 32px;
  background-color: #eff6ff;
  color: #0072CE;
  font-weight: 700;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.8rem;
}

.badge-calle {
  background: #f1f5f9;
  color: #475569;
  border: 1px solid #e2e8f0;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 0.8rem;
  font-weight: 500;
}

.qty-badge {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 0.82rem;
  color: #475569;
  font-weight: 500;
}

.text-green { color: #059669; }

.action-btn-detail {
  background: #eff6ff;
  color: #0072CE;
  border: 1px solid #bfdbfe;
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 0.78rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.action-btn-detail:hover {
  background: #dbeafe;
}

/* SELECTOR DE ROL */
.role-select {
  padding: 5px 10px;
  border-radius: 6px;
  font-size: 0.8rem;
  font-weight: 600;
  font-family: 'Plus Jakarta Sans', sans-serif;
  cursor: pointer;
  outline: none;
  transition: all 0.2s ease;
}

.role-select.role-1 {
  background: #fef2f2;
  color: #dc2626;
  border: 1px solid #fecaca;
}

.role-select.role-2 {
  background: #fffbeb;
  color: #d97706;
  border: 1px solid #fde68a;
}

.role-select.role-3 {
  background: #eff6ff;
  color: #0072CE;
  border: 1px solid #bfdbfe;
}

.status-indicator {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 600;
  background: #fef2f2;
  color: #dc2626;
  border: 1px solid #fecaca;
}

.status-indicator.active {
  background: #ecfdf5;
  color: #059669;
  border-color: #a7f3d0;
}

.status-dot {
  width: 6px;
  height: 6px;
  background-color: currentColor;
  border-radius: 50%;
}

.loading-state, .empty-state {
  padding: 3rem;
  text-align: center;
  color: #64748b;
}

.spinner {
  width: 32px;
  height: 32px;
  border: 3px solid #e2e8f0;
  border-top-color: #0072CE;
  border-radius: 50%;
  animation: spin 1s infinite linear;
  margin: 0 auto 1rem auto;
}

/* MODAL DE DETALLE CLARO */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(15, 23, 42, 0.4);
  backdrop-filter: blur(4px);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
  padding: 1rem;
}

.modal-box {
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 18px;
  width: 100%;
  max-width: 480px;
  padding: 1.8rem;
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: 1.25rem;
}

.modal-header h3 {
  margin: 0;
  font-size: 1.2rem;
  color: #0f172a;
}

.modal-header p {
  margin: 0.2rem 0 0 0;
  font-size: 0.85rem;
  color: #64748b;
}

.close-modal {
  background: none;
  border: none;
  color: #94a3b8;
  font-size: 1.2rem;
  cursor: pointer;
}

.close-modal:hover { color: #0f172a; }

.detail-stats-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.75rem;
  margin-bottom: 1.25rem;
}

.detail-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  padding: 0.85rem;
  border-radius: 12px;
}

.detail-card span {
  display: block;
  font-size: 0.72rem;
  color: #64748b;
  text-transform: uppercase;
  font-weight: 600;
}

.detail-card strong {
  display: block;
  font-size: 1.4rem;
  color: #0f172a;
  margin-top: 0.2rem;
}

.detail-card.text-green-box strong { color: #059669; }

.breakdown-section h4 {
  margin: 0 0 0.6rem 0;
  font-size: 0.8rem;
  color: #64748b;
  text-transform: uppercase;
  font-weight: 600;
}

.breakdown-list {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  padding: 0.5rem;
}

.breakdown-item {
  display: flex;
  justify-content: space-between;
  padding: 0.55rem 0.75rem;
  border-bottom: 1px solid #e2e8f0;
  font-size: 0.85rem;
  color: #334155;
}

.breakdown-item:last-child { border-bottom: none; }

.breakdown-item strong { color: #0072CE; }

.no-data {
  padding: 0.75rem;
  text-align: center;
  font-size: 0.8rem;
  color: #64748b;
}

.modal-footer {
  margin-top: 1.25rem;
  display: flex;
  justify-content: flex-end;
}

.btn-secondary {
  background: #f1f5f9;
  color: #475569;
  border: 1px solid #cbd5e1;
  padding: 0.6rem 1.2rem;
  border-radius: 10px;
  font-size: 0.85rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-secondary:hover { background: #e2e8f0; color: #0f172a; }

/* ==========================================================================
   RESPONSIVE · mobile-first
   ========================================================================== */
.header-banner {
  flex-direction: column;
  align-items: stretch;
  gap: 14px;
  padding: 18px 16px;
  border-left-width: 5px;
  border-radius: 16px;
}

.banner-content h1 {
  font-size: 1.45rem;
  line-height: 1.25;
}

.banner-content p {
  font-size: 0.83rem;
  line-height: 1.5;
}

.refresh-btn {
  justify-content: center;
  width: 100%;
  min-height: 44px;
  padding: 10px 16px;
  font-size: 0.85rem;
}

.metrics-grid {
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
}

.metric-card {
  flex-direction: column;
  align-items: flex-start;
  gap: 8px;
  padding: 12px;
  border-radius: 14px;
}

.card-icon {
  width: 38px;
  height: 38px;
  border-radius: 10px;
}

.card-icon svg {
  width: 20px;
  height: 20px;
}

.metric-info h3 {
  font-size: 0.64rem;
  line-height: 1.3;
}

.metric-info .number {
  margin: 0.15rem 0;
  font-size: 1.35rem;
}

.metric-info .subtext {
  font-size: 0.66rem;
  line-height: 1.3;
}

.table-card {
  padding: 14px;
  border-radius: 16px;
}

.table-header {
  margin-bottom: 14px;
  gap: 10px;
}

.table-header h2 {
  font-size: 1.1rem;
  line-height: 1.3;
}

.table-header p {
  font-size: 0.8rem;
  line-height: 1.45;
}

.search-box {
  width: 100%;
  max-width: none;
}

.search-box input {
  min-height: 44px;
  font-size: 16px;
}

.loading-state,
.empty-state {
  padding: 2rem 1rem;
}

.admin-detail-modal {
  align-items: flex-end;
  padding: 0;
}

.admin-detail-box {
  width: 100%;
  max-width: none;
  max-height: 85dvh;
  padding: 12px 16px calc(16px + var(--safe-bottom));
  border-radius: 20px 20px 0 0;
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}

.modal-sheet-handle {
  display: block;
  width: 40px;
  height: 4px;
  margin: 0 auto 14px;
  border-radius: 999px;
  background: #e2e8f0;
}

.modal-footer .btn-secondary {
  width: 100%;
  min-height: 44px;
}

.close-modal {
  width: 44px;
  height: 44px;
  margin: -8px -8px 0 0;
  border-radius: 10px;
}

.close-modal:hover {
  background: #f1f5f9;
}

/* Tablet pequeña */
@media (min-width: 480px) {
  .metric-card {
    flex-direction: row;
    align-items: center;
    gap: 10px;
    padding: 14px;
  }
}

@media (min-width: 640px) {
  .admin-dashboard {
    gap: 1.5rem;
  }

  .header-banner {
    flex-direction: row;
    align-items: center;
    padding: 1.6rem;
  }

  .banner-content h1 {
    font-size: 1.6rem;
  }

  .refresh-btn {
    width: auto;
    min-height: 40px;
  }

  .table-card {
    padding: 1.25rem;
  }

  .admin-detail-modal {
    align-items: center;
    padding: 20px;
  }

  .admin-detail-box {
    width: 100%;
    max-width: 480px;
    max-height: 85vh;
    padding: 20px;
    border-radius: 18px;
  }

  .modal-sheet-handle {
    display: none;
  }

  .modal-footer .btn-secondary {
    width: auto;
    min-height: 40px;
  }
}

/* Tablet grande */
@media (min-width: 768px) {
  .metrics-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 14px;
  }

  .card-icon {
    width: 42px;
    height: 42px;
  }

  .metric-info h3 {
    font-size: 0.68rem;
  }

  .metric-info .number {
    font-size: 1.5rem;
  }

  .table-header {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
  }

  .search-box {
    max-width: 300px;
  }

  .search-box input {
    min-height: 40px;
    font-size: 15px;
  }
}

/* Desktop */
@media (min-width: 1024px) {
  .admin-dashboard {
    gap: 1.75rem;
  }

  .header-banner {
    padding: 2rem 2.2rem;
    border-radius: 18px;
  }

  .banner-content h1 {
    font-size: 1.8rem;
  }

  .banner-content p {
    font-size: 0.9rem;
  }

  .metrics-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 1.25rem;
  }

  .metric-card {
    padding: 1.35rem 1.5rem;
    border-radius: 16px;
  }

  .card-icon {
    width: 48px;
    height: 48px;
  }

  .card-icon svg {
    width: 24px;
    height: 24px;
  }

  .metric-info h3 {
    font-size: 0.75rem;
  }

  .metric-info .number {
    font-size: 1.75rem;
  }

  .metric-info .subtext {
    font-size: 0.75rem;
  }

  .table-card {
    padding: 1.6rem;
    border-radius: 18px;
  }

  .table-header h2 {
    font-size: 1.25rem;
  }

  .admin-detail-box {
    max-width: 520px;
    padding: 24px;
  }

  .modal-footer .btn-secondary {
    min-height: 36px;
  }
}

@media (min-width: 1280px) {
  .metrics-grid {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }
}
</style>