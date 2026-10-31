/**
 * Validación y saneamiento centralizado de SIGAS.
 *
 * Reglas generales:
 *  - Los campos de nombres (personas, familias) aceptan solo letras, espacios,
 *    tildes, ñ, apóstrofo, punto y guion. Nunca números.
 *  - Los campos numéricos (cédula, teléfono, personas) aceptan solo dígitos.
 *  - Los campos de texto libre (dirección, observaciones, motivo) aceptan
 *    letras, números y puntuación básica, siempre con un límite de caracteres.
 *  - Todos los límites viven aquí para que formularios y base de datos
 *    trabajen con los mismos valores.
 */

export const LIMITS = Object.freeze({
  nombre: 120,
  familia: 120,
  calle: 80,
  ciclo: 80,
  cedula: 10,
  telefono: 12,
  personas: 2,
  email: 254,
  password: 72,
  passwordMin: 6,
  direccion: 200,
  observaciones: 300,
  motivo: 500,
  busqueda: 100,
  uuid: 36,
  codigo: 3,
})

// Letras Unicode (incluye tildes y ñ), espacios y signos habituales de nombres.
const RE_NOMBRE = /[^\p{L}\s'.-]/gu
// Texto libre: letras, números y puntuación básica. Bloquea emojis y símbolos raros.
const RE_TEXTO = /[^\p{L}\p{N}\s.,;:()#°ºª/'"+&%$@_!?¿¡\-]/gu
const RE_EMAIL = /[^a-zA-Z0-9@._%+-]/g
const RE_UUID = /[^0-9a-fA-F-]/g
const RE_DIGITOS = /\D/g
const RE_BUSQUEDA = /[<>{}[\]\\|^~`]/g

export function limitar(value, max) {
  return String(value ?? '').slice(0, Math.max(0, Number(max) || 0))
}

export function limpiarNombre(value, max = LIMITS.nombre) {
  return limitar(
    String(value ?? '')
      .replace(RE_NOMBRE, '')
      .replace(/[ \t]{2,}/g, ' '),
    max
  )
}

export function limpiarTexto(value, max = LIMITS.direccion) {
  return limitar(
    String(value ?? '')
      .replace(RE_TEXTO, '')
      .replace(/[ \t]{2,}/g, ' '),
    max
  )
}

export function limpiarEmail(value, max = LIMITS.email) {
  return limitar(
    String(value ?? '')
      .replace(/\s/g, '')
      .replace(RE_EMAIL, '')
      .toLowerCase(),
    max
  )
}

export function limpiarDigitos(value, max = LIMITS.cedula) {
  return limitar(String(value ?? '').replace(RE_DIGITOS, ''), max)
}

export function limpiarPassword(value, max = LIMITS.password) {
  // La contraseña admite cualquier carácter; solo se limita su longitud.
  return limitar(value, max)
}

export function limpiarUuid(value, max = LIMITS.uuid) {
  return limitar(
    String(value ?? '')
      .replace(RE_UUID, '')
      .toLowerCase(),
    max
  )
}

export function limpiarBusqueda(value, max = LIMITS.busqueda) {
  return limitar(String(value ?? '').replace(RE_BUSQUEDA, ''), max)
}

/**
 * Aplica el saneamiento correspondiente a un tipo de campo.
 * Tipos: nombre, texto, email, digitos, password, uuid, busqueda.
 */
export function limpiarPorTipo(value, tipo = 'texto', max) {
  switch (tipo) {
    case 'nombre':
      return limpiarNombre(value, max ?? LIMITS.nombre)
    case 'texto':
      return limpiarTexto(value, max ?? LIMITS.direccion)
    case 'email':
      return limpiarEmail(value, max ?? LIMITS.email)
    case 'digitos':
    case 'digits':
    case 'numero':
    case 'number':
      return limpiarDigitos(value, max ?? LIMITS.cedula)
    case 'password':
      return limpiarPassword(value, max ?? LIMITS.password)
    case 'uuid':
      return limpiarUuid(value, max ?? LIMITS.uuid)
    case 'busqueda':
      return limpiarBusqueda(value, max ?? LIMITS.busqueda)
    default:
      return limitar(value, max ?? LIMITS.direccion)
  }
}

export function esEmailValido(value) {
  const email = String(value ?? '').trim()
  if (!email || email.length > LIMITS.email) return false
  return /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(email)
}

export function esCodigoValido(value) {
  return /^[A-Z0-9]{3}$/.test(String(value ?? '').trim().toUpperCase())
}

function esVacio(value) {
  return String(value ?? '').trim() === ''
}

export function validarNombre(
  value,
  { label = 'El nombre', min = 2, max = LIMITS.nombre, required = true } = {}
) {
  const texto = String(value ?? '').trim()
  if (!texto) return required ? `${label} es obligatorio.` : ''
  if (texto.length < min) return `${label} debe tener al menos ${min} caracteres.`
  if (texto.length > max) return `${label} no puede superar los ${max} caracteres.`
  if (/\d/.test(texto)) return `${label} solo puede contener letras y espacios.`
  return ''
}

export function validarTexto(
  value,
  { label = 'El texto', min = 0, max = LIMITS.direccion, required = false } = {}
) {
  const texto = String(value ?? '').trim()
  if (!texto) return required ? `${label} es obligatorio.` : ''
  if (texto.length < min) return `${label} debe tener al menos ${min} caracteres.`
  if (texto.length > max) return `${label} no puede superar los ${max} caracteres.`
  return ''
}

export function validarCedula(
  value,
  { label = 'La cédula', min = 5, max = LIMITS.cedula, required = true } = {}
) {
  const texto = String(value ?? '').trim()
  if (!texto) return required ? `${label} es obligatoria.` : ''
  if (!/^\d+$/.test(texto)) return `${label} solo puede contener números.`
  if (texto.length < min) return `${label} debe tener al menos ${min} dígitos.`
  if (texto.length > max) return `${label} no puede superar los ${max} dígitos.`
  // familias.id es integer en PostgreSQL: evitamos desbordamientos.
  if (Number(texto) > 2147483647) return `${label} no es válida.`
  return ''
}

export function validarTelefono(
  value,
  { label = 'El teléfono', min = 7, max = LIMITS.telefono, required = false } = {}
) {
  const texto = String(value ?? '').trim()
  if (!texto) return required ? `${label} es obligatorio.` : ''
  if (!/^\d+$/.test(texto)) return `${label} solo puede contener números.`
  if (texto.length < min) return `${label} debe tener al menos ${min} dígitos.`
  if (texto.length > max) return `${label} no puede superar los ${max} dígitos.`
  return ''
}

export function validarEntero(
  value,
  { label = 'La cantidad', min = 1, max = 30, required = false } = {}
) {
  const texto = String(value ?? '').trim()
  if (!texto) return required ? `${label} es obligatoria.` : ''
  if (!/^\d+$/.test(texto)) return `${label} solo puede contener números.`
  const numero = Number(texto)
  if (!Number.isInteger(numero)) return `${label} debe ser un número entero.`
  if (numero < min) return `${label} debe ser mayor o igual a ${min}.`
  if (numero > max) return `${label} no puede ser mayor que ${max}.`
  return ''
}

export function validarEmail(value, { label = 'El correo electrónico' } = {}) {
  const email = String(value ?? '').trim()
  if (!email) return `${label} es obligatorio.`
  if (email.length > LIMITS.email) return `${label} no puede superar los ${LIMITS.email} caracteres.`
  if (!esEmailValido(email)) return `${label} no tiene un formato válido.`
  return ''
}

export function validarPassword(
  value,
  { label = 'La contraseña', min = LIMITS.passwordMin, max = LIMITS.password } = {}
) {
  const password = String(value ?? '')
  if (!password) return `${label} es obligatoria.`
  if (password.length < min) return `${label} debe tener al menos ${min} caracteres.`
  if (password.length > max) return `${label} no puede superar los ${max} caracteres.`
  return ''
}

export function validarUuid(value, { label = 'El ID de acceso', required = false } = {}) {
  const uuid = String(value ?? '').trim()
  if (!uuid) return required ? `${label} es obligatorio.` : ''
  const regex =
    /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
  if (!regex.test(uuid)) return `${label} debe ser un UUID válido de Supabase Auth.`
  return ''
}

export function validarCodigo(value, { label = 'El código' } = {}) {
  const codigo = String(value ?? '').trim().toUpperCase()
  if (!codigo) return `${label} es obligatorio.`
  if (!esCodigoValido(codigo)) return `${label} debe tener 3 caracteres alfanuméricos.`
  return ''
}

export function normalizarCodigo(value) {
  return String(value ?? '')
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, '')
    .slice(0, LIMITS.codigo)
}

export { esVacio }
