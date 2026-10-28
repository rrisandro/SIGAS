<template>
  <span :class="['status-badge', badgeClass]">
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
  aceptado: { label: 'Aceptado', class: 'bg-blue-100 text-blue-800' },
  entregado: { label: 'Entregado', class: 'bg-emerald-100 text-emerald-800' },
  rechazado: { label: 'Rechazado', class: 'bg-rose-100 text-rose-800' },
  completado: { label: 'Completado', class: 'bg-emerald-100 text-emerald-800' },
  cerrado: { label: 'Cerrado', class: 'bg-emerald-100 text-emerald-800' },
  sin_estado: { label: 'Sin estado', class: 'bg-gray-100 text-gray-600' },
  en_progreso: { label: 'En progreso', class: 'bg-blue-100 text-blue-800' },
  planificado: { label: 'Planificado', class: 'bg-sky-100 text-sky-800' },
  activo: { label: 'Activo', class: 'bg-emerald-100 text-emerald-800' },
  inactivo: { label: 'Inactivo', class: 'bg-gray-100 text-gray-600' },
}

const label = computed(() => map[props.status]?.label || props.status)
const badgeClass = computed(() => map[props.status]?.class || 'bg-gray-100 text-gray-600')
</script>

<style scoped>
.status-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: fit-content;
  padding: 3px 8px;
  border-radius: 999px;
  font-size: 11px;
  font-weight: 600;
  line-height: 1.4;
  white-space: nowrap;
}

@media (min-width: 640px) {
  .status-badge {
    padding: 4px 10px;
    font-size: 12px;
  }
}
</style>
