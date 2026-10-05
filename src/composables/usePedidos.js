    import { ref } from 'vue'
    import { supabase } from '../lib/supabase'

    export function usePedidos() {
    const pedidos = ref([])
    const loading = ref(false)
    const error = ref(null)

    async function fetchPedidos() {
        loading.value = true
        error.value = null

        const { data, error: err } = await supabase
        .from('pedidos')
        .select(`
            *,
            familia:familias (
            id,
            nombre_familia
            )
        `)
        .order('fecha_solicitud', { ascending: false })

        if (err) {
        console.error('Error fetching pedidos:', err)
        error.value = err.message
        pedidos.value = []
        } else {
        pedidos.value = data || []
        }

        loading.value = false
    }


async function createPedido(pedido) {
  const { data, error } = await supabase
    .from('pedidos')
    .insert([
      {
        id_familias: pedido.id_familias,
        id_ciclo: pedido.id_ciclo, // <--- ¡Asegúrate de tener esta línea!
        tipo_bombona: pedido.tipo_bombona,
        pico: pedido.pico,
        status: pedido.status || 'pendiente'
      }
    ])
    .select()

  if (error) {
    console.error('Error en createPedido:', error.message)
    return null
  }

  return data ? data[0] : null
}

    async function updateStatus(id_pedido, status) {
        const { data, error: err } = await supabase
        .from('pedidos')
        .update({ status })
        .eq('id_pedido', id_pedido)
        .select()
        .single()

        if (err) {
        error.value = err.message
        return null
        }

        await fetchPedidos()
        return data
    }

    // ✅ FUNCIÓN QUE FALTABA
    async function registrarEntrega(id_pedido, ciclo_distribucion) {
        console.log('registrarEntrega llamada con:', { id_pedido, ciclo_distribucion })
        
        try {
        // 1. Actualizar pedido a 'entregado'
        const { error: errPedido } = await supabase
            .from('pedidos')
            .update({ 
            status: 'entregado',
            fecha_entrega: new Date().toISOString()
            })
            .eq('id_pedido', id_pedido)

        if (errPedido) {
            console.error('Error actualizando pedido:', errPedido)
            throw errPedido
        }

        // 2. Registrar en historial
        const { error: errHistorial } = await supabase
            .from('historial_distribucion')
            .insert([{
            id_pedido: id_pedido,
            ciclo_distribucion: ciclo_distribucion,
            fecha_entrega: new Date().toISOString()
            }])

        if (errHistorial) {
            console.error('Error insertando historial:', errHistorial)
            throw errHistorial
        }

        await fetchPedidos()
        return true
        } catch (err) {
        console.error('Error en registrarEntrega:', err)
        error.value = err.message
        return false
        }
    }

    // ✅ IMPORTANTE: Incluir registrarEntrega en el return
    return { 
        pedidos, 
        loading, 
        error, 
        fetchPedidos, 
        createPedido, 
        updateStatus,
        registrarEntrega  // ← ESTA LÍNEA ES LA QUE FALTABA
    }
    }