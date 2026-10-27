<template>
  <div class="page space-y-6 audit-page">
    <div class="audit-header">
      <div class="page-heading">
        <h2 class="page-title">Auditoría</h2>
        <p class="page-subtitle">Registro de acciones del sistema</p>
      </div>
      <div class="audit-actions">
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

<style scoped>
.audit-header {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.audit-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.audit-actions :deep(.btn-custom) {
  width: 100%;
}

@media (min-width: 480px) {
  .audit-actions {
    flex-direction: row;
    flex-wrap: wrap;
  }

  .audit-actions :deep(.btn-custom) {
    width: auto;
  }
}

@media (min-width: 640px) {
  .audit-header {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
  }
}
</style>
