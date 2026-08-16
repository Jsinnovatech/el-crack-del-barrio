from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.deps import require_role

router = APIRouter(prefix="/captadores", tags=["captadores"])


def _mi_perfil(db: Session, usuario: models.Usuario) -> models.PerfilCaptador:
    perfil = db.query(models.PerfilCaptador).filter_by(usuario_id=usuario.id).first()
    if not perfil:
        raise HTTPException(404, "Perfil de captador no encontrado")
    return perfil


def _jugador_a_publico(perfil: models.PerfilJugador, db: Session) -> schemas.JugadorPublicoOut:
    usuario = db.get(models.Usuario, perfil.usuario_id)
    return schemas.JugadorPublicoOut(
        id=perfil.id,
        foto_url=perfil.foto_url,
        verificado=perfil.verificado,
        posicion_principal=perfil.posicion_principal,
        posiciones_secundarias=perfil.posiciones_secundarias or [],
        edad=perfil.edad,
        ciudad=perfil.ciudad,
        rating=float(perfil.rating or 0),
        plan_id=perfil.plan_id,
        nombre_usuario=usuario.nombre if usuario else None,
    )


@router.get("/me", response_model=schemas.PerfilCaptadorOut)
def obtener_mi_perfil(
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    return _mi_perfil(db, usuario)


@router.put("/me", response_model=schemas.PerfilCaptadorOut)
def actualizar_mi_perfil(
    payload: schemas.PerfilCaptadorUpdate,
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    for campo, valor in payload.model_dump(exclude_unset=True).items():
        setattr(perfil, campo, valor)
    db.commit()
    db.refresh(perfil)
    return perfil


# ---------- Explorar / filtrar jugadores ----------
@router.get("/explorar", response_model=list[schemas.JugadorPublicoOut])
def explorar_jugadores_get(
    posicion: str | None = None,
    busqueda: str | None = None,
    edad_min: int = 16,
    edad_max: int = 40,
    ciudad: str | None = None,
    rating_min: float = 0,
    solo_verificados: bool = False,
    orden: str = "rating",
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    filtros = schemas.FiltroExplorar(
        posicion=posicion, busqueda=busqueda, edad_min=edad_min, edad_max=edad_max,
        ciudad=ciudad, rating_min=rating_min, solo_verificados=solo_verificados, orden=orden,
    )
    return _ejecutar_explorar(filtros, db)


@router.post("/explorar", response_model=list[schemas.JugadorPublicoOut])
def explorar_jugadores_post(
    filtros: schemas.FiltroExplorar,
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    return _ejecutar_explorar(filtros, db)


def _ejecutar_explorar(filtros: schemas.FiltroExplorar, db: Session) -> list[schemas.JugadorPublicoOut]:
    q = db.query(models.PerfilJugador)

    if filtros.posicion:
        q = q.filter(models.PerfilJugador.posicion_principal.ilike(f"%{filtros.posicion}%"))

    if filtros.busqueda:
        q = q.join(models.Usuario, models.Usuario.id == models.PerfilJugador.usuario_id).filter(
            models.Usuario.nombre.ilike(f"%{filtros.busqueda}%")
        )

    if filtros.ciudad:
        q = q.filter(models.PerfilJugador.ciudad.ilike(f"%{filtros.ciudad}%"))

    if filtros.solo_verificados:
        q = q.filter(models.PerfilJugador.verificado.is_(True))

    q = q.filter(
        (models.PerfilJugador.edad.is_(None))
        | (
            (models.PerfilJugador.edad >= filtros.edad_min)
            & (models.PerfilJugador.edad <= filtros.edad_max)
        )
    )
    q = q.filter(models.PerfilJugador.rating >= filtros.rating_min)

    if filtros.orden == "edad":
        q = q.order_by(models.PerfilJugador.edad.asc())
    elif filtros.orden == "verificado":
        q = q.order_by(models.PerfilJugador.verificado.desc(), models.PerfilJugador.rating.desc())
    else:
        q = q.order_by(models.PerfilJugador.rating.desc())

    perfiles = q.limit(100).all()
    return [_jugador_a_publico(p, db) for p in perfiles]


# ---------- Favoritos ----------
@router.get("/me/favoritos", response_model=list[schemas.JugadorPublicoOut])
def listar_favoritos(
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    resultado = []
    for fav in perfil.favoritos:
        jugador = db.get(models.PerfilJugador, fav.jugador_id)
        if jugador:
            resultado.append(_jugador_a_publico(jugador, db))
    return resultado


@router.post("/me/favoritos/{jugador_id}", response_model=schemas.FavoritoOut)
def agregar_favorito(
    jugador_id: str,
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    existente = db.query(models.Favorito).filter_by(captador_id=perfil.id, jugador_id=jugador_id).first()
    if existente:
        return existente
    fav = models.Favorito(captador_id=perfil.id, jugador_id=jugador_id)
    db.add(fav)
    db.commit()
    db.refresh(fav)
    return fav


@router.delete("/me/favoritos/{jugador_id}")
def quitar_favorito(
    jugador_id: str,
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    db.query(models.Favorito).filter_by(captador_id=perfil.id, jugador_id=jugador_id).delete()
    db.commit()
    return {"ok": True}


# ---------- Contactos ----------
@router.post("/me/contactos", response_model=schemas.ContactoOut)
def registrar_contacto(
    payload: schemas.ContactoCreate,
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    contacto = models.Contacto(captador_id=perfil.id, jugador_id=payload.jugador_id)
    db.add(contacto)
    db.commit()
    db.refresh(contacto)
    return contacto


# ---------- Pruebas ----------
@router.get("/me/pruebas", response_model=list[schemas.PruebaOut])
def listar_pruebas(
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    return perfil.pruebas


@router.post("/me/pruebas", response_model=schemas.PruebaOut)
def agendar_prueba(
    payload: schemas.PruebaCreate,
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    prueba = models.Prueba(captador_id=perfil.id, **payload.model_dump())
    db.add(prueba)
    db.commit()
    db.refresh(prueba)
    return prueba


@router.put("/me/pruebas/{prueba_id}/estado", response_model=schemas.PruebaOut)
def actualizar_estado_prueba(
    prueba_id: str,
    payload: schemas.PruebaEstadoUpdate,
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    prueba = db.get(models.Prueba, prueba_id)
    if not prueba or prueba.captador_id != perfil.id:
        raise HTTPException(404, "Prueba no encontrada")
    prueba.estado = payload.estado
    db.commit()
    db.refresh(prueba)
    return prueba


# ---------- Calificaciones ----------
@router.post("/me/calificaciones", response_model=schemas.CalificacionOut)
def calificar_jugador(
    payload: schemas.CalificacionCreate,
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    existente = db.query(models.Calificacion).filter_by(
        captador_id=perfil.id, jugador_id=payload.jugador_id
    ).first()
    if existente:
        existente.estrellas = payload.estrellas
        existente.comentario = payload.comentario
        calificacion = existente
    else:
        calificacion = models.Calificacion(captador_id=perfil.id, **payload.model_dump())
        db.add(calificacion)
    db.commit()
    db.refresh(calificacion)

    # Recalcular rating promedio del jugador
    jugador = db.get(models.PerfilJugador, payload.jugador_id)
    if jugador:
        todas = db.query(models.Calificacion).filter_by(jugador_id=payload.jugador_id).all()
        jugador.rating = sum(c.estrellas for c in todas) / len(todas)
        db.commit()

    return calificacion


@router.get("/me/calificaciones", response_model=list[schemas.CalificacionOut])
def mis_calificaciones(
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    return perfil.calificaciones


# ---------- Búsquedas guardadas ----------
@router.get("/me/busquedas", response_model=list[schemas.BusquedaGuardadaOut])
def listar_busquedas(
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    return perfil.busquedas


@router.post("/me/busquedas", response_model=schemas.BusquedaGuardadaOut)
def guardar_busqueda(
    payload: schemas.BusquedaGuardadaCreate,
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    busqueda = models.BusquedaGuardada(captador_id=perfil.id, **payload.model_dump())
    db.add(busqueda)
    db.commit()
    db.refresh(busqueda)
    return busqueda


@router.delete("/me/busquedas/{busqueda_id}")
def eliminar_busqueda(
    busqueda_id: str,
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    db.query(models.BusquedaGuardada).filter_by(id=busqueda_id, captador_id=perfil.id).delete()
    db.commit()
    return {"ok": True}


# ---------- Alertas de talento ----------
@router.get("/me/alertas", response_model=list[schemas.AlertaOut])
def listar_alertas(
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    return perfil.alertas


@router.post("/me/alertas", response_model=schemas.AlertaOut)
def crear_alerta(
    payload: schemas.AlertaCreate,
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    alerta = models.Alerta(captador_id=perfil.id, **payload.model_dump())
    db.add(alerta)
    db.commit()
    db.refresh(alerta)
    return alerta


@router.delete("/me/alertas/{alerta_id}")
def eliminar_alerta(
    alerta_id: str,
    usuario: models.Usuario = Depends(require_role("captador")),
    db: Session = Depends(get_db),
):
    perfil = _mi_perfil(db, usuario)
    db.query(models.Alerta).filter_by(id=alerta_id, captador_id=perfil.id).delete()
    db.commit()
    return {"ok": True}
