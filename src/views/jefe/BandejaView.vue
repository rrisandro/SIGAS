<template>
  <div class="space-y-6">
    <div>
      <h2 class="text-xl font-medium text-gray-700">Bandeja de Solicitudes</h2>
      <p class="text-sm text-gray-500">Acepta o rechaza solicitudes de tu calle</p>
    </div>

    <CrudDataTable
      title="Pendientes y en proceso"
      :columns="columns"
      :rows="rows"
      :search-keys="['familia', 'tipo', 'fecha']"
    >
      <template #cell-estatus="{ row }">
        <StatusBadge :status="row.estatus" />
      </template>
      <template #actions="{ row }">
        <template v-if="row.estatus === 'pendiente'">
          <BaseButton size="sm" variant="success" @click="aceptar(row)">Aceptar</BaseButton>
          <BaseButton size="sm" variant="danger" @click="openReject(row)">Rechazar</BaseButton>
        </template>
        <span v-else class="text-xs text-gray-500">Sin acción</span>
      </template>
    </CrudDataTable>

    <ModalDialog
      v-model="showReject"
      title="Rechazar solicitud"
      message="Indica el motivo del rechazo. Esta acción actualizará el estatus."
      confirm-text="Rechazar"
      confirm-variant="danger"
      @confirm="confirmarRechazo"
    />
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import CrudDataTable from '../../components/ui/CrudDataTable.vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import ModalDialog from '../../components/ui/ModalDialog.vue'
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

const showReject = ref(false)
const selected = ref(null)

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
    .filter((s) => familiaIds.value.has(s.familiaId) && ['pendiente', 'en_proceso'].includes(s.estatus))
    .map((s) => ({
      ...s,
      familia: getFamiliaNombre(s.familiaId),
      tipo: getTipoNombre(s.tipoBombonaId),
    }))
)

function aceptar(row) {
  updateSolicitudEstatus(row.id, 'en_proceso', 'Aprobada por jefe de calle')
  addAuditoria({
    usuario: currentUser.value.username,
    accion: 'Aprobar',
    entidad: `Solicitud #${row.id}`,
    detalle: `Solicitud de ${row.familia} aprobada`,
  })
}

function openReject(row) {
  selected.value = row
  showReject.value = true
}

function confirmarRechazo() {
  if (!selected.value) return
  updateSolicitudEstatus(selected.value.id, 'rechazado', 'Rechazada por jefe de calle')
  addAuditoria({
    usuario: currentUser.value.username,
    accion: 'Rechazar',
    entidad: `Solicitud #${selected.value.id}`,
    detalle: `Solicitud de ${selected.value.familia} rechazada`,
  })
  selected.value = null
}
</script>
