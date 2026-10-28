<template>
  <div class="page form-page">
    <div class="page-heading">
      <h2 class="page-title">Registro de Solicitud</h2>
      <p class="page-subtitle">Gestión de calle</p>
    </div>

    <!-- Estado de Carga -->
    <div v-if="loading" class="state-banner state-banner--loading">
      Cargando información del ciclo y familias...
    </div>

    <!-- Alerta de Ciclo Inactivo -->
    <div v-else-if="!cicloActivo" class="state-banner state-banner--warning">
      <span aria-hidden="true">⚠️</span>
      <span><strong>Atención:</strong> No hay ningún ciclo de distribución activo en este momento. No se pueden registrar solicitudes.</span>
    </div>

    <div v-if="jefe" class="jefe-banner">
      <span class="jefe-banner__icon" aria-hidden="true">👤</span>
      <p>
        Jefe de calle:
        <strong>{{ jefe.nombre }}</strong>
      </p>
    </div>

    <div class="form-card">
      <CascadingSelector
        :key="familiasDisponibles.length + '-' + (cicloActivo?.id_ciclo || 0)"
        ref="selectorRef"
        :calles="calles"
        :familias="familiasDisponibles"
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
          :disabled="!selectionComplete || !cicloActivo || loading"
          size="md"
        >
          Registrar solicitud
        </BaseButton>
      </div>

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
  const filtradas = familias.value.filter((f) => {
    if (familiasConPedido.value.includes(String(f.id))) return false
    if (String(f.estado || 'aprobado').toLowerCase() !== 'aprobado') return false
    if (f.activo === false) return false
    if (!jefe.value?.id_calle) return true
    return Number(f.id_calle) === Number(jefe.value.id_calle)
  })
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
      .eq('is_deleted', false)
      .order('nombre')
    calles.value = callesData || []

    // 4. Datos del jefe
    if (currentUser.value?.authId) {
      const { data: jefeData } = await supabase
        .from('jefe_de_calle')
        .select('*')
        .eq('auth_id', currentUser.value.authId)
        .eq('activo', true)
        .eq('is_deleted', false)
        .limit(1)
        .maybeSingle()
      jefe.value = jefeData

      // El Jefe de Calle solo registra solicitudes para su propia calle.
      if (jefeData?.id_calle) {
        calles.value = calles.value.filter(
          (calle) => Number(calle.id_calle) === Number(jefeData.id_calle)
        )
      }
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

<style scoped>
.form-page {
  display: flex;
  flex-direction: column;
  gap: 18px;
  max-width: 960px;
}

.jefe-banner {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 12px 14px;
  background: #eff6ff;
  border: 1px solid #bfdbfe;
  border-radius: 12px;
  color: #1e40af;
  font-size: 0.875rem;
  line-height: 1.5;
}

.jefe-banner__icon {
  flex-shrink: 0;
  line-height: 1.4;
}

.jefe-banner strong {
  font-weight: 600;
}

.state-banner {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  padding: 12px 14px;
  border: 1px solid transparent;
  border-radius: 12px;
  font-size: 0.875rem;
  line-height: 1.5;
}

.state-banner--loading {
  background: var(--color-bg);
  border-color: var(--color-border);
  color: var(--color-muted);
}

.state-banner--warning {
  background: #fffbeb;
  border-color: #fde68a;
  color: #92400e;
}

.state-banner--warning strong {
  color: #78350f;
}

.form-card {
  padding: 16px;
  background: #ffffff;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
}

.field-narrow {
  width: 100%;
  max-width: 440px;
  margin-top: 16px;
}

@media (min-width: 640px) {
  .form-page {
    gap: 24px;
  }

  .jefe-banner {
    padding: 14px 18px;
  }

  .form-card {
    padding: 24px;
  }

  .field-narrow {
    margin-top: 20px;
  }
}

@media (min-width: 1024px) {
  .form-card {
    padding: 28px;
  }
}
</style>
