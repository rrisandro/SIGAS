<template>
  <div class="overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-sm">
    <div class="flex flex-col gap-3 border-b border-gray-100 p-4 sm:flex-row sm:items-center sm:justify-between">
      <div>
        <h3 v-if="title" class="text-base font-medium text-gray-700">{{ title }}</h3>
        <p v-if="subtitle" class="text-sm text-gray-500">{{ subtitle }}</p>
      </div>
      <div class="flex flex-wrap items-center gap-2">
        <slot name="toolbar" />
        <BaseInput
          v-model="search"
          :placeholder="searchPlaceholder"
          class="sm:w-64"
        />
      </div>
    </div>

    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-gray-100 text-left text-sm">
        <thead class="bg-gray-50">
          <tr>
            <th
              v-for="col in columns"
              :key="col.key"
              class="px-4 py-3 font-medium text-gray-500"
            >
              {{ col.label }}
            </th>
            <th v-if="$slots.actions" class="px-4 py-3 font-medium text-gray-500">Acciones</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          <tr v-if="paginatedRows.length === 0">
            <td :colspan="columns.length + ($slots.actions ? 1 : 0)" class="px-4 py-8 text-center text-gray-500">
              No hay registros
            </td>
          </tr>
          <tr
            v-for="(row, index) in paginatedRows"
            :key="row.id ?? index"
            class="hover:bg-sky-50/40"
          >
            <td v-for="col in columns" :key="col.key" class="px-4 py-3 text-gray-700">
              <slot :name="`cell-${col.key}`" :row="row" :value="row[col.key]">
                {{ formatCell(row, col) }}
              </slot>
            </td>
            <td v-if="$slots.actions" class="px-4 py-3">
              <div class="flex items-center gap-2">
                <slot name="actions" :row="row" />
              </div>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div class="flex items-center justify-between border-t border-gray-100 px-4 py-3 text-sm text-gray-500">
      <span>{{ filteredRows.length }} registro(s)</span>
      <div class="flex items-center gap-2">
        <BaseButton variant="outline" size="sm" :disabled="page <= 1" @click="page--">Anterior</BaseButton>
        <span>{{ page }} / {{ totalPages }}</span>
        <BaseButton variant="outline" size="sm" :disabled="page >= totalPages" @click="page++">Siguiente</BaseButton>
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
