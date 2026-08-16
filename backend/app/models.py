import enum
import uuid

from sqlalchemy import (
    Boolean, Column, Date, DateTime, Enum, ForeignKey, Integer,
    Numeric, String, Text, UniqueConstraint, func,
)
from sqlalchemy.dialects.postgresql import ARRAY, JSONB
from sqlalchemy.orm import relationship

from app.database import Base


def gen_uuid() -> str:
    return str(uuid.uuid4())


class Rol(str, enum.Enum):
    jugador = "jugador"
    captador = "captador"


class EstadoDisponibilidad(str, enum.Enum):
    disponible = "disponible"
    contratado = "contratado"
    no_disponible = "no_disponible"


class EstadoPago(str, enum.Enum):
    pendiente = "pendiente"
    confirmado = "confirmado"
    fallido = "fallido"


class MetodoPago(str, enum.Enum):
    yape = "yape"
    plin = "plin"
    tarjeta = "tarjeta"


class EstadoPrueba(str, enum.Enum):
    pendiente = "pendiente"
    confirmada = "confirmada"
    realizada = "realizada"


class Usuario(Base):
    __tablename__ = "usuarios"

    id = Column(String, primary_key=True, default=gen_uuid)
    nombre = Column(String, nullable=False)
    celular = Column(String, unique=True, nullable=False, index=True)
    rol = Column(Enum(Rol), nullable=False)
    password_hash = Column(String, nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())

    perfil_jugador = relationship("PerfilJugador", back_populates="usuario", uselist=False, cascade="all, delete-orphan")
    perfil_captador = relationship("PerfilCaptador", back_populates="usuario", uselist=False, cascade="all, delete-orphan")
    notificaciones = relationship("Notificacion", back_populates="usuario", cascade="all, delete-orphan")


class PerfilJugador(Base):
    __tablename__ = "perfiles_jugador"

    id = Column(String, primary_key=True, default=gen_uuid)
    usuario_id = Column(String, ForeignKey("usuarios.id", ondelete="CASCADE"), unique=True, nullable=False)
    foto_url = Column(String, nullable=True)
    dni_url = Column(String, nullable=True)
    verificado = Column(Boolean, default=False)
    bio = Column(Text, nullable=True)
    posicion_principal = Column(String, nullable=True)
    posiciones_secundarias = Column(ARRAY(String), default=list)
    edad = Column(Integer, nullable=True)
    ciudad = Column(String, nullable=True)
    rating = Column(Numeric(3, 2), default=0)
    plan_id = Column(String, ForeignKey("planes.id"), nullable=True)
    plan_expira = Column(DateTime(timezone=True), nullable=True)
    streak = Column(Integer, default=0)
    ultima_actualizacion_calendario = Column(DateTime(timezone=True), nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())

    usuario = relationship("Usuario", back_populates="perfil_jugador")
    plan = relationship("Plan", back_populates="jugadores")
    videos = relationship("Video", back_populates="jugador", cascade="all, delete-orphan", order_by="Video.orden")
    clubes = relationship("Club", back_populates="jugador", cascade="all, delete-orphan")
    disponibilidad = relationship("Disponibilidad", back_populates="jugador", cascade="all, delete-orphan")
    pagos = relationship("Pago", back_populates="jugador", cascade="all, delete-orphan")
    favorito_de = relationship("Favorito", back_populates="jugador", cascade="all, delete-orphan")
    contactado_por = relationship("Contacto", back_populates="jugador", cascade="all, delete-orphan")
    pruebas = relationship("Prueba", back_populates="jugador", cascade="all, delete-orphan")
    calificaciones = relationship("Calificacion", back_populates="jugador", cascade="all, delete-orphan")


class Video(Base):
    __tablename__ = "videos"

    id = Column(String, primary_key=True, default=gen_uuid)
    jugador_id = Column(String, ForeignKey("perfiles_jugador.id", ondelete="CASCADE"), nullable=False)
    titulo = Column(String, nullable=False)
    thumb_url = Column(String, nullable=True)
    video_url = Column(String, nullable=True)
    vistas = Column(Integer, default=0)
    destacado = Column(Boolean, default=False)
    orden = Column(Integer, default=0)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())

    jugador = relationship("PerfilJugador", back_populates="videos")


class Club(Base):
    __tablename__ = "clubes"

    id = Column(String, primary_key=True, default=gen_uuid)
    jugador_id = Column(String, ForeignKey("perfiles_jugador.id", ondelete="CASCADE"), nullable=False)
    nombre = Column(String, nullable=False)
    tipo = Column(String, nullable=False)  # 'club' | 'campeon' | 'subcampeon'
    anio = Column(Integer, nullable=True)

    jugador = relationship("PerfilJugador", back_populates="clubes")


class Disponibilidad(Base):
    __tablename__ = "disponibilidad"
    __table_args__ = (UniqueConstraint("jugador_id", "fecha", name="uq_disponibilidad_jugador_fecha"),)

    id = Column(String, primary_key=True, default=gen_uuid)
    jugador_id = Column(String, ForeignKey("perfiles_jugador.id", ondelete="CASCADE"), nullable=False)
    fecha = Column(Date, nullable=False)
    estado = Column(Enum(EstadoDisponibilidad), nullable=False)
    hora_desde = Column(String, nullable=True)
    hora_hasta = Column(String, nullable=True)

    jugador = relationship("PerfilJugador", back_populates="disponibilidad")


class Plan(Base):
    __tablename__ = "planes"

    id = Column(String, primary_key=True, default=gen_uuid)
    nombre = Column(String, nullable=False)
    precio = Column(Numeric(10, 2), nullable=False)
    unidad = Column(String, nullable=False)
    beneficios = Column(ARRAY(String), default=list)
    destacado = Column(Boolean, default=False)
    activo = Column(Boolean, default=True)

    jugadores = relationship("PerfilJugador", back_populates="plan")
    pagos = relationship("Pago", back_populates="plan")


class Pago(Base):
    __tablename__ = "pagos"

    id = Column(String, primary_key=True, default=gen_uuid)
    jugador_id = Column(String, ForeignKey("perfiles_jugador.id", ondelete="CASCADE"), nullable=False)
    plan_id = Column(String, ForeignKey("planes.id"), nullable=False)
    monto = Column(Numeric(10, 2), nullable=False)
    metodo = Column(Enum(MetodoPago), nullable=False)
    estado = Column(Enum(EstadoPago), default=EstadoPago.pendiente)
    referencia_externa = Column(String, nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())

    jugador = relationship("PerfilJugador", back_populates="pagos")
    plan = relationship("Plan", back_populates="pagos")


class PerfilCaptador(Base):
    __tablename__ = "perfiles_captador"

    id = Column(String, primary_key=True, default=gen_uuid)
    usuario_id = Column(String, ForeignKey("usuarios.id", ondelete="CASCADE"), unique=True, nullable=False)
    club_representa = Column(String, nullable=True)
    zona_interes = Column(String, nullable=True)

    usuario = relationship("Usuario", back_populates="perfil_captador")
    favoritos = relationship("Favorito", back_populates="captador", cascade="all, delete-orphan")
    contactos = relationship("Contacto", back_populates="captador", cascade="all, delete-orphan")
    pruebas = relationship("Prueba", back_populates="captador", cascade="all, delete-orphan")
    calificaciones = relationship("Calificacion", back_populates="captador", cascade="all, delete-orphan")
    busquedas = relationship("BusquedaGuardada", back_populates="captador", cascade="all, delete-orphan")
    alertas = relationship("Alerta", back_populates="captador", cascade="all, delete-orphan")


class Favorito(Base):
    __tablename__ = "favoritos"
    __table_args__ = (UniqueConstraint("captador_id", "jugador_id", name="uq_favorito"),)

    id = Column(String, primary_key=True, default=gen_uuid)
    captador_id = Column(String, ForeignKey("perfiles_captador.id", ondelete="CASCADE"), nullable=False)
    jugador_id = Column(String, ForeignKey("perfiles_jugador.id", ondelete="CASCADE"), nullable=False)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())

    captador = relationship("PerfilCaptador", back_populates="favoritos")
    jugador = relationship("PerfilJugador", back_populates="favorito_de")


class Contacto(Base):
    __tablename__ = "contactos"

    id = Column(String, primary_key=True, default=gen_uuid)
    captador_id = Column(String, ForeignKey("perfiles_captador.id", ondelete="CASCADE"), nullable=False)
    jugador_id = Column(String, ForeignKey("perfiles_jugador.id", ondelete="CASCADE"), nullable=False)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())

    captador = relationship("PerfilCaptador", back_populates="contactos")
    jugador = relationship("PerfilJugador", back_populates="contactado_por")


class Prueba(Base):
    __tablename__ = "pruebas"

    id = Column(String, primary_key=True, default=gen_uuid)
    captador_id = Column(String, ForeignKey("perfiles_captador.id", ondelete="CASCADE"), nullable=False)
    jugador_id = Column(String, ForeignKey("perfiles_jugador.id", ondelete="CASCADE"), nullable=False)
    fecha = Column(Date, nullable=True)
    hora = Column(String, nullable=True)
    lugar = Column(String, nullable=True)
    estado = Column(Enum(EstadoPrueba), default=EstadoPrueba.pendiente)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())

    captador = relationship("PerfilCaptador", back_populates="pruebas")
    jugador = relationship("PerfilJugador", back_populates="pruebas")


class Calificacion(Base):
    __tablename__ = "calificaciones"
    __table_args__ = (UniqueConstraint("captador_id", "jugador_id", name="uq_calificacion"),)

    id = Column(String, primary_key=True, default=gen_uuid)
    captador_id = Column(String, ForeignKey("perfiles_captador.id", ondelete="CASCADE"), nullable=False)
    jugador_id = Column(String, ForeignKey("perfiles_jugador.id", ondelete="CASCADE"), nullable=False)
    estrellas = Column(Integer, nullable=False)
    comentario = Column(Text, nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())

    captador = relationship("PerfilCaptador", back_populates="calificaciones")
    jugador = relationship("PerfilJugador", back_populates="calificaciones")


class BusquedaGuardada(Base):
    __tablename__ = "busquedas_guardadas"

    id = Column(String, primary_key=True, default=gen_uuid)
    captador_id = Column(String, ForeignKey("perfiles_captador.id", ondelete="CASCADE"), nullable=False)
    nombre = Column(String, nullable=False)
    filtros = Column(JSONB, nullable=False)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())

    captador = relationship("PerfilCaptador", back_populates="busquedas")


class Alerta(Base):
    __tablename__ = "alertas"

    id = Column(String, primary_key=True, default=gen_uuid)
    captador_id = Column(String, ForeignKey("perfiles_captador.id", ondelete="CASCADE"), nullable=False)
    posicion = Column(String, nullable=True)
    ciudad = Column(String, nullable=True)
    edad_max = Column(Integer, nullable=True)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())

    captador = relationship("PerfilCaptador", back_populates="alertas")


class Notificacion(Base):
    __tablename__ = "notificaciones"

    id = Column(String, primary_key=True, default=gen_uuid)
    usuario_id = Column(String, ForeignKey("usuarios.id", ondelete="CASCADE"), nullable=False)
    tipo = Column(String, nullable=False)
    texto = Column(String, nullable=False)
    leido = Column(Boolean, default=False)
    creado_en = Column(DateTime(timezone=True), server_default=func.now())

    usuario = relationship("Usuario", back_populates="notificaciones")
