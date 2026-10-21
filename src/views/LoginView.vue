<template>
  <div class="login-page" :style="{ backgroundImage: `url(${bgImage})` }">
    <div class="card">
      <form class="form" @submit.prevent="handleLogin">
        <div class="logo-container">
          <img :src="logoImage" alt="SIGAS Logo" class="brand-logo" />
        </div>

        <h2 id="heading">Iniciar Sesión</h2>

        <!-- CAMPO DE CORREO -->
        <div class="field">
          <svg viewBox="0 0 16 16" fill="currentColor" class="input-icon" xmlns="http://www.w3.org/2000/svg">
            <path d="M13.106 7.222c0-2.967-2.249-5.032-5.482-5.032-3.35 0-5.646 2.318-5.646 5.702 0 3.493 2.235 5.708 5.762 5.708.862 0 1.689-.123 2.304-.335v-.862c-.43.199-1.354.328-2.29.328-2.926 0-4.813-1.88-4.813-4.798 0-2.844 1.921-4.881 4.594-4.881 2.735 0 4.608 1.688 4.608 4.156 0 1.682-.554 2.769-1.416 2.769-.492 0-.772-.28-.772-.76V5.206H8.923v.834h-.11c-.266-.595-.881-.964-1.6-.964-1.4 0-2.378 1.162-2.378 2.823 0 1.737.957 2.906 2.379 2.906.8 0 1.415-.39 1.709-1.087h.11c.081.67.703 1.148 1.503 1.148 1.572 0 2.57-1.415 2.57-3.643zm-7.177.704c0-1.197.54-1.907 1.456-1.907.93 0 1.524.738 1.524 1.907S8.308 9.84 7.371 9.84c-.895 0-1.442-.725-1.442-1.914z" />
          </svg>
          <input
            v-model="loginEmail"
            type="email"
            class="input-field"
            placeholder="Correo Electrónico"
            required
          />
        </div>

        <!-- CAMPO DE CONTRASEÑA -->
        <div class="field">
          <svg viewBox="0 0 16 16" fill="currentColor" class="input-icon" xmlns="http://www.w3.org/2000/svg">
            <path d="M8 1a2 2 0 0 1 2 2v4H6V3a2 2 0 0 1 2-2zm3 6V3a3 3 0 0 0-6 0v4a2 2 0 0 0-2 2v5a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2z" />
          </svg>
          <input
            v-model="loginPassword"
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
          <button type="button" class="button2" @click="abrirModalRegistro">Registrarse</button>
        </div>

        <button type="button" class="button3" @click="onForgotClick">¿Olvidaste tu contraseña?</button>
      </form>
    </div>

    <!-- MODAL DE REGISTRO DE FAMILIA -->
    <div v-if="mostrarModal" class="modal-overlay" @click.self="mostrarModal = false">
      <div class="modal-card" role="dialog" aria-modal="true" aria-label="Registro de familia">
        <span class="modal-sheet-handle" aria-hidden="true"></span>
        <h3>Registro de Familia</h3>
        <form @submit.prevent="handleRegister" class="modal-form">
          <div class="field">
            <input v-model="regCedula" type="number" class="input-field" placeholder="Cédula (ID de la Familia)" required />
          </div>

          <div class="field">
            <input v-model="regNombre" type="text" class="input-field" placeholder="Nombre y Apellido" required />
          </div>

          <div class="field">
            <input v-model="regEmail" type="email" class="input-field" placeholder="Correo Electrónico" required />
          </div>

          <div class="field">
            <select v-model="regCalle" class="select-field" required>
              <option value="" disabled selected>Selecciona tu Calle</option>
              <option v-for="calle in listaCalles" :key="calle.id_calle" :value="calle.id_calle">
                {{ calle.nombre }}
              </option>
            </select>
          </div>

          <div class="field">
            <input v-model="regPassword" type="password" class="input-field" placeholder="Contraseña" required />
          </div>

          <p v-if="regError" class="error-text">{{ regError }}</p>

          <div class="btn-group">
            <button type="submit" class="button1" :disabled="loadingReg">
              {{ loadingReg ? 'Guardando...' : 'Completar Registro' }}
            </button>
            <button type="button" class="button2" @click="mostrarModal = false">Cancelar</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../composables/supabase.js'
import { useAuth } from '../composables/useAuth.js'
import logoImage from '../assets/sigas-logo.jpeg'
import bgImage from '../assets/sigas-bg.jpeg'

const router = useRouter()
const { setSession } = useAuth()

// Variables de Login
const loginEmail = ref('')
const loginPassword = ref('')
const error = ref('')
const notice = ref('')
const loading = ref(false)

// Variables de Registro
const mostrarModal = ref(false)
const regCedula = ref('')
const regNombre = ref('')
const regEmail = ref('')
const regCalle = ref('')
const regPassword = ref('')
const regError = ref('')
const loadingReg = ref(false)
const listaCalles = ref([])

// Cargar las calles activas registradas en Supabase
onMounted(async () => {
  const { data, error: calleError } = await supabase
    .from('calles')
    .select('id_calle, nombre')
    .eq('activo', true)

  if (!calleError && data) {
    listaCalles.value = data
  }
})

function abrirModalRegistro() {
  regError.value = ''
  mostrarModal.value = true
}

// Proceso de Inicio de Sesión
async function handleLogin() {
  error.value = ''
  notice.value = ''
  loading.value = true

  // 1. Iniciar sesión en Supabase Auth
  const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
    email: loginEmail.value.trim(),
    password: loginPassword.value,
  })

  if (authError) {
    loading.value = false
    error.value = 'Credenciales inválidas o usuario no registrado'
    return
  }

  // 2. Consultar la tabla familias para obtener el id_cargo y datos de la familia
  const { data: familiaData } = await supabase
    .from('familias')
    .select('id_cargo, nombre_familia, id')
    .eq('auth_id', authData.user.id)
    .maybeSingle()

  loading.value = false

  // Mapear id_cargo a la cadena de rol que espera el router ('admin', 'jefe', 'familia')
  const cargoMap = {
    1: 'admin',
    2: 'jefe',
    3: 'familia'
  }

  const userRole = cargoMap[familiaData?.id_cargo] || 'familia'

  // 3. Establecer la sesión en useAuth y localStorage
  setSession({
    id: familiaData?.id || authData.user.id,
    authId: authData.user.id,
    email: authData.user.email,
    nombre: familiaData?.nombre_familia || 'Usuario',
    rol: userRole,
  })

  // 4. Redirigir según el rol
  if (userRole === 'admin') {
    router.push('/admin/dashboard')
  } else if (userRole === 'jefe') {
    router.push('/jefe/dashboard')
  } else {
    router.push('/familia/dashboard')
  }
}

// Proceso de Registro Completo
async function handleRegister() {
  regError.value = ''
  loadingReg.value = true

  const emailTrimmed = regEmail.value.trim()

  // 1. Crear usuario en Authentication de Supabase
  const { data: authData, error: authErr } = await supabase.auth.signUp({
    email: emailTrimmed,
    password: regPassword.value,
  })

  if (authErr) {
    loadingReg.value = false
    if (
      authErr.message.toLowerCase().includes('already registered') || 
      authErr.message.toLowerCase().includes('already exists') ||
      authErr.status === 422
    ) {
      regError.value = 'Este correo electrónico ya está registrado. Inicia sesión.'
    } else {
      regError.value = authErr.message
    }
    return
  }

  if (authData?.user?.identities && authData.user.identities.length === 0) {
    loadingReg.value = false
    regError.value = 'Este correo electrónico ya se encuentra registrado en el sistema.'
    return
  }

  // 2. Insertar registro en la tabla 'familias'
  const { error: dbError } = await supabase.from('familias').insert([
    {
      id: parseInt(regCedula.value),
      auth_id: authData.user.id,
      nombre_familia: regNombre.value,
      id_calle: parseInt(regCalle.value),
      id_cargo: 3, // Cargo 3 = Familia por defecto
      activo: true
    }
  ])

  loadingReg.value = false

  if (dbError) {
    regError.value = 'Error al registrar en la base de datos: ' + dbError.message
  } else {
    mostrarModal.value = false
    notice.value = '¡Registro exitoso! Ya puedes iniciar sesión.'
    loginEmail.value = emailTrimmed
    loginPassword.value = ''
  }
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
  /* Safe areas para iPhone (Dynamic Island / Home Indicator) */
  padding: calc(1rem + env(safe-area-inset-top, 0px)) 1rem calc(1rem + env(safe-area-inset-bottom, 0px)) 1rem;
  /* 100dvh = dynamic viewport height, soluciona el bug de 100vh en iOS Safari */
  min-height: 100vh;
  min-height: 100dvh;
  width: 100%;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  background-repeat: no-repeat;
  background-position: center center;
  background-size: cover;
  font-family: 'Poppins', sans-serif;
  color: #ffffff;
  position: relative;
  box-sizing: border-box;
}

.login-page::before {
  content: '';
  position: absolute;
  /* Cubrir toda el área incluyendo el área scrolleada */
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.45);
  z-index: 0;
  pointer-events: none;
}

.card {
  position: relative;
  z-index: 1;
  background: linear-gradient(135deg, rgba(0, 114, 206, 0.3), rgba(255, 122, 0, 0.15));
  padding: 2px;
  border-radius: 26px;
  box-shadow: 0px 12px 40px rgba(56, 152, 216, 0.8), 0px 0px 25px rgba(67, 162, 218, 0.2);
  transition: transform 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275), box-shadow 0.4s ease;
}

.card:hover {
  transform: translateY(-4px);
  box-shadow: 0px 18px 45px rgba(0, 0, 0, 0.8), 0px 0px 35px rgba(0, 114, 206, 0.4);
}

.form {
  width: 100%;
  max-width: 420px;
  margin: 0 auto;
  padding: 2em 1.5em;
  /* Margen lateral en pantallas estrechas para que no se sienta pegado */
  margin-left: 0.75rem;
  margin-right: 0.75rem;
  background-color: rgba(15, 23, 36, 0.80);
  color: #fff;
  backdrop-filter: blur(16px);
  -webkit-backdrop-filter: blur(16px);
  border-radius: 24px;
  border: 1px solid rgb(50, 132, 209);
  display: flex;
  flex-direction: column;
  gap: 16px;
  box-sizing: border-box;
}

.logo-container {
  display: flex;
  justify-content: center;
  margin-bottom: 0.5em;
}

.brand-logo {
  width: 125px; /* Logo interno un poco más grande */
  height: 125px;
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
  font-size: 1.65em;
  font-weight: 600;
  letter-spacing: 0.5px;
  text-shadow: 0px 2px 4px rgba(0, 0, 0, 0.5);
}

.field {
  display: flex;
  align-items: center;
  gap: 0.8em;
  border-radius: 12px;
  padding: 0.85em 1.1em;
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
  height: 1.25em;
  width: 1.25em;
  fill: #ffffff;
  transition: fill 0.3s ease;
  flex-shrink: 0;
}

.input-field, .select-field {
  background: none;
  border: none;
  outline: none;
  width: 100%;
  color: #ffffff;
  font-size: 1em;
  font-family: 'Poppins', sans-serif;
}

.input-field::placeholder {
  color: #ffffff;
}

.select-field option {
  background-color: #0f1724;
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
  color: #72f293;
  font-size: 0.85em;
  text-align: center;
}

.btn-group {
  display: flex;
  gap: 12px;
  margin-top: 1em;
}

.button1 {
  flex: 1;
  padding: 0.85em;
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
  padding: 0.85em;
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
  font-size: 0.9em;
  font-family: 'Poppins', sans-serif;
  cursor: pointer;
  margin-top: 0.6em;
  transition: color 0.3s ease;
  text-align: center;
}

.button3:hover {
  color: var(--accent-orange);
  text-decoration: underline;
}

/* MODAL DE REGISTRO */
.modal-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.75);
  z-index: 100;
  display: flex;
  justify-content: center;
  align-items: center;
  backdrop-filter: blur(4px);
}

.modal-card {
  background: #0f1724;
  padding: 2em 1.5em;
  border-radius: 20px;
  width: 100%;
  max-width: 420px;
  /* Margen lateral en pantallas estrechas */
  margin-left: 0.75rem;
  margin-right: 0.75rem;
  border: 1px solid #0072CE;
  box-shadow: 0 10px 30px rgba(0,0,0,0.8);
  box-sizing: border-box;
}

.modal-card h3 {
  margin-top: 0;
  margin-bottom: 15px;
  text-align: center;
  color: #ffffff;
}

.modal-form {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

/* ==========================================================================
   RESPONSIVE · mobile-first
   ========================================================================== */
.card {
  width: min(100%, 420px);
}

.form {
  width: 100%;
  max-width: none;
  margin-left: 0;
  margin-right: 0;
  padding: 1.6em 1.1em;
}

.brand-logo {
  width: 96px;
  height: 96px;
}

#heading {
  font-size: 1.45em;
}

.field {
  min-height: 50px;
  padding: 0.7em 0.9em;
}

.input-field,
.select-field {
  min-height: 32px;
  font-size: 16px;
}

.btn-group {
  flex-direction: column;
  gap: 10px;
}

.button1,
.button2 {
  min-height: 48px;
  padding: 0.8em 1em;
}

.button3 {
  min-height: 44px;
  padding: 6px;
  font-size: 0.82em;
}

.modal-overlay {
  align-items: flex-end;
  padding: 0;
}

.modal-card {
  width: 100%;
  max-width: none;
  max-height: 88dvh;
  margin: 0;
  padding: 12px 16px calc(18px + var(--safe-bottom));
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
  border-radius: 22px 22px 0 0;
  animation: loginSheetUp 0.22s ease-out;
}

.modal-sheet-handle {
  display: block;
  width: 40px;
  height: 4px;
  margin: 0 auto 14px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.25);
}

.modal-card h3 {
  font-size: 1.05rem;
}

@keyframes loginSheetUp {
  from { transform: translateY(16px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

@media (min-width: 480px) {
  .brand-logo {
    width: 108px;
    height: 108px;
  }

  .form {
    padding: 1.8em 1.4em;
  }
}

@media (min-width: 640px) {
  .login-page {
    padding: 1.5rem;
  }

  .form {
    padding: 2em 1.5em;
  }

  .brand-logo {
    width: 125px;
    height: 125px;
  }

  #heading {
    font-size: 1.65em;
  }

  .field {
    min-height: 0;
    padding: 0.85em 1.1em;
  }

  .input-field,
  .select-field {
    min-height: 24px;
    font-size: 15px;
  }

  .btn-group {
    flex-direction: row;
    gap: 12px;
  }

  .button1,
  .button2 {
    min-height: 44px;
  }

  .button3 {
    min-height: 40px;
    font-size: 0.9em;
  }

  .modal-overlay {
    align-items: center;
    padding: 1rem;
  }

  .modal-card {
    width: 100%;
    max-width: 420px;
    max-height: 88vh;
    margin: 0;
    padding: 2em 1.5em;
    border-radius: 20px;
    animation: scaleIn 0.2s ease-out;
  }

  .modal-sheet-handle {
    display: none;
  }
}

@media (min-width: 1024px) {
  .input-field,
  .select-field {
    font-size: 14px;
  }

  .button1,
  .button2 {
    min-height: 42px;
  }
}
</style>