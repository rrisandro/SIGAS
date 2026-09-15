<template>
  <div class="space-y-6">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div>
        <h2 class="text-xl font-medium text-gray-700">Calles</h2>
        <p class="text-sm text-gray-500">CRUD de calles del sistema</p>
      </div>
      <BaseButton @click="openCreate">Nueva calle</BaseButton>
    </div>

    <CrudDataTable
      :columns="columns"
      :rows="rows"
      :search-keys="['nombre', 'sector']"
    >
      <template #cell-activo="{ row }">
        <div class="flex items-center gap-2">
          <ToggleSwitch :model-value="row.activo" @update:model-value="toggle(row)" />
          <StatusBadge :status="row.activo ? 'activo' : 'inactivo'" />
        </div>
      </template>
      <template #actions="{ row }">
        <BaseButton size="sm" variant="outline" @click="openEdit(row)">Editar</BaseButton>
      </template>
    </CrudDataTable>

    <Teleport to="body">
      <div v-if="showForm" class="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div class="absolute inset-0 bg-gray-700/30" @click="showForm = false" />
        <div class="relative w-full max-w-md rounded-2xl bg-white p-6 shadow-xl">
          <h3 class="text-lg font-medium text-gray-700">{{ editing ? 'Editar calle' : 'Nueva calle' }}</h3>
          <div class="mt-4 space-y-3">
            <BaseInput v-model="form.nombre" label="Nombre" required />
            <BaseInput v-model="form.sector" label="Sector" required />
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
import ToggleSwitch from '../../components/ui/ToggleSwitch.vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import { useAuth } from '../../composables/useAuth.js'
import { useMockData } from '../../composables/useMockData.js'

const { currentUser } = useAuth()
const { calles, addCalle, updateCalle, toggleActivo, addAuditoria } = useMockData()

const columns = [
  { key: 'id', label: '#' },
  { key: 'nombre', label: 'Nombre' },
  { key: 'sector', label: 'Sector' },
  { key: 'activo', label: 'Estado' },
]

const rows = computed(() => calles.value)
const showForm = ref(false)
const editing = ref(null)
const form = reactive({ nombre: '', sector: '' })

function openCreate() {
  editing.value = null
  form.nombre = ''
  form.sector = ''
  showForm.value = true
}

function openEdit(row) {
  editing.value = row
  form.nombre = row.nombre
  form.sector = row.sector
  showForm.value = true
}

function save() {
  if (!form.nombre || !form.sector) return
  if (editing.value) {
    updateCalle(editing.value.id, { nombre: form.nombre, sector: form.sector })
    addAuditoria({
      usuario: currentUser.value.username,
      accion: 'Modificar',
      entidad: 'Calle',
      detalle: `Calle actualizada: ${form.nombre}`,
    })
  } else {
    addCalle({ nombre: form.nombre, sector: form.sector })
    addAuditoria({
      usuario: currentUser.value.username,
      accion: 'Crear',
      entidad: 'Calle',
      detalle: `Calle creada: ${form.nombre}`,
    })
  }
  showForm.value = false
}

function toggle(row) {
  toggleActivo(calles, row.id)
  addAuditoria({
    usuario: currentUser.value.username,
    accion: row.activo ? 'Activar' : 'Desactivar',
    entidad: 'Calle',
    detalle: `${row.nombre} ${row.activo ? 'activada' : 'desactivada'}`,
  })
}
</script>
