from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import router
from app.core.config import get_settings
from app.db import engine


@asynccontextmanager
async def lifespan(_: FastAPI):
    yield
    await engine.dispose()


settings = get_settings()
app = FastAPI(
    title="CaloAI API",
    version="0.1.0",
    description="Authenticated nutrition tracking API with replaceable food-recognition providers.",
    lifespan=lifespan,
)
if settings.cors_origins:
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["GET", "POST", "PUT", "DELETE"],
        allow_headers=["Authorization", "Content-Type", "Accept-Language"],
    )
app.include_router(router)


@app.get("/health", tags=["health"])
async def health() -> dict[str, str]:
    return {"status": "ok"}
