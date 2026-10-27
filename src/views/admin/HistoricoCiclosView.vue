<template>
  <div class="page space-y-6 historico-page">
    <div class="historico-header">
      <div class="page-heading">
        <h2 class="page-title">Histórico de Ciclos y Reportes</h2>
        <p class="page-subtitle">Resumen ejecutivo de jornadas de distribución de gas</p>
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
      <div class="history-metrics">
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
    <Teleport to="body">
      <div v-if="cicloSeleccionado" class="historico-modal">
        <div class="historico-modal__backdrop" @click="cicloSeleccionado = null" />
        <div class="historico-modal__panel" role="dialog" aria-modal="true" aria-label="Detalle del ciclo">
          <span class="historico-modal__handle" aria-hidden="true"></span>
          <div class="historico-modal__header">
            <div>
              <h3>{{ cicloSeleccionado.nombre_ciclo }}</h3>
              <p>Sector: {{ cicloSeleccionado.calles?.nombre || 'General (Todas las calles)' }}</p>
            </div>
            <button class="historico-modal__close" aria-label="Cerrar detalle" @click="cicloSeleccionado = null">✕</button>
          </div>

          <div class="historico-modal__body">
            <div class="history-detail-grid">
              <div class="history-detail-card">
                <span>Pedidos Solicitados</span>
                <span class="history-detail-value">{{ cicloSeleccionado.totalSolicitudes }}</span>
              </div>
              <div class="history-detail-card history-detail-card--green">
                <span>Entregados con Éxito</span>
                <span class="history-detail-value">{{ cicloSeleccionado.totalEntregados }}</span>
              </div>
            </div>

            <div>
              <h4 class="history-detail-title">Desglose por Tipo de Bombona:</h4>
              <ul class="history-breakdown">
                <li v-for="(cant, tipo) in cicloSeleccionado.desgloseBombonas" :key="tipo">
                  <span>Bombona {{ tipo }}</span>
                  <span>{{ cant }} unid.</span>
                </li>
              </ul>
            </div>
          </div>

          <div class="historico-modal__actions">
            <BaseButton variant="ghost" @click="cicloSeleccionado = null">Cerrar</BaseButton>
            <BaseButton variant="success" @click="imprimirReporte(cicloSeleccionado)">
              🖨️️ Imprimir Planilla
            </BaseButton>
          </div>
        </div>
      </div>
    </Teleport>
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

<style scoped>
.historico-page {
  display: flex;
  flex-direction: column;
}

.historico-header {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.historico-header :deep(.btn-custom) {
  width: 100%;
}

.history-metrics {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 12px;
}

.history-metrics > div {
  min-width: 0;
  padding: 16px !important;
}

/* --------------------------------------------------------------------------
   Modal de detalle · bottom sheet en móvil
   -------------------------------------------------------------------------- */
.historico-modal {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

.historico-modal__backdrop {
  position: absolute;
  inset: 0;
  background: rgba(15, 23, 42, 0.52);
  backdrop-filter: blur(3px);
  -webkit-backdrop-filter: blur(3px);
}

.historico-modal__panel {
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
  animation: historySheetUp 0.22s ease-out;
}

.historico-modal__handle {
  display: block;
  width: 40px;
  height: 4px;
  margin: 0 auto 14px;
  border-radius: 999px;
  background: #e2e8f0;
}

.historico-modal__header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.historico-modal__header h3 {
  color: var(--color-heading);
  font-size: 1.05rem;
  font-weight: 700;
  overflow-wrap: anywhere;
}

.historico-modal__header p {
  margin-top: 3px;
  color: var(--color-muted);
  font-size: 0.78rem;
}

.historico-modal__close {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 44px;
  height: 44px;
  margin: -8px -8px 0 0;
  border: 0;
  border-radius: 10px;
  background: transparent;
  color: var(--color-muted);
  font-size: 1.1rem;
  cursor: pointer;
}

.historico-modal__close:hover {
  background: var(--color-bg);
  color: var(--color-heading);
}

.historico-modal__body {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-top: 14px;
  padding-top: 14px;
  border-top: 1px solid var(--color-border);
}

.history-detail-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
}

.history-detail-card {
  display: flex;
  flex-direction: column;
  gap: 3px;
  min-width: 0;
  padding: 12px;
  background: var(--color-bg);
  border-radius: 10px;
}

.history-detail-card > span:first-child {
  color: var(--color-muted);
  font-size: 0.7rem;
  line-height: 1.35;
}

.history-detail-value {
  color: var(--color-heading);
  font-size: 1.3rem;
  font-weight: 700;
}

.history-detail-card--green {
  background: #f0fdf4;
}

.history-detail-card--green > span:first-child {
  color: #15803d;
}

.history-detail-card--green .history-detail-value {
  color: #166534;
}

.history-detail-title {
  margin-bottom: 8px;
  color: var(--color-muted);
  font-size: 0.72rem;
  font-weight: 600;
  letter-spacing: 0.03em;
  text-transform: uppercase;
}

.history-breakdown {
  overflow: hidden;
  border: 1px solid var(--color-border-light);
  border-radius: 10px;
}

.history-breakdown li {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 9px 12px;
  border-bottom: 1px solid var(--color-border-light);
  color: var(--color-text);
  font-size: 0.84rem;
}

.history-breakdown li:last-child {
  border-bottom: 0;
}

.history-breakdown li span:last-child {
  color: var(--color-heading);
  font-weight: 600;
}

.historico-modal__actions {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-top: 20px;
  padding-top: 14px;
  border-top: 1px solid var(--color-border);
}

.historico-modal__actions :deep(.btn-custom) {
  width: 100%;
}

@keyframes historySheetUp {
  from { transform: translateY(16px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

@media (min-width: 480px) {
  .history-metrics {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (min-width: 640px) {
  .historico-header {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
  }

  .historico-header :deep(.btn-custom) {
    width: auto;
  }

  .history-metrics {
    grid-template-columns: repeat(3, minmax(0, 1fr));
    gap: 16px;
  }

  .historico-modal {
    align-items: center;
    padding: 20px;
  }

  .historico-modal__panel {
    max-width: 520px;
    max-height: 85vh;
    padding: 20px;
    border-radius: 16px;
    animation: scaleIn 0.2s ease-out;
  }

  .historico-modal__handle {
    display: none;
  }

  .historico-modal__actions {
    flex-direction: row;
    justify-content: flex-end;
  }

  .historico-modal__actions :deep(.btn-custom) {
    width: auto;
  }
}

@media (min-width: 1024px) {
  .history-metrics > div {
    padding: 20px !important;
  }

  .historico-modal__panel {
    max-width: 560px;
    padding: 24px;
  }
}
</style>