<template>
  <div class="admin-page">
    <!-- CABECERA BANNER CORPORATIVA -->
    <header class="header-banner">
      <div>
        <div class="badge">
          <span class="pulse-dot"></span>
          Gestión de Habitantes
        </div>
        <h1>Familias Registradas</h1>
        <p>Control y administración de núcleos familiares censados en el sistema</p>
      </div>
      <div class="header-actions">
        <button class="action-btn" @click="abrirModalCrear">+ Nueva Familia</button>
        <button class="refresh-btn" @click="cargarFamilias" :disabled="loading">
          <svg viewBox="0 0 24 24" class="icon" :class="{ spin: loading }">
            <path fill="currentColor" d="M12 4V1L8 5l4 4V6c3.31 0 6 2.69 6 6c0 1.01-.25 1.97-.7 2.8l1.46 1.46A7.93 7.93 0 0 0 20 12c0-4.42-3.58-8-8-8zm0 14c-3.31 0-6-2.69-6-6c0-1.01.25-1.97.7-2.8L5.24 7.74A7.93 7.93 0 0 0 4 12c0 4.42 3.58 8 8 8v3l4-4l-4-4v3z"/>
          </svg>
        </button>
      </div>
    </header>

    <div v-if="mensajeExito" class="alert alert--success" role="status">
      {{ mensajeExito }}
    </div>
    <div v-if="errorGeneral" class="alert alert--error" role="alert">
      {{ errorGeneral }}
    </div>

    <!-- TARJETA DE TABLA PRINCIPAL -->
    <div class="table-card">
      <div class="table-header">
        <div>
          <h2>Directorio Familiar</h2>
          <p>Listado general de familias y asignación por calles</p>
        </div>
        <div class="search-box">
          <svg class="search-icon" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
          </svg>
          <input
            v-model="filtroBusqueda"
            v-restrict="{ tipo: 'busqueda', max: 100 }"
            type="text"
            maxlength="100"
            placeholder="Buscar por Cédula, Código o Nombre..."
          />
        </div>
      </div>

      <div v-if="loading" class="loading-state">
        <div class="spinner"></div>
        <p>Cargando registros desde Supabase...</p>
      </div>

      <div v-else-if="familiasFiltradas.length === 0" class="empty-state">
        <p>No se encontraron familias registradas con esa búsqueda.</p>
      </div>

      <div v-else class="table-wrapper">
        <table class="custom-table">
          <thead>
            <tr>
              <th>Cédula (ID)</th>
              <th>Código</th>
              <th>Nombre de la Familia</th>
              <th>Jefe de Familia</th>
              <th>Calle / Sector</th>
              <th>Estado</th>
              <th>Acciones</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="familia in familiasFiltradas" :key="familia.id" class="table-row">
              <td class="id-cell" data-label="Cédula (ID)">V-{{ familia.id }}</td>
              <td data-label="Código">
                <span class="code-badge">{{ familia.codigo || '—' }}</span>
              </td>
              <td class="name-cell" data-label="Nombre de la familia">
                <div class="avatar">{{ familia.nombre_familia ? familia.nombre_familia.charAt(0).toUpperCase() : 'F' }}</div>
                <span class="family-name">{{ familia.nombre_familia || 'Sin nombre' }}</span>
              </td>
              <td data-label="Jefe de Familia">
                <template v-if="jefeDeFamilia(familia)">
                  <span class="jefe-name">{{ jefeDeFamilia(familia).nombre || 'Sin nombre' }}</span>
                  <span v-if="!jefeDeFamilia(familia).activo" class="jefe-status">
                    Pendiente de cuenta
                  </span>
                </template>
                <span v-else class="jefe-empty">Sin jefe registrado</span>
              </td>
              <td data-label="Calle / Sector">
                <span class="badge-calle">{{ obtenerNombreCalle(familia.id_calle) }}</span>
              </td>
              <td data-label="Estado">
                <span class="status-indicator" :class="{ active: familia.activo }">
                  <span class="status-dot"></span>
                  {{ familia.activo ? 'Activo' : 'Inactivo' }}
                </span>
              </td>
              <td data-label="Acciones" class="actions-cell">
                <button class="btn-jefe" @click="abrirModalJefe(familia)">
                  {{ jefeDeFamilia(familia) ? 'Editar Jefe' : 'Asignar Jefe' }}
                </button>
                <button class="btn-edit" @click="abrirModalEditar(familia)">
                   Editar
                </button>
                <button class="btn-delete" @click="confirmarEliminacion(familia)">
                   Eliminar
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <!-- MODAL CREAR / EDITAR FAMILIA -->
    <div v-if="mostrarModal" class="modal-overlay" @click.self="cerrarModal">
      <div class="modal-card" role="dialog" aria-modal="true">
        <span class="modal-sheet-handle" aria-hidden="true"></span>
        <h3>{{ esEdicion ? 'Editar Familia' : 'Registrar Nueva Familia' }}</h3>
        
        <form @submit.prevent="guardarFamilia" class="modal-form" novalidate>
          <div v-if="!esEdicion" class="field">
            <label class="field-label">Cédula de la Familia</label>
            <input
              v-model="form.id"
              v-restrict="{ tipo: 'digits', max: 10 }"
              type="text"
              inputmode="numeric"
              pattern="[0-9]*"
              minlength="5"
              maxlength="10"
              placeholder="Ej: 12345678"
              required
              class="input-field"
            />
            <small class="field-hint">Solo números, entre 5 y 10 dígitos.</small>
          </div>

          <div v-else class="field">
            <label class="field-label">Cédula de la Familia</label>
            <input :value="form.id" type="text" class="input-field" disabled />
          </div>

          <div v-if="esEdicion" class="field">
            <label class="field-label">Código único</label>
            <input :value="form.codigo || '—'" type="text" class="input-field code-input" disabled />
          </div>

          <div class="field">
            <label class="field-label">Nombre de la Familia</label>
            <input
              v-model="form.nombre_familia"
              v-restrict="{ tipo: 'nombre', max: 120 }"
              type="text"
              placeholder="Ej: Familia Angarita"
              maxlength="120"
              required
              class="input-field"
            />
            <small class="field-hint">Solo letras y espacios, máximo 120 caracteres.</small>
          </div>

          <div class="field">
            <label class="field-label">Calle / Sector</label>
            <select v-model="form.id_calle" class="input-field select-field" required>
              <option :value="null" disabled>Selecciona una calle</option>
              <option v-for="calle in calles" :key="calle.id_calle" :value="calle.id_calle">
                {{ calle.nombre }}
              </option>
            </select>
          </div>

          <div v-if="esEdicion" class="field flex-row">
            <label class="field-label">Familia Activa:</label>
            <input type="checkbox" v-model="form.activo" class="checkbox-input" />
          </div>

          <p v-if="formError" class="form-error" role="alert">{{ formError }}</p>

          <div class="btn-group">
            <button type="submit" class="button1" :disabled="guardando">
              {{ guardando ? 'Guardando...' : (esEdicion ? 'Actualizar' : 'Guardar') }}
            </button>
            <button type="button" class="button2" @click="cerrarModal">Cancelar</button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL ASIGNAR / EDITAR JEFE DE FAMILIA -->
    <div v-if="mostrarModalJefe" class="modal-overlay" @click.self="cerrarModalJefe">
      <div class="modal-card" role="dialog" aria-modal="true">
        <span class="modal-sheet-handle" aria-hidden="true"></span>
        <h3>{{ jefeEditando ? 'Editar Jefe de Familia' : 'Asignar Jefe de Familia' }}</h3>
        <p class="modal-subtitle">
          {{ familiaJefeSeleccionada?.nombre_familia || 'Familia' }}
          — V-{{ familiaJefeSeleccionada?.id }}
        </p>

        <form @submit.prevent="guardarJefeFamilia" class="modal-form" novalidate>
          <div class="field">
            <label class="field-label">Nombre del Jefe de Familia</label>
            <input
              v-model="jefeForm.nombre"
              v-restrict="{ tipo: 'nombre', max: 120 }"
              type="text"
              maxlength="120"
              placeholder="Ej: María Pérez"
              required
              class="input-field"
            />
          </div>

          <div class="field">
            <label class="field-label">Cédula</label>
            <input
              :value="familiaJefeSeleccionada?.id || ''"
              type="text"
              class="input-field"
              disabled
            />
            <small class="field-hint">La cédula identifica a la familia en SIGAS.</small>
          </div>

          <div class="field">
            <label class="field-label">Teléfono</label>
            <input
              v-model="jefeForm.telefono"
              v-restrict="{ tipo: 'digits', max: 12 }"
              type="tel"
              inputmode="numeric"
              maxlength="12"
              placeholder="04141234567"
              class="input-field"
            />
          </div>

          <div class="field">
            <label class="field-label">Correo electrónico</label>
            <input
              v-model="jefeForm.email"
              v-restrict="{ tipo: 'email', max: 254 }"
              type="email"
              maxlength="254"
              placeholder="correo@ejemplo.com"
              required
              class="input-field"
            />
            <small class="field-hint">
              La persona debe registrarse en el login con este mismo correo.
            </small>
          </div>

          <p v-if="jefeEditando && !jefeEditando.activo" class="jefe-modal-note">
            Este Jefe de Familia está <strong>pendiente de cuenta</strong>. La persona debe
            registrarse desde el login con la cédula V-{{ familiaJefeSeleccionada?.id }} y este
            correo. Luego podrás aprobarlo desde el panel del Jefe de Calle.
          </p>
          <p v-else-if="jefeEditando" class="jefe-modal-note jefe-modal-note--ok">
            Cuenta de acceso vinculada. Los cambios de nombre, teléfono y correo son solo de
            contacto; no cambian la contraseña de la persona.
          </p>

          <p v-if="jefeFormError" class="form-error" role="alert">{{ jefeFormError }}</p>

          <div class="btn-group">
            <button type="submit" class="button1" :disabled="jefeGuardando">
              {{ jefeGuardando ? 'Guardando...' : (jefeEditando ? 'Guardar cambios' : 'Asignar Jefe') }}
            </button>
            <button type="button" class="button2" :disabled="jefeGuardando" @click="cerrarModalJefe">
              Cancelar
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../../composables/supabase.js'
import {
  validarCedula,
  validarEmail,
  validarNombre,
  validarTelefono,
} from '../../lib/validation.js'

const familias = ref([])
const calles = ref([])
const jefesFamilia = ref([])
const filtroBusqueda = ref('')
const loading = ref(true)
const guardando = ref(false)
const mensajeExito = ref('')
const errorGeneral = ref('')
let exitoTimer = null

// Modales y estado de formulario
const mostrarModal = ref(false)
const esEdicion = ref(false)
const familiaIdSeleccionada = ref(null)
const formError = ref('')

const form = ref({
  id: '',
  codigo: '',
  nombre_familia: '',
  id_calle: null,
  activo: true
})

// Modal para asignar / editar al Jefe de Familia
const mostrarModalJefe = ref(false)
const jefeEditando = ref(null)
const familiaJefeSeleccionada = ref(null)
const jefeFormError = ref('')
const jefeGuardando = ref(false)
const jefeForm = ref({
  nombre: '',
  telefono: '',
  email: '',
})

const jefesPorFamilia = computed(() => {
  const mapa = new Map()
  for (const jefe of jefesFamilia.value) {
    const clave = Number(jefe.id_familia)
    const actual = mapa.get(clave)
    if (!actual) {
      mapa.set(clave, jefe)
      continue
    }
    if (jefe.activo && !actual.activo) {
      mapa.set(clave, jefe)
      continue
    }
    if (
      Boolean(jefe.activo) === Boolean(actual.activo) &&
      new Date(jefe.created_at || 0) > new Date(actual.created_at || 0)
    ) {
      mapa.set(clave, jefe)
    }
  }
  return mapa
})

function jefeDeFamilia(familia) {
  if (!familia) return null
  return jefesPorFamilia.value.get(Number(familia.id)) || null
}

function abrirModalJefe(familia) {
  const jefe = jefeDeFamilia(familia)
  familiaJefeSeleccionada.value = familia
  jefeEditando.value = jefe || null
  jefeFormError.value = ''
  jefeForm.value = {
    nombre: jefe?.nombre || familia.nombre_familia || '',
    telefono: jefe?.telefono || familia.telefono || '',
    email: familia.email || '',
  }
  mostrarModalJefe.value = true
}

function cerrarModalJefe() {
  if (jefeGuardando.value) return
  mostrarModalJefe.value = false
  jefeEditando.value = null
  familiaJefeSeleccionada.value = null
}

function esRpcInexistente(error) {
  if (!error) return false
  const codigo = String(error.code || '')
  const mensaje = String(error.message || error.details || '')
  return (
    codigo === 'PGRST202' ||
    /could not find the function|function .* does not exist|schema cache/i.test(mensaje)
  )
}

async function actualizarJefeFallback(familia, nombre, telefono, email) {
  const { error: jefeError } = await supabase
    .from('jefes_familia')
    .update({
      nombre,
      telefono: telefono || null,
      updated_at: new Date().toISOString(),
    })
    .eq('id_jefe_familia', jefeEditando.value.id_jefe_familia)

  if (jefeError) throw jefeError

  const { error: familiaError } = await supabase
    .from('familias')
    .update({
      email,
      updated_at: new Date().toISOString(),
    })
    .eq('id', familia.id)

  if (familiaError) throw familiaError
}

async function registrarJefeFallback(familia, nombre, telefono, email) {
  const { data: jefeExistente, error: consultaError } = await supabase
    .from('jefes_familia')
    .select('*')
    .eq('id_familia', familia.id)
    .eq('is_deleted', false)
    .order('activo', { ascending: false })
    .order('created_at', { ascending: false })
    .limit(1)
    .maybeSingle()

  if (consultaError) throw consultaError
  if (jefeExistente?.activo) {
    throw new Error('La familia ya tiene un Jefe de Familia activo.')
  }

  const datosJefe = {
    id_familia: familia.id,
    // Conserva la cuenta ya vinculada, si existe, al reemplazar los datos.
    auth_id: jefeExistente?.auth_id ?? null,
    id_calle: familia.id_calle,
    nombre,
    ci: String(familia.id),
    telefono: telefono || null,
    activo: false,
    estado: 'pendiente',
    is_deleted: false,
  }

  if (jefeExistente) {
    const { error: updateError } = await supabase
      .from('jefes_familia')
      .update(datosJefe)
      .eq('id_jefe_familia', jefeExistente.id_jefe_familia)
    if (updateError) throw updateError
  } else {
    const { error: insertError } = await supabase
      .from('jefes_familia')
      .insert([datosJefe])
    if (insertError) throw insertError
  }

  if (email) {
    const { error: familiaError } = await supabase
      .from('familias')
      .update({
        email,
        updated_at: new Date().toISOString(),
      })
      .eq('id', familia.id)
      .is('auth_id', null)

    if (familiaError) throw familiaError
  }
}

async function guardarJefeFamilia() {
  jefeFormError.value = ''

  const familia = familiaJefeSeleccionada.value
  if (!familia) {
    jefeFormError.value = 'No se identificó la familia.'
    return
  }

  const nombre = jefeForm.value.nombre.trim()
  const telefono = jefeForm.value.telefono.trim()
  const email = jefeForm.value.email.trim()

  const errores = [
    validarNombre(nombre, { label: 'El nombre del Jefe de Familia', max: 120 }),
    validarTelefono(telefono, {
      label: 'El teléfono',
      required: false,
      min: 7,
      max: 12,
    }),
    validarEmail(email, { label: 'El correo electrónico' }),
  ]

  const primerError = errores.find(Boolean)
  if (primerError) {
    jefeFormError.value = primerError
    return
  }

  jefeGuardando.value = true
  let mensaje = ''

  try {
    if (jefeEditando.value) {
      const { error } = await supabase.rpc('actualizar_jefe_familia', {
        p_id_jefe_familia: jefeEditando.value.id_jefe_familia,
        p_nombre: nombre,
        p_telefono: telefono || null,
        p_email: email,
      })

      if (error) {
        if (!esRpcInexistente(error)) throw error
        await actualizarJefeFallback(familia, nombre, telefono, email)
      }

      mensaje = 'Jefe de Familia actualizado correctamente.'
    } else {
      const { error } = await supabase.rpc('registrar_jefe_familia', {
        p_id_familia: familia.id,
        p_nombre: nombre,
        p_telefono: telefono || null,
        p_email: email,
        p_auth_id: null,
      })

      if (error) {
        if (!esRpcInexistente(error)) throw error
        await registrarJefeFallback(familia, nombre, telefono, email)
      }

      mensaje = `Jefe de Familia asignado. La persona debe registrarse en el login con la cédula V-${familia.id} y el correo ${email}.`
    }
  } catch (err) {
    jefeFormError.value = mensajeError(
      err,
      jefeEditando.value
        ? 'No se pudo actualizar el Jefe de Familia.'
        : 'No se pudo asignar el Jefe de Familia.'
    )
    return
  } finally {
    jefeGuardando.value = false
  }

  mostrarModalJefe.value = false
  jefeEditando.value = null
  familiaJefeSeleccionada.value = null
  mostrarExito(mensaje)
  await cargarFamilias()
}

async function cargarFamilias() {
  loading.value = true
  errorGeneral.value = ''
  try {
    const { data: callesData } = await supabase
      .from('calles')
      .select('*')
      .eq('is_deleted', false)
      .order('nombre')
    if (callesData) calles.value = callesData

    const { data, error } = await supabase
      .from('familias')
      .select('*')
      .eq('is_deleted', false)
      .order('id', { ascending: true })
    if (!error && data) {
      familias.value = data
    }

    const { data: jefesData, error: jefesError } = await supabase
      .from('jefes_familia')
      .select('*')
      .eq('is_deleted', false)

    if (!jefesError && jefesData) {
      jefesFamilia.value = jefesData
    } else if (jefesError) {
      console.warn('[SIGAS] No se pudieron cargar los Jefes de Familia:', jefesError)
    }
  } catch (e) {
    console.error('Error cargando familias:', e)
    errorGeneral.value = 'No se pudieron cargar las familias. Intenta nuevamente.'
  } finally {
    loading.value = false
  }
}

function abrirModalCrear() {
  esEdicion.value = false
  familiaIdSeleccionada.value = null
  formError.value = ''
  form.value = { id: '', codigo: '', nombre_familia: '', id_calle: null, activo: true }
  mostrarModal.value = true
}

function abrirModalEditar(familia) {
  esEdicion.value = true
  familiaIdSeleccionada.value = familia.id
  formError.value = ''
  form.value = {
    id: familia.id,
    codigo: familia.codigo || '',
    nombre_familia: familia.nombre_familia,
    id_calle: familia.id_calle,
    activo: familia.activo
  }
  mostrarModal.value = true
}

function cerrarModal() {
  if (guardando.value) return
  mostrarModal.value = false
}

function mostrarExito(mensaje) {
  mensajeExito.value = mensaje
  if (exitoTimer) window.clearTimeout(exitoTimer)
  exitoTimer = window.setTimeout(() => {
    mensajeExito.value = ''
  }, 6000)
}

function mensajeError(err, fallback) {
  const mensaje = String(err?.message || err?.details || '')
  if (/duplicate key/i.test(mensaje)) {
    return 'Ya existe una familia registrada con esa cédula.'
  }
  if (/No tienes permiso|42501|row-level security/i.test(mensaje)) {
    return 'No tienes permisos para gestionar familias.'
  }
  return mensaje || fallback
}

async function guardarFamilia() {
  formError.value = ''
  errorGeneral.value = ''

  const nombreError = validarNombre(form.value.nombre_familia, {
    label: 'El nombre de la familia',
    max: 120,
  })
  if (nombreError) {
    formError.value = nombreError
    return
  }

  if (!form.value.id_calle) {
    formError.value = 'Selecciona la calle o sector de la familia.'
    return
  }

  if (!esEdicion.value) {
    const cedulaError = validarCedula(form.value.id, {
      label: 'La cédula de la familia',
      min: 5,
      max: 10,
    })
    if (cedulaError) {
      formError.value = cedulaError
      return
    }
    if (Number(form.value.id) <= 0) {
      formError.value = 'La cédula de la familia no es válida.'
      return
    }
  }

  guardando.value = true

  if (esEdicion.value) {
    const { error } = await supabase
      .from('familias')
      .update({
        nombre_familia: form.value.nombre_familia.trim(),
        id_calle: form.value.id_calle,
        activo: form.value.activo
      })
      .eq('id', familiaIdSeleccionada.value)

    if (!error) {
      cerrarModal()
      mostrarExito('Familia actualizada correctamente.')
      await cargarFamilias()
    } else {
      formError.value = mensajeError(error, 'No se pudo actualizar la familia.')
    }
  } else {
    const { data, error } = await supabase
      .from('familias')
      .insert([{
        id: Number(form.value.id),
        nombre_familia: form.value.nombre_familia.trim(),
        id_calle: form.value.id_calle,
        id_cargo: 3,
        estado: 'aprobado',
        activo: true,
        is_deleted: false,
      }])
      .select()
      .single()

    if (!error) {
      cerrarModal()
      mostrarExito(
        data?.codigo
          ? `Familia registrada correctamente. Su código único es ${data.codigo}.`
          : 'Familia registrada correctamente.'
      )
      await cargarFamilias()
    } else {
      formError.value = mensajeError(error, 'No se pudo registrar la familia.')
    }
  }

  guardando.value = false
}

async function confirmarEliminacion(familia) {
  const confirmacion = confirm(`¿Estás seguro de que deseas eliminar la familia "${familia.nombre_familia}"?`)
  
  if (confirmacion) {
    const { error } = await supabase
      .from('familias')
      .delete()
      .eq('id', familia.id)

    if (error) {
      alert('No se pudo eliminar el registro. Es posible que tenga pedidos asociados en la base de datos.')
      console.error('Error al eliminar:', error.message)
    } else {
      cargarFamilias()
    }
  }
}

function obtenerNombreCalle(idCalle) {
  const c = calles.value.find((item) => item.id_calle === idCalle)
  return c ? c.nombre : `Calle ID ${idCalle}`
}

onMounted(cargarFamilias)

const familiasFiltradas = computed(() => {
  if (!filtroBusqueda.value.trim()) return familias.value
  const query = filtroBusqueda.value.toLowerCase().trim()
  return familias.value.filter(
    (f) =>
      String(f.id).includes(query) ||
      String(f.codigo || '').toLowerCase().includes(query) ||
      (f.nombre_familia && f.nombre_familia.toLowerCase().includes(query))
  )
})
</script>

<style scoped>
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap');

.admin-page { 
  font-family: 'Plus Jakarta Sans', sans-serif; 
  color: #0f172a; 
  padding: 0;
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
  background-color: transparent !important;
  min-height: 0;
  box-sizing: border-box;
}

.header-banner { 
  background: #ffffff; 
  border: 1px solid #e2e8f0; 
  border-left: 6px solid #0072CE; 
  border-radius: 18px; 
  padding: 2rem 2.2rem; 
  display: flex; 
  justify-content: space-between; 
  align-items: center; 
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.04);
}

.badge { 
  display: inline-flex; 
  align-items: center; 
  gap: 8px; 
  background: #eff6ff; 
  color: #0072CE; 
  border: 1px solid #dbeafe; 
  padding: 5px 12px; 
  border-radius: 20px; 
  font-size: 0.75rem; 
  font-weight: 600; 
  margin-bottom: 0.5rem; 
}

.pulse-dot {
  width: 7px;
  height: 7px;
  background-color: #0072CE;
  border-radius: 50%;
  animation: pulse 2s infinite;
}

@keyframes pulse {
  0% { transform: scale(0.95); opacity: 0.8; }
  50% { transform: scale(1.3); opacity: 1; }
  100% { transform: scale(0.95); opacity: 0.8; }
}

.header-banner h1 { 
  margin: 0; 
  font-size: 1.8rem; 
  font-weight: 700; 
  color: #0f172a; 
  letter-spacing: -0.02em; 
}

.header-banner p { 
  margin: 0.3rem 0 0 0; 
  color: #64748b; 
  font-size: 0.9rem; 
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 10px;
}

.action-btn { 
  display: flex;
  align-items: center;
  gap: 8px;
  background: #0072CE; 
  color: #ffffff; 
  border: none; 
  padding: 0.75rem 1.4rem; 
  border-radius: 12px; 
  font-weight: 600; 
  font-size: 0.88rem;
  cursor: pointer; 
  transition: all 0.2s ease;
  box-shadow: 0 1px 2px 0 rgba(0, 0, 0, 0.05);
}

.action-btn:hover:not(:disabled) { 
  background: #005aa3; 
  transform: translateY(-1px); 
}

.refresh-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f1f5f9;
  color: #475569;
  border: 1px solid #cbd5e1;
  padding: 0.75rem;
  border-radius: 12px;
  cursor: pointer;
  transition: all 0.2s ease;
}

.refresh-btn:hover:not(:disabled) {
  background: #e2e8f0;
  color: #0f172a;
}

.refresh-btn .icon {
  width: 18px;
  height: 18px;
}

.refresh-btn .icon.spin {
  animation: spin 1s linear infinite;
}

@keyframes spin { 
  100% { transform: rotate(360deg); } 
}

.table-card { 
  background: #ffffff; 
  border: 1px solid #e2e8f0; 
  border-radius: 18px; 
  padding: 1.6rem; 
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.03); 
}

.table-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 1.5rem;
  flex-wrap: wrap;
  gap: 1rem;
}

.table-header h2 {
  margin: 0;
  font-size: 1.25rem;
  font-weight: 700;
  color: #0f172a;
}

.table-header p {
  margin: 0.2rem 0 0 0;
  font-size: 0.85rem;
  color: #64748b;
}

.search-box {
  position: relative;
  width: 100%;
  max-width: 300px;
}

.search-box input {
  width: 100%;
  background: #f8fafc;
  border: 1px solid #cbd5e1;
  padding: 0.65rem 1rem 0.65rem 2.4rem;
  border-radius: 10px;
  color: #0f172a;
  outline: none;
  font-family: 'Plus Jakarta Sans', sans-serif;
  font-size: 0.85rem;
  transition: all 0.2s ease;
}

.search-box input::placeholder {
  color: #94a3b8;
}

.search-box input:focus {
  border-color: #0072CE;
  background: #ffffff;
  box-shadow: 0 0 0 3px rgba(0, 114, 206, 0.1);
}

.search-icon {
  position: absolute;
  left: 10px;
  top: 50%;
  transform: translateY(-50%);
  width: 16px;
  height: 16px;
  color: #94a3b8;
}

.table-wrapper { 
  overflow-x: auto; 
}

.custom-table { 
  width: 100%; 
  border-collapse: collapse; 
  text-align: left; 
}

.custom-table th { 
  padding: 0.85rem 1rem; 
  font-size: 0.72rem; 
  text-transform: uppercase; 
  letter-spacing: 0.05em; 
  color: #64748b; 
  background-color: #f8fafc;
  border-bottom: 1px solid #e2e8f0; 
  font-weight: 600; 
}

.custom-table td { 
  padding: 1rem; 
  border-bottom: 1px solid #f1f5f9; 
  font-size: 0.88rem; 
  color: #334155; 
}

.table-row { 
  transition: background-color 0.15s ease; 
}

.table-row:hover { 
  background-color: #f8fafc; 
}

.id-cell { 
  font-weight: 600; 
  color: #0072CE; 
}

.code-badge {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 48px;
  padding: 4px 9px;
  border: 1px solid #bae6fd;
  border-radius: 7px;
  background: #f0f9ff;
  color: #0369a1;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-size: 0.78rem;
  font-weight: 700;
  letter-spacing: 0.08em;
}

.code-input {
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-weight: 700;
  letter-spacing: 0.12em;
  color: #0369a1;
}

.field-hint {
  display: block;
  margin-top: 4px;
  color: #94a3b8;
  font-size: 0.72rem;
}

.form-error {
  margin: 0;
  padding: 9px 12px;
  border: 1px solid #fecaca;
  border-radius: 9px;
  background: #fef2f2;
  color: #b91c1c;
  font-size: 0.8rem;
  line-height: 1.4;
}

.alert {
  padding: 12px 16px;
  border-radius: 12px;
  font-size: 0.86rem;
  font-weight: 500;
  line-height: 1.45;
}

.alert--success {
  border: 1px solid #a7f3d0;
  background: #ecfdf5;
  color: #047857;
}

.alert--error {
  border: 1px solid #fecaca;
  background: #fef2f2;
  color: #b91c1c;
}

.name-cell {
  display: flex;
  align-items: center;
  gap: 10px;
}

.family-name {
  font-weight: 500;
  color: #0f172a;
}

.avatar {
  width: 32px;
  height: 32px;
  background-color: #eff6ff;
  color: #0072CE;
  font-weight: 700;
  border-radius: 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 0.8rem;
}

.badge-calle { 
  background: #f1f5f9; 
  color: #475569; 
  border: 1px solid #e2e8f0; 
  padding: 4px 10px; 
  border-radius: 6px; 
  font-size: 0.8rem; 
  font-weight: 500; 
}

.jefe-name {
  display: block;
  color: #0f172a;
  font-size: 0.84rem;
  font-weight: 600;
  line-height: 1.35;
}

.jefe-status {
  display: block;
  margin-top: 2px;
  color: #b45309;
  font-size: 0.7rem;
  font-weight: 600;
}

.jefe-empty {
  color: #94a3b8;
  font-size: 0.8rem;
  font-style: italic;
}

.status-indicator {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 0.75rem;
  font-weight: 600;
  background: #fef2f2;
  color: #dc2626;
  border: 1px solid #fecaca;
}

.status-indicator.active {
  background: #ecfdf5;
  color: #059669;
  border-color: #a7f3d0;
}

.status-dot {
  width: 6px;
  height: 6px;
  background-color: currentColor;
  border-radius: 50%;
}

/* ==========================================================================
   BOTONES DE ACCIÓN (ELEGANTES Y SUTILES)
   ========================================================================== */
.actions-cell {
  display: flex;
  align-items: center;
  gap: 8px;
}

.btn-edit {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  background-color: #f0f9ff;
  color: #0284c7;
  border: 1px solid #bae6fd;
  padding: 5px 11px;
  border-radius: 8px;
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-edit:hover {
  background-color: #0284c7;
  color: #ffffff;
  border-color: #0284c7;
  box-shadow: 0 2px 6px rgba(2, 132, 199, 0.25);
}

.btn-delete {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  background-color: #fef2f2;
  color: #dc2626;
  border: 1px solid #fecaca;
  padding: 5px 11px;
  border-radius: 8px;
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-delete:hover {
  background-color: #dc2626;
  color: #ffffff;
  border-color: #dc2626;
  box-shadow: 0 2px 6px rgba(220, 38, 38, 0.25);
}

.btn-jefe {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  background-color: #f5f3ff;
  color: #6d28d9;
  border: 1px solid #ddd6fe;
  padding: 5px 11px;
  border-radius: 8px;
  font-size: 0.8rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s ease;
}

.btn-jefe:hover {
  background-color: #6d28d9;
  color: #ffffff;
  border-color: #6d28d9;
  box-shadow: 0 2px 6px rgba(109, 40, 217, 0.25);
}

/* ESTILOS DEL MODAL */
.field-label {
  font-size: 0.85rem;
  color: #475569;
  font-weight: 500;
  margin-bottom: 0.3rem;
  display: block;
}

.select-field {
  width: 100%;
  padding: 0.75rem 1rem;
  border-radius: 10px;
  background: #f8fafc;
  color: #0f172a;
  border: 1px solid #cbd5e1;
  font-family: 'Plus Jakarta Sans', sans-serif;
  font-size: 0.9rem;
  outline: none;
}

.select-field:focus {
  border-color: #0072CE;
  background: #ffffff;
  box-shadow: 0 0 0 3px rgba(0, 114, 206, 0.1);
}

.flex-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.checkbox-input {
  width: 18px;
  height: 18px;
  cursor: pointer;
}

.loading-state, .empty-state { 
  text-align: center; 
  padding: 3rem; 
  color: #64748b; 
}

.spinner { 
  width: 32px; 
  height: 32px; 
  border: 3px solid #e2e8f0; 
  border-top-color: #0072CE; 
  border-radius: 50%; 
  animation: spin 1s infinite linear; 
  margin: 0 auto 1rem auto; 
}

.modal-overlay { 
  position: fixed; 
  inset: 0; 
  background: rgba(0, 0, 0, 0.5); 
  display: flex; 
  justify-content: center; 
  align-items: center; 
  z-index: 100; 
  backdrop-filter: blur(4px); 
}

.modal-card { 
  background: #ffffff; 
  padding: 2rem; 
  border-radius: 20px; 
  width: 400px; 
  border: 1px solid #e2e8f0; 
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1); 
}

.modal-card h3 {
  margin-top: 0;
  color: #0f172a;
  font-size: 1.25rem;
  font-weight: 600;
  margin-bottom: 1.25rem;
  text-align: center;
}

.modal-subtitle {
  margin: -0.85rem 0 1.25rem;
  color: #64748b;
  font-size: 0.85rem;
  font-weight: 500;
  text-align: center;
}

.jefe-modal-note {
  margin: 0;
  padding: 10px 13px;
  border: 1px solid #fde68a;
  border-radius: 10px;
  background: #fffbeb;
  color: #92400e;
  font-size: 0.78rem;
  line-height: 1.5;
}

.jefe-modal-note--ok {
  border-color: #bbf7d0;
  background: #f0fdf4;
  color: #166534;
}

.modal-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.field { 
  margin-bottom: 0.5rem; 
}

.input-field { 
  width: 100%; 
  padding: 0.75rem 1rem; 
  border-radius: 10px; 
  background: #f8fafc; 
  border: 1px solid #cbd5e1; 
  color: #0f172a; 
  outline: none; 
  font-family: 'Plus Jakarta Sans', sans-serif;
  font-size: 0.9rem;
  transition: all 0.2s ease;
}

.input-field:focus {
  border-color: #0072CE;
  background: #ffffff;
  box-shadow: 0 0 0 3px rgba(0, 114, 206, 0.1);
}

.btn-group { 
  display: flex; 
  gap: 10px; 
  margin-top: 0.5rem;
}

.button1 { 
  flex: 1; 
  padding: 0.75rem; 
  border-radius: 10px; 
  border: none; 
  background: #0072CE; 
  color: white; 
  font-weight: 600; 
  font-size: 0.9rem;
  cursor: pointer; 
  transition: background 0.2s ease;
}

.button1:hover {
  background: #005aa3;
}

.button2 { 
  flex: 1; 
  padding: 0.75rem; 
  border-radius: 10px; 
  border: 1px solid #cbd5e1; 
  background: #ffffff; 
  color: #475569; 
  font-weight: 600;
  font-size: 0.9rem;
  cursor: pointer; 
  transition: all 0.2s ease;
}

.button2:hover {
  background: #f1f5f9;
  color: #0f172a;
}

/* RESPONSIVE */
@media (max-width: 639.98px) {
  .header-banner {
    flex-direction: column;
    align-items: stretch;
    gap: 16px;
    padding: 18px 16px;
    border-left-width: 4px;
  }

  .header-banner h1 {
    font-size: 1.35rem;
  }

  .header-actions {
    flex-direction: column;
    width: 100%;
  }

  .action-btn, .refresh-btn {
    justify-content: center;
    width: 100%;
    min-height: 44px;
  }

  .table-card {
    padding: 14px;
    border-radius: 16px;
  }

  .table-header {
    flex-direction: column;
    align-items: stretch;
    margin-bottom: 1rem;
  }

  .search-box {
    max-width: none;
  }

  .search-box input {
    min-height: 44px;
    font-size: 16px;
  }

  .name-cell {
    gap: 8px;
  }

  .modal-overlay {
    align-items: flex-end;
    padding: 0;
  }

  .modal-card {
    width: 100%;
    border-radius: 20px 20px 0 0;
  }

  .btn-group {
    flex-direction: column;
  }
}

@media (min-width: 640px) {
  .admin-page {
    gap: 1.5rem;
  }

  .header-banner {
    padding: 1.7rem 1.9rem;
  }

  .table-card {
    padding: 1.4rem;
  }

  .action-btn {
    min-height: 40px;
  }

  .modal-overlay {
    align-items: center;
  }

  .modal-card {
    width: 400px;
    border-radius: 18px;
  }
}

@media (min-width: 1024px) {
  .admin-page {
    gap: 1.75rem;
  }

  .header-banner h1 {
    font-size: 1.8rem;
  }

  .table-card {
    padding: 1.6rem;
  }
}
</style>