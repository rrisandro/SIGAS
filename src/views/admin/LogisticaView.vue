<template>
  <div class="space-y-6">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div>
        <h2 class="text-xl font-medium text-gray-700">Logística</h2>
        <p class="text-sm text-gray-500">Ciclos de distribución</p>
      </div>
      <BaseButton @click="openCreate">Nuevo ciclo</BaseButton>
    </div>

    <CrudDataTable
      :columns="columns"
      :rows="rows"
      :search-keys="['nombre', 'estado']"
    >
      <template #cell-estado="{ row }">
        <StatusBadge :status="row.estado" />
      </template>
      <template #actions="{ row }">
        <BaseButton
          v-if="row.estado === 'planificado'"
          size="sm"
          variant="success"
          @click="startCiclo(row)"
        >
          Iniciar
        </BaseButton>
        <BaseButton
          v-else-if="row.estado === 'en_progreso'"
          size="sm"
          variant="warning"
          @click="completeCiclo(row)"
        >
          Completar
        </BaseButton>
        <span v-else class="text-xs text-gray-500">Cerrado</span>
      </template>
    </CrudDataTable>

    <Teleport to="body">
      <div v-if="showForm" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-gray-700/30" @click="showForm = false" />
        <div class="relative w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">
          <h3 class="text-lg font-medium text-gray-700">Nuevo ciclo</h3>
          <div class="mt-4 space-y-3">
            <BaseInput v-model="form.nombre" label="Nombre" />
            <BaseInput v-model="form.fechaInicio" label="Fecha inicio" type="date" />
            <BaseInput v-model="form.fechaFin" label="Fecha fin" type="date" />
          </div>
          <div class="mt-6 flex justify-end gap-2">
            <BaseButton variant="ghost" @click="showForm = false">Cancelar</BaseButton>
            <BaseButton @click="save">Guardar</BaseButton>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { computed, reactive, ref } from 'vue'
import CrudDataTable from '../../components/ui/CrudDataTable.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import { useAuth } from '../../composables/useAuth.js'
import { useMockData } from '../../composables/useMockData.js'

const { currentUser } = useAuth()
const { ciclosDistribucion, addCiclo, updateCiclo, addAuditoria } = useMockData()

const columns = [
  { key: 'id', label: '#' },
  { key: 'nombre', label: 'Ciclo' },
  { key: 'fechaInicio', label: 'Inicio' },
  { key: 'fechaFin', label: 'Fin' },
  { key: 'totalEntregas', label: 'Entregas' },
  { key: 'totalPendientes', label: 'Pendientes' },
  { key: 'estado', label: 'Estado' },
]

const rows = computed(() => ciclosDistribucion.value)
const showForm = ref(false)
const form = reactive({ nombre: '', fechaInicio: '', fechaFin: '' })

function openCreate() {
  Object.assign(form, { nombre: '', fechaInicio: '', fechaFin: '' })
  showForm.value = true
}

function save() {
  if (!form.nombre) return
  addCiclo({ ...form })
  addAuditoria({
    usuario: currentUser.value.username,
    accion: 'Crear',
    entidad: 'Ciclo de Distribución',
    detalle: form.nombre,
  })
  showForm.value = false
}

function startCiclo(row) {
  updateCiclo(row.id, { estado: 'en_progreso' })
  addAuditoria({
    usuario: currentUser.value.username,
    accion: 'Iniciar',
    entidad: 'Ciclo',
    detalle: row.nombre,
  })
}

function completeCiclo(row) {
  updateCiclo(row.id, { estado: 'completado', totalPendientes: 0 })
  addAuditoria({
    usuario: currentUser.value.username,
    accion: 'Completar',
    entidad: 'Ciclo',
    detalle: row.nombre,
  })
}
</script>
