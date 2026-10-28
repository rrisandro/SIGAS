import { ref } from 'vue'
import { supabase } from '../lib/supabase.js'

const SESSION_KEY = 'gas_system_session'
const currentUser = ref(null)

function loadSession() {
  const data = localStorage.getItem(SESSION_KEY)
  if (!data) return
  try {
    currentUser.value = JSON.parse(data)
  } catch {
    currentUser.value = null
    localStorage.removeItem(SESSION_KEY)
  }
}

// Guarda la sesión del usuario autenticado con Supabase.
function setSession(userData) {
  localStorage.setItem(SESSION_KEY, JSON.stringify(userData))
  currentUser.value = userData
}

/**
 * Limpia la sesión local y cierra la sesión de Supabase.
 * Se mantiene síncrona para no romper los llamados existentes.
 */
function logout() {
  try {
    supabase.auth.signOut().catch((error) => {
      console.error('[SIGAS] Error cerrando sesión en Supabase:', error)
    })
  } catch (error) {
    console.error('[SIGAS] Error cerrando sesión:', error)
  } finally {
    localStorage.removeItem(SESSION_KEY)
    localStorage.removeItem('user')
    localStorage.removeItem('supabase.auth.token')
    currentUser.value = null
  }
}

function isAuthenticated() {
  return currentUser.value !== null
}

function requireAuth() {
  return isAuthenticated()
}

async function getAuthUser() {
  const { data, error } = await supabase.auth.getUser()
  if (error) return null
  return data?.user || null
}

function useAuth() {
  return {
    currentUser,
    setSession,
    logout,
    isAuthenticated,
    requireAuth,
    loadSession,
    getAuthUser,
  }
}

export { useAuth, loadSession }
