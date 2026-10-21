<template>
  <div class="admin-page">
    <!-- CABECERA BANNER CORPORATIVA -->
    <header class="header-banner">
      <div>
        <div class="badge">
          <span class="pulse-dot"></span>
          Líderes Comunales
        </div>
        <h1>Jefes de Calle Registrados</h1>
        <p>Listado de responsables asignados por sector en Supabase</p>
      </div>
      <button class="action-btn" @click="cargarJefes">
        <svg viewBox="0 0 24 24" class="icon"><path fill="currentColor" d="M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6c0 1.01-.25 1.97-.7 2.8l1.46 1.46A7.93 7.93 0 0 0 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6c0-1.01.25-1.97.7-2.8L5.24 7.74A7.93 7.93 0 0 0 4 12c0 4.42 3.58 8 8 8v3l4-4l-4-4v3z"/></svg>
        Actualizar
      </button>
    </header>

    <!-- TARJETA DE TABLA LIMPIA Y MODERNA -->
    <div class="table-card">
      <div v-if="loading" class="loading-state">
        <div class="spinner"></div>
        <p>Cargando jefes de calle...</p>
      </div>

      <div v-else-if="jefes.length === 0" class="empty-state">
        <p>No hay jefes de calle registrados actualmente.</p>
      </div>

      <div v-else class="table-wrapper">
        <table class="custom-table">
          <thead>
            <tr>
              <th>Cédula</th>
              <th>Nombre Completo</th>
              <th>Calle Asignada</th>
              <th>Cargo</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="jefe in jefes" :key="jefe.id" class="table-row">
              <td class="id-cell">V-{{ jefe.id }}</td>
              <td class="name-cell">
                <div class="avatar">{{ jefe.nombre_familia ? jefe.nombre_familia.charAt(0).toUpperCase() : 'J' }}</div>
                <span class="family-name">{{ jefe.nombre_familia || 'Sin nombre' }}</span>
              </td>
              <td>
                <span class="badge-calle">{{ obtenerNombreCalle(jefe.id_calle) }}</span>
              </td>
              <td>
                <span class="role-badge">Jefe de Calle</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../../composables/supabase.js'

const jefes = ref([])
const calles = ref([])
const loading = ref(true)

async function cargarJefes() {
  loading.value = true
  try {
    const { data: callesData } = await supabase.from('calles').select('*')
    if (callesData) calles.value = callesData

    // Suponiendo que el rol de jefe de calle es id_cargo = 2 o similar
    const { data, error } = await supabase
      .from('familias')
      .select('*')
      .eq('id_cargo', 2)

    if (!error && data) {
      jefes.value = data
    }
  } catch (e) {
    console.error('Error cargando jefes:', e)
  } finally {
    loading.value = false
  }
}

function obtenerNombreCalle(idCalle) {
  const c = calles.value.find((item) => item.id_calle === idCalle)
  return c ? c.nombre : `Calle ID ${idCalle}`
}

onMounted(cargarJefes)
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap');

.admin-page { 
  font-family: 'Plus Jakarta Sans', sans-serif; 
  color: #0f172a; 
  padding: 2.2rem; 
  display: flex; 
  flex-direction: column; 
  gap: 1.75rem; 
  background-color: #f8fafc; 
  min-height: 100vh;
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

.action-btn:hover { 
  background: #005aa3; 
  transform: translateY(-1px); 
}

.action-btn .icon {
  width: 18px;
  height: 18px;
}

.table-card { 
  background: #ffffff; 
  border: 1px solid #e2e8f0; 
  border-radius: 18px; 
  padding: 1.6rem; 
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.03); 
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

.role-badge {
  background: #fffbeb;
  color: #d97706;
  border: 1px solid #fde68a;
  padding: 4px 10px;
  border-radius: 6px;
  font-size: 0.8rem;
  font-weight: 600;
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

@keyframes spin { 
  100% { transform: rotate(360deg); } 
}
</style>