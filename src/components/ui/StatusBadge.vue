<template>
  <span :class="['inline-flex items-center rounded-full px-2.5 py-0.5 text-xs font-medium', badgeClass]">
    {{ label }}
  </span>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  status: { type: String, required: true },
})

const map = {
  pendiente: { label: 'Pendiente', class: 'bg-amber-100 text-amber-800' },
  en_proceso: { label: 'En proceso', class: 'bg-blue-100 text-blue-800' },
  entregado: { label: 'Entregado', class: 'bg-emerald-100 text-emerald-800' },
  rechazado: { label: 'Rechazado', class: 'bg-rose-100 text-rose-800' },
  completado: { label: 'Completado', class: 'bg-emerald-100 text-emerald-800' },
  en_progreso: { label: 'En progreso', class: 'bg-blue-100 text-blue-800' },
  planificado: { label: 'Planificado', class: 'bg-sky-100 text-sky-800' },
  activo: { label: 'Activo', class: 'bg-emerald-100 text-emerald-800' },
  inactivo: { label: 'Inactivo', class: 'bg-gray-100 text-gray-600' },
}

const label = computed(() => map[props.status]?.label || props.status)
const badgeClass = computed(() => map[props.status]?.class || 'bg-gray-100 text-gray-600')
</script>
