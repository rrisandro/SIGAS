<template>
  <header class="top-navbar">
    <!-- NAVEGACIÓN Y TÍTULO DE LA SECCIÓN ACTIVA -->
    <div class="header-left">
      <div class="breadcrumb">
        <span class="system-tag">SIGAS System</span>
        <span class="divider">/</span>
        <span class="current-page">{{ tituloVista }}</span>
      </div>
      <h1 class="page-title">{{ tituloVista }}</h1>
    </div>

    <!-- ÁREA DE USUARIO Y ACCIONES -->
    <div class="header-right">
      <!-- CAMPANA DE NOTIFICACIONES CON AUDITORÍA REAL DE SUPABASE -->
      <div class="notifications-wrapper">
        <button 
          class="icon-btn" 
          :class="{ active: mostrarNotificaciones }"
          title="Historial de Auditoría y Cambios"
          @click="toggleNotificaciones"
        >
          <svg viewBox="0 0 24 24" class="icon">
            <path fill="currentColor" d="M12 22c1.1 0 2-.9 2-2h-4c0 1.1.89 2 2 2zm6-6v-5c0-3.07-1.64-5.64-4.5-6.32V4c0-.83-.67-1.5-1.5-1.5s-1.5.67-1.5 1.5v.68C7.63 5.36 6 7.92 6 11v5l-2 2v1h16v-1l-2-2z"/>
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
            <button class="btn-clear" @click="cargarAuditoriaReal">
              🔄 Actualizar
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
                  <svg viewBox="0 0 24 24"><path fill="currentColor" d="M14 2H6c-1.1 0-1.99.9-1.99 2L4 20c0 1.1.89 2 1.99 2H18c1.1 0 2-.9 2-2V8l-6-6zm2 16H8v-2h8v2zm0-4H8v-2h8v-2zm-3-5V3.5L18.5 9H13z"/></svg>
                </div>
                <div class="notif-content">
                  <p class="notif-title">{{ item.accion || 'Acción Registrada' }}</p>
                  <p class="notif-desc">{{ item.descripcion || 'Sin detalles adicionales' }}</p>
                  <span class="notif-time">
                    👤 <strong>{{ item.usuario || item.autor || 'Administrador' }}</strong> — 
                    🕒 {{ item.fecha ? new Date(item.fecha).toLocaleString('es-VE') : 'Reciente' }}
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

      <div class="header-divider"></div>

      <!-- PERFIL DEL ADMINISTRADOR -->
      <div class="user-profile">
        <div class="avatar-container">
          <div class="avatar-circle">
            {{ currentUser?.nombre ? currentUser.nombre.charAt(0).toUpperCase() : 'J' }}
          </div>
          <span class="online-indicator"></span>
        </div>
        <div class="user-details">
          <p class="user-name">{{ currentUser?.nombre || 'Jhonjairo Carusi' }}</p>
          <span class="role-badge">{{ currentUser?.rol || 'Administrador' }}</span>
        </div>
      </div>

      <!-- BOTÓN DE SALIR CORREGIDO -->
      <button class="logout-btn" @click="cerrarSesion">
        <svg viewBox="0 0 24 24" class="logout-icon"><path fill="currentColor" d="M17 7l-1.41 1.41L18.17 11H8v2h10.17l-2.58 2.58L17 17l5-5zM4 5h8V3H4c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h8v-2H4V5z"/></svg>
        <span>Salir</span>
      </button>
    </div>
  </header>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuth } from '../../composables/useAuth.js'
import { supabase } from '../../composables/supabase.js'

const route = useRoute()
const router = useRouter()
const { currentUser, logout } = useAuth()

const mostrarNotificaciones = ref(false)
const loading = ref(false)
const listaAuditoria = ref([])

const notificacionesNoLeidas = computed(() => {
  return listaAuditoria.value.filter(item => !item.leida).length
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
      // Mapeamos los datos para asegurar que tengan la propiedad 'leida' (por defecto no leída)
      listaAuditoria.value = data.map(item => ({
        ...item,
        leida: false
      }))
    }
  } catch (e) {
    console.error('Error cargando auditoría:', e)
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  cargarAuditoriaReal()
})

const tituloVista = computed(() => {
  const path = route.path
  if (path.includes('calles')) return 'Gestión de Calles'
  if (path.includes('jefes')) return 'Jefes de Calle'
  if (path.includes('familias')) return 'Directorio de Familias'
  if (path.includes('usuarios')) return 'Usuarios del Sistema'
  if (path.includes('logistica')) return 'Logística y Despacho'
  if (path.includes('auditoria')) return 'Histórico de Auditoría'
  return 'Panel de Control General'
})

async function cerrarSesion() {
  try {
    if (typeof logout === 'function') {
      await logout()
    }
  } catch (e) {
    console.error('Error en logout:', e)
  } finally {
    localStorage.removeItem('user')
    localStorage.removeItem('supabase.auth.token')
    router.push('/login')
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap');

.top-navbar {
  font-family: 'Plus Jakarta Sans', sans-serif;
  height: 80px;
  background-color: #ffffff;
  border-bottom: 1px solid #e2e8f0;
  padding: 0 2.2rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.02);
  position: sticky;
  top: 0;
  z-index: 30;
}

.header-left { display: flex; flex-direction: column; gap: 2px; }
.breadcrumb { display: flex; align-items: center; gap: 6px; font-size: 0.75rem; color: #94a3b8; font-weight: 500; }
.system-tag { color: #0072CE; font-weight: 600; }
.current-page { color: #64748b; }
.page-title { margin: 0; font-size: 1.2rem; font-weight: 700; color: #0f172a; }

.header-right { display: flex; align-items: center; gap: 1.2rem; }

.notifications-wrapper { position: relative; }
.icon-btn {
  position: relative;
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  width: 44px;
  height: 44px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #64748b;
  cursor: pointer;
  transition: all 0.2s ease;
}
.icon-btn:hover, .icon-btn.active { background: #eff6ff; color: #0072CE; border-color: #bfdbfe; }
.icon-btn .icon { width: 20px; height: 20px; }

.notification-badge {
  position: absolute;
  top: -4px;
  right: -4px;
  background-color: #0072CE;
  color: #ffffff;
  font-size: 0.7rem;
  font-weight: 700;
  min-width: 18px;
  height: 18px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 0 4px;
  border: 2px solid #ffffff;
}

.notifications-dropdown {
  position: absolute;
  right: 0;
  top: 54px;
  width: 350px;
  background: #ffffff;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1);
  overflow: hidden;
  z-index: 100;
}

.dropdown-header {
  padding: 1rem 1.2rem;
  border-bottom: 1px solid #f1f5f9;
  display: flex;
  justify-content: space-between;
  align-items: center;
  background: #f8fafc;
}

.dropdown-header h3 { margin: 0; font-size: 0.95rem; font-weight: 700; color: #0f172a; }
.dropdown-header p { margin: 0.1rem 0 0 0; font-size: 0.75rem; color: #64748b; }
.btn-clear { background: none; border: none; color: #0072CE; font-size: 0.8rem; font-weight: 600; cursor: pointer; }

.dropdown-body { max-height: 320px; overflow-y: auto; }
.loading-notif { padding: 1.5rem; text-align: center; font-size: 0.8rem; color: #64748b; }

.notification-item {
  display: flex;
  gap: 12px;
  padding: 0.9rem 1.2rem;
  border-bottom: 1px solid #f1f5f9;
  cursor: pointer;
  transition: background 0.15s ease;
}
.notification-item:hover { background: #f8fafc; }
.notification-item.unread { background: #f0f7ff; }

.notif-icon {
  width: 32px;
  height: 32px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  background: #eff6ff;
  color: #0072CE;
}
.notif-icon svg { width: 16px; height: 16px; }

.notif-content { flex-grow: 1; }
.notif-title { margin: 0; font-size: 0.85rem; font-weight: 700; color: #0f172a; }
.notif-desc { margin: 0.2rem 0 0 0; font-size: 0.78rem; color: #64748b; }
.notif-time { display: block; margin-top: 0.4rem; font-size: 0.7rem; color: #64748b; }

.empty-notif { padding: 2rem; text-align: center; color: #94a3b8; font-size: 0.85rem; }

.header-divider { width: 1px; height: 32px; background-color: #e2e8f0; }

.user-profile { display: flex; align-items: center; gap: 12px; }
.avatar-container { position: relative; }
.avatar-circle {
  width: 44px;
  height: 44px;
  background: linear-gradient(135deg, #0072CE 0%, #227cc5 100%);
  color: #ffffff;
  font-weight: 700;
  font-size: 1.05rem;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 3px 10px rgba(0, 114, 206, 0.25);
}
.online-indicator {
  position: absolute;
  bottom: -1px;
  right: -1px;
  width: 11px;
  height: 11px;
  background-color: #10b981;
  border: 2px solid #ffffff;
  border-radius: 50%;
}

.user-details { display: flex; flex-direction: column; }
.user-name { margin: 0; font-size: 0.92rem; font-weight: 700; color: #0f172a; }
.role-badge { font-size: 0.72rem; font-weight: 600; color: #0072CE; }

.logout-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  background: #fef2f2;
  color: #dc2626;
  border: 1px solid #fecaca;
  padding: 0.65rem 1.2rem;
  border-radius: 12px;
  font-weight: 600;
  font-size: 0.88rem;
  cursor: pointer;
  transition: all 0.2s ease;
}
.logout-btn:hover {
  background: #dc2626;
  color: #ffffff;
  border-color: #dc2626;
  transform: translateY(-1px);
  box-shadow: 0 4px 12px rgba(220, 38, 38, 0.25);
}
.logout-icon { width: 18px; height: 18px; }
</style>