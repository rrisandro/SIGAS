import { ref } from 'vue'
import { supabase } from '../lib/supabase'

export function useFamilias() {
    const familias = ref([])
    const loading = ref(false)
    const error = ref(null)

    async function fetchFamilias() {
        loading.value = true
        error.value = null

        const { data, error: err } = await supabase
        .from('familias')
        .select(`
            *,
            calle:calles (id_calle, nombre),
            cargo:cargos (id_cargo, nombre)
        `)
        .order('id', { ascending: false })

        if (err) error.value = err.message
        else familias.value = data

        loading.value = false
    }

    async function createFamilia(familia) {
        const { data, error: err } = await supabase
        .from('familias')
        .insert([{
            nombre_familia: familia.nombre_familia,
            id_calle: familia.id_calle,
            id_cargo: familia.id_cargo,
            activo: true
        }])
        .select()
        .single()

        if (err) {
        error.value = err.message
        return null
        }

        await fetchFamilias()
        return data
    }

    async function updateFamilia(id, updates) {
        const { data, error: err } = await supabase
        .from('familias')
        .update(updates)
        .eq('id', id)
        .select()
        .single()

        if (err) {
        error.value = err.message
        return null
        }

        await fetchFamilias()
        return data
    }

    return { familias, loading, error, fetchFamilias, createFamilia, updateFamilia }
}
