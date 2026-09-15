import { createRouter, createWebHistory } from 'vue-router'
import { useAuth, loadSession } from '../composables/useAuth.js'
import { defaultRoutes } from '../data/menu.js'
import AppLayout from '../components/layout/AppLayout.vue'

loadSession()

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/login',
      name: 'login',
      component: () => import('../views/LoginView.vue'),
      meta: { guest: true },
    },
    {
      path: '/',
      component: AppLayout,
      meta: { requiresAuth: true },
      children: [
        { path: 'admin', redirect: '/admin/dashboard' },
        {
          path: 'admin/dashboard',
          component: () => import('../views/admin/DashboardView.vue'),
          meta: { role: 'admin' },
        },
        {
          path: 'admin/calles',
          component: () => import('../views/admin/CallesView.vue'),
          meta: { role: 'admin' },
        },
        {
          path: 'admin/jefes',
          component: () => import('../views/admin/JefesView.vue'),
          meta: { role: 'admin' },
        },
        {
          path: 'admin/familias',
          component: () => import('../views/admin/FamiliasView.vue'),
          meta: { role: 'admin' },
        },
        {
          path: 'admin/usuarios',
          component: () => import('../views/admin/UsuariosView.vue'),
          meta: { role: 'admin' },
        },
        {
          path: 'admin/logistica',
          component: () => import('../views/admin/LogisticaView.vue'),
          meta: { role: 'admin' },
        },
        {
          path: 'admin/auditoria',
          component: () => import('../views/admin/AuditoriaView.vue'),
          meta: { role: 'admin' },
        },

        { path: 'jefe', redirect: '/jefe/dashboard' },
        {
          path: 'jefe/dashboard',
          component: () => import('../views/jefe/DashboardView.vue'),
          meta: { role: 'jefe' },
        },
        {
          path: 'jefe/bandeja',
          component: () => import('../views/jefe/BandejaView.vue'),
          meta: { role: 'jefe' },
        },
        {
          path: 'jefe/registro',
          component: () => import('../views/jefe/RegistroView.vue'),
          meta: { role: 'jefe' },
        },
        {
          path: 'jefe/entregas',
          component: () => import('../views/jefe/EntregasView.vue'),
          meta: { role: 'jefe' },
        },

        { path: 'familia', redirect: '/familia/dashboard' },
        {
          path: 'familia/dashboard',
          component: () => import('../views/familia/DashboardView.vue'),
          meta: { role: 'familia' },
        },
        {
          path: 'familia/solicitud',
          component: () => import('../views/familia/SolicitudView.vue'),
          meta: { role: 'familia' },
        },
        {
          path: 'familia/historial',
          component: () => import('../views/familia/HistorialView.vue'),
          meta: { role: 'familia' },
        },
      ],
    },
    {
      path: '/:pathMatch(.*)*',
      redirect: '/',
    },
  ],
})

router.beforeEach((to) => {
  const { isAuthenticated, currentUser } = useAuth()

  if (to.path === '/' || to.path === '') {
    if (!isAuthenticated()) return '/login'
    return defaultRoutes[currentUser.value.rol] || '/login'
  }

  if (to.meta.guest) {
    if (isAuthenticated()) {
      return defaultRoutes[currentUser.value.rol] || '/'
    }
    return true
  }

  if (to.matched.some((r) => r.meta.requiresAuth) && !isAuthenticated()) {
    return '/login'
  }

  const neededRole = to.meta.role
  if (neededRole && currentUser.value?.rol !== neededRole) {
    return defaultRoutes[currentUser.value?.rol] || '/login'
  }

  return true
})

export default router
