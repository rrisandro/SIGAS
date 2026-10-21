<template>
  <div class="page jefe-dashboard">
    <div class="page-heading">
      <h2 class="page-title">Dashboard</h2>
      <p class="page-subtitle">
        Métricas de {{ jefe?.calle?.nombre || 'tu calle' }}
      </p>
    </div>

    <!-- Tarjetas de métricas -->
    <div class="metrics-grid">
      <!-- Familias activas -->
      <article class="metric-card">
        <div class="metric-icon metric-icon--blue">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="1.8"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
            <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
            <circle cx="9" cy="7" r="4" />
            <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
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
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="1.8"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
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
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="1.8"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
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
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            stroke-width="1.8"
            stroke-linecap="round"
            stroke-linejoin="round"
            aria-hidden="true"
          >
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
import { usePedidos } from '../../composables/usePedidos'
import { useFamilias } from '../../composables/useFamilias'
import { supabase } from '../../lib/supabase'

const { pedidos, fetchPedidos } = usePedidos()
const { familias, fetchFamilias } = useFamilias()

const jefe = ref(null)

const stats = computed(() => {
  const pedidosDeMiCalle = getPedidosDeMiCalle()

  return {
    familiasActivas: familias.value.filter(f => f.activo && f.id_calle === jefe.value?.id_calle).length,
    pendientes: pedidosDeMiCalle.filter(p => p.status === 'pendiente').length,
    enProceso: pedidosDeMiCalle.filter(p => p.status === 'en_proceso').length,
    entregadas: pedidosDeMiCalle.filter(p => p.status === 'entregado').length,
  }
})

function getPedidosDeMiCalle() {
  if (!jefe.value) return []

  const familiaIdsDeMiCalle = new Set(
    familias.value
      .filter(f => f.id_calle === jefe.value.id_calle)
      .map(f => f.id)
  )

  return pedidos.value.filter(p => familiaIdsDeMiCalle.has(p.id_familias))
}

onMounted(async () => {
  console.log('🔍 Dashboard montado')

  await fetchPedidos()
  await fetchFamilias()

  console.log('Pedidos:', pedidos.value.length)
  console.log('Familias:', familias.value.length)

  const { data: { user } } = await supabase.auth.getUser()
  console.log(' Usuario:', user)

  if (user) {
    const { data: jefeData, error } = await supabase
      .from('jefe_de_calle')
      .select('*, calle:calles(nombre)')
      .eq('auth_id', user.id)
      .single()

    console.log('Jefe:', jefeData)
    console.log('Error jefe:', error)

    jefe.value = jefeData
  }
})
</script>

<style scoped>
.jefe-dashboard {
  display: flex;
  flex-direction: column;
  gap: 20px;
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

.metric-icon--blue {
  background: #eff6ff;
  color: #2563eb;
}

.metric-icon--warning {
  background: #fffbeb;
  color: #d97706;
}

.metric-icon--purple {
  background: #faf5ff;
  color: #9333ea;
}

.metric-icon--success {
  background: #ecfdf5;
  color: #059669;
}

.metric-info {
  min-width: 0;
}

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
  .jefe-dashboard {
    gap: 24px;
  }

  .metrics-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 16px;
  }

  .metric-card {
    padding: 18px;
  }

  .metric-icon {
    width: 44px;
    height: 44px;
  }

  .metric-icon svg {
    width: 22px;
    height: 22px;
  }

  .metric-value {
    font-size: 1.625rem;
  }
}

@media (min-width: 1024px) {
  .metrics-grid {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }

  .metric-card {
    gap: 16px;
    padding: 20px;
  }

  .metric-icon {
    width: 48px;
    height: 48px;
  }

  .metric-icon svg {
    width: 24px;
    height: 24px;
  }

  .metric-value {
    font-size: 1.75rem;
  }
}
</style>
