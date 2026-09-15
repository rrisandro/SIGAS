<template>
  <div class="space-y-6">
    <div>
      <h2 class="text-xl font-medium text-gray-700">Control de Entregas</h2>
      <p class="text-sm text-gray-500">Marca como entregadas las solicitudes en proceso</p>
    </div>

    <CrudDataTable
      title="En ruta / en proceso"
      :columns="columns"
      :rows="rows"
      :search-keys="['familia', 'tipo', 'fecha']"
    >
      <template #cell-estatus="{ row }">
        <StatusBadge :status="row.estatus" />
      </template>
      <template #actions="{ row }">
        <BaseButton size="sm" variant="success" @click="entregar(row)">Marcar entregado</BaseButton>
      </template>
    </CrudDataTable>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import CrudDataTable from '../../components/ui/CrudDataTable.vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import { useAuth } from '../../composables/useAuth.js'
import { useMockData } from '../../composables/useMockData.js'

const { currentUser } = useAuth()
const {
  jefes,
  familias,
  solicitudes,
  findById,
  getFamiliaNombre,
  getTipoNombre,
  updateSolicitudEstatus,
  addAuditoria,
} = useMockData()

const jefe = computed(() => findById(jefes, currentUser.value?.entidadId))
const familiaIds = computed(() => {
  const calleId = jefe.value?.calleId
  return new Set(familias.value.filter((f) => f.calleId === calleId).map((f) => f.id))
})

const columns = [
  { key: 'id', label: '#' },
  { key: 'fecha', label: 'Fecha' },
  { key: 'familia', label: 'Familia' },
  { key: 'tipo', label: 'Tipo' },
  { key: 'estatus', label: 'Estatus' },
]

const rows = computed(() =>
  solicitudes.value
    .filter((s) => familiaIds.value.has(s.familiaId) && s.estatus === 'en_proceso')
    .map((s) => ({
      ...s,
      familia: getFamiliaNombre(s.familiaId),
      tipo: getTipoNombre(s.tipoBombonaId),
    }))
)

function entregar(row) {
  updateSolicitudEstatus(row.id, 'entregado', 'Entregada correctamente')
  addAuditoria({
    usuario: currentUser.value.username,
    accion: 'Entregar',
    entidad: `Solicitud #${row.id}`,
    detalle: `Entrega a ${row.familia}`,
  })
}
</script>
