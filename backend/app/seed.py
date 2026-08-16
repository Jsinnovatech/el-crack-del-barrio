"""
Script de datos semilla para desarrollo local.
Ejecutar con: python -m app.seed
"""
import uuid
from datetime import date, datetime, timedelta, timezone

from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.core.config import settings
from app.database import Base
from app import models


def gen_id() -> str:
    return str(uuid.uuid4())


def run():
    engine = create_engine(settings.database_url, pool_pre_ping=True)
    Base.metadata.create_all(bind=engine)
    Session = sessionmaker(bind=engine)
    db = Session()

    try:
        if db.query(models.Plan).first():
            print("✓ Ya existen datos. No se vuelve a sembrar.")
            return

        print("🌱 Iniciando seed...")

        # ─── PLANES ────────────────────────────────────────────────
        plan_gratis = models.Plan(
            id=gen_id(), nombre="Gratis", precio=0, unidad="siempre",
            beneficios=["Perfil visible", "1 video", "Búsqueda básica"],
            destacado=False, activo=True,
        )
        plan_crack = models.Plan(
            id=gen_id(), nombre="Crack", precio=29, unidad="30 días",
            beneficios=["Prioridad en búsquedas", "Videos ilimitados", "Badge Crack",
                        "Estadísticas avanzadas", "1000 vistas/mes"],
            destacado=True, activo=True,
        )
        plan_pro = models.Plan(
            id=gen_id(), nombre="Pro", precio=59, unidad="30 días",
            beneficios=["Top del ranking", "Videos ilimitados", "Badge dorado PRO",
                        "Vistas ilimitadas", "Soporte prioritario", "Analítica completa"],
            destacado=False, activo=True,
        )
        db.add_all([plan_gratis, plan_crack, plan_pro])
        db.flush()
        print("✓ Planes creados")

        # ─── JUGADORES ─────────────────────────────────────────────
        jugadores_data = [
            {"nombre": "Carlos Mendoza", "celular": "51987001001", "posicion": "Delantero Centro",
             "ciudad": "Lima", "edad": 22, "rating": 4.8, "verificado": True, "plan": plan_crack,
             "bio": "Delantero con gran olfato goleador y velocidad explosiva.",
             "clubes": [("Alianza Lima juvenil", "club", 2021), ("Deportivo Municipal", "club", 2023)],
             "foto": "https://picsum.photos/seed/cm1/400/400"},
            {"nombre": "Luis Quispe", "celular": "51987001002", "posicion": "Portero",
             "ciudad": "Arequipa", "edad": 19, "rating": 4.2, "verificado": False, "plan": plan_gratis,
             "bio": "Portero agresivo con gran colocación y reflejos rápidos.",
             "clubes": [("FBC Melgar", "club", 2022), ("Cienciano", "club", 2023)],
             "foto": "https://picsum.photos/seed/lq2/400/400"},
            {"nombre": "Diego Flores", "celular": "51987001003", "posicion": "Mediocampista",
             "ciudad": "Trujillo", "edad": 25, "rating": 4.5, "verificado": True, "plan": plan_crack,
             "bio": "Volante creativo con visión de juego y excelente técnica individual.",
             "clubes": [("Sporting Cristal", "club", 2020), ("César Vallejo", "club", 2022)],
             "foto": "https://picsum.photos/seed/df3/400/400"},
            {"nombre": "Juan Torres", "celular": "51987001004", "posicion": "Defensa Central",
             "ciudad": "Chiclayo", "edad": 21, "rating": 3.9, "verificado": False, "plan": plan_gratis,
             "bio": "Defensor central contundente en el juego aéreo y buen pase largo.",
             "clubes": [("Juan Aurich", "club", 2022), ("Alianza Lima", "club", 2023)],
             "foto": "https://picsum.photos/seed/jt4/400/400"},
            {"nombre": "Óscar Vargas", "celular": "51987001005", "posicion": "Extremo Derecho",
             "ciudad": "Lima", "edad": 23, "rating": 4.7, "verificado": True, "plan": plan_pro,
             "bio": "Extremo desequilibrante con regate endiablado y golazo desde fuera del área.",
             "clubes": [("Universitario", "club", 2021), ("Sport Boys", "club", 2023)],
             "foto": "https://picsum.photos/seed/ov5/400/400"},
            {"nombre": "Pedro Huamán", "celular": "51987001006", "posicion": "Lateral Izquierdo",
             "ciudad": "Cusco", "edad": 20, "rating": 4.1, "verificado": False, "plan": plan_gratis,
             "bio": "Lateral ofensivo con gran resistencia física y buen centro al área.",
             "clubes": [("Cienciano", "club", 2021), ("Real Garcilaso", "club", 2023)],
             "foto": "https://picsum.photos/seed/ph6/400/400"},
            {"nombre": "Rodrigo Sánchez", "celular": "51987001007", "posicion": "Mediocampista Defensivo",
             "ciudad": "Piura", "edad": 27, "rating": 4.3, "verificado": True, "plan": plan_crack,
             "bio": "Mediocampista récuperador con excelente cobertura y salida limpia.",
             "clubes": [("ADT Tarma", "club", 2019), ("Universitario", "club", 2022)],
             "foto": "https://picsum.photos/seed/rs7/400/400"},
            {"nombre": "Andrés Bejarano", "celular": "51987001008", "posicion": "Segundo Delantero",
             "ciudad": "Lima", "edad": 24, "rating": 4.6, "verificado": True, "plan": plan_pro,
             "bio": "Enganche con visión de juego excepcional y gol desde segunda línea.",
             "clubes": [("San Martín", "club", 2020), ("Alianza Lima", "club", 2023)],
             "foto": "https://picsum.photos/seed/ab8/400/400"},
            {"nombre": "Miguel Paredes", "celular": "51987001009", "posicion": "Lateral Derecho",
             "ciudad": "Ica", "edad": 18, "rating": 3.8, "verificado": False, "plan": plan_gratis,
             "bio": "Lateral joven con mucha proyección ofensiva y velocidad.",
             "clubes": [("UTC Cajamarca", "club", 2023)],
             "foto": "https://picsum.photos/seed/mp9/400/400"},
            {"nombre": "Fabricio Luna", "celular": "51987001010", "posicion": "Defensa Central",
             "ciudad": "Callao", "edad": 26, "rating": 4.0, "verificado": False, "plan": plan_gratis,
             "bio": "Defensor experimentado con fuerte presencia física y liderazgo.",
             "clubes": [("Sporting Cristal", "club", 2018), ("FBC Melgar", "club", 2021)],
             "foto": "https://picsum.photos/seed/fl10/400/400"},
        ]

        hoy = date.today()
        perfiles_jugador = []

        for jd in jugadores_data:
            u = models.Usuario(
                id=gen_id(), nombre=jd["nombre"], celular=jd["celular"],
                rol=models.Rol.jugador,
            )
            db.add(u)
            db.flush()

            pj = models.PerfilJugador(
                id=gen_id(), usuario_id=u.id,
                foto_url=jd["foto"], verificado=jd["verificado"],
                bio=jd["bio"], posicion_principal=jd["posicion"],
                posiciones_secundarias=[], edad=jd["edad"], ciudad=jd["ciudad"],
                rating=jd["rating"],
                plan_id=jd["plan"].id if jd["plan"].precio > 0 else None,
                plan_expira=datetime.now(timezone.utc) + timedelta(days=30) if jd["plan"].precio > 0 else None,
            )
            db.add(pj)
            db.flush()
            perfiles_jugador.append(pj)

            # Clubes
            for nombre_club, tipo, anio in jd["clubes"]:
                db.add(models.Club(id=gen_id(), jugador_id=pj.id, nombre=nombre_club, tipo=tipo, anio=anio))

            # Videos (3 por jugador)
            for idx in range(3):
                seed = jd["nombre"].replace(" ", "").lower()
                db.add(models.Video(
                    id=gen_id(), jugador_id=pj.id,
                    titulo=f"Jugada destacada {idx + 1}",
                    thumb_url=f"https://picsum.photos/seed/{seed}{idx}/400/300",
                    video_url=None, vistas=idx * 17 + 3,
                    destacado=(idx == 0), orden=idx,
                ))

            # Disponibilidad (5 días disponibles)
            for d_offset in [2, 5, 8, 12, 15]:
                dia = hoy + timedelta(days=d_offset)
                db.add(models.Disponibilidad(
                    id=gen_id(), jugador_id=pj.id, fecha=dia,
                    estado=models.EstadoDisponibilidad.disponible,
                    hora_desde="09:00", hora_hasta="18:00",
                ))

            print(f"  ✓ Jugador: {jd['nombre']}")

        # ─── CAPTADORES ────────────────────────────────────────────
        captadores_data = [
            {"nombre": "Marco Parodi", "celular": "51987002001", "club": "Alianza Lima", "zona": "Lima"},
            {"nombre": "Daniel Castillo", "celular": "51987002002", "club": "FBC Melgar", "zona": "Arequipa"},
        ]

        for cd in captadores_data:
            u = models.Usuario(
                id=gen_id(), nombre=cd["nombre"], celular=cd["celular"],
                rol=models.Rol.captador,
            )
            db.add(u)
            db.flush()
            pc = models.PerfilCaptador(
                id=gen_id(), usuario_id=u.id,
                club_representa=cd["club"], zona_interes=cd["zona"],
            )
            db.add(pc)
            db.flush()

            # Agregar favoritos (primeros 3 jugadores)
            for pj in perfiles_jugador[:3]:
                db.add(models.Favorito(id=gen_id(), captador_id=pc.id, jugador_id=pj.id))

            # Agregar notificación de bienvenida
            db.add(models.Notificacion(
                id=gen_id(), usuario_id=u.id, tipo="bienvenida",
                texto=f"¡Bienvenido {cd['nombre']}! Empieza a explorar jugadores.",
                leido=False,
            ))
            print(f"  ✓ Captador: {cd['nombre']}")

        db.commit()
        print("\n✅ Seed completado exitosamente.")

    except Exception as e:
        db.rollback()
        print(f"❌ Error durante el seed: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    run()
