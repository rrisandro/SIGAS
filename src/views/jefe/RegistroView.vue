<template>
  <div class="p-6 max-w-4xl mx-auto">
    <h2 class="text-2xl font-bold mb-2 text-gray-800">Registro de Solicitud</h2>
    <p class="text-sm text-gray-500 mb-6">Gestión de calle</p>

    <!-- Estado de Carga -->
    <div v-if="loading" class="mb-6 p-4 bg-gray-50 text-gray-600 rounded-lg border border-gray-200">
      Cargando información del ciclo y familias...
    </div>

    <!-- Alerta de Ciclo Inactivo -->
    <div v-else-if="!cicloActivo" class="mb-6 p-4 bg-yellow-100 text-yellow-800 rounded-lg border border-yellow-300 flex items-center gap-2">
      <span>⚠️ <strong>Atención:</strong> No hay ningún ciclo de distribución activo en este momento. No se pueden registrar solicitudes.</span>
    </div>

    <div v-if="jefe" class="mb-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
      <p class="text-sm text-gray-600">
        Jefe de calle: <span class="font-medium text-blue-700">{{ jefe.nombre }}</span>
      </p>
    </div>

    <div class="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      <!-- Agregamos :key para forzar la reactividad del selector -->
      <CascadingSelector
        :key="familiasDisponibles.length + '-' + (cicloActivo?.id_ciclo || 0)"
        ref="selectorRef"
        :calles="calles"
        :familias="familiasDisponibles"
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
          :disabled="!selectionComplete || !cicloActivo || loading"
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
import { ref, onMounted, computed } from 'vue'
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

const loading = ref(true)
const cicloActivo = ref(null)
const familiasConPedido = ref([])

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

// Computed para filtrar familias
const familiasDisponibles = computed(() => {
  if (!familias.value) return []
  const filtradas = familias.value.filter(f => !familiasConPedido.value.includes(String(f.id)))
  console.log('🔍 Familias Totales:', familias.value.length, '| Disponibles:', filtradas.length)
  return filtradas
})

function onSelectionUpdate(data) {
  selection.value = data
  selectionComplete.value = data.complete
}

onMounted(async () => {
  loading.value = true
  success.value = ''
  error.value = ''

  try {
    await fetchFamilias()

    // 1. Consulta segura de ciclo activo (evita fallos de .maybeSingle)
    const { data: ciclosData, error: errCiclo } = await supabase
      .from('ciclos_distribucion')
      .select('*')
      .ilike('estado', 'activo')
      .limit(1)

    if (errCiclo) console.error('❌ Error ciclos:', errCiclo)

    cicloActivo.value = ciclosData && ciclosData.length > 0 ? ciclosData[0] : null
    console.log('📌 Ciclo activo obtenido:', cicloActivo.value)

    // 2. Si hay ciclo activo, obtenemos los pedidos
    if (cicloActivo.value) {
      const { data: pedidosExistentes, error: errPedidos } = await supabase
        .from('pedidos')
        .select('id_familias')
        .eq('id_ciclo', cicloActivo.value.id_ciclo)

      if (errPedidos) console.error('❌ Error pedidos:', errPedidos)

      if (pedidosExistentes) {
        // Convertimos todos a String para asegurar coincidencias
        familiasConPedido.value = pedidosExistentes.map(p => String(p.id_familias))
        console.log('📋 IDs de Familias que ya hicieron pedido:', familiasConPedido.value)
      }
    }

    // 3. Obtener calles
    const { data: callesData } = await supabase
      .from('calles')
      .select('*')
      .eq('activo', true)
      .order('nombre')
    calles.value = callesData || []

    // 4. Datos del jefe
    if (currentUser.value?.id) {
      const { data: jefeData } = await supabase
        .from('jefe_de_calle')
        .select('*')
        .eq('auth_id', currentUser.value.id)
        .single()
      jefe.value = jefeData
    }
  } catch (err) {
    console.error('❌ Error general:', err)
  } finally {
    loading.value = false
  }
})

async function submit() {
  if (!cicloActivo.value) {
    error.value = 'No hay un ciclo de distribución activo para registrar solicitudes.'
    return
  }

  if (!selection.value.complete) {
    error.value = 'Completa todos los campos obligatorios'
    return
  }

  error.value = ''
  success.value = ''

  const idFamilia = String(selection.value.familiaId)

  if (familiasConPedido.value.includes(idFamilia)) {
    error.value = 'Esta familia ya posee una solicitud en el ciclo activo.'
    return
  }

  try {
    const result = await createPedido({
      id_familias: selection.value.familiaId,
      id_ciclo: cicloActivo.value.id_ciclo,
      tipo_bombona: selection.value.tipoBombonaId,
      pico: selection.value.picoId,
      status: 'pendiente',
      fecha_solicitud: new Date().toISOString()
    })

    if (result) {
      success.value = 'Solicitud registrada exitosamente'
      familiasConPedido.value.push(idFamilia)
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