export const menuByRole = {
  admin: [
    { path: 'dashboard', label: 'Dashboard', icon: 'LayoutDashboard' },
    { path: 'calles', label: 'Calles', icon: 'MapPin' },
    { path: 'jefes', label: 'Jefes de Calle', icon: 'UserCheck' },
    { path: 'familias', label: 'Familias', icon: 'Users' },
    { path: 'usuarios', label: 'Usuarios', icon: 'Shield' },
    { path: 'logistica', label: 'Logística', icon: 'Truck' },
    { path: 'auditoria', label: 'Auditoría', icon: 'FileText' },
  ],
  jefe: [
    { path: 'dashboard', label: 'Dashboard', icon: 'LayoutDashboard' },
    { path: 'bandeja', label: 'Bandeja de Solicitudes', icon: 'Inbox' },
    { path: 'registro', label: 'Registro Presencial', icon: 'ClipboardList' },
    { path: 'entregas', label: 'Control de Entregas', icon: 'PackageCheck' },
  ],
  familia: [
    { path: 'dashboard', label: 'Mi Panel', icon: 'LayoutDashboard' },
    { path: 'solicitud', label: 'Solicitar Gas', icon: 'Flame' },
    { path: 'historial', label: 'Mi Historial', icon: 'History' },
  ],
}

export const defaultRoutes = {
  admin: '/admin/dashboard',
  jefe: '/jefe/dashboard',
  familia: '/familia/dashboard',
}
