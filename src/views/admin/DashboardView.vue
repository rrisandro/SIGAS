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
        <p>Monitoreo y control centralizado de familias, sectores y roles del sistema</p>
      </div>
      <button class="refresh-btn" @click="cargarDatos" :disabled="loading">
        <svg viewBox="0 0 24 24" class="icon" :class="{ spin: loading }">
          <path fill="currentColor" d="M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6c0 1.01-.25 1.97-.7 2.8l1.46 1.46A7.93 7.93 0 0 0 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6c0-1.01.25-1.97.7-2.8L5.24 7.74A7.93 7.93 0 0 0 4 12c0 4.42 3.58 8 8 8v3l4-4l-4-4v3z"/>
        </svg>
        Actualizar Datos
      </button>
    </header>

    <!-- TARJETAS DE MÉTRICAS -->
    <div class="metrics-grid">
      <div class="metric-card border-blue">
        <div class="card-icon blue">
          <svg viewBox="0 0 24 24"><path fill="currentColor" d="M16 11c1.66 0 2.99-1.34 2.99-3S17.66 5 16 5c-1.66 0-3 1.34-3 3s1.34 3 3 3zm-8 0c1.66 0 2.99-1.34 2.99-3S9.66 5 8 5C6.34 5 5 6.34 5 8s1.34 3 3 3zm0 2c-2.33 0-7 1.17-7 3.5V19h14v-2.5c0-2.33-4.67-3.5-7-3.5zm8 0c-.29 0-.62.02-.97.05c1.16.84 1.97 1.97 1.97 3.45V19h6v-2.5c0-2.33-4.67-3.5-7-3.5z"/></svg>
        </div>
        <div class="metric-info">
          <h3>Total Familias</h3>
          <p class="number">{{ familias.length }}</p>
          <span class="subtext">Registradas en el sistema</span>
        </div>
      </div>

      <div class="metric-card border-cyan">
        <div class="card-icon cyan">
          <svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5s2.5 1.12 2.5 2.5s-1.12 2.5-2.5 2.5z"/></svg>
        </div>
        <div class="metric-info">
          <h3>Calles Activas</h3>
          <p class="number">{{ calles.length }}</p>
          <span class="subtext">Sectores censados</span>
        </div>
      </div>

      <div class="metric-card border-green">
        <div class="card-icon green">
          <svg viewBox="0 0 24 24"><path fill="currentColor" d="M12 2A10 10 0 0 0 2 12a10 10 0 0 0 10 10a10 10 0 0 0 10-10A10 10 0 0 0 12 2zm-2 15l-5-5l1.41-1.41L10 14.17l7.59-7.59L19 8l-9 9z"/></svg>
        </div>
        <div class="metric-info">
          <h3>Estado Servidor</h3>
          <p class="number status">
            <span class="server-dot"></span> En Línea
          </p>
          <span class="subtext">Conectado a Supabase</span>
        </div>
      </div>
    </div>

    <!-- TABLA PRINCIPAL DE REGISTROS -->
    <div class="table-card">
      <div class="table-header">
        <div>
          <h2>Gestión de Usuarios y Roles</h2>
          <p>Modifica los permisos y roles de los usuarios directamente sobre la base de datos</p>
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
        <p>Cargando registros desde Supabase...</p>
      </div>

      <div v-else-if="familiasFiltradas.length === 0" class="empty-state">
        <p>No se encontraron familias registradas con esa búsqueda.</p>
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
            <tr v-for="familia in familiasFiltradas" :key="familia.id" class="table-row">
              <td class="id-cell">V-{{ familia.id }}</td>
              <td class="name-cell">
                <div class="avatar">{{ familia.nombre_familia ? familia.nombre_familia.charAt(0).toUpperCase() : 'F' }}</div>
                <span class="family-name">{{ familia.nombre_familia || 'Sin nombre' }}</span>
              </td>
              <td>
                <span class="badge-calle">{{ obtenerNombreCalle(familia.id_calle) }}</span>
              </td>
              <td>
                <!-- SELECTOR INTERACTIVO PARA CAMBIAR EL ROL Y GUARDAR EN SUPABASE -->
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
              <td>
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
const filtroBusqueda = ref('')
const loading = ref(true)

async function cargarDatos() {
  loading.value = true
  try {
    const { data: callesData } = await supabase.from('calles').select('*').eq('activo', true)
    if (callesData) calles.value = callesData

    const { data: cargosData } = await supabase.from('cargos').select('*')
    if (cargosData) cargos.value = cargosData

    const { data: familiasData, error } = await supabase.from('familias').select('*')
    if (!error && familiasData) {
      familias.value = familiasData
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
      console.error('Error al actualizar el rol en Supabase:', error.message)
      alert('Hubo un error al actualizar el rol.')
      cargarDatos() // Recargar para revertir en caso de fallo
    }
  } catch (e) {
    console.error('Excepción al actualizar rol:', e)
  }
}

onMounted(() => {
  cargarDatos()
})

const familiasFiltradas = computed(() => {
  if (!filtroBusqueda.value.trim()) return familias.value
  const query = filtroBusqueda.value.toLowerCase().trim()
  return familias.value.filter(
    (f) =>
      String(f.id).includes(query) ||
      (f.nombre_familia && f.nombre_familia.toLowerCase().includes(query))
  )
})

function obtenerNombreCalle(idCalle) {
  const c = calles.value.find((item) => item.id_calle === idCalle)
  return c ? c.nombre : `Calle ID ${idCalle}`
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap');

.admin-dashboard {
  font-family: 'Plus Jakarta Sans', sans-serif;
  color: #f8fafc;
  padding: 2rem;
  display: flex;
  flex-direction: column;
  gap: 1.75rem;
  background-color: #060d1a; /* Tono profundo elegante inspirado en el login */
  min-height: 100vh;
}

/* BANNER HEADER PREMIUM */
.header-banner {
  background: linear-gradient(135deg, #0f1d36 0%, #172a4d 100%);
  border: 1px solid rgba(0, 212, 255, 0.2);
  border-radius: 20px;
  padding: 2.2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
  box-shadow: 0 12px 30px -10px rgba(0, 0, 0, 0.5);
  position: relative;
  overflow: hidden;
}

.header-banner::after {
  content: '';
  position: absolute;
  top: 0;
  right: 0;
  width: 350px;
  height: 100%;
  background: radial-gradient(circle, rgba(0, 168, 255, 0.12) 0%, transparent 70%);
  pointer-events: none;
}

.badge {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  background: rgba(0, 212, 255, 0.12);
  color: #00d4ff;
  border: 1px solid rgba(0, 212, 255, 0.3);
  padding: 6px 14px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 600;
  margin-bottom: 0.75rem;
}

.pulse-dot {
  width: 7px;
  height: 7px;
  background-color: #00d4ff;
  border-radius: 50%;
  box-shadow: 0 0 10px #00d4ff;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% { transform: scale(0.95); opacity: 0.8; }
  50% { transform: scale(1.3); opacity: 1; box-shadow: 0 0 14px #00d4ff; }
  100% { transform: scale(0.95); opacity: 0.8; }
}

.banner-content h1 {
  margin: 0;
  font-size: 1.85rem;
  font-weight: 700;
  color: #ffffff;
  letter-spacing: -0.02em;
}

.banner-content p {
  margin: 0.4rem 0 0 0;
  color: #94a3b8;
  font-size: 0.92rem;
}

.refresh-btn {
  display: flex;
  align-items: center;
  gap: 10px;
  background: linear-gradient(135deg, #0072ff 0%, #0051bb 100%);
  color: #ffffff;
  border: none;
  padding: 0.85rem 1.6rem;
  border-radius: 12px;
  font-weight: 600;
  font-size: 0.88rem;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 15px rgba(0, 114, 255, 0.4);
  z-index: 1;
}

.refresh-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  background: linear-gradient(135deg, #0085ff 0%, #0060d4 100%);
  box-shadow: 0 6px 20px rgba(0, 114, 255, 0.6);
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
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.25rem;
}

.metric-card {
  background: #0f1d36;
  border: 1px solid rgba(255, 255, 255, 0.07);
  border-radius: 18px;
  padding: 1.35rem 1.6rem;
  display: flex;
  align-items: center;
  gap: 1.25rem;
  transition: all 0.3s ease;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.25);
}

.metric-card.border-blue { border-left: 4px solid #0072ff; }
.metric-card.border-cyan { border-left: 4px solid #00d4ff; }
.metric-card.border-green { border-left: 4px solid #10b981; }

.metric-card:hover {
  transform: translateY(-3px);
  border-color: rgba(255, 255, 255, 0.15);
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.35);
}

.card-icon {
  width: 52px;
  height: 52px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.card-icon svg {
  width: 26px;
  height: 26px;
}

.card-icon.blue { background: rgba(0, 114, 255, 0.15); color: #3b82f6; }
.card-icon.cyan { background: rgba(0, 212, 255, 0.15); color: #00d4ff; }
.card-icon.green { background: rgba(16, 185, 129, 0.15); color: #34d399; }

.metric-info h3 {
  margin: 0;
  font-size: 0.78rem;
  color: #94a3b8;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.metric-info .number {
  margin: 0.25rem 0;
  font-size: 1.8rem;
  font-weight: 700;
  color: #ffffff;
}

.metric-info .number.status {
  color: #34d399;
  font-size: 1.2rem;
  display: flex;
  align-items: center;
  gap: 8px;
}

.server-dot {
  width: 8px;
  height: 8px;
  background-color: #34d399;
  border-radius: 50%;
  box-shadow: 0 0 8px #34d399;
  animation: pulse 2s infinite;
}

.metric-info .subtext {
  font-size: 0.75rem;
  color: #64748b;
}

/* TABLA DE REGISTROS */
.table-card {
  background: #0f1d36;
  border: 1px solid rgba(255, 255, 255, 0.07);
  border-radius: 20px;
  padding: 1.6rem;
  box-shadow: 0 12px 30px -10px rgba(0, 0, 0, 0.5);
}

.table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.6rem;
  flex-wrap: wrap;
  gap: 1rem;
}

.table-header h2 {
  margin: 0;
  font-size: 1.3rem;
  font-weight: 600;
  color: #ffffff;
}

.table-header p {
  margin: 0.3rem 0 0 0;
  font-size: 0.85rem;
  color: #94a3b8;
}

.search-box {
  position: relative;
  width: 100%;
  max-width: 300px;
}

.search-box input {
  width: 100%;
  background: #081120;
  border: 1px solid #1e293b;
  padding: 0.75rem 1rem 0.75rem 2.4rem;
  border-radius: 12px;
  color: #ffffff;
  outline: none;
  font-family: 'Plus Jakarta Sans', sans-serif;
  font-size: 0.85rem;
  transition: all 0.3s ease;
}

.search-box input::placeholder {
  color: #64748b;
}

.search-box input:focus {
  border-color: #00d4ff;
  box-shadow: 0 0 0 3px rgba(0, 212, 255, 0.15);
}

.search-icon {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  width: 16px;
  height: 16px;
  color: #64748b;
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
  padding: 1rem;
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: #94a3b8;
  background-color: rgba(8, 17, 32, 0.6);
  border-bottom: 1px solid #1e293b;
  font-weight: 600;
}

.custom-table td {
  padding: 1.1rem 1rem;
  border-bottom: 1px solid #1e293b;
  font-size: 0.9rem;
  color: #e2e8f0;
}

.table-row {
  transition: background-color 0.2s ease;
}

.table-row:hover {
  background-color: rgba(30, 41, 59, 0.4);
}

.id-cell {
  font-weight: 600;
  color: #00d4ff;
}

.name-cell {
  display: flex;
  align-items: center;
  gap: 12px;
}

.family-name {
  font-weight: 500;
  color: #f8fafc;
}

.avatar {
  width: 36px;
  height: 36px;
  background: linear-gradient(135deg, #0072ff, #00d4ff);
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 600;
  font-size: 0.85rem;
  color: #ffffff;
  box-shadow: 0 2px 5px rgba(0, 0, 0, 0.3);
}

.badge-calle {
  background: #081120;
  border: 1px solid #1e293b;
  padding: 5px 10px;
  border-radius: 8px;
  font-size: 0.8rem;
  color: #cbd5e1;
  font-weight: 500;
}

/* ESTILOS DEL SELECTOR DE ROL */
.role-select {
  padding: 6px 12px;
  border-radius: 8px;
  font-size: 0.8rem;
  font-weight: 600;
  font-family: 'Plus Jakarta Sans', sans-serif;
  cursor: pointer;
  outline: none;
  transition: all 0.2s ease;
}

.role-select.role-1 {
  background: rgba(239, 68, 68, 0.15);
  color: #f87171;
  border: 1px solid rgba(239, 68, 68, 0.3);
}

.role-select.role-2 {
  background: rgba(245, 158, 11, 0.15);
  color: #fbbf24;
  border: 1px solid rgba(245, 158, 11, 0.3);
}

.role-select.role-3 {
  background: rgba(0, 114, 255, 0.15);
  color: #60a5fa;
  border: 1px solid rgba(0, 114, 255, 0.3);
}

.role-select option {
  background: #0f1d36;
  color: #ffffff;
}

.status-indicator {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 600;
  background: rgba(239, 68, 68, 0.15);
  color: #f87171;
  border: 1px solid rgba(239, 68, 68, 0.3);
}

.status-indicator.active {
  background: rgba(16, 185, 129, 0.15);
  color: #34d399;
  border-color: rgba(16, 185, 129, 0.3);
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
  color: #94a3b8;
}

.spinner {
  width: 36px;
  height: 36px;
  border: 3px solid rgba(255, 255, 255, 0.1);
  border-top-color: #00d4ff;
  border-radius: 50%;
  animation: spin 1s infinite linear;
  margin: 0 auto 1rem auto;
}
</style>