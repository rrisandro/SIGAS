<template>
  <div class="page familias-jefe-page space-y-6">
    <div class="page-heading flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
      <div>
        <h2 class="page-title">Familias a Cargo</h2>
        <p class="page-subtitle">
          Sector asignado: <strong>{{ nombreSector || 'Cargando...' }}</strong>
        </p>
      </div>
    </div>

    <!-- Indicador de Carga -->
    <div v-if="cargando" class="py-8 text-center text-gray-500">
      Cargando familias de tu sector...
    </div>

    <!-- Advertencia si no tiene calle vinculada -->
    <div v-else-if="sinCalleAsignada" class="p-4 bg-red-50 text-red-700 rounded-xl border border-red-200">
      ⚠️ <strong>Atención:</strong> Tu usuario de Jefe de Calle no tiene asignada ninguna calle en el sistema.
    </div>

    <div v-else class="space-y-6">
      <!-- SELECTOR DE PESTAÑAS POR CALLE -->
      <div v-if="callesAgrupadas.length > 0" class="flex flex-wrap gap-2 border-b border-gray-200 pb-3">
        <BaseButton
          v-for="grupo in callesAgrupadas"
          :key="grupo.id_calle"
          :variant="calleActivaTab === grupo.id_calle ? 'primary' : 'ghost'"
          size="sm"
          @click="calleActivaTab = grupo.id_calle"
        >
           {{ grupo.nombre_calle }} ({{ grupo.familias.length }})
        </BaseButton>
      </div>

      <!-- TABLA ÚNICA FILTRADA DINÁMICAMENTE SEGÚN LA PESTAÑA ACTIVA -->
      <div class="bg-white p-5 rounded-2xl border border-gray-200 shadow-sm space-y-4">
        <div class="flex items-center justify-between border-b border-gray-100 pb-3">
          <h3 class="text-lg font-bold text-gray-800 flex items-center gap-2">
             {{ calleSeleccionadaNombre }}
          </h3>
          <span class="text-xs font-semibold px-2.5 py-1 bg-blue-50 text-blue-700 rounded-full border border-blue-100">
            {{ familiasDeCalleSeleccionada.length }} familias censadas
          </span>
        </div>

        <CrudDataTable
          :title="`Padrón de ${calleSeleccionadaNombre}`"
          :columns="columns"
          :rows="familiasDeCalleSeleccionada"
          :search-keys="['familia', 'solicitud']"
        >
          <template #cell-estatusCiclo="{ row }">
            <StatusBadge :status="row.estatusCiclo" />
          </template>
        </CrudDataTable>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import CrudDataTable from '../../components/ui/CrudDataTable.vue'
import StatusBadge from '../../components/ui/StatusBadge.vue'
import BaseButton from '../../components/ui/BaseButton.vue'
import { supabase } from '../../lib/supabase'

const cargando = ref(true)
const sinCalleAsignada = ref(false)
const callesAgrupadas = ref([])
const nombreSector = ref('')
const calleActivaTab = ref(null)

const columns = [
  { key: 'id', label: 'Cédula / ID' },
  { key: 'familia', label: 'Nombre de la Familia' },
  { key: 'solicitud', label: 'Cilindros / Detalle' },
  { key: 'estatusCiclo', label: 'Estatus en Ciclo Activo' },
]

// 1. Obtiene las familias de la calle actualmente seleccionada
const familiasDeCalleSeleccionada = computed(() => {
  if (!calleActivaTab.value) return []
  const grupo = callesAgrupadas.value.find(c => c.id_calle === calleActivaTab.value)
  return grupo ? grupo.familiasRows : []
})

// 2. Obtiene el nombre de la calle activa para la cabecera de la tabla
const calleSeleccionadaNombre = computed(() => {
  if (!calleActivaTab.value) return ''
  const grupo = callesAgrupadas.value.find(c => c.id_calle === calleActivaTab.value)
  return grupo ? grupo.nombre_calle : ''
})

async function cargarPadronPorCalle() {
  cargando.value = true
  sinCalleAsignada.value = false

  try {
    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      cargando.value = false
      return
    }

    // 1. Obtener datos del jefe de calle logueado
    const { data: jefeData } = await supabase
      .from('jefe_de_calle')
      .select('*')
      .eq('auth_id', user.id)
      .maybeSingle()

    if (!jefeData) {
      sinCalleAsignada.value = true
      cargando.value = false
      return
    }

    // 2. Traer TODAS las calles asignadas a este Jefe de Calle
    const { data: callesAsignadas } = await supabase
      .from('calles')
      .select('id_calle, nombre')
      .eq('id_jefe_calle', jefeData.id_jefe_calle)

    if (!callesAsignadas || callesAsignadas.length === 0) {
      sinCalleAsignada.value = true
      cargando.value = false
      return
    }

    const idsCalles = callesAsignadas.map(c => c.id_calle)
    nombreSector.value = callesAsignadas.map(c => c.nombre).join(', ')

    // 3. Traer solo las familias pertenecientes a estas calles
    const { data: familiasData } = await supabase
      .from('familias')
      .select('*, calles(id_calle, nombre)')
      .in('id_calle', idsCalles)
      .order('nombre_familia', { ascending: true })

    // 4. Consultar si hay un ciclo activo en la comunidad
    const { data: ciclosActivos } = await supabase
      .from('ciclos_distribucion')
      .select('id_ciclo')
      .eq('estado', 'activo')
      .limit(1)

    let pedidosCicloActivo = []
    if (ciclosActivos && ciclosActivos.length > 0 && familiasData && familiasData.length > 0) {
      const idsFamilias = familiasData.map(f => f.id)
      const { data: pedidosData } = await supabase
        .from('pedidos')
        .select('*')
        .eq('id_ciclo', ciclosActivos[0].id_ciclo)
        .in('id_familias', idsFamilias)

      pedidosCicloActivo = pedidosData || []
    }

    // 5. Agrupar familias separadas estrictamente por su calle
    const agrupado = callesAsignadas.map(calle => {
      const familiasDeEstaCalle = (familiasData || []).filter(
        f => Number(f.id_calle) === Number(calle.id_calle)
      )

      const familiasRows = familiasDeEstaCalle.map(f => {
        const pedido = pedidosCicloActivo.find(
          p => String(p.id_familias || p.id_familia) === String(f.id)
        )

        let estatus = 'sin_pedido'
        let detalleBombona = 'Sin solicitud'

        if (pedido) {
          estatus = (pedido.status || 'pendiente').toLowerCase()
          detalleBombona = `Bombona ${pedido.tipo_bombona} (${pedido.pico || 'Sin pico'})`
        }

        return {
          id: `V-${f.id}`,
          familia: f.nombre_familia || 'Sin nombre',
          solicitud: detalleBombona,
          estatusCiclo: estatus,
          _original: f
        }
      })

      return {
        id_calle: calle.id_calle,
        nombre_calle: calle.nombre,
        familias: familiasDeEstaCalle,
        familiasRows
      }
    })

    callesAgrupadas.value = agrupado
    if (agrupado.length > 0) {
      calleActivaTab.value = agrupado[0].id_calle
    }
  } catch (err) {
    console.error('Error al cargar padrón agrupado por calle:', err)
  } finally {
    cargando.value = false
  }
}

onMounted(() => {
  cargarPadronPorCalle()
})
</script>

<style scoped>
.familias-jefe-page {
  display: flex;
  flex-direction: column;
}
</style>