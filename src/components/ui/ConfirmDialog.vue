<template>
  <Teleport to="body">
    <div v-if="modelValue" class="confirm-root" @keydown.esc="onCancel">
      <div class="confirm-backdrop" @click="onBackdrop" />

      <div
        class="confirm-panel"
        role="dialog"
        aria-modal="true"
        :aria-label="title"
        tabindex="-1"
        @keydown.esc.stop.prevent="onCancel"
      >
        <span class="confirm-handle" aria-hidden="true" />

        <div class="confirm-head">
          <div class="confirm-icon" :class="`confirm-icon--${tone}`" aria-hidden="true">
            <svg v-if="tone === 'danger'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v4m0 4h.01M10.29 3.86 1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" />
            </svg>
            <svg v-else-if="tone === 'success'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M20 6 9 17l-5-5" />
            </svg>
            <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="9" />
              <path stroke-linecap="round" d="M12 8h.01M11 12h1v4h1" />
            </svg>
          </div>

          <div class="confirm-copy">
            <h3 class="confirm-title">{{ title }}</h3>
            <p v-if="message" class="confirm-message">{{ message }}</p>
          </div>
        </div>

        <div v-if="$slots.default" class="confirm-body">
          <slot />
        </div>

        <p v-if="error" class="confirm-error" role="alert">{{ error }}</p>

        <div class="confirm-actions">
          <BaseButton variant="ghost" :disabled="loading" @click="onCancel">
            {{ cancelText }}
          </BaseButton>
          <BaseButton
            :variant="confirmVariant"
            :loading="loading"
            :disabled="loading || confirmDisabled"
            @click="onConfirm"
          >
            {{ confirmText }}
          </BaseButton>
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
  title: { type: String, default: 'Confirmar acción' },
  message: { type: String, default: '' },
  confirmText: { type: String, default: 'Confirmar' },
  cancelText: { type: String, default: 'Cancelar' },
  confirmVariant: { type: String, default: 'primary' },
  tone: { type: String, default: 'warning' },
  loading: { type: Boolean, default: false },
  error: { type: String, default: '' },
  confirmDisabled: { type: Boolean, default: false },
})

const emit = defineEmits(['update:modelValue', 'confirm', 'cancel'])

watch(
  () => props.modelValue,
  (open) => {
    document.body.classList.toggle('modal-open', open)
  },
  { immediate: true }
)

onBeforeUnmount(() => {
  document.body.classList.remove('modal-open')
})

function onCancel() {
  if (props.loading) return
  emit('update:modelValue', false)
  emit('cancel')
}

function onBackdrop() {
  if (!props.loading) onCancel()
}

function onConfirm() {
  if (props.loading || props.confirmDisabled) return
  emit('confirm')
}
</script>

<style scoped>
.confirm-root {
  position: fixed;
  inset: 0;
  z-index: 1200;
  display: flex;
  align-items: flex-end;
  justify-content: center;
}

.confirm-backdrop {
  position: absolute;
  inset: 0;
  background: rgba(2, 6, 23, 0.62);
  backdrop-filter: blur(5px);
  -webkit-backdrop-filter: blur(5px);
  animation: confirmFade 0.18s ease-out;
}

.confirm-panel {
  position: relative;
  z-index: 1;
  width: 100%;
  max-height: 90dvh;
  padding: 12px 16px calc(18px + var(--safe-bottom));
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
  background: #ffffff;
  border-radius: 24px 24px 0 0;
  box-shadow: 0 -18px 60px rgba(2, 6, 23, 0.32);
  animation: confirmSheetUp 0.24s cubic-bezier(0.2, 0.9, 0.3, 1);
  outline: none;
}

.confirm-handle {
  display: block;
  width: 42px;
  height: 4px;
  margin: 0 auto 16px;
  border-radius: 999px;
  background: #e2e8f0;
}

.confirm-head {
  display: flex;
  align-items: flex-start;
  gap: 14px;
}

.confirm-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 46px;
  height: 46px;
  border-radius: 14px;
  background: #fffbeb;
  color: #d97706;
}

.confirm-icon--danger {
  background: #fef2f2;
  color: #dc2626;
}

.confirm-icon--success {
  background: #ecfdf5;
  color: #059669;
}

.confirm-icon svg {
  width: 23px;
  height: 23px;
}

.confirm-copy {
  min-width: 0;
}

.confirm-title {
  margin: 0;
  color: #0f172a;
  font-size: 1.1rem;
  font-weight: 700;
  line-height: 1.3;
}

.confirm-message {
  margin: 6px 0 0;
  color: #64748b;
  font-size: 0.9rem;
  line-height: 1.55;
}

.confirm-body {
  margin-top: 18px;
}

.confirm-error {
  margin: 14px 0 0;
  padding: 10px 12px;
  border: 1px solid #fecaca;
  border-radius: 10px;
  background: #fef2f2;
  color: #b91c1c;
  font-size: 0.84rem;
  line-height: 1.45;
}

.confirm-actions {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-top: 22px;
}

.confirm-actions :deep(.btn-custom) {
  width: 100%;
}

@keyframes confirmFade {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes confirmSheetUp {
  from { transform: translateY(20px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

@media (min-width: 640px) {
  .confirm-root {
    align-items: center;
    padding: 20px;
  }

  .confirm-panel {
    width: 100%;
    max-width: 480px;
    max-height: 88vh;
    padding: 22px;
    border-radius: 20px;
    animation: confirmScaleIn 0.2s ease-out;
  }

  .confirm-handle {
    display: none;
  }

  .confirm-actions {
    flex-direction: row;
    justify-content: flex-end;
  }

  .confirm-actions :deep(.btn-custom) {
    width: auto;
  }
}

@keyframes confirmScaleIn {
  from { transform: scale(0.96); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}
</style>
