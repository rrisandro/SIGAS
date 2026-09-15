<template>
  <button
    :type="type"
    :disabled="disabled || loading"
    :class="buttonClass"
    @click="$emit('click', $event)"
  >
    <span v-if="loading" class="inline-block h-4 w-4 animate-spin rounded-full border-2 border-white/40 border-t-white" />
    <slot />
  </button>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  variant: { type: String, default: 'primary' },
  size: { type: String, default: 'md' },
  type: { type: String, default: 'button' },
  disabled: { type: Boolean, default: false },
  loading: { type: Boolean, default: false },
  block: { type: Boolean, default: false },
})

defineEmits(['click'])

const variants = {
  primary: 'bg-sky-500 text-white hover:bg-sky-600 shadow-sm',
  success: 'bg-emerald-400 text-white hover:bg-emerald-500 shadow-sm',
  danger: 'bg-rose-400 text-white hover:bg-rose-500 shadow-sm',
  warning: 'bg-amber-400 text-white hover:bg-amber-500 shadow-sm',
  ghost: 'bg-transparent text-gray-700 hover:bg-gray-100',
  outline: 'bg-white text-gray-700 border border-gray-200 hover:bg-gray-50',
}

const sizes = {
  sm: 'px-3 py-1.5 text-sm',
  md: 'px-4 py-2 text-sm',
  lg: 'px-5 py-2.5 text-base',
}

const buttonClass = computed(() => [
  'inline-flex items-center justify-center gap-2 font-medium rounded-xl transition-colors duration-150 disabled:opacity-50 disabled:cursor-not-allowed',
  variants[props.variant] || variants.primary,
  sizes[props.size] || sizes.md,
  props.block ? 'w-full' : '',
])
</script>
