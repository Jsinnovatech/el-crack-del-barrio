from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.deps import get_current_user

router = APIRouter(prefix="/notificaciones", tags=["notificaciones"])


@router.get("", response_model=list[schemas.NotificacionOut])
def listar_notificaciones(
    usuario: models.Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(models.Notificacion)
        .filter_by(usuario_id=usuario.id)
        .order_by(models.Notificacion.creado_en.desc())
        .all()
    )


@router.patch("/{notif_id}/leer", response_model=schemas.NotificacionOut)
def marcar_leida(
    notif_id: str,
    usuario: models.Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    notif = db.get(models.Notificacion, notif_id)
    if not notif or notif.usuario_id != usuario.id:
        raise HTTPException(404, "Notificación no encontrada")
    notif.leido = True
    db.commit()
    db.refresh(notif)
    return notif


@router.post("/leer-todas")
def marcar_todas_leidas(
    usuario: models.Usuario = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    db.query(models.Notificacion).filter_by(usuario_id=usuario.id, leido=False).update({"leido": True})
    db.commit()
    return {"ok": True}
