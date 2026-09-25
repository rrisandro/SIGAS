import { ref } from 'vue'
import { supabase } from '../lib/supabase'

export function useJefesCalle() {
    const jefes = ref([])
    const loading = ref(false)
    const error = ref(null)

    async function fetchJefes() {
    loading.value = true
    error.value = null

    const { data, error: err } = await supabase
        .from('jefe_de_calle')
        .select('*')
        .order('id_jefe_calle', { ascending: false })

    if (err) error.value = err.message
    else jefes.value = data

    loading.value = false
    }

    async function createJefe(jefe) {
    const { data, error: err } = await supabase
    .from('jefe_de_calle')
    .insert([{
        nombre: jefe.nombre,
        ci: jefe.ci,
        activo: true
    }])
    .select()
    .single()

    if (err) {
        error.value = err.message
        return null
    }

    await fetchJefes()
    return data
    }

    async function updateJefe(id, updates) {
    const { data, error: err } = await supabase
    .from('jefe_de_calle')
    .update(updates)
    .eq('id_jefe_calle', id)
    .select()
    .single()

    if (err) {
        error.value = err.message
        return null
    }

    await fetchJefes()
    return data
    }

    async function toggleActivo(id) {
        const jefe = jefes.value.find(j => j.id_jefe_calle === id)
        if (!jefe) return

        const { error: err } = await supabase
        .from('jefe_de_calle')
        .update({ activo: !jefe.activo })
        .eq('id_jefe_calle', id)

        if (err) {
            error.value = err.message
            return false
        }

    await fetchJefes()
    return true
    }

return { jefes, loading, error, fetchJefes, createJefe, updateJefe, toggleActivo }
}