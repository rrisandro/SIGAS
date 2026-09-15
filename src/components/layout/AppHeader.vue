<template>
  <header class="sticky top-0 z-30 flex h-16 items-center justify-between border-b border-gray-100 bg-white px-4 shadow-sm lg:px-8">
    <div class="flex items-center gap-3">
      <button
        type="button"
        class="rounded-xl p-2 text-gray-500 hover:bg-gray-50 lg:hidden"
        @click="$emit('toggle-sidebar')"
      >
        <Menu :size="20" />
      </button>
      <div>
        <h1 class="text-base font-medium text-gray-700">{{ title }}</h1>
        <p class="hidden text-xs text-gray-500 sm:block">{{ subtitle }}</p>
      </div>
    </div>

    <div class="flex items-center gap-3">
      <div class="hidden text-right sm:block">
        <p class="text-sm font-medium text-gray-700">{{ currentUser?.nombre }}</p>
        <p class="text-xs capitalize text-gray-500">{{ currentUser?.rol }}</p>
      </div>
      <BaseButton variant="outline" size="sm" @click="handleLogout">
        <LogOut :size="16" />
        Salir
      </BaseButton>
    </div>
  </header>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Menu, LogOut } from '../icons.js'
import BaseButton from '../ui/BaseButton.vue'
import { useAuth } from '../../composables/useAuth.js'
import { menuByRole } from '../../data/menu.js'

defineEmits(['toggle-sidebar'])

const route = useRoute()
const router = useRouter()
const { currentUser, logout } = useAuth()

const title = computed(() => {
  const rol = currentUser.value?.rol
  const segment = route.path.split('/').pop()
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

function handleLogout() {
  logout()
  router.push('/login')
}
</script>
