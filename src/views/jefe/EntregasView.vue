<template>
  <div class="space-y-6">
    <div>
      <h2 class="text-xl font-medium text-gray-700">Control de Entregas</h2>
      <p class="text-sm text-gray-500">Registra las entregas de bombonas realizadas</p>
    </div>

    <!-- Entregas Pendientes -->
    <CrudDataTable
      title="Entregas Pendientes"
      :columns="columnsPendientes"
      :rows="pedidosPendientes"
      :search-keys="['familia', 'tipo']"
    >
      <template #cell-estatus="{ row }">
        <StatusBadge :status="row.estatus" />
      </template>
      <template #actions="{ row }">
        <BaseButton size="sm" variant="success" @click="openEntrega(row)">
          Registrar Entrega
        </BaseButton>
      </template>
    </CrudDataTable>

    <!-- Historial de Entregas -->
    <CrudDataTable
      title="Historial de Entregas"
      :columns="columnsHistorial"
      :rows="entregasRealizadas"
      :search-keys="['familia', 'tipo', 'ciclo']"
    >
      <template #cell-fecha_entrega="{ row }">
        {{ formatearFecha(row.fecha_entrega) }}
      </template>
    </CrudDataTable>

    <!-- Modal para registrar entrega -->
    <div v-if="showEntrega" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" @click="showEntrega = false" />
      <div class="relative w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl">
        <!-- Header del modal -->
        <div class="flex items-center gap-3 mb-4">
          <div class="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center">
            <svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <div>
            <h3 class="text-lg font-semibold text-gray-800">Registrar Entrega</h3>
            <p class="text-sm text-gray-500">
              {{ selected?.tipo || '' }} → {{ selected?.familia || '' }}
            </p>
          </div>
        </div>

        <!-- Divider -->
        <div class="border-t border-gray-200 my-4" />

        <!-- Formulario -->
        <div class="space-y-4">
          <BaseInput 
            v-model="cicloDistribucion" 
            label="Ciclo de Distribución" 
            placeholder="Ej: Ciclo 1 - Septiembre 2026"
            required
          />
          
          <!-- Sugerencias de ciclos -->
          <div>
            <label class="block text-xs font-medium text-gray-500 mb-2">Ciclos sugeridos:</label>
            <div class="flex flex-wrap gap-2">
              <button
                v-for="ciclo in ciclosSugeridos"
                :key="ciclo"
                @click="cicloDistribucion = ciclo"
                :class="cicloDistribucion === ciclo 
                  ? 'bg-green-100 text-green-700 border-green-300' 
                  : 'bg-gray-50 text-gray-600 border-gray-200 hover:bg-gray-100'"
                class="px-3 py-1.5 text-xs font-medium rounded-full border transition"
              >
                {{ ciclo }}
              </button>
            </div>
          </div>

          <!-- Error -->
          <p v-if="errorCiclo" class="text-sm text-red-600 flex items-center gap-1">
            <svg class="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clip-rule="evenodd" />
            </svg>
            {{ errorCiclo }}
          </p>
        </div>

        <!-- Divider -->
        <div class="border-t border-gray-200 my-4" />

        <!-- Botones -->
        <div class="flex justify-end gap-2">
          <BaseButton variant="ghost" @click="showEntrega = false">Cancelar</BaseButton>
          <BaseButton variant="success" @click="confirmarEntrega">
            <template #iconLeft>
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>
            </template>
            Confirmar Entrega
          </BaseButton>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref, onMounted } from 'vue'
import CrudDataTable from '../../components/ui/CrudDataTable.vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import { usePedidos } from '../../composables/usePedidos'
import { supabase } from '../../lib/supabase'

const { pedidos, fetchPedidos, registrarEntrega } = usePedidos()

const showEntrega = ref(false)
const selected = ref(null)
const cicloDistribucion = ref('')
const errorCiclo = ref('')
const historialEntregas = ref([])

// Ciclos sugeridos automáticamente según el mes actual
const ciclosSugeridos = computed(() => {
  const meses = ['Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio', 
                 'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre']
  const ahora = new Date()
  const mesActual = meses[ahora.getMonth()]
  const año = ahora.getFullYear()
  
  return [
    `Ciclo 1 - ${mesActual} ${año}`,
    `Ciclo 2 - ${mesActual} ${año}`,
    `Ciclo 1 - ${meses[(ahora.getMonth() + 1) % 12]} ${año}`
  ]
})

const columnsPendientes = [
  { key: 'id', label: '#' },
  { key: 'fecha', label: 'Fecha Solicitud' },
  { key: 'familia', label: 'Familia' },
  { key: 'tipo', label: 'Tipo' },
  { key: 'estatus', label: 'Estatus' },
]

const columnsHistorial = [
  { key: 'id', label: '#' },
  { key: 'familia', label: 'Familia' },
  { key: 'tipo', label: 'Tipo' },
  { key: 'ciclo', label: 'Ciclo' },
  { key: 'fecha_entrega', label: 'Fecha Entrega' },
]

const pedidosPendientes = computed(() =>
  pedidos.value
    .filter((p) => p.status === 'en_proceso')
    .map((p) => ({
      id: p.id_pedido,
      fecha: formatearFecha(p.fecha_solicitud),
      familia: p.familia?.nombre_familia || 'Sin familia',
      tipo: `Bombona ${p.tipo_bombona}`,
      estatus: p.status,
      _original: p
    }))
)

const entregasRealizadas = computed(() =>
  historialEntregas.value.map((h) => ({
    id: h.id_historial,
    familia: h.pedido?.familia?.nombre_familia || 'Sin familia',
    tipo: `Bombona ${h.pedido?.tipo_bombona}`,
    ciclo: h.ciclo_distribucion,
    fecha_entrega: h.fecha_entrega,
    _original: h
  }))
)

onMounted(async () => {
  await fetchPedidos()
  await cargarHistorial()
})

async function cargarHistorial() {
  const { data, error } = await supabase
    .from('historial_distribucion')
    .select(`
      *,
      pedido:pedidos (
        id_pedido,
        tipo_bombona,
        familia:familias (
          id,
          nombre_familia
        )
      )
    `)
    .order('fecha_entrega', { ascending: false })

  if (!error) {
    historialEntregas.value = data || []
  }
}

function openEntrega(row) {
  selected.value = row
  cicloDistribucion.value = ''
  errorCiclo.value = ''
  showEntrega.value = true
}

async function confirmarEntrega() {
  if (!cicloDistribucion.value.trim()) {
    errorCiclo.value = 'Debes ingresar el ciclo de distribución'
    return
  }

  errorCiclo.value = ''

  const success = await registrarEntrega(
    selected.value._original.id_pedido,
    cicloDistribucion.value
  )

  if (success) {
    showEntrega.value = false
    selected.value = null
    cicloDistribucion.value = ''
    errorCiclo.value = ''
    await cargarHistorial()
  } else {
    errorCiclo.value = 'Error al registrar la entrega'
  }
}

function formatearFecha(fecha) {
  if (!fecha) return '-'
  return new Date(fecha).toLocaleDateString('es-VE')
}
</script>