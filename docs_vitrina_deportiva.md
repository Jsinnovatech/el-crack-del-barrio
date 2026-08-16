# El Crack del Barrio — Documentación Técnica y Plan de Desarrollo

> Documento de referencia para el equipo de desarrollo. Incluye diagramas de flujo, secuencia, estados, modelo de datos y arquitectura, además del plan de acción completo para pasar del prototipo interactivo (`vitrina_deportiva.html`) a una app en producción.

**Índice**
1. [Visión general del producto](#1-visión-general-del-producto)
2. [Diagrama de casos de uso](#2-diagrama-de-casos-de-uso)
3. [Diagramas de flujo (flowcharts)](#3-diagramas-de-flujo-flowcharts)
4. [Diagramas de secuencia](#4-diagramas-de-secuencia)
5. [Diagramas de estados](#5-diagramas-de-estados)
6. [Modelo de datos (entidad-relación)](#6-modelo-de-datos-entidad-relación)
7. [Arquitectura del sistema](#7-arquitectura-del-sistema)
8. [Plan de acción para el desarrollo](#8-plan-de-acción-para-el-desarrollo)

---

## 1. Visión general del producto

**El Crack del Barrio** conecta a dos roles:

- **Jugador**: crea un perfil deportivo (fotos, videos, clubes, disponibilidad), lo verifica con DNI, y contrata planes para ganar visibilidad.
- **Captador / DT**: explora, filtra, compara y contacta jugadores; agenda pruebas y guarda búsquedas/alertas.

El prototipo actual (`vitrina_deportiva.html`) es un **artefacto funcional del lado del cliente** con datos simulados y persistencia local vía `window.storage`. Este documento traza el camino hacia una versión real con backend, base de datos y pagos.

---

## 2. Diagrama de casos de uso

```mermaid
graph TB
  Jugador((Jugador))
  Captador((Captador / DT))

  subgraph "El Crack del Barrio"
    UC1[Registrarse / Elegir rol]
    UC2[Completar perfil deportivo]
    UC3[Verificar identidad con DNI]
    UC4[Subir y ordenar videos]
    UC5[Marcar disponibilidad en calendario]
    UC6[Contratar plan de visibilidad]
    UC7[Explorar y filtrar jugadores]
    UC8[Ver perfil de un jugador]
    UC9[Guardar favoritos]
    UC10[Comparar hasta 3 jugadores]
    UC11[Contactar por WhatsApp]
    UC12[Agendar prueba / tryout]
    UC13[Guardar búsquedas y alertas]
    UC14[Calificar jugador]
    UC15[Recibir notificaciones]
  end

  Jugador --> UC1
  Jugador --> UC2
  Jugador --> UC3
  Jugador --> UC4
  Jugador --> UC5
  Jugador --> UC6

  Captador --> UC1
  Captador --> UC7
  Captador --> UC8
  Captador --> UC9
  Captador --> UC10
  Captador --> UC11
  Captador --> UC12
  Captador --> UC13
  Captador --> UC14
  Captador --> UC15

  UC8 -.incluye.-> UC9
  UC12 -.incluye.-> UC11
```

---

## 3. Diagramas de flujo (flowcharts)

### 3.1 Flujo general de la app (onboarding → rol → pantallas)

```mermaid
flowchart TD
  A[Abrir app] --> B{¿Hay sesión guardada?<br/>window.storage}
  B -- Sí --> C[Restaurar rol y pantalla<br/>de la última sesión]
  B -- No --> D[Pantalla de Onboarding]
  D --> E[Elegir rol: Jugador o Captador]
  E --> F[Pantalla de Login]
  F --> G[Ingresar nombre / celular]
  G --> H{¿Rol?}
  H -- Jugador --> I[Home Jugador]
  H -- Captador --> J[Home Captador]
  C --> H

  I --> I1[Perfil]
  I --> I2[Videos]
  I --> I3[Calendario]
  I --> I4[Planes]

  J --> J1[Explorar]
  J --> J2[Favoritos]
  J --> J3[Cuenta]
```

### 3.2 Flujo — Jugador completa su perfil

```mermaid
flowchart TD
  Start([Jugador entra a Perfil]) --> P1[Subir foto de perfil]
  P1 --> P2[Subir DNI para verificación]
  P2 --> P3[Escribir bio ≥10 caracteres]
  P3 --> P4[Elegir posición principal<br/>y hasta 2 secundarias]
  P4 --> P5[Añadir clubes / campeonatos]
  P5 --> P6[Guardar cambios]
  P6 --> Val{¿Pasa validación?}
  Val -- No --> Err[Mostrar error específico] --> P3
  Val -- Sí --> Done[Perfil actualizado<br/>+ checklist recalculado]
  Done --> Persist[(Guardar en storage)]
```

### 3.3 Flujo — Captador busca y contacta un jugador

```mermaid
flowchart TD
  S([Captador entra a Explorar]) --> F1[Buscar por nombre / posición]
  F1 --> F2{¿Aplica filtros avanzados?}
  F2 -- Sí --> F3[Edad, ciudad, rating,<br/>disponibilidad, verificado]
  F2 -- No --> F4[Lista ordenada]
  F3 --> F4
  F4 --> F5{¿Guardar esta búsqueda?}
  F5 -- Sí --> F6[Nombrar y guardar como chip]
  F5 -- No --> F7[Ver lista / mapa]
  F6 --> F7
  F7 --> V[Abrir perfil de jugador]
  V --> Act{Acción}
  Act -- Favorito --> Fav[Agregar a Favoritos]
  Act -- Comparar --> Cmp[Añadir a comparador<br/>hasta 3 jugadores]
  Act -- Contactar --> Wa[Abrir WhatsApp con mensaje]
  Wa --> Tr{¿Agendar prueba?}
  Tr -- Sí --> Sch[Registrar fecha, hora, lugar<br/>estado = pendiente]
  Tr -- No --> End([Fin])
  Sch --> End
  Fav --> End
  Cmp --> End
```

### 3.4 Flujo — Contratación de plan (Jugador)

```mermaid
flowchart TD
  A([Jugador entra a Planes]) --> B[Ver tarjetas o tabla comparativa]
  B --> C[Elegir plan de pago]
  C --> D[Modal de pago simulado<br/>Yape / Plin]
  D --> E{¿Pago confirmado?}
  E -- No --> F[Cancelar / reintentar]
  E -- Sí --> G[Activar plan]
  G --> H[Actualizar badge y prioridad<br/>en resultados del captador]
  H --> I[(Persistir plan activo)]
```

---

## 4. Diagramas de secuencia

### 4.1 Secuencia — Arranque de la app con sesión persistida

```mermaid
sequenceDiagram
  autonumber
  participant U as Usuario
  participant App as App (JS)
  participant St as window.storage

  U->>App: Abre la app (DOMContentLoaded)
  App->>App: fillIcons() en markup estático
  App->>St: get('crack-del-barrio-state-v1')
  St-->>App: JSON con state, myProfile, roster
  alt hay datos guardados
    App->>App: Reconstruye Sets (favoritos, vistos, contactados)
    App->>App: Aplica ratings/views a ROSTER
    App->>U: Muestra pantalla correspondiente al rol (Home)
    App->>U: Toast "Bienvenido de nuevo"
  else no hay datos guardados
    App->>U: Muestra Onboarding
  end
```

### 4.2 Secuencia — Captador contacta a un jugador

```mermaid
sequenceDiagram
  autonumber
  participant C as Captador
  participant App as App (JS)
  participant St as window.storage

  C->>App: Abre perfil de jugador (viewPlayer)
  App->>App: state.viewedIds.add(id)
  App->>C: Muestra ficha, videos, calendario, reseñas
  C->>App: Toca "Contactar por WhatsApp"
  App->>App: state.contactedIds.add(id)
  App->>App: Genera enlace wa.me con mensaje precargado
  App-->>C: Abre WhatsApp (nueva pestaña)
  App->>St: persist() [debounced 350ms]
  St-->>App: OK
  Note over App,St: El embudo de conversión<br/>en Home se recalcula al volver
```

### 4.3 Secuencia — Guardar progreso (persist genérico)

```mermaid
sequenceDiagram
  autonumber
  participant U as Usuario
  participant UI as Componente UI
  participant App as App (JS)
  participant St as window.storage

  U->>UI: Realiza una acción (guardar perfil,<br/>marcar día, subir video, etc.)
  UI->>App: Muta el estado en memoria
  UI->>App: toast(mensaje)
  App->>App: clearTimeout(_saveTimer)
  App->>App: setTimeout 350ms
  App->>App: serializeState()
  App->>St: set(STORAGE_KEY, JSON)
  St-->>App: {key, value, shared:false}
  Note right of App: Si storage falla,<br/>se registra en consola<br/>sin interrumpir la UX
```

### 4.4 Secuencia — Agendar una prueba (tryout)

```mermaid
sequenceDiagram
  autonumber
  participant C as Captador
  participant App as App (JS)
  participant St as window.storage

  C->>App: Abre sheet "Agendar prueba"
  C->>App: Completa fecha, hora, lugar
  C->>App: Confirma (confirmTryout)
  App->>App: tryouts.push({status:'pendiente', ...})
  App->>St: persist()
  App-->>C: Toast "Prueba propuesta"
  C->>App: Va a Cuenta → Mis pruebas
  App-->>C: Lista con chip de estado
  C->>App: Toca chip (cycleTryoutStatus)
  App->>App: pendiente → confirmada → realizada
  App->>St: persist()
```

---

## 5. Diagramas de estados

### 5.1 Estado de una prueba (tryout)

```mermaid
stateDiagram-v2
  [*] --> pendiente: Captador agenda la prueba
  pendiente --> confirmada: Captador actualiza el estado
  confirmada --> realizada: Captador marca como completada
  realizada --> [*]
  pendiente --> [*]: Se cancela (eliminación futura)
```

### 5.2 Estado de un plan del jugador

```mermaid
stateDiagram-v2
  [*] --> free: Registro inicial
  free --> pendiente_pago: Elige plan de pago
  pendiente_pago --> free: Pago cancelado
  pendiente_pago --> activo: Pago confirmado
  activo --> vencido: Se agotan vistas / expira periodo
  vencido --> pendiente_pago: Renueva plan
  activo --> free: Downgrade manual
```

### 5.3 Estado de verificación del jugador

```mermaid
stateDiagram-v2
  [*] --> sin_verificar
  sin_verificar --> dni_subido: Sube foto de DNI
  dni_subido --> en_revision: (futuro) Validación automática/manual
  en_revision --> verificado: Aprobado
  en_revision --> rechazado: Rechazado
  rechazado --> dni_subido: Reintenta
  verificado --> [*]
```

---

## 6. Modelo de datos (entidad-relación)

> Refleja el modelo actual en memoria (`state`, `myProfile`, `ROSTER`, `PLANS`) proyectado a un esquema relacional para el backend.

```mermaid
erDiagram
  USUARIO ||--o| PERFIL_JUGADOR : "tiene (si rol=jugador)"
  USUARIO ||--o| PERFIL_CAPTADOR : "tiene (si rol=captador)"
  USUARIO {
    string id PK
    string nombre
    string celular
    string rol "jugador | captador"
    datetime creado_en
  }

  PERFIL_JUGADOR {
    string id PK
    string usuario_id FK
    string foto_url
    string dni_url
    bool   verificado
    string bio
    string posicion_principal
    string[] posiciones_secundarias
    int    edad
    string ciudad
    float  rating
    string plan_id FK
    datetime plan_expira
  }

  VIDEO {
    string id PK
    string jugador_id FK
    string titulo
    string thumb_url
    string video_url
    int    vistas
    bool   destacado
    int    orden
  }
  PERFIL_JUGADOR ||--o{ VIDEO : "sube"

  CLUB {
    string id PK
    string jugador_id FK
    string nombre
    string tipo "club | campeon"
    int    anio
  }
  PERFIL_JUGADOR ||--o{ CLUB : "registra"

  DISPONIBILIDAD {
    string id PK
    string jugador_id FK
    date   fecha
    string estado "disponible | contratado | no_disponible"
    time   hora_desde
    time   hora_hasta
  }
  PERFIL_JUGADOR ||--o{ DISPONIBILIDAD : "marca"

  PLAN {
    string id PK
    string nombre
    decimal precio
    string unidad
    string[] beneficios
  }
  PERFIL_JUGADOR }o--|| PLAN : "contrata"

  PAGO {
    string id PK
    string jugador_id FK
    string plan_id FK
    decimal monto
    string metodo "yape | plin | tarjeta"
    string estado "pendiente | confirmado | fallido"
    datetime creado_en
  }
  PERFIL_JUGADOR ||--o{ PAGO : "realiza"

  PERFIL_CAPTADOR {
    string id PK
    string usuario_id FK
    string club_representa
    string zona_interes
    string plan_id FK
  }

  FAVORITO {
    string id PK
    string captador_id FK
    string jugador_id FK
    datetime creado_en
  }
  PERFIL_CAPTADOR ||--o{ FAVORITO : "guarda"
  PERFIL_JUGADOR ||--o{ FAVORITO : "es guardado en"

  CONTACTO {
    string id PK
    string captador_id FK
    string jugador_id FK
    datetime creado_en
  }
  PERFIL_CAPTADOR ||--o{ CONTACTO : "inicia"

  PRUEBA {
    string id PK
    string captador_id FK
    string jugador_id FK
    date   fecha
    time   hora
    string lugar
    string estado "pendiente | confirmada | realizada"
  }
  PERFIL_CAPTADOR ||--o{ PRUEBA : "agenda"
  PERFIL_JUGADOR ||--o{ PRUEBA : "recibe"

  CALIFICACION {
    string id PK
    string captador_id FK
    string jugador_id FK
    int    estrellas
    string comentario
  }
  PERFIL_CAPTADOR ||--o{ CALIFICACION : "otorga"

  BUSQUEDA_GUARDADA {
    string id PK
    string captador_id FK
    string nombre
    json   filtros
  }
  PERFIL_CAPTADOR ||--o{ BUSQUEDA_GUARDADA : "guarda"

  ALERTA {
    string id PK
    string captador_id FK
    string posicion
    string ciudad
    int    edad_max
  }
  PERFIL_CAPTADOR ||--o{ ALERTA : "configura"

  NOTIFICACION {
    string id PK
    string usuario_id FK
    string tipo
    string texto
    bool   leido
    datetime creado_en
  }
  USUARIO ||--o{ NOTIFICACION : "recibe"
```

---

## 7. Arquitectura del sistema

### 7.1 Estado actual (prototipo)

```mermaid
graph LR
  subgraph Cliente
    UI[HTML + CSS + JS<br/>vitrina_deportiva.html]
    LS[(window.storage<br/>key-value personal)]
  end
  UI <--> LS
```

### 7.2 Arquitectura objetivo (producción)

```mermaid
graph TB
  subgraph Cliente
    APP[App móvil / PWA<br/>React Native o Flutter]
  end

  subgraph Backend
    API[API REST / GraphQL<br/>Node.js o similar]
    AUTH[Servicio de autenticación<br/>OTP por SMS/WhatsApp]
    PAY[Servicio de pagos<br/>Culqi / Niubiz / Yape API]
    NOTIF[Servicio de notificaciones<br/>push + email]
    JOBS[Jobs programados<br/>alertas, recordatorios]
  end

  subgraph Datos
    DB[(Base de datos<br/>PostgreSQL)]
    CDN[(CDN / Storage<br/>videos e imágenes)]
    CACHE[(Cache<br/>Redis)]
  end

  APP --> API
  API --> AUTH
  API --> PAY
  API --> DB
  API --> CACHE
  API --> CDN
  JOBS --> DB
  JOBS --> NOTIF
  NOTIF --> APP
  PAY --> DB
```

---

## 8. Plan de acción para el desarrollo

### 8.1 Resumen de fases

| Fase | Objetivo | Duración estimada |
|---|---|---|
| 0. Validación del prototipo | Confirmar flujos con usuarios reales | 1–2 semanas |
| 1. Diseño técnico | Arquitectura, esquema de BD, contratos de API | 1 semana |
| 2. Backend base | Auth, usuarios, perfiles | 2 semanas |
| 3. Módulo Jugador | Perfil, videos, calendario | 2 semanas |
| 4. Módulo Captador | Explorar, favoritos, comparar, contacto | 2 semanas |
| 5. Pagos y planes | Integración Yape/Plin/tarjeta | 1.5 semanas |
| 6. Notificaciones y alertas | Push, jobs programados | 1 semana |
| 7. QA y pruebas | Funcional, usabilidad, carga | 1.5 semanas |
| 8. Beta cerrada | Lanzamiento con grupo reducido | 2 semanas |
| 9. Lanzamiento y métricas | Publicación y monitoreo | continuo |

**Duración total estimada hasta beta pública: ~14–15 semanas** (equipo pequeño de 2–3 personas).

---

### 8.2 Fase 0 — Validación del prototipo

- [ ] Compartir el artefacto interactivo con 5–8 jugadores y 3–5 captadores reales.
- [ ] Recoger feedback sobre el flujo de registro, el explorar/filtrar y el flujo de pago.
- [ ] Priorizar ajustes de UX antes de invertir en backend.
- [ ] Definir métricas de éxito iniciales (perfiles completados, contactos generados, pruebas agendadas).

### 8.3 Fase 1 — Diseño técnico

- [ ] Elegir stack: backend (Node.js/NestJS o similar), base de datos (PostgreSQL), frontend móvil (React Native / Flutter / PWA).
- [ ] Formalizar el modelo de datos (sección 6) en migraciones de base de datos.
- [ ] Definir contratos de API (REST/GraphQL) para cada pantalla del prototipo.
- [ ] Definir política de almacenamiento de videos/imágenes (CDN, límites de tamaño, compresión).
- [ ] Definir estrategia de autenticación (OTP por SMS o WhatsApp, dado que el login actual es solo nombre + celular).

### 8.4 Fase 2 — Backend base (Auth + Usuarios)

- [ ] Endpoint de registro/login con verificación de celular.
- [ ] Gestión de sesión (JWT o similar) y selección de rol.
- [ ] CRUD de usuario base.
- [ ] Middleware de autorización por rol (jugador vs. captador).

### 8.5 Fase 3 — Módulo Jugador

- [ ] CRUD de perfil deportivo (foto, bio, posición principal y secundarias, ciudad).
- [ ] Subida y verificación de DNI (integrar validación manual o servicio tipo RENIEC/terceros).
- [ ] CRUD de videos con orden y video destacado; integración con CDN.
- [ ] CRUD de disponibilidad (calendario mensual y semanal).
- [ ] Cálculo de "perfil completo" y checklist en backend (evitar lógica solo en cliente).
- [ ] Endpoint de estadísticas (vistas por día, contactos recibidos).

### 8.6 Fase 4 — Módulo Captador

- [ ] Endpoint de exploración con filtros (posición, edad, ciudad, rating, verificado, disponibilidad por fecha).
- [ ] Favoritos (guardar/quitar).
- [ ] Comparador (2–3 jugadores) con datos consolidados.
- [ ] Contacto (registro de evento "contactado" + deep link a WhatsApp).
- [ ] Agenda de pruebas con estados (pendiente/confirmada/realizada).
- [ ] Calificaciones y reseñas de jugadores.
- [ ] Búsquedas guardadas y alertas configurables (requiere job programado, ver 8.8).
- [ ] Vista de mapa: reemplazar mock por geolocalización real (lat/lng por distrito o del propio jugador).

### 8.7 Fase 5 — Pagos y planes

- [ ] Definir planes reales (precio, beneficios, duración o cupo de vistas).
- [ ] Integrar pasarela de pago (Yape/Plin vía API de un agregador, o Culqi/Niubiz para tarjetas).
- [ ] Webhook de confirmación de pago → activar plan.
- [ ] Manejo de expiración y renovación automática/manual.
- [ ] Panel simple de facturación para soporte.

### 8.8 Fase 6 — Notificaciones y alertas

- [ ] Servicio de push notifications (Firebase Cloud Messaging u OneSignal).
- [ ] Job programado que evalúa `ALERTA` contra nuevos jugadores/actualizaciones y dispara notificación.
- [ ] Notificaciones in-app con estado leído/no leído persistido en backend.
- [ ] Recordatorio automático a jugadores con calendario desactualizado (>5 días).

### 8.9 Fase 7 — QA y pruebas

- [ ] Pruebas funcionales de cada flujo (registro, perfil, pago, contacto, prueba, comparador).
- [ ] Pruebas de usabilidad en dispositivos reales (390px en adelante).
- [ ] Pruebas de carga en endpoints de exploración/filtrado.
- [ ] Revisión de seguridad: manejo de DNI (dato sensible), tokens, permisos por rol.

### 8.10 Fase 8 — Beta cerrada

- [ ] Onboarding guiado con 10–20 jugadores y 5–10 captadores reales.
- [ ] Canal de feedback directo (WhatsApp o formulario in-app).
- [ ] Monitoreo de errores (Sentry o similar) y analítica de uso (Amplitude/Mixpanel).
- [ ] Ciclo de iteración semanal sobre hallazgos.

### 8.11 Fase 9 — Lanzamiento y métricas

- [ ] Publicación en tiendas (Google Play / App Store) o distribución como PWA.
- [ ] Definir KPIs de negocio: perfiles verificados, tasa de contacto, pruebas agendadas, conversión a planes pagados.
- [ ] Roadmap de mejora continua basado en el embudo de captación (sección 6/7 del prototipo).

---

### 8.12 Riesgos y consideraciones

| Riesgo | Impacto | Mitigación |
|---|---|---|
| Verificación de DNI de menores de edad | Legal / seguridad | Definir política clara, posible requerimiento de consentimiento de tutor |
| Fraude en pagos Yape/Plin | Financiero | Usar agregador certificado, no procesar pagos manualmente |
| Datos sensibles (DNI, ubicación) | Privacidad | Cifrado en reposo, acceso restringido, política de retención |
| Baja liquidez de captadores al inicio | Producto | Estrategia de adquisición dual (regalar plan premium a primeros captadores) |
| Dependencia de WhatsApp para contacto | Producto | Mantenerlo como MVP, evaluar chat in-app en fases posteriores |

---

*Documento generado a partir del prototipo `vitrina_deportiva.html`. Actualizar cada vez que cambie un flujo o el modelo de datos en el prototipo, para mantener la trazabilidad entre diseño y desarrollo.*
