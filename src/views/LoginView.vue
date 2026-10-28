<template>
  <div class="login-page">
    <div class="login-bg" aria-hidden="true">
      <span class="orb orb--one" />
      <span class="orb orb--two" />
      <span class="orb orb--three" />
      <span class="grid-glow" />
    </div>

    <main class="login-shell">
      <section class="login-brand">
        <div class="brand-lockup">
          <span class="brand-logo">
            <img :src="logoImage" alt="SIGAS" />
          </span>
          <div>
            <p class="brand-name">SIGAS</p>
            <p class="brand-tagline">Sistema Integral de Gas</p>
          </div>
        </div>

        <div class="brand-copy">
          <span class="brand-eyebrow">Control comunitario inteligente</span>
          <h1>La energía de tu comunidad, organizada en un solo lugar.</h1>
          <p>
            Gestiona solicitudes, entregas, familias y jefes de calle con
            información segura y actualizada en tiempo real.
          </p>
        </div>

        <ul class="brand-features">
          <li><span class="feature-dot" aria-hidden="true" /> Seguimiento de solicitudes y entregas</li>
          <li><span class="feature-dot" aria-hidden="true" /> Aprobación de registros por zona</li>
          <li><span class="feature-dot" aria-hidden="true" /> Notificaciones en tiempo real</li>
        </ul>

        <p class="brand-footnote">
          <span class="status-pulse" aria-hidden="true" /> Plataforma segura · Supabase
        </p>
      </section>

      <section class="login-card" aria-labelledby="login-heading">
        <div class="card-glow" aria-hidden="true" />

        <div class="card-header">
          <span class="card-logo"><img :src="logoImage" alt="" aria-hidden="true" /></span>
          <p class="card-eyebrow">Bienvenido de nuevo</p>
          <h2 id="login-heading">Inicia sesión</h2>
          <p class="card-subtitle">Accede con tu correo y contraseña registrados.</p>
        </div>

        <form class="login-form" @submit.prevent="handleLogin" novalidate>
          <div class="field">
            <label for="login-email">Correo electrónico</label>
            <div class="field-control">
              <svg viewBox="0 0 24 24" class="field-icon" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16v12H4z" />
                <path stroke-linecap="round" stroke-linejoin="round" d="m4 7 8 6 8-6" />
              </svg>
              <input id="login-email" v-model="loginEmail" type="email" autocomplete="email" placeholder="tu@correo.com" required />
            </div>
          </div>

          <div class="field">
            <label for="login-password">Contraseña</label>
            <div class="field-control">
              <svg viewBox="0 0 24 24" class="field-icon" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                <rect x="4" y="10" width="16" height="10" rx="2" />
                <path stroke-linecap="round" d="M8 10V7a4 4 0 0 1 8 0v3" />
              </svg>
              <input id="login-password" v-model="loginPassword" :type="showPassword ? 'text' : 'password'" autocomplete="current-password" placeholder="Tu contraseña" required />
              <button type="button" class="password-toggle" :aria-label="showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'" @click="showPassword = !showPassword">
                <svg v-if="showPassword" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M3 3l18 18M10.6 10.6a2 2 0 0 0 2.8 2.8M9.9 5.2A10.4 10.4 0 0 1 12 5c5.5 0 9 7 9 7a17.6 17.6 0 0 1-3.2 4.1M6.2 6.2C4.1 7.8 3 10 3 12c0 0 3.5 7 9 7 1.1 0 2.1-.3 3-.7" />
                </svg>
                <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M2.5 12S6 5 12 5s9.5 7 9.5 7-3.5 7-9.5 7-9.5-7-9.5-7z" />
                  <circle cx="12" cy="12" r="2.8" />
                </svg>
              </button>
            </div>
          </div>

          <div v-if="error" class="alert alert--error" role="alert">
            <span aria-hidden="true">!</span>
            <p>{{ error }}</p>
          </div>

          <div v-if="notice" class="alert alert--success" role="status">
            <span aria-hidden="true">✓</span>
            <p>{{ notice }}</p>
          </div>

          <button type="submit" class="btn-primary" :disabled="loading">
            <span v-if="loading" class="btn-spinner" aria-hidden="true" />
            {{ loading ? 'Verificando acceso…' : 'Ingresar al sistema' }}
          </button>

          <div class="form-links">
            <button type="button" class="link-button" @click="openForgot">¿Olvidaste tu contraseña?</button>
            <span class="link-separator" aria-hidden="true">·</span>
            <button type="button" class="link-button link-button--accent" @click="openRegister">Crear cuenta</button>
          </div>
        </form>

        <p class="card-footnote">Al ingresar aceptas las políticas de uso y privacidad de SIGAS.</p>
      </section>
    </main>

    <!-- Modal recuperar contraseña -->
    <Teleport to="body">
      <div v-if="showForgot" class="modal-overlay" @click.self="closeForgot">
        <div class="modal-card" role="dialog" aria-modal="true" aria-labelledby="forgot-title">
          <button type="button" class="modal-close" aria-label="Cerrar" @click="closeForgot">×</button>
          <div class="modal-icon modal-icon--blue" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
              <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16v12H4z" />
              <path stroke-linecap="round" stroke-linejoin="round" d="m4 7 8 6 8-6" />
            </svg>
          </div>
          <h3 id="forgot-title">Recuperar contraseña</h3>
          <p class="modal-subtitle">Escribe el correo de tu cuenta. Te enviaremos un enlace seguro para crear una nueva contraseña.</p>

          <form class="modal-form" @submit.prevent="handleForgotPassword">
            <div class="field">
              <label for="forgot-email">Correo electrónico</label>
              <div class="field-control">
                <svg viewBox="0 0 24 24" class="field-icon" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M4 6h16v12H4z" />
                  <path stroke-linecap="round" stroke-linejoin="round" d="m4 7 8 6 8-6" />
                </svg>
                <input id="forgot-email" v-model="forgotEmail" type="email" autocomplete="email" placeholder="tu@correo.com" required />
              </div>
            </div>

            <p v-if="forgotError" class="modal-error" role="alert">{{ forgotError }}</p>
            <p v-if="forgotNotice" class="modal-success" role="status">{{ forgotNotice }}</p>

            <div class="modal-actions">
              <button type="button" class="btn-ghost" :disabled="forgotLoading" @click="closeForgot">Cancelar</button>
              <button type="submit" class="btn-primary btn-primary--compact" :disabled="forgotLoading">
                <span v-if="forgotLoading" class="btn-spinner" aria-hidden="true" />
                {{ forgotLoading ? 'Enviando…' : 'Enviar enlace' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>

    <!-- Modal registro de familia -->
    <Teleport to="body">
      <div v-if="showRegister" class="modal-overlay" @click.self="closeRegister">
        <div class="modal-card modal-card--wide" role="dialog" aria-modal="true" aria-labelledby="register-title">
          <button type="button" class="modal-close" aria-label="Cerrar" @click="closeRegister">×</button>
          <div class="modal-icon modal-icon--green" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
              <path stroke-linecap="round" stroke-linejoin="round" d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
              <circle cx="9" cy="7" r="4" />
              <path stroke-linecap="round" stroke-linejoin="round" d="M19 8v6m3-3h-6" />
            </svg>
          </div>
          <h3 id="register-title">Registro de familia</h3>
          <p class="modal-subtitle">Completa tus datos. El registro quedará en estado <strong>PENDIENTE</strong> hasta que el Jefe de Calle de tu zona lo revise y apruebe.</p>

          <form class="modal-form register-form" @submit.prevent="handleRegister" novalidate>
            <div class="form-grid">
              <div class="field">
                <label for="reg-cedula">Cédula</label>
                <div class="field-control">
                  <input id="reg-cedula" v-model="regCedula" type="number" inputmode="numeric" min="1" placeholder="V-12345678" required />
                </div>
              </div>

              <div class="field">
                <label for="reg-nombre">Nombre y apellido</label>
                <div class="field-control">
                  <input id="reg-nombre" v-model="regNombre" type="text" autocomplete="name" placeholder="Nombre completo" required />
                </div>
              </div>

              <div class="field">
                <label for="reg-email">Correo electrónico</label>
                <div class="field-control">
                  <input id="reg-email" v-model="regEmail" type="email" autocomplete="email" placeholder="tu@correo.com" required />
                </div>
              </div>

              <div class="field">
                <label for="reg-telefono">Teléfono</label>
                <div class="field-control">
                  <input id="reg-telefono" v-model="regTelefono" type="tel" autocomplete="tel" placeholder="0414-1234567" />
                </div>
              </div>

              <div class="field">
                <label for="reg-calle">Calle / sector</label>
                <div class="field-control">
                  <select id="reg-calle" v-model="regCalle" required>
                    <option value="" disabled>Selecciona tu calle</option>
                    <option v-for="calle in listaCalles" :key="calle.id_calle" :value="calle.id_calle">{{ calle.nombre }}</option>
                  </select>
                </div>
              </div>

              <div class="field">
                <label for="reg-personas">Personas en el hogar</label>
                <div class="field-control">
                  <input id="reg-personas" v-model="regPersonas" type="number" inputmode="numeric" min="1" placeholder="4" />
                </div>
              </div>
            </div>

            <div class="field">
              <label for="reg-direccion">Dirección de la vivienda</label>
              <div class="field-control">
                <input id="reg-direccion" v-model="regDireccion" type="text" autocomplete="street-address" placeholder="Casa #12, referencia…" />
              </div>
            </div>

            <div class="form-grid">
              <div class="field">
                <label for="reg-password">Contraseña</label>
                <div class="field-control">
                  <input id="reg-password" v-model="regPassword" :type="showRegPassword ? 'text' : 'password'" autocomplete="new-password" minlength="6" placeholder="Mínimo 6 caracteres" required />
                  <button type="button" class="password-toggle" :aria-label="showRegPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'" @click="showRegPassword = !showRegPassword">
                    <svg v-if="showRegPassword" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M3 3l18 18M10.6 10.6a2 2 0 0 0 2.8 2.8M9.9 5.2A10.4 10.4 0 0 1 12 5c5.5 0 9 7 9 7a17.6 17.6 0 0 1-3.2 4.1M6.2 6.2C4.1 7.8 3 10 3 12c0 0 3.5 7 9 7 1.1 0 2.1-.3 3-.7" />
                    </svg>
                    <svg v-else viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" aria-hidden="true">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M2.5 12S6 5 12 5s9.5 7 9.5 7-3.5 7-9.5 7-9.5-7-9.5-7z" />
                      <circle cx="12" cy="12" r="2.8" />
                    </svg>
                  </button>
                </div>
              </div>

              <div class="field">
                <label for="reg-password-confirm">Confirmar contraseña</label>
                <div class="field-control">
                  <input id="reg-password-confirm" v-model="regPasswordConfirm" :type="showRegPassword ? 'text' : 'password'" autocomplete="new-password" minlength="6" placeholder="Repite la contraseña" required />
                </div>
              </div>
            </div>

            <p v-if="registerError" class="modal-error" role="alert">{{ registerError }}</p>
            <p v-if="registerNotice" class="modal-success" role="status">{{ registerNotice }}</p>

            <div class="modal-actions">
              <button type="button" class="btn-ghost" :disabled="registerLoading" @click="closeRegister">Cancelar</button>
              <button type="submit" class="btn-primary btn-primary--compact" :disabled="registerLoading">
                <span v-if="registerLoading" class="btn-spinner" aria-hidden="true" />
                {{ registerLoading ? 'Enviando registro…' : 'Enviar registro' }}
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
    let { data, error: queryError } = await supabase.from('calles').select('id_calle, nombre').eq('activo', true).eq('is_deleted', false).order('nombre')
    if (queryError && /is_deleted/i.test(queryError.message || '')) {
      const fallback = await supabase.from('calles').select('id_calle, nombre').eq('activo', true).order('nombre')
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
  if (/already registered|already exists|user already/i.test(mensaje)) return 'Este correo electrónico ya está registrado. Inicia sesión o recupera tu contraseña.'
  if (/invalid login credentials/i.test(mensaje)) return 'Correo o contraseña incorrectos.'
  if (/email not confirmed/i.test(mensaje)) return 'Debes confirmar tu correo electrónico antes de iniciar sesión.'
  if (/registro de familia asociado/i.test(mensaje)) return 'Esta cuenta ya tiene un registro de familia. Inicia sesión o contacta al Jefe de Calle.'
  if (/duplicate key|ya existe|cedula|cédula/i.test(mensaje)) return 'Ya existe un registro con esa cédula. Si es tuyo, contacta al Jefe de Calle.'
  if (/password/i.test(mensaje) && /least|short|6/i.test(mensaje)) return 'La contraseña debe tener al menos 6 caracteres.'
  return mensaje || fallback
}

async function handleLogin() {
  error.value = ''
  notice.value = ''
  loading.value = true

  try {
    const email = loginEmail.value.trim()
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({ email, password: loginPassword.value })
    if (authError) throw authError

    const { data: perfil, error: perfilError } = await supabase.from('familias').select('*').eq('auth_id', authData.user.id).order('id', { ascending: true }).limit(1).maybeSingle()
    if (perfilError) console.warn('[SIGAS] No se pudo leer el perfil de familias:', perfilError)

    let perfilFinal = perfil
    if (!perfilFinal) {
      const { data: jefe } = await supabase.from('jefe_de_calle').select('*').eq('auth_id', authData.user.id).eq('activo', true).eq('is_deleted', false).limit(1).maybeSingle()
      if (jefe) {
        perfilFinal = { id: jefe.id_jefe_calle, auth_id: jefe.auth_id, nombre_familia: jefe.nombre, id_calle: jefe.id_calle, id_cargo: 2, activo: jefe.activo, estado: 'aprobado', is_deleted: jefe.is_deleted }
      }
    }

    if (!perfilFinal) throw new Error('Tu cuenta no tiene un perfil asociado. Contacta al administrador.')
    if (perfilFinal.is_deleted) throw new Error('Esta cuenta fue dada de baja. Contacta al administrador.')

    const esFamilia = Number(perfilFinal.id_cargo) === 3
    const estado = String(perfilFinal.estado || 'aprobado').toLowerCase()

    if (esFamilia && estado === 'pendiente') throw new Error('Tu registro está PENDIENTE de aprobación por el Jefe de Calle de tu zona. Te avisaremos cuando sea aprobado.')
    if (esFamilia && estado === 'rechazado') throw new Error(`Tu registro fue rechazado.${perfilFinal.notas_rechazo ? ' Motivo: ' + perfilFinal.notas_rechazo : ''}`)
    if (perfilFinal.activo === false) throw new Error('Tu cuenta está inactiva. Contacta al administrador.')

    const rol = cargoMap[Number(perfilFinal.id_cargo)] || 'familia'

    setSession({ id: perfilFinal.id, authId: authData.user.id, email: authData.user.email, nombre: perfilFinal.nombre_familia || authData.user.email, rol, idCalle: perfilFinal.id_calle || null, estado })

    const rutas = { admin: '/admin/dashboard', jefe: '/jefe/dashboard', familia: '/familia/dashboard' }
    await router.push(rutas[rol] || '/familia/dashboard')
  } catch (err) {
    console.error('[SIGAS] Error de login:', err)
    error.value = mensajeDeError(err, 'No se pudo iniciar sesión. Intenta nuevamente.')
    if (!/incorrectos|confirmar tu correo/i.test(error.value)) await supabase.auth.signOut().catch(() => {})
  } finally {
    loading.value = false
  }
}

async function handleForgotPassword() {
  forgotError.value = ''
  forgotNotice.value = ''
  const email = forgotEmail.value.trim()
  if (!email) { forgotError.value = 'Escribe tu correo electrónico.'; return }

  forgotLoading.value = true
  try {
    const { error: resetError } = await supabase.auth.resetPasswordForEmail(email, { redirectTo: PASSWORD_RESET_REDIRECT })
    if (resetError) throw resetError
    forgotNotice.value = 'Si el correo está registrado, recibirás un enlace para restablecer tu contraseña. Revisa también la carpeta de spam.'
    notice.value = forgotNotice.value
  } catch (err) {
    console.error('[SIGAS] Error enviando recuperación:', err)
    forgotError.value = mensajeDeError(err, 'No se pudo enviar el enlace de recuperación. Intenta nuevamente.')
  } finally {
    forgotLoading.value = false
  }
}

async function insertarRegistroDirecto(authUserId, payload) {
  const { error: insertError } = await supabase.from('familias').insert([{
    id: payload.p_id, auth_id: authUserId, nombre_familia: payload.p_nombre, id_calle: payload.p_id_calle,
    id_cargo: 3, activo: false, estado: 'pendiente', telefono: payload.p_telefono,
    direccion: payload.p_direccion, num_personas: payload.p_personas, email: payload.p_email, is_deleted: false,
  }])
  if (insertError) throw insertError

  const { data: jefe } = await supabase.from('jefe_de_calle').select('*').eq('id_calle', payload.p_id_calle).eq('activo', true).eq('is_deleted', false).limit(1)
  const jefeZona = jefe?.[0]
  if (jefeZona?.auth_id) {
    const { error: notifError } = await supabase.from('notificaciones').insert([{
      destinatario_auth_id: jefeZona.auth_id, id_jefe_calle: jefeZona.id_jefe_calle, id_familia: payload.p_id,
      tipo: 'registro_familia', titulo: 'Nuevo registro pendiente',
      mensaje: `La familia ${payload.p_nombre} (cédula ${payload.p_id}) solicitó registro en tu calle.`,
      metadata: { id_familia: payload.p_id, id_calle: payload.p_id_calle, email: payload.p_email },
    }])
    if (notifError) console.warn('[SIGAS] No se pudo insertar la notificación:', notifError)
  }
  return { notificado: Boolean(jefeZona?.auth_id) }
}

async function handleRegister() {
  registerError.value = ''
  registerNotice.value = ''

  const cedula = Number(regCedula.value)
  const email = regEmail.value.trim()
  const nombre = regNombre.value.trim()

  if (!Number.isInteger(cedula) || cedula <= 0) { registerError.value = 'Ingresa una cédula válida.'; return }
  if (!nombre) { registerError.value = 'Ingresa tu nombre y apellido.'; return }
  if (!email) { registerError.value = 'Ingresa tu correo electrónico.'; return }
  if (!regCalle.value) { registerError.value = 'Selecciona tu calle o sector.'; return }
  if (regPassword.value.length < 6) { registerError.value = 'La contraseña debe tener al menos 6 caracteres.'; return }
  if (regPassword.value !== regPasswordConfirm.value) { registerError.value = 'Las contraseñas no coinciden.'; return }

  registerLoading.value = true
  try {
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email, password: regPassword.value, options: { data: { nombre, cedula } }
    })
    if (authError) throw authError
    if (authData?.user?.identities && authData.user.identities.length === 0) throw new Error('Este correo electrónico ya se encuentra registrado en el sistema.')
    if (!authData?.user?.id) throw new Error('No se pudo crear la cuenta. Intenta nuevamente.')

    const payload = {
      p_id: cedula, p_auth_id: authData.user.id, p_nombre: nombre, p_id_calle: Number(regCalle.value),
      p_telefono: regTelefono.value.trim() || null, p_direccion: regDireccion.value.trim() || null,
      p_personas: regPersonas.value ? Number(regPersonas.value) : null, p_email: email,
    }

    let resultado = null
    const { data: rpcData, error: rpcError } = await supabase.rpc('registrar_familia_pendiente', payload)

    if (rpcError) {
      const noExisteRpc = rpcError.code === 'PGRST202' || /could not find the function|function .* does not exist/i.test(rpcError.message || '')
      if (noExisteRpc) { resultado = await insertarRegistroDirecto(authData.user.id, payload) }
      else { throw rpcError }
    } else { resultado = rpcData }

    if (authData.session) await supabase.auth.signOut().catch(() => {})

    const notificado = resultado?.notificado !== false
    registerNotice.value = notificado
      ? 'Registro enviado. Quedó en estado PENDIENTE y el Jefe de Calle de tu zona recibió una notificación.'
      : 'Registro enviado. Quedó en estado PENDIENTE. Aún no hay un Jefe de Calle asignado a tu zona; el administrador lo revisará.'

    notice.value = registerNotice.value
    loginEmail.value = email
    loginPassword.value = ''
    limpiarFormularioRegistro()

    window.setTimeout(() => { if (!registerLoading.value) showRegister.value = false }, 1800)
  } catch (err) {
    console.error('[SIGAS] Error de registro:', err)
    registerError.value = mensajeDeError(err, 'No se pudo completar el registro. Intenta nuevamente.')
  } finally {
    registerLoading.value = false
  }
}
</script>

<style scoped>
.login-page {
  --login-blue-950: #020617;
  --login-blue-900: #082f49;
  --login-blue-700: #0369a1;
  --login-blue-500: #0ea5e9;
  --login-cyan: #22d3ee;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  min-height: 100dvh;
  padding: calc(18px + env(safe-area-inset-top, 0px)) 16px calc(18px + env(safe-area-inset-bottom, 0px));
  overflow: hidden;
  background: linear-gradient(-45deg, #020617 0%, #082f49 28%, #075985 52%, #0369a1 72%, #0c4a6e 100%);
  background-size: 400% 400%;
  animation: loginGradient 18s ease infinite;
  font-family: var(--font-sans, system-ui, -apple-system, sans-serif);
  color: #f8fafc;
}

@keyframes loginGradient {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}

.login-bg { position: absolute; inset: 0; overflow: hidden; pointer-events: none; }
.login-bg::before {
  content: ''; position: absolute; inset: 0;
  background: radial-gradient(circle at 18% 18%, rgba(34, 211, 238, 0.2), transparent 34%),
              radial-gradient(circle at 82% 76%, rgba(14, 165, 233, 0.24), transparent 38%),
              radial-gradient(circle at 70% 12%, rgba(59, 130, 246, 0.16), transparent 30%);
}
.login-bg::after {
  content: ''; position: absolute; inset: 0; opacity: 0.18;
  background-image: linear-gradient(rgba(255, 255, 255, 0.08) 1px, transparent 1px), linear-gradient(90deg, rgba(255, 255, 255, 0.08) 1px, transparent 1px);
  background-size: 72px 72px;
  mask-image: radial-gradient(circle at center, #000 20%, transparent 78%);
  -webkit-mask-image: radial-gradient(circle at center, #000 20%, transparent 78%);
}

.orb { position: absolute; display: block; border-radius: 999px; filter: blur(10px); opacity: 0.55; animation: orbFloat 16s ease-in-out infinite; }
.orb--one { top: -12%; left: -8%; width: 42vmax; height: 42vmax; background: radial-gradient(circle at 35% 35%, rgba(34, 211, 238, 0.5), rgba(2, 132, 199, 0.08) 62%, transparent 72%); }
.orb--two { right: -14%; bottom: -18%; width: 48vmax; height: 48vmax; background: radial-gradient(circle at 45% 45%, rgba(59, 130, 246, 0.46), rgba(29, 78, 216, 0.08) 60%, transparent 72%); animation-delay: -6s; }
.orb--three { top: 38%; left: 46%; width: 28vmax; height: 28vmax; background: radial-gradient(circle, rgba(125, 211, 252, 0.3), transparent 68%); animation-delay: -11s; }

@keyframes orbFloat {
  0%, 100% { transform: translate3d(0, 0, 0) scale(1); }
  33% { transform: translate3d(3%, -4%, 0) scale(1.06); }
  66% { transform: translate3d(-3%, 3%, 0) scale(0.96); }
}

.grid-glow { position: absolute; left: 50%; bottom: -35%; width: 80vmax; height: 60vmax; transform: translateX(-50%); background: radial-gradient(ellipse at center, rgba(14, 165, 233, 0.22), transparent 65%); }

.login-shell { position: relative; z-index: 1; display: grid; grid-template-columns: minmax(0, 1fr); width: min(100%, 1100px); gap: 28px; align-items: center; }
.login-brand { display: none; min-width: 0; padding: 20px 8px; }
.brand-lockup { display: flex; align-items: center; gap: 14px; }
.brand-logo { display: inline-flex; align-items: center; justify-content: center; width: 58px; height: 58px; overflow: hidden; border: 1px solid rgba(255, 255, 255, 0.28); border-radius: 18px; background: rgba(255, 255, 255, 0.1); box-shadow: 0 18px 40px rgba(2, 6, 23, 0.32); backdrop-filter: blur(12px); }
.brand-logo img { width: 100%; height: 100%; object-fit: cover; }
.brand-name { margin: 0; color: #ffffff; font-size: 1.55rem; font-weight: 800; letter-spacing: 0.06em; }
.brand-tagline { margin: 2px 0 0; color: rgba(224, 242, 254, 0.78); font-size: 0.78rem; letter-spacing: 0.04em; text-transform: uppercase; }
.brand-copy { max-width: 560px; margin-top: 46px; }
.brand-eyebrow { display: inline-flex; align-items: center; gap: 8px; padding: 7px 12px; border: 1px solid rgba(125, 211, 252, 0.28); border-radius: 999px; background: rgba(14, 165, 233, 0.14); color: #bae6fd; font-size: 0.72rem; font-weight: 700; letter-spacing: 0.08em; text-transform: uppercase; }
.brand-copy h1 { margin: 18px 0 0; color: #ffffff; font-size: clamp(2.15rem, 4.4vw, 3.35rem); font-weight: 800; line-height: 1.06; letter-spacing: -0.035em; text-wrap: balance; }
.brand-copy p { max-width: 480px; margin: 18px 0 0; color: rgba(224, 242, 254, 0.8); font-size: 1rem; line-height: 1.65; }
.brand-features { display: grid; gap: 12px; margin: 30px 0 0; padding: 0; list-style: none; }
.brand-features li { display: flex; align-items: center; gap: 10px; color: rgba(240, 249, 255, 0.88); font-size: 0.9rem; }
.feature-dot { display: inline-block; flex-shrink: 0; width: 7px; height: 7px; border-radius: 50%; background: #22d3ee; box-shadow: 0 0 0 4px rgba(34, 211, 238, 0.14); }
.brand-footnote { display: inline-flex; align-items: center; gap: 9px; margin: 36px 0 0; color: rgba(186, 230, 253, 0.68); font-size: 0.76rem; }
.status-pulse { position: relative; display: inline-block; width: 8px; height: 8px; border-radius: 50%; background: #34d399; }
.status-pulse::after { content: ''; position: absolute; inset: -4px; border: 1px solid rgba(52, 211, 153, 0.55); border-radius: 50%; animation: statusPulse 2.2s ease-out infinite; }
@keyframes statusPulse { 0% { transform: scale(0.8); opacity: 1; } 100% { transform: scale(1.9); opacity: 0; } }

.login-card { position: relative; width: 100%; max-width: 460px; margin-inline: auto; padding: 26px 22px 22px; overflow: hidden; border: 1px solid rgba(255, 255, 255, 0.18); border-radius: 26px; background: linear-gradient(145deg, rgba(255, 255, 255, 0.13), rgba(255, 255, 255, 0.05)); box-shadow: 0 30px 80px rgba(2, 6, 23, 0.48), inset 0 1px 0 rgba(255, 255, 255, 0.24); backdrop-filter: blur(26px) saturate(150%); -webkit-backdrop-filter: blur(26px) saturate(150%); }
.card-glow { position: absolute; top: -120px; right: -100px; width: 260px; height: 260px; border-radius: 50%; background: radial-gradient(circle, rgba(34, 211, 238, 0.3), transparent 68%); pointer-events: none; }
.card-header { position: relative; text-align: center; }
.card-logo { display: none; width: 64px; height: 64px; margin: 0 auto 14px; overflow: hidden; border: 1px solid rgba(255, 255, 255, 0.26); border-radius: 18px; background: rgba(255, 255, 255, 0.12); }
.card-logo img { width: 100%; height: 100%; object-fit: cover; }
.card-eyebrow { margin: 0; color: #7dd3fc; font-size: 0.7rem; font-weight: 800; letter-spacing: 0.12em; text-transform: uppercase; }
.card-header h2 { margin: 8px 0 0; color: #ffffff; font-size: 1.75rem; font-weight: 800; letter-spacing: -0.02em; }
.card-subtitle { margin: 8px auto 0; max-width: 320px; color: rgba(224, 242, 254, 0.72); font-size: 0.84rem; line-height: 1.5; }

.login-form { position: relative; display: grid; gap: 15px; margin-top: 24px; }
.field { display: grid; gap: 7px; }
.field > label { color: rgba(240, 249, 255, 0.88); font-size: 0.78rem; font-weight: 700; letter-spacing: 0.02em; }
.field-control { display: flex; align-items: center; gap: 9px; min-height: 48px; padding: 0 13px; border: 1px solid rgba(255, 255, 255, 0.17); border-radius: 13px; background: rgba(2, 6, 23, 0.22); transition: border-color 160ms ease, background-color 160ms ease, box-shadow 160ms ease; }
.field-control:focus-within { border-color: rgba(125, 211, 252, 0.78); background: rgba(2, 6, 23, 0.32); box-shadow: 0 0 0 4px rgba(14, 165, 233, 0.16); }
.field-icon { flex-shrink: 0; width: 18px; height: 18px; color: rgba(186, 230, 253, 0.75); }
.field-control input, .field-control select { width: 100%; min-width: 0; height: 46px; padding: 0; border: 0; outline: 0; background: transparent; color: #f8fafc; font: inherit; font-size: 0.9rem; }
.field-control input::placeholder { color: rgba(186, 230, 253, 0.45); }
.field-control select { cursor: pointer; appearance: none; -webkit-appearance: none; background-image: linear-gradient(45deg, transparent 50%, rgba(186, 230, 253, 0.8) 50%), linear-gradient(135deg, rgba(186, 230, 253, 0.8) 50%, transparent 50%); background-position: calc(100% - 15px) 20px, calc(100% - 10px) 20px; background-size: 5px 5px, 5px 5px; background-repeat: no-repeat; padding-right: 26px; }
.field-control select option { background: #082f49; color: #f8fafc; }

.password-toggle { display: inline-flex; align-items: center; justify-content: center; flex-shrink: 0; width: 34px; height: 34px; padding: 0; border: 0; border-radius: 9px; background: transparent; color: rgba(186, 230, 253, 0.7); cursor: pointer; }
.password-toggle:hover { background: rgba(255, 255, 255, 0.08); color: #ffffff; }
.password-toggle svg { width: 18px; height: 18px; }

.alert { display: flex; align-items: flex-start; gap: 9px; padding: 10px 12px; border: 1px solid transparent; border-radius: 11px; font-size: 0.82rem; line-height: 1.45; }
.alert p { margin: 0; }
.alert > span { display: inline-flex; align-items: center; justify-content: center; flex-shrink: 0; width: 18px; height: 18px; border-radius: 50%; font-size: 0.68rem; font-weight: 800; }
.alert--error { border-color: rgba(248, 113, 113, 0.38); background: rgba(127, 29, 29, 0.32); color: #fecaca; }
.alert--error > span { background: rgba(248, 113, 113, 0.22); color: #fecaca; }
.alert--success { border-color: rgba(52, 211, 153, 0.36); background: rgba(6, 78, 59, 0.32); color: #bbf7d0; }
.alert--success > span { background: rgba(52, 211, 153, 0.2); color: #bbf7d0; }

.btn-primary { display: inline-flex; align-items: center; justify-content: center; gap: 9px; width: 100%; min-height: 50px; padding: 0 20px; border: 0; border-radius: 13px; background: linear-gradient(135deg, #22d3ee 0%, #0ea5e9 42%, #2563eb 100%); color: #ffffff; font: inherit; font-size: 0.92rem; font-weight: 800; letter-spacing: 0.01em; cursor: pointer; box-shadow: 0 16px 34px rgba(2, 132, 199, 0.34); transition: transform 160ms ease, box-shadow 160ms ease, filter 160ms ease; }
.btn-primary:hover:not(:disabled) { transform: translateY(-1px); filter: brightness(1.06); box-shadow: 0 20px 42px rgba(2, 132, 199, 0.44); }
.btn-primary:active:not(:disabled) { transform: translateY(0) scale(0.99); }
.btn-primary:disabled { opacity: 0.62; cursor: wait; }
.btn-primary--compact { width: auto; min-height: 44px; padding: 0 18px; font-size: 0.86rem; }
.btn-spinner { width: 17px; height: 17px; border: 2px solid rgba(255, 255, 255, 0.38); border-top-color: #ffffff; border-radius: 50%; animation: spin 0.8s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

.form-links { display: flex; flex-wrap: wrap; align-items: center; justify-content: center; gap: 8px; margin-top: 2px; }
.link-button { padding: 4px 2px; border: 0; background: transparent; color: rgba(186, 230, 253, 0.78); font: inherit; font-size: 0.8rem; cursor: pointer; transition: color 150ms ease; }
.link-button:hover { color: #ffffff; text-decoration: underline; }
.link-button--accent { color: #67e8f9; font-weight: 700; }
.link-separator { color: rgba(186, 230, 253, 0.34); }
.card-footnote { margin: 18px 0 0; color: rgba(186, 230, 253, 0.48); font-size: 0.68rem; line-height: 1.5; text-align: center; }

.modal-overlay { position: fixed; inset: 0; z-index: 1000; display: flex; align-items: flex-end; justify-content: center; background: rgba(2, 6, 23, 0.66); backdrop-filter: blur(7px); -webkit-backdrop-filter: blur(7px); animation: fadeIn 0.18s ease-out; }
.modal-card { position: relative; width: 100%; max-height: 92dvh; padding: 22px 18px calc(20px + env(safe-area-inset-bottom, 0px)); overflow-y: auto; -webkit-overflow-scrolling: touch; border: 1px solid rgba(255, 255, 255, 0.16); border-radius: 24px 24px 0 0; background: linear-gradient(160deg, rgba(15, 23, 42, 0.98), rgba(8, 47, 73, 0.98)); box-shadow: 0 -24px 70px rgba(2, 6, 23, 0.55); animation: sheetUp 0.24s cubic-bezier(0.2, 0.9, 0.3, 1); }
.modal-card--wide { max-width: 620px; }
.modal-close { position: absolute; top: 14px; right: 14px; display: inline-flex; align-items: center; justify-content: center; width: 38px; height: 38px; padding: 0; border: 1px solid rgba(255, 255, 255, 0.14); border-radius: 11px; background: rgba(255, 255, 255, 0.06); color: rgba(224, 242, 254, 0.8); font-size: 1.35rem; line-height: 1; cursor: pointer; }
.modal-close:hover { background: rgba(255, 255, 255, 0.12); color: #ffffff; }
.modal-icon { display: flex; align-items: center; justify-content: center; width: 48px; height: 48px; margin-bottom: 14px; border-radius: 15px; }
.modal-icon--blue { background: rgba(14, 165, 233, 0.18); color: #7dd3fc; }
.modal-icon--green { background: rgba(16, 185, 129, 0.18); color: #6ee7b7; }
.modal-icon svg { width: 24px; height: 24px; }
.modal-card h3 { margin: 0; padding-right: 40px; color: #ffffff; font-size: 1.25rem; font-weight: 800; }
.modal-subtitle { margin: 8px 0 0; color: rgba(224, 242, 254, 0.68); font-size: 0.84rem; line-height: 1.55; }
.modal-subtitle strong { color: #fbbf24; }
.modal-form { display: grid; gap: 14px; margin-top: 20px; }
.form-grid { display: grid; grid-template-columns: minmax(0, 1fr); gap: 13px; }
.modal-error, .modal-success { margin: 0; padding: 10px 12px; border-radius: 10px; font-size: 0.8rem; line-height: 1.45; }
.modal-error { border: 1px solid rgba(248, 113, 113, 0.38); background: rgba(127, 29, 29, 0.3); color: #fecaca; }
.modal-success { border: 1px solid rgba(52, 211, 153, 0.36); background: rgba(6, 78, 59, 0.3); color: #bbf7d0; }
.modal-actions { display: flex; flex-direction: column-reverse; gap: 10px; margin-top: 8px; }
.btn-ghost { display: inline-flex; align-items: center; justify-content: center; width: 100%; min-height: 44px; padding: 0 18px; border: 1px solid rgba(255, 255, 255, 0.16); border-radius: 12px; background: rgba(255, 255, 255, 0.04); color: rgba(224, 242, 254, 0.82); font: inherit; font-size: 0.86rem; font-weight: 600; cursor: pointer; }
.btn-ghost:hover:not(:disabled) { background: rgba(255, 255, 255, 0.1); color: #ffffff; }

@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
@keyframes sheetUp { from { transform: translateY(22px); opacity: 0; } to { transform: translateY(0); opacity: 1; } }

@media (min-width: 420px) {
  .form-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .register-form > .field { grid-column: 1 / -1; }
}
@media (min-width: 640px) {
  .login-page { padding: 28px; }
  .login-card { padding: 32px 30px 26px; border-radius: 28px; }
  .card-logo { display: block; }
  .login-form { margin-top: 26px; }
  .modal-overlay { align-items: center; padding: 24px; }
  .modal-card { max-width: 480px; max-height: 88vh; padding: 26px; border-radius: 22px; animation: scaleIn 0.2s ease-out; }
  .modal-card--wide { max-width: 640px; }
  .modal-actions { flex-direction: row; justify-content: flex-end; }
  .btn-ghost, .btn-primary--compact { width: auto; }
}
@keyframes scaleIn { from { transform: scale(0.96); opacity: 0; } to { transform: scale(1); opacity: 1; } }
@media (min-width: 1024px) {
  .login-shell { grid-template-columns: minmax(0, 1.05fr) minmax(400px, 0.78fr); gap: 56px; }
  .login-brand { display: block; }
  .login-card { max-width: 440px; margin: 0; }
}
@media (prefers-reduced-motion: reduce) {
  .login-page, .orb, .status-pulse::after, .btn-spinner { animation: none; }
  .login-page { background-position: 50% 50%; }
}
</style>