# El Crack del Barrio — Proyecto completo

Este repo contiene **dos proyectos independientes**, tal como se pidió, listos para
abrir cada uno como carpeta de trabajo en **Claude Code** o **Windsurf**:

```
proyecto/
├── backend/    → API FastAPI + PostgreSQL (Python)
└── frontend/   → App Flutter (Dart)
```

Ambos están construidos a partir de `docs_crack_del_barrio.md` (diagramas de flujo,
secuencia, estados, modelo ER y arquitectura) y del prototipo interactivo
`vitrina_deportiva.html`.

## Cómo abrir esto en Claude Code / Windsurf

**Opción A — un proyecto a la vez (recomendado):**
Abre `backend/` como carpeta de trabajo en una sesión, y `frontend/` en otra.
Así cada IDE/agente solo ve el contexto relevante (Python vs. Dart) y las
sugerencias/autocompletado son más precisas.

**Opción B — monorepo:**
Abre la carpeta `proyecto/` completa. Ambos README (`backend/README.md` y
`frontend/README.md`) documentan su stack y sus pendientes por separado.

## Orden sugerido de trabajo

1. **Backend primero**: levanta PostgreSQL local, corre `python -m app.seed`,
   luego `uvicorn app.main:app --reload` y verifica `http://localhost:8000/docs`.
2. **Frontend después**: con el backend corriendo, `flutter pub get` y `flutter run`
   apuntando a `http://10.0.2.2:8000` (emulador Android) o la IP de tu máquina.
3. Cada README tiene una sección **"Notas de implementación"** con los TODO
   explícitos que quedan pendientes — son el mejor punto de partida para pedirle
   a Claude Code o Windsurf que continúe el desarrollo módulo por módulo.

## Trazabilidad con la documentación

| Documento | Para qué sirve |
|---|---|
| `docs_crack_del_barrio.md` | Diagramas y plan de acción (referencia de producto/arquitectura) |
| `backend/app/models.py` | Implementación real del modelo entidad-relación del documento |
| `backend/app/routers/*.py` | Implementación real de cada flujo (flowcharts/secuencia) |
| `frontend/lib/screens/` | Implementación real de cada pantalla del prototipo HTML |

Mantén los tres en sync: si cambias un flujo en el prototipo o el documento,
refleja el cambio en el modelo del backend y en la pantalla correspondiente del
frontend.
