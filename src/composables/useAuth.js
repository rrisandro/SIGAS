import { ref } from 'vue'

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

// Función para guardar la sesión del usuario autenticado con Supabase
function setSession(userData) {
  localStorage.setItem(SESSION_KEY, JSON.stringify(userData))
  currentUser.value = userData
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
    setSession,
    logout,
    isAuthenticated,
    requireAuth,
    loadSession,
  }
}

export { useAuth, loadSession }