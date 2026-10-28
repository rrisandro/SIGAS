<template>
  <div class="page deliveries-page">
    <!-- Header y Filtro por Ciclo -->
    <div class="deliveries-header">
      <div class="page-heading">
        <h2 class="page-title">Control de Entregas</h2>
        <p class="page-subtitle">Gestión de entregas sectorizadas por jornada</p>
      </div>

      <!-- Desplegable para Filtrar por Ciclo -->
      <div class="cycle-filter">
        <label for="cycle-filter-select" class="cycle-filter__label">Filtrar por Ciclo:</label>
        <select
          id="cycle-filter-select"
          v-model="cicloSeleccionado"
          class="cycle-filter__select"
        >
          <option value="todos">Todos los Ciclos</option>
          <option v-for="ciclo in listaCiclos" :key="ciclo.id_ciclo" :value="ciclo.id_ciclo">
            {{ ciclo.nombre_ciclo }} {{ ciclo.estado === 'activo' ? '(Activo)' : '' }}
          </option>
        </select>
      </div>
    </div>

    <!-- Indicador de Carga -->
    <div v-if="cargando" class="loading-box">
      Cargando información de entregas...
    </div>

    <div v-else class="deliveries-stack">
      <!-- Entregas Pendientes (Pedidos Aceptados) -->
      <CrudDataTable
        title="Pedidos Aceptados (Pendientes por Entrega)"
        :columns="columnsPendientes"
        :rows="pedidosPendientes"
        :search-keys="['familia', 'calle', 'tipo']"
      >
        <template #cell-estatus="{ row }">
          <StatusBadge :status="row.estatus" />
        </template>
        <template #actions="{ row }">
          <BaseButton size="sm" variant="success" @click="openEntrega(row)">
            Registrar Entrega
          </BaseButton>
        </template>
      </CrudDataTable>

      <!-- Historial de Entregas Realizadas -->
      <CrudDataTable
        title="Historial de Entregas Realizadas"
        :columns="columnsHistorial"
        :rows="entregasRealizadas"
        :search-keys="['familia', 'tipo', 'ciclo']"
      >
        <template #cell-fecha_entrega="{ row }">
          {{ formatearFecha(row.fecha_entrega) }}
        </template>
      </CrudDataTable>
    </div>

    <!-- Modal para registrar entrega -->
    <Teleport to="body">
      <div v-if="showEntrega" class="delivery-modal">
        <div class="delivery-modal__backdrop" @click="showEntrega = false" />

        <div
          class="delivery-modal__panel"
          role="dialog"
          aria-modal="true"
          aria-label="Confirmar entrega"
        >
          <span class="delivery-modal__handle" aria-hidden="true" />

          <!-- Header del modal -->
          <div class="delivery-modal__header">
            <div class="delivery-modal__icon">
              <svg fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <div>
              <h3>Confirmar Entrega</h3>
              <p>
                {{ selected?.familia || 'Familia' }} — Bombona {{ selected?.tipo || '' }}
              </p>
            </div>
          </div>

          <div class="delivery-modal__divider" />

          <p class="delivery-modal__text">
            ¿Confirmas que la bombona ha sido despachada y entregada exitosamente al usuario? Esta acción cambiará el estado del pedido a <strong>entregado</strong> y guardará la constancia en el historial.
          </p>

          <!-- Error -->
          <p v-if="errorEntrega" class="delivery-modal__error">
            {{ errorEntrega }}
          </p>

          <div class="delivery-modal__divider" />

          <!-- Botones -->
          <div class="delivery-modal__actions">
            <BaseButton variant="ghost" @click="showEntrega = false">Cancelar</BaseButton>
            <BaseButton variant="success" :disabled="guardando" @click="confirmarEntrega">
              {{ guardando ? 'Guardando...' : 'Confirmar Entrega' }}
            </BaseButton>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { computed, ref, onMounted } from 'vue'
import CrudDataTable from '../../components/ui/CrudDataTable.vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import { supabase } from '../../lib/supabase'

const showEntrega = ref(false)
const selected = ref(null)
const errorEntrega = ref('')
const cargando = ref(true)
const guardando = ref(false)

const listaPedidos = ref([])
const historialEntregas = ref([])
const listaCiclos = ref([])
const cicloSeleccionado = ref('todos') // 'todos' o ID del ciclo seleccionado

const columnsPendientes = [
  { key: 'id', label: '#' },
  { key: 'fecha', label: 'Fecha Solicitud' },
  { key: 'familia', label: 'Familia' },
  { key: 'calle', label: 'Calle' },
  { key: 'tipo', label: 'Tipo' },
  { key: 'estatus', label: 'Estatus' },
]

const columnsHistorial = [
  { key: 'id', label: '#' },
  { key: 'familia', label: 'Familia' },
  { key: 'tipo', label: 'Tipo' },
  { key: 'ciclo', label: 'Ciclo' },
  { key: 'fecha_entrega', label: 'Fecha Entrega' },
]

// Filtra los pedidos pendientes considerando el ciclo seleccionado
const pedidosPendientes = computed(() => {
  return listaPedidos.value
    .filter((p) => {
      const esAceptado = p.status === 'aceptado'
      const coincideCiclo = cicloSeleccionado.value === 'todos' || p.id_ciclo === Number(cicloSeleccionado.value)
      return esAceptado && coincideCiclo
    })
    .map((p) => ({
      id: p.id_pedido,
      fecha: formatearFecha(p.fecha_solicitud || p.created_at),
      familia: p.familias?.nombre_familia || 'Familia no registrada',
      calle: p.familias?.calles?.nombre || 'Sin calle',
      tipo: `${p.tipo_bombona} (${p.pico})`,
      estatus: p.status,
      _original: p
    }))
})

// Mapea y filtra las entregas realizadas por el ciclo seleccionado
const entregasRealizadas = computed(() => {
  return historialEntregas.value
    .filter((h) => {
      if (cicloSeleccionado.value === 'todos') return true
      return h.id_ciclo === Number(cicloSeleccionado.value)
    })
    .map((h) => {
      const pedidoRel = h.pedidos || h.pedido || listaPedidos.value.find(p => p.id_pedido === h.id_pedido)
      const nombreFamilia = pedidoRel?.familias?.nombre_familia || pedidoRel?.familia?.nombre_familia || 'Familia'
      const tipoBombona = pedidoRel?.tipo_bombona ? `Bombona ${pedidoRel.tipo_bombona}` : 'Bombona'

      const nombreCiclo = h.ciclos_distribucion?.nombre_ciclo
                       || pedidoRel?.ciclos_distribucion?.nombre_ciclo
                       || h.ciclo_distribucion
                       || 'Ciclo General'

      return {
        id: h.id_historial || h.id_pedido,
        familia: nombreFamilia,
        tipo: tipoBombona,
        ciclo: nombreCiclo,
        fecha_entrega: h.fecha_entrega,
        _original: h
      }
    })
})

async function cargarDatos() {
  cargando.value = true

  // 1. Cargar catálogo de ciclos de distribución para el desplegable
  const { data: ciclosData } = await supabase
    .from('ciclos_distribucion')
    .select('id_ciclo, nombre_ciclo, estado')
    .order('id_ciclo', { ascending: false })

  listaCiclos.value = ciclosData || []

  // 2. Cargar pedidos con sus relaciones
  const { data: pedidosData, error: errPedidos } = await supabase
    .from('pedidos')
    .select(`
      *,
      familias (
        id,
        nombre_familia,
        is_deleted,
        calles (id_calle, nombre)
      ),
      ciclos_distribucion (
        id_ciclo,
        nombre_ciclo
      )
    `)
    .order('id_pedido', { ascending: false })

  if (!errPedidos) {
    listaPedidos.value = (pedidosData || []).filter(
      (pedido) => !pedido.familias?.is_deleted
    )
  }

  // 3. Cargar el historial de entregas
  const { data: historialData, error: errHistorial } = await supabase
    .from('historial_distribucion')
    .select(`
      id_historial,
      id_pedido,
      id_ciclo,
      ciclo_distribucion,
      fecha_entrega,
      pedidos:id_pedido (
        id_pedido,
        tipo_bombona,
        pico,
        status,
        familias (
          id,
          nombre_familia
        )
      ),
      ciclos_distribucion:id_ciclo (
        id_ciclo,
        nombre_ciclo
      )
    `)
    .order('fecha_entrega', { ascending: false })

  if (errHistorial || !historialData || historialData.length === 0) {
    const { data: fallbackHistorial } = await supabase
      .from('historial_distribucion')
      .select('*')
      .order('fecha_entrega', { ascending: false })

    historialEntregas.value = fallbackHistorial || []
  } else {
    historialEntregas.value = historialData || []
  }

  cargando.value = false
}

onMounted(async () => {
  await supabase.auth.getSession()
  await cargarDatos()
})

function openEntrega(row) {
  selected.value = row
  errorEntrega.value = ''
  showEntrega.value = true
}

async function confirmarEntrega() {
  if (!selected.value) return

  guardando.value = true
  errorEntrega.value = ''

  const pedidoObj = selected.value._original

  // A. Actualizar estado a 'entregado' en la tabla pedidos
  const { error: errUpdate } = await supabase
    .from('pedidos')
    .update({ status: 'entregado' })
    .eq('id_pedido', pedidoObj.id_pedido)

  if (errUpdate) {
    errorEntrega.value = 'Error al actualizar el pedido: ' + errUpdate.message
    guardando.value = false
    return
  }

  const nombreCicloReal = pedidoObj.ciclos_distribucion?.nombre_ciclo || 'Ciclo General'

  // B. Registrar la constancia en 'historial_distribucion'
  const { error: errHistorial } = await supabase
    .from('historial_distribucion')
    .insert([
      {
        id_pedido: pedidoObj.id_pedido,
        id_ciclo: pedidoObj.id_ciclo,
        ciclo_distribucion: nombreCicloReal,
        fecha_entrega: new Date().toISOString()
      }
    ])

  guardando.value = false

  if (errHistorial) {
    errorEntrega.value = 'Error al registrar en historial: ' + errHistorial.message
  } else {
    showEntrega.value = false
    selected.value = null
    await cargarDatos()
  }
}

function formatearFecha(fecha) {
  if (!fecha) return '-'
  return new Date(fecha).toLocaleDateString('es-VE')
}
</script>

<style scoped>
.deliveries-page {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.deliveries-header {
  display: flex;
  flex-direction: column;
  gap: 14px;
  padding: 14px;
  background: #ffffff;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
}

.cycle-filter {
  display: flex;
  flex-direction: column;
  gap: 6px;
  width: 100%;
}

.cycle-filter__label {
  color: var(--color-text);
  font-size: 0.8125rem;
  font-weight: 600;
}

.cycle-filter__select {
  width: 100%;
  min-height: 44px;
  padding: 0 38px 0 12px;
  border: 1px solid #d1d5db;
  border-radius: 11px;
  background-color: #ffffff;
  color: var(--color-text);
  font-size: 16px;
  outline: none;
  cursor: pointer;
  -webkit-appearance: none;
  appearance: none;
  transition: border-color var(--transition-fast), box-shadow var(--transition-fast);
}

.cycle-filter__select:focus {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.14);
}

.deliveries-stack {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.loading-box {
  padding: 32px 16px;
  color: var(--color-muted);
  text-align: center;
}

/* --------------------------------------------------------------------------
   Modal de entrega
   -------------------------------------------------------------------------- */
.delivery-modal {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

.delivery-modal__backdrop {
  position: absolute;
  inset: 0;
  background: rgba(15, 23, 42, 0.52);
  backdrop-filter: blur(3px);
  -webkit-backdrop-filter: blur(3px);
}

.delivery-modal__panel {
  position: relative;
  z-index: 1;
  width: 100%;
  max-height: 85dvh;
  padding: 12px 16px calc(18px + var(--safe-bottom));
  overflow-y: auto;
  background: #ffffff;
  border-radius: 22px 22px 0 0;
  box-shadow: 0 -12px 40px rgba(15, 23, 42, 0.2);
  animation: slideUp 0.22s ease-out;
}

.delivery-modal__handle {
  display: block;
  width: 40px;
  height: 4px;
  margin: 0 auto 14px;
  border-radius: 999px;
  background: #e2e8f0;
}

.delivery-modal__header {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.delivery-modal__icon {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: #d1fae5;
  color: #059669;
}

.delivery-modal__icon svg {
  width: 20px;
  height: 20px;
}

.delivery-modal__header h3 {
  color: var(--color-heading);
  font-size: 1.05rem;
  font-weight: 700;
}

.delivery-modal__header p {
  margin-top: 2px;
  color: var(--color-muted);
  font-size: 0.82rem;
  line-height: 1.4;
}

.delivery-modal__divider {
  height: 1px;
  margin: 14px 0;
  background: var(--color-border);
}

.delivery-modal__text {
  color: var(--color-text);
  font-size: 0.875rem;
  line-height: 1.55;
}

.delivery-modal__text strong {
  color: #059669;
}

.delivery-modal__error {
  margin-top: 10px;
  color: #dc2626;
  font-size: 0.82rem;
  font-weight: 500;
}

.delivery-modal__actions {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.delivery-modal__actions :deep(.btn-custom) {
  width: 100%;
}

@media (min-width: 640px) {
  .deliveries-page {
    gap: 24px;
  }

  .deliveries-header {
    padding: 18px 20px;
  }

  .cycle-filter__select {
    min-height: 40px;
    font-size: 15px;
  }

  .delivery-modal {
    align-items: center;
    padding: 20px;
  }

  .delivery-modal__panel {
    max-width: 480px;
    max-height: 85vh;
    padding: 20px;
    border-radius: 16px;
    animation: scaleIn 0.2s ease-out;
  }

  .delivery-modal__handle {
    display: none;
  }

  .delivery-modal__actions {
    flex-direction: row;
    justify-content: flex-end;
  }

  .delivery-modal__actions :deep(.btn-custom) {
    width: auto;
  }
}

@media (min-width: 768px) {
  .deliveries-header {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
  }

  .cycle-filter {
    flex-direction: row;
    align-items: center;
    width: auto;
    gap: 10px;
  }

  .cycle-filter__label {
    white-space: nowrap;
  }

  .cycle-filter__select {
    width: auto;
    min-width: 210px;
  }
}

@media (min-width: 1024px) {
  .deliveries-header {
    padding: 20px 22px;
  }

  .delivery-modal__panel {
    max-width: 520px;
    padding: 24px;
  }
}
</style>
