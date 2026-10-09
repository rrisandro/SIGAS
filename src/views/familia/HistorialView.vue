<template>
  <div class="p-6 max-w-5xl mx-auto">
    <h2 class="text-2xl font-bold mb-2 text-gray-800">Mi Historial</h2>
    <p class="text-sm text-gray-500 mb-6">Todas tus solicitudes registradas</p>

    <div class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
      <!-- Barra superior (Buscador visual) -->
      <div class="p-4 border-b border-gray-100 flex justify-between items-center">
        <h3 class="font-medium text-gray-700">Solicitudes</h3>
        <input 
          type="text" 
          placeholder="Buscar..." 
          class="border border-gray-300 rounded-md px-3 py-1.5 text-sm focus:outline-none focus:border-sky-400 focus:ring-2 focus:ring-sky-100"
        >
      </div>

      <!-- Estado de carga -->
      <div v-if="cargando" class="p-8 text-center text-gray-500">
        Cargando tu historial de pedidos...
      </div>

      <!-- Tabla de datos -->
      <div v-else class="overflow-x-auto">
        <table class="w-full text-left text-sm text-gray-600">
          <thead class="bg-gray-50 text-gray-700 border-b border-gray-100">
            <tr>
              <th class="px-4 py-3 font-medium">#</th>
              <th class="px-4 py-3 font-medium">Fecha</th>
              <th class="px-4 py-3 font-medium">Tipo</th>
              <th class="px-4 py-3 font-medium">Pico</th>
              <th class="px-4 py-3 font-medium">Estatus</th>
              <th class="px-4 py-3 font-medium">Observaciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-if="pedidos.length === 0">
              <td colspan="6" class="px-4 py-8 text-center text-gray-500">
                No hay registros
              </td>
            </tr>
            
            <tr 
              v-for="(pedido, index) in pedidos" 
              :key="pedido.id_pedido"
              class="border-b border-gray-50 hover:bg-gray-50"
            >
              <td class="px-4 py-3">{{ pedido.id_pedido }}</td>
              <td class="px-4 py-3">{{ formatearFecha(pedido.fecha_solicitud) }}</td>
              <td class="px-4 py-3">{{ pedido.tipo_bombona }}</td>
              <td class="px-4 py-3">{{ pedido.pico }}</td>
              
              <!-- Estatus enlazado a los colores reales de tu CSS (amber y emerald) -->
              <td class="px-4 py-3">
                <span 
                  class="inline-block px-3 py-1 rounded-full text-xs font-medium capitalize"
                  :class="{
                    'bg-amber-100 text-amber-800': pedido.status && String(pedido.status).trim().toLowerCase() === 'pendiente',
                    'bg-emerald-100 text-emerald-800': pedido.status && String(pedido.status).trim().toLowerCase() === 'entregado'
                  }"
                >
                  {{ String(pedido.status).trim() }}
                </span>
              </td>
              
              <td class="px-4 py-3 text-gray-400">
                {{ pedido.observaciones || '-' }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Paginación (Visual) -->
      <div class="p-4 border-t border-gray-100 flex justify-between items-center text-sm text-gray-500">
        <span>{{ pedidos.length }} registro(s)</span>
        <div class="flex space-x-2">
          <button class="px-3 py-1 border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50">Anterior</button>
          <span class="px-2 py-1">1 / 1</span>
          <button class="px-3 py-1 border border-gray-300 rounded-md hover:bg-gray-50 disabled:opacity-50">Siguiente</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'

const pedidos = ref([])
const cargando = ref(true)
const error = ref('')

onMounted(async () => {
  const { data: { user }, error: authError } = await supabase.auth.getUser()

  if (user && !authError) {
    const { data: familiaData } = await supabase
      .from('familias')
      .select('id')
      .eq('auth_id', user.id)
      .single()

    if (familiaData) {
      const { data: pedidosData, error: pedidosError } = await supabase
        .from('pedidos')
        .select('*')
        .eq('id_familias', familiaData.id)
        .order('status', { ascending: false }) 
        .order('fecha_solicitud', { ascending: false })

      if (pedidosData) {
        pedidos.value = pedidosData
      } else if (pedidosError) {
        console.error("Error al cargar historial:", pedidosError)
      }
    }
  } else {
    error.value = "Sesión no válida"
  }
  
  cargando.value = false
})

function formatearFecha(fechaString) {
  if (!fechaString) return 'Sin fecha'
  const fecha = new Date(fechaString)
  return fecha.toLocaleDateString('es-VE')
}
</script>