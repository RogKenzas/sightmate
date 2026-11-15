
from fastapi import FastAPI

from app.api.routes.health import router as health_router
from app.api.routes.scene import router as scene_router

app = FastAPI(
    title="SightMate AI Backend",
    description="API d'assistance visuelle SightMate",
    version="0.1.0",
)

app.include_router(
    health_router,
    prefix="/api/v1",
    tags=["Health"],
)

app.include_router(
    scene_router,
    prefix="/api/v1/scene",
    tags=["Scene Description"],
)
