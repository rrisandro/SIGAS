<template>
  <div class="page space-y-6 logistica-page">
    <div class="logistica-header">
      <div class="page-heading">
        <h2 class="page-title">Logística</h2>
        <p class="page-subtitle">Ciclos de distribución</p>
      </div>
      <BaseButton @click="openCreate">Nuevo ciclo</BaseButton>
    </div>

    <!-- Indicador de Carga o Mensajes -->
    <div v-if="cargando" class="py-6 text-center text-gray-500">
      Cargando ciclos de distribución...
    </div>

    <div v-else-if="errorMsg" class="p-4 bg-red-100 text-red-700 rounded-lg border border-red-300">
      {{ errorMsg }}
    </div>

    <!-- Tabla de Ciclos -->
    <CrudDataTable
      v-else
      :columns="columns"
      :rows="rows"
      :search-keys="['nombre', 'calleNombre', 'estado']"
    >
      <template #cell-estado="{ row }">
        <StatusBadge :status="row.estado" />
      </template>
      <template #actions="{ row }">
        <BaseButton
          v-if="row.estado === 'planificado' || row.estado === 'creado'"
          size="sm"
          variant="success"
          @click="startCiclo(row)"
        >
          Iniciar
        </BaseButton>
        <BaseButton
          v-else-if="row.estado === 'activo' || row.estado === 'en_progreso'"
          size="sm"
          variant="warning"
          @click="completeCiclo(row)"
        >
          Completar
        </BaseButton>
        <span v-else class="text-xs text-gray-500">Cerrado</span>
      </template>
    </CrudDataTable>

    <!-- Modal para Crear Nuevo Ciclo -->
    <Teleport to="body">
      <div v-if="showForm" class="admin-modal-overlay">
        <div class="admin-modal-backdrop" @click="showForm = false" />
        <div class="admin-modal-panel" role="dialog" aria-modal="true" aria-label="Nuevo ciclo de distribución">
          <span class="admin-modal-handle" aria-hidden="true"></span>
          <h3 class="admin-modal-title">Nuevo ciclo de distribución</h3>
          
          <div class="admin-modal-form">
            <BaseInput v-model="form.nombre" label="Nombre del ciclo" placeholder="Ej: Jornada Octubre 2026" />
            
            <!-- Selector de Calle -->
            <div>
              <label class="admin-modal-label" for="logistica-calle">Calle destino</label>
              <select
                id="logistica-calle"
                v-model="form.id_calle"
                class="admin-modal-select"
              >
                <option :value="null">Todas las calles (Ciclo general)</option>
                <option v-for="calle in listaCalles" :key="calle.id_calle" :value="calle.id_calle">
                  {{ calle.nombre }}
                </option>
              </select>
            </div>
          </div>

          <div class="admin-modal-actions">
            <BaseButton variant="ghost" @click="showForm = false">Cancelar</BaseButton>
            <BaseButton :disabled="guardando || !form.nombre" @click="save">
              {{ guardando ? 'Guardando...' : 'Guardar' }}
            </BaseButton>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { computed, reactive, ref, onMounted } from 'vue'
import CrudDataTable from '../../components/ui/CrudDataTable.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import { supabase } from '../../lib/supabase'

const columns = [
  { key: 'id_ciclo', label: '#' },
  { key: 'nombre', label: 'Ciclo' },
  { key: 'calleNombre', label: 'Calle' },
  { key: 'fechaInicio', label: 'Inicio' },
  { key: 'fechaFin', label: 'Fin' },
  { key: 'estado', label: 'Estado' },
]

const ciclos = ref([])
const listaCalles = ref([])
const cargando = ref(true)
const guardando = ref(false)
const errorMsg = ref('')

const rows = computed(() => {
  return ciclos.value.map(c => ({
    id_ciclo: c.id_ciclo,
    nombre: c.nombre_ciclo,
    calleNombre: c.calles ? c.calles.nombre : 'Todas las calles',
    fechaInicio: c.fecha_inicio ? new Date(c.fecha_inicio).toLocaleDateString() : '-',
    fechaFin: c.fecha_cierre ? new Date(c.fecha_cierre).toLocaleDateString() : '-',
    estado: c.estado
  }))
})

const showForm = ref(false)
const form = reactive({ nombre: '', id_calle: null })

// 1. Cargar ciclos y lista de calles de Supabase
async function fetchDatos() {
  cargando.value = true
  errorMsg.value = ''

  const { data: callesData } = await supabase
    .from('calles')
    .select('id_calle, nombre')
    .eq('activo', true)
    .order('nombre')
  
  listaCalles.value = callesData || []

  const { data: ciclosData, error } = await supabase
    .from('ciclos_distribucion')
    .select('*, calles(id_calle, nombre)')
    .order('id_ciclo', { ascending: false })

  if (error) {
    errorMsg.value = 'Error al cargar ciclos: ' + error.message
  } else {
    ciclos.value = ciclosData || []
  }

  cargando.value = false
}

onMounted(() => {
  fetchDatos()
})

function openCreate() {
  form.nombre = ''
  form.id_calle = null
  showForm.value = true
}

// 2. Guardar nuevo ciclo enviando id_calle directamente (soporta NULL)
async function save() {
  if (!form.nombre) return

  guardando.value = true
  errorMsg.value = ''

  const { error } = await supabase
    .from('ciclos_distribucion')
    .insert([
      {
        nombre_ciclo: form.nombre,
        id_calle: form.id_calle, // Envía null si se eligió "Todas las calles"
        estado: 'activo',
        fecha_inicio: new Date().toISOString()
      }
    ])

  if (error) {
    // Capturar intento de ciclo duplicado bloqueado por el índice único
    if (error.code === '23505' || error.message.includes('idx_unico_ciclo_activo')) {
      alert('⚠️ No se puede activar este ciclo. Ya existe un ciclo de distribución en estado "activo". Debes completar o cerrar el ciclo actual antes de iniciar uno nuevo.')
    } else {
      alert('Error al guardar el ciclo: ' + error.message)
    }
  } else {
    showForm.value = false
    await fetchDatos()
  }

  guardando.value = false
}

// 3. Iniciar un ciclo en estado planificado/creado
async function startCiclo(row) {
  const { error } = await supabase
    .from('ciclos_distribucion')
    .update({ estado: 'activo' })
    .eq('id_ciclo', row.id_ciclo)

  if (error) {
    if (error.code === '23505' || error.message.includes('idx_unico_ciclo_activo')) {
      alert('⚠️ No se puede activar este ciclo. Ya existe un ciclo activo en este momento. Completa el ciclo actual antes de iniciar otro.')
    } else {
      alert('Error al activar ciclo: ' + error.message)
    }
  } else {
    await fetchDatos()
  }
}

// 4. Completar / Cerrar un ciclo
async function completeCiclo(row) {
  const { error } = await supabase
    .from('ciclos_distribucion')
    .update({ 
      estado: 'cerrado',
      fecha_cierre: new Date().toISOString()
    })
    .eq('id_ciclo', row.id_ciclo)

  if (error) {
    alert('Error al cerrar ciclo: ' + error.message)
  } else {
    await fetchDatos()
  }
}
</script>

<style scoped>
.logistica-page {
  display: flex;
  flex-direction: column;
}

.logistica-header {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.logistica-header :deep(.btn-custom) {
  width: 100%;
}

/* --------------------------------------------------------------------------
   Modal · bottom sheet en móvil
   -------------------------------------------------------------------------- */
.admin-modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

.admin-modal-backdrop {
  position: absolute;
  inset: 0;
  background: rgba(15, 23, 42, 0.52);
  backdrop-filter: blur(3px);
  -webkit-backdrop-filter: blur(3px);
}

.admin-modal-panel {
  position: relative;
  z-index: 1;
  width: 100%;
  max-height: 85dvh;
  padding: 12px 16px calc(18px + var(--safe-bottom));
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
  background: #ffffff;
  border-radius: 22px 22px 0 0;
  box-shadow: 0 -12px 40px rgba(15, 23, 42, 0.2);
  animation: adminSheetUp 0.22s ease-out;
}

.admin-modal-handle {
  display: block;
  width: 40px;
  height: 4px;
  margin: 0 auto 14px;
  border-radius: 999px;
  background: #e2e8f0;
}

.admin-modal-title {
  color: var(--color-heading);
  font-size: 1.05rem;
  font-weight: 700;
}

.admin-modal-form {
  display: flex;
  flex-direction: column;
  gap: 14px;
  margin-top: 18px;
}

.admin-modal-label {
  display: block;
  margin-bottom: 6px;
  color: var(--color-text);
  font-size: 0.8125rem;
  font-weight: 600;
}

.admin-modal-select {
  width: 100%;
  min-height: 44px;
  padding: 0 12px;
  border: 1px solid #d1d5db;
  border-radius: 11px;
  background: #ffffff;
  color: var(--color-text);
  font-size: 16px;
  outline: none;
  cursor: pointer;
}

.admin-modal-select:focus {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.14);
}

.admin-modal-actions {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-top: 22px;
}

.admin-modal-actions :deep(.btn-custom) {
  width: 100%;
}

@keyframes adminSheetUp {
  from { transform: translateY(16px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

@media (min-width: 640px) {
  .logistica-header {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
  }

  .logistica-header :deep(.btn-custom) {
    width: auto;
  }

  .admin-modal-overlay {
    align-items: center;
    padding: 20px;
  }

  .admin-modal-panel {
    max-width: 480px;
    max-height: 85vh;
    padding: 20px;
    border-radius: 16px;
    animation: scaleIn 0.2s ease-out;
  }

  .admin-modal-handle {
    display: none;
  }

  .admin-modal-select {
    min-height: 40px;
    font-size: 15px;
  }

  .admin-modal-actions {
    flex-direction: row;
    justify-content: flex-end;
  }

  .admin-modal-actions :deep(.btn-custom) {
    width: auto;
  }
}

@media (min-width: 1024px) {
  .admin-modal-panel {
    max-width: 520px;
    padding: 24px;
  }

  .admin-modal-select {
    min-height: 38px;
    font-size: 14px;
  }
}
</style>