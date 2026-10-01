from app.core.config import get_settings
from app.recognition.base import FoodRecognitionService
from app.recognition.gemini import GeminiFoodRecognitionService
from app.recognition.groq import GroqFoodRecognitionService


def get_food_recognition_service() -> FoodRecognitionService:
    provider = get_settings().food_recognition_provider.lower()
    if provider == "gemini":
        return GeminiFoodRecognitionService()
    if provider == "groq":
        return GroqFoodRecognitionService()
    raise RuntimeError(f"Unsupported food recognition provider: {provider}")
