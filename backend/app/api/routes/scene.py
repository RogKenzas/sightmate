
from typing import Annotated, Literal

from fastapi import APIRouter, File, Form, HTTPException, UploadFile

from app.schemas.scene import SceneDescriptionResponse

router = APIRouter()

MAX_IMAGE_SIZE = 8 * 1024 * 1024
SUPPORTED_TYPES = {"image/jpeg", "image/png", "image/webp"}


@router.post(
    "/describe",
    response_model=SceneDescriptionResponse,
)
async def describe_scene(
    image: Annotated[UploadFile, File()],
    language: Annotated[
        Literal["fr-FR", "en-US"], Form()
    ] = "fr-FR",
):
    if image.content_type not in SUPPORTED_TYPES:
        raise HTTPException(
            status_code=415,
            detail="Unsupported image format",
        )

    try:
        content = await image.read(MAX_IMAGE_SIZE + 1)

        if len(content) > MAX_IMAGE_SIZE:
            raise HTTPException(
                status_code=413,
                detail="Image exceeds 8 MB",
            )

        if not content:
            raise HTTPException(
                status_code=400,
                detail="Image is empty",
            )
    finally:
        await image.close()

    descriptions = {
        "fr-FR": (
            "Image reçue. La description intelligente "
            "n'est pas encore disponible."
        ),
        "en-US": (
            "Image received. Intelligent scene description "
            "is not available yet."
        ),
    }

    return SceneDescriptionResponse(
        description=descriptions[language],
        language=language,
        status="success",
        model="mock-v1",
        is_mock=True,
    )
