"""
Auth simplificado por OTP (celular + código).
En producción: integrar envío real de OTP vía SMS o WhatsApp Business API.
En desarrollo: el código válido es el definido en settings.otp_dev_code.
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app import models, schemas
from app.core.config import settings
from app.core.security import create_access_token
from app.database import get_db
from app.deps import get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/registro", response_model=schemas.TokenResponse)
def registro(payload: schemas.UsuarioRegistro, db: Session = Depends(get_db)):
    existente = db.query(models.Usuario).filter_by(celular=payload.celular).first()
    if existente:
        raise HTTPException(400, "Ese celular ya está registrado")

    usuario = models.Usuario(nombre=payload.nombre, celular=payload.celular, rol=payload.rol)
    db.add(usuario)
    db.flush()

    if payload.rol == models.Rol.jugador:
        db.add(models.PerfilJugador(usuario_id=usuario.id))
    else:
        db.add(models.PerfilCaptador(usuario_id=usuario.id))

    db.commit()
    db.refresh(usuario)

    token = create_access_token({"sub": usuario.id, "rol": usuario.rol.value})
    return schemas.TokenResponse(access_token=token, usuario=usuario)


@router.post("/otp/solicitar")
def solicitar_otp(celular: str):
    # TODO: integrar proveedor real de SMS/WhatsApp. Por ahora, siempre "envía" el código de desarrollo.
    return {"mensaje": f"Código enviado a {celular} (modo desarrollo: usa {settings.otp_dev_code})"}


@router.post("/login", response_model=schemas.TokenResponse)
def login(payload: schemas.OTPVerificar, db: Session = Depends(get_db)):
    if payload.codigo != settings.otp_dev_code:
        raise HTTPException(401, "Código OTP inválido")

    usuario = db.query(models.Usuario).filter_by(celular=payload.celular).first()
    if not usuario:
        raise HTTPException(404, "No existe una cuenta con ese celular")

    token = create_access_token({"sub": usuario.id, "rol": usuario.rol.value})
    return schemas.TokenResponse(access_token=token, usuario=usuario)


@router.get("/yo", response_model=schemas.UsuarioOut)
def yo(usuario: models.Usuario = Depends(get_current_user)):
    return usuario
