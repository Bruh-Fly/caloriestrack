import json
from decimal import Decimal

import httpx

from app.core.config import get_settings
from app.recognition.base import FoodAnalysis

_PROMPT = """Analyze this meal photo for a calorie-tracking app. Respond in {language}.
Estimate visible foods and the edible serving shown. Never claim exact measurement from an image.
Return a JSON object matching the supplied schema only. If there is no food, set is_food=false.
When uncertain, use a conservative estimate and describe uncertainty briefly.
"""

_LANGUAGES = {
    "vi": "Vietnamese",
    "en": "English",
    "es": "Spanish",
    "fr": "French",
    "zh": "Simplified Chinese",
    "hi": "Hindi",
    "ar": "Arabic",
}

_RESPONSE_SCHEMA = {
    "type": "OBJECT",
    "properties": {
        "is_food": {"type": "BOOLEAN"},
        "name": {"type": "STRING"},
        "calories": {"type": "INTEGER"},
        "protein": {"type": "NUMBER"},
        "carbs": {"type": "NUMBER"},
        "fat": {"type": "NUMBER"},
        "serving": {"type": "STRING"},
        "description": {"type": "STRING"},
    },
    "required": ["is_food", "name", "calories", "protein", "carbs", "fat", "serving", "description"],
}


class GeminiFoodRecognitionService:
    provider_name = "gemini"

    def __init__(self) -> None:
        settings = get_settings()
        if not settings.gemini_api_key:
            raise RuntimeError("GEMINI_API_KEY is not configured on the backend")
        self._api_key = settings.gemini_api_key
        self.model_name = settings.gemini_model
        self._endpoint = (
            "https://generativelanguage.googleapis.com/v1beta/models/"
            f"{self.model_name}:generateContent"
        )

    async def analyze(self, image_jpeg: bytes, locale: str = "vi") -> FoodAnalysis:
        language_code = locale.lower().replace("_", "-").split(",", 1)[0].split("-", 1)[0]
        language = _LANGUAGES.get(language_code, "English")
        prompt = _PROMPT.format(language=language)
        body = {
            "contents": [{"parts": [
                {"text": prompt},
                {"inline_data": {"mime_type": "image/jpeg", "data": _b64(image_jpeg)}},
            ]}],
            "generationConfig": {
                "temperature": 0.1,
                "responseMimeType": "application/json",
                "responseSchema": _RESPONSE_SCHEMA,
            },
        }
        async with httpx.AsyncClient(timeout=httpx.Timeout(45.0, connect=10.0)) as client:
            response = await client.post(
                self._endpoint,
                headers={"x-goog-api-key": self._api_key},
                json=body,
            )
        if response.is_error:
            # Do not return vendor response bodies: they can contain request metadata.
            raise RuntimeError(f"Gemini request failed with status {response.status_code}")
        try:
            payload = response.json()
            raw = payload["candidates"][0]["content"]["parts"][0]["text"]
            parsed = json.loads(raw)
        except (KeyError, IndexError, TypeError, ValueError) as exc:
            raise RuntimeError("Gemini returned an invalid structured response") from exc
        if not parsed.get("is_food"):
            raise ValueError("Không phát hiện thức ăn trong ảnh.")
        try:
            calories = int(parsed["calories"])
            protein = Decimal(str(parsed["protein"]))
            carbs = Decimal(str(parsed["carbs"]))
            fat = Decimal(str(parsed["fat"]))
            name = str(parsed["name"]).strip()
            serving = str(parsed["serving"]).strip()
        except (KeyError, TypeError, ValueError, ArithmeticError) as exc:
            raise RuntimeError("Gemini returned incomplete nutrition values") from exc
        if not name or not serving or min(calories, protein, carbs, fat) < 0:
            raise RuntimeError("Gemini returned out-of-range nutrition values")
        return FoodAnalysis(
            name=name,
            calories=min(calories, 10000),
            protein=min(protein, Decimal("1000")),
            carbs=min(carbs, Decimal("1500")),
            fat=min(fat, Decimal("1000")),
            serving=serving[:200],
            description=str(parsed.get("description", ""))[:1000] or None,
        )


def _b64(value: bytes) -> str:
    import base64

    return base64.b64encode(value).decode("ascii")
