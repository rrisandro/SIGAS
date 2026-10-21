import { supabase } from './supabase.js'

export function useAuditoria() {
  async function registrarAccion(accion, descripcion, usuario = 'Jhonjairo Carusi') {
    try {
      await supabase.from('auditoria').insert([
        {
          accion: accion,
          descripcion: descripcion,
          usuario: usuario,
          fecha: new Date().toISOString()
        }
      ])
    } catch (e) {
      console.error('Error registrando auditoría:', e)
    }
  }

  return {
    registrarAccion
  }
}