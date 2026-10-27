<template>
  <Teleport to="body">
    <div v-if="modelValue" class="modal-root">
      <div class="modal-backdrop animate-fadeIn" @click="onCancel" />

      <div
        class="modal-panel animate-slideUp"
        role="dialog"
        aria-modal="true"
        :aria-label="title"
      >
        <span class="modal-handle" aria-hidden="true" />

        <h3 class="modal-title">{{ title }}</h3>
        <p class="modal-message">{{ message }}</p>

        <div class="modal-actions">
          <BaseButton variant="ghost" @click="onCancel">{{ cancelText }}</BaseButton>
          <BaseButton :variant="confirmVariant" @click="onConfirm">{{ confirmText }}</BaseButton>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { onBeforeUnmount, watch } from 'vue'
import BaseButton from './BaseButton.vue'

const props = defineProps({
  modelValue: { type: Boolean, default: false },
  title: { type: String, default: 'Confirmar' },
  message: { type: String, default: '¿Deseas continuar?' },
  confirmText: { type: String, default: 'Confirmar' },
  cancelText: { type: String, default: 'Cancelar' },
  confirmVariant: { type: String, default: 'primary' },
})

const emit = defineEmits(['update:modelValue', 'confirm', 'cancel'])

watch(
  () => props.modelValue,
  (open) => {
    document.body.classList.toggle('modal-open', open)
  }
)

onBeforeUnmount(() => {
  document.body.classList.remove('modal-open')
})

function onCancel() {
  emit('update:modelValue', false)
  emit('cancel')
}

function onConfirm() {
  emit('confirm')
  emit('update:modelValue', false)
}
</script>

<style scoped>
.modal-root {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

.modal-backdrop {
  position: absolute;
  inset: 0;
  background: rgba(15, 23, 42, 0.52);
  backdrop-filter: blur(3px);
  -webkit-backdrop-filter: blur(3px);
}

.modal-panel {
  position: relative;
  z-index: 1;
  width: 100%;
  max-height: 85dvh;
  padding: 12px 16px calc(18px + var(--safe-bottom));
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
  background: #ffffff;
  border-radius: 22px 22px 0 0;
  box-shadow: 0 -12px 40px rgba(15, 23, 42, 0.2);
  animation: slideUp 0.22s ease-out;
}

.modal-handle {
  display: block;
  width: 40px;
  height: 4px;
  margin: 0 auto 14px;
  border-radius: 999px;
  background: #e2e8f0;
}

.modal-title {
  color: var(--color-heading);
  font-size: 1.05rem;
  font-weight: 700;
  line-height: 1.3;
}

.modal-message {
  margin-top: 8px;
  color: var(--color-muted);
  font-size: 0.875rem;
  line-height: 1.55;
}

.modal-actions {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-top: 22px;
}

.modal-actions :deep(.btn-custom) {
  width: 100%;
}

@media (min-width: 640px) {
  .modal-root {
    align-items: center;
    padding: 20px;
  }

  .modal-panel {
    width: 100%;
    max-width: 480px;
    max-height: 85vh;
    padding: 20px;
    border-radius: 16px;
    box-shadow: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);
    animation: scaleIn 0.2s ease-out;
  }

  .modal-handle {
    display: none;
  }

  .modal-title {
    font-size: 1.125rem;
  }

  .modal-actions {
    flex-direction: row;
    justify-content: flex-end;
    margin-top: 24px;
  }

  .modal-actions :deep(.btn-custom) {
    width: auto;
  }
}

@media (min-width: 1024px) {
  .modal-panel {
    max-width: 520px;
    padding: 24px;
  }
}
</style>
