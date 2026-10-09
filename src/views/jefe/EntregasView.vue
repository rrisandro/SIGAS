<template>
  <div class="space-y-6">
    <!-- Header y Filtro por Ciclo -->
    <div class="flex flex-wrap items-center justify-between gap-4 bg-white p-4 rounded-xl border border-gray-200 shadow-sm">
      <div>
        <h2 class="text-xl font-medium text-gray-800">Control de Entregas</h2>
        <p class="text-sm text-gray-500">Gestión de entregas sectorizadas por jornada</p>
      </div>

      <!-- Desplegable para Filtrar por Ciclo -->
      <div class="flex items-center gap-2">
        <label class="text-sm font-medium text-gray-700 whitespace-nowrap">Filtrar por Ciclo:</label>
        <select
          v-model="cicloSeleccionado"
          class="px-3 py-2 border border-gray-300 rounded-lg text-sm bg-white focus:outline-none focus:ring-2 focus:ring-green-500 shadow-sm"
        >
          <option value="todos">Todos los Ciclos</option>
          <option v-for="ciclo in listaCiclos" :key="ciclo.id_ciclo" :value="ciclo.id_ciclo">
            {{ ciclo.nombre_ciclo }} {{ ciclo.estado === 'activo' ? '(Activo)' : '' }}
          </option>
        </select>
      </div>
    </div>

    <!-- Indicador de Carga -->
    <div v-if="cargando" class="py-8 text-center text-gray-500">
      Cargando información de entregas...
    </div>

    <div v-else class="space-y-6">
      <!-- Entregas Pendientes (Pedidos Aceptados) -->
      <CrudDataTable
        title="Pedidos Aceptados (Pendientes por Entrega)"
        :columns="columnsPendientes"
        :rows="pedidosPendientes"
        :search-keys="['familia', 'calle', 'tipo']"
      >
        <template #cell-estatus="{ row }">
          <StatusBadge :status="row.estatus" />
        </template>
        <template #actions="{ row }">
          <BaseButton size="sm" variant="success" @click="openEntrega(row)">
            Registrar Entrega
          </BaseButton>
        </template>
      </CrudDataTable>

      <!-- Historial de Entregas Realizadas -->
      <CrudDataTable
        title="Historial de Entregas Realizadas"
        :columns="columnsHistorial"
        :rows="entregasRealizadas"
        :search-keys="['familia', 'tipo', 'ciclo']"
      >
        <template #cell-fecha_entrega="{ row }">
          {{ formatearFecha(row.fecha_entrega) }}
        </template>
      </CrudDataTable>
    </div>

    <!-- Modal para registrar entrega -->
    <div v-if="showEntrega" class="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div class="absolute inset-0 bg-black/40 backdrop-blur-sm" @click="showEntrega = false" />
      <div class="relative w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl space-y-4">
        <!-- Header del modal -->
        <div class="flex items-center gap-3">
          <div class="w-10 h-10 rounded-full bg-green-100 flex items-center justify-center">
            <svg class="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <div>
            <h3 class="text-lg font-semibold text-gray-800">Confirmar Entrega</h3>
            <p class="text-sm text-gray-500">
              {{ selected?.familia || 'Familia' }} — Bombona {{ selected?.tipo || '' }}
            </p>
          </div>
        </div>

        <div class="border-t border-gray-200 my-2" />

        <p class="text-sm text-gray-600">
          ¿Confirmas que la bombona ha sido despachada y entregada exitosamente al usuario? Esta acción cambiará el estado del pedido a <strong class="text-green-600">entregado</strong> y guardará la constancia en el historial.
        </p>

        <!-- Error -->
        <p v-if="errorEntrega" class="text-sm text-red-600 font-medium">
          {{ errorEntrega }}
        </p>

        <div class="border-t border-gray-200 my-2" />

        <!-- Botones -->
        <div class="flex justify-end gap-2">
          <BaseButton variant="ghost" @click="showEntrega = false">Cancelar</BaseButton>
          <BaseButton variant="success" :disabled="guardando" @click="confirmarEntrega">
            {{ guardando ? 'Guardando...' : 'Confirmar Entrega' }}
          </BaseButton>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref, onMounted } from 'vue'
import CrudDataTable from '../../components/ui/CrudDataTable.vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import { supabase } from '../../lib/supabase'

const showEntrega = ref(false)
const selected = ref(null)
const errorEntrega = ref('')
const cargando = ref(true)
const guardando = ref(false)

const listaPedidos = ref([])
const historialEntregas = ref([])
const listaCiclos = ref([])
const cicloSeleccionado = ref('todos') // 'todos' o ID del ciclo seleccionado

const columnsPendientes = [
  { key: 'id', label: '#' },
  { key: 'fecha', label: 'Fecha Solicitud' },
  { key: 'familia', label: 'Familia' },
  { key: 'calle', label: 'Calle' },
  { key: 'tipo', label: 'Tipo' },
  { key: 'estatus', label: 'Estatus' },
]

const columnsHistorial = [
  { key: 'id', label: '#' },
  { key: 'familia', label: 'Familia' },
  { key: 'tipo', label: 'Tipo' },
  { key: 'ciclo', label: 'Ciclo' },
  { key: 'fecha_entrega', label: 'Fecha Entrega' },
]

// Filtra los pedidos pendientes considerando el ciclo seleccionado
const pedidosPendientes = computed(() => {
  return listaPedidos.value
    .filter((p) => {
      const esAceptado = p.status === 'aceptado'
      const coincideCiclo = cicloSeleccionado.value === 'todos' || p.id_ciclo === Number(cicloSeleccionado.value)
      return esAceptado && coincideCiclo
    })
    .map((p) => ({
      id: p.id_pedido,
      fecha: formatearFecha(p.fecha_solicitud || p.created_at),
      familia: p.familias?.nombre_familia || 'Familia no registrada',
      calle: p.familias?.calles?.nombre || 'Sin calle',
      tipo: `${p.tipo_bombona} (${p.pico})`,
      estatus: p.status,
      _original: p
    }))
})

// Mapea y filtra las entregas realizadas por el ciclo seleccionado
const entregasRealizadas = computed(() => {
  return historialEntregas.value
    .filter((h) => {
      if (cicloSeleccionado.value === 'todos') return true
      return h.id_ciclo === Number(cicloSeleccionado.value)
    })
    .map((h) => {
      const pedidoRel = h.pedidos || h.pedido || listaPedidos.value.find(p => p.id_pedido === h.id_pedido)
      const nombreFamilia = pedidoRel?.familias?.nombre_familia || pedidoRel?.familia?.nombre_familia || 'Familia'
      const tipoBombona = pedidoRel?.tipo_bombona ? `Bombona ${pedidoRel.tipo_bombona}` : 'Bombona'
      
      const nombreCiclo = h.ciclos_distribucion?.nombre_ciclo 
                       || pedidoRel?.ciclos_distribucion?.nombre_ciclo 
                       || h.ciclo_distribucion 
                       || 'Ciclo General'

      return {
        id: h.id_historial || h.id_pedido,
        familia: nombreFamilia,
        tipo: tipoBombona,
        ciclo: nombreCiclo,
        fecha_entrega: h.fecha_entrega,
        _original: h
      }
    })
})

async function cargarDatos() {
  cargando.value = true

  // 1. Cargar catálogo de ciclos de distribución para el desplegable
  const { data: ciclosData } = await supabase
    .from('ciclos_distribucion')
    .select('id_ciclo, nombre_ciclo, estado')
    .order('id_ciclo', { ascending: false })

  listaCiclos.value = ciclosData || []

  // 2. Cargar pedidos con sus relaciones
  const { data: pedidosData, error: errPedidos } = await supabase
    .from('pedidos')
    .select(`
      *,
      familias (
        id,
        nombre_familia,
        calles (id_calle, nombre)
      ),
      ciclos_distribucion (
        id_ciclo,
        nombre_ciclo
      )
    `)
    .order('id_pedido', { ascending: false })

  if (!errPedidos) {
    listaPedidos.value = pedidosData || []
  }

  // 3. Cargar el historial de entregas
  const { data: historialData, error: errHistorial } = await supabase
    .from('historial_distribucion')
    .select(`
      id_historial,
      id_pedido,
      id_ciclo,
      ciclo_distribucion,
      fecha_entrega,
      pedidos:id_pedido (
        id_pedido,
        tipo_bombona,
        pico,
        status,
        familias (
          id,
          nombre_familia
        )
      ),
      ciclos_distribucion:id_ciclo (
        id_ciclo,
        nombre_ciclo
      )
    `)
    .order('fecha_entrega', { ascending: false })

  if (errHistorial || !historialData || historialData.length === 0) {
    const { data: fallbackHistorial } = await supabase
      .from('historial_distribucion')
      .select('*')
      .order('fecha_entrega', { ascending: false })

    historialEntregas.value = fallbackHistorial || []
  } else {
    historialEntregas.value = historialData || []
  }

  cargando.value = false
}

onMounted(async () => {
  await supabase.auth.getSession()
  await cargarDatos()
})

function openEntrega(row) {
  selected.value = row
  errorEntrega.value = ''
  showEntrega.value = true
}

async function confirmarEntrega() {
  if (!selected.value) return

  guardando.value = true
  errorEntrega.value = ''

  const pedidoObj = selected.value._original

  // A. Actualizar estado a 'entregado' en la tabla pedidos
  const { error: errUpdate } = await supabase
    .from('pedidos')
    .update({ status: 'entregado' })
    .eq('id_pedido', pedidoObj.id_pedido)

  if (errUpdate) {
    errorEntrega.value = 'Error al actualizar el pedido: ' + errUpdate.message
    guardando.value = false
    return
  }

  const nombreCicloReal = pedidoObj.ciclos_distribucion?.nombre_ciclo || 'Ciclo General'

  // B. Registrar la constancia en 'historial_distribucion'
  const { error: errHistorial } = await supabase
    .from('historial_distribucion')
    .insert([
      {
        id_pedido: pedidoObj.id_pedido,
        id_ciclo: pedidoObj.id_ciclo,
        ciclo_distribucion: nombreCicloReal,
        fecha_entrega: new Date().toISOString()
      }
    ])

  guardando.value = false

  if (errHistorial) {
    errorEntrega.value = 'Error al registrar en historial: ' + errHistorial.message
  } else {
    showEntrega.value = false
    selected.value = null
    await cargarDatos()
  }
}

function formatearFecha(fecha) {
  if (!fecha) return '-'
  return new Date(fecha).toLocaleDateString('es-VE')
}
</script>