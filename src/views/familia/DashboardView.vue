
<template>
  <div class="space-y-6">
    <div>
      <h2 class="text-xl font-medium text-gray-700">Mi Panel</h2>
      <p class="text-sm text-gray-500">Resumen de tus solicitudes de gas</p>
    </div>

    <!-- Indicador de Carga -->
    <div v-if="cargando" class="py-8 text-center text-gray-500">
      Cargando tu información...
    </div>

    <template v-else>
      <!-- Tarjetas de Resumen -->
      <div class="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <div v-for="card in cards" :key="card.label" class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
          <p class="text-sm text-gray-500">{{ card.label }}</p>
          <p class="mt-2 text-2xl font-medium text-gray-700">{{ card.value }}</p>
        </div>
      </div>

      <!-- Últimas Solicitudes -->
      <div class="rounded-2xl border border-gray-100 bg-white p-5 shadow-sm">
        <h3 class="mb-4 text-base font-medium text-gray-700">Últimas solicitudes</h3>
        <div class="space-y-3">
          <div
            v-for="s in recent"
            :key="s.id_pedido || s.id"
            class="flex items-center justify-between rounded-xl bg-gray-50 px-4 py-3"
          >
            <div>
              <p class="text-sm font-medium text-gray-700">Bombona de {{ s.tipo_bombona }} (Pico {{ s.pico }})</p>
              <p class="text-xs text-gray-500">{{ formatearFecha(s.created_at || s.fecha_solicitud) }}</p>
            </div>
            <StatusBadge :status="s.status" />
          </div>
          <p v-if="!recent.length" class="text-sm text-gray-500">Sin solicitudes aún.</p>
        </div>
      </div>
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
