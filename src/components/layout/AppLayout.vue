<template>
  <div class="min-h-screen bg-gray-50">
    <div
      v-if="sidebarOpen"
      class="fixed inset-0 z-30 bg-gray-700/30 lg:hidden"
      @click="sidebarOpen = false"
    />
    <AppSidebar :open="sidebarOpen" @navigate="sidebarOpen = false" />
    <div class="lg:pl-64">
      <AppHeader @toggle-sidebar="sidebarOpen = !sidebarOpen" />
      <main class="animate-fadeIn p-4 lg:p-8">
        <RouterView />
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import AppSidebar from './AppSidebar.vue'
import AppHeader from './AppHeader.vue'

const sidebarOpen = ref(false)
</script>

<style>
/* Quitar subrayados de los enlaces del menú */
nav a,
nav router-link,
.sidebar a,
.sidebar router-link {
  text-decoration: none !important;
}

nav a:hover,
nav router-link:hover {
  text-decoration: none !important;
}
</style>
