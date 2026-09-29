<template>
  <div class="admin-page">
    <header class="header-banner">
      <div>
        <div class="badge">Líderes Comunales</div>
        <h1>Jefes de Calle Registrados</h1>
        <p>Listado de responsables asignados por sector en Supabase</p>
      </div>
    </header>

    <div class="table-card">
      <div v-if="loading" class="loading-state"><div class="spinner"></div>Cargando jefes...</div>
      
      <div v-else-if="jefes.length === 0" class="empty-state">
        No hay Jefes de Calle registrados actualmente (Cargo ID: 2).
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
            <tr v-for="jefe in jefes" :key="jefe.id">
              <td class="id-cell">V-{{ jefe.id }}</td>
              <td>{{ jefe.nombre_familia }}</td>
              <td><span class="badge-calle">{{ jefe.calles?.nombre || 'Sin asignar' }}</span></td>
              <td><span class="badge-jefe">Jefe de Calle</span></td>
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
const loading = ref(true)

async function cargarJefes() {
  loading.value = true
  const { data } = await supabase
    .from('familias')
    .select('*, calles(nombre)')
    .eq('id_cargo', 2)

  if (data) jefes.value = data
  loading.value = false
}

onMounted(cargarJefes)
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600&display=swap');

.admin-page { font-family: 'Poppins', sans-serif; color: #fff; padding: 1.5rem; display: flex; flex-direction: column; gap: 1.5rem; }
.header-banner { background: linear-gradient(135deg, rgba(0, 114, 206, 0.4), rgba(255, 122, 0, 0.2)); backdrop-filter: blur(16px); border: 1px solid rgba(0, 114, 206, 0.4); border-radius: 20px; padding: 1.8rem 2rem; }
.badge { display: inline-block; background: rgba(0, 114, 206, 0.3); color: #38b6ff; border: 1px solid rgba(56, 182, 255, 0.4); padding: 4px 12px; border-radius: 20px; font-size: 0.75rem; font-weight: 600; margin-bottom: 0.5rem; }
.header-banner h1 { margin: 0; font-size: 1.6rem; }
.header-banner p { margin: 0.3rem 0 0 0; color: #a0aec0; font-size: 0.9rem; }
.table-card { background: rgba(15, 23, 36, 0.75); backdrop-filter: blur(16px); border: 1px solid rgba(50, 132, 209, 0.3); border-radius: 20px; padding: 1.5rem; }
.custom-table { width: 100%; border-collapse: collapse; text-align: left; }
.custom-table th { padding: 0.8rem 1rem; font-size: 0.8rem; color: #a0aec0; border-bottom: 1px solid rgba(255, 255, 255, 0.1); }
.custom-table td { padding: 1rem; border-bottom: 1px solid rgba(255, 255, 255, 0.05); }
.id-cell { font-weight: 600; color: #38b6ff; }
.badge-calle { background: rgba(255, 255, 255, 0.08); padding: 4px 10px; border-radius: 8px; font-size: 0.8rem; }
.badge-jefe { background: rgba(245, 158, 11, 0.2); color: #fbbf24; padding: 4px 10px; border-radius: 8px; font-size: 0.75rem; font-weight: 600; }
.loading-state, .empty-state { text-align: center; padding: 3rem; color: #a0aec0; }
.spinner { width: 30px; height: 30px; border: 3px solid rgba(255, 255, 255, 0.1); border-top-color: #0072ce; border-radius: 50%; animation: spin 1s infinite linear; margin: 0 auto 0.5rem auto; }
@keyframes spin { 100% { transform: rotate(360deg); } }
</style>