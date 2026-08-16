from __future__ import annotations

from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field

from app.models import EstadoDisponibilidad, EstadoPago, EstadoPrueba, MetodoPago, Rol


# ---------- Auth / Usuario ----------
class UsuarioRegistro(BaseModel):
    nombre: str
    celular: str
    rol: Rol


class OTPVerificar(BaseModel):
    celular: str
    codigo: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    usuario: "UsuarioOut"


class UsuarioOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    nombre: str
    celular: str
    rol: Rol
    creado_en: datetime


# ---------- Jugador público (para exploración por captadores) ----------
class JugadorPublicoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    foto_url: Optional[str] = None
    verificado: bool = False
    posicion_principal: Optional[str] = None
    posiciones_secundarias: list[str] = []
    edad: Optional[int] = None
    ciudad: Optional[str] = None
    rating: float = 0
    plan_id: Optional[str] = None
    # Nombre del usuario (se agrega manualmente desde el router)
    nombre_usuario: Optional[str] = None


class EstadisticasJugador(BaseModel):
    vistas_total: int = 0
    contactos_total: int = 0
    favoritos_total: int = 0
    videos_count: int = 0


# ---------- Perfil Jugador ----------
class PerfilJugadorUpdate(BaseModel):
    foto_url: Optional[str] = None
    bio: Optional[str] = Field(default=None, min_length=10)
    posicion_principal: Optional[str] = None
    posiciones_secundarias: Optional[list[str]] = None
    edad: Optional[int] = None
    ciudad: Optional[str] = None


class PerfilJugadorOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    usuario_id: str
    foto_url: Optional[str]
    dni_url: Optional[str]
    verificado: bool
    bio: Optional[str]
    posicion_principal: Optional[str]
    posiciones_secundarias: list[str]
    edad: Optional[int]
    ciudad: Optional[str]
    rating: float
    plan_id: Optional[str]
    streak: int


class DNIUpload(BaseModel):
    dni_url: str


# ---------- Video ----------
class VideoCreate(BaseModel):
    titulo: str
    thumb_url: Optional[str] = None
    video_url: Optional[str] = None


class VideoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    titulo: str
    thumb_url: Optional[str]
    video_url: Optional[str]
    vistas: int
    destacado: bool
    orden: int


class VideoReorder(BaseModel):
    orden_ids: list[str]  # lista de video_id en el nuevo orden


# ---------- Club ----------
class ClubCreate(BaseModel):
    nombre: str
    tipo: str
    anio: Optional[int] = None


class ClubOut(ClubCreate):
    model_config = ConfigDict(from_attributes=True)
    id: str


# ---------- Disponibilidad ----------
class DisponibilidadUpsert(BaseModel):
    fecha: date
    estado: EstadoDisponibilidad
    hora_desde: Optional[str] = None
    hora_hasta: Optional[str] = None


class DisponibilidadOut(DisponibilidadUpsert):
    model_config = ConfigDict(from_attributes=True)
    id: str


# ---------- Plan / Pago ----------
class PlanOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    nombre: str
    precio: float
    unidad: str
    beneficios: list[str]
    destacado: bool


class PagoCreate(BaseModel):
    plan_id: str
    metodo: MetodoPago


class PagoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    plan_id: str
    monto: float
    metodo: MetodoPago
    estado: EstadoPago
    creado_en: datetime


# ---------- Captador ----------
class PerfilCaptadorUpdate(BaseModel):
    club_representa: Optional[str] = None
    zona_interes: Optional[str] = None


class PerfilCaptadorOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    usuario_id: str
    club_representa: Optional[str]
    zona_interes: Optional[str]


# ---------- Favoritos / Contactos / Pruebas / Calificaciones ----------
class FavoritoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    jugador_id: str


class ContactoCreate(BaseModel):
    jugador_id: str


class ContactoOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    jugador_id: str


class PruebaCreate(BaseModel):
    jugador_id: str
    fecha: Optional[date] = None
    hora: Optional[str] = None
    lugar: Optional[str] = None


class PruebaOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    jugador_id: str
    fecha: Optional[date]
    hora: Optional[str]
    lugar: Optional[str]
    estado: EstadoPrueba


class PruebaEstadoUpdate(BaseModel):
    estado: EstadoPrueba


class CalificacionCreate(BaseModel):
    jugador_id: str
    estrellas: int = Field(ge=1, le=5)
    comentario: Optional[str] = None


class CalificacionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    jugador_id: str
    estrellas: int
    comentario: Optional[str]


# ---------- Búsquedas guardadas / Alertas / Notificaciones ----------
class BusquedaGuardadaCreate(BaseModel):
    nombre: str
    filtros: dict


class BusquedaGuardadaOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    nombre: str
    filtros: dict


class AlertaCreate(BaseModel):
    posicion: Optional[str] = None
    ciudad: Optional[str] = None
    edad_max: Optional[int] = None


class AlertaOut(AlertaCreate):
    model_config = ConfigDict(from_attributes=True)
    id: str


class NotificacionOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    tipo: str
    texto: str
    leido: bool
    creado_en: datetime


# ---------- Explorar (filtros de búsqueda) ----------
class FiltroExplorar(BaseModel):
    posicion: Optional[str] = None
    busqueda: Optional[str] = None
    edad_min: int = 16
    edad_max: int = 40
    ciudad: Optional[str] = None
    rating_min: float = 0
    solo_verificados: bool = False
    disponible_fecha: Optional[date] = None
    orden: str = "rating"  # rating | vistas | verificado | edad
