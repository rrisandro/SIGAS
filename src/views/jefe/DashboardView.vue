<template>
  <div class="page jefe-dashboard">
    <div class="page-heading">
      <h2 class="page-title">Dashboard</h2>
      <p class="page-subtitle">
        Métricas de {{ nombreCalle || 'tu calle asignada' }}
      </p>
    </div>

    <div v-if="!cargando && jefe?.codigo" class="code-banner" aria-label="Código único de Jefe de Calle">
      <span>Tu código de Jefe de Calle</span>
      <strong>{{ jefe.codigo }}</strong>
    </div>

    <!-- Alerta si no se encuentra la asignación de calle -->
    <div v-if="!cargando && sinCalleAsignada" class="alert-banner alert-banner--warning">
      ⚠️ <strong>Atención:</strong> Tu usuario de Jefe de Calle no tiene una calle vinculada en la base de datos. Pide al administrador que vincule tu usuario en la sección de Calles.
    </div>

    <!-- Alerta cuando no hay ciclo activo -->
    <div v-else-if="!cargando && !cicloActivo" class="alert-banner">
      ⚠️ <strong>Atención:</strong> No hay ningún ciclo de distribución activo en este momento. Las métricas de pedidos corresponden al último ciclo registrado o se actualizarán cuando la administración abra una nueva jornada.
    </div>

    <!-- Indicador de Carga -->
    <div v-if="cargando" class="py-8 text-center text-gray-500">
      Cargando estadísticas de tu sector...
    </div>

    <!-- Tarjetas de métricas -->
    <div v-else class="metrics-grid">
      <!-- Familias activas -->
      <article class="metric-card">
        <div class="metric-icon metric-icon--blue">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
            <circle cx="9" cy="7" r="4" />
            <path d="M22 21v-2a4 4 0 0 3-3.87" />
            <path d="M16 3.13a4 4 0 0 1 0 7.75" />
          </svg>
        </div>
        <div class="metric-info">
          <p class="metric-label">Familias activas</p>
          <p class="metric-value">{{ stats.familiasActivas }}</p>
        </div>
      </article>

      <!-- Pendientes -->
      <article class="metric-card">
        <div class="metric-icon metric-icon--warning">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="9" />
            <path d="M12 7v5l3 2" />
          </svg>
        </div>
        <div class="metric-info">
          <p class="metric-label">Pendientes</p>
          <p class="metric-value">{{ stats.pendientes }}</p>
        </div>
      </article>

      <!-- En proceso -->
      <article class="metric-card">
        <div class="metric-icon metric-icon--purple">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="9" />
            <path d="M12 7v5l3 2" />
          </svg>
        </div>
        <div class="metric-info">
          <p class="metric-label">En proceso</p>
          <p class="metric-value">{{ stats.enProceso }}</p>
        </div>
      </article>

      <!-- Entregadas -->
      <article class="metric-card">
        <div class="metric-icon metric-icon--success">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
            <path d="M20 6 9 17l-5-5" />
          </svg>
        </div>
        <div class="metric-info">
          <p class="metric-label">Entregadas</p>
          <p class="metric-value">{{ stats.entregadas }}</p>
        </div>
      </article>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'

const cargando = ref(true)
const jefe = ref(null)
const nombreCalle = ref('')
const sinCalleAsignada = ref(false)
const cicloActivo = ref(null)
const familiasSector = ref([])
const pedidosSector = ref([])

const stats = computed(() => {
  return {
    familiasActivas: familiasSector.value.filter(f => f.activo !== false).length,
    pendientes: pedidosSector.value.filter(p => (p.status || p.estatus || '').toLowerCase() === 'pendiente').length,
    enProceso: pedidosSector.value.filter(p => ['aceptado', 'en_proceso'].includes((p.status || p.estatus || '').toLowerCase())).length,
    entregadas: pedidosSector.value.filter(p => (p.status || p.estatus || '').toLowerCase() === 'entregado').length,
  }
})

async function cargarDatosDashboardJefe() {
  cargando.value = true
  sinCalleAsignada.value = false

  try {
    // 1. Obtener usuario autenticado de Supabase
    const { data: { user } } = await supabase.auth.getUser()

    if (user) {
      // 2. Traer los datos del jefe de calle
      const { data: jefeData } = await supabase
        .from('jefe_de_calle')
        .select('*')
        .eq('auth_id', user.id)
        .maybeSingle()

      jefe.value = jefeData

      if (!jefeData) {
        sinCalleAsignada.value = true
        cargando.value = false
        return
      }

      // 3. Consultar TODAS las calles asignadas a este id_jefe_calle
      const { data: callesAsignadas } = await supabase
        .from('calles')
        .select('id_calle, nombre')
        .eq('id_jefe_calle', jefeData.id_jefe_calle)

      if (!callesAsignadas || callesAsignadas.length === 0) {
        sinCalleAsignada.value = true
        cargando.value = false
        return
      }

      // Guardamos la lista de IDs de calles
      const idsCalles = callesAsignadas.map(c => c.id_calle)

      // Formateamos el nombre para el título (Ej: "Calle Bolívar, Calle Principal")
      nombreCalle.value = callesAsignadas.map(c => c.nombre).join(', ')

      // 4. Traer todas las familias pertenecientes a cualquiera de sus calles asignadas
      const { data: familiasData } = await supabase
        .from('familias')
        .select('id, id_calle, activo')
        .in('id_calle', idsCalles)

      familiasSector.value = familiasData || []
      const idsFamiliasCalle = familiasSector.value.map(f => f.id)

      // 5. Buscar si existe un ciclo de distribución activo
      const { data: ciclosActivos } = await supabase
        .from('ciclos_distribucion')
        .select('*')
        .eq('estado', 'activo')
        .order('id_ciclo', { ascending: false })

      let cicloEncontrado = null

      if (ciclosActivos && ciclosActivos.length > 0) {
        // Prioridad 1: Ciclo General para la comunidad (id_calle es NULL)
        cicloEncontrado = ciclosActivos.find(c => c.id_calle === null || c.id_calle === undefined)
        
        // Prioridad 2: Ciclo asignado a alguna de las calles del jefe
        if (!cicloEncontrado) {
          cicloEncontrado = ciclosActivos.find(c => idsCalles.includes(Number(c.id_calle)))
        }

        // Prioridad 3: Respaldo, tomar el ciclo activo más reciente
        if (!cicloEncontrado) {
          cicloEncontrado = ciclosActivos[0]
        }
      }

      cicloActivo.value = cicloEncontrado

      // 6. Cargar los pedidos de todas las familias de sus sectores
      if (cicloActivo.value && idsFamiliasCalle.length > 0) {
        const { data: pedidosData } = await supabase
          .from('pedidos')
          .select('*')
          .eq('id_ciclo', cicloActivo.value.id_ciclo)
          .in('id_familias', idsFamiliasCalle)

        pedidosSector.value = pedidosData || []
      } else {
        pedidosSector.value = []
      }
    }
  } catch (err) {
    console.error('Error en el dashboard del jefe:', err)
  } finally {
    cargando.value = false
  }
}
onMounted(() => {
  cargarDatosDashboardJefe()
})
</script>

<style scoped>
.jefe-dashboard {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.alert-banner {
  padding: 1rem;
  background-color: #fffbeb;
  border: 1px solid #fef08a;
  border-radius: 0.75rem;
  color: #854d0e;
  font-size: 0.88rem;
}

.code-banner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 12px 16px;
  border: 1px solid #bae6fd;
  border-radius: 12px;
  background: #f0f9ff;
}

.code-banner span {
  color: #0369a1;
  font-size: 0.78rem;
  font-weight: 600;
  letter-spacing: 0.03em;
  text-transform: uppercase;
}

.code-banner strong {
  padding: 4px 12px;
  border: 1px solid #7dd3fc;
  border-radius: 8px;
  background: #ffffff;
  color: #0369a1;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-size: 1rem;
  font-weight: 800;
  letter-spacing: 0.14em;
}

.alert-banner--warning {
  background-color: #fef2f2;
  border-color: #fecaca;
  color: #991b1b;
}

.metrics-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 12px;
}

.metric-card {
  display: flex;
  align-items: center;
  gap: 14px;
  min-width: 0;
  padding: 16px;
  background: #ffffff;
  border: 1px solid var(--color-border);
  border-radius: 14px;
  box-shadow: var(--shadow-sm);
}

.metric-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 40px;
  height: 40px;
  border-radius: 11px;
}

.metric-icon svg {
  width: 20px;
  height: 20px;
}

.metric-icon--blue { background: #eff6ff; color: #2563eb; }
.metric-icon--warning { background: #fffbeb; color: #d97706; }
.metric-icon--purple { background: #faf5ff; color: #9333ea; }
.metric-icon--success { background: #ecfdf5; color: #059669; }

.metric-info { min-width: 0; }

.metric-label {
  color: var(--color-muted);
  font-size: 0.72rem;
  font-weight: 600;
  letter-spacing: 0.03em;
  line-height: 1.35;
  text-transform: uppercase;
}

.metric-value {
  margin-top: 2px;
  color: var(--color-heading);
  font-size: 1.5rem;
  font-weight: 700;
  line-height: 1.2;
  font-variant-numeric: tabular-nums;
}

@media (min-width: 640px) {
  .jefe-dashboard { gap: 24px; }
  .metrics-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }
  .metric-card { padding: 18px; }
  .metric-icon { width: 44px; height: 44px; }
  .metric-icon svg { width: 22px; height: 22px; }
  .metric-value { font-size: 1.625rem; }
}

@media (min-width: 1024px) {
  .metrics-grid { grid-template-columns: repeat(4, minmax(0, 1fr)); }
  .metric-card { gap: 16px; padding: 20px; }
  .metric-icon { width: 48px; height: 48px; }
  .metric-icon svg { width: 24px; height: 24px; }
  .metric-value { font-size: 1.75rem; }
}
</style>
