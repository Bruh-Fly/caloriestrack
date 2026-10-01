from dataclasses import dataclass
from decimal import Decimal
from typing import Protocol


@dataclass(frozen=True)
class FoodAnalysis:
    name: str
    calories: int
    protein: Decimal
    carbs: Decimal
    fat: Decimal
    serving: str
    description: str | None = None


class FoodRecognitionService(Protocol):
    provider_name: str
    model_name: str

    async def analyze(self, image_jpeg: bytes, locale: str = "vi") -> FoodAnalysis: ...

    async def translate_recipe(self, recipe: dict) -> dict: ...

    async def translate_recipe_titles(self, recipes: list[dict], language_code: str) -> list[dict]: ...
