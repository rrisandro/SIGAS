# Sistema de Gas Doméstico — Peticiones de la API

Este documento describe **todas las peticiones que el frontend necesita
del backend** para que el sistema funcione de verdad. Está basado en el
comportamiento real de la interfaz ya construida (login, roles, CRUDs,
solicitudes, entregas, ciclos y auditoría). Falta implementar el backend
y algunos retoques de frontend, pero el contrato de la API descrito aquí
ya cubre todo lo que la UI necesita.

## Convenciones generales

- Base URL sugerida: `/api`
- Formato: JSON en request y response (`Content-Type: application/json`)
- Autenticación: token (JWT o sesión) enviado en el header
  `Authorization: Bearer <token>`
- Respuestas de error consistentes:
  ```json
  { "error": "Mensaje descriptivo", "code": "ESTADO_HTTP_O_CODIGO_INTERNO" }
  ```
- Códigos HTTP esperados: `200` OK, `201` creado, `400` datos inválidos,
  `401` no autenticado, `403` sin permiso para ese rol, `404` no
  encontrado, `500` error del servidor.
- Todas las rutas (excepto `/auth/login`) requieren estar autenticado.
  Las rutas de administración además requieren rol `admin`; las de jefe
  de calle, rol `jefe`; las de familia, rol `familia`.

---

## 1. Autenticación

### `POST /api/auth/login`
Login con usuario y contraseña.

**Body:**
```json
{ "username": "carlos.mendoza", "password": "jefe123" }
```

**Response 200:**
```json
{
  "token": "jwt-o-similar",
  "user": {
    "id": 2,
    "username": "carlos.mendoza",
    "nombre": "Carlos Mendoza",
    "rol": "jefe",
    "entidadId": 1
  }
}
```
`entidadId` es el id del jefe de calle o de la familia asociada al
usuario (según el rol); para `admin` puede ir en `null`.

**Response 401:** credenciales inválidas o usuario inactivo.

### `POST /api/auth/logout`
Invalida el token/sesión actual. Response `204`.

### `GET /api/auth/me`
Devuelve el usuario autenticado actual (útil para restaurar sesión al
recargar la página en vez de confiar solo en lo guardado en el
navegador). Response igual al objeto `user` de arriba.

---

## 2. Calles *(solo admin)*

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/calles` | Lista todas las calles |
| POST | `/api/calles` | Crea una calle |
| PUT | `/api/calles/:id` | Edita nombre/sector de una calle |
| PATCH | `/api/calles/:id/estado` | Activa/desactiva (`{ "activo": true }`) |
| DELETE | `/api/calles/:id` | Elimina una calle (si no tiene familias/jefes asociados) |

**Body de creación/edición:**
```json
{ "nombre": "Calle Bolívar", "sector": "Sector Norte" }
```

---

## 3. Jefes de calle *(solo admin)*

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/jefes` | Lista todos los jefes de calle |
| GET | `/api/jefes?calleId=1` | Filtra por calle |
| POST | `/api/jefes` | Crea un jefe de calle |
| PUT | `/api/jefes/:id` | Edita datos de un jefe |
| PATCH | `/api/jefes/:id/estado` | Activa/desactiva |
| DELETE | `/api/jefes/:id` | Elimina un jefe de calle |

**Body de creación/edición:**
```json
{
  "nombre": "Pedro López",
  "cedula": "V-56789012",
  "calleId": 5,
  "telefono": "0426-5678901"
}
```

> Al crear un jefe de calle, el backend debería también crear (o
> permitir vincular) su usuario de acceso (ver sección 5).

---

## 4. Familias

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/api/familias` | admin | Lista todas las familias |
| GET | `/api/familias?calleId=1` | admin, jefe | Familias de una calle (bandeja, registro presencial) |
| GET | `/api/familias/:id` | admin, jefe, familia (propia) | Detalle de una familia |
| POST | `/api/familias` | admin | Crea una familia |
| PUT | `/api/familias/:id` | admin | Edita una familia |
| PATCH | `/api/familias/:id/estado` | admin | Activa/desactiva |
| DELETE | `/api/familias/:id` | admin | Elimina una familia |

**Body de creación/edición:**
```json
{
  "nombre": "Familia Pérez",
  "calleId": 1,
  "jefeCalleId": 1,
  "personas": 4,
  "direccion": "Casa #12"
}
```

---

## 5. Usuarios *(solo admin)*

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/usuarios` | Lista todos los usuarios |
| POST | `/api/usuarios` | Crea un usuario (admin, jefe o familia) |
| PUT | `/api/usuarios/:id` | Edita username/nombre/rol/entidad vinculada |
| PATCH | `/api/usuarios/:id/estado` | Activa/desactiva |
| POST | `/api/usuarios/:id/reset-password` | Genera o resetea contraseña |

**Body de creación:**
```json
{
  "username": "familia.perez",
  "password": "familia123",
  "rol": "familia",
  "nombre": "Familia Pérez",
  "entidadId": 1
}
```
La contraseña nunca debe devolverse en las respuestas `GET`.

---

## 6. Catálogos: tipos de bombona y picos

Estos catálogos son casi estáticos, pero conviene tenerlos en la base de
datos (no *hardcodeados* en el frontend) para poder ajustar precios o
agregar tipos sin tocar código.

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/tipos-bombona` | Lista tipos de bombona (nombre, peso, precio) |
| POST / PUT / DELETE | `/api/tipos-bombona/:id` | *(opcional, solo admin)* mantenimiento del catálogo |
| GET | `/api/picos` | Lista tipos de pico |
| POST / PUT / DELETE | `/api/picos/:id` | *(opcional, solo admin)* mantenimiento del catálogo |

---

## 7. Solicitudes de gas

Este es el recurso central del sistema.

| Método | Ruta | Rol | Descripción |
|---|---|---|---|
| GET | `/api/solicitudes` | admin | Todas las solicitudes |
| GET | `/api/solicitudes?familiaId=1` | familia (propia) | Historial de una familia |
| GET | `/api/solicitudes?calleId=1` | jefe | Solicitudes de su calle |
| GET | `/api/solicitudes?calleId=1&estatus=pendiente` | jefe | Bandeja de pendientes |
| GET | `/api/solicitudes?calleId=1&estatus=en_proceso` | jefe | Listado para control de entregas |
| POST | `/api/solicitudes` | familia | Crea una solicitud propia |
| POST | `/api/solicitudes` | jefe | Registro presencial (indicando `familiaId`) |
| PATCH | `/api/solicitudes/:id/estatus` | jefe | Aprobar / rechazar / marcar entregado |

**Body al crear (familia o jefe):**
```json
{
  "familiaId": 1,
  "tipoBombonaId": 2,
  "picoId": 2,
  "observaciones": "Nota opcional"
}
```
`fecha` y `estatus: "pendiente"` los pone el backend automáticamente.

**Body al cambiar estatus (jefe):**
```json
{ "estatus": "en_proceso", "observaciones": "Aprobada por jefe de calle" }
```
Valores válidos de `estatus`: `pendiente`, `en_proceso`, `entregado`,
`rechazado`. El backend debe validar las transiciones permitidas (por
ejemplo, no se puede pasar de `rechazado` a `entregado` directamente) y
generar el registro de auditoría correspondiente (ver sección 9).

---

## 8. Ciclos de distribución *(solo admin)*

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/ciclos` | Lista los ciclos de distribución |
| POST | `/api/ciclos` | Crea un nuevo ciclo |
| PUT | `/api/ciclos/:id` | Edita fechas/nombre de un ciclo |
| PATCH | `/api/ciclos/:id/estado` | Cambia estado (`planificado` → `en_progreso` → `completado`) |

**Body de creación:**
```json
{
  "nombre": "Ciclo Enero 2025 - Semana 3",
  "fechaInicio": "2025-01-20",
  "fechaFin": "2025-01-26"
}
```

**Response (incluye contadores calculados por el backend):**
```json
{
  "id": 3,
  "nombre": "Ciclo Enero 2025 - Semana 3",
  "fechaInicio": "2025-01-20",
  "fechaFin": "2025-01-26",
  "estado": "planificado",
  "totalEntregas": 0,
  "totalPendientes": 35
}
```

> Pendiente de decidir en el diseño de base de datos: si cada
> `solicitud` va a llevar un `cicloId` para calcular `totalEntregas` /
> `totalPendientes` reales, o si esos contadores se calculan aparte. En
> el frontend actual son solo datos de ejemplo.

---

## 9. Auditoría *(solo admin)*

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/api/auditoria` | Lista de logs (paginada) |
| GET | `/api/auditoria?usuario=carlos.mendoza` | Filtra por usuario |
| GET | `/api/auditoria/export` | Genera/descarga la planilla (CSV o PDF) |

**Formato de cada log (generado automáticamente por el backend, no por
el frontend):**
```json
{
  "id": 2,
  "fecha": "2025-01-15 10:15:00",
  "usuario": "carlos.mendoza",
  "accion": "Aprobar",
  "entidad": "Solicitud #2",
  "detalle": "Solicitud de Familia García aprobada",
  "ip": "192.168.1.105"
}
```
El backend debe crear un registro de auditoría cada vez que ocurra una
acción relevante: login, crear/editar/activar/desactivar en cualquier
CRUD, y cambios de estatus de solicitudes.

---

## 10. Dashboards (resúmenes)

El frontend hoy calcula las tarjetas de cada dashboard (pendientes, en
proceso, entregadas, totales, etc.) a partir de las listas ya
mencionadas arriba (`/solicitudes`, `/familias`, `/jefes`, `/calles`,
`/ciclos`). **No es obligatorio** crear endpoints aparte; alcanza con
que el frontend pida las listas y calcule los conteos en el cliente.

Si el volumen de datos crece y eso se vuelve lento, se pueden agregar
más adelante endpoints de resumen ya calculados en el servidor:

- `GET /api/dashboard/admin`
- `GET /api/dashboard/jefe` *(usa la calle del jefe autenticado)*
- `GET /api/dashboard/familia` *(usa la familia del usuario autenticado)*

---

## Resumen de permisos por rol

| Recurso | admin | jefe | familia |
|---|---|---|---|
| Calles | CRUD completo | — | — |
| Jefes de calle | CRUD completo | — | — |
| Familias | CRUD completo | lectura (de su calle) | lectura (la propia) |
| Usuarios | CRUD completo | — | — |
| Solicitudes | lectura total | lectura/aprobación de su calle, registro presencial | crear y ver las propias |
| Ciclos de distribución | CRUD completo | — | — |
| Auditoría | lectura total | — | — |

---

## Pendientes para cuando se conecte el backend real

- Definir cómo se generará la contraseña inicial de un usuario nuevo
  (¿temporal + cambio obligatorio?) y el endpoint de recuperación.
- Decidir si `PATCH /estado` y `DELETE` conviven (activar/desactivar es
  un *soft delete*; `DELETE` sería borrado real, probablemente
  restringido si el registro tiene historial asociado).
- Paginación real en `GET /api/solicitudes` y `GET /api/auditoria`
  (`?page=1&perPage=8`, igual que la tabla del frontend).
- Validar del lado del servidor las transiciones de `estatus` de una
  solicitud (el frontend ya asume que son válidas).
