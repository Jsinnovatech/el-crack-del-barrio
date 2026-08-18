from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text

from app.core.config import settings
from app.routers import auth, captadores, jugadores, notificaciones, planes


def _run_migrations(engine):
    """Migraciones incrementales sin Alembic — safe para Railway."""
    sql_steps = [
        # Módulo 1 — contacto en perfil jugador
        "ALTER TABLE perfiles_jugador ADD COLUMN IF NOT EXISTS telefono VARCHAR;",
        "ALTER TABLE perfiles_jugador ADD COLUMN IF NOT EXISTS whatsapp VARCHAR;",
        # Módulo 2 — historial deportivo (tabla nueva, create_all la crea)
        # Módulo 3 — fotos equipo (tabla nueva, create_all la crea)
        # Módulo 4 — franjas disponibilidad (tabla nueva, create_all la crea)
        # La tabla antigua 'disponibilidad' se mantiene intacta para no perder datos
    ]
    with engine.connect() as conn:
        for step in sql_steps:
            try:
                conn.execute(text(step))
            except Exception:
                pass  # columna ya existe u otro error no crítico
        conn.commit()


@asynccontextmanager
async def lifespan(app: FastAPI):
    from app.database import engine
    from app.models import Base  # noqa: F401
    # Crear tablas nuevas (historial_deportivo, fotos_equipo, franjas_disponibilidad)
    Base.metadata.create_all(bind=engine)
    # Agregar columnas nuevas en tablas existentes
    _run_migrations(engine)
    yield


app = FastAPI(
    title="Vitrina Deportiva — API",
    description="API REST para la app de jugadores y captadores de fútbol.",
    version="2.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(jugadores.router)
app.include_router(captadores.router)
app.include_router(planes.router)
app.include_router(notificaciones.router)


@app.get("/", tags=["salud"])
def raiz():
    return {"app": "Vitrina Deportiva", "estado": "ok", "version": "2.0.0"}


@app.get("/salud", tags=["salud"])
def salud():
    return {"estado": "ok"}
