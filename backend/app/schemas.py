from datetime import date, datetime
from decimal import Decimal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class GoogleLoginRequest(BaseModel):
    id_token: str = Field(min_length=20)


class TokenPair(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class RefreshRequest(BaseModel):
    refresh_token: str


class NutritionGoalsIn(BaseModel):
    daily_calories: int = Field(ge=500, le=10000)
    protein_goal: Decimal = Field(ge=0, le=1000)
    carbs_goal: Decimal = Field(ge=0, le=1500)
    fat_goal: Decimal = Field(ge=0, le=1000)


class UserProfileIn(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    goal: str = Field(max_length=32)
    goal_rate: str = Field(default="moderate", max_length=16)
    sex: str = Field(max_length=16)
    age: int = Field(ge=10, le=120)
    height: Decimal = Field(gt=0, le=300)
    weight: Decimal = Field(gt=0, le=700)
    target_weight: Decimal = Field(gt=0, le=700)
    activity: str = Field(max_length=24)
    diet: str = Field(max_length=24)
    meals_per_day: int = Field(ge=1, le=12)
    exercise: str = Field(max_length=24)
    sleep: str = Field(max_length=24)
    daily_calories: int = Field(ge=500, le=10000)
    protein_goal: Decimal = Field(ge=0, le=1000)
    carbs_goal: Decimal = Field(ge=0, le=1500)
    fat_goal: Decimal = Field(ge=0, le=1000)
    photo_url: str | None = None


class UserProfileOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    uid: UUID
    name: str
    email: str
    goal: str
    goal_rate: str
    sex: str
    age: int | None
    height: Decimal | None
    weight: Decimal | None
    target_weight: Decimal | None
    activity: str
    diet: str
    meals_per_day: int
    exercise: str
    sleep: str
    daily_calories: int
    protein_goal: Decimal
    carbs_goal: Decimal
    fat_goal: Decimal
    photo_url: str | None
    created_at: datetime


class FoodAnalysisOut(BaseModel):
    analysis_id: UUID
    name: str
    calories: int = Field(ge=0, le=10000)
    protein: Decimal = Field(ge=0, le=1000)
    carbs: Decimal = Field(ge=0, le=1500)
    fat: Decimal = Field(ge=0, le=1000)
    serving: str = Field(max_length=200)
    description: str | None = Field(default=None, max_length=1000)
    provider: str
    model: str


class MealItemIn(BaseModel):
    name: str = Field(min_length=1, max_length=200)
    serving: str = Field(max_length=200)
    serving_grams: Decimal | None = Field(default=None, gt=0, le=10000)
    calories: int = Field(ge=0, le=10000)
    protein: Decimal = Field(ge=0, le=1000)
    carbs: Decimal = Field(ge=0, le=1500)
    fat: Decimal = Field(ge=0, le=1000)
    analysis_id: UUID | None = None


class MealCreate(BaseModel):
    consumed_at: datetime
    nutrition_date: date
    meal_type: str = Field(default="other", max_length=24)
    analysis_id: UUID | None = None
    items: list[MealItemIn] = Field(min_length=1, max_length=50)


class WeightEntryIn(BaseModel):
    recorded_on: date
    weight_kg: Decimal = Field(gt=0, le=700)
    note: str | None = Field(default=None, max_length=1000)


class WeightEntryOut(WeightEntryIn):
    id: UUID


class DailyNutritionOut(BaseModel):
    nutrition_date: date
    calories: int
    protein_g: Decimal
    carbs_g: Decimal
    fat_g: Decimal
