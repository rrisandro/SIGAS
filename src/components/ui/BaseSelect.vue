<template>
  <div class="base-field">
    <label v-if="label" class="base-label">{{ label }}</label>
    <div class="base-select-wrap">
      <select
        :value="modelValue === '' || modelValue === null || modelValue === undefined ? '' : String(modelValue)"
        :disabled="disabled"
        :required="required"
        class="base-select"
        @change="onChange"
      >
        <option value="" disabled>{{ placeholder }}</option>
        <option v-for="opt in options" :key="String(opt.value)" :value="String(opt.value)">
          {{ opt.label }}
        </option>
      </select>
    </div>
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

<style scoped>
.base-field {
  display: flex;
  flex-direction: column;
  width: 100%;
  min-width: 0;
}

.base-label {
  display: block;
  margin-bottom: 6px;
  color: var(--color-text);
  font-size: 0.8125rem;
  font-weight: 600;
  line-height: 1.35;
}

.base-select-wrap {
  position: relative;
  width: 100%;
}

.base-select-wrap::after {
  content: '';
  position: absolute;
  top: 50%;
  right: 14px;
  width: 8px;
  height: 8px;
  border-right: 2px solid var(--color-muted);
  border-bottom: 2px solid var(--color-muted);
  transform: translateY(-65%) rotate(45deg);
  pointer-events: none;
}

.base-select {
  display: block;
  width: 100%;
  min-width: 0;
  height: 44px;
  padding: 0 38px 0 12px;
  border: 1px solid #d1d5db;
  border-radius: 11px;
  background: #ffffff;
  color: var(--color-text);
  font-family: inherit;
  font-size: 16px;
  line-height: 1.4;
  outline: none;
  cursor: pointer;
  -webkit-appearance: none;
  appearance: none;
  transition: border-color var(--transition-fast), box-shadow var(--transition-fast),
    background-color var(--transition-fast);
}

.base-select:hover:not(:disabled) {
  border-color: #bae6fd;
}

.base-select:focus {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.14);
}

.base-select:disabled {
  background: var(--color-bg);
  color: var(--color-muted);
  cursor: not-allowed;
  opacity: 1;
}

@media (min-width: 640px) {
  .base-select {
    height: 40px;
    font-size: 15px;
    border-radius: 10px;
  }
}

@media (min-width: 1024px) {
  .base-select {
    height: 38px;
    font-size: 14px;
  }
}
</style>
