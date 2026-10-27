<template>
  <div class="page family-dashboard">
    <div class="page-heading">
      <h2 class="page-title">Mi Panel</h2>
      <p class="page-subtitle">Resumen de tus solicitudes de gas</p>
    </div>

    <!-- Indicador de Carga -->
    <div v-if="cargando" class="loading-box">
      Cargando tu información...
    </div>

    <template v-else>
      <!-- Última solicitud destacada -->
      <section v-if="recent.length" class="last-request" aria-label="Estado de la última solicitud">
        <div class="last-request__content">
          <p class="last-request__eyebrow">Última solicitud</p>
          <p class="last-request__title">
            Bombona de {{ recent[0].tipo_bombona }} (Pico {{ recent[0].pico }})
          </p>
          <p class="last-request__date">
            {{ formatearFecha(recent[0].created_at || recent[0].fecha_solicitud) }}
          </p>
        </div>
        <StatusBadge :status="recent[0].status" />
      </section>

      <!-- Tarjetas de Resumen -->
      <div class="summary-grid">
        <div v-for="card in cards" :key="card.label" class="summary-card">
          <p class="summary-label">{{ card.label }}</p>
          <p class="summary-value">{{ card.value }}</p>
        </div>
      </div>

      <!-- Últimas Solicitudes -->
      <section class="recent-card">
        <h3 class="recent-title">Últimas solicitudes</h3>
        <div class="recent-list">
          <div
            v-for="s in recent"
            :key="s.id_pedido || s.id"
            class="recent-item"
          >
            <div class="recent-item__info">
              <p class="recent-item__title">Bombona de {{ s.tipo_bombona }} (Pico {{ s.pico }})</p>
              <p class="recent-item__date">{{ formatearFecha(s.created_at || s.fecha_solicitud) }}</p>
            </div>
            <StatusBadge :status="s.status" />
          </div>
          <p v-if="!recent.length" class="recent-empty">Sin solicitudes aún.</p>
        </div>
      </section>
    </template>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import { supabase } from '../../lib/supabase'

const solicitudes = ref([])
const cargando = ref(true)

// Cargar los pedidos de la familia logueada al iniciar
onMounted(async () => {
  cargando.value = true
  try {
    // 1. Obtener el usuario autenticado actual
    const { data: { user }, error: authError } = await supabase.auth.getUser()

    if (user && !authError) {
      // 2. Buscar el id de la familia asociada a este usuario
      const { data: familiaData, error: familiaError } = await supabase
        .from('familias')
        .select('id')
        .eq('auth_id', user.id)
        .maybeSingle()

      if (familiaData && !familiaError) {
        // 3. Consultar los pedidos de esta familia en Supabase
        const { data: pedidosData, error: pedidosError } = await supabase
          .from('pedidos')
          .select('*')
          .eq('id_familias', familiaData.id)
          .order('id_pedido', { ascending: false })

        if (!pedidosError) {
          solicitudes.value = pedidosData || []
        }
      }
    }
  } catch (err) {
    console.error('Error al cargar el panel:', err)
  } finally {
    cargando.value = false
  }
})

// Métricas para las tarjetas superiores
const cards = computed(() => [
  { label: 'Total', value: solicitudes.value.length },
  { label: 'Pendientes', value: solicitudes.value.filter((s) => (s.status || '').toLowerCase() === 'pendiente').length },
  { label: 'Aceptados / En proceso', value: solicitudes.value.filter((s) => ['aceptado', 'en_proceso'].includes((s.status || '').toLowerCase())).length },
  { label: 'Entregadas', value: solicitudes.value.filter((s) => (s.status || '').toLowerCase() === 'entregado').length },
])

// Las últimas 5 solicitudes
const recent = computed(() => solicitudes.value.slice(0, 5))

// Función auxiliar para formatear la fecha de forma limpia
function formatearFecha(fechaStr) {
  if (!fechaStr) return 'Fecha no disponible'
  const fecha = new Date(fechaStr)
  return isNaN(fecha.getTime()) ? fechaStr : fecha.toLocaleDateString()
}
</script>

<style scoped>
.family-dashboard {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.loading-box {
  padding: 32px 16px;
  color: var(--color-muted);
  text-align: center;
}

.last-request {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 14px;
  padding: 16px;
  background: linear-gradient(135deg, #f0f9ff 0%, #ffffff 68%);
  border: 1px solid #bae6fd;
  border-left: 4px solid var(--color-primary);
  border-radius: 14px;
  box-shadow: var(--shadow-sm);
}

.last-request__content {
  min-width: 0;
}

.last-request__eyebrow {
  color: var(--color-primary-dark);
  font-size: 0.68rem;
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
}

.last-request__title {
  margin-top: 4px;
  color: var(--color-heading);
  font-size: 0.95rem;
  font-weight: 600;
  line-height: 1.35;
  overflow-wrap: anywhere;
}

.last-request__date {
  margin-top: 3px;
  color: var(--color-muted);
  font-size: 0.78rem;
}

.summary-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 12px;
}

.summary-card {
  min-width: 0;
  padding: 16px;
  background: #ffffff;
  border: 1px solid var(--color-border-light);
  border-radius: 14px;
  box-shadow: var(--shadow-sm);
}

.summary-label {
  color: var(--color-muted);
  font-size: 0.78rem;
  line-height: 1.35;
}

.summary-value {
  margin-top: 6px;
  color: var(--color-heading);
  font-size: 1.5rem;
  font-weight: 700;
  line-height: 1.2;
  font-variant-numeric: tabular-nums;
}

.recent-card {
  padding: 16px;
  background: #ffffff;
  border: 1px solid var(--color-border-light);
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-sm);
}

.recent-title {
  margin-bottom: 12px;
  color: var(--color-heading);
  font-size: 0.95rem;
  font-weight: 600;
}

.recent-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.recent-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  min-width: 0;
  padding: 11px 12px;
  background: var(--color-bg);
  border-radius: 11px;
}

.recent-item__info {
  min-width: 0;
}

.recent-item__title {
  color: var(--color-text);
  font-size: 0.84rem;
  font-weight: 500;
  line-height: 1.4;
  overflow-wrap: anywhere;
}

.recent-item__date {
  margin-top: 2px;
  color: var(--color-muted);
  font-size: 0.72rem;
}

.recent-empty {
  padding: 12px 4px;
  color: var(--color-muted);
  font-size: 0.84rem;
}

@media (min-width: 640px) {
  .family-dashboard {
    gap: 24px;
  }

  .last-request {
    padding: 18px 20px;
  }

  .last-request__title {
    font-size: 1.05rem;
  }

  .summary-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
    gap: 16px;
  }

  .summary-card,
  .recent-card {
    padding: 18px;
  }
}

@media (min-width: 1024px) {
  .summary-grid {
    grid-template-columns: repeat(4, minmax(0, 1fr));
  }

  .summary-card {
    padding: 20px;
  }

  .summary-value {
    font-size: 1.6rem;
  }

  .recent-card {
    padding: 22px;
  }
}
</style>
