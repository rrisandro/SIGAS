<template>
  <header class="app-header">
    <button
      type="button"
      class="header-icon-btn menu-btn"
      aria-label="Abrir menú de navegación"
      aria-controls="app-sidebar"
      @click="$emit('toggle-sidebar')"
    >
      <Menu :size="22" />
    </button>

    <RouterLink to="/" class="app-header__brand" aria-label="SIGAS, ir al panel">
      <span class="brand-mark">
        <Flame :size="18" />
      </span>
      <span class="brand-text">SIGAS</span>
    </RouterLink>

    <div class="app-header__page">
      <p class="app-header__title">{{ title }}</p>
      <p class="app-header__subtitle">{{ subtitle }}</p>
    </div>

    <div class="app-header__actions">
      <!-- CAMPANA DE NOTIFICACIONES CON AUDITORÍA REAL DE SUPABASE -->
      <div class="notifications-wrapper">
        <button
          type="button"
          class="header-icon-btn notification-btn"
          :class="{ active: mostrarNotificaciones }"
          aria-label="Historial de auditoría y cambios"
          title="Historial de Auditoría y Cambios"
          :aria-expanded="mostrarNotificaciones"
          @click="toggleNotificaciones"
        >
          <svg viewBox="0 0 24 24" class="notification-icon" aria-hidden="true">
            <path
              fill="currentColor"
              d="M12 22c1.1 0 2-.9 2-2h-4c0 1.1.89 2 2 2zm6-6v-5c0-3.07-1.64-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.63 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z"
            />
          </svg>
          <span v-if="notificacionesNoLeidas > 0" class="notification-badge">
            {{ notificacionesNoLeidas }}
          </span>
        </button>

        <!-- PANEL DESPLEGABLE DE AUDITORÍA -->
        <div v-if="mostrarNotificaciones" class="notifications-dropdown">
          <div class="dropdown-header">
            <div>
              <h3>Auditoría de Cambios</h3>
              <p>Registro de actividad del sistema</p>
            </div>
            <button type="button" class="btn-clear" @click="cargarAuditoriaReal">
              Actualizar
            </button>
          </div>

          <div class="dropdown-body">
            <div v-if="loading" class="loading-notif">
              Cargando reportes de auditoría...
            </div>

            <template v-else>
              <div
                v-for="item in listaAuditoria"
                :key="item.id || item.id_auditoria"
                class="notification-item"
                :class="{ unread: !item.leida }"
                @click="item.leida = true"
              >
                <div class="notif-icon audit">
                  <svg viewBox="0 0 24 24" aria-hidden="true">
                    <path
                      fill="currentColor"
                      d="M14 2H6c-1.1 0-1.99.9-1.99 2L4 20c0 1.1.89 2 1.99 2H18c1.1 0 2-.9 2-2V8l-6-6zm2 16H8v-2h8v2zm0-4H8v-2h8v-2zm-3-5V3.5L18.5 9H13z"
                    />
                  </svg>
                </div>
                <div class="notif-content">
                  <p class="notif-title">{{ item.accion || 'Acción Registrada' }}</p>
                  <p class="notif-desc">{{ item.descripcion || 'Sin detalles adicionales' }}</p>
                  <span class="notif-time">
                    <strong>{{ item.usuario || item.autor || 'Administrador' }}</strong>
                    <span aria-hidden="true"> · </span>
                    {{ item.fecha ? new Date(item.fecha).toLocaleString('es-VE') : 'Reciente' }}
                  </span>
                </div>
              </div>

              <div v-if="listaAuditoria.length === 0" class="empty-notif">
                No hay registros de auditoría en la base de datos.
              </div>
            </template>
          </div>
        </div>
      </div>

      <div class="user-meta">
        <p class="user-name">{{ currentUser?.nombre }}</p>
        <p class="user-role">{{ currentUser?.rol }}</p>
      </div>

      <span class="user-avatar" aria-hidden="true">{{ userInitial }}</span>

      <button
        type="button"
        class="header-icon-btn logout-btn"
        aria-label="Cerrar sesión"
        title="Cerrar sesión"
        @click="handleLogout"
      >
        <LogOut :size="20" />
        <span class="logout-label">Salir</span>
      </button>
    </div>
  </header>
</template>

<script setup>
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Menu, LogOut, Flame } from '../icons.js'
import { useAuth } from '../../composables/useAuth.js'
import { supabase } from '../../composables/supabase.js'
import { menuByRole } from '../../data/menu.js'

defineEmits(['toggle-sidebar'])

const route = useRoute()
const router = useRouter()
const { currentUser, logout } = useAuth()

const mostrarNotificaciones = ref(false)
const loading = ref(false)
const listaAuditoria = ref([])

const title = computed(() => {
  const rol = currentUser.value?.rol
  const segment = route.path.split('/').filter(Boolean).pop()
  const item = menuByRole[rol]?.find((m) => m.path === segment)
  return item?.label || 'Panel'
})

const subtitle = computed(() => {
  const map = {
    admin: 'Administración del sistema',
    jefe: 'Gestión de calle',
    familia: 'Solicitudes de gas',
  }
  return map[currentUser.value?.rol] || ''
})

const userInitial = computed(() => {
  const name = currentUser.value?.nombre?.trim()
  return name ? name.charAt(0).toUpperCase() : 'U'
})

const notificacionesNoLeidas = computed(() => {
  return listaAuditoria.value.filter((item) => !item.leida).length
})

function toggleNotificaciones() {
  mostrarNotificaciones.value = !mostrarNotificaciones.value
  if (mostrarNotificaciones.value) {
    cargarAuditoriaReal()
  }
}

async function cargarAuditoriaReal() {
  loading.value = true
  try {
    const { data, error } = await supabase
      .from('auditoria')
      .select('*')
      .order('fecha', { ascending: false })
      .limit(6)

    if (!error && data) {
      listaAuditoria.value = data.map((item) => ({
        ...item,
        leida: false,
      }))
    }
  } catch (e) {
    console.error('Error cargando auditoría:', e)
  } finally {
    loading.value = false
  }
}

function handleLogout() {
  try {
    logout()
  } catch (e) {
    console.error('Error en logout:', e)
  } finally {
    localStorage.removeItem('user')
    localStorage.removeItem('supabase.auth.token')
    mostrarNotificaciones.value = false
    router.push('/login')
  }
}

watch(
  () => route.fullPath,
  () => {
    mostrarNotificaciones.value = false
  }
)

onMounted(() => {
  cargarAuditoriaReal()
})
</script>

<style scoped>
.app-header {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 80;
  display: flex;
  align-items: center;
  gap: 8px;
  height: var(--header-height);
  padding: 0 10px 0 max(10px, var(--safe-left));
  padding-right: max(10px, var(--safe-right));
  background: rgba(255, 255, 255, 0.96);
  border-bottom: 1px solid var(--color-border-light);
  box-shadow: 0 1px 4px rgba(15, 23, 42, 0.04);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
}

.header-icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  min-width: 44px;
  min-height: 44px;
  padding: 0;
  border: 0;
  border-radius: 12px;
  background: transparent;
  color: var(--color-muted);
  cursor: pointer;
  transition: background-color var(--transition-fast), color var(--transition-fast);
}

.header-icon-btn:hover,
.header-icon-btn.active {
  background: var(--color-bg);
  color: var(--color-heading);
}

.header-icon-btn:active {
  background: var(--color-border-light);
}

.menu-btn {
  margin-right: 2px;
}

.app-header__brand {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  flex-shrink: 0;
  min-height: 44px;
  white-space: nowrap;
}

.brand-mark {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 10px;
  background: var(--color-primary);
  color: #ffffff;
  box-shadow: 0 2px 6px rgba(14, 165, 233, 0.35);
}

.brand-text {
  color: var(--color-primary-darker);
  font-size: 0.95rem;
  font-weight: 700;
  letter-spacing: 0.02em;
}

.app-header__page {
  display: none;
  min-width: 0;
  padding-left: 4px;
}

.app-header__title {
  overflow: hidden;
  color: var(--color-heading);
  font-size: 0.9rem;
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.app-header__subtitle {
  overflow: hidden;
  color: var(--color-muted);
  font-size: 0.7rem;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.app-header__actions {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-left: auto;
}

.notifications-wrapper {
  position: relative;
  display: flex;
}

.notification-btn {
  position: relative;
}

.notification-icon {
  width: 21px;
  height: 21px;
}

.notification-badge {
  position: absolute;
  top: 3px;
  right: 3px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 18px;
  height: 18px;
  padding: 0 4px;
  border: 2px solid #ffffff;
  border-radius: 10px;
  background: var(--color-danger);
  color: #ffffff;
  font-size: 0.65rem;
  font-weight: 700;
  line-height: 1;
}

.notifications-dropdown {
  position: fixed;
  top: calc(var(--header-height) + 6px);
  left: max(8px, var(--safe-left));
  right: max(8px, var(--safe-right));
  z-index: 120;
  display: flex;
  flex-direction: column;
  max-height: calc(100dvh - var(--header-height) - 16px);
  overflow: hidden;
  background: #ffffff;
  border: 1px solid var(--color-border);
  border-radius: 16px;
  box-shadow: 0 16px 40px -18px rgba(15, 23, 42, 0.4);
}

.dropdown-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-shrink: 0;
  padding: 12px 16px;
  background: var(--color-bg);
  border-bottom: 1px solid var(--color-border-light);
}

.dropdown-header h3 {
  margin: 0;
  color: var(--color-heading);
  font-size: 0.9rem;
  font-weight: 700;
}

.dropdown-header p {
  margin: 2px 0 0;
  color: var(--color-muted);
  font-size: 0.72rem;
}

.btn-clear {
  flex-shrink: 0;
  min-height: 36px;
  padding: 0 10px;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  background: #ffffff;
  color: var(--color-primary-darker);
  font-size: 0.75rem;
  font-weight: 600;
  cursor: pointer;
}

.btn-clear:hover {
  background: var(--color-primary-soft);
}

.dropdown-body {
  overflow-y: auto;
  overscroll-behavior: contain;
}

.loading-notif,
.empty-notif {
  padding: 28px 16px;
  color: var(--color-muted);
  font-size: 0.82rem;
  text-align: center;
}

.notification-item {
  display: flex;
  gap: 12px;
  padding: 12px 16px;
  border-bottom: 1px solid var(--color-border-light);
  cursor: pointer;
  transition: background-color var(--transition-fast);
}

.notification-item:last-child {
  border-bottom: 0;
}

.notification-item:hover {
  background: var(--color-bg);
}

.notification-item.unread {
  background: var(--color-primary-soft);
}

.notif-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 34px;
  height: 34px;
  border-radius: 10px;
  background: var(--color-primary-soft);
  color: var(--color-primary-darker);
}

.notif-icon svg {
  width: 17px;
  height: 17px;
}

.notif-content {
  min-width: 0;
}

.notif-title {
  margin: 0;
  color: var(--color-heading);
  font-size: 0.82rem;
  font-weight: 700;
}

.notif-desc {
  margin: 2px 0 0;
  color: var(--color-muted);
  font-size: 0.76rem;
  line-height: 1.4;
}

.notif-time {
  display: block;
  margin-top: 5px;
  color: var(--color-muted);
  font-size: 0.68rem;
}

.user-meta {
  display: none;
  max-width: 150px;
  text-align: right;
}

.user-name,
.user-role {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.user-name {
  color: var(--color-heading);
  font-size: 0.8rem;
  font-weight: 600;
}

.user-role {
  color: var(--color-muted);
  font-size: 0.68rem;
  text-transform: capitalize;
}

.user-avatar {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  border-radius: 50%;
  background: var(--color-primary-soft);
  color: var(--color-primary-darker);
  font-size: 0.8rem;
  font-weight: 700;
}

.logout-btn {
  gap: 6px;
  color: var(--color-muted);
}

.logout-label {
  display: none;
  font-size: 0.8rem;
  font-weight: 500;
}

@media (max-width: 359.98px) {
  .brand-text {
    display: none;
  }
}

@media (min-width: 480px) {
  .logout-label {
    display: inline;
  }

  .logout-btn {
    padding: 0 12px;
  }
}

@media (min-width: 640px) {
  .app-header {
    height: 64px;
    padding-left: 16px;
    padding-right: 16px;
  }

  .app-header__brand {
    position: static;
    transform: none;
    margin-right: 12px;
  }

  .app-header__page {
    display: block;
    padding-left: 12px;
    border-left: 1px solid var(--color-border);
  }

  .user-meta {
    display: block;
  }

  .notifications-dropdown {
    position: absolute;
    top: calc(100% + 8px);
    right: 0;
    left: auto;
    width: 360px;
    max-height: min(480px, calc(100dvh - 96px));
  }
}

@media (min-width: 768px) {
  .brand-text {
    font-size: 1rem;
  }
}

@media (min-width: 1024px) {
  .app-header {
    left: var(--sidebar-width);
  }

  .menu-btn,
  .app-header__brand {
    display: none;
  }

  .app-header__page {
    padding-left: 0;
    border-left: 0;
  }

  .logout-btn {
    display: none;
  }
}
</style>
