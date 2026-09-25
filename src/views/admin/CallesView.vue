<template>
  <div class="admin-page">
    <header class="header-banner">
      <div>
        <div class="badge">Administración de Sectores</div>
        <h1>Calles y Sectores Registrados</h1>
        <p>Gestión de calles activas para la distribución de gas</p>
      </div>
      <button class="action-btn" @click="mostrarModal = true">+ Nueva Calle</button>
    </header>

    <div class="table-card">
      <div v-if="loading" class="loading-state"><div class="spinner"></div>Cargando calles...</div>
      
      <div v-else class="table-wrapper">
        <table class="custom-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Nombre de la Calle</th>
              <th>Estado</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="calle in calles" :key="calle.id_calle">
              <td class="id-cell">#{{ calle.id_calle }}</td>
              <td>{{ calle.nombre }}</td>
              <td>
                <span class="status-badge" :class="{ active: calle.activo }">
                  {{ calle.activo ? 'Activa' : 'Inactiva' }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- MODAL NUEVA CALLE -->
    <div v-if="mostrarModal" class="modal-overlay">
      <div class="modal-card">
        <h3>Registrar Nueva Calle</h3>
        <form @submit.prevent="guardarCalle">
          <div class="field">
            <input v-model="nombreNuevaCalle" type="text" placeholder="Nombre de la Calle" required class="input-field" />
          </div>
          <div class="btn-group">
            <button type="submit" class="button1" :disabled="guardando">
              {{ guardando ? 'Guardando...' : 'Guardar' }}
            </button>
            <button type="button" class="button2" @click="mostrarModal = false">Cancelar</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../../composables/supabase.js'

const calles = ref([])
const loading = ref(true)
const mostrarModal = ref(false)
const nombreNuevaCalle = ref('')
const guardando = ref(false)

async function cargarCalles() {
  loading.value = true
  const { data } = await supabase.from('calles').select('*').order('id_calle', { ascending: true })
  if (data) calles.value = data
  loading.value = false
}

async function guardarCalle() {
  guardando.value = true
  const { error } = await supabase.from('calles').insert([{ nombre: nombreNuevaCalle.value, activo: true }])
  guardando.value = false
  if (!error) {
    nombreNuevaCalle.value = ''
    mostrarModal.value = false
    cargarCalles()
  }
}

onMounted(cargarCalles)
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600&display=swap');

.admin-page { font-family: 'Poppins', sans-serif; color: #fff; padding: 1.5rem; display: flex; flex-direction: column; gap: 1.5rem; }
.header-banner { background: linear-gradient(135deg, rgba(0, 114, 206, 0.4), rgba(255, 122, 0, 0.2)); backdrop-filter: blur(16px); border: 1px solid rgba(0, 114, 206, 0.4); border-radius: 20px; padding: 1.8rem 2rem; display: flex; justify-content: space-between; align-items: center; }
.badge { display: inline-block; background: rgba(0, 114, 206, 0.3); color: #38b6ff; border: 1px solid rgba(56, 182, 255, 0.4); padding: 4px 12px; border-radius: 20px; font-size: 0.75rem; font-weight: 600; margin-bottom: 0.5rem; }
.header-banner h1 { margin: 0; font-size: 1.6rem; }
.header-banner p { margin: 0.3rem 0 0 0; color: #a0aec0; font-size: 0.9rem; }
.action-btn { background: linear-gradient(135deg, #0072CE 0%, #005aa3 100%); color: #fff; border: none; padding: 0.7rem 1.3rem; border-radius: 12px; font-weight: 600; cursor: pointer; }
.table-card { background: rgba(15, 23, 36, 0.75); backdrop-filter: blur(16px); border: 1px solid rgba(50, 132, 209, 0.3); border-radius: 20px; padding: 1.5rem; }
.custom-table { width: 100%; border-collapse: collapse; text-align: left; }
.custom-table th { padding: 0.8rem 1rem; font-size: 0.8rem; color: #a0aec0; border-bottom: 1px solid rgba(255, 255, 255, 0.1); }
.custom-table td { padding: 1rem; border-bottom: 1px solid rgba(255, 255, 255, 0.05); }
.id-cell { font-weight: 600; color: #38b6ff; }
.status-badge { padding: 3px 8px; border-radius: 6px; font-size: 0.75rem; background: rgba(239, 68, 68, 0.2); color: #f87171; }
.status-badge.active { background: rgba(34, 197, 94, 0.2); color: #4ade80; }
.loading-state { text-align: center; padding: 2rem; color: #a0aec0; }
.spinner { width: 30px; height: 30px; border: 3px solid rgba(255, 255, 255, 0.1); border-top-color: #0072ce; border-radius: 50%; animation: spin 1s infinite linear; margin: 0 auto 0.5rem auto; }
@keyframes spin { 100% { transform: rotate(360deg); } }

.modal-overlay { position: fixed; inset: 0; background: rgba(0, 0, 0, 0.75); display: flex; justify-content: center; align-items: center; z-index: 100; backdrop-filter: blur(4px); }
.modal-card { background: #0f1724; padding: 2em; border-radius: 20px; width: 380px; border: 1px solid #0072CE; }
.field { margin-bottom: 1rem; }
.input-field { width: 100%; padding: 0.8rem; border-radius: 10px; background: rgba(255, 255, 255, 0.08); border: 1px solid rgba(255, 255, 255, 0.15); color: #fff; outline: none; }
.btn-group { display: flex; gap: 10px; }
.button1 { flex: 1; padding: 0.8rem; border-radius: 10px; border: none; background: #0072CE; color: white; font-weight: 600; cursor: pointer; }
.button2 { flex: 1; padding: 0.8rem; border-radius: 10px; border: 1px solid rgba(255, 255, 255, 0.3); background: transparent; color: white; cursor: pointer; }
</style>