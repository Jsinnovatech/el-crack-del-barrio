# El Crack del Barrio — Backend (FastAPI + PostgreSQL)

API REST para la app de jugadores y captadores de fútbol. Traduce a código real el
modelo de datos y los flujos definidos en `docs_crack_del_barrio.md` del prototipo.

## Stack

- **FastAPI** (Python) — framework web/API
- **SQLAlchemy 2.0** — ORM
- **Alembic** — migraciones de base de datos
- **PostgreSQL** — base de datos
- **Pydantic v2** — validación de esquemas
- **JWT (python-jose)** + **passlib** — autenticación

## Estructura

```
backend/
├── app/
│   ├── core/
│   │   ├── config.py       # variables de entorno (pydantic-settings)
│   │   └── security.py     # JWT y hashing
│   ├── routers/
│   │   ├── auth.py         # registro, OTP, login
│   │   ├── jugadores.py    # perfil, videos, clubes, disponibilidad
│   │   ├── captadores.py   # explorar, favoritos, contactos, pruebas, alertas
│   │   ├── planes.py       # planes y pagos
│   │   └── notificaciones.py
│   ├── database.py         # engine + sesión SQLAlchemy
│   ├── deps.py              # dependencias de auth (get_current_user, require_role)
│   ├── models.py            # modelos SQLAlchemy (todo el ER del proyecto)
│   ├── schemas.py           # esquemas Pydantic (request/response)
│   ├── seed.py               # datos semilla (planes)
│   └── main.py                # entrypoint FastAPI
├── alembic/                    # migraciones
├── requirements.txt
├── .env.example
└── alembic.ini
```

## Cómo correrlo localmente

```bash
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env             # y edita DATABASE_URL con tus credenciales

# Crea las tablas (para desarrollo rápido, sin migraciones aún)
python -m app.seed

# o, usando Alembic (recomendado antes de tocar producción):
# alembic revision --autogenerate -m "esquema inicial"
# alembic upgrade head

uvicorn app.main:app --reload --port 8000
```

Documentación interactiva automática: `http://localhost:8000/docs`

## Notas de implementación (para continuar en Claude Code / Windsurf)

- **Auth**: el login actual usa un código OTP fijo (`OTP_DEV_CODE`) para desarrollo.
  Pendiente: integrar un proveedor real (Twilio, WhatsApp Business API) en
  `app/routers/auth.py` → `solicitar_otp`.
- **Uploads de video/foto/DNI**: los endpoints reciben URLs (`thumb_url`, `video_url`,
  `foto_url`, `dni_url`) asumiendo que el archivo ya se subió a un storage externo
  (S3, Cloudinary, Supabase Storage). Falta implementar el endpoint de subida directa
  si se prefiere que el backend la maneje.
- **Pagos**: `app/routers/planes.py` deja los endpoints de pago como placeholders.
  Falta integrar la pasarela real (Culqi/Niubiz para tarjeta, un agregador para
  Yape/Plin) y mover la confirmación a un **webhook**, no a una llamada directa del
  cliente como está ahora (eso es solo para poder probar el flujo end-to-end).
- **Alertas de talento**: el modelo `Alerta` ya existe; falta el job programado
  (Celery/APScheduler o un cron) que las evalúe contra nuevos jugadores y dispare
  `Notificacion`.
- **Explorar con disponibilidad por fecha**: el filtro de `disponible_fecha` está en
  el esquema (`FiltroExplorar`) pero falta conectarlo al endpoint `/captadores/explorar`
  (requiere un join contra `Disponibilidad`).
- Todos los endpoints devuelven/reciben JSON con nombres de campo en snake_case,
  igual que el modelo de datos del documento de arquitectura, para que el mapeo con
  el frontend Flutter sea directo.

## Comandos útiles de Alembic

```bash
alembic revision --autogenerate -m "descripcion del cambio"
alembic upgrade head
alembic downgrade -1
```
