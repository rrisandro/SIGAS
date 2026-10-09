<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold text-gray-800">Histórico de Ciclos y Reportes</h2>
        <p class="text-sm text-gray-500">Resumen ejecutivo de jornadas de distribución de gas</p>
      </div>
      <BaseButton variant="ghost" @click="cargarHistorico">
        🔄 Actualizar Datos
      </BaseButton>
    </div>

    <!-- Indicador de Carga -->
    <div v-if="cargando" class="py-8 text-center text-gray-500">
      Cargando estadísticas de jornadas...
    </div>

    <div v-else class="space-y-6">
      <!-- Tarjetas Resumen Global -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm space-y-1">
          <p class="text-xs font-semibold text-gray-400 uppercase">Total Ciclos Realizados</p>
          <p class="text-2xl font-bold text-gray-800">{{ listaHistorico.length }}</p>
        </div>
        <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm space-y-1">
          <p class="text-xs font-semibold text-gray-400 uppercase">Bombonas Despachadas</p>
          <p class="text-2xl font-bold text-green-600">{{ totalBombonasEntregadasGlobal }}</p>
        </div>
        <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm space-y-1">
          <p class="text-xs font-semibold text-gray-400 uppercase">Efectividad General</p>
          <p class="text-2xl font-bold text-blue-600">{{ porcentajeEfectividad }}%</p>
        </div>
      </div>

      <!-- Tabla Consolidada por Ciclo -->
      <CrudDataTable
        title="Consolidado de Ciclos de Distribución"
        :columns="columnsHistorico"
        :rows="rowsHistorico"
        :search-keys="['nombre', 'calle', 'estado']"
      >
        <template #cell-estado="{ row }">
          <StatusBadge :status="row.estado" />
        </template>
        <template #actions="{ row }">
          <BaseButton size="sm" variant="ghost" @click="verDetalleCiclo(row._original)">
            🔍 Ver Detalle
          </BaseButton>
        </template>
      </CrudDataTable>
    </div>

    <!-- Modal Detalle del Ciclo -->
    <div v-if="cicloSeleccionado" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" @click="cicloSeleccionado = null" />
      <div class="relative w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl space-y-4">
        <div class="flex justify-between items-start">
          <div>
            <h3 class="text-lg font-bold text-gray-800">{{ cicloSeleccionado.nombre_ciclo }}</h3>
            <p class="text-xs text-gray-500">Sector: {{ cicloSeleccionado.calles?.nombre || 'General (Todas las calles)' }}</p>
          </div>
          <button @click="cicloSeleccionado = null" class="text-gray-400 hover:text-gray-600">✕</button>
        </div>

        <div class="border-t border-gray-200 pt-3 space-y-3">
          <div class="grid grid-cols-2 gap-3 text-sm">
            <div class="bg-gray-50 p-3 rounded-lg">
              <span class="block text-xs text-gray-500">Pedidos Solicitados</span>
              <span class="font-bold text-gray-800">{{ cicloSeleccionado.totalSolicitudes }}</span>
            </div>
            <div class="bg-green-50 p-3 rounded-lg">
              <span class="block text-xs text-green-700">Entregados con Éxito</span>
              <span class="font-bold text-green-800">{{ cicloSeleccionado.totalEntregados }}</span>
            </div>
          </div>

          <div>
            <h4 class="text-xs font-semibold text-gray-500 uppercase mb-2">Desglose por Tipo de Bombona:</h4>
            <ul class="divide-y divide-gray-100 text-sm">
              <li v-for="(cant, tipo) in cicloSeleccionado.desgloseBombonas" :key="tipo" class="py-1.5 flex justify-between">
                <span>Bombona {{ tipo }}</span>
                <span class="font-semibold text-gray-700">{{ cant }} unid.</span>
              </li>
            </ul>
          </div>
        </div>

        <div class="border-t border-gray-200 pt-3 flex justify-end gap-2">
          <BaseButton variant="ghost" @click="cicloSeleccionado = null">Cerrar</BaseButton>
          <BaseButton variant="success" @click="imprimirReporte(cicloSeleccionado)">
            🖨️️ Imprimir Planilla
          </BaseButton>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import CrudDataTable from '../../components/ui/CrudDataTable.vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import { supabase } from '../../lib/supabase'

const cargando = ref(true)
const listaHistorico = ref([])
const cicloSeleccionado = ref(null)

const columnsHistorico = [
  { key: 'id', label: '#' },
  { key: 'nombre', label: 'Ciclo / Jornada' },
  { key: 'calle', label: 'Calle / Sector' },
  { key: 'entregados', label: 'Bombonas Entregadas' },
  { key: 'fecha', label: 'Fecha Inicio' },
  { key: 'estado', label: 'Estado' },
]

const totalBombonasEntregadasGlobal = computed(() => {
  return listaHistorico.value.reduce((acc, c) => acc + (c.totalEntregados || 0), 0)
})

const porcentajeEfectividad = computed(() => {
  const totalSolicitados = listaHistorico.value.reduce((acc, c) => acc + (c.totalSolicitudes || 0), 0)
  if (!totalSolicitados) return 0
  return Math.round((totalBombonasEntregadasGlobal.value / totalSolicitados) * 100)
})

const rowsHistorico = computed(() => {
  return listaHistorico.value.map((c) => ({
    id: c.id_ciclo,
    nombre: c.nombre_ciclo,
    calle: c.calles?.nombre || 'Comunidad General',
    entregados: `${c.totalEntregados} / ${c.totalSolicitudes}`,
    fecha: c.fecha_inicio ? new Date(c.fecha_inicio).toLocaleDateString('es-VE') : '-',
    estado: c.estado,
    _original: c
  }))
})

async function cargarHistorico() {
  cargando.value = true

  // 1. Cargar ciclos con relaciones
  const { data: ciclosData, error } = await supabase
    .from('ciclos_distribucion')
    .select(`
      *,
      calles (id_calle, nombre),
      pedidos (
        id_pedido,
        tipo_bombona,
        status
      )
    `)
    .order('id_ciclo', { ascending: false })

  if (!error && ciclosData) {
    // Procesar métricas por cada ciclo
    listaHistorico.value = ciclosData.map((c) => {
      const pedidosList = c.pedidos || []
      const entregados = pedidosList.filter(p => p.status === 'entregado')

      // Conteo por tipo de bombona
      const desglose = {}
      entregados.forEach(p => {
        const t = p.tipo_bombona || 'No especificada'
        desglose[t] = (desglose[t] || 0) + 1
      })

      return {
        ...c,
        totalSolicitudes: pedidosList.length,
        totalEntregados: entregados.length,
        desgloseBombonas: desglose
      }
    })
  }

  cargando.value = false
}

onMounted(() => {
  cargarHistorico()
})

function verDetalleCiclo(ciclo) {
  cicloSeleccionado.value = ciclo
}

function imprimirReporte(ciclo) {
  window.print()
}
</script>