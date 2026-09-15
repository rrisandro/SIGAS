<template>
  <div class="space-y-6">
    <div>
      <h2 class="text-xl font-medium text-gray-700">Dashboard</h2>
      <p class="text-sm text-gray-500">Métricas de {{ calleNombre }}</p>
    </div>

    <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
      <div v-for="card in cards" :key="card.label" class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
        <p class="text-sm text-gray-500">{{ card.label }}</p>
        <p class="mt-2 text-2xl font-medium text-gray-700">{{ card.value }}</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useAuth } from '../../composables/useAuth.js'
import { useMockData } from '../../composables/useMockData.js'

const { currentUser } = useAuth()
const { jefes, familias, solicitudes, findById, getCalleNombre } = useMockData()

const jefe = computed(() => findById(jefes, currentUser.value?.entidadId))
const calleId = computed(() => jefe.value?.calleId)
const calleNombre = computed(() => getCalleNombre(calleId.value) || 'tu calle')

const familiasCalle = computed(() =>
  familias.value.filter((f) => f.calleId === calleId.value && f.activo)
)

const solicitudesCalle = computed(() => {
  const ids = new Set(familiasCalle.value.map((f) => f.id))
  return solicitudes.value.filter((s) => ids.has(s.familiaId))
})

const cards = computed(() => [
  { label: 'Familias activas', value: familiasCalle.value.length },
  { label: 'Pendientes', value: solicitudesCalle.value.filter((s) => s.estatus === 'pendiente').length },
  { label: 'En proceso', value: solicitudesCalle.value.filter((s) => s.estatus === 'en_proceso').length },
  { label: 'Entregadas', value: solicitudesCalle.value.filter((s) => s.estatus === 'entregado').length },
])
</script>
