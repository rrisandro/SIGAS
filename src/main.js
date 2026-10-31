import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import { loadSession } from './composables/useAuth.js'
import { restrict } from './directives/restrict.js'
import './style.css'

loadSession()

const app = createApp(App)
app.use(router)
app.directive('restrict', restrict)
app.mount('#app')
