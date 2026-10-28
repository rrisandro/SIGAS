<template>
  <div class="page space-y-6 historico-page">
    <!-- CABECERA PRINCIPAL (Oculta en la impresión) -->
    <div class="historico-header print:hidden">
      <div class="page-heading">
        <h2 class="page-title">Histórico y Auditoría de Ciclos</h2>
        <p class="page-subtitle">Trazabilidad y reportes de las jornadas de distribución de gas</p>
      </div>
      <div class="audit-actions print:hidden">
        <BaseButton variant="outline" :disabled="cargando" @click="cargarHistorico">
          {{ cargando ? 'Actualizando...' : 'Actualizar' }}
        </BaseButton>
        <BaseButton variant="outline" :disabled="!rowsHistorico.length" @click="download('csv')">
          Descargar CSV
        </BaseButton>
        <BaseButton variant="outline" :disabled="!rowsHistorico.length" @click="download('json')">
          Descargar JSON
        </BaseButton>
      </div>
      <BaseButton size="sm" variant="ghost" @click="cargarHistorico">
        🔄 Actualizar Datos
      </BaseButton>
    </div>

    <!-- Indicador de Carga -->
    <div v-if="cargando" class="py-8 text-center text-gray-500 print:hidden">
      Cargando historial de jornadas...
    </div>

    <div v-else class="space-y-6 print:hidden">
      <!-- Tarjetas Resumen Global -->
      <div class="history-metrics">
        <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm space-y-1">
          <p class="text-xs font-semibold text-gray-400 uppercase">Total Ciclos Realizados</p>
          <p class="text-2xl font-bold text-gray-800">{{ listaHistorico.length }}</p>
        </div>
        <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm space-y-1">
          <p class="text-xs font-semibold text-gray-400 uppercase">Bombonas Despachadas</p>
          <p class="text-2xl font-bold text-green-600">{{ totalBombonasEntregadasGlobal }}</p>
        </div>
        <div class="bg-white p-5 rounded-xl border border-gray-200 shadow-sm space-y-1">
          <p class="text-xs font-semibold text-gray-400 uppercase">Efectividad General</p>
          <p class="text-2xl font-bold text-blue-600">{{ porcentajeEfectividad }}%</p>
        </div>
      </div>

      <!-- Tabla Consolidada por Ciclo -->
      <CrudDataTable
        title="Consolidado de Ciclos de Distribución"
        :columns="columnsHistorico"
        :rows="rowsHistorico"
        :search-keys="['nombre', 'calle', 'estado']"
      >
        <template #cell-estado="{ row }">
          <StatusBadge :status="row.estado" />
        </template>
        <template #actions="{ row }">
          <BaseButton size="sm" variant="ghost" @click="verDetalleCiclo(row._original)">
           Ver Detalle
          </BaseButton>
        </template>
      </CrudDataTable>
    </div>

    <!-- MODAL DETALLE DEL CICLO (Con vista previa de la tabla) -->
    <Teleport to="body">
      <div v-if="cicloSeleccionado" class="historico-modal print:hidden">
        <div class="historico-modal__backdrop" @click="cicloSeleccionado = null" />
        <div class="historico-modal__panel" role="dialog" aria-modal="true" aria-label="Detalle del ciclo">
          <span class="historico-modal__handle" aria-hidden="true"></span>
          
          <div class="historico-modal__header">
            <div>
              <h3>{{ cicloSeleccionado.nombre_ciclo }}</h3>
              <p>Sector: {{ cicloSeleccionado.calles?.nombre || 'General (Comunidad Completa)' }}</p>
            </div>
            <button class="historico-modal__close" aria-label="Cerrar detalle" @click="cicloSeleccionado = null">✕</button>
          </div>

          <div class="historico-modal__body">
            <div class="history-detail-grid">
              <div class="history-detail-card">
                <span>Pedidos Solicitados</span>
                <span class="history-detail-value">{{ cicloSeleccionado.totalSolicitudes }}</span>
              </div>
              <div class="history-detail-card history-detail-card--green">
                <span>Entregados con Éxito</span>
                <span class="history-detail-value">{{ cicloSeleccionado.totalEntregados }}</span>
              </div>
            </div>

            <!-- VISTA PREVIA DE LA TABLA EXCEL -->
            <div class="mt-4">
              <h4 class="history-detail-title">Vista Previa de la Planilla:</h4>
              <div class="table-responsive">
                <table class="sheet-table">
                  <thead>
                    <tr>
                      <th style="width: 15%">FECHA</th>
                      <th style="width: 45%">CONCEPTO / FAMILIA</th>
                      <th style="width: 15%">BOMBONA</th>
                      <th style="width: 10%">PICO</th>
                      <th style="width: 15%">ESTATUS</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="pedido in cicloSeleccionado.pedidos" :key="pedido.id_pedido">
                      <td class="text-center">{{ formatearFecha(cicloSeleccionado.fecha_inicio) }}</td>
                      <td>{{ pedido.familias?.nombre_familia || 'Familia No Asignada' }}</td>
                      <td class="text-center">{{ pedido.tipo_bombona || '-' }}</td>
                      <td class="text-center">{{ pedido.pico || '-' }}</td>
                      <td class="text-center uppercase">{{ pedido.status }}</td>
                    </tr>
                    <tr v-for="n in Math.max(0, 3 - (cicloSeleccionado.pedidos?.length || 0))" :key="'blank-' + n">
                      <td>&nbsp;</td>
                      <td>&nbsp;</td>
                      <td>&nbsp;</td>
                      <td>&nbsp;</td>
                      <td>&nbsp;</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              
              <div style="display: flex; justify-content: space-around; margin-top: 30px; padding-bottom: 10px;">
                <div style="text-align: center; width: 35%;">
                  <div style="border-top: 1px solid #000; margin-bottom: 8px;"></div>
                  <p style="font-size: 11px; font-weight: bold; color: #000;">Firma Jefe de Calle</p>
                </div>
                <div style="text-align: center; width: 35%;">
                  <div style="border-top: 1px solid #000; margin-bottom: 8px;"></div>
                  <p style="font-size: 11px; font-weight: bold; color: #000;">Firma Jefe Comunal</p>
                </div>
              </div>
            </div>
          </div>

          <div class="historico-modal__actions">
            <BaseButton variant="ghost" @click="cicloSeleccionado = null">Cerrar</BaseButton>
            <BaseButton variant="success" @click="imprimirReporte">
              🖨 Imprimir Planilla
            </BaseButton>
          </div>
        </div>
      </div>
    </Teleport>

    <!-- HOJA IMPRIMIBLE (Oculta en pantalla) -->
    <Teleport to="body">
      <div v-if="cicloSeleccionado" class="printable-sheet">
        <div class="sheet-container">
          
          <div class="sheet-logo-container">
            <!-- ⚠️ RECUERDA CAMBIAR ESTA RUTA POR LA DE TU LOGO -->
            <img src="../../../SIGAS-removebg-preview.jpeg" alt="Logo SIGAS" class="sheet-logo" />
          </div>

          <h1 class="sheet-title">Registro de Distribución</h1>
          
          <p class="sheet-subtitle">
            <strong>Ciclo:</strong> {{ cicloSeleccionado.nombre_ciclo }} | 
            <strong>Sector:</strong> {{ cicloSeleccionado.calles?.nombre || 'Comunidad General' }} | 
            <strong>Fechas:</strong> {{ formatearFecha(cicloSeleccionado.fecha_inicio) }} al {{ formatearFecha(cicloSeleccionado.fecha_cierre) }}
          </p>

          <table class="sheet-table">
            <thead>
              <tr>
                <th style="width: 15%">FECHA</th>
                <th style="width: 45%">CONCEPTO / FAMILIA</th>
                <th style="width: 15%">BOMBONA</th>
                <th style="width: 10%">PICO</th>
                <th style="width: 15%">ESTATUS</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="pedido in cicloSeleccionado.pedidos" :key="pedido.id_pedido">
                <td class="text-center">{{ formatearFecha(cicloSeleccionado.fecha_inicio) }}</td>
                <td>{{ pedido.familias?.nombre_familia || 'Familia No Asignada' }}</td>
                <td class="text-center">{{ pedido.tipo_bombona || '-' }}</td>
                <td class="text-center">{{ pedido.pico || '-' }}</td>
                <td class="text-center uppercase">{{ pedido.status }}</td>
              </tr>
              <!-- REDUCIDO A 12 FILAS PARA NO DESBORDAR LA HOJA -->
              <tr v-for="n in Math.max(0, 12 - (cicloSeleccionado.pedidos?.length || 0))" :key="'blank-' + n">
                <td>&nbsp;</td>
                <td>&nbsp;</td>
                <td>&nbsp;</td>
                <td>&nbsp;</td>
                <td>&nbsp;</td>
              </tr>
            </tbody>
          </table>

          <div class="sheet-summary">
            <span><strong>Total Solicitudes:</strong> {{ cicloSeleccionado.totalSolicitudes }}</span>
            <span><strong>Total Entregados:</strong> {{ cicloSeleccionado.totalEntregados }}</span>
          </div>

          <div class="sheet-signatures">
            <div class="signature-box">
              <div class="line"></div>
              <p><strong>Firma Jefe de Calle</strong></p>
            </div>
            <div class="signature-box">
              <div class="line"></div>
              <p><strong>Firma Jefe Comunal</strong></p>
            </div>
          </div>

        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import CrudDataTable from '../../components/ui/CrudDataTable.vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import { supabase } from '../../lib/supabase'

const cargando = ref(true)
const error = ref('')
const listaHistorico = ref([])
const cicloSeleccionado = ref(null)

const columnsHistorico = [
  { key: 'id', label: '#' },
  { key: 'nombre', label: 'Ciclo / Jornada' },
  { key: 'calle', label: 'Calle / Sector' },
  { key: 'entregados', label: 'Bombonas Entregadas' },
  { key: 'fecha', label: 'Fecha Inicio' },
  { key: 'estado', label: 'Estado' },
]

const totalBombonasEntregadasGlobal = computed(() => {
  return listaHistorico.value.reduce((acc, c) => acc + (c.totalEntregados || 0), 0)
})

const porcentajeEfectividad = computed(() => {
  const totalSolicitados = listaHistorico.value.reduce((acc, c) => acc + (c.totalSolicitudes || 0), 0)
  if (!totalSolicitados) return 0
  return Math.round((totalBombonasEntregadasGlobal.value / totalSolicitados) * 100)
})

const rowsHistorico = computed(() => {
  return listaHistorico.value.map((c) => ({
    id: c.id_ciclo,
    nombre: c.nombre_ciclo,
    calle: c.calles?.nombre || 'Comunidad General',
    entregados: `${c.totalEntregados} / ${c.totalSolicitudes}`,
    fecha: c.fecha_inicio ? formatearFecha(c.fecha_inicio) : '-',
    estado: c.estado,
    _original: c
  }))
})

function formatearFecha(fecha) {
  if (!fecha) return 'S/F'
  return new Date(fecha).toLocaleDateString('es-VE')
}

async function cargarHistorico() {
  cargando.value = true
  error.value = ''

  try {
    const { data: ciclosData, error: queryError } = await supabase
      .from('ciclos_distribucion')
      .select(`
        *,
        calles (id_calle, nombre),
        pedidos (
          id_pedido,
          tipo_bombona,
          pico,
          status,
          familias (
            id,
            nombre_familia
          )
        )
      `)
      .order('id_ciclo', { ascending: false })

    if (queryError) throw queryError

    if (ciclosData) {
      listaHistorico.value = ciclosData.map((c) => {
        const pedidosList = c.pedidos || []
        const entregados = pedidosList.filter(p => p.status === 'entregado')

        const desglose = {}
        entregados.forEach(p => {
          const t = p.tipo_bombona || 'General'
          desglose[t] = (desglose[t] || 0) + 1
        })

        return {
          ...c,
          totalSolicitudes: pedidosList.length,
          totalEntregados: entregados.length,
          desgloseBombonas: desglose
        }
      })
    }
  } catch (err) {
    console.error('[SIGAS] Error cargando histórico:', err)
    error.value = `No se pudo cargar el historial: ${err?.message || 'error desconocido'}`
  } finally {
    cargando.value = false
  }
}

function download(format) {
  const data = rowsHistorico.value.map(({ _original, ...row }) => row)
  let content
  let mime
  let filename

  if (format === 'json') {
    content = JSON.stringify(data, null, 2)
    mime = 'application/json'
    filename = 'auditoria-ciclos.json'
  } else {
    const headers = ['nombre', 'calle', 'entregados', 'fecha', 'estado']
    const lines = [headers.join(',')]
    data.forEach((row) => {
      lines.push(headers.map((h) => `"${String(row[h] ?? '').replace(/"/g, '""')}"`).join(','))
    })
    content = lines.join('\n')
    mime = 'text/csv;charset=utf-8'
    filename = 'auditoria-ciclos.csv'
  }

  const blob = new Blob([content], { type: mime })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  link.click()
  URL.revokeObjectURL(url)
}

function verDetalleCiclo(ciclo) {
  cicloSeleccionado.value = ciclo
}

function imprimirReporte() {
  window.print()
}

onMounted(() => {
  cargarAuditoria()
})
</script>

<style scoped>
/* ==========================================
   ESTILOS DE PANTALLA (UI)
   ========================================== */
.historico-page {
  display: flex;
  flex-direction: column;
}

.historico-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
}

.history-metrics {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 12px;
}

.history-metrics > div {
  min-width: 0;
  padding: 16px !important;
}

/* Modal UI */
.historico-modal {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

.historico-modal__backdrop {
  position: absolute;
  inset: 0;
  background: rgba(15, 23, 42, 0.52);
  backdrop-filter: blur(3px);
  -webkit-backdrop-filter: blur(3px);
}

.historico-modal__panel {
  position: relative;
  z-index: 1;
  width: 100%;
  max-height: 90dvh;
  padding: 12px 16px calc(18px + var(--safe-bottom));
  overflow-y: auto;
  background: #ffffff;
  border-radius: 22px 22px 0 0;
  box-shadow: 0 -12px 40px rgba(15, 23, 42, 0.2);
  animation: historySheetUp 0.22s ease-out;
}

.historico-modal__handle {
  display: block;
  width: 40px;
  height: 4px;
  margin: 0 auto 14px;
  border-radius: 999px;
  background: #e2e8f0;
}

.historico-modal__header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
}

.historico-modal__header h3 {
  color: var(--color-heading);
  font-size: 1.05rem;
  font-weight: 700;
}

.historico-modal__header p {
  margin-top: 3px;
  color: var(--color-muted);
  font-size: 0.78rem;
}

.historico-modal__close {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 44px;
  height: 44px;
  border: 0;
  border-radius: 10px;
  background: transparent;
  color: var(--color-muted);
  font-size: 1.1rem;
  cursor: pointer;
}

.historico-modal__body {
  display: flex;
  flex-direction: column;
  gap: 16px;
  margin-top: 14px;
  padding-top: 14px;
  border-top: 1px solid var(--color-border);
}

.history-detail-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
}

.history-detail-card {
  display: flex;
  flex-direction: column;
  gap: 3px;
  padding: 12px;
  background: var(--color-bg);
  border-radius: 10px;
}

.audit-alert {
  padding: 12px 14px;
  border: 1px solid #fecaca;
  border-radius: 10px;
  background: #fef2f2;
  color: #991b1b;
  font-size: 14px;
  margin-bottom: 1rem;
}

.history-detail-card > span:first-child {
  color: var(--color-muted);
  font-size: 0.7rem;
}

.history-detail-value {
  color: var(--color-heading);
  font-size: 1.3rem;
  font-weight: 700;
}

.history-detail-card--green {
  background: #f0fdf4;
}

.history-detail-card--green > span:first-child {
  color: #15803d;
}

.history-detail-card--green .history-detail-value {
  color: #166534;
}

.history-detail-title {
  margin-bottom: 8px;
  color: var(--color-muted);
  font-size: 0.72rem;
  font-weight: 600;
  text-transform: uppercase;
}

.historico-modal__actions {
  display: flex;
  gap: 10px;
  margin-top: 20px;
  padding-top: 14px;
  border-top: 1px solid var(--color-border);
  justify-content: flex-end;
}

/* Estilos de la tabla en pantalla */
.table-responsive {
  overflow-x: auto;
  border: 1px solid #e2e8f0;
  border-radius: 8px;
}

.table-responsive .sheet-table {
  min-width: 600px;
}

/* Ajustes para pantallas grandes */
@media (min-width: 640px) {
  .historico-modal {
    align-items: center;
    padding: 20px;
  }

  .historico-modal__panel {
    max-width: 800px;
    max-height: 90vh;
    padding: 24px;
    border-radius: 16px;
  }

  .historico-modal__handle {
    display: none;
  }

  .audit-metrics {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }
}

/* Estilos base de la tabla (pantalla e impresión) */
.sheet-table {
  width: 100%;
  border-collapse: collapse;
  font-family: Arial, sans-serif;
}

.sheet-table th, 
.sheet-table td {
  border: 1px solid #cbd5e1;
  padding: 6px 8px;
  font-size: 11px;
  color: #000000;
}

.sheet-table th {
  background-color: #e0f2fe; /* Azul del sistema */
  font-weight: bold;
  text-align: center;
  text-transform: uppercase;
  font-size: 10px;
  padding: 8px;
}

/* ==========================================
   OCULTAR LA PLANILLA EN PANTALLA
   ========================================== */
@media screen {
  .printable-sheet {
    display: none !important;
  }
}

/* ==========================================
   REGLAS EXCLUSIVAS DE IMPRESIÓN (MEDIOS PRINT)
   ========================================== */
@media print {
  /* 1. Configuración de la página */
  @page {
    margin: 0;
    size: letter portrait;
  }

  /* 2. ELIMINAR TODO EL CONTENIDO DEL BODY EXCEPTO LA PLANILLA */
  /* Esto destruye el menú, los modales y previene cualquier página extra */
  body > *:not(.printable-sheet) {
    display: none !important;
  }

  /* 3. Forzar al body a medir exactamente una hoja para que no se duplique */
  html, body {
    height: 100vh !important;
    max-height: 100vh !important;
    overflow: hidden !important;
    margin: 0 !important;
    padding: 0 !important;
    background: #ffffff !important;
  }

  /* 4. Mostrar la planilla ocupando toda la hoja */
  .printable-sheet {
    display: block !important;
    position: absolute !important;
    left: 0 !important;
    top: 0 !important;
    width: 100% !important;
    height: 100vh !important;
    background: #ffffff !important;
    z-index: 99999;
  }

  /* 5. Contenedor con márgenes internos para que no se corte el texto */
  .sheet-container {
    display: flex;
    flex-direction: column;
    height: 100%;
    box-sizing: border-box;
    padding: 15mm; /* Márgenes de la hoja */
  }

  /* LOGOTIPO */
  .sheet-logo-container {
    text-align: center;
    margin-top: 0;
    margin-bottom: 15px;
  }

  .sheet-logo {
    height: 70px;
    object-fit: contain;
  }

  /* Título formal */
  .sheet-title {
    font-family: 'Georgia', 'Times New Roman', serif;
    font-size: 22pt !important;
    font-weight: bold !important;
    text-align: center !important;
    margin-top: 0 !important;
    margin-bottom: 8px !important;
    color: #000000 !important;
  }

  .sheet-subtitle {
    font-size: 10pt !important;
    text-align: center !important;
    margin-bottom: 20px !important;
    color: #333333 !important;
    font-family: Arial, sans-serif;
  }

  /* Tabla estilo Excel */
  .sheet-table {
    border: 1px solid #000000 !important;
  }

  .sheet-table th, 
  .sheet-table td {
    border: 1px solid #000000 !important;
    padding: 6px 8px !important;
    font-size: 10pt !important;
    color: #000000 !important;
  }

  .sheet-table th {
    background-color: #e0f2fe !important;
    -webkit-print-color-adjust: exact !important;
    print-color-adjust: exact !important;
    padding: 8px !important;
  }

  .sheet-table td {
    height: 26px !important;
    vertical-align: middle;
  }

  /* Resumen inferior */
  .sheet-summary {
    display: flex !important;
    justify-content: space-between !important;
    font-size: 11pt !important;
    margin-top: 15px !important;
    padding: 0 5px !important;
    font-family: Arial, sans-serif;
  }

  /* Firmas */
  .sheet-signatures {
    display: flex !important;
    justify-content: space-around !important;
    margin-top: auto !important; /* Empuja las firmas hacia el fondo de la hoja */
    padding-top: 30px !important;
    padding-bottom: 10px !important;
  }

  .signature-box {
    width: 35% !important;
    text-align: center !important;
    font-size: 10pt !important;
    font-family: Arial, sans-serif;
  }

  .signature-box .line {
    border-top: 1px solid #000000 !important;
    margin-bottom: 8px !important;
  }
}
</style>