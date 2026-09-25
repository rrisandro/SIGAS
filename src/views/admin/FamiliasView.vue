<template>
  <div class="admin-page">
    <header class="header-banner">
      <div>
        <div class="badge">Censo y Registro</div>
        <h1>Gestión de Familias</h1>
        <p>Listado general de familias censadas en el sistema SIGAS</p>
      </div>
    </header>

    <div class="table-card">
      <div v-if="loading" class="loading-state"><div class="spinner"></div>Cargando familias...</div>
      
      <div v-else class="table-wrapper">
        <table class="custom-table">
          <thead>
            <tr>
              <th>Cédula (ID)</th>
              <th>Nombre de la Familia</th>
              <th>Calle</th>
              <th>Estado</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="fam in familias" :key="fam.id">
              <td class="id-cell">V-{{ fam.id }}</td>
              <td>{{ fam.nombre_familia }}</td>
              <td><span class="badge-calle">{{ fam.calles?.nombre || 'Sin Calle' }}</span></td>
              <td>
                <span class="status-badge" :class="{ active: fam.activo }">
                  {{ fam.activo ? 'Activa' : 'Inactiva' }}
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
import { ref, onMounted } from 'vue'
import { supabase } from '../../composables/supabase.js'

const familias = ref([])
const loading = ref(true)

async function cargarFamilias() {
  loading.value = true
  const { data } = await supabase
    .from('familias')
    .select('*, calles(nombre)')
    .eq('id_cargo', 3) // Filtrar por cargo de familia

  if (data) familias.value = data
  loading.value = false
}

onMounted(cargarFamilias)
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
.status-badge { padding: 3px 8px; border-radius: 6px; font-size: 0.75rem; background: rgba(239, 68, 68, 0.2); color: #f87171; }
.status-badge.active { background: rgba(34, 197, 94, 0.2); color: #4ade80; }
.loading-state { text-align: center; padding: 3rem; color: #a0aec0; }
.spinner { width: 30px; height: 30px; border: 3px solid rgba(255, 255, 255, 0.1); border-top-color: #0072ce; border-radius: 50%; animation: spin 1s infinite linear; margin: 0 auto 0.5rem auto; }
@keyframes spin { 100% { transform: rotate(360deg); } }
</style>