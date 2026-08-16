from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.routers import auth, captadores, jugadores, notificaciones, planes


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Crear tablas automáticamente en desarrollo (sin migraciones alembic)
    from app.database import engine
    from app.models import Base  # noqa: F401
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(
    title="El Crack del Barrio — API",
    description="API REST para la app de jugadores y captadores de fútbol. "
                "Código OTP de desarrollo: 123456.",
    version="1.0.0",
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
    return {"app": "El Crack del Barrio", "estado": "ok", "version": "1.0.0"}


@app.get("/salud", tags=["salud"])
def salud():
    return {"estado": "ok"}
