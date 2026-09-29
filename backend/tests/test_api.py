import os

os.environ.setdefault("JWT_SECRET", "test-only-secret-value-with-more-than-32-chars")
os.environ.setdefault("GOOGLE_CLIENT_ID", "test-client-id.apps.googleusercontent.com")

from fastapi.testclient import TestClient

from app.main import app


def test_health_endpoint() -> None:
    with TestClient(app) as client:
        response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_profile_requires_backend_authentication() -> None:
    with TestClient(app) as client:
        response = client.get("/api/v1/me/profile")

    assert response.status_code == 401


def test_meal_and_weight_endpoints_require_backend_authentication() -> None:
    with TestClient(app) as client:
        meals = client.get("/api/v1/me/meals")
        weights = client.get("/api/v1/me/weight")
        daily = client.get("/api/v1/me/nutrition/2026-09-25")

    assert meals.status_code == 401
    assert weights.status_code == 401
    assert daily.status_code == 401


def test_food_analysis_requires_backend_authentication() -> None:
    with TestClient(app) as client:
        response = client.post(
            "/api/v1/food/analyze",
            files={"image": ("meal.jpg", b"not-a-real-image", "image/jpeg")},
        )

    assert response.status_code == 401
