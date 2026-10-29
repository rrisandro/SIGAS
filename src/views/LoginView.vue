<template>
  <div class="login-page">
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
            autocomplete="email"
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
            autocomplete="current-password"
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

    <!-- MODAL DE RECUPERACIÓN DE CONTRASEÑA -->
    <div v-if="showForgot" class="modal-overlay" @click.self="closeForgot">
      <div class="modal-card" role="dialog" aria-modal="true" aria-label="Recuperar contraseña">
        <span class="modal-sheet-handle" aria-hidden="true"></span>
        <h3>Recuperar contraseña</h3>
        <p class="modal-hint">
          Escribe el correo de tu cuenta y te enviaremos un enlace para crear una nueva contraseña.
        </p>

        <form class="modal-form" @submit.prevent="handleForgotPassword">
          <div class="field">
            <input
              v-model="forgotEmail"
              type="email"
              class="input-field"
              placeholder="Correo Electrónico"
              autocomplete="email"
              required
            />
          </div>

          <p v-if="forgotError" class="error-text">{{ forgotError }}</p>
          <p v-if="forgotNotice" class="notice-text">{{ forgotNotice }}</p>

          <div class="btn-group">
            <button type="submit" class="button1" :disabled="forgotLoading">
              {{ forgotLoading ? 'Enviando...' : 'Enviar enlace' }}
            </button>
            <button type="button" class="button2" :disabled="forgotLoading" @click="closeForgot">
              Cancelar
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL DE REGISTRO DE FAMILIA -->
    <div v-if="mostrarModal" class="modal-overlay" @click.self="cerrarModalRegistro">
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
            <input
              v-model="regPassword"
              type="password"
              class="input-field"
              placeholder="Contraseña"
              autocomplete="new-password"
              minlength="6"
              required
            />
          </div>

          <p v-if="regError" class="error-text">{{ regError }}</p>

          <div class="btn-group">
            <button type="submit" class="button1" :disabled="loadingReg">
              {{ loadingReg ? 'Guardando...' : 'Completar Registro' }}
            </button>
            <button type="button" class="button2" :disabled="loadingReg" @click="cerrarModalRegistro">
              Cancelar
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { PASSWORD_RESET_REDIRECT, supabase } from '../lib/supabase.js'
import { useAuth } from '../composables/useAuth.js'
import logoImage from '../assets/sigas-logo.jpeg'

const router = useRouter()
const route = useRoute()
const { setSession } = useAuth()

// Variables de Login
const loginEmail = ref('')
const loginPassword = ref('')
const error = ref('')
const notice = ref('')
const loading = ref(false)

// Variables de recuperación
const showForgot = ref(false)
const forgotEmail = ref('')
const forgotError = ref('')
const forgotNotice = ref('')
const forgotLoading = ref(false)

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

const cargoMap = {
  1: 'admin',
  2: 'jefe',
  3: 'familia',
}

onMounted(async () => {
  if (route.query.reset === '1') {
    notice.value = 'Tu contraseña se actualizó correctamente. Inicia sesión con tu nueva contraseña.'
  }
  await cargarCalles()
})

async function cargarCalles() {
  try {
    let { data, error: queryError } = await supabase
      .from('calles')
      .select('id_calle, nombre')
      .eq('activo', true)
      .eq('is_deleted', false)
      .order('nombre')

    // Compatibilidad mientras se ejecuta la migración de soft delete.
    if (queryError && /is_deleted/i.test(queryError.message || '')) {
      const fallback = await supabase
        .from('calles')
        .select('id_calle, nombre')
        .eq('activo', true)
        .order('nombre')
      data = fallback.data
      queryError = fallback.error
    }

    if (queryError) throw queryError
    listaCalles.value = data || []
  } catch (err) {
    console.error('[SIGAS] Error cargando calles:', err)
  }
}

function abrirModalRegistro() {
  regError.value = ''
  mostrarModal.value = true
}

function cerrarModalRegistro() {
  if (loadingReg.value) return
  mostrarModal.value = false
}

function onForgotClick() {
  forgotEmail.value = loginEmail.value.trim()
  forgotError.value = ''
  forgotNotice.value = ''
  showForgot.value = true
}

function closeForgot() {
  if (forgotLoading.value) return
  showForgot.value = false
}

function mensajeDeError(err, fallback) {
  const mensaje = String(err?.message || err?.error_description || '')
  if (/already registered|already exists|user already/i.test(mensaje)) {
    return 'Este correo electrónico ya está registrado. Inicia sesión o recupera tu contraseña.'
  }
  if (/invalid login credentials/i.test(mensaje)) {
    return 'Correo o contraseña incorrectos.'
  }
  if (/email not confirmed/i.test(mensaje)) {
    return 'Debes confirmar tu correo electrónico antes de iniciar sesión.'
  }
  if (/registro de familia asociado/i.test(mensaje)) {
    return 'Esta cuenta ya tiene un registro de familia. Inicia sesión o contacta al Jefe de Calle.'
  }
  if (/duplicate key|ya existe|cedula|cédula/i.test(mensaje)) {
    return 'Ya existe un registro con esa cédula. Si es tuyo, contacta al Jefe de Calle.'
  }
  if (/password/i.test(mensaje) && /least|short|6/i.test(mensaje)) {
    return 'La contraseña debe tener al menos 6 caracteres.'
  }
  return mensaje || fallback
}

// Proceso de Inicio de Sesión
async function handleLogin() {
  error.value = ''
  notice.value = ''
  loading.value = true

  try {
    const email = loginEmail.value.trim()
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email,
      password: loginPassword.value,
    })

    if (authError) throw authError

    // Consultar la tabla familias para obtener el id_cargo y datos de la familia.
    const { data: perfil, error: perfilError } = await supabase
      .from('familias')
      .select('*')
      .eq('auth_id', authData.user.id)
      .order('id', { ascending: true })
      .limit(1)
      .maybeSingle()

    if (perfilError) {
      console.warn('[SIGAS] No se pudo leer el perfil de familias:', perfilError)
    }

    let perfilFinal = perfil

    // Los Jefes de Calle también pueden existir solo en jefe_de_calle.
    if (!perfilFinal) {
      const { data: jefe } = await supabase
        .from('jefe_de_calle')
        .select('*')
        .eq('auth_id', authData.user.id)
        .eq('activo', true)
        .eq('is_deleted', false)
        .limit(1)
        .maybeSingle()

      if (jefe) {
        perfilFinal = {
          id: jefe.id_jefe_calle,
          auth_id: jefe.auth_id,
          nombre_familia: jefe.nombre,
          id_calle: jefe.id_calle,
          id_cargo: 2,
          activo: jefe.activo,
          estado: 'aprobado',
          is_deleted: jefe.is_deleted,
        }
      }
    }

    if (!perfilFinal) {
      throw new Error('Tu cuenta no tiene un perfil asociado. Contacta al administrador.')
    }

    if (perfilFinal.is_deleted) {
      throw new Error('Esta cuenta fue dada de baja. Contacta al administrador.')
    }

    const esFamilia = Number(perfilFinal.id_cargo) === 3
    const estado = String(perfilFinal.estado || 'aprobado').toLowerCase()

    if (esFamilia && estado === 'pendiente') {
      throw new Error(
        'Tu registro está PENDIENTE de aprobación por el Jefe de Calle de tu zona. Te avisaremos cuando sea aprobado.'
      )
    }

    if (esFamilia && estado === 'rechazado') {
      const motivo = perfilFinal.notas_rechazo ? ` Motivo: ${perfilFinal.notas_rechazo}` : ''
      throw new Error(`Tu registro fue rechazado.${motivo}`)
    }

    if (perfilFinal.activo === false) {
      throw new Error('Tu cuenta está inactiva. Contacta al administrador.')
    }

    const rol = cargoMap[Number(perfilFinal.id_cargo)] || 'familia'

    setSession({
      id: perfilFinal.id,
      authId: authData.user.id,
      email: authData.user.email,
      nombre: perfilFinal.nombre_familia || authData.user.email,
      rol,
      idCalle: perfilFinal.id_calle || null,
      estado,
    })

    const rutas = {
      admin: '/admin/dashboard',
      jefe: '/jefe/dashboard',
      familia: '/familia/dashboard',
    }
    await router.push(rutas[rol] || '/familia/dashboard')
  } catch (err) {
    console.error('[SIGAS] Error de login:', err)
    error.value = mensajeDeError(err, 'No se pudo iniciar sesión. Intenta nuevamente.')

    // Si la cuenta existe pero no está autorizada, cerramos la sesión temporal.
    if (!/incorrectos|confirmar tu correo/i.test(error.value)) {
      await supabase.auth.signOut().catch(() => {})
    }
  } finally {
    loading.value = false
  }
}

// Recuperación de contraseña con enlace de Supabase
async function handleForgotPassword() {
  forgotError.value = ''
  forgotNotice.value = ''
  const email = forgotEmail.value.trim()

  if (!email) {
    forgotError.value = 'Escribe tu correo electrónico.'
    return
  }

  forgotLoading.value = true
  try {
    const { error: resetError } = await supabase.auth.resetPasswordForEmail(email, {
      redirectTo: PASSWORD_RESET_REDIRECT,
    })

    if (resetError) throw resetError

    forgotNotice.value =
      'Si el correo está registrado, recibirás un enlace para restablecer tu contraseña. Revisa también la carpeta de spam.'
    notice.value = forgotNotice.value
  } catch (err) {
    console.error('[SIGAS] Error enviando recuperación:', err)
    forgotError.value = mensajeDeError(
      err,
      'No se pudo enviar el enlace de recuperación. Intenta nuevamente.'
    )
  } finally {
    forgotLoading.value = false
  }
}

async function insertarRegistroDirecto(authUserId, payload) {
  const { error: insertError } = await supabase.from('familias').insert([
    {
      id: payload.p_id,
      auth_id: authUserId,
      nombre_familia: payload.p_nombre,
      id_calle: payload.p_id_calle,
      id_cargo: 3,
      activo: false,
      estado: 'pendiente',
      telefono: payload.p_telefono,
      direccion: payload.p_direccion,
      num_personas: payload.p_personas,
      email: payload.p_email,
      is_deleted: false,
    },
  ])

  if (insertError) throw insertError

  // Notificación al Jefe de Calle de la zona (fallback si el RPC aún no existe).
  const { data: jefe } = await supabase
    .from('jefe_de_calle')
    .select('*')
    .eq('id_calle', payload.p_id_calle)
    .eq('activo', true)
    .eq('is_deleted', false)
    .limit(1)

  const jefeZona = jefe?.[0]
  if (jefeZona?.auth_id) {
    const { error: notifError } = await supabase.from('notificaciones').insert([
      {
        destinatario_auth_id: jefeZona.auth_id,
        id_jefe_calle: jefeZona.id_jefe_calle,
        id_familia: payload.p_id,
        tipo: 'registro_familia',
        titulo: 'Nuevo registro pendiente',
        mensaje: `La familia ${payload.p_nombre} (cédula ${payload.p_id}) solicitó registro en tu calle.`,
        metadata: {
          id_familia: payload.p_id,
          id_calle: payload.p_id_calle,
          email: payload.p_email,
        },
      },
    ])
    if (notifError) {
      console.warn('[SIGAS] No se pudo insertar la notificación:', notifError)
    }
  }

  return { notificado: Boolean(jefeZona?.auth_id) }
}

// Proceso de Registro Completo
async function handleRegister() {
  regError.value = ''

  const cedula = Number(regCedula.value)
  const email = regEmail.value.trim()
  const nombre = regNombre.value.trim()

  if (!Number.isInteger(cedula) || cedula <= 0) {
    regError.value = 'Ingresa una cédula válida.'
    return
  }
  if (!nombre) {
    regError.value = 'Ingresa tu nombre y apellido.'
    return
  }
  if (!email) {
    regError.value = 'Ingresa tu correo electrónico.'
    return
  }
  if (!regCalle.value) {
    regError.value = 'Selecciona tu calle o sector.'
    return
  }
  if (regPassword.value.length < 6) {
    regError.value = 'La contraseña debe tener al menos 6 caracteres.'
    return
  }

  loadingReg.value = true

  try {
    // 1. Crear usuario en Authentication de Supabase
    const { data: authData, error: authErr } = await supabase.auth.signUp({
      email,
      password: regPassword.value,
      options: {
        data: {
          nombre,
          cedula,
        },
      },
    })

    if (authErr) throw authErr

    if (authData?.user?.identities && authData.user.identities.length === 0) {
      throw new Error('Este correo electrónico ya se encuentra registrado en el sistema.')
    }

    if (!authData?.user?.id) {
      throw new Error('No se pudo crear la cuenta. Intenta nuevamente.')
    }

    // 2. Registrar la familia en estado PENDIENTE.
    const payload = {
      p_id: cedula,
      p_auth_id: authData.user.id,
      p_nombre: nombre,
      p_id_calle: Number(regCalle.value),
      p_telefono: null,
      p_direccion: null,
      p_personas: null,
      p_email: email,
    }

    let resultado = null
    const { data: rpcData, error: rpcError } = await supabase.rpc(
      'registrar_familia_pendiente',
      payload
    )

    if (rpcError) {
      const noExisteRpc =
        rpcError.code === 'PGRST202' ||
        /could not find the function|function .* does not exist/i.test(rpcError.message || '')

      if (noExisteRpc) {
        resultado = await insertarRegistroDirecto(authData.user.id, payload)
      } else {
        throw rpcError
      }
    } else {
      resultado = rpcData
    }

    // Si Supabase creó una sesión (confirmación de correo desactivada),
    // la cerramos: el usuario aún no puede entrar hasta ser aprobado.
    if (authData.session) {
      await supabase.auth.signOut().catch(() => {})
    }

    const notificado = resultado?.notificado !== false
    notice.value = notificado
      ? 'Registro enviado. Quedó en estado PENDIENTE y el Jefe de Calle de tu zona recibió una notificación.'
      : 'Registro enviado. Quedó en estado PENDIENTE. Aún no hay un Jefe de Calle asignado a tu zona; el administrador lo revisará.'

    loginEmail.value = email
    loginPassword.value = ''
    regCedula.value = ''
    regNombre.value = ''
    regEmail.value = ''
    regCalle.value = ''
    regPassword.value = ''
    mostrarModal.value = false
  } catch (err) {
    console.error('[SIGAS] Error de registro:', err)
    regError.value = mensajeDeError(
      err,
      'No se pudo completar el registro. Intenta nuevamente.'
    )
  } finally {
    loadingReg.value = false
  }
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
  /* Fondo sólido en tonos azules: contrasta con la tarjeta oscura del login. */
  background: radial-gradient(circle at 18% 18%, #e0f2fe 0%, #7dd3fc 38%, #0ea5e9 70%, #0369a1 100%);
  font-family: 'Poppins', sans-serif;
  color: #ffffff;
  position: relative;
  box-sizing: border-box;
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

/* MODAL */
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
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.8);
  box-sizing: border-box;
}

.modal-card h3 {
  margin-top: 0;
  margin-bottom: 15px;
  text-align: center;
  color: #ffffff;
}

.modal-hint {
  margin: -4px 0 14px;
  color: #a0aec0;
  font-size: 0.88em;
  line-height: 1.5;
  text-align: center;
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

@keyframes scaleIn {
  from { transform: scale(0.96); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
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
