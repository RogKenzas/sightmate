
from typing import Literal

from pydantic import BaseModel


class SceneDescriptionResponse(BaseModel):
    description: str
    language: Literal["fr-FR", "en-US"]
    status: Literal["success"]
    model: str
    is_mock: bool
