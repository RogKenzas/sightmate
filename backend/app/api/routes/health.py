
from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
def health_check():
    return {
        "status": "ok",
        "service": "sightmate-ai-backend",
        "version": "0.1.0",
    }
