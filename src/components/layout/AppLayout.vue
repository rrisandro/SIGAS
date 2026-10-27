<template>
  <div class="app-shell">
    <div
      v-if="sidebarOpen"
      class="sidebar-overlay"
      aria-hidden="true"
      @click="closeSidebar"
    />

    <AppSidebar :open="sidebarOpen" @navigate="closeSidebar" />

    <div class="app-main">
      <AppHeader @toggle-sidebar="toggleSidebar" />

      <main class="app-content">
        <RouterView />
      </main>
    </div>
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import AppSidebar from './AppSidebar.vue'
import AppHeader from './AppHeader.vue'

const route = useRoute()
const sidebarOpen = ref(false)

function toggleSidebar() {
  sidebarOpen.value = !sidebarOpen.value
}

function closeSidebar() {
  sidebarOpen.value = false
}

function handleKeydown(event) {
  if (event.key === 'Escape' && sidebarOpen.value) {
    closeSidebar()
  }
}

function handleResize() {
  if (window.innerWidth >= 1024) {
    closeSidebar()
  }
}

watch(sidebarOpen, (open) => {
  document.body.classList.toggle('nav-open', open && window.innerWidth < 1024)
})

watch(() => route.fullPath, () => {
  closeSidebar()
})

onMounted(() => {
  document.addEventListener('keydown', handleKeydown)
  window.addEventListener('resize', handleResize)
})

onBeforeUnmount(() => {
  document.removeEventListener('keydown', handleKeydown)
  window.removeEventListener('resize', handleResize)
  document.body.classList.remove('nav-open')
})
</script>

<style scoped>
.app-shell {
  min-height: 100vh;
  min-height: 100dvh;
  background: var(--color-bg);
}

.app-main {
  display: flex;
  flex-direction: column;
  min-width: 0;
  min-height: 100vh;
  min-height: 100dvh;
}

.app-content {
  flex: 1;
  width: 100%;
  max-width: 1440px;
  margin-inline: auto;
  padding: calc(var(--header-height) + 10px) var(--content-padding)
    calc(24px + var(--safe-bottom));
  animation: fadeIn 0.2s ease-out;
}

.sidebar-overlay {
  position: fixed;
  inset: 0;
  z-index: 90;
  background: rgba(15, 23, 42, 0.48);
  backdrop-filter: blur(2px);
  -webkit-backdrop-filter: blur(2px);
  animation: fadeIn 0.18s ease-out;
}

@media (min-width: 640px) {
  .app-content {
    padding-top: calc(var(--header-height) + 12px);
    padding-bottom: calc(32px + var(--safe-bottom));
  }
}

@media (min-width: 1024px) {
  .app-main {
    margin-left: var(--sidebar-width);
  }

  .app-content {
    padding: calc(64px + 24px) 28px calc(40px + var(--safe-bottom));
  }

  .sidebar-overlay {
    display: none;
  }
}

@media (min-width: 1280px) {
  .app-content {
    padding: calc(64px + 28px) 32px calc(44px + var(--safe-bottom));
  }
}
</style>

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
