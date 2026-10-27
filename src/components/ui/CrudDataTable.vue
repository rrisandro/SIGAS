<template>
  <div class="cdt">
    <div class="cdt-toolbar">
      <div class="cdt-heading">
        <h3 v-if="title" class="cdt-title">{{ title }}</h3>
        <p v-if="subtitle" class="cdt-subtitle">{{ subtitle }}</p>
      </div>

      <div class="cdt-toolbar-actions">
        <slot name="toolbar" />
        <BaseInput
          v-model="search"
          :placeholder="searchPlaceholder"
          class="cdt-search"
        />
      </div>
    </div>

    <!-- Móvil: una tarjeta por fila -->
    <div class="cdt-cards" role="list">
      <p v-if="paginatedRows.length === 0" class="cdt-empty">No hay registros</p>

      <article
        v-for="(row, index) in paginatedRows"
        :key="row.id ?? index"
        class="cdt-card"
        role="listitem"
      >
        <div
          v-for="(col, colIndex) in columns"
          :key="col.key"
          class="cdt-card-row"
          :class="{ 'cdt-card-row--primary': colIndex === 0 }"
        >
          <span class="cdt-card-label">{{ col.label }}</span>
          <div class="cdt-card-value">
            <slot :name="`cell-${col.key}`" :row="row" :value="row[col.key]">
              <span class="break-words">{{ formatCell(row, col) }}</span>
            </slot>
          </div>
        </div>

        <div v-if="$slots.actions" class="cdt-card-actions">
          <slot name="actions" :row="row" />
        </div>
      </article>
    </div>

    <!-- Tablet / desktop: tabla -->
    <div
      class="cdt-table-wrap table-scroll"
      tabindex="0"
      role="region"
      aria-label="Tabla de registros desplazable"
    >
      <table class="cdt-table">
        <thead>
          <tr>
            <th
              v-for="col in columns"
              :key="col.key"
              scope="col"
            >
              {{ col.label }}
            </th>
            <th v-if="$slots.actions" scope="col">Acciones</th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="paginatedRows.length === 0">
            <td :colspan="columns.length + ($slots.actions ? 1 : 0)" class="cdt-empty-cell">
              No hay registros
            </td>
          </tr>
          <tr v-for="(row, index) in paginatedRows" :key="row.id ?? index">
            <td v-for="col in columns" :key="col.key">
              <slot :name="`cell-${col.key}`" :row="row" :value="row[col.key]">
                <span class="break-words">{{ formatCell(row, col) }}</span>
              </slot>
            </td>
            <td v-if="$slots.actions" class="cdt-actions-cell">
              <div class="cdt-actions">
                <slot name="actions" :row="row" />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="cdt-footer">
      <span class="cdt-count">{{ filteredRows.length }} registro(s)</span>

      <div class="cdt-pagination">
        <BaseButton
          variant="outline"
          size="sm"
          :disabled="page <= 1"
          @click="page--"
        >
          Anterior
        </BaseButton>
        <span class="cdt-page-indicator">{{ page }} / {{ totalPages }}</span>
        <BaseButton
          variant="outline"
          size="sm"
          :disabled="page >= totalPages"
          @click="page++"
        >
          Siguiente
        </BaseButton>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue'
import BaseInput from './BaseInput.vue'
import BaseButton from './BaseButton.vue'

const props = defineProps({
  title: { type: String, default: '' },
  subtitle: { type: String, default: '' },
  columns: { type: Array, required: true },
  rows: { type: Array, default: () => [] },
  searchKeys: { type: Array, default: () => [] },
  searchPlaceholder: { type: String, default: 'Buscar...' },
  pageSize: { type: Number, default: 8 },
})

const search = ref('')
const page = ref(1)

const filteredRows = computed(() => {
  const q = search.value.trim().toLowerCase()
  if (!q) return props.rows
  const keys = props.searchKeys.length
    ? props.searchKeys
    : props.columns.map((c) => c.key)
  return props.rows.filter((row) =>
    keys.some((key) => String(row[key] ?? '').toLowerCase().includes(q))
  )
})

const totalPages = computed(() => Math.max(1, Math.ceil(filteredRows.value.length / props.pageSize)))

const paginatedRows = computed(() => {
  const start = (page.value - 1) * props.pageSize
  return filteredRows.value.slice(start, start + props.pageSize)
})

watch([search, () => props.rows], () => {
  page.value = 1
})

watch(totalPages, (n) => {
  if (page.value > n) page.value = n
})

function formatCell(row, col) {
  if (typeof col.format === 'function') return col.format(row[col.key], row)
  return row[col.key] ?? '—'
}
</script>

<style scoped>
.cdt {
  width: 100%;
  min-width: 0;
  overflow: hidden;
  background: #ffffff;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
}

/* --------------------------------------------------------------------------
   Barra superior + buscador
   -------------------------------------------------------------------------- */
.cdt-toolbar {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 14px;
  border-bottom: 1px solid var(--color-border-light);
}

.cdt-heading {
  min-width: 0;
}

.cdt-title {
  color: var(--color-heading);
  font-size: 1rem;
  font-weight: 600;
  line-height: 1.3;
}

.cdt-subtitle {
  margin-top: 2px;
  color: var(--color-muted);
  font-size: 0.8rem;
}

.cdt-toolbar-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
  width: 100%;
}

.cdt-toolbar-actions :deep(.btn-custom) {
  width: 100%;
}

.cdt-search {
  width: 100%;
}

/* --------------------------------------------------------------------------
   Móvil · tarjetas
   -------------------------------------------------------------------------- */
.cdt-cards {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 12px;
}

.cdt-card {
  display: flex;
  flex-direction: column;
  min-width: 0;
  padding: 12px 14px;
  background: #ffffff;
  border: 1px solid var(--color-border);
  border-radius: 14px;
  box-shadow: 0 1px 3px rgba(15, 23, 42, 0.06);
}

.cdt-card-row {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  min-width: 0;
  padding: 7px 0;
  border-bottom: 1px solid var(--color-border-light);
}

.cdt-card-row:first-child {
  padding-top: 0;
}

.cdt-card-row--primary {
  padding-bottom: 10px;
}

.cdt-card-row--primary .cdt-card-value {
  color: var(--color-heading);
  font-size: 1rem;
  font-weight: 600;
}

.cdt-card-label {
  flex: 0 0 auto;
  max-width: 45%;
  padding-top: 1px;
  color: var(--color-muted-light);
  font-size: 0.68rem;
  font-weight: 600;
  letter-spacing: 0.03em;
  line-height: 1.4;
  text-transform: uppercase;
}

.cdt-card-value {
  min-width: 0;
  color: var(--color-text);
  font-size: 0.875rem;
  line-height: 1.45;
  text-align: right;
  overflow-wrap: anywhere;
}

.cdt-card-value :deep(svg) {
  margin-left: auto;
}

.cdt-card-actions {
  display: flex;
  align-items: stretch;
  gap: 8px;
  margin-top: 10px;
}

.cdt-card-actions :deep(.btn-custom) {
  flex: 1 1 0;
  width: 100%;
  min-width: 0;
  padding-inline: 10px;
  font-size: 0.8rem;
}

.cdt-card-actions :deep(.text-xs),
.cdt-card-actions :deep(.text-sm) {
  display: inline-flex;
  align-items: center;
  min-height: 44px;
}

.cdt-empty {
  padding: 28px 12px;
  color: var(--color-muted);
  font-size: 0.875rem;
  text-align: center;
}

/* La tabla se oculta en móvil */
.cdt-table-wrap {
  display: none;
}

/* --------------------------------------------------------------------------
   Footer y paginación
   -------------------------------------------------------------------------- */
.cdt-footer {
  display: flex;
  flex-direction: column;
  align-items: stretch;
  gap: 10px;
  padding: 12px 14px;
  border-top: 1px solid var(--color-border-light);
  color: var(--color-muted);
  font-size: 0.8rem;
}

.cdt-count {
  text-align: center;
}

.cdt-pagination {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.cdt-pagination :deep(.btn-custom) {
  flex: 1 1 0;
  min-width: 0;
  padding-inline: 12px;
}

.cdt-page-indicator {
  flex: 0 0 auto;
  min-width: 48px;
  text-align: center;
  font-variant-numeric: tabular-nums;
}

/* --------------------------------------------------------------------------
   Tablet · tabla con scroll horizontal y encabezado sticky
   -------------------------------------------------------------------------- */
@media (min-width: 640px) {
  .cdt-toolbar {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
    padding: 16px;
  }

  .cdt-toolbar-actions {
    flex-direction: row;
    flex-wrap: wrap;
    align-items: center;
    justify-content: flex-end;
    width: auto;
    max-width: 65%;
  }

  .cdt-toolbar-actions :deep(.btn-custom) {
    width: auto;
  }

  .cdt-search {
    width: 220px;
  }

  .cdt-cards {
    display: none;
  }

  .cdt-table-wrap {
    display: block;
    width: 100%;
    max-height: min(68vh, 720px);
    overflow: auto;
    -webkit-overflow-scrolling: touch;
    overscroll-behavior: contain;
  }

  .cdt-table {
    width: 100%;
    min-width: 680px;
    border-collapse: separate;
    border-spacing: 0;
    text-align: left;
  }

  .cdt-table thead th {
    position: sticky;
    top: 0;
    z-index: 2;
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

  .cdt-table tbody td {
    padding: 11px 12px;
    border-bottom: 1px solid var(--color-border-light);
    color: var(--color-text);
    font-size: 0.84rem;
    vertical-align: middle;
  }

  .cdt-table tbody tr:last-child td {
    border-bottom: 0;
  }

  .cdt-table tbody tr:hover {
    background: rgba(240, 249, 255, 0.5);
  }

  .cdt-actions-cell {
    width: 1%;
    white-space: nowrap;
  }

  .cdt-actions {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 8px;
  }

  .cdt-empty-cell {
    padding: 32px 16px !important;
    color: var(--color-muted) !important;
    text-align: center;
  }

  .cdt-footer {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    padding: 12px 16px;
  }

  .cdt-count {
    text-align: left;
  }

  .cdt-pagination :deep(.btn-custom) {
    flex: 0 0 auto;
  }
}

/* --------------------------------------------------------------------------
   Desktop · tabla completa
   -------------------------------------------------------------------------- */
@media (min-width: 1024px) {
  .cdt-table-wrap {
    max-height: none;
    overflow-x: auto;
    overflow-y: visible;
  }

  .cdt-table {
    min-width: 100%;
  }

  .cdt-table thead th {
    position: static;
    padding: 12px 16px;
  }

  .cdt-table tbody td {
    padding: 13px 16px;
    font-size: 0.875rem;
  }

  .cdt-toolbar {
    padding: 18px 20px;
  }

  .cdt-footer {
    padding: 14px 20px;
  }

  .cdt-search {
    width: 260px;
  }
}
</style>
