<template>
  <div class="space-y-6">
    <div>
      <h2 class="text-2xl font-bold text-gray-800">Dashboard</h2>
      <p class="text-sm text-gray-500 mt-1">
        Métricas de {{ jefe?.calle?.nombre || 'tu calle' }}
      </p>
    </div>

    <!-- Tarjetas de métricas -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">

      <!-- Familias activas -->
      <div class="bg-white rounded-lg border border-gray-200 p-5">
        <div class="flex items-center gap-4">
          <div
            class="w-11 h-11 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center flex-shrink-0"
          >
            <!-- Users -->
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="w-5 h-5"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.8"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
              <circle cx="9" cy="7" r="4" />
              <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
              <path d="M16 3.13a4 4 0 0 1 0 7.75" />
            </svg>
          </div>

          <div>
            <p class="text-xs text-gray-500 uppercase tracking-wide">
              Familias activas
            </p>
            <p class="text-2xl font-bold text-gray-800">
              {{ stats.familiasActivas }}
            </p>
          </div>
        </div>
      </div>

      <!-- Pendientes -->
      <div class="bg-white rounded-lg border border-gray-200 p-5">
        <div class="flex items-center gap-4">
          <div
            class="w-11 h-11 rounded-lg bg-yellow-50 text-yellow-600 flex items-center justify-center flex-shrink-0"
          >
            <!-- Clock / Pending -->
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="w-5 h-5"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.8"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <circle cx="12" cy="12" r="9" />
              <path d="M12 7v5l3 2" />
            </svg>
          </div>

          <div>
            <p class="text-xs text-gray-500 uppercase tracking-wide">
              Pendientes
            </p>
            <p class="text-2xl font-bold text-gray-800">
              {{ stats.pendientes }}
            </p>
          </div>
        </div>
      </div>

      <!-- En proceso -->
      <div class="bg-white rounded-lg border border-gray-200 p-5">
        <div class="flex items-center gap-4">
          <div
            class="w-11 h-11 rounded-lg bg-purple-50 text-purple-600 flex items-center justify-center flex-shrink-0"
          >
            <!-- Clock -->
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="w-5 h-5"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.8"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <circle cx="12" cy="12" r="9" />
              <path d="M12 7v5l3 2" />
            </svg>
          </div>

          <div>
            <p class="text-xs text-gray-500 uppercase tracking-wide">
              En proceso
            </p>
            <p class="text-2xl font-bold text-gray-800">
              {{ stats.enProceso }}
            </p>
          </div>
        </div>
      </div>

      <!-- Entregadas -->
      <div class="bg-white rounded-lg border border-gray-200 p-5">
        <div class="flex items-center gap-4">
          <div
            class="w-11 h-11 rounded-lg bg-green-50 text-green-600 flex items-center justify-center flex-shrink-0"
          >
            <!-- Check -->
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="w-5 h-5"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              stroke-width="1.8"
              stroke-linecap="round"
              stroke-linejoin="round"
            >
              <path d="M20 6 9 17l-5-5" />
            </svg>
          </div>

          <div>
            <p class="text-xs text-gray-500 uppercase tracking-wide">
              Entregadas
            </p>
            <p class="text-2xl font-bold text-gray-800">
              {{ stats.entregadas }}
            </p>
          </div>
        </div>
      </div>

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