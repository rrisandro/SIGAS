<template>
  <div class="usuarios-page">
    <header class="page-banner">
      <div class="banner-copy">
        <span class="banner-eyebrow">
          <span class="pulse-dot" aria-hidden="true" />
          Seguridad y Accesos
        </span>
        <h1>Gestión de Usuarios</h1>
        <p>
          Administra las cuentas del sistema, sus roles y estados. Las cuentas se
          eliminan de forma lógica: se conservan en el historial y pueden restaurarse.
        </p>
      </div>

      <div class="banner-actions">
        <button type="button" class="btn-refresh" :disabled="loading" @click="cargarUsuarios">
          <svg viewBox="0 0 24 24" class="refresh-icon" :class="{ spin: loading }" aria-hidden="true">
            <path fill="currentColor" d="M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6 0 1.01-.25 1.97-.7 2.8l1.46 1.46A7.93 7.93 0 0 0 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6 0-1.01.25-1.97.7-2.8L5.24 7.74A7.93 7.93 0 0 0 4 12c0 4.42 3.58 8 8 8v3l4-4-4-4v3" />
          </svg>
          {{ loading ? 'Actualizando…' : 'Actualizar' }}
        </button>
      </div>
    </header>

    <div v-if="error && !confirmOpen" class="alert alert--error" role="alert">{{ error }}</div>
    <div v-if="success" class="alert alert--success" role="status">{{ success }}</div>

    <section class="stats-grid" aria-label="Resumen de usuarios">
      <article class="stat-card stat-card--blue">
        <span class="stat-icon" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <path stroke-linecap="round" stroke-linejoin="round" d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
            <circle cx="9" cy="7" r="4" />
            <path stroke-linecap="round" stroke-linejoin="round" d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" />
          </svg>
        </span>
        <div>
          <p class="stat-label">Cuentas vigentes</p>
          <p class="stat-value">{{ totalVigentes }}</p>
        </div>
      </article>
      <article class="stat-card stat-card--green">
        <span class="stat-icon" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M20 6 9 17l-5-5" />
          </svg>
        </span>
        <div>
          <p class="stat-label">Activas</p>
          <p class="stat-value">{{ totalActivas }}</p>
        </div>
      </article>
      <article class="stat-card stat-card--amber">
        <span class="stat-icon" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <circle cx="12" cy="12" r="9" />
            <path stroke-linecap="round" d="M12 7v5l3 2" />
          </svg>
        </span>
        <div>
          <p class="stat-label">Pendientes</p>
          <p class="stat-value">{{ totalPendientes }}</p>
        </div>
      </article>
      <article class="stat-card stat-card--red">
        <span class="stat-icon" aria-hidden="true">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8">
            <path stroke-linecap="round" stroke-linejoin="round" d="M3 6h18M8 6V4h8v2M6 6l1 14h10l1-14M10 11v5M14 11v5" />
          </svg>
        </span>
        <div>
          <p class="stat-label">Eliminadas</p>
          <p class="stat-value">{{ totalEliminadas }}</p>
        </div>
      </article>
    </section>

    <section class="filter-card" aria-label="Filtros de usuarios">
      <label class="search-field">
        <span class="sr-only">Buscar usuario</span>
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" d="m21 21-4.35-4.35M19 11a8 8 0 1 1-16 0 8 8 0 0 1 16 0z" />
        </svg>
        <input
          v-model="filtroBusqueda"
          type="search"
          placeholder="Buscar por cédula, nombre, correo o teléfono…"
        />
      </label>

      <div class="filter-chips" role="group" aria-label="Filtrar por estado">
        <button
          v-for="item in filtros"
          :key="item.value"
          type="button"
          class="filter-chip"
          :class="{ active: filtroEstado === item.value }"
          @click="filtroEstado = item.value"
        >
          {{ item.label }}
          <span>{{ contarPorFiltro(item.value) }}</span>
        </button>
      </div>
    </section>

    <div v-if="loading" class="state-panel">
      <span class="spinner" aria-hidden="true" />
      <p>Cargando usuarios desde Supabase…</p>
    </div>

    <div v-else-if="usuariosFiltrados.length === 0" class="state-panel state-panel--empty">
      <span class="empty-icon" aria-hidden="true">🔎</span>
      <strong>No se encontraron usuarios</strong>
      <p>Prueba con otra búsqueda o cambia el filtro de estado.</p>
    </div>

    <div v-else class="table-card">
      <div class="table-wrapper">
        <table class="custom-table">
          <thead>
            <tr>
              <th>Cédula (ID)</th>
              <th>Nombre completo</th>
              <th>Contacto</th>
              <th>Calle / Sector</th>
              <th>Rol / Cargo</th>
              <th>Estado</th>
              <th class="actions-head">Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="usuario in usuariosFiltrados"
              :key="usuario.id"
              class="table-row"
              :class="{ 'is-deleted': usuario.is_deleted }"
            >
              <td class="id-cell" data-label="Cédula (ID)">V-{{ usuario.id }}</td>
              <td data-label="Nombre completo">
                <div class="name-cell">
                  <div class="avatar">{{ inicial(usuario.nombre_familia) }}</div>
                  <div class="name-copy">
                    <span class="family-name">{{ usuario.nombre_familia || 'Sin nombre' }}</span>
                    <span v-if="esCuentaActual(usuario)" class="self-tag">Tu cuenta</span>
                    <span v-else-if="usuario.is_deleted" class="deleted-tag">Eliminada</span>
                  </div>
                </div>
              </td>
              <td data-label="Contacto">
                <div class="contact-copy">
                  <span>{{ usuario.email || 'Sin correo' }}</span>
                  <small>{{ usuario.telefono || 'Sin teléfono' }}</small>
                </div>
              </td>
              <td data-label="Calle / Sector">
                <span class="badge-calle">{{ obtenerNombreCalle(usuario.id_calle) }}</span>
              </td>
              <td data-label="Rol / Cargo">
                <span class="role-badge" :class="`role-${usuario.id_cargo}`">
                  {{ obtenerNombreCargo(usuario.id_cargo) }}
                </span>
              </td>
              <td data-label="Estado">
                <span class="status-pill" :class="estadoClase(usuario)">
                  {{ estadoLabel(usuario) }}
                </span>
              </td>
              <td data-label="Acciones">
                <div class="row-actions">
                  <span v-if="esCuentaActual(usuario)" class="self-note">No puedes eliminarte</span>
                  <button
                    v-else-if="usuario.is_deleted"
                    type="button"
                    class="btn-row btn-row--success"
                    @click="abrirConfirmacion(usuario, 'restaurar')"
                  >
                    Restaurar
                  </button>
                  <button
                    v-else
                    type="button"
                    class="btn-row btn-row--danger"
                    @click="abrirConfirmacion(usuario, 'eliminar')"
                  >
                    Eliminar
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="mobile-list" role="list">
        <article
          v-for="usuario in usuariosFiltrados"
          :key="`card-${usuario.id}`"
          class="mobile-card"
          :class="{ 'is-deleted': usuario.is_deleted }"
          role="listitem"
        >
          <div class="mobile-card-head">
            <div class="name-cell">
              <div class="avatar">{{ inicial(usuario.nombre_familia) }}</div>
              <div class="name-copy">
                <p class="mobile-name">{{ usuario.nombre_familia || 'Sin nombre' }}</p>
                <p class="mobile-id">V-{{ usuario.id }}</p>
              </div>
            </div>
            <span class="status-pill" :class="estadoClase(usuario)">{{ estadoLabel(usuario) }}</span>
          </div>

          <div class="mobile-details">
            <div>
              <span>Rol</span>
              <strong>{{ obtenerNombreCargo(usuario.id_cargo) }}</strong>
            </div>
            <div>
              <span>Calle</span>
              <strong>{{ obtenerNombreCalle(usuario.id_calle) }}</strong>
            </div>
            <div>
              <span>Correo</span>
              <strong>{{ usuario.email || 'Sin correo' }}</strong>
            </div>
          </div>

          <p v-if="usuario.is_deleted" class="mobile-deleted-note">
            Cuenta eliminada lógicamente. Puedes restaurarla para que vuelva a estar vigente.
          </p>

          <div class="mobile-actions">
            <span v-if="esCuentaActual(usuario)" class="self-note">Esta es tu cuenta actual</span>
            <button
              v-else-if="usuario.is_deleted"
              type="button"
              class="btn-row btn-row--success"
              @click="abrirConfirmacion(usuario, 'restaurar')"
            >
              Restaurar
            </button>
            <button
              v-else
              type="button"
              class="btn-row btn-row--danger"
              @click="abrirConfirmacion(usuario, 'eliminar')"
            >
              Eliminar usuario
            </button>
          </div>
        </article>
      </div>
    </div>

    <ConfirmDialog
      v-model="confirmOpen"
      :title="confirmTitle"
      :message="confirmMessage"
      :confirm-text="confirmText"
      :confirm-variant="confirmAction === 'eliminar' ? 'danger' : 'success'"
      :tone="confirmAction === 'eliminar' ? 'danger' : 'success'"
      :loading="accionLoading"
      :error="confirmError"
      :confirm-disabled="confirmAction === 'eliminar' && !adminPassword.trim()"
      @confirm="ejecutarConfirmacion"
    >
      <template v-if="confirmAction === 'eliminar'">
        <div class="dialog-field">
          <label for="admin-password">Contraseña del administrador</label>
          <input
            id="admin-password"
            v-model="adminPassword"
            type="password"
            autocomplete="current-password"
            placeholder="Escribe tu contraseña actual"
          />
          <small>Por seguridad, confirma tu contraseña para eliminar esta cuenta.</small>
        </div>

        <div class="dialog-field">
          <label for="delete-motivo">Motivo (opcional)</label>
          <textarea
            id="delete-motivo"
            v-model="motivo"
            rows="3"
            maxlength="500"
            placeholder="Motivo de la baja, visible en auditoría…"
          />
        </div>
      </template>
    </ConfirmDialog>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import ConfirmDialog from '../../components/ui/ConfirmDialog.vue'
import { supabase } from '../../lib/supabase.js'
import { useAuth } from '../../composables/useAuth.js'

const { currentUser } = useAuth()

const usuarios = ref([])
const calles = ref([])
const cargos = ref([])
const filtroBusqueda = ref('')
const filtroEstado = ref('todos')
const loading = ref(true)
const error = ref('')
const success = ref('')
let successTimer = null

const confirmOpen = ref(false)
const confirmAction = ref('')
const confirmError = ref('')
const seleccionado = ref(null)
const adminPassword = ref('')
const motivo = ref('')
const accionLoading = ref(false)

const filtros = [
  { value: 'todos', label: 'Todos' },
  { value: 'activos', label: 'Activos' },
  { value: 'pendientes', label: 'Pendientes' },
  { value: 'rechazados', label: 'Rechazados' },
  { value: 'inactivos', label: 'Inactivos' },
  { value: 'eliminados', label: 'Eliminados' },
]

const vigentes = computed(() => usuarios.value.filter((usuario) => !usuario.is_deleted))
const totalVigentes = computed(() => vigentes.value.length)
const totalActivas = computed(
  () => vigentes.value.filter((usuario) => estadoDe(usuario) === 'aprobado' && usuario.activo).length
)
const totalPendientes = computed(
  () => vigentes.value.filter((usuario) => estadoDe(usuario) === 'pendiente').length
)
const totalEliminadas = computed(
  () => usuarios.value.filter((usuario) => usuario.is_deleted).length
)

const usuariosFiltrados = computed(() => {
  const q = filtroBusqueda.value.trim().toLowerCase()

  return usuarios.value.filter((usuario) => {
    const estado = estadoDe(usuario)

    if (filtroEstado.value === 'eliminados' && !usuario.is_deleted) return false
    if (filtroEstado.value !== 'eliminados' && usuario.is_deleted) return false
    if (filtroEstado.value === 'activos' && !(estado === 'aprobado' && usuario.activo)) return false
    if (filtroEstado.value === 'pendientes' && estado !== 'pendiente') return false
    if (filtroEstado.value === 'rechazados' && estado !== 'rechazado') return false
    if (filtroEstado.value === 'inactivos' && !(estado === 'aprobado' && !usuario.activo)) return false

    if (!q) return true
    return [usuario.id, usuario.nombre_familia, usuario.email, usuario.telefono]
      .some((value) => String(value || '').toLowerCase().includes(q))
  })
})

const confirmTitle = computed(() =>
  confirmAction.value === 'eliminar' ? 'Eliminar usuario del sistema' : 'Restaurar usuario'
)

const confirmMessage = computed(() => {
  const nombre = seleccionado.value?.nombre_familia || 'este usuario'
  if (confirmAction.value === 'eliminar') {
    return `¿Eliminar la cuenta de ${nombre}? Se desactivará su acceso y se darán de baja sus roles asociados. La cuenta se conservará en el historial y podrá restaurarse.`
  }
  return `¿Restaurar la cuenta de ${nombre}? Volverá a estar vigente según su estado de aprobación.`
})

const confirmText = computed(() =>
  confirmAction.value === 'eliminar' ? 'Eliminar usuario' : 'Sí, restaurar'
)

onMounted(cargarUsuarios)

async function cargarUsuarios() {
  loading.value = true
  error.value = ''

  try {
    const [callesResult, cargosResult, usuariosResult] = await Promise.all([
      supabase
        .from('calles')
        .select('id_calle, nombre')
        .eq('is_deleted', false)
        .order('nombre'),
      supabase.from('cargos').select('id_cargo, nombre').order('id_cargo'),
      supabase.from('familias').select('*').order('id', { ascending: false }),
    ])

    if (callesResult.error) throw callesResult.error
    if (cargosResult.error) throw cargosResult.error
    if (usuariosResult.error) throw usuariosResult.error

    calles.value = callesResult.data || []
    cargos.value = cargosResult.data || []
    usuarios.value = usuariosResult.data || []
  } catch (err) {
    console.error('[SIGAS] Error cargando usuarios:', err)
    error.value = mensajeError(err, 'No se pudieron cargar los usuarios.')
    usuarios.value = []
  } finally {
    loading.value = false
  }
}

function abrirConfirmacion(usuario, accion) {
  seleccionado.value = usuario
  confirmAction.value = accion
  confirmError.value = ''
  adminPassword.value = ''
  motivo.value = ''
  confirmOpen.value = true
}

async function ejecutarConfirmacion() {
  if (!seleccionado.value) return
  confirmError.value = ''

  if (confirmAction.value === 'eliminar') {
    await eliminarUsuario()
  } else {
    await restaurarUsuario()
  }
}

async function eliminarUsuario() {
  if (!adminPassword.value.trim()) {
    confirmError.value = 'Escribe la contraseña del administrador.'
    return
  }

  accionLoading.value = true

  try {
    await reautenticarAdmin(adminPassword.value)

    const usuario = seleccionado.value
    const { error: rpcError } = await supabase.rpc('eliminar_usuario_logico', {
      p_id: usuario.id,
      p_auth_id: usuario.auth_id || null,
      p_motivo: motivo.value.trim() || null,
    })

    if (rpcError) {
      if (!esRpcInexistente(rpcError)) throw rpcError
      await eliminarUsuarioFallback(usuario, motivo.value.trim())
    }

    confirmOpen.value = false
    mostrarExito(`La cuenta de ${usuario.nombre_familia || usuario.id} fue eliminada.`)
    seleccionado.value = null
    await cargarUsuarios()
  } catch (err) {
    console.error('[SIGAS] Error eliminando usuario:', err)
    confirmError.value = mensajeError(err, 'No se pudo eliminar el usuario.')
  } finally {
    accionLoading.value = false
  }
}

async function reautenticarAdmin(password) {
  const { data: authData, error: authError } = await supabase.auth.getUser()
  if (authError) throw new Error('Tu sesión expiró. Vuelve a iniciar sesión.')

  const email = authData?.user?.email || currentUser.value?.email
  if (!email) {
    throw new Error('No se pudo obtener el correo del administrador para verificar la contraseña.')
  }

  const { error: signInError } = await supabase.auth.signInWithPassword({
    email,
    password,
  })

  if (signInError) {
    if (/invalid login credentials/i.test(signInError.message || '')) {
      throw new Error('La contraseña del administrador es incorrecta.')
    }
    throw signInError
  }
}

async function eliminarUsuarioFallback(usuario, motivoTexto) {
  const now = new Date().toISOString()

  const { error: familiaError } = await supabase
    .from('familias')
    .update({ is_deleted: true, deleted_at: now, activo: false })
    .eq('id', usuario.id)

  if (familiaError) throw familiaError

  if (usuario.auth_id) {
    const { error: jefesFamiliaError } = await supabase
      .from('jefes_familia')
      .update({ activo: false, is_deleted: true, deleted_at: now })
      .eq('auth_id', usuario.auth_id)

    if (jefesFamiliaError && !/relation .* does not exist/i.test(jefesFamiliaError.message || '')) {
      console.warn('[SIGAS] No se pudieron dar de baja los jefes de familia:', jefesFamiliaError)
    }

    const { error: jefeCalleError } = await supabase
      .from('jefe_de_calle')
      .update({ activo: false, is_deleted: true, deleted_at: now })
      .eq('auth_id', usuario.auth_id)

    if (jefeCalleError) {
      console.warn('[SIGAS] No se pudo dar de baja el Jefe de Calle:', jefeCalleError)
    }
  }

  console.info('[SIGAS] Baja lógica aplicada sin RPC.', {
    id: usuario.id,
    motivo: motivoTexto || null,
  })
}

async function restaurarUsuario() {
  accionLoading.value = true

  try {
    const usuario = seleccionado.value
    const { error: updateError } = await supabase
      .from('familias')
      .update({
        is_deleted: false,
        deleted_at: null,
        activo: estadoDe(usuario) === 'aprobado',
      })
      .eq('id', usuario.id)

    if (updateError) throw updateError

    confirmOpen.value = false
    mostrarExito(`La cuenta de ${usuario.nombre_familia || usuario.id} fue restaurada.`)
    seleccionado.value = null
    await cargarUsuarios()
  } catch (err) {
    console.error('[SIGAS] Error restaurando usuario:', err)
    confirmError.value = mensajeError(err, 'No se pudo restaurar el usuario.')
  } finally {
    accionLoading.value = false
  }
}

function contarPorFiltro(filtro) {
  if (filtro === 'todos') return vigentes.value.length
  if (filtro === 'eliminados') return totalEliminadas.value
  if (filtro === 'activos') return totalActivas.value
  if (filtro === 'pendientes') return totalPendientes.value
  if (filtro === 'rechazados') {
    return vigentes.value.filter((usuario) => estadoDe(usuario) === 'rechazado').length
  }
  if (filtro === 'inactivos') {
    return vigentes.value.filter(
      (usuario) => estadoDe(usuario) === 'aprobado' && !usuario.activo
    ).length
  }
  return 0
}

function estadoDe(usuario) {
  return String(usuario?.estado || 'aprobado').toLowerCase()
}

function estadoLabel(usuario) {
  if (usuario.is_deleted) return 'Eliminada'
  const estado = estadoDe(usuario)
  if (estado === 'pendiente') return 'Pendiente'
  if (estado === 'rechazado') return 'Rechazado'
  return usuario.activo ? 'Activo' : 'Inactivo'
}

function estadoClase(usuario) {
  if (usuario.is_deleted) return 'is-deleted'
  const estado = estadoDe(usuario)
  if (estado === 'pendiente') return 'is-pending'
  if (estado === 'rechazado') return 'is-rejected'
  return usuario.activo ? 'is-active' : 'is-inactive'
}

function esCuentaActual(usuario) {
  const authId = currentUser.value?.authId
  if (authId && usuario.auth_id === authId) return true
  return Number(usuario.id) === Number(currentUser.value?.id)
}

function obtenerNombreCalle(idCalle) {
  if (!idCalle) return 'Sin calle'
  const calle = calles.value.find((item) => Number(item.id_calle) === Number(idCalle))
  return calle?.nombre || `Calle ID ${idCalle}`
}

function obtenerNombreCargo(idCargo) {
  const cargo = cargos.value.find((item) => Number(item.id_cargo) === Number(idCargo))
  if (cargo) return cargo.nombre
  if (Number(idCargo) === 1) return 'Administrador'
  if (Number(idCargo) === 2) return 'Jefe de Calle'
  return 'Familia'
}

function inicial(nombre) {
  return String(nombre || 'U').trim().charAt(0).toUpperCase() || 'U'
}

function mostrarExito(mensaje) {
  success.value = mensaje
  if (successTimer) window.clearTimeout(successTimer)
  successTimer = window.setTimeout(() => {
    success.value = ''
  }, 5000)
}

function esRpcInexistente(err) {
  return (
    err?.code === 'PGRST202' ||
    /could not find the function|function .* does not exist/i.test(err?.message || '')
  )
}

function mensajeError(err, fallback = 'No se pudo completar la acción.') {
  const mensaje = String(err?.message || err?.details || '')
  if (/No puedes eliminar tu propia cuenta/i.test(mensaje)) {
    return 'No puedes eliminar tu propia cuenta.'
  }
  if (/No tienes permiso|42501|row-level security/i.test(mensaje)) {
    return 'No tienes permisos para eliminar usuarios.'
  }
  if (/invalid login credentials/i.test(mensaje)) {
    return 'La contraseña del administrador es incorrecta.'
  }
  return mensaje || fallback
}
</script>

<style scoped>
.usuarios-page {
  display: flex;
  flex-direction: column;
  gap: 18px;
  color: #0f172a;
}

.page-banner {
  display: flex;
  flex-direction: column;
  gap: 16px;
  padding: 22px 18px;
  overflow: hidden;
  border: 1px solid #dbeafe;
  border-radius: 20px;
  background:
    radial-gradient(circle at 92% 8%, rgba(34, 211, 238, 0.22), transparent 32%),
    linear-gradient(135deg, #ffffff 0%, #f0f9ff 58%, #e0f2fe 100%);
  box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
}

.banner-eyebrow {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  width: fit-content;
  padding: 5px 11px;
  border: 1px solid #bfdbfe;
  border-radius: 999px;
  background: #eff6ff;
  color: #0369a1;
  font-size: 0.7rem;
  font-weight: 800;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

.pulse-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #0ea5e9;
  box-shadow: 0 0 0 4px rgba(14, 165, 233, 0.14);
  animation: pulse 2s ease-in-out infinite;
}

@keyframes pulse {
  0%, 100% { transform: scale(0.92); opacity: 0.8; }
  50% { transform: scale(1.18); opacity: 1; }
}

.banner-copy h1 {
  margin: 12px 0 0;
  color: #0f172a;
  font-size: 1.55rem;
  font-weight: 800;
  letter-spacing: -0.025em;
  line-height: 1.2;
}

.banner-copy p {
  max-width: 720px;
  margin: 7px 0 0;
  color: #64748b;
  font-size: 0.88rem;
  line-height: 1.55;
}

.banner-actions {
  display: flex;
  flex-direction: column;
  gap: 9px;
}

.btn-refresh,
.btn-row {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  min-height: 44px;
  padding: 0 16px;
  border-radius: 12px;
  font: inherit;
  font-size: 0.84rem;
  font-weight: 700;
  cursor: pointer;
  transition: background-color 150ms ease, border-color 150ms ease, color 150ms ease;
}

.btn-refresh {
  border: 1px solid #bae6fd;
  background: #ffffff;
  color: #0369a1;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
}

.btn-refresh:hover:not(:disabled) {
  background: #f0f9ff;
}

.btn-refresh:disabled,
.btn-row:disabled {
  opacity: 0.6;
  cursor: wait;
}

.refresh-icon {
  width: 17px;
  height: 17px;
}

.refresh-icon.spin {
  animation: spin 0.9s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.alert {
  padding: 12px 14px;
  border: 1px solid transparent;
  border-radius: 12px;
  font-size: 0.85rem;
  line-height: 1.5;
}

.alert--error {
  border-color: #fecaca;
  background: #fef2f2;
  color: #b91c1c;
}

.alert--success {
  border-color: #a7f3d0;
  background: #ecfdf5;
  color: #047857;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
}

.stat-card {
  display: flex;
  align-items: center;
  gap: 11px;
  min-width: 0;
  padding: 13px;
  border: 1px solid #e2e8f0;
  border-radius: 15px;
  background: #ffffff;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.03);
}

.stat-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 38px;
  height: 38px;
  border-radius: 11px;
  background: #f1f5f9;
}

.stat-icon svg {
  width: 20px;
  height: 20px;
}

.stat-card--blue .stat-icon { background: #eff6ff; color: #1d4ed8; }
.stat-card--green .stat-icon { background: #ecfdf5; color: #047857; }
.stat-card--amber .stat-icon { background: #fffbeb; color: #b45309; }
.stat-card--red .stat-icon { background: #fef2f2; color: #b91c1c; }

.stat-label {
  margin: 0;
  color: #64748b;
  font-size: 0.68rem;
  font-weight: 700;
  letter-spacing: 0.03em;
  line-height: 1.3;
  text-transform: uppercase;
}

.stat-value {
  margin: 2px 0 0;
  color: #0f172a;
  font-size: 1.45rem;
  font-weight: 800;
  line-height: 1.1;
  font-variant-numeric: tabular-nums;
}

.filter-card {
  display: grid;
  gap: 11px;
  padding: 13px;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  background: #ffffff;
  box-shadow: 0 1px 2px rgba(15, 23, 42, 0.03);
}

.search-field {
  position: relative;
  display: flex;
  align-items: center;
}

.search-field svg {
  position: absolute;
  left: 12px;
  width: 17px;
  height: 17px;
  color: #94a3b8;
  pointer-events: none;
}

.search-field input {
  width: 100%;
  min-height: 44px;
  padding: 0 12px 0 38px;
  border: 1px solid #d1d5db;
  border-radius: 11px;
  background: #f8fafc;
  color: #0f172a;
  font: inherit;
  font-size: 16px;
  outline: none;
  transition: border-color 150ms ease, box-shadow 150ms ease, background-color 150ms ease;
}

.search-field input:focus {
  border-color: #0ea5e9;
  background: #ffffff;
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.14);
}

.filter-chips {
  display: flex;
  gap: 7px;
  overflow-x: auto;
  padding-bottom: 2px;
  scrollbar-width: none;
}

.filter-chips::-webkit-scrollbar {
  display: none;
}

.filter-chip {
  display: inline-flex;
  flex-shrink: 0;
  align-items: center;
  gap: 6px;
  min-height: 36px;
  padding: 0 11px;
  border: 1px solid #e2e8f0;
  border-radius: 999px;
  background: #ffffff;
  color: #64748b;
  font: inherit;
  font-size: 0.76rem;
  font-weight: 700;
  cursor: pointer;
}

.filter-chip span {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 18px;
  height: 18px;
  padding: 0 4px;
  border-radius: 999px;
  background: #f1f5f9;
  font-size: 0.64rem;
}

.filter-chip.active {
  border-color: #7dd3fc;
  background: #f0f9ff;
  color: #0369a1;
}

.filter-chip.active span {
  background: #e0f2fe;
  color: #0369a1;
}

.state-panel {
  display: grid;
  justify-items: center;
  gap: 8px;
  padding: 38px 18px;
  border: 1px solid #e2e8f0;
  border-radius: 16px;
  background: #ffffff;
  color: #64748b;
  text-align: center;
}

.state-panel p {
  margin: 0;
  font-size: 0.84rem;
  line-height: 1.5;
}

.state-panel strong {
  color: #0f172a;
  font-size: 0.9rem;
}

.state-panel--empty {
  border-style: dashed;
  background: #f8fafc;
}

.empty-icon {
  font-size: 1.8rem;
}

.spinner {
  width: 28px;
  height: 28px;
  border: 3px solid #e2e8f0;
  border-top-color: #0ea5e9;
  border-radius: 50%;
  animation: spin 0.9s linear infinite;
}

.table-card {
  overflow: hidden;
  border: 1px solid #e2e8f0;
  border-radius: 18px;
  background: #ffffff;
  box-shadow: 0 1px 3px rgba(15, 23, 42, 0.04);
}

.table-wrapper {
  display: none;
  overflow-x: auto;
}

.custom-table {
  width: 100%;
  border-collapse: collapse;
  text-align: left;
}

.custom-table th {
  padding: 12px 14px;
  border-bottom: 1px solid #e2e8f0;
  background: #f8fafc;
  color: #64748b;
  font-size: 0.7rem;
  font-weight: 700;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  white-space: nowrap;
}

.custom-table td {
  padding: 13px 14px;
  border-bottom: 1px solid #f1f5f9;
  color: #334155;
  font-size: 0.84rem;
  vertical-align: middle;
}

.custom-table tbody tr:last-child td {
  border-bottom: 0;
}

.table-row:hover {
  background: #f8fafc;
}

.table-row.is-deleted {
  background: #fafafa;
}

.table-row.is-deleted td {
  color: #94a3b8;
}

.id-cell {
  color: #0369a1;
  font-weight: 700;
  white-space: nowrap;
}

.name-cell {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
}

.name-copy {
  display: flex;
  flex-direction: column;
  gap: 3px;
  min-width: 0;
}

.family-name {
  overflow: hidden;
  color: #0f172a;
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.avatar {
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  width: 34px;
  height: 34px;
  border-radius: 9px;
  background: #eff6ff;
  color: #1d4ed8;
  font-size: 0.8rem;
  font-weight: 800;
}

.self-tag,
.deleted-tag {
  display: inline-flex;
  width: fit-content;
  padding: 2px 7px;
  border: 1px solid #bfdbfe;
  border-radius: 999px;
  background: #eff6ff;
  color: #1d4ed8;
  font-size: 0.6rem;
  font-weight: 700;
  white-space: nowrap;
}

.deleted-tag {
  border-color: #e2e8f0;
  background: #f1f5f9;
  color: #64748b;
}

.contact-copy {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.contact-copy span {
  overflow: hidden;
  color: #334155;
  font-size: 0.8rem;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.contact-copy small {
  color: #94a3b8;
  font-size: 0.7rem;
}

.badge-calle {
  display: inline-flex;
  padding: 4px 9px;
  border: 1px solid #e2e8f0;
  border-radius: 7px;
  background: #f1f5f9;
  color: #475569;
  font-size: 0.76rem;
  font-weight: 600;
  white-space: nowrap;
}

.role-badge {
  display: inline-flex;
  padding: 4px 9px;
  border: 1px solid transparent;
  border-radius: 7px;
  font-size: 0.72rem;
  font-weight: 700;
  white-space: nowrap;
}

.role-badge.role-1 {
  border-color: #fecaca;
  background: #fef2f2;
  color: #b91c1c;
}

.role-badge.role-2 {
  border-color: #fde68a;
  background: #fffbeb;
  color: #b45309;
}

.role-badge.role-3 {
  border-color: #bfdbfe;
  background: #eff6ff;
  color: #1d4ed8;
}

.status-pill {
  display: inline-flex;
  align-items: center;
  padding: 4px 9px;
  border: 1px solid transparent;
  border-radius: 999px;
  font-size: 0.68rem;
  font-weight: 800;
  letter-spacing: 0.02em;
  white-space: nowrap;
}

.status-pill.is-active {
  border-color: #a7f3d0;
  background: #ecfdf5;
  color: #047857;
}

.status-pill.is-pending {
  border-color: #fde68a;
  background: #fffbeb;
  color: #b45309;
}

.status-pill.is-rejected,
.status-pill.is-deleted {
  border-color: #fecaca;
  background: #fef2f2;
  color: #b91c1c;
}

.status-pill.is-inactive {
  border-color: #e2e8f0;
  background: #f1f5f9;
  color: #475569;
}

.actions-head {
  text-align: right;
}

.row-actions {
  display: flex;
  flex-wrap: wrap;
  justify-content: flex-end;
  gap: 6px;
}

.btn-row {
  min-height: 36px;
  padding: 0 11px;
  border: 1px solid transparent;
  border-radius: 9px;
  font-size: 0.75rem;
}

.btn-row--danger {
  border-color: #fecaca;
  background: #fef2f2;
  color: #b91c1c;
}

.btn-row--danger:hover {
  border-color: #dc2626;
  background: #dc2626;
  color: #ffffff;
}

.btn-row--success {
  border-color: #a7f3d0;
  background: #ecfdf5;
  color: #047857;
}

.btn-row--success:hover {
  border-color: #059669;
  background: #059669;
  color: #ffffff;
}

.self-note {
  display: inline-flex;
  align-items: center;
  min-height: 36px;
  color: #94a3b8;
  font-size: 0.72rem;
  font-weight: 600;
  text-align: right;
}

.mobile-list {
  display: grid;
  gap: 10px;
  padding: 12px;
}

.mobile-card {
  padding: 14px;
  border: 1px solid #e2e8f0;
  border-radius: 15px;
  background: #ffffff;
}

.mobile-card.is-deleted {
  background: #fafafa;
}

.mobile-card-head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 10px;
}

.mobile-name {
  margin: 0;
  overflow: hidden;
  color: #0f172a;
  font-size: 0.9rem;
  font-weight: 800;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.mobile-id {
  margin: 2px 0 0;
  color: #64748b;
  font-size: 0.72rem;
  font-weight: 600;
}

.mobile-details {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 9px;
  margin-top: 12px;
  padding-top: 11px;
  border-top: 1px solid #f1f5f9;
}

.mobile-details span {
  display: block;
  color: #94a3b8;
  font-size: 0.62rem;
  font-weight: 700;
  letter-spacing: 0.04em;
  text-transform: uppercase;
}

.mobile-details strong {
  display: block;
  margin-top: 2px;
  overflow: hidden;
  color: #334155;
  font-size: 0.76rem;
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.mobile-deleted-note {
  margin: 11px 0 0;
  padding: 8px 10px;
  border: 1px solid #e2e8f0;
  border-radius: 9px;
  background: #f1f5f9;
  color: #64748b;
  font-size: 0.72rem;
  line-height: 1.45;
}

.mobile-actions {
  display: flex;
  gap: 7px;
  margin-top: 12px;
}

.mobile-actions .btn-row {
  flex: 1;
  min-height: 42px;
}

.dialog-field {
  display: grid;
  gap: 7px;
}

.dialog-field + .dialog-field {
  margin-top: 14px;
}

.dialog-field label {
  color: #334155;
  font-size: 0.8rem;
  font-weight: 700;
}

.dialog-field input,
.dialog-field textarea {
  width: 100%;
  min-height: 44px;
  padding: 10px 12px;
  border: 1px solid #d1d5db;
  border-radius: 11px;
  background: #ffffff;
  color: #0f172a;
  font: inherit;
  font-size: 16px;
  line-height: 1.45;
  outline: none;
}

.dialog-field textarea {
  min-height: 84px;
  resize: vertical;
}

.dialog-field input:focus,
.dialog-field textarea:focus {
  border-color: #0ea5e9;
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.14);
}

.dialog-field small {
  color: #64748b;
  font-size: 0.72rem;
  line-height: 1.4;
}

.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}

@media (min-width: 560px) {
  .banner-actions {
    flex-direction: row;
  }

  .filter-card {
    grid-template-columns: minmax(0, 1fr);
  }
}

@media (min-width: 640px) {
  .usuarios-page {
    gap: 22px;
  }

  .page-banner {
    flex-direction: row;
    align-items: center;
    justify-content: space-between;
    padding: 26px 28px;
  }

  .banner-copy h1 {
    font-size: 1.85rem;
  }

  .stats-grid {
    grid-template-columns: repeat(4, minmax(0, 1fr));
    gap: 14px;
  }

  .stat-card {
    padding: 16px;
  }

  .mobile-list {
    display: none;
  }

  .table-wrapper {
    display: block;
  }
}

@media (min-width: 1024px) {
  .page-banner {
    padding: 28px 32px;
  }

  .filter-card {
    grid-template-columns: minmax(260px, 1fr) auto;
    align-items: center;
  }

  .filter-chips {
    justify-content: flex-end;
  }
}

@media (prefers-reduced-motion: reduce) {
  .pulse-dot,
  .refresh-icon.spin,
  .spinner {
    animation: none;
  }
}
</style>
