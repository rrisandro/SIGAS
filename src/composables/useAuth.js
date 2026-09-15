// ============================================
// COMPOSABLE: useAuth
// Autenticación simulada
// ============================================

import { ref } from 'vue'
import { useMockData } from './useMockData.js'

const SESSION_KEY = 'gas_system_session'
const currentUser = ref(null)

function loadSession() {
  const data = localStorage.getItem(SESSION_KEY)
  if (data) {
    try {
      currentUser.value = JSON.parse(data)
    } catch {
      currentUser.value = null
    }
  }
}

function login(username, password) {
  const { usuarios } = useMockData()
  const user = usuarios.value.find(
    (u) => u.username === username && u.password === password && u.activo
  )
  if (user) {
    const session = {
      id: user.id,
      username: user.username,
      nombre: user.nombre,
      rol: user.rol,
      entidadId: user.entidadId || null,
    }
    localStorage.setItem(SESSION_KEY, JSON.stringify(session))
    currentUser.value = session
    return session
  }
  return null
}

function logout() {
  localStorage.removeItem(SESSION_KEY)
  currentUser.value = null
}

function isAuthenticated() {
  return currentUser.value !== null
}

function requireAuth() {
  return isAuthenticated()
}

function useAuth() {
  return {
    currentUser,
    login,
    logout,
    isAuthenticated,
    requireAuth,
    loadSession,
  }
}

export { useAuth, loadSession }
