<template>
  <div class="page history-page">
    <div class="page-heading">
      <h2 class="page-title">Mi Historial</h2>
      <p class="page-subtitle">Todas tus solicitudes registradas</p>
    </div>

    <div class="history-card">
      <!-- Barra superior: buscador colapsable en móvil -->
      <div class="history-toolbar">
        <h3 class="history-toolbar__title">Solicitudes</h3>

        <button
          type="button"
          class="filters-toggle"
          :aria-expanded="filtrosAbiertos"
          aria-controls="history-filters"
          @click="filtrosAbiertos = !filtrosAbiertos"
        >
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16M7 12h10M10 18h4" />
          </svg>
          Buscar / filtrar
        </button>

        <div
          id="history-filters"
          class="filters-panel"
          :class="{ 'is-open': filtrosAbiertos }"
        >
          <label for="history-search" class="sr-only">Buscar en el historial</label>
          <input
            id="history-search"
            v-model="filtro"
            type="search"
            placeholder="Buscar por tipo, pico, estatus..."
            class="history-search"
          />
        </div>
      </div>

      <!-- Estado de carga -->
      <div v-if="cargando" class="loading-box">
        Cargando tu historial de pedidos...
      </div>

      <template v-else>
        <!-- Móvil: tarjetas -->
        <div class="history-cards">
          <p v-if="pedidosFiltrados.length === 0" class="empty-box">No hay registros</p>

          <article
            v-for="pedido in pedidosFiltrados"
            :key="pedido.id_pedido"
            class="history-card-item"
          >
            <div class="history-card-item__head">
              <span class="history-card-item__id">#{{ pedido.id_pedido }}</span>
              <StatusBadge :status="String(pedido.status).trim()" />
            </div>

            <div class="history-card-item__row">
              <span>Fecha</span>
              <strong>{{ formatearFecha(pedido.fecha_solicitud) }}</strong>
            </div>
            <div class="history-card-item__row">
              <span>Tipo</span>
              <strong>{{ pedido.tipo_bombona }}</strong>
            </div>
            <div class="history-card-item__row">
              <span>Pico</span>
              <strong>{{ pedido.pico }}</strong>
            </div>
            <div class="history-card-item__row history-card-item__row--column">
              <span>Observaciones</span>
              <strong>{{ pedido.observaciones || '-' }}</strong>
            </div>
          </article>
        </div>

        <!-- Tablet / desktop: tabla -->
        <div class="table-scroll history-table-wrap">
          <table class="history-table">
            <thead>
              <tr>
                <th scope="col">#</th>
                <th scope="col">Fecha</th>
                <th scope="col">Tipo</th>
                <th scope="col">Pico</th>
                <th scope="col">Estatus</th>
                <th scope="col">Observaciones</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="pedidosFiltrados.length === 0">
                <td colspan="6" class="empty-cell">No hay registros</td>
              </tr>

              <tr v-for="pedido in pedidosFiltrados" :key="pedido.id_pedido">
                <td class="id-cell">{{ pedido.id_pedido }}</td>
                <td class="nowrap-cell">{{ formatearFecha(pedido.fecha_solicitud) }}</td>
                <td>{{ pedido.tipo_bombona }}</td>
                <td class="nowrap-cell">{{ pedido.pico }}</td>
                <td><StatusBadge :status="String(pedido.status).trim()" /></td>
                <td class="obs-cell">{{ pedido.observaciones || '-' }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </template>

      <!-- Paginación (Visual) -->
      <div class="history-footer">
        <span>{{ pedidosFiltrados.length }} registro(s)</span>
        <div class="pagination">
          <button type="button" class="pager-btn" disabled>Anterior</button>
          <span class="page-indicator">1 / 1</span>
          <button type="button" class="pager-btn" disabled>Siguiente</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref, onMounted } from 'vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import { supabase } from '../../lib/supabase'

const pedidos = ref([])
const cargando = ref(true)
const error = ref('')
const filtro = ref('')
const filtrosAbiertos = ref(false)

const pedidosFiltrados = computed(() => {
  const q = filtro.value.trim().toLowerCase()
  if (!q) return pedidos.value
  return pedidos.value.filter((pedido) =>
    [
      pedido.id_pedido,
      pedido.tipo_bombona,
      pedido.pico,
      pedido.status,
      pedido.observaciones,
    ].some((value) => String(value ?? '').toLowerCase().includes(q))
  )
})

onMounted(async () => {
  const { data: { user }, error: authError } = await supabase.auth.getUser()

  if (user && !authError) {
    const { data: familiaData } = await supabase
      .from('familias')
      .select('id')
      .eq('auth_id', user.id)
      .eq('is_deleted', false)
      .maybeSingle()

    if (familiaData) {
      const { data: pedidosData, error: pedidosError } = await supabase
        .from('pedidos')
        .select('*')
        .eq('id_familias', familiaData.id)
        .order('status', { ascending: false })
        .order('fecha_solicitud', { ascending: false })

      if (pedidosData) {
        pedidos.value = pedidosData
      } else if (pedidosError) {
        console.error("Error al cargar historial:", pedidosError)
      }
    }
  } else {
    error.value = "Sesión no válida"
  }

  cargando.value = false
})

function formatearFecha(fechaString) {
  if (!fechaString) return 'Sin fecha'
  const fecha = new Date(fechaString)
  return fecha.toLocaleDateString('es-VE')
}
</script>

<style scoped>
.history-page {
  display: flex;
  flex-direction: column;
  gap: 18px;
  max-width: 1100px;
}

.history-card {
  overflow: hidden;
  background: #ffffff;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
}

.history-toolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 14px;
  border-bottom: 1px solid var(--color-border-light);
}

.history-toolbar__title {
  color: var(--color-heading);
  font-size: 0.95rem;
  font-weight: 600;
}

.filters-toggle {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 7px;
  min-height: 44px;
  padding: 8px 14px;
  border: 1px solid #d1d5db;
  border-radius: 10px;
  background: #ffffff;
  color: var(--color-text);
  font-size: 0.82rem;
  font-weight: 600;
  cursor: pointer;
}

.filters-toggle svg {
  width: 17px;
  height: 17px;
}

.filters-panel {
  display: none;
  width: 100%;
}

.filters-panel.is-open {
  display: block;
}

.history-search {
  width: 100%;
  height: 44px;
  padding: 0 12px;
  border: 1px solid #d1d5db;
  border-radius: 11px;
  background: #ffffff;
  color: var(--color-text);
  font-size: 16px;
  outline: none;
}

.history-search:focus {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.14);
}

.loading-box,
.empty-box {
  padding: 32px 16px;
  color: var(--color-muted);
  text-align: center;
  font-size: 0.875rem;
}

/* --------------------------------------------------------------------------
   Móvil · tarjetas
   -------------------------------------------------------------------------- */
.history-cards {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
}

.history-card-item {
  padding: 12px 14px;
  background: #ffffff;
  border: 1px solid var(--color-border);
  border-radius: 14px;
  box-shadow: 0 1px 3px rgba(15, 23, 42, 0.05);
}

.history-card-item__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding-bottom: 10px;
  margin-bottom: 4px;
  border-bottom: 1px solid var(--color-border-light);
}

.history-card-item__id {
  color: var(--color-primary-dark);
  font-size: 0.9rem;
  font-weight: 700;
}

.history-card-item__row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  padding: 7px 0;
  border-bottom: 1px solid var(--color-border-light);
  font-size: 0.82rem;
}

.history-card-item__row:last-child {
  border-bottom: 0;
}

.history-card-item__row > span {
  flex: 0 0 auto;
  color: var(--color-muted-light);
  font-size: 0.68rem;
  font-weight: 600;
  letter-spacing: 0.03em;
  text-transform: uppercase;
}

.history-card-item__row > strong {
  color: var(--color-text);
  font-weight: 500;
  text-align: right;
  overflow-wrap: anywhere;
}

.history-card-item__row--column {
  flex-direction: column;
  gap: 3px;
}

.history-card-item__row--column > strong {
  text-align: left;
}

/* La tabla se oculta en móvil */
.history-table-wrap {
  display: none;
}

/* --------------------------------------------------------------------------
   Footer / paginación
   -------------------------------------------------------------------------- */
.history-footer {
  display: flex;
  flex-direction: column;
  align-items: stretch;
  gap: 10px;
  padding: 12px 14px;
  border-top: 1px solid var(--color-border-light);
  color: var(--color-muted);
  font-size: 0.8rem;
}

.history-footer > span {
  text-align: center;
}

.pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.pager-btn {
  flex: 1 1 0;
  min-height: 44px;
  padding: 8px 12px;
  border: 1px solid #d1d5db;
  border-radius: 10px;
  background: #ffffff;
  color: var(--color-text);
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
}

.pager-btn:hover:not(:disabled) {
  background: var(--color-bg);
}

.pager-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.page-indicator {
  flex: 0 0 auto;
  min-width: 48px;
  text-align: center;
}

/* --------------------------------------------------------------------------
   Tablet / desktop · tabla
   -------------------------------------------------------------------------- */
@media (min-width: 640px) {
  .history-page {
    gap: 24px;
  }

  .history-toolbar {
    padding: 16px 18px;
  }

  .filters-toggle {
    display: none;
  }

  .filters-panel {
    display: block;
    width: auto;
    flex: 0 1 320px;
  }

  .history-search {
    height: 40px;
    font-size: 15px;
  }

  .history-cards {
    display: none;
  }

  .history-table-wrap {
    display: block;
  }

  .history-table {
    width: 100%;
    min-width: 640px;
    border-collapse: collapse;
    text-align: left;
  }

  .history-table thead th {
    position: sticky;
    top: 0;
    z-index: 1;
    padding: 11px 12px;
    background: #f9fafb;
    border-bottom: 1px solid var(--color-border);
    color: var(--color-muted);
    font-size: 0.72rem;
    font-weight: 600;
    letter-spacing: 0.03em;
    text-transform: uppercase;
    white-space: nowrap;
  }

  .history-table tbody td {
    padding: 11px 12px;
    border-bottom: 1px solid var(--color-border-light);
    color: var(--color-text);
    font-size: 0.84rem;
    vertical-align: middle;
  }

  .history-table tbody tr:hover {
    background: rgba(240, 249, 255, 0.5);
  }

  .history-table .id-cell {
    color: var(--color-primary-dark);
    font-weight: 600;
  }

  .nowrap-cell {
    white-space: nowrap;
  }

  .obs-cell {
    min-width: 160px;
    overflow-wrap: anywhere;
  }

  .history-table .empty-cell {
    padding: 32px 16px;
    color: var(--color-muted);
    text-align: center;
  }

  .history-footer {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    padding: 12px 18px;
  }

  .history-footer > span {
    text-align: left;
  }

  .pager-btn {
    flex: 0 0 auto;
    min-height: 40px;
  }
}

@media (min-width: 1024px) {
  .history-toolbar {
    padding: 18px 20px;
  }

  .history-table thead th {
    padding: 12px 16px;
  }

  .history-table tbody td {
    padding: 13px 16px;
  }

  .history-footer {
    padding: 14px 20px;
  }

  .pager-btn {
    min-height: 36px;
  }
}
</style>
