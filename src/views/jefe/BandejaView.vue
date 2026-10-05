<template>
  <div class="space-y-6">
    <div>
      <h2 class="text-xl font-medium text-gray-700">Bandeja de Solicitudes</h2>
      <p class="text-sm text-gray-500">Acepta o rechaza solicitudes de tu calle</p>
    </div>

    <!-- Indicador de carga -->
    <div v-if="loading" class="py-6 text-center text-gray-500">
      Cargando solicitudes de la comunidad...
    </div>

    <CrudDataTable
      v-else
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
        <span v-else-if="row.estatus === 'aceptado'" class="text-xs text-blue-600 font-medium">Aceptado</span>
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
const loading = ref(true)

const columns = [
  { key: 'id', label: '#' },
  { key: 'fecha', label: 'Fecha' },
  { key: 'familia', label: 'Familia' },
  { key: 'tipo', label: 'Tipo' },
  { key: 'estatus', label: 'Estatus' },
]

// Muestra únicamente los pedidos en estado "pendiente"
const rows = computed(() =>
  pedidos.value
    .filter((p) => p.status === 'pendiente')
    .map((p) => ({
      id: p.id_pedido,
      fecha: formatearFecha(p.fecha_solicitud || p.created_at),
      familia: p.familias?.nombre_familia || p.familia?.nombre_familia || 'Sin familia',
      tipo: `Bombona ${p.tipo_bombona}`,
      estatus: p.status,
      _original: p
    }))
)

onMounted(async () => {
  loading.value = true
  await fetchPedidos()
  loading.value = false
})

function formatearFecha(fecha) {
  if (!fecha) return '-'
  return new Date(fecha).toLocaleDateString('es-VE')
}

// Al presionar 'Aceptar', pasa de 'pendiente' a 'aceptado'
async function aceptar(row) {
  loading.value = true
  await updateStatus(row._original.id_pedido, 'aceptado')
  await fetchPedidos()
  loading.value = false
}

function openReject(row) {
  selected.value = row
  showReject.value = true
}

async function confirmarRechazo() {
  if (!selected.value) return
  loading.value = true
  await updateStatus(selected.value._original.id_pedido, 'rechazado')
  await fetchPedidos()
  selected.value = null
  loading.value = false
}
</script>