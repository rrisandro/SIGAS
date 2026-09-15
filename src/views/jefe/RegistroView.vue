<template>
  <div class="mx-auto max-w-3xl space-y-6">
    <div>
      <h2 class="text-xl font-medium text-gray-700">Registro Presencial</h2>
      <p class="text-sm text-gray-500">Registra una solicitud rápida para una familia de tu calle</p>
    </div>

    <div class="rounded-2xl border border-gray-100 bg-white p-6 shadow-sm">
      <CascadingSelector
        ref="selectorRef"
        :initial-calle-id="jefe?.calleId"
        lock-calle
        @update="selection = $event"
      />
      <BaseInput v-model="observaciones" class="mt-4" label="Observaciones" placeholder="Opcional" />
      <p v-if="success" class="mt-4 text-sm text-emerald-600">{{ success }}</p>
      <div class="mt-6 flex justify-end">
        <BaseButton :disabled="!selection.complete" @click="submit">Registrar</BaseButton>
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
const { jefes, findById, addSolicitud, addAuditoria, getFamiliaNombre } = useMockData()

const selectorRef = ref(null)
const selection = ref({ complete: false })
const observaciones = ref('')
const success = ref('')

const jefe = computed(() => findById(jefes, currentUser.value?.entidadId))

function submit() {
  if (!selection.value.complete) return
  const item = addSolicitud({
    familiaId: selection.value.familiaId,
    tipoBombonaId: selection.value.tipoBombonaId,
    picoId: selection.value.picoId,
    observaciones: observaciones.value || 'Registro presencial',
    estatus: 'en_proceso',
  })
  addAuditoria({
    usuario: currentUser.value.username,
    accion: 'Registrar',
    entidad: 'Solicitud Presencial',
    detalle: `Solicitud para ${getFamiliaNombre(selection.value.familiaId)}`,
  })
  success.value = `Solicitud #${item.id} registrada`
  observaciones.value = ''
  selectorRef.value?.reset()
}
</script>
