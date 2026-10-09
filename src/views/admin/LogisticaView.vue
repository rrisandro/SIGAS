<<template>
  <div class="space-y-6">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div>
        <h2 class="text-xl font-medium text-gray-700">Logística</h2>
        <p class="text-sm text-gray-500">Ciclos de distribución</p>
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

    <!-- Modal Modal para Crear Nuevo Ciclo -->
    <Teleport to="body">
      <div v-if="showForm" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-gray-700/30" @click="showForm = false" />
        <div class="relative w-full max-w-md rounded-2xl bg-white p-6 shadow-xl space-y-4">
          <h3 class="text-lg font-medium text-gray-700">Nuevo ciclo de distribución</h3>
          
          <div class="space-y-3">
            <BaseInput v-model="form.nombre" label="Nombre del ciclo" placeholder="Ej: Jornada Octubre 2026" />
            
            <!-- Selector de Calle -->
            <div>
              <label class="block text-sm font-medium text-gray-700 mb-1">Calle destino</label>
              <select
                v-model="form.id_calle"
                class="w-full px-3 py-2 border rounded-md text-sm bg-white focus:outline-none focus:ring-2 focus:ring-blue-500"
              >
                <option :value="null">Todas las calles (Ciclo general)</option>
                <option v-for="calle in listaCalles" :key="calle.id_calle" :value="calle.id_calle">
                  {{ calle.nombre }}
                </option>
              </select>
            </div>
          </div>

          <div class="mt-6 flex justify-end gap-2">
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

// 1. Cargar ciclos (con la relación de calles) y catálogo de calles de Supabase
async function fetchDatos() {
  cargando.value = true
  errorMsg.value = ''

  // Cargar lista de calles activas
  const { data: callesData } = await supabase
    .from('calles')
    .select('id_calle, nombre')
    .eq('activo', true)
    .order('nombre')
  
  listaCalles.value = callesData || []

  // Cargar ciclos con el JOIN hacia la tabla calles
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

// 2. Guardar nuevo ciclo con la calle seleccionada
async function save() {
  if (!form.nombre) return

  // Si eligió "Todas las calles" y no tienes DROP NOT NULL, le asignamos la primera calle por defecto
  const calleAEnviar = form.id_calle || (listaCalles.value.length > 0 ? listaCalles.value[0].id_calle : 1)

  guardando.value = true
  errorMsg.value = ''

  const { error } = await supabase
    .from('ciclos_distribucion')
    .insert([
      {
        nombre_ciclo: form.nombre,
        id_calle: calleAEnviar, // Envía el id_calle válido
        estado: 'activo',
        fecha_inicio: new Date().toISOString()
      }
    ])

  if (error) {
    alert('Error al guardar el ciclo: ' + error.message)
  } else {
    showForm.value = false
    await fetchDatos()
  }

  guardando.value = false
}
// 3. Iniciar un ciclo
async function startCiclo(row) {
  const { error } = await supabase
    .from('ciclos_distribucion')
    .update({ estado: 'activo' })
    .eq('id_ciclo', row.id_ciclo)

  if (error) {
    alert('Error al activar ciclo: ' + error.message)
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