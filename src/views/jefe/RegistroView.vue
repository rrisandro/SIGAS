<template>
  <div class="p-6 max-w-4xl mx-auto">
    <h2 class="text-2xl font-bold mb-2 text-gray-800">Registro de Solicitud</h2>
    <p class="text-sm text-gray-500 mb-6">Gestión de calle</p>

    <div v-if="jefe" class="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
      <p class="text-sm text-gray-600">
        Jefe de calle: <span class="font-medium text-blue-700">{{ jefe.nombre }}</span>
      </p>
    </div>

    <div class="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      <CascadingSelector
        ref="selectorRef"
        :calles="calles"
        :familias="familias"
        :tipos-bombona="tiposBombona"
        :picos="picosDisponibles"
        @selection-change="onSelectionUpdate"
      />

      <div class="mt-4 max-w-md">
        <BaseInput 
          v-model="observaciones" 
          label="Observaciones" 
          placeholder="Opcional"
        />
      </div>

      <div class="mt-6 flex justify-end">
        <BaseButton 
          @click="submit" 
          variant="success"
          :disabled="!selectionComplete"
          size="md"
        >
          Registrar solicitud
        </BaseButton>
      </div>

      <div v-if="success" class="mt-4 p-4 bg-green-100 text-green-700 rounded-lg border border-green-300">
        {{ success }}
      </div>

      <div v-if="error" class="mt-4 p-4 bg-red-100 text-red-700 rounded-lg border border-red-300">
        {{ error }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import CascadingSelector from '../../components/ui/CascadingSelector.vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import { useAuth } from '../../composables/useAuth.js'
import { usePedidos } from '../../composables/usePedidos'
import { useFamilias } from '../../composables/useFamilias'
import { supabase } from '../../lib/supabase'

const { currentUser } = useAuth()
const { createPedido } = usePedidos()
const { familias, fetchFamilias } = useFamilias()

const selectorRef = ref(null)
const observaciones = ref('')
const success = ref('')
const error = ref('')
const selectionComplete = ref(false)

const selection = ref({
  calleId: null,
  familiaId: null,
  tipoBombonaId: null,
  picoId: null,
  complete: false
})

const calles = ref([])
const jefe = ref(null)

const tiposBombona = [
  { id: '10kg', nombre: '10 kg' },
  { id: '18kg', nombre: '18 kg' },
  { id: '43kg', nombre: '43 kg' }
]

const picosDisponibles = [
  { id: 'fino', nombre: 'Pico Fino' },
  { id: 'ancho', nombre: 'Pico Ancho' }
]

function onSelectionUpdate(data) {
  selection.value = data
  selectionComplete.value = data.complete
}

onMounted(async () => {
  success.value = ''
  error.value = ''

  await fetchFamilias()

  const { data: callesData } = await supabase
    .from('calles')
    .select('*')
    .eq('activo', true)
    .order('nombre')
  calles.value = callesData || []

  if (currentUser.value?.id) {
    const { data: jefeData } = await supabase
      .from('jefe_de_calle')
      .select('*')
      .eq('auth_id', currentUser.value.id)
      .single()
    jefe.value = jefeData
  }
})

async function submit() {
  if (!selection.value.complete) {
    error.value = 'Completa todos los campos obligatorios'
    success.value = ''
    return
  }

  error.value = ''
  success.value = ''

  try {
    const result = await createPedido({
      id_familias: selection.value.familiaId,
      tipo_bombona: selection.value.tipoBombonaId,
      pico: selection.value.picoId,
      status: 'pendiente',
      fecha_solicitud: new Date().toISOString()
    })

    if (result) {
      success.value = 'Solicitud registrada exitosamente'
      observaciones.value = ''
      selectorRef.value?.reset()
      selectionComplete.value = false
    } else {
      error.value = 'Error al registrar la solicitud'
    }
  } catch (err) {
    error.value = err.message
  }
}
</script>