from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.database import get_db
from app.deps import require_role

router = APIRouter(tags=["planes"])


@router.get("/planes", response_model=list[schemas.PlanOut])
def listar_planes(db: Session = Depends(get_db)):
    return db.query(models.Plan).filter_by(activo=True).all()


@router.post("/planes/pagos", response_model=schemas.PagoOut)
def iniciar_pago(
    payload: schemas.PagoCreate,
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    """
    Crea un pago en estado 'pendiente'. En producción, integrar con pasarela real
    (Culqi/Niubiz/agregador Yape-Plin) para generar el QR o redirigir al usuario.
    """
    plan = db.get(models.Plan, payload.plan_id)
    if not plan:
        raise HTTPException(404, "Plan no encontrado")

    perfil = db.query(models.PerfilJugador).filter_by(usuario_id=usuario.id).first()
    if not perfil:
        raise HTTPException(404, "Perfil de jugador no encontrado")

    pago = models.Pago(
        jugador_id=perfil.id,
        plan_id=plan.id,
        monto=plan.precio,
        metodo=payload.metodo,
        estado=models.EstadoPago.pendiente,
    )
    db.add(pago)
    db.commit()
    db.refresh(pago)
    return pago


@router.post("/planes/pagos/{pago_id}/confirmar", response_model=schemas.PagoOut)
def confirmar_pago(
    pago_id: str,
    usuario: models.Usuario = Depends(require_role("jugador")),
    db: Session = Depends(get_db),
):
    """
    Simula la confirmación de pago. En producción, este endpoint se invoca
    únicamente por WEBHOOK del proveedor de pagos, no desde el cliente.
    """
    pago = db.get(models.Pago, pago_id)
    if not pago:
        raise HTTPException(404, "Pago no encontrado")

    pago.estado = models.EstadoPago.confirmado

    perfil = db.get(models.PerfilJugador, pago.jugador_id)
    if perfil:
        perfil.plan_id = pago.plan_id
        perfil.plan_expira = datetime.now(timezone.utc) + timedelta(days=30)

    db.commit()
    db.refresh(pago)
    return pago
