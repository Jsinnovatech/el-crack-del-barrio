from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.deps import get_current_user, require_role

router = APIRouter(prefix="/jugadores", tags=["jugadores"])

MAX_VIDEOS = 5
MAX_FOTOS = 8


def _mi_perfil(db: Session, usuario: models.Usuario) -> models.PerfilJugador:
    perfil = db.query(models.PerfilJugador).filter_by(usuario_id=usuario.id).first()
    if not perfil:
        raise HTTPException(404, "Perfil de jugador no encontrado")
    return perfil


# ---------- Perfil propio ----------
@router.get("/me", response_model=schemas.PerfilJugadorOut)
def obtener_mi_perfil(
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    return _mi_perfil(db, usuario)


@router.put("/me", response_model=schemas.PerfilJugadorOut)
def actualizar_mi_perfil(
    payload: schemas.PerfilJugadorUpdate,
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    for campo, valor in payload.model_dump(exclude_unset=True).items():
        setattr(perfil, campo, valor)
    db.commit()
    db.refresh(perfil)
    return perfil


@router.post("/me/dni", response_model=schemas.PerfilJugadorOut)
def subir_dni(
    payload: schemas.DNIUpload,
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    perfil.dni_url = payload.dni_url
    perfil.verificado = False
    db.commit()
    db.refresh(perfil)
    return perfil


@router.get("/me/estadisticas", response_model=schemas.EstadisticasJugador)
def mis_estadisticas(
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    vistas = db.query(func.sum(models.Video.vistas)).filter_by(jugador_id=perfil.id).scalar() or 0
    contactos = db.query(func.count(models.Contacto.id)).filter_by(jugador_id=perfil.id).scalar() or 0
    favoritos = db.query(func.count(models.Favorito.id)).filter_by(jugador_id=perfil.id).scalar() or 0
    videos = db.query(func.count(models.Video.id)).filter_by(jugador_id=perfil.id).scalar() or 0
    return schemas.EstadisticasJugador(
        vistas_total=int(vistas),
        contactos_total=int(contactos),
        favoritos_total=int(favoritos),
        videos_count=int(videos),
    )


# ---------- Videos (máx 5) ----------
@router.get("/me/videos", response_model=list[schemas.VideoOut])
def listar_mis_videos(
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    return _mi_perfil(db, usuario).videos


@router.post("/me/videos", response_model=schemas.VideoOut)
def subir_video(
    payload: schemas.VideoCreate,
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    if len(perfil.videos) >= MAX_VIDEOS:
        raise HTTPException(400, f"Máximo {MAX_VIDEOS} videos permitidos")
    orden = len(perfil.videos)
    video = models.Video(jugador_id=perfil.id, orden=orden, **payload.model_dump())
    db.add(video)
    db.commit()
    db.refresh(video)
    return video


@router.delete("/me/videos/{video_id}")
def eliminar_video(
    video_id: str,
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    video = db.get(models.Video, video_id)
    if not video or video.jugador_id != perfil.id:
        raise HTTPException(404, "Video no encontrado")
    db.delete(video)
    db.commit()
    return {"ok": True}


@router.post("/me/videos/{video_id}/destacar", response_model=schemas.VideoOut)
def marcar_destacado(
    video_id: str,
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    video = db.get(models.Video, video_id)
    if not video or video.jugador_id != perfil.id:
        raise HTTPException(404, "Video no encontrado")
    for v in perfil.videos:
        v.destacado = v.id == video_id and not video.destacado
    db.commit()
    db.refresh(video)
    return video


@router.put("/me/videos/orden")
def reordenar_videos(
    payload: schemas.VideoReorder,
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    ids_validos = {v.id for v in perfil.videos}
    for i, video_id in enumerate(payload.orden_ids):
        if video_id not in ids_validos:
            raise HTTPException(400, f"Video {video_id} no pertenece a este perfil")
        db.query(models.Video).filter_by(id=video_id).update({"orden": i})
    db.commit()
    return {"ok": True}


# ---------- Historial Deportivo ----------
@router.get("/me/historial", response_model=list[schemas.HistorialOut])
def listar_historial(
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    return _mi_perfil(db, usuario).historial


@router.post("/me/historial", response_model=schemas.HistorialOut)
def agregar_historial(
    payload: schemas.HistorialCreate,
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    entrada = models.HistorialDeportivo(jugador_id=perfil.id, **payload.model_dump())
    db.add(entrada)
    db.commit()
    db.refresh(entrada)
    return entrada


@router.delete("/me/historial/{historial_id}")
def eliminar_historial(
    historial_id: str,
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    entrada = db.get(models.HistorialDeportivo, historial_id)
    if not entrada or entrada.jugador_id != perfil.id:
        raise HTTPException(404, "Entrada de historial no encontrada")
    db.delete(entrada)
    db.commit()
    return {"ok": True}


# ---------- Franjas de Disponibilidad ----------
@router.get("/me/disponibilidad", response_model=list[schemas.FranjaOut])
def listar_disponibilidad(
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    return _mi_perfil(db, usuario).disponibilidad


@router.post("/me/disponibilidad", response_model=schemas.FranjaOut)
def agregar_franja(
    payload: schemas.FranjaCreate,
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    franja = models.FranjaDisponibilidad(jugador_id=perfil.id, **payload.model_dump())
    db.add(franja)

    from datetime import datetime, timezone
    perfil.ultima_actualizacion_calendario = datetime.now(timezone.utc)

    db.commit()
    db.refresh(franja)
    return franja


@router.delete("/me/disponibilidad/{franja_id}")
def eliminar_franja(
    franja_id: str,
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    franja = db.get(models.FranjaDisponibilidad, franja_id)
    if not franja or franja.jugador_id != perfil.id:
        raise HTTPException(404, "Franja no encontrada")
    db.delete(franja)
    db.commit()
    return {"ok": True}


# ---------- Fotos de Equipos (máx 8) ----------
@router.get("/me/fotos", response_model=list[schemas.FotoEquipoOut])
def listar_fotos(
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    return _mi_perfil(db, usuario).fotos


@router.post("/me/fotos", response_model=schemas.FotoEquipoOut)
def agregar_foto(
    payload: schemas.FotoEquipoCreate,
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    if len(perfil.fotos) >= MAX_FOTOS:
        raise HTTPException(400, f"Máximo {MAX_FOTOS} fotos permitidas")
    orden = len(perfil.fotos)
    foto = models.FotoEquipo(jugador_id=perfil.id, orden=orden, **payload.model_dump())
    db.add(foto)
    db.commit()
    db.refresh(foto)
    return foto


@router.delete("/me/fotos/{foto_id}")
def eliminar_foto(
    foto_id: str,
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    foto = db.get(models.FotoEquipo, foto_id)
    if not foto or foto.jugador_id != perfil.id:
        raise HTTPException(404, "Foto no encontrada")
    db.delete(foto)
    db.commit()
    return {"ok": True}


# ---------- Clubes (legacy) ----------
@router.get("/me/clubes", response_model=list[schemas.ClubOut])
def listar_clubes(
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    return _mi_perfil(db, usuario).clubes


@router.post("/me/clubes", response_model=schemas.ClubOut)
def agregar_club(
    payload: schemas.ClubCreate,
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    club = models.Club(jugador_id=perfil.id, **payload.model_dump())
    db.add(club)
    db.commit()
    db.refresh(club)
    return club


@router.delete("/me/clubes/{club_id}")
def eliminar_club(
    club_id: str,
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    club = db.get(models.Club, club_id)
    if not club or club.jugador_id != perfil.id:
        raise HTTPException(404, "Club no encontrado")
    db.delete(club)
    db.commit()
    return {"ok": True}


# ---------- Endpoints públicos ----------
@router.get("/{jugador_id}", response_model=schemas.PerfilJugadorOut)
def ver_perfil_publico(jugador_id: str, db: Session = Depends(get_db)):
    perfil = db.get(models.PerfilJugador, jugador_id)
    if not perfil:
        raise HTTPException(404, "Jugador no encontrado")
    return perfil


@router.get("/{jugador_id}/videos", response_model=list[schemas.VideoOut])
def ver_videos_publicos(jugador_id: str, db: Session = Depends(get_db)):
    perfil = db.get(models.PerfilJugador, jugador_id)
    if not perfil:
        raise HTTPException(404, "Jugador no encontrado")
    return perfil.videos


@router.get("/{jugador_id}/disponibilidad", response_model=list[schemas.FranjaOut])
def ver_disponibilidad_publica(jugador_id: str, db: Session = Depends(get_db)):
    perfil = db.get(models.PerfilJugador, jugador_id)
    if not perfil:
        raise HTTPException(404, "Jugador no encontrado")
    return perfil.disponibilidad


@router.get("/{jugador_id}/fotos", response_model=list[schemas.FotoEquipoOut])
def ver_fotos_publicas(jugador_id: str, db: Session = Depends(get_db)):
    perfil = db.get(models.PerfilJugador, jugador_id)
    if not perfil:
        raise HTTPException(404, "Jugador no encontrado")
    return perfil.fotos


@router.get("/{jugador_id}/historial", response_model=list[schemas.HistorialOut])
def ver_historial_publico(jugador_id: str, db: Session = Depends(get_db)):
    perfil = db.get(models.PerfilJugador, jugador_id)
    if not perfil:
        raise HTTPException(404, "Jugador no encontrado")
    return perfil.historial


@router.get("/{jugador_id}/calificaciones", response_model=list[schemas.CalificacionOut])
def ver_calificaciones(jugador_id: str, db: Session = Depends(get_db)):
    perfil = db.get(models.PerfilJugador, jugador_id)
    if not perfil:
        raise HTTPException(404, "Jugador no encontrado")
    return perfil.calificaciones
