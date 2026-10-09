<template>
  <div class="p-6 max-w-4xl mx-auto">
    <h2 class="text-2xl font-bold mb-2 text-gray-800">Solicitar Gas</h2>
    <p class="text-sm text-gray-500 mb-6">Módulo de Familia</p>

    <div class="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
      
      <!-- Mensaje de carga mientras se consulta la información -->
      <div v-if="!datosCargados" class="py-8 text-center text-gray-500">
        Cargando tu información personal y del ciclo de distribución...
      </div>

      <!-- CASO 1: No hay un ciclo de distribución activo habilitado por el Admin -->
      <div 
        v-else-if="!cicloActivo" 
        class="p-6 text-center rounded-lg bg-amber-50 border border-amber-200 text-amber-800"
      >
        <p class="font-medium text-lg mb-1">Jornada no disponible</p>
        <p class="text-sm">En este momento no hay un ciclo de distribución activo para tu comunidad o sector. Por favor, espera a que la administración habilite una nueva jornada.</p>
      </div>

      <!-- CASO 2: La familia ya realizó su solicitud en el ciclo actual (Muestra estatus real) -->
      <div 
        v-else-if="pedidoExistente" 
        class="p-6 text-center rounded-lg space-y-2"
        :class="estatusBannerClass"
      >
        <p class="font-bold text-lg">{{ tituloEstatus }}</p>
        <p class="text-sm max-w-xl mx-auto">{{ mensajeEstatus }}</p>

        <div class="mt-4 pt-3 border-t border-gray-200/50 text-xs opacity-80 space-y-1">
          <p><strong>Jornada:</strong> {{ cicloActivo.nombre_ciclo }}</p>
          <p><strong>Detalle de solicitud:</strong> Bombona {{ pedidoExistente.tipo_bombona }} ({{ pedidoExistente.pico }})</p>
        </div>
      </div>

      <!-- CASO 3: Hay ciclo activo y la familia aún no ha realizado pedido -->
      <div v-else>
        <div class="mb-4 p-3 bg-green-50 border border-green-200 text-green-800 text-sm rounded-lg">
          Ciclo de entrega activo: <strong>{{ cicloActivo.nombre_ciclo }}</strong>
        </div>

        <CascadingSelector
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
            :disabled="!selectionComplete || enviando"
            size="md"
          >
            {{ enviando ? 'Enviando...' : 'Registrar solicitud' }}
          </BaseButton>
        </div>
      </div>

      <!-- Notificaciones de éxito y error -->
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
import { ref, computed, onMounted } from 'vue'
import CascadingSelector from '../../components/ui/CascadingSelector.vue'
import BaseInput from '../../components/ui/BaseInput.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import { usePedidos } from '../../composables/usePedidos'
import { useFamilias } from '../../composables/useFamilias'
import { supabase } from '../../lib/supabase'

const { createPedido } = usePedidos()
const { familias, fetchFamilias } = useFamilias()

const selectorRef = ref(null)
const observaciones = ref('')
const success = ref('')
const error = ref('')
const selectionComplete = ref(false)
const datosCargados = ref(false)

const enviando = ref(false)
const cicloActivo = ref(null)
const pedidoExistente = ref(null)

const selection = ref({
  calleId: null,
  familiaId: null,
  tipoBombonaId: null,
  picoId: null,
  complete: false
})

const initialFamiliaId = ref(null)
const initialCalleId = ref(null)
const calles = ref([])

const tiposBombona = [
  { id: '10kg', nombre: '10 kg' },
  { id: '18kg', nombre: '18 kg' },
  { id: '43kg', nombre: '43 kg' }
]

const picosDisponibles = [
  { id: 'fino', nombre: 'Pico Fino' },
  { id: 'ancho', nombre: 'Pico Ancho' }
]

// Computed Properties para los títulos, mensajes y colores de estado
const tituloEstatus = computed(() => {
  if (!pedidoExistente.value) return ''
  const status = (pedidoExistente.value.status || '').toLowerCase()
  if (status === 'pendiente') return '⏳ Solicitud en espera de aprobación'
  if (status === 'aceptado') return '✅ Solicitud Aceptada'
  if (status === 'entregado') return '🎉 Gas Entregado'
  return 'Solicitud Registrada'
})

const mensajeEstatus = computed(() => {
  if (!pedidoExistente.value) return ''
  const status = (pedidoExistente.value.status || '').toLowerCase()
  if (status === 'pendiente') {
    return 'Tu pedido ha sido registrado con éxito. Se encuentra a la espera de ser revisado y aceptado por el Jefe de Calle de tu sector.'
  }
  if (status === 'aceptado') {
    return '¡Excelente noticia! Tu Jefe de Calle ha aceptado tu solicitud. Mantente atento al grupo de WhatsApp comunal para coordinar la entrega y recolección de tu bombona.'
  }
  if (status === 'entregado') {
    return 'Tu bombona ya fue despachada y entregada exitosamente en esta jornada. ¡Gracias por usar el sistema!'
  }
  return ''
})

const estatusBannerClass = computed(() => {
  if (!pedidoExistente.value) return ''
  const status = (pedidoExistente.value.status || '').toLowerCase()
  if (status === 'pendiente') return 'bg-amber-50 border border-amber-200 text-amber-900'
  if (status === 'aceptado') return 'bg-blue-50 border border-blue-200 text-blue-900'
  if (status === 'entregado') return 'bg-green-50 border border-green-200 text-green-900'
  return 'bg-gray-50 border border-gray-200 text-gray-800'
})

function onSelectionUpdate(data) {
  selection.value = data
  selectionComplete.value = data.complete || (data.tipoBombonaId && data.picoId)
}

async function cargarEstadoFormulario() {
  success.value = ''
  error.value = ''
  datosCargados.value = false

  try {
    // 1. Cargar familias y calles
    await fetchFamilias()
    const { data: callesData } = await supabase
      .from('calles')
      .select('*')
      .eq('activo', true)
      .order('nombre')
    calles.value = callesData || []

    // 2. Obtener la sesión del usuario autenticado
    const { data: { user }, error: authError } = await supabase.auth.getUser()

    if (user && !authError) {
      // 3. Obtener la familia asociada a este usuario
      const { data: familiaData, error: dbError } = await supabase
        .from('familias')
        .select('id, id_calle')
        .eq('auth_id', user.id)
        .maybeSingle()

      if (familiaData && !dbError) {
        initialFamiliaId.value = familiaData.id
        initialCalleId.value = familiaData.id_calle
        
        selection.value.familiaId = familiaData.id
        selection.value.calleId = familiaData.id_calle

        // 4. CONSULTA DIRECTA Y FLEXIBLE DE CICLOS ACTIVOS
        // Traemos todos los ciclos activos y dejamos que JavaScript los evalúe sin restricciones de Supabase
        const { data: ciclosActivos } = await supabase
          .from('ciclos_distribucion')
          .select('*')
          .eq('estado', 'activo')
          .order('id_ciclo', { ascending: false })

        let ciclo = null

        if (ciclosActivos && ciclosActivos.length > 0) {
          // Prioridad 1: Buscar si hay un ciclo general (id_calle es null, undefined o cadena vacía)
          ciclo = ciclosActivos.find(c => c.id_calle === null || c.id_calle === undefined || c.id_calle === '')

          // Prioridad 2: Si no hay general, buscar ciclo específico para la calle de la familia
          if (!ciclo && familiaData.id_calle) {
            ciclo = ciclosActivos.find(c => Number(c.id_calle) === Number(familiaData.id_calle))
          }

          // Prioridad 3 (Respaldo absoluto): Si hay algún ciclo activo pero no cumplió lo anterior, toma el primero disponible
          if (!ciclo) {
            ciclo = ciclosActivos[0]
          }
        }

        if (ciclo) {
          cicloActivo.value = ciclo

          // 5. CONSULTA DEL PEDIDO EN EL CICLO ACTIVO
          const { data: pedidosGuardados } = await supabase
            .from('pedidos')
            .select('*')
            .eq('id_familias', familiaData.id)
            .eq('id_ciclo', ciclo.id_ciclo)
            .order('id_pedido', { ascending: false })

          if (pedidosGuardados && pedidosGuardados.length > 0) {
            pedidoExistente.value = pedidosGuardados[0]
          } else {
            pedidoExistente.value = null
          }
        } else {
          cicloActivo.value = null
          pedidoExistente.value = null
        }
      } else {
        error.value = 'No se encontraron los datos de tu familia en la base de datos.'
      }
    } else {
      error.value = 'No se detectó una sesión iniciada.'
    }
  } catch (err) {
    console.error('Error al cargar formulario:', err)
    error.value = 'Error al consultar la información del ciclo.'
  } finally {
    datosCargados.value = true
  }
}

onMounted(() => {
  cargarEstadoFormulario()
})

async function submit() {
  if (!selection.value.tipoBombonaId || !selection.value.picoId) {
    error.value = 'Completa el tipo de bombona y el pico'
    success.value = ''
    return
  }

  if (!cicloActivo.value) {
    error.value = 'No hay un ciclo de entrega activo en este momento.'
    return
  }

  error.value = ''
  success.value = ''
  enviando.value = true

  try {
    const nuevoPedidoData = {
      id_familias: initialFamiliaId.value,
      id_ciclo: cicloActivo.value.id_ciclo,
      tipo_bombona: selection.value.tipoBombonaId,
      pico: selection.value.picoId,
      status: 'pendiente',
    }

    const result = await createPedido(nuevoPedidoData)

    if (result) {
      success.value = 'Solicitud registrada exitosamente'
      observaciones.value = ''
      pedidoExistente.value = result.id_pedido ? result : nuevoPedidoData
    } else {
      error.value = 'Error al registrar la solicitud'
    }
  } catch (err) {
    error.value = err.message
  } finally {
    enviando.value = false
  }
}
</script>
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
