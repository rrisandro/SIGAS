<template>
  <div class="grid gap-4 sm:grid-cols-2">
    <BaseSelect
      v-model="calleId"
      label="Calle"
      :options="calleOptions"
      placeholder="Seleccionar calle..."
      :disabled="lockCalle"
    />
    <BaseSelect
      v-model="familiaId"
      label="Familia"
      :options="familiaOptions"
      placeholder="Seleccionar familia..."
      :disabled="!calleId || lockFamilia"
    />
    <BaseSelect
      v-model="tipoBombonaId"
      label="Tipo de bombona"
      :options="tipoOptions"
      placeholder="Seleccionar tipo..."
    />
    <BaseSelect
      v-model="picoId"
      label="Pico"
      :options="picoOptions"
      placeholder="Seleccionar pico..."
    />
  </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue'
import BaseSelect from './BaseSelect.vue'
import { useMockData } from '../../composables/useMockData.js'

const props = defineProps({
  initialCalleId: { type: [Number, String], default: null },
  initialFamiliaId: { type: [Number, String], default: null },
  lockCalle: { type: Boolean, default: false },
  lockFamilia: { type: Boolean, default: false },
})

const emit = defineEmits(['update'])

const { calles, familias, tiposBombona, picos } = useMockData()

const calleId = ref(props.initialCalleId || '')
const familiaId = ref(props.initialFamiliaId || '')
const tipoBombonaId = ref('')
const picoId = ref('')

const calleOptions = computed(() =>
  calles.value.filter((c) => c.activo).map((c) => ({ value: c.id, label: c.nombre }))
)

const familiaOptions = computed(() => {
  if (!calleId.value) return []
  return familias.value
    .filter((f) => f.activo && f.calleId === Number(calleId.value))
    .map((f) => ({ value: f.id, label: f.nombre }))
})

const tipoOptions = computed(() =>
  tiposBombona.value.map((t) => ({ value: t.id, label: t.nombre }))
)

const picoOptions = computed(() =>
  picos.value.map((p) => ({ value: p.id, label: p.nombre }))
)

watch(calleId, () => {
  if (!props.lockFamilia) familiaId.value = ''
  emitSelection()
})

watch([familiaId, tipoBombonaId, picoId], emitSelection)

function emitSelection() {
  emit('update', {
    calleId: calleId.value ? Number(calleId.value) : null,
    familiaId: familiaId.value ? Number(familiaId.value) : null,
    tipoBombonaId: tipoBombonaId.value ? Number(tipoBombonaId.value) : null,
    picoId: picoId.value ? Number(picoId.value) : null,
    complete: !!(calleId.value && familiaId.value && tipoBombonaId.value && picoId.value),
  })
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
