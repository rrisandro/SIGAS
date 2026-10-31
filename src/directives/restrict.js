import { LIMITS, limpiarPorTipo } from '../lib/validation.js'

/**
 * Directiva global v-restrict.
 *
 * Uso:
 *   <input v-model="nombre" v-restrict="'nombre'" />
 *   <input v-model="cedula" v-restrict="{ tipo: 'digitos', max: 10 }" />
 *
 * Aplica el saneamiento al escribir o pegar, fija maxlength y avisa a v-model
 * mediante un evento input cuando el valor cambia.
 */
function resolverConfig(valor) {
  if (typeof valor === 'string') return { tipo: valor }
  return valor && typeof valor === 'object' ? valor : {}
}

function aplicarConfig(el, valor) {
  const config = resolverConfig(valor)
  const tipo = config.tipo || 'texto'
  const max = Number(config.max ?? LIMITS[tipo] ?? LIMITS.direccion)

  el._sigasRestrict = { tipo, max: Number.isFinite(max) && max > 0 ? max : LIMITS.direccion }
  el.setAttribute('maxlength', String(el._sigasRestrict.max))
}

function limpiarElemento(el) {
  const config = el._sigasRestrict
  if (!config) return

  const limpio = limpiarPorTipo(el.value, config.tipo, config.max)
  if (limpio === el.value) return

  const inicio = typeof el.selectionStart === 'number' ? el.selectionStart : limpio.length
  const fin = typeof el.selectionEnd === 'number' ? el.selectionEnd : limpio.length

  el.value = limpio

  if (typeof el.setSelectionRange === 'function') {
    const posicion = Math.min(inicio, limpio.length)
    const posicionFin = Math.min(fin, limpio.length)
    try {
      el.setSelectionRange(posicion, posicionFin)
    } catch {
      // Algunos tipos de input no soportan setSelectionRange.
    }
  }

  // Notifica a v-model con el valor ya saneado.
  el.dispatchEvent(new Event('input', { bubbles: true }))
}

function manejarInput(event) {
  limpiarElemento(event.currentTarget)
}

function manejarBlur(event) {
  const el = event.currentTarget
  const config = el._sigasRestrict
  if (!config || config.tipo === 'password') return

  const recortado = String(el.value ?? '').trim()
  if (recortado === el.value) return

  el.value = recortado
  el.dispatchEvent(new Event('input', { bubbles: true }))
}

export const restrict = {
  mounted(el, binding) {
    aplicarConfig(el, binding.value)
    el._sigasInputHandler = manejarInput
    el._sigasBlurHandler = manejarBlur
    el.addEventListener('input', manejarInput)
    el.addEventListener('blur', manejarBlur)
  },
  updated(el, binding) {
    aplicarConfig(el, binding.value)
  },
  unmounted(el) {
    if (el._sigasInputHandler) el.removeEventListener('input', el._sigasInputHandler)
    if (el._sigasBlurHandler) el.removeEventListener('blur', el._sigasBlurHandler)
    delete el._sigasRestrict
    delete el._sigasInputHandler
    delete el._sigasBlurHandler
  },
}
