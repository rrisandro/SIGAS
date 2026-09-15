<template>
  <div class="space-y-6">
    <div>
      <h2 class="text-xl font-medium text-gray-700">Mi Panel</h2>
      <p class="text-sm text-gray-500">Resumen de tus solicitudes de gas</p>
    </div>

    <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      <div v-for="card in cards" :key="card.label" class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
        <p class="text-sm text-gray-500">{{ card.label }}</p>
        <p class="mt-2 text-2xl font-medium text-gray-700">{{ card.value }}</p>
      </div>
    </div>

    <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
      <h3 class="mb-4 text-base font-medium text-gray-700">Últimas solicitudes</h3>
      <div class="space-y-3">
        <div
          v-for="s in recent"
          :key="s.id"
          class="flex items-center justify-between rounded-xl bg-gray-50 px-4 py-3"
        >
          <div>
            <p class="text-sm font-medium text-gray-700">{{ getTipoNombre(s.tipoBombonaId) }}</p>
            <p class="text-xs text-gray-500">{{ s.fecha }}</p>
          </div>
          <StatusBadge :status="s.estatus" />
        </div>
        <p v-if="!recent.length" class="text-sm text-gray-500">Sin solicitudes aún.</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import { useAuth } from '../../composables/useAuth.js'
import { useMockData } from '../../composables/useMockData.js'

const { currentUser } = useAuth()
const { solicitudes, getTipoNombre } = useMockData()

const mine = computed(() =>
  solicitudes.value.filter((s) => s.familiaId === currentUser.value?.entidadId)
)

const cards = computed(() => [
  { label: 'Total', value: mine.value.length },
  { label: 'Pendientes', value: mine.value.filter((s) => s.estatus === 'pendiente').length },
  { label: 'En proceso', value: mine.value.filter((s) => s.estatus === 'en_proceso').length },
  { label: 'Entregadas', value: mine.value.filter((s) => s.estatus === 'entregado').length },
])

const recent = computed(() => mine.value.slice(0, 5))
</script>
