<template>
  <div class="space-y-6">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div>
        <h2 class="text-xl font-medium text-gray-700">Usuarios</h2>
        <p class="text-sm text-gray-500">CRUD de cuentas de acceso</p>
      </div>
      <BaseButton @click="openCreate">Nuevo usuario</BaseButton>
    </div>

    <CrudDataTable
      :columns="columns"
      :rows="rows"
      :search-keys="['username', 'nombre', 'rol']"
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
          <h3 class="text-lg font-medium text-gray-700">{{ editing ? 'Editar usuario' : 'Nuevo usuario' }}</h3>
          <div class="mt-4 space-y-3">
            <BaseInput v-model="form.nombre" label="Nombre" />
            <BaseInput v-model="form.username" label="Usuario" />
            <BaseInput v-model="form.password" label="Contraseña" type="password" />
            <BaseSelect
              v-model="form.rol"
              label="Rol"
              value-type="string"
              :options="rolOptions"
            />
            <BaseInput
              v-if="form.rol !== 'admin'"
              v-model="form.entidadId"
              label="ID entidad (jefe/familia)"
              type="number"
            />
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
const { usuarios, addUsuario, updateUsuario, toggleActivo, addAuditoria } = useMockData()

const columns = [
  { key: 'id', label: '#' },
  { key: 'nombre', label: 'Nombre' },
  { key: 'username', label: 'Usuario' },
  { key: 'rol', label: 'Rol' },
  { key: 'activo', label: 'Estado' },
]

const rows = computed(() => usuarios.value)
const rolOptions = [
  { value: 'admin', label: 'Administrador' },
  { value: 'jefe', label: 'Jefe de calle' },
  { value: 'familia', label: 'Familia' },
]

const showForm = ref(false)
const editing = ref(null)
const form = reactive({
  nombre: '',
  username: '',
  password: '',
  rol: 'familia',
  entidadId: '',
})

function openCreate() {
  editing.value = null
  Object.assign(form, { nombre: '', username: '', password: '', rol: 'familia', entidadId: '' })
  showForm.value = true
}

function openEdit(row) {
  editing.value = row
  Object.assign(form, {
    nombre: row.nombre,
    username: row.username,
    password: row.password,
    rol: row.rol,
    entidadId: row.entidadId || '',
  })
  showForm.value = true
}

function save() {
  const payload = {
    nombre: form.nombre,
    username: form.username,
    password: form.password,
    rol: form.rol,
    entidadId: form.rol === 'admin' ? undefined : Number(form.entidadId) || null,
  }
  if (editing.value) {
    updateUsuario(editing.value.id, payload)
    addAuditoria({
      usuario: currentUser.value.username,
      accion: 'Modificar',
      entidad: 'Usuario',
      detalle: form.username,
    })
  } else {
    addUsuario(payload)
    addAuditoria({
      usuario: currentUser.value.username,
      accion: 'Crear',
      entidad: 'Usuario',
      detalle: form.username,
    })
  }
  showForm.value = false
}

function toggle(row) {
  toggleActivo(usuarios, row.id)
  addAuditoria({
    usuario: currentUser.value.username,
    accion: row.activo ? 'Activar' : 'Desactivar',
    entidad: 'Usuario',
    detalle: row.username,
  })
}
</script>
