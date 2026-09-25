<template>
  <label class="switch">
    <!-- 1. Usamos el input y vinculamos su estado a modelValue -->
    <input 
      type="checkbox" 
      :checked="modelValue" 
      :disabled="disabled"
      @change="$emit('update:modelValue', $event.target.checked)"
    >
    <span class="slider"></span>
  </label>
</template>

<script setup>
defineProps({
  modelValue: { type: Boolean, default: false },
  disabled: { type: Boolean, default: false },
})

defineEmits(['update:modelValue'])
</script>

<style scoped> /* Te recomiendo añadir 'scoped' para no afectar otros componentes */
/* The switch - the box around the slider */
.switch {
  font-size: 17px;
  position: relative;
  display: inline-block;
  width: 3.5em;
  height: 2em;
}

/* Hide default HTML checkbox */
.switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

/* The slider */
.slider {
  position: absolute;
  cursor: pointer;
  inset: 0;
  background: #9fccfa;
  border-radius: 50px;
  transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

.slider:before {
  position: absolute;
  content: "";
  display: flex;
  align-items: center;
  justify-content: center;
  height: 2em;
  width: 2em;
  left: 0; /* Cambiado de inset: 0 para que empiece a la izquierda */
  top: 0;
  background-color: white;
  border-radius: 50px;
  box-shadow: 0 10px 20px rgba(0,0,0,0.4);
  transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
}

.switch input:checked + .slider {
  background: #0974f1;
}

.switch input:focus + .slider {
  box-shadow: 0 0 1px #0974f1;
}

/* Ajusté el translateX a 1.5em para que encaje perfecto en el ancho de 3.5em */
.switch input:checked + .slider:before {
  transform: translateX(1.5em); 
}

/* Estilos para cuando está deshabilitado */
.switch input:disabled + .slider {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>