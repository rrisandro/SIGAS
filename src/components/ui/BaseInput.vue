<template>
  <div class="base-field">
    <label v-if="label" :for="id" class="base-label">{{ label }}</label>
    <input
      :id="id"
      :type="type"
      :value="modelValue"
      :placeholder="placeholder"
      :disabled="disabled"
      :required="required"
      :maxlength="maxlength"
      :inputmode="inputmode || undefined"
      :autocomplete="autocomplete || undefined"
      :aria-invalid="Boolean(error)"
      class="base-input"
      :class="{ 'base-input--error': error }"
      @input="onInput"
      @blur="onBlur"
    />
    <p v-if="error" class="base-error" role="alert">{{ error }}</p>
    <p v-else-if="hint" class="base-hint">{{ hint }}</p>
  </div>
</template>

<script setup>
import { LIMITS, limpiarPorTipo } from '../../lib/validation.js'

const props = defineProps({
  modelValue: { type: [String, Number], default: '' },
  label: { type: String, default: '' },
  type: { type: String, default: 'text' },
  placeholder: { type: String, default: '' },
  hint: { type: String, default: '' },
  error: { type: String, default: '' },
  id: { type: String, default: undefined },
  disabled: { type: Boolean, default: false },
  required: { type: Boolean, default: false },
  maxlength: { type: [String, Number], default: LIMITS.nombre },
  restrict: { type: String, default: 'texto' },
  inputmode: { type: String, default: '' },
  autocomplete: { type: String, default: '' },
})

const emit = defineEmits(['update:modelValue'])

function onInput(event) {
  const max = Number(props.maxlength) || LIMITS.nombre
  const limpio = limpiarPorTipo(event.target.value, props.restrict, max)

  if (event.target.value !== limpio) {
    event.target.value = limpio
  }

  emit('update:modelValue', limpio)
}

function onBlur(event) {
  if (props.restrict === 'password') return

  const recortado = String(event.target.value ?? '').trim()
  if (recortado === event.target.value) return

  event.target.value = recortado
  emit('update:modelValue', recortado)
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

.base-input {
  display: block;
  width: 100%;
  min-width: 0;
  height: 44px;
  padding: 0 12px;
  border: 1px solid #d1d5db;
  border-radius: 11px;
  background: #ffffff;
  color: var(--color-text);
  font-family: inherit;
  font-size: 16px;
  line-height: 1.4;
  outline: none;
  -webkit-appearance: none;
  appearance: none;
  transition: border-color var(--transition-fast), box-shadow var(--transition-fast),
    background-color var(--transition-fast);
}

.base-input::placeholder {
  color: var(--color-muted-light);
}

.base-input:hover:not(:disabled) {
  border-color: #bae6fd;
}

.base-input:focus {
  border-color: var(--color-primary);
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.14);
}

.base-input:disabled {
  background: var(--color-bg);
  color: var(--color-muted);
  cursor: not-allowed;
}

.base-input--error {
  border-color: #dc2626;
  background: #fef2f2;
}

.base-input--error:focus {
  border-color: #dc2626;
  box-shadow: 0 0 0 3px rgba(220, 38, 38, 0.14);
}

.base-hint {
  margin-top: 5px;
  color: var(--color-muted);
  font-size: 0.75rem;
  line-height: 1.4;
}

.base-error {
  margin-top: 5px;
  color: #dc2626;
  font-size: 0.75rem;
  line-height: 1.4;
}

@media (min-width: 640px) {
  .base-input {
    height: 40px;
    font-size: 15px;
    border-radius: 10px;
  }
}

@media (min-width: 1024px) {
  .base-input {
    height: 38px;
    padding: 0 12px;
    font-size: 14px;
  }
}
</style>
