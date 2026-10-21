<template>
  <div class="page request-page">
    <div class="page-heading">
      <h2 class="page-title">Solicitar Gas</h2>
      <p class="page-subtitle">Módulo de Familia</p>
    </div>

    <div class="request-card">
      <!-- Mensaje de carga mientras se consulta la información -->
      <div v-if="!datosCargados" class="loading-box">
        Cargando tu información personal y del ciclo de distribución...
      </div>

      <!-- CASO 1: No hay un ciclo de distribución activo habilitado por el Admin -->
      <div
        v-else-if="!cicloActivo"
        class="notice notice--warning"
      >
        <p class="notice__title">Jornada no disponible</p>
        <p class="notice__text">En este momento no hay un ciclo de distribución activo para tu comunidad o sector. Por favor, espera a que la administración habilite una nueva jornada.</p>
      </div>

      <!-- CASO 2: La familia ya realizó su solicitud en el ciclo actual (Muestra estatus real) -->
      <div
        v-else-if="pedidoExistente"
        class="status-panel"
        :class="estatusBannerClass"
      >
        <p class="status-panel__title">{{ tituloEstatus }}</p>
        <p class="status-panel__message">{{ mensajeEstatus }}</p>

        <div class="status-panel__detail">
          <p><strong>Jornada:</strong> {{ cicloActivo.nombre_ciclo }}</p>
          <p><strong>Detalle de solicitud:</strong> Bombona {{ pedidoExistente.tipo_bombona }} ({{ pedidoExistente.pico }})</p>
        </div>
      </div>

      <!-- CASO 3: Hay ciclo activo y la familia aún no ha realizado pedido -->
      <div v-else>
        <div class="active-cycle">
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

        <div class="field-narrow">
          <BaseInput
            v-model="observaciones"
            label="Observaciones"
            placeholder="Opcional"
          />
        </div>

        <div class="form-actions">
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
      <div v-if="success" class="form-message form-message--success">
        {{ success }}
      </div>

      <div v-if="error" class="form-message form-message--error">
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

<style scoped>
.request-page {
  display: flex;
  flex-direction: column;
  gap: 18px;
  max-width: 960px;
}

.request-card {
  padding: 16px;
  background: #ffffff;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
}

.loading-box {
  padding: 32px 16px;
  color: var(--color-muted);
  text-align: center;
}

.active-cycle {
  margin-bottom: 16px;
  padding: 11px 13px;
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  border-radius: 11px;
  color: #166534;
  font-size: 0.84rem;
  line-height: 1.45;
}

.notice {
  padding: 18px 16px;
  border: 1px solid transparent;
  border-radius: 12px;
  text-align: center;
}

.notice--warning {
  background: #fffbeb;
  border-color: #fde68a;
  color: #92400e;
}

.notice__title {
  font-size: 1rem;
  font-weight: 700;
}

.notice__text {
  margin-top: 4px;
  font-size: 0.84rem;
  line-height: 1.55;
}

.status-panel {
  padding: 18px 16px;
  border-radius: 12px;
  text-align: center;
}

.status-panel__title {
  font-size: 1rem;
  font-weight: 700;
  line-height: 1.35;
}

.status-panel__message {
  max-width: 560px;
  margin: 6px auto 0;
  font-size: 0.84rem;
  line-height: 1.55;
}

.status-panel__detail {
  margin-top: 14px;
  padding-top: 12px;
  border-top: 1px solid rgba(148, 163, 184, 0.3);
  font-size: 0.75rem;
  line-height: 1.6;
  opacity: 0.85;
}

.field-narrow {
  width: 100%;
  max-width: 440px;
  margin-top: 16px;
}

@media (min-width: 640px) {
  .request-page {
    gap: 24px;
  }

  .request-card {
    padding: 24px;
  }

  .active-cycle {
    margin-bottom: 20px;
    padding: 12px 16px;
  }

  .notice,
  .status-panel {
    padding: 22px 20px;
  }

  .field-narrow {
    margin-top: 20px;
  }
}

@media (min-width: 1024px) {
  .request-card {
    padding: 28px;
  }
}
</style>
