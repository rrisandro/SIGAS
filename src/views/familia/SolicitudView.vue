<template>
  <div class="p-6 max-w-4xl mx-auto">
    <h2 class="text-2xl font-bold mb-2 text-gray-800">Solicitar Gas</h2>
    <p class="text-sm text-gray-500 mb-6">Módulo de Familia</p>

    <div class="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      
      <div v-if="!datosCargados" class="py-8 text-center text-gray-500">
        Cargando tu información personal...
      </div>

      <!-- Le enviamos las listas completas de la BD, pero lo bloqueamos en los IDs del usuario -->
      <CascadingSelector
        v-if="datosCargados"
        ref="selectorRef"
        :calles="calles"
        :familias="familias"
        :initial-calle-id="initialCalleId"
        :initial-familia-id="initialFamiliaId"
        lock-calle
        lock-familia
        :tipos-bombona="tiposBombona"
        :picos="picosDisponibles"
        @selection-change="onSelectionUpdate"
      />

      <div v-if="datosCargados" class="mt-4 max-w-md">
        <BaseInput 
          v-model="observaciones" 
          label="Observaciones" 
          placeholder="Opcional"
        />
      </div>

      <div v-if="datosCargados" class="mt-6 flex justify-end">
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
import { usePedidos } from '../../composables/usePedidos'
import { useFamilias } from '../../composables/useFamilias' // Volvemos a traer tu composable
import { supabase } from '../../lib/supabase'

const { createPedido } = usePedidos()
const { familias, fetchFamilias } = useFamilias()

const selectorRef = ref(null)
const observaciones = ref('')
const success = ref('')
const error = ref('')
const selectionComplete = ref(false)
const datosCargados = ref(false)

const selection = ref({
  calleId: null,
  familiaId: null,
  tipoBombonaId: null,
  picoId: null,
  complete: false
})

const initialFamiliaId = ref(null)
const initialCalleId = ref(null)
const calles = ref([]) // Volvemos a usar la lista real de calles

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
  selectionComplete.value = data.complete || (data.tipoBombonaId && data.picoId)
}

onMounted(async () => {
  success.value = ''
  error.value = ''

  // 1. Cargamos TODAS las familias y calles para que tu selector pueda hacer la búsqueda interna
  await fetchFamilias()
  const { data: callesData } = await supabase
    .from('calles')
    .select('*')
    .eq('activo', true)
    .order('nombre')
  calles.value = callesData || []

  // 2. Buscamos al usuario logueado
  const { data: { user }, error: authError } = await supabase.auth.getUser()

  if (user && !authError) {
    // 3. Extraemos SOLO los IDs (id e id_calle) de la familia logueada
    const { data: familiaData, error: dbError } = await supabase
      .from('familias')
      .select('id, id_calle')
      .eq('auth_id', user.id)
      .single()

    if (familiaData && !dbError) {
      // 4. Se los pasamos al selector como initial-ids. 
      // El selector buscará estos IDs dentro de "calles" y "familias" y mostrará los nombres.
      initialFamiliaId.value = familiaData.id
      initialCalleId.value = familiaData.id_calle
      
      selection.value.familiaId = familiaData.id
      selection.value.calleId = familiaData.id_calle
      
      datosCargados.value = true
    } else {
      error.value = 'No se encontraron los datos de tu familia en la base de datos.'
    }
  } else {
    error.value = 'No se detectó una sesión iniciada.'
  }
})

async function submit() {
  if (!selection.value.tipoBombonaId || !selection.value.picoId) {
    error.value = 'Completa el tipo de bombona y el pico'
    success.value = ''
    return
  }

  error.value = ''
  success.value = ''

  try {
    const result = await createPedido({
      id_familias: initialFamiliaId.value, // Garantizamos que siempre envíe su propio ID
      tipo_bombona: selection.value.tipoBombonaId,
      pico: selection.value.picoId,
      status: 'pendiente',
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
}</script>
/* ==========================================================================
   DOCUMENTACIÓN: MÓDULO DE SOLICITUD DE GAS (VUE 3 + SUPABASE)
   ========================================================================== */

/* 
1. ESTADO DE ESPERA (v-if="datosCargados")
Ocultamos el formulario visualmente usando v-if="datosCargados" y mostramos 
un mensaje de "Cargando". Esto evita el error de renderizado donde las casillas 
se dibujan vacías por no tener la respuesta de Supabase a tiempo.
*/

/* 
2. PREPARACIÓN INICIAL (onMounted)
Se ejecuta apenas abre la pantalla y hace 3 tareas en cadena:
- Descarga TODAS las calles y familias (fetchFamilias).
- Valida quién está conectado: supabase.auth.getUser().
- Busca el ID de familia y calle de ese usuario. Al terminar, activa 
  datosCargados = true para que Vue dibuje el formulario de golpe.
*/

/* 
3. CRUCE DE DATOS (CascadingSelector)
El selector recibe las listas completas y los IDs predeterminados del usuario. 
Internamente busca esos IDs, extrae los nombres y los inyecta en las casillas. 
Los atributos "lock-calle" y "lock-familia" impiden que el menú se despliegue.
*/

/* 
4. VALIDACIÓN EN TIEMPO REAL (onSelectionUpdate)
Mientras el usuario elige la bombona y el pico, esta función actualiza el objeto 
"selection". El botón verde de "Registrar" solo se enciende cuando esta función 
confirma que ya se llenaron los campos obligatorios.
*/

/* 
5. INSERCIÓN SEGURA (submit)
Envía el pedido a la base de datos. Como medida de seguridad, ignora lo que diga 
el selector en pantalla (evitando hackeos del HTML) y usa "initialFamiliaId.value", 
que es el ID validado en secreto en el paso 2. Es imposible pedir por otro vecino.
*/
