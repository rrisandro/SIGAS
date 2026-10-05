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
import { computed, ref, onMounted } from 'vue'
import CrudDataTable from '../../components/ui/CrudDataTable.vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import ModalDialog from '../../components/ui/ModalDialog.vue'
import { usePedidos } from '../../composables/usePedidos'

const { pedidos, fetchPedidos, updateStatus } = usePedidos()

const showReject = ref(false)
const selected = ref(null)

const columns = [
  { key: 'id', label: '#' },
  { key: 'fecha', label: 'Fecha' },
  { key: 'familia', label: 'Familia' },
  { key: 'tipo', label: 'Tipo' },
  { key: 'estatus', label: 'Estatus' },
]

const rows = computed(() =>
  pedidos.value
    .filter((p) => p.status === 'pendiente')  // ✅ SOLO pendientes
    .map((p) => ({
      id: p.id_pedido,
      fecha: formatearFecha(p.fecha_solicitud),
      familia: p.familia?.nombre_familia || 'Sin familia',
      tipo: `Bombona ${p.tipo_bombona}`,
      estatus: p.status,
      _original: p
    }))
)

onMounted(() => {
  fetchPedidos()
})

function formatearFecha(fecha) {
  if (!fecha) return '-'
  return new Date(fecha).toLocaleDateString('es-VE')
}

async function aceptar(row) {
  await updateStatus(row._original.id_pedido, 'en_proceso')
}

function openReject(row) {
  selected.value = row
  showReject.value = true
}

async function confirmarRechazo() {
  if (!selected.value) return
  await updateStatus(selected.value._original.id_pedido, 'rechazado')
  selected.value = null
}
</script>