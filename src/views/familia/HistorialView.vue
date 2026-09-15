<template>
  <div class="space-y-6">
    <div>
      <h2 class="text-xl font-medium text-gray-700">Mi Historial</h2>
      <p class="text-sm text-gray-500">Todas tus solicitudes registradas</p>
    </div>

    <CrudDataTable
      title="Solicitudes"
      :columns="columns"
      :rows="rows"
      :search-keys="['tipo', 'pico', 'fecha', 'estatus']"
    >
      <template #cell-estatus="{ row }">
        <StatusBadge :status="row.estatus" />
      </template>
    </CrudDataTable>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import CrudDataTable from '../../components/ui/CrudDataTable.vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import { useAuth } from '../../composables/useAuth.js'
import { useMockData } from '../../composables/useMockData.js'

const { currentUser } = useAuth()
const { solicitudes, getTipoNombre, getPicoNombre } = useMockData()

const columns = [
  { key: 'id', label: '#' },
  { key: 'fecha', label: 'Fecha' },
  { key: 'tipo', label: 'Tipo' },
  { key: 'pico', label: 'Pico' },
  { key: 'estatus', label: 'Estatus' },
  { key: 'observaciones', label: 'Observaciones' },
]

const rows = computed(() =>
  solicitudes.value
    .filter((s) => s.familiaId === currentUser.value?.entidadId)
    .map((s) => ({
      ...s,
      tipo: getTipoNombre(s.tipoBombonaId),
      pico: getPicoNombre(s.picoId),
    }))
)
</script>
