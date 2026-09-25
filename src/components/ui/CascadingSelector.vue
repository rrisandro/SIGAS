<template>
  <div class="grid gap-4 sm:grid-cols-2">
    <BaseSelect
      v-model="calleId"
      label="Calle"
      :options="calleOptions"
      placeholder="Seleccionar calle..."
      :disabled="lockCalle"
      value-type="number"
    />
    <BaseSelect
      v-model="familiaId"
      label="Familia"
      :options="familiaOptions"
      placeholder="Seleccionar familia..."
      :disabled="!calleId || lockFamilia"
      value-type="number"
    />
    <!-- ✅ value-type="string" para que no convierta '10kg' a NaN -->
    <BaseSelect
      v-model="tipoBombonaId"
      label="Tipo de bombona"
      :options="tipoOptions"
      placeholder="Seleccionar tipo..."
      value-type="string"
    />
    <!-- ✅ value-type="string" para que no convierta 'fino' a NaN -->
    <BaseSelect
      v-model="picoId"
      label="Pico"
      :options="picoOptions"
      placeholder="Seleccionar pico..."
      value-type="string"
    />
  </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue'
import BaseSelect from './BaseSelect.vue'

const props = defineProps({
  calles: { type: Array, default: () => [] },
  familias: { type: Array, default: () => [] },
  tiposBombona: { type: Array, default: () => [] },
  picos: { type: Array, default: () => [] },
  initialCalleId: { type: [Number, String], default: null },
  initialFamiliaId: { type: [Number, String], default: null },
  lockCalle: { type: Boolean, default: false },
  lockFamilia: { type: Boolean, default: false },
})

const emit = defineEmits(['selection-change'])

const calleId = ref(props.initialCalleId || '')
const familiaId = ref(props.initialFamiliaId || '')
const tipoBombonaId = ref('')
const picoId = ref('')

const calleOptions = computed(() =>
  props.calles
    .filter((c) => c.activo)
    .map((c) => ({ value: c.id_calle, label: c.nombre }))
)

const familiaOptions = computed(() => {
  if (!calleId.value) return []
  return props.familias
    .filter((f) => f.activo && f.id_calle === Number(calleId.value))
    .map((f) => ({ value: f.id, label: f.nombre_familia }))
})

const tipoOptions = computed(() =>
  props.tiposBombona.map((t) => ({ value: t.id, label: t.nombre }))
)

const picoOptions = computed(() =>
  props.picos.map((p) => ({ value: p.id, label: p.nombre }))
)

watch([calleId, familiaId, tipoBombonaId, picoId], () => {
  emitSelection()
})

function emitSelection() {
  const data = {
    calleId: calleId.value ? Number(calleId.value) : null,
    familiaId: familiaId.value ? Number(familiaId.value) : null,
    tipoBombonaId: tipoBombonaId.value || null,
    picoId: picoId.value || null,
    complete: !!(calleId.value && familiaId.value && tipoBombonaId.value && picoId.value),
  }
  emit('selection-change', data)
}

function reset() {
  if (!props.lockCalle) calleId.value = props.initialCalleId || ''
  if (!props.lockFamilia) familiaId.value = props.initialFamiliaId || ''
  tipoBombonaId.value = ''
  picoId.value = ''
  emitSelection()
}

defineExpose({ reset })
</script>