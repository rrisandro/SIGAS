<template>
  <aside
    class="fixed inset-y-0 left-0 z-40 flex w-72 flex-col justify-between border-r border-sky-100 bg-sky-50 transition-all duration-300 lg:translate-x-0 shadow-sm"
    :class="open ? 'translate-x-0' : '-translate-x-full'"
  >
    <!-- CABECERA DE LOGO -->
    <div class="flex h-20 items-center gap-4 border-b border-sky-100 px-6 shrink-0">
      <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-sky-500 text-white shadow-sm">
        <Flame :size="22" />
      </div>
      <div>
        <p class="text-base font-bold text-gray-800 tracking-tight">SIGAS</p>
        <p class="text-xs font-medium text-gray-500">Gas Doméstico</p>
      </div>
    </div>

    <!-- NAVEGACIÓN CON ESPACIADO INDEPENDIENTE (SEPARADOS) -->
    <nav class="flex-1 space-y-3 overflow-y-auto p-4">
      <RouterLink
        v-for="item in menu"
        :key="item.path"
        :to="`/${role}/${item.path}`"
        class="group flex items-center gap-4 rounded-xl px-4 py-3.5 text-sm font-semibold text-gray-600 transition-all duration-200 hover:translate-x-2 hover:bg-white hover:text-sky-600 hover:shadow-sm"
        active-class="!bg-white !text-sky-500 !translate-x-0 shadow-sm font-bold"
        @click="$emit('navigate')"
      >
        <component 
          :is="icons[item.icon]" 
          :size="20" 
          class="shrink-0 transition-transform duration-200 group-hover:scale-110"
        />
        <span class="tracking-wide">{{ item.label }}</span>
      </RouterLink>
    </nav>

    <!-- FOOTER DE SESIÓN DE USUARIO -->
    <div class="border-t border-sky-100 p-4 shrink-0">
      <div class="rounded-2xl border border-sky-100 bg-white/80 p-4 shadow-sm">
        <p class="text-[11px] font-semibold text-gray-400 uppercase tracking-wider">Sesión como</p>
        <p class="mt-1 truncate text-sm font-bold text-gray-700">{{ currentUser?.nombre || 'Usuario' }}</p>
      </div>
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