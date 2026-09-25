]<template>
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
    validator: (v) => ['primary', 'secondary', 'outline', 'ghost', 'danger', 'success'].includes(v)
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
   ESTILO BASE (tu diseño adaptado)
   ============================================ */
.btn-custom {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  
  /* Tamaño base ajustado (más pequeño que 150x60) */
  width: 130px;
  height: 45px;
  
  border: 3px solid #315cfd;
  border-radius: 45px;
  background: white;
  color: #315cfd;
  
  font-size: 0.95em;
  font-weight: 550;
  
  cursor: pointer;
  transition: all 0.3s ease;
}

/* ============================================
   EFECTO HOVER (tu animación)
   ============================================ */
.btn-custom:hover:not(:disabled) {
  background: #315cfd;
  color: white;
  font-size: 1.1em;
  box-shadow: 0 4px 15px rgba(49, 92, 253, 0.4);
}

/* ============================================
   TAMAÑOS
   ============================================ */
.btn-sm {
  width: 100px;
  height: 36px;
  font-size: 0.8em;
  border-width: 2px;
}
.btn-sm:hover:not(:disabled) {
  font-size: 0.95em;
}

.btn-md {
  width: 130px;
  height: 45px;
  font-size: 0.95em;
}
.btn-md:hover:not(:disabled) {
  font-size: 1.1em;
}

.btn-lg {
  width: 170px;
  height: 55px;
  font-size: 1.1em;
}
.btn-lg:hover:not(:disabled) {
  font-size: 1.3em;
}

/* ============================================
   VARIANTES DE COLOR
   ============================================ */
.btn-primary {
  border-color: #315cfd;
  color: #315cfd;
}
.btn-primary:hover:not(:disabled) {
  background: #315cfd;
  color: white;
}

.btn-secondary {
  border-color: #6b7280;
  color: #6b7280;
}
.btn-secondary:hover:not(:disabled) {
  background: #6b7280;
  color: white;
}

.btn-danger {
  border-color: #ef4444;
  color: #ef4444;
}
.btn-danger:hover:not(:disabled) {
  background: #ef4444;
  color: white;
  box-shadow: 0 4px 15px rgba(239, 68, 68, 0.4);
}

.btn-success {
  border-color: #10b981;
  color: #10b981;
}
.btn-success:hover:not(:disabled) {
  background: #10b981;
  color: white;
  box-shadow: 0 4px 15px rgba(16, 185, 129, 0.4);
}

.btn-outline {
  border-color: #d1d5db;
  color: #374151;
  background: white;
}
.btn-outline:hover:not(:disabled) {
  background: #f3f4f6;
  color: #111827;
  border-color: #9ca3af;
}

.btn-ghost {
  border-color: transparent;
  color: #374151;
  background: transparent;
}
.btn-ghost:hover:not(:disabled) {
  background: #f3f4f6;
  color: #111827;
}

/* ============================================
   ESTADOS
   ============================================ */
.btn-custom:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.btn-custom:active:not(:disabled) {
  transform: scale(0.97);
}

.btn-loading {
  cursor: wait;
}

/* ============================================
   SPINNER
   ============================================ */
.btn-spinner {
  width: 1em;
  height: 1em;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
</style>