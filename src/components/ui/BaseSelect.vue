<template>
  <div class="w-full">
    <label v-if="label" class="mb-1.5 block text-sm font-medium text-gray-700">{{ label }}</label>
    <select
      :value="modelValue === '' || modelValue === null || modelValue === undefined ? '' : String(modelValue)"
      :disabled="disabled"
      :required="required"
      class="w-full rounded-xl border border-gray-200 bg-white px-3.5 py-2.5 text-sm text-gray-700 outline-none transition focus:border-sky-400 focus:ring-2 focus:ring-sky-100 disabled:bg-gray-50 disabled:text-gray-500"
      @change="onChange"
    >
      <option value="" disabled>{{ placeholder }}</option>
      <option v-for="opt in options" :key="String(opt.value)" :value="String(opt.value)">
        {{ opt.label }}
      </option>
    </select>
  </div>
</template>

<script setup>
const props = defineProps({
  modelValue: { type: [String, Number], default: '' },
  label: { type: String, default: '' },
  options: { type: Array, default: () => [] },
  placeholder: { type: String, default: 'Seleccionar...' },
  disabled: { type: Boolean, default: false },
  required: { type: Boolean, default: false },
  valueType: { type: String, default: 'number' },
})

const emit = defineEmits(['update:modelValue'])

function onChange(event) {
  const raw = event.target.value
  if (raw === '') {
    emit('update:modelValue', '')
    return
  }
  emit('update:modelValue', props.valueType === 'number' ? Number(raw) : raw)
}
</script>
