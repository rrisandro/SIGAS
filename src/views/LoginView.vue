<template>
  <div class="login-page" :style="{ backgroundImage: `url(${bgImage})` }">
    <div class="card">
      <form class="form" @submit.prevent="handleLogin">
        <div class="logo-container">
          <img :src="logoImage" alt="SIGAS Logo" class="brand-logo" />
        </div>

        <h2 id="heading">Iniciar Sesión</h2>

        <div class="field">
          <svg viewBox="0 0 16 16" fill="currentColor" class="input-icon" xmlns="http://www.w3.org/2000/svg">
            <path d="M13.106 7.222c0-2.967-2.249-5.032-5.482-5.032-3.35 0-5.646 2.318-5.646 5.702 0 3.493 2.235 5.708 5.762 5.708.862 0 1.689-.123 2.304-.335v-.862c-.43.199-1.354.328-2.29.328-2.926 0-4.813-1.88-4.813-4.798 0-2.844 1.921-4.881 4.594-4.881 2.735 0 4.608 1.688 4.608 4.156 0 1.682-.554 2.769-1.416 2.769-.492 0-.772-.28-.772-.76V5.206H8.923v.834h-.11c-.266-.595-.881-.964-1.6-.964-1.4 0-2.378 1.162-2.378 2.823 0 1.737.957 2.906 2.379 2.906.8 0 1.415-.39 1.709-1.087h.11c.081.67.703 1.148 1.503 1.148 1.572 0 2.57-1.415 2.57-3.643zm-7.177.704c0-1.197.54-1.907 1.456-1.907.93 0 1.524.738 1.524 1.907S8.308 9.84 7.371 9.84c-.895 0-1.442-.725-1.442-1.914z" />
          </svg>
          <input
            v-model="username"
            type="text"
            class="input-field"
            placeholder="Usuario"
            autocomplete="off"
            required
          />
        </div>

        <div class="field">
          <svg viewBox="0 0 16 16" fill="currentColor" class="input-icon" xmlns="http://www.w3.org/2000/svg">
            <path d="M8 1a2 2 0 0 1 2 2v4H6V3a2 2 0 0 1 2-2zm3 6V3a3 3 0 0 0-6 0v4a2 2 0 0 0-2 2v5a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2z" />
          </svg>
          <input
            v-model="password"
            type="password"
            class="input-field"
            placeholder="Contraseña"
            required
          />
        </div>

        <p v-if="error" class="error-text">{{ error }}</p>
        <p v-if="notice" class="notice-text">{{ notice }}</p>

        <div class="btn-group">
          <button type="submit" class="button1" :disabled="loading">
            {{ loading ? 'Ingresando...' : 'Ingresar' }}
          </button>
          <button type="button" class="button2" @click="onRegisterClick">Registrarse</button>
        </div>

        <button type="button" class="button3" @click="onForgotClick">¿Olvidaste tu contraseña?</button>

        <div class="demo-box">
          <p class="demo-title">Cuentas de demo</p>
          <ul>
            <li>Admin: <span>admin / admin123</span></li>
            <li>Jefe: <span>carlos.mendoza / jefe123</span></li>
            <li>Familia: <span>familia.perez / familia123</span></li>
          </ul>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '../composables/useAuth.js'
import { defaultRoutes } from '../data/menu.js'
import logoImage from '../assets/sigas-logo.jpeg'
import bgImage from '../assets/sigas-bg.jpeg'

const router = useRouter()
const { login } = useAuth()

const username = ref('')
const password = ref('')
const error = ref('')
const notice = ref('')
const loading = ref(false)

function handleLogin() {
  error.value = ''
  notice.value = ''
  loading.value = true
  const session = login(username.value.trim(), password.value)
  loading.value = false
  if (!session) {
    error.value = 'Credenciales inválidas o usuario inactivo'
    return
  }
  router.push(defaultRoutes[session.rol] || '/login')
}

function onRegisterClick() {
  error.value = ''
  notice.value = 'El registro de nuevos usuarios lo gestiona el administrador del sistema.'
}

function onForgotClick() {
  error.value = ''
  notice.value = 'Contacta al jefe de tu calle o al administrador para recuperar tu acceso.'
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600&display=swap');

:root {
  --primary-blue: #0072CE;
  --dark-blue: #003366;
  --accent-orange: #FF7A00;
  --card-bg: rgba(15, 23, 36, 0.90);
}

.login-page {
  margin: 0;
  padding: 1rem;
  min-height: 100vh;
  width: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  background-repeat: no-repeat;
  background-position: center center;
  background-size: cover;
  background-attachment: fixed;
  font-family: 'Poppins', sans-serif;
  color: #ffffff;
  position: relative;
}

.login-page::before {
  content: '';
  position: absolute;
  inset: 0;
  background: rgba(0, 0, 0, 0.45);
  z-index: 0;
}

.card {
  position: relative;
  z-index: 1;
  background: linear-gradient(135deg, rgba(0, 114, 206, 0.3), rgba(255, 122, 0, 0.15));
  padding: 2px;
  border-radius: 24px;
  box-shadow: 0px 10px 35px rgba(56, 152, 216, 0.8), 0px 0px 20px rgba(67, 162, 218, 0.2);
  transition: transform 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275), box-shadow 0.4s ease;
}

.card:hover {
  transform: translateY(-4px);
  box-shadow: 0px 15px 40px rgba(0, 0, 0, 0.8), 0px 0px 30px rgba(0, 114, 206, 0.4);
}

.form {
  width: 390px;
  padding: 2.5em 2em;
  background-color: rgba(15, 23, 36, 0.6); /* o un color sólido en lugar de blanco/gris */
  color: #fff;
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border-radius: 22px;
  border: 1px solid rgb(50, 132, 209);
  display: flex;
  flex-direction: column;
  gap: 15px;
}

.logo-container {
  display: flex;
  justify-content: center;
  margin-bottom: 0.5em;
}

.brand-logo {
  width: 115px;
  height: 115px;
  border-radius: 50%;
  object-fit: cover;
  background-color: #3473d1;
  border: 3px solid rgba(255, 255, 255, 0.15);
  box-shadow: 0px 8px 20px rgba(0, 0, 0, 0.5);
  transition: transform 0.3s ease;
}

.brand-logo:hover {
  transform: scale(1.05);
}

#heading {
  text-align: center;
  margin: 0 0 10px 0;
  color: #ffffff;
  font-size: 1.5em;
  font-weight: 600;
  letter-spacing: 0.5px;
  text-shadow: 0px 2px 4px rgba(0, 0, 0, 0.5);
}

.field {
  display: flex;
  align-items: center;
  gap: 0.8em;
  border-radius: 12px;
  padding: 0.8em 1em;
  background-color: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.15);
  transition: border-color 0.3s ease, background-color 0.3s ease, box-shadow 0.3s ease;
}

.field:focus-within {
  border-color: var(--primary-blue);
  background-color: rgba(255, 255, 255, 0.15);
  box-shadow: 0 0 10px rgba(0, 114, 206, 0.4);
}

.input-icon {
  height: 1.2em;
  width: 1.2em;
  fill: #ffffff;
  transition: fill 0.3s ease;
  flex-shrink: 0;
}

.field:focus-within .input-icon {
  fill: #ffffff;
}

.input-field {
  background: none;
  border: none;
  outline: none;
  width: 100%;
  color: #ffffff;
  font-size: 0.95em;
  font-family: 'Poppins', sans-serif;
}

.input-field::placeholder {
  color: #ffffff;
}

.error-text {
  margin: 0;
  color: #ff8a8a;
  font-size: 0.85em;
  text-align: center;
}

.notice-text {
  margin: 0;
  color: #ffd699;
  font-size: 0.8em;
  text-align: center;
}

.btn-group {
  display: flex;
  gap: 10px;
  margin-top: 1em;
}

.button1 {
  flex: 1;
  padding: 0.8em;
  border-radius: 10px;
  border: none;
  font-family: 'Poppins', sans-serif;
  font-weight: 600;
  background: linear-gradient(135deg, #0072CE 0%, #227cc5 100%);
  color: white;
  cursor: pointer;
  transition: all 0.3s ease;
  box-shadow: 0 4px 12px rgba(0, 114, 206, 0.4);
}

.button1:hover:not(:disabled) {
  background: linear-gradient(135deg, #0084eb 0%, #005aa3 100%);
  box-shadow: 0 6px 18px rgba(0, 114, 206, 0.6);
  transform: translateY(-1px);
}

.button1:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.button2 {
  flex: 1;
  padding: 0.8em;
  border-radius: 10px;
  border: 1px solid rgba(255, 255, 255, 0.3);
  background: rgba(255, 255, 255, 0.05);
  color: #d1d5db;
  font-family: 'Poppins', sans-serif;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s ease;
}

.button2:hover {
  background: rgba(255, 255, 255, 0.15);
  color: #ffffff;
  border-color: rgba(255, 255, 255, 0.5);
  transform: translateY(-1px);
}

.button3 {
  background: none;
  border: none;
  color: #a0aec0;
  font-size: 0.85em;
  font-family: 'Poppins', sans-serif;
  cursor: pointer;
  margin-top: 0.5em;
  transition: color 0.3s ease;
  text-align: center;
}

.button3:hover {
  color: var(--accent-orange);
  text-decoration: underline;
}

.demo-box {
  margin-top: 0.8em;
  padding: 0.8em 1em;
  border-radius: 12px;
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.1);
}

.demo-title {
  margin: 0 0 0.4em 0;
  font-size: 0.75em;
  font-weight: 600;
  color: #d1d5db;
}

.demo-box ul {
  margin: 0;
  padding: 0;
  list-style: none;
  font-size: 0.72em;
  color: #a0aec0;
  display: flex;
  flex-direction: column;
  gap: 0.2em;
}

.demo-box span {
  color: #e2e8f0;
}
</style>
