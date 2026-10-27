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
            <tr v-for="calle in calles" :key="calle.id_calle" class="table-row">
              <td class="id-cell" data-label="ID">#{{ calle.id_calle }}</td>
              <td class="name-cell" data-label="Nombre de la calle">{{ calle.nombre }}</td>
              <td data-label="Estado">
                <span class="status-badge" :class="{ active: calle.activo }">
                  <span class="status-dot"></span>
                  {{ calle.activo ? 'Activa' : 'Inactiva' }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- MODAL NUEVA CALLE -->
    <div v-if="mostrarModal" class="modal-overlay" @click.self="mostrarModal = false">
      <div class="modal-card" role="dialog" aria-modal="true" aria-label="Registrar nueva calle">
        <span class="modal-sheet-handle" aria-hidden="true"></span>
        <h3>Registrar Nueva Calle</h3>
        <form @submit.prevent="guardarCalle" class="modal-form">
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
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap');

.admin-page { 
  font-family: 'Plus Jakarta Sans', sans-serif; 
  color: #1e293b; 
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
  background-color: transparent;
  min-height: 0;
}

.header-banner { 
  background: #ffffff; 
  border: 1px solid #e2e8f0; 
  border-radius: 20px; 
  padding: 2.2rem; 
  display: flex; 
  justify-content: space-between; 
  align-items: center; 
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.05);
}

.badge { 
  display: inline-flex; 
  align-items: center; 
  background: #eff6ff; 
  color: #2563eb; 
  border: 1px solid #dbeafe; 
  padding: 6px 14px; 
  border-radius: 20px; 
  font-size: 0.75rem; 
  font-weight: 600; 
  margin-bottom: 0.75rem; 
}

.header-banner h1 { 
  margin: 0; 
  font-size: 1.85rem; 
  font-weight: 700; 
  color: #0f172a; 
  letter-spacing: -0.02em; 
}

.header-banner p { 
  margin: 0.4rem 0 0 0; 
  color: #64748b; 
  font-size: 0.92rem; 
}

.action-btn { 
  background: #2563eb; 
  color: #ffffff; 
  border: none; 
  padding: 0.85rem 1.6rem; 
  border-radius: 12px; 
  font-weight: 600; 
  font-size: 0.88rem;
  cursor: pointer; 
  transition: all 0.2s ease;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
}

.action-btn:hover { 
  background: #1d4ed8; 
  transform: translateY(-1px); 
}

.table-card { 
  background: #ffffff; 
  border: 1px solid #e2e8f0; 
  border-radius: 20px; 
  padding: 1.6rem; 
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.04); 
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
  color: #64748b; 
  background-color: #f8fafc;
  border-bottom: 1px solid #e2e8f0; 
  font-weight: 600; 
}

.custom-table td { 
  padding: 1.1rem 1rem; 
  border-bottom: 1px solid #f1f5f9; 
  font-size: 0.9rem; 
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
  color: #2563eb; 
}

.name-cell {
  font-weight: 500;
  color: #0f172a;
}

.status-badge { 
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px; 
  border-radius: 20px; 
  font-size: 0.78rem; 
  font-weight: 600; 
  background: #fef2f2; 
  color: #dc2626; 
  border: 1px solid #fecaca; 
}

.status-badge.active { 
  background: #ecfdf5; 
  color: #059669; 
  border-color: #a7f3d0; 
}

.status-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background-color: currentColor;
}

.loading-state { 
  text-align: center; 
  padding: 3rem; 
  color: #64748b; 
}

.spinner { 
  width: 32px; 
  height: 32px; 
  border: 3px solid #e2e8f0; 
  border-top-color: #2563eb; 
  border-radius: 50%; 
  animation: spin 1s infinite linear; 
  margin: 0 auto 1rem auto; 
}

@keyframes spin { 
  100% { transform: rotate(360deg); } 
}

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
  border-color: #2563eb;
  background: #ffffff;
  box-shadow: 0 0 0 3px rgba(37, 99, 235, 0.1);
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
  background: #2563eb; 
  color: white; 
  font-weight: 600; 
  font-size: 0.9rem;
  cursor: pointer; 
  transition: background 0.2s ease;
}

.button1:hover {
  background: #1d4ed8;
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
}

/* ==========================================================================
   RESPONSIVE · mobile-first
   ========================================================================== */
.header-banner {
  flex-direction: column;
  align-items: stretch;
  gap: 14px;
  padding: 18px 16px;
  border-radius: 16px;
}

.header-banner h1 {
  font-size: 1.4rem;
  line-height: 1.25;
}

.header-banner p {
  font-size: 0.84rem;
  line-height: 1.5;
}

.badge {
  font-size: 0.68rem;
}

.action-btn {
  width: 100%;
  min-height: 44px;
  padding: 10px 16px;
  font-size: 0.85rem;
}

.table-card {
  padding: 14px;
  border-radius: 16px;
}

.modal-overlay {
  align-items: flex-end;
  padding: 0;
}

.modal-card {
  width: 100%;
  max-width: none;
  max-height: 85dvh;
  padding: 12px 16px calc(16px + var(--safe-bottom));
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
  border-radius: 20px 20px 0 0;
  animation: sheetUp 0.22s ease-out;
}

.modal-sheet-handle {
  display: block;
  width: 40px;
  height: 4px;
  margin: 0 auto 14px;
  border-radius: 999px;
  background: #e2e8f0;
}

.modal-card h3 {
  margin-bottom: 16px;
  font-size: 1.08rem;
}

.input-field {
  min-height: 44px;
  font-size: 16px;
}

.btn-group {
  flex-direction: column;
  gap: 8px;
}

.button1,
.button2 {
  min-height: 44px;
}

@keyframes sheetUp {
  from { transform: translateY(16px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

@media (min-width: 640px) {
  .admin-page {
    gap: 1.5rem;
  }

  .header-banner {
    flex-direction: row;
    align-items: center;
    padding: 1.6rem;
  }

  .header-banner h1 {
    font-size: 1.6rem;
  }

  .action-btn {
    width: auto;
    min-height: 40px;
  }

  .table-card {
    padding: 1.25rem;
  }

  .modal-overlay {
    align-items: center;
    padding: 20px;
  }

  .modal-card {
    width: 400px;
    max-width: 100%;
    max-height: 85vh;
    padding: 1.75rem;
    border-radius: 18px;
    animation: none;
  }

  .modal-sheet-handle {
    display: none;
  }

  .input-field {
    min-height: 40px;
    font-size: 15px;
  }

  .btn-group {
    flex-direction: row;
    gap: 10px;
  }

  .button1,
  .button2 {
    min-height: 40px;
  }
}

@media (min-width: 1024px) {
  .admin-page {
    gap: 1.75rem;
  }

  .header-banner {
    padding: 2.2rem;
    border-radius: 20px;
  }

  .header-banner h1 {
    font-size: 1.85rem;
  }

  .table-card {
    padding: 1.6rem;
    border-radius: 20px;
  }

  .input-field {
    min-height: 38px;
    font-size: 14px;
  }
}
</style>