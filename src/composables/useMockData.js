// ============================================
// COMPOSABLE: useMockData
// Datos simulados reactivos (singleton)
// ============================================

import { ref } from 'vue'

const calles = ref([
  { id: 1, nombre: 'Calle 1 de Mayo', sector: 'Sector Norte', activo: true },
  { id: 2, nombre: 'Calle Bolívar', sector: 'Sector Norte', activo: true },
  { id: 3, nombre: 'Calle Sucre', sector: 'Sector Sur', activo: true },
  { id: 4, nombre: 'Calle Miranda', sector: 'Sector Sur', activo: true },
  { id: 5, nombre: 'Calle Carabobo', sector: 'Sector Este', activo: true },
  { id: 6, nombre: 'Calle Zamora', sector: 'Sector Este', activo: true },
])

const jefes = ref([
  { id: 1, nombre: 'Carlos Mendoza', cedula: 'V-12345678', calleId: 1, telefono: '0414-1234567', activo: true },
  { id: 2, nombre: 'María González', cedula: 'V-23456789', calleId: 2, telefono: '0424-2345678', activo: true },
  { id: 3, nombre: 'José Rodríguez', cedula: 'V-34567890', calleId: 3, telefono: '0412-3456789', activo: true },
  { id: 4, nombre: 'Ana Martínez', cedula: 'V-45678901', calleId: 4, telefono: '0416-4567890', activo: true },
  { id: 5, nombre: 'Pedro López', cedula: 'V-56789012', calleId: 5, telefono: '0426-5678901', activo: false },
])

const familias = ref([
  { id: 1, nombre: 'Familia Pérez', calleId: 1, jefeCalleId: 1, personas: 4, direccion: 'Casa #12', activo: true },
  { id: 2, nombre: 'Familia García', calleId: 1, jefeCalleId: 1, personas: 3, direccion: 'Casa #15', activo: true },
  { id: 3, nombre: 'Familia Hernández', calleId: 1, jefeCalleId: 1, personas: 5, direccion: 'Casa #18', activo: true },
  { id: 4, nombre: 'Familia Díaz', calleId: 2, jefeCalleId: 2, personas: 2, direccion: 'Casa #3', activo: true },
  { id: 5, nombre: 'Familia López', calleId: 2, jefeCalleId: 2, personas: 6, direccion: 'Casa #7', activo: true },
  { id: 6, nombre: 'Familia Ramírez', calleId: 3, jefeCalleId: 3, personas: 4, direccion: 'Casa #22', activo: true },
  { id: 7, nombre: 'Familia Torres', calleId: 3, jefeCalleId: 3, personas: 3, direccion: 'Casa #25', activo: true },
  { id: 8, nombre: 'Familia Flores', calleId: 4, jefeCalleId: 4, personas: 5, direccion: 'Casa #9', activo: true },
  { id: 9, nombre: 'Familia Morales', calleId: 5, jefeCalleId: 5, personas: 4, direccion: 'Casa #14', activo: true },
  { id: 10, nombre: 'Familia Castro', calleId: 5, jefeCalleId: 5, personas: 2, direccion: 'Casa #16', activo: false },
])

const tiposBombona = ref([
  { id: 1, nombre: 'Bombona 10 Kg', peso: 10, precio: 0.50 },
  { id: 2, nombre: 'Bombona 18 Kg', peso: 18, precio: 0.90 },
  { id: 3, nombre: 'Bombona 43 Kg', peso: 43, precio: 2.15 },
])

const picos = ref([
  { id: 1, nombre: 'Pico Delgado', descripcion: 'Para bombonas de 10 Kg' },
  { id: 2, nombre: 'Pico Estándar', descripcion: 'Para bombonas de 18 Kg' },
  { id: 3, nombre: 'Pico Grueso', descripcion: 'Para bombonas de 43 Kg' },
])

const solicitudes = ref([
  { id: 1, familiaId: 1, tipoBombonaId: 2, picoId: 2, fecha: '2025-01-15', estatus: 'pendiente', observaciones: '' },
  { id: 2, familiaId: 2, tipoBombonaId: 1, picoId: 1, fecha: '2025-01-15', estatus: 'en_proceso', observaciones: 'Aprobada por jefe de calle' },
  { id: 3, familiaId: 4, tipoBombonaId: 3, picoId: 3, fecha: '2025-01-14', estatus: 'entregado', observaciones: 'Entregada correctamente' },
  { id: 4, familiaId: 6, tipoBombonaId: 2, picoId: 2, fecha: '2025-01-14', estatus: 'pendiente', observaciones: '' },
  { id: 5, familiaId: 3, tipoBombonaId: 1, picoId: 1, fecha: '2025-01-13', estatus: 'rechazado', observaciones: 'Ya recibió este mes' },
  { id: 6, familiaId: 7, tipoBombonaId: 2, picoId: 2, fecha: '2025-01-13', estatus: 'entregado', observaciones: '' },
  { id: 7, familiaId: 8, tipoBombonaId: 3, picoId: 3, fecha: '2025-01-12', estatus: 'en_proceso', observaciones: 'En ruta de entrega' },
  { id: 8, familiaId: 5, tipoBombonaId: 2, picoId: 2, fecha: '2025-01-12', estatus: 'pendiente', observaciones: '' },
  { id: 9, familiaId: 9, tipoBombonaId: 1, picoId: 1, fecha: '2025-01-11', estatus: 'entregado', observaciones: '' },
  { id: 10, familiaId: 1, tipoBombonaId: 2, picoId: 2, fecha: '2025-01-10', estatus: 'entregado', observaciones: 'Ciclo anterior' },
])

const ciclosDistribucion = ref([
  { id: 1, nombre: 'Ciclo Enero 2025 - Semana 1', fechaInicio: '2025-01-06', fechaFin: '2025-01-12', estado: 'completado', totalEntregas: 45, totalPendientes: 0 },
  { id: 2, nombre: 'Ciclo Enero 2025 - Semana 2', fechaInicio: '2025-01-13', fechaFin: '2025-01-19', estado: 'en_progreso', totalEntregas: 28, totalPendientes: 12 },
  { id: 3, nombre: 'Ciclo Enero 2025 - Semana 3', fechaInicio: '2025-01-20', fechaFin: '2025-01-26', estado: 'planificado', totalEntregas: 0, totalPendientes: 35 },
  { id: 4, nombre: 'Ciclo Febrero 2025 - Semana 1', fechaInicio: '2025-02-03', fechaFin: '2025-02-09', estado: 'planificado', totalEntregas: 0, totalPendientes: 0 },
])

const usuarios = ref([
  { id: 1, username: 'admin', password: 'admin123', rol: 'admin', nombre: 'Administrador del Sistema', activo: true },
  { id: 2, username: 'carlos.mendoza', password: 'jefe123', rol: 'jefe', nombre: 'Carlos Mendoza', entidadId: 1, activo: true },
  { id: 3, username: 'maria.gonzalez', password: 'jefe123', rol: 'jefe', nombre: 'María González', entidadId: 2, activo: true },
  { id: 4, username: 'jose.rodriguez', password: 'jefe123', rol: 'jefe', nombre: 'José Rodríguez', entidadId: 3, activo: true },
  { id: 5, username: 'ana.martinez', password: 'jefe123', rol: 'jefe', nombre: 'Ana Martínez', entidadId: 4, activo: true },
  { id: 6, username: 'familia.perez', password: 'familia123', rol: 'familia', nombre: 'Familia Pérez', entidadId: 1, activo: true },
  { id: 7, username: 'familia.garcia', password: 'familia123', rol: 'familia', nombre: 'Familia García', entidadId: 2, activo: true },
  { id: 8, username: 'familia.diaz', password: 'familia123', rol: 'familia', nombre: 'Familia Díaz', entidadId: 4, activo: true },
  { id: 9, username: 'familia.ramirez', password: 'familia123', rol: 'familia', nombre: 'Familia Ramírez', entidadId: 6, activo: true },
])

const auditoriaLogs = ref([
  { id: 1, fecha: '2025-01-15 09:30:00', usuario: 'admin', accion: 'Crear', entidad: 'Ciclo de Distribución', detalle: 'Ciclo Enero S2 creado', ip: '192.168.1.100' },
  { id: 2, fecha: '2025-01-15 10:15:00', usuario: 'carlos.mendoza', accion: 'Aprobar', entidad: 'Solicitud #2', detalle: 'Solicitud de Familia García aprobada', ip: '192.168.1.105' },
  { id: 3, fecha: '2025-01-14 14:20:00', usuario: 'admin', accion: 'Modificar', entidad: 'Jefe de Calle', detalle: 'Teléfono actualizado - Pedro López', ip: '192.168.1.100' },
  { id: 4, fecha: '2025-01-14 16:45:00', usuario: 'jose.rodriguez', accion: 'Registrar', entidad: 'Solicitud Presencial', detalle: 'Solicitud para Familia Torres', ip: '192.168.1.110' },
  { id: 5, fecha: '2025-01-13 08:00:00', usuario: 'admin', accion: 'Desactivar', entidad: 'Usuario', detalle: 'Usuario pedro.lopez dado de baja', ip: '192.168.1.100' },
  { id: 6, fecha: '2025-01-13 11:30:00', usuario: 'familia.perez', accion: 'Crear', entidad: 'Solicitud', detalle: 'Nueva solicitud de bombona 18Kg', ip: '192.168.1.120' },
  { id: 7, fecha: '2025-01-12 15:00:00', usuario: 'admin', accion: 'Exportar', entidad: 'Reporte', detalle: 'Planilla de distribución generada', ip: '192.168.1.100' },
  { id: 8, fecha: '2025-01-12 09:10:00', usuario: 'maria.gonzalez', accion: 'Rechazar', entidad: 'Solicitud #5', detalle: 'Familia Hernández - Ya recibió este mes', ip: '192.168.1.108' },
])

function nextId(collection) {
  return collection.value.length ? Math.max(...collection.value.map((i) => i.id)) + 1 : 1
}

function findById(collection, id) {
  return collection.value.find((item) => item.id === Number(id))
}

function toggleActivo(collection, id) {
  const item = findById(collection, id)
  if (item) item.activo = !item.activo
  return item
}

function addCalle(data) {
  const item = { id: nextId(calles), activo: true, ...data }
  calles.value.push(item)
  return item
}

function updateCalle(id, data) {
  const item = findById(calles, id)
  if (item) Object.assign(item, data)
  return item
}

function addJefe(data) {
  const item = { id: nextId(jefes), activo: true, ...data }
  jefes.value.push(item)
  return item
}

function updateJefe(id, data) {
  const item = findById(jefes, id)
  if (item) Object.assign(item, data)
  return item
}

function addFamilia(data) {
  const item = { id: nextId(familias), activo: true, ...data }
  familias.value.push(item)
  return item
}

function updateFamilia(id, data) {
  const item = findById(familias, id)
  if (item) Object.assign(item, data)
  return item
}

function addUsuario(data) {
  const item = { id: nextId(usuarios), activo: true, ...data }
  usuarios.value.push(item)
  return item
}

function updateUsuario(id, data) {
  const item = findById(usuarios, id)
  if (item) Object.assign(item, data)
  return item
}

function addSolicitud(data) {
  const item = {
    id: nextId(solicitudes),
    fecha: new Date().toISOString().slice(0, 10),
    estatus: 'pendiente',
    observaciones: '',
    ...data,
  }
  solicitudes.value.unshift(item)
  return item
}

function updateSolicitudEstatus(id, estatus, observaciones = '') {
  const item = findById(solicitudes, id)
  if (item) {
    item.estatus = estatus
    if (observaciones) item.observaciones = observaciones
  }
  return item
}

function addCiclo(data) {
  const item = {
    id: nextId(ciclosDistribucion),
    estado: 'planificado',
    totalEntregas: 0,
    totalPendientes: 0,
    ...data,
  }
  ciclosDistribucion.value.push(item)
  return item
}

function updateCiclo(id, data) {
  const item = findById(ciclosDistribucion, id)
  if (item) Object.assign(item, data)
  return item
}

function addAuditoria({ usuario, accion, entidad, detalle }) {
  const item = {
    id: nextId(auditoriaLogs),
    fecha: new Date().toISOString().replace('T', ' ').slice(0, 19),
    usuario,
    accion,
    entidad,
    detalle,
    ip: '192.168.1.' + Math.floor(Math.random() * 200 + 100),
  }
  auditoriaLogs.value.unshift(item)
  return item
}

function getCalleNombre(id) {
  return findById(calles, id)?.nombre || '—'
}

function getFamiliaNombre(id) {
  return findById(familias, id)?.nombre || '—'
}

function getTipoNombre(id) {
  return findById(tiposBombona, id)?.nombre || '—'
}

function getPicoNombre(id) {
  return findById(picos, id)?.nombre || '—'
}

function getJefeNombre(id) {
  return findById(jefes, id)?.nombre || '—'
}

function useMockData() {
  return {
    calles,
    jefes,
    familias,
    tiposBombona,
    picos,
    solicitudes,
    ciclosDistribucion,
    usuarios,
    auditoriaLogs,
    findById,
    toggleActivo,
    addCalle,
    updateCalle,
    addJefe,
    updateJefe,
    addFamilia,
    updateFamilia,
    addUsuario,
    updateUsuario,
    addSolicitud,
    updateSolicitudEstatus,
    addCiclo,
    updateCiclo,
    addAuditoria,
    getCalleNombre,
    getFamiliaNombre,
    getTipoNombre,
    getPicoNombre,
    getJefeNombre,
  }
}

export { useMockData }
