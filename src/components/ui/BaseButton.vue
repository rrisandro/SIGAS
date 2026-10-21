<template>
  <button
    :type="type"
    :disabled="disabled || loading"
    :class="[
      'btn-custom',
      `btn-${variant}`,
      `btn-${size}`,
      { 'btn-loading': loading }
    ]"
    @click="$emit('click', $event)"
  >
    <!-- Spinner -->
    <svg
      v-if="loading"
      class="btn-spinner"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      aria-hidden="true"
    >
      <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
      <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z" />
    </svg>

    <slot />
  </button>
</template>

<script setup>
defineProps({
  variant: {
    type: String,
    default: 'primary',
    validator: (v) => ['primary', 'secondary', 'outline', 'ghost', 'danger', 'success', 'warning'].includes(v)
  },
  size: {
    type: String,
    default: 'md',
    validator: (v) => ['sm', 'md', 'lg'].includes(v)
  },
  type: { type: String, default: 'button' },
  disabled: { type: Boolean, default: false },
  loading: { type: Boolean, default: false }
})

defineEmits(['click'])
</script>

<style scoped>
/* ============================================
   Base · mobile-first
   ============================================ */
.btn-custom {
  --btn-color: var(--color-primary);
  --btn-color-hover: var(--color-primary-dark);
  --btn-shadow: rgba(14, 165, 233, 0.25);

  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.45rem;

  width: auto;
  max-width: 100%;
  min-width: 44px;
  min-height: 44px;
  padding: 12px 20px;

  border: 1.5px solid var(--btn-color);
  border-radius: 12px;
  background: #ffffff;
  color: var(--btn-color);

  font-size: 0.9375rem;
  font-weight: 600;
  line-height: 1.2;
  text-align: center;
  white-space: nowrap;

  cursor: pointer;
  user-select: none;
  touch-action: manipulation;
  -webkit-tap-highlight-color: transparent;
  transition: background-color var(--transition-fast), border-color var(--transition-fast),
    color var(--transition-fast), box-shadow var(--transition-fast), transform 120ms ease;
}

.btn-custom:active:not(:disabled) {
  transform: scale(0.98);
}

.btn-custom:focus-visible {
  outline: 2px solid var(--btn-color);
  outline-offset: 2px;
}

/* En dispositivos táctiles evitamos estados hover persistentes */
@media (hover: hover) and (pointer: fine) {
  .btn-custom:hover:not(:disabled) {
    background: var(--btn-color);
    border-color: var(--btn-color);
    color: #ffffff;
    box-shadow: 0 4px 14px var(--btn-shadow);
  }
}

/* ============================================
   Tamaños
   ============================================ */
.btn-sm {
  min-width: 44px;
  min-height: 44px;
  padding: 10px 14px;
  border-radius: 10px;
  font-size: 0.82rem;
}

.btn-md {
  min-height: 44px;
  padding: 12px 20px;
  font-size: 0.9375rem;
}

.btn-lg {
  min-height: 48px;
  padding: 14px 24px;
  border-radius: 14px;
  font-size: 1rem;
}

/* ============================================
   Variantes de color · paleta SIGAS
   ============================================ */
.btn-primary {
  --btn-color: #0ea5e9;
  --btn-color-hover: #0284c7;
  --btn-shadow: rgba(14, 165, 233, 0.3);
}

.btn-secondary {
  --btn-color: #6b7280;
  --btn-color-hover: #4b5563;
  --btn-shadow: rgba(107, 114, 128, 0.25);
}

.btn-danger {
  --btn-color: #ef4444;
  --btn-color-hover: #dc2626;
  --btn-shadow: rgba(239, 68, 68, 0.3);
}

.btn-success {
  --btn-color: #10b981;
  --btn-color-hover: #059669;
  --btn-shadow: rgba(16, 185, 129, 0.3);
}

.btn-warning {
  --btn-color: #f59e0b;
  --btn-color-hover: #d97706;
  --btn-shadow: rgba(245, 158, 11, 0.3);
}

.btn-outline {
  --btn-color: #d1d5db;
  --btn-color-hover: #9ca3af;
  --btn-shadow: rgba(107, 114, 128, 0.18);

  border-color: #d1d5db;
  background: #ffffff;
  color: #374151;
}

@media (hover: hover) and (pointer: fine) {
  .btn-outline:hover:not(:disabled) {
    background: #f3f4f6;
    border-color: #9ca3af;
    color: #111827;
    box-shadow: var(--btn-shadow);
  }
}

.btn-ghost {
  --btn-color: transparent;
  --btn-color-hover: transparent;
  --btn-shadow: transparent;

  border-color: transparent;
  background: transparent;
  color: #374151;
}

@media (hover: hover) and (pointer: fine) {
  .btn-ghost:hover:not(:disabled) {
    background: #f3f4f6;
    border-color: transparent;
    color: #111827;
    box-shadow: none;
  }
}

/* ============================================
   Estados
   ============================================ */
.btn-custom:disabled {
  opacity: 0.5;
  cursor: not-allowed;
  box-shadow: none;
  transform: none;
}

.btn-loading {
  cursor: wait;
}

.btn-spinner {
  flex-shrink: 0;
  width: 1em;
  height: 1em;
  animation: btn-spin 1s linear infinite;
}

@keyframes btn-spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}

/* ============================================
   Tablet
   ============================================ */
@media (min-width: 640px) {
  .btn-custom {
    min-width: 40px;
    min-height: 40px;
    padding: 10px 18px;
    font-size: 0.9rem;
  }

  .btn-sm {
    min-height: 40px;
    padding: 8px 14px;
    font-size: 0.8rem;
  }

  .btn-md {
    min-height: 40px;
    padding: 10px 18px;
  }

  .btn-lg {
    min-height: 46px;
    padding: 12px 22px;
  }
}

/* ============================================
   Desktop
   ============================================ */
@media (min-width: 1024px) {
  .btn-custom {
    min-width: 36px;
    min-height: 36px;
    padding: 8px 16px;
    font-size: 0.875rem;
  }

  .btn-sm {
    min-height: 32px;
    padding: 6px 12px;
    font-size: 0.78rem;
  }

  .btn-md {
    min-height: 36px;
    padding: 8px 16px;
  }

  .btn-lg {
    min-height: 44px;
    padding: 10px 20px;
    font-size: 0.95rem;
  }
}
</style>
