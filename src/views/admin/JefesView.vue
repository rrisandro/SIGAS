<template>
  <div class="space-y-6">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div>
        <h2 class="text-xl font-medium text-gray-700">Jefes de Calle</h2>
        <p class="text-sm text-gray-500">CRUD de jefes asignados</p>
      </div>
      <BaseButton @click="openCreate">Nuevo jefe</BaseButton>
    </div>

    <CrudDataTable
      :columns="columns"
      :rows="rows"
      :search-keys="['nombre', 'cedula', 'calle', 'telefono']"
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
          <h3 class="text-lg font-medium text-gray-700">{{ editing ? 'Editar jefe' : 'Nuevo jefe' }}</h3>
          <div class="mt-4 space-y-3">
            <BaseInput v-model="form.nombre" label="Nombre" />
            <BaseInput v-model="form.cedula" label="Cédula" />
            <BaseInput v-model="form.telefono" label="Teléfono" />
            <BaseSelect v-model="form.calleId" label="Calle" :options="calleOptions" />
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
import BaseSelect from '../../components/ui/BaseSelect.vue'
import ToggleSwitch from '../../components/ui/ToggleSwitch.vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import { useAuth } from '../../composables/useAuth.js'
import { useMockData } from '../../composables/useMockData.js'

const { currentUser } = useAuth()
const { jefes, calles, addJefe, updateJefe, toggleActivo, addAuditoria, getCalleNombre } = useMockData()

const columns = [
  { key: 'id', label: '#' },
  { key: 'nombre', label: 'Nombre' },
  { key: 'cedula', label: 'Cédula' },
  { key: 'calle', label: 'Calle' },
  { key: 'telefono', label: 'Teléfono' },
  { key: 'activo', label: 'Estado' },
]

const rows = computed(() =>
  jefes.value.map((j) => ({ ...j, calle: getCalleNombre(j.calleId) }))
)

const calleOptions = computed(() =>
  calles.value.filter((c) => c.activo).map((c) => ({ value: c.id, label: c.nombre }))
)

const showForm = ref(false)
const editing = ref(null)
const form = reactive({ nombre: '', cedula: '', telefono: '', calleId: '' })

function openCreate() {
  editing.value = null
  Object.assign(form, { nombre: '', cedula: '', telefono: '', calleId: '' })
  showForm.value = true
}

function openEdit(row) {
  editing.value = row
  Object.assign(form, {
    nombre: row.nombre,
    cedula: row.cedula,
    telefono: row.telefono,
    calleId: row.calleId,
  })
  showForm.value = true
}

function save() {
  const payload = {
    nombre: form.nombre,
    cedula: form.cedula,
    telefono: form.telefono,
    calleId: Number(form.calleId),
  }
  if (editing.value) {
    updateJefe(editing.value.id, payload)
    addAuditoria({
      usuario: currentUser.value.username,
      accion: 'Modificar',
      entidad: 'Jefe de Calle',
      detalle: `Actualizado: ${form.nombre}`,
    })
  } else {
    addJefe(payload)
    addAuditoria({
      usuario: currentUser.value.username,
      accion: 'Crear',
      entidad: 'Jefe de Calle',
      detalle: `Creado: ${form.nombre}`,
    })
  }
  showForm.value = false
}

function toggle(row) {
  toggleActivo(jefes, row.id)
  addAuditoria({
    usuario: currentUser.value.username,
    accion: row.activo ? 'Activar' : 'Desactivar',
    entidad: 'Jefe de Calle',
    detalle: row.nombre,
  })
}
</script>
