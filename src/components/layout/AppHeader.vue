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
      <div ref="notificationsRef" class="notifications-wrapper">
        <button
          type="button"
          class="header-icon-btn notification-btn"
          :class="{ active: mostrarNotificaciones }"
          aria-label="Notificaciones"
          title="Notificaciones"
          :aria-expanded="mostrarNotificaciones"
          aria-controls="notifications-dropdown"
          @click="toggleNotificaciones"
        >
          <svg viewBox="0 0 24 24" class="notification-icon" aria-hidden="true">
            <path
              fill="currentColor"
              d="M12 22c1.1 0 2-.9 2-2h-4c0 1.1.89 2 2 2zm6-6v-5c0-3.07-1.64-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.63 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z"
            />
          </svg>
          <span v-if="noLeidas > 0" class="notification-badge" aria-live="polite">
            {{ noLeidas > 99 ? '99+' : noLeidas }}
          </span>
          <span v-if="noLeidas > 0" class="notification-ping" aria-hidden="true" />
        </button>

        <Transition name="notif-dropdown">
          <div
            v-if="mostrarNotificaciones"
            id="notifications-dropdown"
            class="notifications-dropdown"
            role="dialog"
            aria-label="Panel de notificaciones"
          >
            <div class="dropdown-header">
              <div>
                <h3>Notificaciones</h3>
                <p>
                  {{ noLeidas > 0 ? `${noLeidas} sin leer` : 'Todo al día' }}
                  <span class="live-label">
                    <span class="live-dot" :class="{ offline: realtimeStatus !== 'SUBSCRIBED' }" />
                    {{ realtimeStatus === 'SUBSCRIBED' ? 'Tiempo real' : 'Conectando' }}
                  </span>
                </p>
              </div>
              <div class="dropdown-header-actions">
                <button
                  v-if="noLeidas > 0"
                  type="button"
                  class="btn-clear"
                  :disabled="marcandoTodas"
                  @click="marcarTodas"
                >
                  {{ marcandoTodas ? 'Marcando…' : 'Marcar leídas' }}
                </button>
                <button
                  type="button"
                  class="btn-close-notif"
                  aria-label="Cerrar notificaciones"
                  @click="mostrarNotificaciones = false"
                >
                  ×
                </button>
              </div>
            </div>

            <div class="dropdown-body">
              <div v-if="loading" class="loading-notif">
                <span class="notif-spinner" aria-hidden="true" />
                Cargando notificaciones…
              </div>

              <p v-else-if="error" class="notif-error" role="alert">{{ error }}</p>

              <template v-else>
                <button
                  v-for="item in notificaciones"
                  :key="item.id_notificacion"
                  type="button"
                  class="notification-item"
                  :class="{ unread: !item.leida }"
                  @click="abrirNotificacion(item)"
                >
                  <span class="notif-icon" :class="`notif-icon--${tipoIcono(item.tipo)}`" aria-hidden="true">
                    <svg v-if="tipoIcono(item.tipo) === 'registro'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
                      <circle cx="9" cy="7" r="4" />
                      <path stroke-linecap="round" stroke-linejoin="round" d="M19 8v6m3-3h-6" />
                    </svg>
                    <svg v-else-if="tipoIcono(item.tipo) === 'aprobado'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M20 6 9 17l-5-5" />
                    </svg>
                    <svg v-else-if="tipoIcono(item.tipo) === 'rechazado'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M18 6 6 18M6 6l12 12" />
                    </svg>
                    <svg v-else-if="tipoIcono(item.tipo) === 'pedido'" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                      <path stroke-linecap="round" stroke-linejoin="round" d="m16 16 2 2 4-4" />
                      <path stroke-linecap="round" stroke-linejoin="round" d="M21 10V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l2-1.14" />
                      <path stroke-linecap="round" stroke-linejoin="round" d="m7.5 4.27 9 5.15M3.29 7 12 12l8.71-5M12 22V12" />
                    </svg>
                    <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9" />
                      <path stroke-linecap="round" stroke-linejoin="round" d="M10 21h4" />
                    </svg>
                  </span>

                  <span class="notif-content">
                    <span class="notif-title">{{ item.titulo || 'Notificación' }}</span>
                    <span class="notif-desc">{{ item.mensaje || 'Sin detalles adicionales.' }}</span>
                    <span class="notif-time">{{ formatearFecha(item.created_at) }}</span>
                  </span>

                  <span v-if="!item.leida" class="notif-unread-dot" aria-label="No leída" />
                </button>

                <div v-if="notificaciones.length === 0" class="empty-notif">
                  <span class="empty-notif__icon" aria-hidden="true">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.6">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9" />
                      <path stroke-linecap="round" stroke-linejoin="round" d="M10 21h4" />
                    </svg>
                  </span>
                  <strong>No tienes notificaciones</strong>
                  <span>Aquí aparecerán los avisos de registros, aprobaciones y solicitudes.</span>
                </div>
              </template>
            </div>

            <div class="dropdown-footer">
              <span>Actualizado automáticamente</span>
              <span class="footer-live">
                <span class="live-dot" :class="{ offline: realtimeStatus !== 'SUBSCRIBED' }" />
                Supabase Realtime
              </span>
            </div>
          </div>
        </Transition>
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
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Menu, LogOut, Flame } from '../icons.js'
import { useAuth } from '../../composables/useAuth.js'
import { useNotificaciones } from '../../composables/useNotificaciones.js'
import { menuByRole } from '../../data/menu.js'

defineEmits(['toggle-sidebar'])

const route = useRoute()
const router = useRouter()
const { currentUser, logout } = useAuth()

const {
  notificaciones,
  noLeidas,
  loading,
  error,
  realtimeStatus,
  iniciar,
  detener,
  cargarNotificaciones,
  marcarLeida,
  marcarTodasLeidas,
} = useNotificaciones()

const mostrarNotificaciones = ref(false)
const marcandoTodas = ref(false)
const notificationsRef = ref(null)

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

function toggleNotificaciones() {
  mostrarNotificaciones.value = !mostrarNotificaciones.value
  if (mostrarNotificaciones.value) cargarNotificaciones()
}

function handleOutsideClick(event) {
  if (!mostrarNotificaciones.value) return
  if (notificationsRef.value && !notificationsRef.value.contains(event.target)) {
    mostrarNotificaciones.value = false
  }
}

function handleKeydown(event) {
  if (event.key === 'Escape' && mostrarNotificaciones.value) {
    mostrarNotificaciones.value = false
  }
}

async function marcarTodas() {
  marcandoTodas.value = true
  await marcarTodasLeidas()
  marcandoTodas.value = false
}

async function abrirNotificacion(item) {
  await marcarLeida(item.id_notificacion)

  if (item.tipo === 'registro_familia' && currentUser.value?.rol === 'jefe') {
    mostrarNotificaciones.value = false
    router.push('/jefe/registros')
    return
  }

  if (
    ['registro_aprobado', 'registro_rechazado'].includes(item.tipo) &&
    currentUser.value?.rol === 'familia'
  ) {
    mostrarNotificaciones.value = false
    router.push('/familia/dashboard')
  }
}

function tipoIcono(tipo) {
  if (tipo === 'registro_familia' || tipo === 'registro') return 'registro'
  if (tipo === 'registro_aprobado' || tipo === 'aprobado') return 'aprobado'
  if (tipo === 'registro_rechazado' || tipo === 'rechazado') return 'rechazado'
  if (tipo === 'pedido' || tipo === 'solicitud') return 'pedido'
  return 'sistema'
}

function formatearFecha(fecha) {
  if (!fecha) return 'Ahora'
  const date = new Date(fecha)
  if (Number.isNaN(date.getTime())) return 'Ahora'

  const diff = Date.now() - date.getTime()
  if (diff < 60_000) return 'Ahora mismo'
  if (diff < 3_600_000) return `Hace ${Math.floor(diff / 60_000)} min`
  if (diff < 86_400_000) return `Hace ${Math.floor(diff / 3_600_000)} h`
  if (diff < 604_800_000) return `Hace ${Math.floor(diff / 86_400_000)} d`

  return date.toLocaleDateString('es-VE', { day: '2-digit', month: 'short' })
}

function handleLogout() {
  mostrarNotificaciones.value = false
  logout()
  router.push('/login')
}

watch(
  () => route.fullPath,
  () => {
    mostrarNotificaciones.value = false
  }
)

onMounted(() => {
  iniciar()
  document.addEventListener('click', handleOutsideClick)
  document.addEventListener('keydown', handleKeydown)
})

onBeforeUnmount(() => {
  detener()
  document.removeEventListener('click', handleOutsideClick)
  document.removeEventListener('keydown', handleKeydown)
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

.notification-ping {
  position: absolute;
  top: 6px;
  right: 6px;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--color-danger);
  opacity: 0.4;
  animation: notifPing 1.8s ease-out infinite;
  pointer-events: none;
}

@keyframes notifPing {
  0% { transform: scale(0.8); opacity: 0.45; }
  70% { transform: scale(2.4); opacity: 0; }
  100% { transform: scale(2.4); opacity: 0; }
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
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  flex-shrink: 0;
  padding: 13px 14px;
  background: linear-gradient(135deg, #f0f9ff, #ffffff);
  border-bottom: 1px solid var(--color-border-light);
}

.dropdown-header h3 {
  margin: 0;
  color: var(--color-heading);
  font-size: 0.92rem;
  font-weight: 700;
}

.dropdown-header p {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 7px;
  margin: 3px 0 0;
  color: var(--color-muted);
  font-size: 0.72rem;
}

.live-label,
.footer-live {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  color: #0284c7;
  font-size: 0.66rem;
  font-weight: 600;
}

.live-dot {
  display: inline-block;
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: #10b981;
  box-shadow: 0 0 0 3px rgba(16, 185, 129, 0.14);
}

.live-dot.offline {
  background: #f59e0b;
  box-shadow: 0 0 0 3px rgba(245, 158, 11, 0.14);
}

.dropdown-header-actions {
  display: flex;
  align-items: center;
  gap: 5px;
  flex-shrink: 0;
}

.btn-clear {
  min-height: 34px;
  padding: 0 9px;
  border: 1px solid var(--color-border);
  border-radius: 9px;
  background: #ffffff;
  color: var(--color-primary-darker);
  font-size: 0.7rem;
  font-weight: 700;
  cursor: pointer;
}

.btn-clear:hover:not(:disabled) {
  background: var(--color-primary-soft);
}

.btn-clear:disabled {
  opacity: 0.6;
  cursor: wait;
}

.btn-close-notif {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  padding: 0;
  border: 0;
  border-radius: 9px;
  background: transparent;
  color: var(--color-muted);
  font-size: 1.2rem;
  line-height: 1;
  cursor: pointer;
}

.btn-close-notif:hover {
  background: var(--color-bg);
  color: var(--color-heading);
}

.dropdown-body {
  overflow-y: auto;
  overscroll-behavior: contain;
}

.loading-notif,
.empty-notif {
  display: grid;
  justify-items: center;
  gap: 8px;
  padding: 30px 18px;
  color: var(--color-muted);
  font-size: 0.82rem;
  text-align: center;
}

.notif-spinner {
  width: 24px;
  height: 24px;
  border: 2px solid #e2e8f0;
  border-top-color: var(--color-primary);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.notif-error {
  margin: 12px;
  padding: 10px 12px;
  border: 1px solid #fecaca;
  border-radius: 10px;
  background: #fef2f2;
  color: #b91c1c;
  font-size: 0.8rem;
  line-height: 1.45;
}

.notification-item {
  position: relative;
  display: flex;
  align-items: flex-start;
  gap: 11px;
  width: 100%;
  padding: 12px 14px;
  border: 0;
  border-bottom: 1px solid var(--color-border-light);
  background: #ffffff;
  color: inherit;
  font: inherit;
  text-align: left;
  cursor: pointer;
  transition: background-color var(--transition-fast);
}

.notification-item:last-child {
  border-bottom: 0;
}

.notification-item:hover {
  background: #f8fafc;
}

.notification-item.unread {
  background: linear-gradient(90deg, #f0f9ff, #ffffff);
}

.notif-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 36px;
  height: 36px;
  border-radius: 11px;
  background: #e0f2fe;
  color: #0369a1;
}

.notif-icon svg {
  width: 18px;
  height: 18px;
}

.notif-icon--registro {
  background: #eff6ff;
  color: #2563eb;
}

.notif-icon--aprobado {
  background: #ecfdf5;
  color: #059669;
}

.notif-icon--rechazado {
  background: #fef2f2;
  color: #dc2626;
}

.notif-icon--pedido {
  background: #fffbeb;
  color: #d97706;
}

.notif-content {
  display: grid;
  gap: 2px;
  min-width: 0;
  padding-right: 12px;
}

.notif-title {
  color: var(--color-heading);
  font-size: 0.82rem;
  font-weight: 700;
  line-height: 1.35;
}

.notif-desc {
  color: var(--color-muted);
  font-size: 0.76rem;
  line-height: 1.45;
  overflow-wrap: anywhere;
}

.notif-time {
  margin-top: 2px;
  color: var(--color-muted-light);
  font-size: 0.66rem;
}

.notif-unread-dot {
  position: absolute;
  top: 17px;
  right: 12px;
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--color-primary);
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.14);
}

.empty-notif {
  padding: 34px 22px;
}

.empty-notif__icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
  border-radius: 15px;
  background: var(--color-primary-soft);
  color: var(--color-primary-darker);
}

.empty-notif__icon svg {
  width: 23px;
  height: 23px;
}

.empty-notif strong {
  color: var(--color-heading);
  font-size: 0.85rem;
}

.empty-notif span:last-child {
  max-width: 260px;
  font-size: 0.75rem;
  line-height: 1.45;
}

.dropdown-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  flex-shrink: 0;
  padding: 9px 14px;
  border-top: 1px solid var(--color-border-light);
  background: #f9fafb;
  color: var(--color-muted-light);
  font-size: 0.66rem;
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

.notif-dropdown-enter-active,
.notif-dropdown-leave-active {
  transition: opacity 0.16s ease, transform 0.16s ease;
}

.notif-dropdown-enter-from,
.notif-dropdown-leave-to {
  opacity: 0;
  transform: translateY(-6px);
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
    width: 390px;
    max-height: min(540px, calc(100dvh - 96px));
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

@media (prefers-reduced-motion: reduce) {
  .notification-ping,
  .notif-spinner {
    animation: none;
  }

  .notif-dropdown-enter-active,
  .notif-dropdown-leave-active {
    transition: none;
  }
}
</style>
