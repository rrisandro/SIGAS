<template>
  <div class="space-y-6">
    <div>
      <h2 class="text-xl font-medium text-gray-700">Dashboard Global</h2>
      <p class="text-sm text-gray-500">Resumen general del sistema</p>
    </div>

    <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      <div v-for="card in cards" :key="card.label" class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
        <p class="text-sm text-gray-500">{{ card.label }}</p>
        <p class="mt-2 text-2xl font-medium text-gray-700">{{ card.value }}</p>
      </div>
    </div>

    <div class="grid gap-4 lg:grid-cols-2">
      <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
        <h3 class="mb-4 text-base font-medium text-gray-700">Solicitudes recientes</h3>
        <div class="space-y-3">
          <div
            v-for="s in recent"
            :key="s.id"
            class="flex items-center justify-between rounded-xl bg-gray-50 px-4 py-3"
          >
            <div>
              <p class="text-sm font-medium text-gray-700">{{ getFamiliaNombre(s.familiaId) }}</p>
              <p class="text-xs text-gray-500">{{ s.fecha }} · {{ getTipoNombre(s.tipoBombonaId) }}</p>
            </div>
            <StatusBadge :status="s.estatus" />
          </div>
        </div>
      </div>
      <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
        <h3 class="mb-4 text-base font-medium text-gray-700">Ciclos activos</h3>
        <div class="space-y-3">
          <div
            v-for="c in ciclosActivos"
            :key="c.id"
            class="flex items-center justify-between rounded-xl bg-gray-50 px-4 py-3"
          >
            <div>
              <p class="text-sm font-medium text-gray-700">{{ c.nombre }}</p>
              <p class="text-xs text-gray-500">{{ c.fechaInicio }} → {{ c.fechaFin }}</p>
            </div>
            <StatusBadge :status="c.estado" />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import { useMockData } from '../../composables/useMockData.js'

const {
  calles,
  jefes,
  familias,
  solicitudes,
  ciclosDistribucion,
  getFamiliaNombre,
  getTipoNombre,
} = useMockData()

const cards = computed(() => [
  { label: 'Calles activas', value: calles.value.filter((c) => c.activo).length },
  { label: 'Jefes activos', value: jefes.value.filter((j) => j.activo).length },
  { label: 'Familias activas', value: familias.value.filter((f) => f.activo).length },
  { label: 'Pendientes', value: solicitudes.value.filter((s) => s.estatus === 'pendiente').length },
])

const recent = computed(() => solicitudes.value.slice(0, 5))
const ciclosActivos = computed(() =>
  ciclosDistribucion.value.filter((c) => c.estado !== 'completado')
)
</script>
