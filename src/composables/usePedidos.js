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
            nombre_familia,
            activo
        )
        `)
        .order('fecha_solicitud', { ascending: false })

    if (err) error.value = err.message
    else pedidos.value = data

    loading.value = false
    }

    async function createPedido(pedido) {
        const { data, error: err } = await supabase
        .from('pedidos')
        .insert([{
        id_familias: pedido.id_familias,
        tipo_bombona: pedido.tipo_bombona,
        pico: pedido.pico || '',
        status: 'pendiente',
        fecha_solicitud: new Date().toISOString()
        }])
        .select()
        .single()

    if (err) {
        error.value = err.message
        return null
    }

    await fetchPedidos()
    return data
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

    async function registrarEntrega(id_pedido, ciclo) {
    // 1. Actualizar pedido a 'entregado'
    await updateStatus(id_pedido, 'entregado')

    // 2. Registrar en historial
    const { error: err } = await supabase
        .from('historial_distribucion')
        .insert([{
        id_pedido,
        ciclo_distribucion: ciclo,
        fecha_entrega: new Date().toISOString()
        }])

    if (err) {
        error.value = err.message
        return false
    }

    await fetchPedidos()
    return true
    }

    return { pedidos, loading, error, fetchPedidos, createPedido, updateStatus, registrarEntrega }
}