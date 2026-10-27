<template>
  <div class="admin-page">
    <!-- CABECERA BANNER CORPORATIVA -->
    <header class="header-banner">
      <div>
        <div class="badge">
          <span class="pulse-dot"></span>
          Gestión de Habitantes
        </div>
        <h1>Familias Registradas</h1>
        <p>Control y administración de núcleos familiares censados en el sistema</p>
      </div>
      <button class="action-btn" @click="cargarFamilias" :disabled="loading">
        <svg viewBox="0 0 24 24" class="icon" :class="{ spin: loading }">
          <path fill="currentColor" d="M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6c0 1.01-.25 1.97-.7 2.8l1.46 1.46A7.93 7.93 0 0 0 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6c0-1.01.25-1.97.7-2.8L5.24 7.74A7.93 7.93 0 0 0 4 12c0 4.42 3.58 8 8 8v3l4-4l-4-4v3z"/>
        </svg>
        Actualizar Datos
      </button>
    </header>

    <!-- TARJETA DE TABLA PRINCIPAL -->
    <div class="table-card">
      <div class="table-header">
        <div>
          <h2>Directorio Familiar</h2>
          <p>Listado general de familias y asignación por calles</p>
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
              <th>Calle / Sector</th>
              <th>Estado</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="familia in familiasFiltradas" :key="familia.id" class="table-row">
              <td class="id-cell" data-label="Cédula (ID)">V-{{ familia.id }}</td>
              <td class="name-cell" data-label="Nombre de la familia">
                <div class="avatar">{{ familia.nombre_familia ? familia.nombre_familia.charAt(0).toUpperCase() : 'F' }}</div>
                <span class="family-name">{{ familia.nombre_familia || 'Sin nombre' }}</span>
              </td>
              <td data-label="Calle / Sector">
                <span class="badge-calle">{{ obtenerNombreCalle(familia.id_calle) }}</span>
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
const filtroBusqueda = ref('')
const loading = ref(true)

async function cargarFamilias() {
  loading.value = true
  try {
    const { data: callesData } = await supabase.from('calles').select('*')
    if (callesData) calles.value = callesData

    const { data, error } = await supabase.from('familias').select('*')
    if (!error && data) {
      familias.value = data
    }
  } catch (e) {
    console.error('Error cargando familias:', e)
  } finally {
    loading.value = false
  }
}

function obtenerNombreCalle(idCalle) {
  const c = calles.value.find((item) => item.id_calle === idCalle)
  return c ? c.nombre : `Calle ID ${idCalle}`
}

onMounted(cargarFamilias)

const familiasFiltradas = computed(() => {
  if (!filtroBusqueda.value.trim()) return familias.value
  const query = filtroBusqueda.value.toLowerCase().trim()
  return familias.value.filter(
    (f) =>
      String(f.id).includes(query) ||
      (f.nombre_familia && f.nombre_familia.toLowerCase().includes(query))
  )
})
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap');

.admin-page { 
  font-family: 'Plus Jakarta Sans', sans-serif; 
  color: #0f172a; 
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
  background-color: transparent !important;
  min-height: 0;
  box-sizing: border-box;
}

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

.header-banner h1 { 
  margin: 0; 
  font-size: 1.8rem; 
  font-weight: 700; 
  color: #0f172a; 
  letter-spacing: -0.02em; 
}

.header-banner p { 
  margin: 0.3rem 0 0 0; 
  color: #64748b; 
  font-size: 0.9rem; 
}

.action-btn { 
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

.action-btn:hover:not(:disabled) { 
  background: #005aa3; 
  transform: translateY(-1px); 
}

.action-btn .icon {
  width: 18px;
  height: 18px;
}

.action-btn .icon.spin {
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

.table-row { 
  transition: background-color 0.15s ease; 
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
  text-align: center; 
  padding: 3rem; 
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

@media (max-width: 639.98px) {
  .header-banner {
    flex-direction: column;
    align-items: stretch;
    gap: 16px;
    padding: 18px 16px;
    border-left-width: 4px;
  }

  .header-banner h1 {
    font-size: 1.35rem;
  }

  .action-btn {
    justify-content: center;
    width: 100%;
    min-height: 44px;
  }

  .table-card {
    padding: 14px;
    border-radius: 16px;
  }

  .table-header {
    flex-direction: column;
    align-items: stretch;
    margin-bottom: 1rem;
  }

  .search-box {
    max-width: none;
  }

  .search-box input {
    min-height: 44px;
    font-size: 16px;
  }

  .name-cell {
    gap: 8px;
  }
}

@media (min-width: 640px) {
  .admin-page {
    gap: 1.5rem;
  }

  .header-banner {
    padding: 1.7rem 1.9rem;
  }

  .table-card {
    padding: 1.4rem;
  }

  .action-btn {
    min-height: 40px;
  }
}

@media (min-width: 1024px) {
  .admin-page {
    gap: 1.75rem;
  }

  .header-banner h1 {
    font-size: 1.8rem;
  }

  .table-card {
    padding: 1.6rem;
  }
}
</style>