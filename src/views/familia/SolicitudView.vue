<template>
  <div class="mx-auto max-w-3xl space-y-6">
    <div>
      <h2 class="text-xl font-medium text-gray-700">Solicitar Gas</h2>
      <p class="text-sm text-gray-500">Completa el formulario en cascada para registrar tu solicitud</p>
    </div>

    <div class="rounded-2xl border border-gray-100 bg-white p-6 shadow-sm">
      <CascadingSelector
        ref="selectorRef"
        :initial-calle-id="familia?.calleId"
        :initial-familia-id="currentUser?.entidadId"
        lock-calle
        lock-familia
        @update="selection = $event"
      />

      <BaseInput
        v-model="observaciones"
        class="mt-4"
        label="Observaciones"
        placeholder="Opcional"
      />

      <p v-if="success" class="mt-4 text-sm text-emerald-600">{{ success }}</p>
      <p v-if="error" class="mt-4 text-sm text-rose-500">{{ error }}</p>

      <div class="mt-6 flex justify-end">
        <BaseButton :disabled="!selection.complete" @click="submit">
          Enviar solicitud
        </BaseButton>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from 'vue'
import CascadingSelector from '../../components/ui/CascadingSelector.vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import { useAuth } from '../../composables/useAuth.js'
import { useMockData } from '../../composables/useMockData.js'

const { currentUser } = useAuth()
const { familias, addSolicitud, addAuditoria, findById } = useMockData()

const selectorRef = ref(null)
const selection = ref({ complete: false })
const observaciones = ref('')
const success = ref('')
const error = ref('')

const familia = computed(() => findById(familias, currentUser.value?.entidadId))

function submit() {
  error.value = ''
  success.value = ''
  if (!selection.value.complete) {
    error.value = 'Completa todos los campos'
    return
  }
  const item = addSolicitud({
    familiaId: selection.value.familiaId,
    tipoBombonaId: selection.value.tipoBombonaId,
    picoId: selection.value.picoId,
    observaciones: observaciones.value,
  })
  addAuditoria({
    usuario: currentUser.value.username,
    accion: 'Crear',
    entidad: `Solicitud #${item.id}`,
    detalle: 'Nueva solicitud de gas doméstico',
  })
  success.value = `Solicitud #${item.id} registrada correctamente`
  observaciones.value = ''
  selectorRef.value?.reset()
}
</script>
