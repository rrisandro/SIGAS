<template>
  <aside
    id="app-sidebar"
    class="app-sidebar"
    :class="{ 'is-open': open }"
  >
    <div class="sidebar-brand">
      <div class="sidebar-brand__icon">
        <Flame :size="20" />
      </div>
      <div class="sidebar-brand__text">
        <p class="sidebar-brand__name">SIGAS</p>
        <p class="sidebar-brand__sub">Gas Doméstico</p>
      </div>
      <button
        type="button"
        class="sidebar-close"
        aria-label="Cerrar menú"
        @click="$emit('navigate')"
      >
        <span aria-hidden="true">×</span>
      </button>
    </div>

    <nav class="sidebar-nav" aria-label="Menú principal">
      <RouterLink
        v-for="item in menu"
        :key="item.path"
        :to="`/${role}/${item.path}`"
        class="nav-link"
        active-class="!bg-white !text-sky-500 shadow-sm"
        @click="$emit('navigate')"
      >
        <component :is="icons[item.icon]" :size="19" />
        <span>{{ item.label }}</span>
      </RouterLink>
    </nav>

    <div class="sidebar-footer">
      <div class="sidebar-user">
        <span class="sidebar-avatar" aria-hidden="true">{{ userInitial }}</span>
        <div class="sidebar-user__info">
          <p class="sidebar-user__label">Sesión como</p>
          <p class="sidebar-user__name">{{ currentUser?.nombre }}</p>
          <p class="sidebar-user__role">{{ currentUser?.rol }}</p>
        </div>
      </div>

      <button type="button" class="sidebar-logout" @click="handleLogout">
        <LogOut :size="18" />
        <span>Cerrar sesión</span>
      </button>
    </div>
  </aside>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import {
  Flame,
  LayoutDashboard,
  MapPin,
  UserCheck,
  Users,
  Shield,
  Truck,
  FileText,
  Inbox,
  ClipboardList,
  PackageCheck,
  History,
  LogOut,
} from '../icons.js'
import { useAuth } from '../../composables/useAuth.js'
import { menuByRole } from '../../data/menu.js'

defineProps({
  open: { type: Boolean, default: false },
})

const emit = defineEmits(['navigate'])

const router = useRouter()
const { currentUser, logout } = useAuth()

const role = computed(() => currentUser.value?.rol || 'familia')
const menu = computed(() => menuByRole[role.value] || [])

const userInitial = computed(() => {
  const name = currentUser.value?.nombre?.trim()
  return name ? name.charAt(0).toUpperCase() : 'U'
})

const icons = {
  LayoutDashboard,
  MapPin,
  UserCheck,
  Users,
  Shield,
  Truck,
  FileText,
  Inbox,
  ClipboardList,
  PackageCheck,
  Flame,
  History,
}

function handleLogout() {
  emit('navigate')
  logout()
  router.push('/login')
}
</script>

<style scoped>
.app-sidebar {
  position: fixed;
  top: 0;
  bottom: 0;
  left: 0;
  z-index: 100;
  display: flex;
  flex-direction: column;
  width: min(86vw, 300px);
  padding-top: var(--safe-top);
  padding-bottom: var(--safe-bottom);
  background: #f0f9ff;
  border-right: 1px solid #e0f2fe;
  box-shadow: 8px 0 24px rgba(15, 23, 42, 0.12);
  transform: translateX(-100%);
  transition: transform 0.22s cubic-bezier(0.22, 1, 0.36, 1);
  will-change: transform;
  overscroll-behavior: contain;
}

.app-sidebar.is-open {
  transform: translateX(0);
}

.sidebar-brand {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-shrink: 0;
  min-height: 64px;
  padding: 10px 12px 10px 16px;
  border-bottom: 1px solid #e0f2fe;
}

.sidebar-brand__icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  border-radius: 11px;
  background: var(--color-primary);
  color: #ffffff;
  box-shadow: 0 2px 8px rgba(14, 165, 233, 0.35);
}

.sidebar-brand__text {
  min-width: 0;
}

.sidebar-brand__name {
  color: var(--color-heading);
  font-size: 0.95rem;
  font-weight: 700;
  letter-spacing: 0.02em;
}

.sidebar-brand__sub {
  color: var(--color-muted);
  font-size: 0.7rem;
}

.sidebar-close {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 44px;
  height: 44px;
  margin-left: auto;
  padding: 0;
  border: 0;
  border-radius: 12px;
  background: transparent;
  color: var(--color-muted);
  font-size: 1.6rem;
  line-height: 1;
  cursor: pointer;
  transition: background-color var(--transition-fast), color var(--transition-fast);
}

.sidebar-close:hover {
  background: #ffffff;
  color: var(--color-heading);
}

.sidebar-nav {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding: 12px;
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
}

.nav-link {
  display: flex;
  align-items: center;
  gap: 12px;
  min-height: 48px;
  padding: 10px 12px;
  border-radius: 12px;
  color: var(--color-muted);
  font-size: 0.9rem;
  font-weight: 500;
  line-height: 1.3;
  transition: background-color var(--transition-fast), color var(--transition-fast),
    box-shadow var(--transition-fast);
}

.nav-link:hover {
  background: #ffffff;
  color: var(--color-heading);
}

.nav-link.router-link-active {
  background: #ffffff;
  color: var(--color-primary);
  box-shadow: var(--shadow-sm);
}

.nav-link svg {
  flex-shrink: 0;
}

.sidebar-footer {
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 12px 12px calc(12px + var(--safe-bottom));
  border-top: 1px solid #e0f2fe;
}

.sidebar-user {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
  padding: 4px;
}

.sidebar-avatar {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 38px;
  height: 38px;
  border-radius: 50%;
  background: #ffffff;
  color: var(--color-primary-darker);
  font-size: 0.85rem;
  font-weight: 700;
  box-shadow: var(--shadow-sm);
}

.sidebar-user__info {
  min-width: 0;
}

.sidebar-user__label {
  color: var(--color-muted-light);
  font-size: 0.65rem;
  text-transform: uppercase;
  letter-spacing: 0.03em;
}

.sidebar-user__name {
  overflow: hidden;
  color: var(--color-heading);
  font-size: 0.82rem;
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.sidebar-user__role {
  color: var(--color-muted);
  font-size: 0.68rem;
  text-transform: capitalize;
}

.sidebar-logout {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  min-height: 44px;
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #bae6fd;
  border-radius: 11px;
  background: #ffffff;
  color: #0369a1;
  font-size: 0.82rem;
  font-weight: 600;
  cursor: pointer;
  transition: background-color var(--transition-fast), color var(--transition-fast);
}

.sidebar-logout:hover {
  background: var(--color-primary);
  border-color: var(--color-primary);
  color: #ffffff;
}

@media (min-width: 640px) {
  .app-sidebar {
    width: 280px;
  }

  .sidebar-brand {
    min-height: 70px;
    padding-left: 18px;
  }
}

@media (min-width: 1024px) {
  .app-sidebar {
    width: var(--sidebar-width);
    transform: translateX(0);
    z-index: 40;
    box-shadow: none;
  }

  .sidebar-close {
    display: none;
  }

  .sidebar-brand {
    min-height: 76px;
  }
}
</style>
