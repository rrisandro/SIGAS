import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import { loadSession } from './composables/useAuth.js'
import './style.css'

loadSession()

const app = createApp(App)
app.use(router)
app.mount('#app')
