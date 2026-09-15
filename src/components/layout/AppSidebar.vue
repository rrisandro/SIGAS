<template>
  <aside
    class="fixed inset-y-0 left-0 z-40 flex w-64 flex-col border-r border-sky-100 bg-sky-50 transition-transform duration-200 lg:translate-x-0"
    :class="open ? 'translate-x-0' : '-translate-x-full'"
  >
    <div class="flex h-16 items-center gap-3 border-b border-sky-100 px-5">
      <div class="flex h-9 w-9 items-center justify-center rounded-xl bg-sky-500 text-white">
        <Flame :size="18" />
      </div>
      <div>
        <p class="text-sm font-medium text-gray-700">SIGAS</p>
        <p class="text-xs text-gray-500">Gas Doméstico</p>
      </div>
    </div>

    <nav class="flex-1 space-y-1 overflow-y-auto p-3">
      <RouterLink
        v-for="item in menu"
        :key="item.path"
        :to="`/${role}/${item.path}`"
        class="flex items-center gap-3 rounded-xl px-3 py-2.5 text-sm font-medium text-gray-500 transition hover:bg-white hover:text-gray-700"
        active-class="!bg-white !text-sky-500 shadow-sm"
        @click="$emit('navigate')"
      >
        <component :is="icons[item.icon]" :size="18" />
        <span>{{ item.label }}</span>
      </RouterLink>
    </nav>

    <div class="border-t border-sky-100 p-4">
      <p class="text-xs text-gray-500">Sesión como</p>
      <p class="truncate text-sm font-medium text-gray-700">{{ currentUser?.nombre }}</p>
    </div>
  </aside>
</template>

<script setup>
import { computed } from 'vue'
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
} from '../icons.js'
import { useAuth } from '../../composables/useAuth.js'
import { menuByRole } from '../../data/menu.js'

defineProps({
  open: { type: Boolean, default: false },
})

defineEmits(['navigate'])

const { currentUser } = useAuth()

const role = computed(() => currentUser.value?.rol || 'familia')
const menu = computed(() => menuByRole[role.value] || [])

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
</script>
