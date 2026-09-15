<template>
  <div class="space-y-6">
    <div class="flex flex-wrap items-center justify-between gap-3">
      <div>
        <h2 class="text-xl font-medium text-gray-700">Auditoría</h2>
        <p class="text-sm text-gray-500">Registro de acciones del sistema</p>
      </div>
      <div class="flex gap-2">
        <BaseButton variant="outline" @click="download('csv')">Descargar CSV</BaseButton>
        <BaseButton variant="outline" @click="download('json')">Descargar JSON</BaseButton>
      </div>
    </div>

    <CrudDataTable
      :columns="columns"
      :rows="rows"
      :search-keys="['usuario', 'accion', 'entidad', 'detalle']"
      :page-size="10"
    />
  </div>
</template>

<script setup>
import { computed } from 'vue'
import CrudDataTable from '../../components/ui/CrudDataTable.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import { useAuth } from '../../composables/useAuth.js'
import { useMockData } from '../../composables/useMockData.js'

const { currentUser } = useAuth()
const { auditoriaLogs, addAuditoria } = useMockData()

const columns = [
  { key: 'fecha', label: 'Fecha' },
  { key: 'usuario', label: 'Usuario' },
  { key: 'accion', label: 'Acción' },
  { key: 'entidad', label: 'Entidad' },
  { key: 'detalle', label: 'Detalle' },
  { key: 'ip', label: 'IP' },
]

const rows = computed(() => auditoriaLogs.value)

function download(format) {
  const data = auditoriaLogs.value
  let content
  let mime
  let filename

  if (format === 'json') {
    content = JSON.stringify(data, null, 2)
    mime = 'application/json'
    filename = 'auditoria.json'
  } else {
    const headers = ['fecha', 'usuario', 'accion', 'entidad', 'detalle', 'ip']
    const lines = [headers.join(',')]
    data.forEach((row) => {
      lines.push(headers.map((h) => `"${String(row[h] ?? '').replace(/"/g, '""')}"`).join(','))
    })
    content = lines.join('\n')
    mime = 'text/csv'
    filename = 'auditoria.csv'
  }

  const blob = new Blob([content], { type: mime })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  a.click()
  URL.revokeObjectURL(url)

  addAuditoria({
    usuario: currentUser.value.username,
    accion: 'Exportar',
    entidad: 'Reporte',
    detalle: `Auditoría exportada (${format.toUpperCase()})`,
  })
}
</script>
