<template>
  <div class="w-full">
    <label v-if="label" class="mb-1.5 block text-sm font-medium text-gray-700">{{ label }}</label>
    <input
      :id="id"
      :type="type"
      :value="modelValue"
      :placeholder="placeholder"
      :disabled="disabled"
      :required="required"
      class="w-full rounded-xl border border-gray-200 bg-white px-3.5 py-2.5 text-sm text-gray-700 placeholder:text-gray-400 outline-none transition focus:border-sky-400 focus:ring-2 focus:ring-sky-100 disabled:bg-gray-50 disabled:text-gray-500"
      @input="$emit('update:modelValue', $event.target.value)"
    />
    <p v-if="hint" class="mt-1 text-xs text-gray-500">{{ hint }}</p>
  </div>
</template>

<script setup>
defineProps({
  modelValue: { type: [String, Number], default: '' },
  label: { type: String, default: '' },
  type: { type: String, default: 'text' },
  placeholder: { type: String, default: '' },
  hint: { type: String, default: '' },
  id: { type: String, default: undefined },
  disabled: { type: Boolean, default: false },
  required: { type: Boolean, default: false },
})

defineEmits(['update:modelValue'])
</script>
