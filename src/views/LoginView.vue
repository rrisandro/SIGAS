<template>
  <div class="login-page">
    <div class="login-bg" aria-hidden="true">
      <div class="bg-glow bg-glow--one" />
      <div class="bg-glow bg-glow--two" />
      <div class="bg-grid" />
    </div>

    <div class="card">
      <form class="form" @submit.prevent="handleLogin" novalidate>
        <div class="logo-container">
          <img :src="logoImage" alt="SIGAS Logo" class="brand-logo" />
        </div>

        <div class="heading-wrap">
          <p class="eyebrow">Sistema Integral de Gas</p>
          <h2 id="heading">Iniciar Sesión</h2>
          <p class="subtitle">Accede con tu correo y contraseña registrados.</p>
        </div>

        <!-- CAMPO DE CORREO -->
        <div class="field">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" class="input-icon" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16v12H4z" />
            <path stroke-linecap="round" stroke-linejoin="round" d="m4 7 8 6 8-6" />
          </svg>
          <input
            id="login-email"
            v-model="loginEmail"
            type="email"
            class="input-field"
            placeholder="Correo electrónico"
            autocomplete="email"
            aria-label="Correo electrónico"
            required
          />
        </div>

        <!-- CAMPO DE CONTRASEÑA -->
        <div class="field">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" class="input-icon" aria-hidden="true">
            <rect x="4" y="10" width="16" height="10" rx="2" />
            <path stroke-linecap="round" d="M8 10V7a4 4 0 0 1 8 0v3" />
          </svg>
          <input
            id="login-password"
            v-model="loginPassword"
            :type="showPassword ? 'text' : 'password'"
            class="input-field"
            placeholder="Contraseña"
            autocomplete="current-password"
            aria-label="Contraseña"
            required
          />
          <button
            type="button"
            class="password-toggle"
            :aria-label="showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'"
            @click="showPassword = !showPassword"
          >
            <svg v-if="showPassword" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M3 3l18 18M10.6 10.6a2 2 0 0 0 2.8 2.8M9.9 5.2A10.4 10.4 0 0 1 12 5c5.5 0 9 7 9 7a17.6 17.6 0 0 1-3.2 4.1M6.2 6.2C4.1 7.8 3 10 3 12c0 0 3.5 7 9 7 1.1 0 2.1-.3 3-.7" />
            </svg>
            <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" d="M2.5 12S6 5 12 5s9.5 7 9.5 7-3.5 7-9.5 7-9.5-7-9.5-7z" />
              <circle cx="12" cy="12" r="2.8" />
            </svg>
          </button>
        </div>

        <p v-if="error" class="error-text" role="alert">{{ error }}</p>
        <p v-if="notice" class="notice-text" role="status">{{ notice }}</p>

        <div class="btn-group">
          <button type="submit" class="button1" :disabled="loading">
            <span v-if="loading" class="btn-spinner" aria-hidden="true" />
            {{ loading ? 'Ingresando...' : 'Ingresar' }}
          </button>
          <button type="button" class="button2" @click="openRegister">Registrarse</button>
        </div>

        <button type="button" class="button3" @click="openForgot">¿Olvidaste tu contraseña?</button>

        <p class="footnote">Al ingresar aceptas las políticas de uso y privacidad de SIGAS.</p>
      </form>
    </div>

    <!-- MODAL DE RECUPERACIÓN DE CONTRASEÑA -->
    <Teleport to="body">
      <div v-if="showForgot" class="modal-overlay" @click.self="closeForgot">
        <div class="modal-card" role="dialog" aria-modal="true" aria-labelledby="forgot-title">
          <span class="modal-sheet-handle" aria-hidden="true"></span>
          <button type="button" class="modal-close" aria-label="Cerrar" @click="closeForgot">×</button>
          <h3 id="forgot-title">Recuperar contraseña</h3>
          <p class="modal-hint">
            Escribe el correo de tu cuenta y te enviaremos un enlace para crear una nueva contraseña.
          </p>

          <form class="modal-form" @submit.prevent="handleForgotPassword">
            <div class="field">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" class="input-icon" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16v12H4z" />
                <path stroke-linecap="round" stroke-linejoin="round" d="m4 7 8 6 8-6" />
              </svg>
              <input
                id="forgot-email"
                v-model="forgotEmail"
                type="email"
                class="input-field"
                placeholder="Correo electrónico"
                autocomplete="email"
                aria-label="Correo electrónico"
                required
              />
            </div>

            <p v-if="forgotError" class="error-text" role="alert">{{ forgotError }}</p>
            <p v-if="forgotNotice" class="notice-text" role="status">{{ forgotNotice }}</p>

            <div class="modal-actions">
              <button type="button" class="button2" :disabled="forgotLoading" @click="closeForgot">Cancelar</button>
              <button type="submit" class="button1" :disabled="forgotLoading">
                <span v-if="forgotLoading" class="btn-spinner" aria-hidden="true" />
                {{ forgotLoading ? 'Enviando...' : 'Enviar enlace' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>

    <!-- MODAL DE REGISTRO DE FAMILIA -->
    <Teleport to="body">
      <div v-if="showRegister" class="modal-overlay" @click.self="closeRegister">
        <div class="modal-card modal-card--wide" role="dialog" aria-modal="true" aria-labelledby="register-title">
          <span class="modal-sheet-handle" aria-hidden="true"></span>
          <button type="button" class="modal-close" aria-label="Cerrar" @click="closeRegister">×</button>
          <h3 id="register-title">Registro de Familia</h3>
          <p class="modal-hint">
            Completa tus datos. El registro quedará en estado <strong>PENDIENTE</strong> hasta que el Jefe de Calle de tu zona lo revise y apruebe.
          </p>

          <form class="modal-form register-form" @submit.prevent="handleRegister" novalidate>
            <div class="form-grid">
              <div class="field">
                <input
                  id="reg-cedula"
                  v-model="regCedula"
                  type="number"
                  inputmode="numeric"
                  min="1"
                  class="input-field"
                  placeholder="Cédula (ID de la Familia)"
                  aria-label="Cédula"
                  required
                />
              </div>

              <div class="field">
                <input
                  id="reg-nombre"
                  v-model="regNombre"
                  type="text"
                  class="input-field"
                  placeholder="Nombre y Apellido"
                  autocomplete="name"
                  aria-label="Nombre y apellido"
                  required
                />
              </div>

              <div class="field">
                <input
                  id="reg-email"
                  v-model="regEmail"
                  type="email"
                  class="input-field"
                  placeholder="Correo Electrónico"
                  autocomplete="email"
                  aria-label="Correo electrónico"
                  required
                />
              </div>

              <div class="field">
                <input
                  id="reg-telefono"
                  v-model="regTelefono"
                  type="tel"
                  class="input-field"
                  placeholder="Teléfono"
                  autocomplete="tel"
                  aria-label="Teléfono"
                />
              </div>

              <div class="field">
                <select
                  id="reg-calle"
                  v-model="regCalle"
                  class="select-field"
                  aria-label="Calle o sector"
                  required
                >
                  <option value="" disabled>Selecciona tu Calle</option>
                  <option v-for="calle in listaCalles" :key="calle.id_calle" :value="calle.id_calle">
                    {{ calle.nombre }}
                  </option>
                </select>
              </div>

              <div class="field">
                <input
                  id="reg-personas"
                  v-model="regPersonas"
                  type="number"
                  inputmode="numeric"
                  min="1"
                  class="input-field"
                  placeholder="Personas en el hogar"
                  aria-label="Personas en el hogar"
                />
              </div>
            </div>

            <div class="field">
              <input
                id="reg-direccion"
                v-model="regDireccion"
                type="text"
                class="input-field"
                placeholder="Dirección de la vivienda"
                autocomplete="street-address"
                aria-label="Dirección de la vivienda"
              />
            </div>

            <div class="form-grid">
              <div class="field">
                <input
                  id="reg-password"
                  v-model="regPassword"
                  :type="showRegPassword ? 'text' : 'password'"
                  class="input-field"
                  placeholder="Contraseña"
                  autocomplete="new-password"
                  minlength="6"
                  aria-label="Contraseña"
                  required
                />
                <button
                  type="button"
                  class="password-toggle"
                  :aria-label="showRegPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'"
                  @click="showRegPassword = !showRegPassword"
                >
                  <svg v-if="showRegPassword" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M3 3l18 18M10.6 10.6a2 2 0 0 0 2.8 2.8M9.9 5.2A10.4 10.4 0 0 1 12 5c5.5 0 9 7 9 7a17.6 17.6 0 0 1-3.2 4.1M6.2 6.2C4.1 7.8 3 10 3 12c0 0 3.5 7 9 7 1.1 0 2.1-.3 3-.7" />
                  </svg>
                  <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M2.5 12S6 5 12 5s9.5 7 9.5 7-3.5 7-9.5 7-9.5-7-9.5-7z" />
                    <circle cx="12" cy="12" r="2.8" />
                  </svg>
                </button>
              </div>

              <div class="field">
                <input
                  id="reg-password-confirm"
                  v-model="regPasswordConfirm"
                  :type="showRegPassword ? 'text' : 'password'"
                  class="input-field"
                  placeholder="Confirmar contraseña"
                  autocomplete="new-password"
                  minlength="6"
                  aria-label="Confirmar contraseña"
                  required
                />
              </div>
            </div>

            <p v-if="registerError" class="error-text" role="alert">{{ registerError }}</p>
            <p v-if="registerNotice" class="notice-text" role="status">{{ registerNotice }}</p>

            <div class="modal-actions">
              <button type="button" class="button2" :disabled="registerLoading" @click="closeRegister">Cancelar</button>
              <button type="submit" class="button1" :disabled="registerLoading">
                <span v-if="registerLoading" class="btn-spinner" aria-hidden="true" />
                {{ registerLoading ? 'Guardando...' : 'Completar Registro' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>
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

const loginEmail = ref('')
const loginPassword = ref('')
const error = ref('')
const notice = ref('')
const loading = ref(false)
const showPassword = ref(false)

const showForgot = ref(false)
const forgotEmail = ref('')
const forgotError = ref('')
const forgotNotice = ref('')
const forgotLoading = ref(false)

const showRegister = ref(false)
const regCedula = ref('')
const regNombre = ref('')
const regEmail = ref('')
const regTelefono = ref('')
const regCalle = ref('')
const regPersonas = ref('')
const regDireccion = ref('')
const regPassword = ref('')
const regPasswordConfirm = ref('')
const registerError = ref('')
const registerNotice = ref('')
const registerLoading = ref(false)
const showRegPassword = ref(false)
const listaCalles = ref([])

const cargoMap = { 1: 'admin', 2: 'jefe', 3: 'familia' }

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

function openForgot() {
  forgotEmail.value = loginEmail.value.trim()
  forgotError.value = ''
  forgotNotice.value = ''
  showForgot.value = true
}

function closeForgot() {
  if (forgotLoading.value) return
  showForgot.value = false
}

function openRegister() {
  registerError.value = ''
  registerNotice.value = ''
  showRegister.value = true
}

function closeRegister() {
  if (registerLoading.value) return
  showRegister.value = false
}

function limpiarFormularioRegistro() {
  regCedula.value = ''
  regNombre.value = ''
  regEmail.value = ''
  regTelefono.value = ''
  regCalle.value = ''
  regPersonas.value = ''
  regDireccion.value = ''
  regPassword.value = ''
  regPasswordConfirm.value = ''
  showRegPassword.value = false
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
  registerError.value = ''
  registerNotice.value = ''

  const cedula = Number(regCedula.value)
  const email = regEmail.value.trim()
  const nombre = regNombre.value.trim()

  if (!Number.isInteger(cedula) || cedula <= 0) {
    registerError.value = 'Ingresa una cédula válida.'
    return
  }
  if (!nombre) {
    registerError.value = 'Ingresa tu nombre y apellido.'
    return
  }
  if (!email) {
    registerError.value = 'Ingresa tu correo electrónico.'
    return
  }
  if (!regCalle.value) {
    registerError.value = 'Selecciona tu calle o sector.'
    return
  }
  if (regPassword.value.length < 6) {
    registerError.value = 'La contraseña debe tener al menos 6 caracteres.'
    return
  }
  if (regPassword.value !== regPasswordConfirm.value) {
    registerError.value = 'Las contraseñas no coinciden.'
    return
  }

  registerLoading.value = true

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
      p_telefono: regTelefono.value.trim() || null,
      p_direccion: regDireccion.value.trim() || null,
      p_personas: regPersonas.value ? Number(regPersonas.value) : null,
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
    registerNotice.value = notificado
      ? 'Registro enviado. Quedó en estado PENDIENTE y el Jefe de Calle de tu zona recibió una notificación.'
      : 'Registro enviado. Quedó en estado PENDIENTE. Aún no hay un Jefe de Calle asignado a tu zona; el administrador lo revisará.'

    notice.value = registerNotice.value
    loginEmail.value = email
    loginPassword.value = ''
    limpiarFormularioRegistro()

    window.setTimeout(() => {
      if (!registerLoading.value) showRegister.value = false
    }, 1800)
  } catch (err) {
    console.error('[SIGAS] Error de registro:', err)
    registerError.value = mensajeDeError(
      err,
      'No se pudo completar el registro. Intenta nuevamente.'
    )
  } finally {
    registerLoading.value = false
  }
}
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700&display=swap');

.login-page {
  --primary-blue: #0ea5e9;
  --accent-cyan: #38bdf8;
  --card-bg: rgba(9, 17, 31, 0.9);
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  width: 100%;
  min-height: 100vh;
  min-height: 100dvh;
  margin: 0;
  padding: calc(1rem + env(safe-area-inset-top, 0px)) 1rem calc(1rem + env(safe-area-inset-bottom, 0px));
  overflow-x: hidden;
  background:
    radial-gradient(circle at 12% 8%, rgba(56, 189, 248, 0.12), transparent 34%),
    radial-gradient(circle at 88% 92%, rgba(20, 184, 166, 0.09), transparent 40%),
    linear-gradient(145deg, #0b1220 0%, #0d1b2e 48%, #08111f 100%);
  color: #f8fafc;
  font-family: 'Poppins', system-ui, -apple-system, sans-serif;
  box-sizing: border-box;
}

.login-bg {
  position: absolute;
  inset: 0;
  overflow: hidden;
  pointer-events: none;
}

.bg-glow {
  position: absolute;
  border-radius: 50%;
  filter: blur(90px);
  opacity: 0.55;
  pointer-events: none;
}

.bg-glow--one {
  top: -180px;
  left: -140px;
  width: 520px;
  height: 520px;
  background: rgba(14, 165, 233, 0.22);
}

.bg-glow--two {
  right: -220px;
  bottom: -260px;
  width: 620px;
  height: 620px;
  background: rgba(20, 184, 166, 0.14);
}

.bg-grid {
  position: absolute;
  inset: 0;
  opacity: 0.1;
  pointer-events: none;
  background-image:
    linear-gradient(rgba(148, 163, 184, 0.2) 1px, transparent 1px),
    linear-gradient(90deg, rgba(148, 163, 184, 0.2) 1px, transparent 1px);
  background-size: 64px 64px;
  mask-image: radial-gradient(circle at center, #000 8%, transparent 72%);
  -webkit-mask-image: radial-gradient(circle at center, #000 8%, transparent 72%);
}

.card {
  position: relative;
  z-index: 1;
  width: min(100%, 430px);
  padding: 1px;
  border-radius: 28px;
  background: linear-gradient(135deg, rgba(56, 189, 248, 0.5), rgba(14, 165, 233, 0.16) 48%, rgba(251, 146, 60, 0.22));
  box-shadow:
    0 30px 80px rgba(2, 6, 23, 0.58),
    0 0 0 1px rgba(255, 255, 255, 0.03);
  transition: transform 0.35s ease, box-shadow 0.35s ease;
}

.card:hover {
  transform: translateY(-3px);
  box-shadow:
    0 36px 90px rgba(2, 6, 23, 0.62),
    0 0 0 1px rgba(255, 255, 255, 0.05);
}

.form {
  display: flex;
  flex-direction: column;
  gap: 14px;
  width: 100%;
  padding: 2.2em 1.6em 1.8em;
  border: 1px solid rgba(148, 163, 184, 0.12);
  border-radius: 27px;
  background: linear-gradient(160deg, rgba(15, 23, 42, 0.94), rgba(8, 17, 31, 0.97));
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.05);
  backdrop-filter: blur(18px);
  -webkit-backdrop-filter: blur(18px);
  box-sizing: border-box;
}

.logo-container {
  display: flex;
  justify-content: center;
  margin-bottom: 0.25em;
}

.brand-logo {
  width: 110px;
  height: 110px;
  border-radius: 50%;
  object-fit: cover;
  background-color: #1e3a5f;
  border: 2px solid rgba(148, 163, 184, 0.22);
  box-shadow: 0 14px 34px rgba(2, 6, 23, 0.55);
  transition: transform 0.3s ease;
}

.brand-logo:hover {
  transform: scale(1.04);
}

.heading-wrap {
  text-align: center;
}

.eyebrow {
  margin: 0 0 6px;
  color: #7dd3fc;
  font-size: 0.66rem;
  font-weight: 600;
  letter-spacing: 0.14em;
  text-transform: uppercase;
}

#heading {
  margin: 0;
  color: #ffffff;
  font-size: 1.6rem;
  font-weight: 600;
  letter-spacing: 0.01em;
}

.subtitle {
  margin: 8px 0 0;
  color: rgba(203, 213, 225, 0.62);
  font-size: 0.8rem;
  line-height: 1.5;
}

.field {
  display: flex;
  align-items: center;
  gap: 0.75em;
  min-height: 52px;
  padding: 0.75em 1em;
  border: 1px solid rgba(148, 163, 184, 0.16);
  border-radius: 13px;
  background: rgba(255, 255, 255, 0.045);
  transition: border-color 0.25s ease, background-color 0.25s ease, box-shadow 0.25s ease;
}

.field:focus-within {
  border-color: rgba(56, 189, 248, 0.65);
  background: rgba(255, 255, 255, 0.07);
  box-shadow: 0 0 0 4px rgba(14, 165, 233, 0.12);
}

.input-icon {
  flex-shrink: 0;
  width: 1.15em;
  height: 1.15em;
  color: rgba(186, 230, 253, 0.7);
}

.input-field,
.select-field {
  width: 100%;
  min-width: 0;
  min-height: 30px;
  border: 0;
  outline: 0;
  background: transparent;
  color: #f8fafc;
  font-family: 'Poppins', system-ui, sans-serif;
  font-size: 16px;
}

.input-field::placeholder {
  color: rgba(203, 213, 225, 0.5);
}

.select-field {
  cursor: pointer;
  appearance: none;
  -webkit-appearance: none;
  padding-right: 24px;
  background-image:
    linear-gradient(45deg, transparent 50%, rgba(186, 230, 253, 0.75) 50%),
    linear-gradient(135deg, rgba(186, 230, 253, 0.75) 50%, transparent 50%);
  background-position:
    calc(100% - 14px) 13px,
    calc(100% - 9px) 13px;
  background-size: 5px 5px, 5px 5px;
  background-repeat: no-repeat;
}

.select-field option {
  background-color: #0f1b2d;
  color: #f8fafc;
}

.password-toggle {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 34px;
  height: 34px;
  padding: 0;
  border: 0;
  border-radius: 9px;
  background: transparent;
  color: rgba(186, 230, 253, 0.65);
  cursor: pointer;
  transition: background-color 0.2s ease, color 0.2s ease;
}

.password-toggle:hover {
  background: rgba(255, 255, 255, 0.08);
  color: #ffffff;
}

.password-toggle svg {
  width: 18px;
  height: 18px;
}

.error-text,
.notice-text {
  margin: 0;
  padding: 10px 12px;
  border-radius: 10px;
  font-size: 0.8rem;
  line-height: 1.45;
  text-align: center;
}

.error-text {
  border: 1px solid rgba(248, 113, 113, 0.32);
  background: rgba(127, 29, 29, 0.26);
  color: #fecaca;
}

.notice-text {
  border: 1px solid rgba(52, 211, 153, 0.3);
  background: rgba(6, 78, 59, 0.26);
  color: #bbf7d0;
}

.btn-group {
  display: flex;
  flex-direction: column;
  gap: 10px;
  margin-top: 0.5em;
}

.btn-group .button1,
.btn-group .button2 {
  flex: 1;
}

.button1,
.button2 {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  min-height: 48px;
  padding: 0.8em 1em;
  border-radius: 12px;
  font-family: 'Poppins', system-ui, sans-serif;
  font-size: 0.92rem;
  font-weight: 600;
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease, background-color 0.2s ease, border-color 0.2s ease;
}

.button1 {
  border: 0;
  background: linear-gradient(135deg, #0ea5e9 0%, #2563eb 100%);
  color: #ffffff;
  box-shadow: 0 12px 26px rgba(2, 132, 199, 0.28);
}

.button1:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 16px 32px rgba(2, 132, 199, 0.38);
}

.button1:active:not(:disabled) {
  transform: translateY(0) scale(0.99);
}

.button1:disabled {
  opacity: 0.62;
  cursor: wait;
}

.button2 {
  border: 1px solid rgba(148, 163, 184, 0.22);
  background: rgba(255, 255, 255, 0.04);
  color: rgba(226, 232, 240, 0.82);
}

.button2:hover:not(:disabled) {
  border-color: rgba(56, 189, 248, 0.45);
  background: rgba(255, 255, 255, 0.08);
  color: #ffffff;
  transform: translateY(-1px);
}

.button2:disabled {
  opacity: 0.55;
  cursor: wait;
}

.button3 {
  align-self: center;
  min-height: 40px;
  margin-top: 0.15em;
  padding: 6px;
  border: 0;
  background: transparent;
  color: rgba(186, 230, 253, 0.65);
  font-family: 'Poppins', system-ui, sans-serif;
  font-size: 0.82rem;
  cursor: pointer;
  transition: color 0.2s ease;
}

.button3:hover {
  color: #ffffff;
  text-decoration: underline;
}

.footnote {
  margin: 0.15em 0 0;
  color: rgba(148, 163, 184, 0.45);
  font-size: 0.68rem;
  line-height: 1.5;
  text-align: center;
}

.btn-spinner {
  width: 16px;
  height: 16px;
  border: 2px solid rgba(255, 255, 255, 0.35);
  border-top-color: #ffffff;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* ==========================================================================
   MODALES
   ========================================================================== */
.modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 1000;
  display: flex;
  align-items: flex-end;
  justify-content: center;
  background: rgba(2, 6, 23, 0.72);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
  animation: fadeIn 0.18s ease-out;
}

.modal-card {
  position: relative;
  width: 100%;
  max-height: 92dvh;
  margin: 0;
  padding: 12px 16px calc(18px + env(safe-area-inset-bottom, 0px));
  overflow-y: auto;
  -webkit-overflow-scrolling: touch;
  border: 1px solid rgba(56, 189, 248, 0.2);
  border-radius: 24px 24px 0 0;
  background: linear-gradient(160deg, #0f1b2d 0%, #0a1424 100%);
  box-shadow: 0 -24px 70px rgba(2, 6, 23, 0.6);
  box-sizing: border-box;
  animation: sheetUp 0.24s cubic-bezier(0.2, 0.9, 0.3, 1);
}

.modal-card--wide {
  max-width: 640px;
}

.modal-sheet-handle {
  display: block;
  width: 40px;
  height: 4px;
  margin: 0 auto 14px;
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.22);
}

.modal-close {
  position: absolute;
  top: 14px;
  right: 14px;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 36px;
  height: 36px;
  padding: 0;
  border: 1px solid rgba(148, 163, 184, 0.18);
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.04);
  color: rgba(226, 232, 240, 0.75);
  font-size: 1.3rem;
  line-height: 1;
  cursor: pointer;
  transition: background-color 0.2s ease, color 0.2s ease;
}

.modal-close:hover {
  background: rgba(255, 255, 255, 0.1);
  color: #ffffff;
}

.modal-card h3 {
  margin: 0;
  padding-right: 42px;
  color: #ffffff;
  font-size: 1.15rem;
  font-weight: 600;
  text-align: left;
}

.modal-hint {
  margin: 8px 0 0;
  color: rgba(203, 213, 225, 0.65);
  font-size: 0.82rem;
  line-height: 1.55;
}

.modal-hint strong {
  color: #fbbf24;
  font-weight: 600;
}

.modal-form {
  display: flex;
  flex-direction: column;
  gap: 12px;
  margin-top: 18px;
}

.form-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  gap: 12px;
}

.modal-actions {
  display: flex;
  flex-direction: column-reverse;
  gap: 10px;
  margin-top: 6px;
}

.modal-actions .button1,
.modal-actions .button2 {
  width: 100%;
}

@keyframes fadeIn {
  from { opacity: 0; }
  to { opacity: 1; }
}

@keyframes sheetUp {
  from { transform: translateY(18px); opacity: 0; }
  to { transform: translateY(0); opacity: 1; }
}

@keyframes scaleIn {
  from { transform: scale(0.96); opacity: 0; }
  to { transform: scale(1); opacity: 1; }
}

/* ==========================================================================
   RESPONSIVE · mobile-first
   ========================================================================== */
@media (min-width: 480px) {
  .form-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (min-width: 640px) {
  .login-page {
    padding: 1.5rem;
  }

  .form {
    padding: 2.2em 1.8em 2em;
  }

  .brand-logo {
    width: 120px;
    height: 120px;
  }

  #heading {
    font-size: 1.7rem;
  }

  .btn-group {
    flex-direction: row;
    gap: 12px;
  }

  .modal-overlay {
    align-items: center;
    padding: 1rem;
  }

  .modal-card {
    max-width: 460px;
    max-height: 88vh;
    padding: 26px 24px;
    border-radius: 22px;
    animation: scaleIn 0.2s ease-out;
  }

  .modal-card--wide {
    max-width: 640px;
  }

  .modal-sheet-handle {
    display: none;
  }

  .modal-actions {
    flex-direction: row;
    justify-content: flex-end;
  }

  .modal-actions .button1,
  .modal-actions .button2 {
    width: auto;
    min-width: 130px;
  }
}

@media (min-width: 1024px) {
  .input-field,
  .select-field {
    font-size: 15px;
  }
}

@media (prefers-reduced-motion: reduce) {
  .card,
  .brand-logo,
  .button1,
  .button2,
  .btn-spinner,
  .modal-overlay,
  .modal-card {
    animation: none;
    transition: none;
  }
}
</style>
