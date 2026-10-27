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
        <p>Listado de responsables asignados por sector en Supabase (5 por página)</p>
      </div>
      <div class="header-actions">
        <button class="action-btn" @click="abrirModalCrear">+ Nuevo Jefe</button>
        <button class="refresh-btn" @click="cargarJefes" :disabled="loading" title="Actualizar datos">
          <svg viewBox="0 0 24 24" class="icon" :class="{ spin: loading }">
            <path fill="currentColor" d="M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6c0 1.01-.25 1.97-.7 2.8l1.46 1.46A7.93 7.93 0 0 0 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6c0-1.01.25-1.97.7-2.8L5.24 7.74A7.93 7.93 0 0 0 4 12c0 4.42 3.58 8 8 8v3l4-4l-4-4v3z"/>
          </svg>
        </button>
      </div>
    </header>

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

      <div v-else class="table-wrapper">
        <table class="custom-table">
          <thead>
            <tr>
              <th>Cédula</th>
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
              </td>
              <td data-label="Calle asignada">
                <span class="badge-calle">{{ obtenerNombreCalle(jefe.id_calle) }}</span>
              </td>
              <td data-label="Cargo">
                <span class="role-badge">Jefe de Calle</span>
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
    </div>
  </div>
</template>

<script setup>
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

    if (!error && data) {
      jefes.value = data
    }
  } catch (e) {
    console.error('Error cargando jefes:', e)
  } finally {
    loading.value = false
  }
}

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

.header-actions {
  display: flex;
  align-items: center;
  gap: 10px;
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
  width: 18px;
  height: 18px;
}

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

  .header-actions {
    flex-direction: column;
    width: 100%;
  }

  .action-btn, .refresh-btn {
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

  .modal-overlay {
    align-items: center;
  }

  .modal-card {
    width: 400px;
    border-radius: 18px;
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