<template>
  <Teleport to="body">
    <div
      v-if="modelValue"
      class="fixed inset-0 z-50 flex items-center justify-center p-4"
    >
      <div class="absolute inset-0 bg-gray-700/30 animate-fadeIn" @click="onCancel" />
      <div class="relative w-full max-w-md rounded-2xl bg-white p-6 shadow-xl animate-scaleIn">
        <h3 class="text-lg font-medium text-gray-700">{{ title }}</h3>
        <p class="mt-2 text-sm text-gray-500">{{ message }}</p>
        <div class="mt-6 flex justify-end gap-3">
          <BaseButton variant="ghost" @click="onCancel">{{ cancelText }}</BaseButton>
          <BaseButton :variant="confirmVariant" @click="onConfirm">{{ confirmText }}</BaseButton>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import BaseButton from './BaseButton.vue'

defineProps({
  modelValue: { type: Boolean, default: false },
  title: { type: String, default: 'Confirmar' },
  message: { type: String, default: '¿Deseas continuar?' },
  confirmText: { type: String, default: 'Confirmar' },
  cancelText: { type: String, default: 'Cancelar' },
  confirmVariant: { type: String, default: 'primary' },
})

const emit = defineEmits(['update:modelValue', 'confirm', 'cancel'])

function onCancel() {
  emit('update:modelValue', false)
  emit('cancel')
}

function onConfirm() {
  emit('confirm')
  emit('update:modelValue', false)
}
</script>
