<template>
  <div class="recovery-page">
    <div class="recovery-bg" aria-hidden="true">
      <span class="orb orb--one" />
      <span class="orb orb--two" />
    </div>

    <main class="recovery-card">
      <div class="brand-row">
        <span class="brand-logo">
          <img :src="logoImage" alt="SIGAS" />
        </span>
        <div>
          <p class="brand-name">SIGAS</p>
          <p class="brand-sub">Sistema Integral de Gas</p>
        </div>
      </div>

      <template v-if="checking">
        <div class="state-box">
          <span class="spinner" aria-hidden="true" />
          <h1>Validando enlace…</h1>
          <p>Estamos verificando tu enlace de recuperación.</p>
        </div>
      </template>

      <template v-else-if="!hasSession">
        <div class="state-icon state-icon--danger" aria-hidden="true">!</div>
        <h1>Enlace no válido o expirado</h1>
        <p class="subtitle">
          Por seguridad, los enlaces de recuperación caducan. Solicita uno nuevo
          desde la pantalla de inicio de sesión.
        </p>
        <RouterLink to="/login" class="btn-primary">Volver al inicio de sesión</RouterLink>
      </template>

      <template v-else-if="success">
        <div class="state-icon state-icon--success" aria-hidden="true">✓</div>
        <h1>Contraseña actualizada</h1>
        <p class="subtitle">
          Tu contraseña se cambió correctamente. Ya puedes iniciar sesión con tus
          nuevas credenciales.
        </p>
        <RouterLink to="/login?reset=1" class="btn-primary">Ir a iniciar sesión</RouterLink>
      </template>

      <template v-else>
        <div class="state-icon state-icon--blue" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <rect x="4" y="10" width="16" height="10" rx="2" />
            <path stroke-linecap="round" d="M8 10V7a4 4 0 0 1 8 0v3" />
          </svg>
        </div>
        <h1>Crea una nueva contraseña</h1>
        <p class="subtitle">
          Elige una contraseña segura de al menos 6 caracteres. No uses la misma
          que tenías anteriormente.
        </p>

        <form class="recovery-form" @submit.prevent="handleSubmit" novalidate>
          <div class="field">
            <label for="new-password">Nueva contraseña</label>
            <div class="field-control">
              <input
                id="new-password"
                v-model="password"
                :type="showPassword ? 'text' : 'password'"
                autocomplete="new-password"
                minlength="6"
                placeholder="Mínimo 6 caracteres"
                required
              />
              <button
                type="button"
                class="password-toggle"
                :aria-label="showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'"
                @click="showPassword = !showPassword"
              >
                {{ showPassword ? 'Ocultar' : 'Ver' }}
              </button>
            </div>
          </div>

          <div class="field">
            <label for="confirm-password">Confirmar contraseña</label>
            <div class="field-control">
              <input
                id="confirm-password"
                v-model="passwordConfirm"
                :type="showPassword ? 'text' : 'password'"
                autocomplete="new-password"
                minlength="6"
                placeholder="Repite la contraseña"
                required
              />
            </div>
          </div>

          <p v-if="error" class="alert alert--error" role="alert">{{ error }}</p>

          <button type="submit" class="btn-primary" :disabled="loading">
            <span v-if="loading" class="spinner spinner--small" aria-hidden="true" />
            {{ loading ? 'Guardando…' : 'Guardar nueva contraseña' }}
          </button>
        </form>

        <RouterLink to="/login" class="back-link">Cancelar y volver al inicio</RouterLink>
      </template>
    </main>
  </div>
</template>

<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { supabase } from '../lib/supabase.js'
import logoImage from '../assets/sigas-logo.jpeg'

const checking = ref(true)
const hasSession = ref(false)
const success = ref(false)
const loading = ref(false)
const password = ref('')
const passwordConfirm = ref('')
const showPassword = ref(false)
const error = ref('')

let authSubscription = null
let checkTimer = null

onMounted(async () => {
  const { data, error: sessionError } = await supabase.auth.getSession()

  if (sessionError) {
    console.error('[SIGAS] Error obteniendo sesión de recuperación:', sessionError)
  }

  if (data?.session) {
    hasSession.value = true
    checking.value = false
  }

  const { data: listener } = supabase.auth.onAuthStateChange((event, session) => {
    if ((event === 'PASSWORD_RECOVERY' || event === 'SIGNED_IN') && session) {
      hasSession.value = true
      checking.value = false
      if (checkTimer) window.clearTimeout(checkTimer)
    }
  })
  authSubscription = listener?.subscription || null

  // Damos un margen para que detectSessionInUrl procese el hash del correo.
  checkTimer = window.setTimeout(() => {
    checking.value = false
  }, 1400)
})

onBeforeUnmount(() => {
  if (checkTimer) window.clearTimeout(checkTimer)
  if (authSubscription) authSubscription.unsubscribe()
})

async function handleSubmit() {
  error.value = ''

  if (password.value.length < 6) {
    error.value = 'La contraseña debe tener al menos 6 caracteres.'
    return
  }
  if (password.value !== passwordConfirm.value) {
    error.value = 'Las contraseñas no coinciden.'
    return
  }

  loading.value = true
  try {
    const { error: updateError } = await supabase.auth.updateUser({
      password: password.value,
    })

    if (updateError) throw updateError

    success.value = true
    password.value = ''
    passwordConfirm.value = ''
    await supabase.auth.signOut().catch(() => {})
  } catch (err) {
    console.error('[SIGAS] Error actualizando contraseña:', err)
    const message = String(err?.message || '')
    if (/expired|invalid|session/i.test(message)) {
      error.value =
        'El enlace de recuperación expiró o la sesión no es válida. Solicita un nuevo enlace.'
    } else if (/password/i.test(message) && /least|short|6/i.test(message)) {
      error.value = 'La contraseña debe tener al menos 6 caracteres.'
    } else {
      error.value = message || 'No se pudo actualizar la contraseña. Intenta nuevamente.'
    }
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.recovery-page {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  min-height: 100dvh;
  padding: calc(20px + env(safe-area-inset-top, 0px)) 16px
    calc(20px + env(safe-area-inset-bottom, 0px));
  overflow: hidden;
  background: linear-gradient(-45deg, #020617, #082f49, #075985, #0369a1, #0c4a6e);
  background-size: 400% 400%;
  animation: recoveryGradient 18s ease infinite;
  font-family: var(--font-sans);
  color: #f8fafc;
}

@keyframes recoveryGradient {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}

.recovery-bg {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.recovery-bg::before {
  content: '';
  position: absolute;
  inset: 0;
  background:
    radial-gradient(circle at 20% 20%, rgba(34, 211, 238, 0.2), transparent 35%),
    radial-gradient(circle at 80% 78%, rgba(59, 130, 246, 0.24), transparent 38%);
}

.orb {
  position: absolute;
  border-radius: 50%;
  filter: blur(8px);
  opacity: 0.55;
  animation: orbFloat 16s ease-in-out infinite;
}

.orb--one {
  top: -18%;
  left: -12%;
  width: 46vmax;
  height: 46vmax;
  background: radial-gradient(circle, rgba(34, 211, 238, 0.42), transparent 66%);
}

.orb--two {
  right: -16%;
  bottom: -20%;
  width: 52vmax;
  height: 52vmax;
  background: radial-gradient(circle, rgba(59, 130, 246, 0.4), transparent 66%);
  animation-delay: -7s;
}

@keyframes orbFloat {
  0%, 100% { transform: translate3d(0, 0, 0) scale(1); }
  50% { transform: translate3d(3%, -3%, 0) scale(1.05); }
}

.recovery-card {
  position: relative;
  z-index: 1;
  width: 100%;
  max-width: 460px;
  padding: 26px 22px;
  border: 1px solid rgba(255, 255, 255, 0.18);
  border-radius: 26px;
  background: linear-gradient(145deg, rgba(255, 255, 255, 0.13), rgba(255, 255, 255, 0.05));
  box-shadow:
    0 30px 80px rgba(2, 6, 23, 0.48),
    inset 0 1px 0 rgba(255, 255, 255, 0.24);
  backdrop-filter: blur(26px) saturate(150%);
  -webkit-backdrop-filter: blur(26px) saturate(150%);
}

.brand-row {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-bottom: 24px;
}

.brand-logo {
  display: inline-flex;
  width: 48px;
  height: 48px;
  overflow: hidden;
  border: 1px solid rgba(255, 255, 255, 0.26);
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.1);
}

.brand-logo img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.brand-name {
  margin: 0;
  color: #ffffff;
  font-size: 1.2rem;
  font-weight: 800;
  letter-spacing: 0.06em;
}

.brand-sub {
  margin: 1px 0 0;
  color: rgba(224, 242, 254, 0.7);
  font-size: 0.7rem;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.recovery-card h1 {
  margin: 0;
  color: #ffffff;
  font-size: 1.6rem;
  font-weight: 800;
  line-height: 1.2;
  letter-spacing: -0.02em;
}

.subtitle {
  margin: 10px 0 0;
  color: rgba(224, 242, 254, 0.72);
  font-size: 0.86rem;
  line-height: 1.55;
}

.state-box {
  display: grid;
  justify-items: center;
  padding: 20px 0;
  text-align: center;
}

.state-box h1 {
  margin-top: 16px;
}

.state-box p {
  margin: 8px 0 0;
  color: rgba(224, 242, 254, 0.7);
  font-size: 0.86rem;
}

.state-icon {
  display: flex;
  align-items: center;
  justify-content: center;
  width: 50px;
  height: 50px;
  margin-bottom: 16px;
  border-radius: 16px;
  font-size: 1.4rem;
  font-weight: 800;
}

.state-icon svg {
  width: 24px;
  height: 24px;
}

.state-icon--blue {
  background: rgba(14, 165, 233, 0.18);
  color: #7dd3fc;
}

.state-icon--danger {
  background: rgba(239, 68, 68, 0.18);
  color: #fca5a5;
}

.state-icon--success {
  background: rgba(16, 185, 129, 0.18);
  color: #6ee7b7;
}

.recovery-form {
  display: grid;
  gap: 15px;
  margin-top: 22px;
}

.field {
  display: grid;
  gap: 7px;
}

.field > label {
  color: rgba(240, 249, 255, 0.88);
  font-size: 0.78rem;
  font-weight: 700;
}

.field-control {
  display: flex;
  align-items: center;
  gap: 9px;
  min-height: 48px;
  padding: 0 13px;
  border: 1px solid rgba(255, 255, 255, 0.17);
  border-radius: 13px;
  background: rgba(2, 6, 23, 0.22);
  transition: border-color 160ms ease, box-shadow 160ms ease;
}

.field-control:focus-within {
  border-color: rgba(125, 211, 252, 0.78);
  box-shadow: 0 0 0 4px rgba(14, 165, 233, 0.16);
}

.field-control input {
  width: 100%;
  min-width: 0;
  height: 46px;
  padding: 0;
  border: 0;
  outline: 0;
  background: transparent;
  color: #f8fafc;
  font: inherit;
  font-size: 0.9rem;
}

.field-control input::placeholder {
  color: rgba(186, 230, 253, 0.45);
}

.password-toggle {
  flex-shrink: 0;
  min-width: 42px;
  min-height: 34px;
  padding: 0 8px;
  border: 0;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.06);
  color: #bae6fd;
  font: inherit;
  font-size: 0.72rem;
  font-weight: 700;
  cursor: pointer;
}

.password-toggle:hover {
  background: rgba(255, 255, 255, 0.12);
  color: #ffffff;
}

.alert {
  margin: 0;
  padding: 10px 12px;
  border: 1px solid transparent;
  border-radius: 11px;
  font-size: 0.82rem;
  line-height: 1.45;
}

.alert--error {
  border-color: rgba(248, 113, 113, 0.38);
  background: rgba(127, 29, 29, 0.32);
  color: #fecaca;
}

.btn-primary {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 9px;
  width: 100%;
  min-height: 50px;
  margin-top: 6px;
  padding: 0 20px;
  border: 0;
  border-radius: 13px;
  background: linear-gradient(135deg, #22d3ee 0%, #0ea5e9 42%, #2563eb 100%);
  color: #ffffff;
  font: inherit;
  font-size: 0.92rem;
  font-weight: 800;
  text-align: center;
  text-decoration: none;
  cursor: pointer;
  box-shadow: 0 16px 34px rgba(2, 132, 199, 0.34);
  transition: transform 160ms ease, filter 160ms ease;
}

.btn-primary:hover:not(:disabled) {
  transform: translateY(-1px);
  filter: brightness(1.06);
}

.btn-primary:disabled {
  opacity: 0.62;
  cursor: wait;
}

.back-link {
  display: block;
  margin-top: 18px;
  color: rgba(186, 230, 253, 0.7);
  font-size: 0.8rem;
  text-align: center;
  text-decoration: none;
}

.back-link:hover {
  color: #ffffff;
  text-decoration: underline;
}

.spinner {
  width: 26px;
  height: 26px;
  border: 3px solid rgba(255, 255, 255, 0.25);
  border-top-color: #ffffff;
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

.spinner--small {
  width: 17px;
  height: 17px;
  border-width: 2px;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

@media (min-width: 640px) {
  .recovery-card {
    padding: 34px 32px;
    border-radius: 28px;
  }

  .recovery-card h1 {
    font-size: 1.8rem;
  }
}

@media (prefers-reduced-motion: reduce) {
  .recovery-page,
  .orb,
  .spinner {
    animation: none;
  }
}
</style>
