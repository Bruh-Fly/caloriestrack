from datetime import date, datetime
from decimal import Decimal
from uuid import UUID, uuid4

from sqlalchemy import (
    Boolean,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import JSONB, UUID as PGUUID
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    display_name: Mapped[str] = mapped_column(String(120), default="")
    goal: Mapped[str] = mapped_column(String(32), default="eat_healthier")
    goal_rate: Mapped[str] = mapped_column(String(16), default="moderate")
    sex: Mapped[str] = mapped_column(String(16), default="unspecified")
    age: Mapped[int | None] = mapped_column(Integer)
    height_cm: Mapped[Decimal | None] = mapped_column(Numeric(6, 2))
    weight_kg: Mapped[Decimal | None] = mapped_column(Numeric(6, 2))
    target_weight_kg: Mapped[Decimal | None] = mapped_column(Numeric(6, 2))
    activity: Mapped[str] = mapped_column(String(24), default="light")
    diet: Mapped[str] = mapped_column(String(24), default="none")
    meals_per_day: Mapped[int] = mapped_column(Integer, default=3)
    exercise: Mapped[str] = mapped_column(String(24), default="never")
    sleep: Mapped[str] = mapped_column(String(24), default="7_8")
    daily_calories: Mapped[int] = mapped_column(Integer, default=2000)
    protein_goal_g: Mapped[Decimal] = mapped_column(Numeric(7, 2), default=50)
    carbs_goal_g: Mapped[Decimal] = mapped_column(Numeric(7, 2), default=250)
    fat_goal_g: Mapped[Decimal] = mapped_column(Numeric(7, 2), default=65)
    photo_url: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    identities: Mapped[list["AuthIdentity"]] = relationship(
        back_populates="user", cascade="all, delete-orphan"
    )
    meals: Mapped[list["Meal"]] = relationship(back_populates="user", cascade="all, delete-orphan")


class AuthIdentity(Base):
    __tablename__ = "auth_identities"
    __table_args__ = (UniqueConstraint("provider", "provider_subject"),)

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    provider: Mapped[str] = mapped_column(String(32), default="google")
    provider_subject: Mapped[str] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    user: Mapped[User] = relationship(back_populates="identities")


class AuthSession(Base):
    __tablename__ = "auth_sessions"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    refresh_token_hash: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    expires_at: Mapped[datetime] = mapped_column(DateTime(timezone=True))
    revoked: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class Meal(Base):
    __tablename__ = "meals"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    consumed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), index=True)
    nutrition_date: Mapped[date] = mapped_column(Date, index=True)
    meal_type: Mapped[str] = mapped_column(String(24), default="other")
    image_ref: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(24), default="logged")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    user: Mapped[User] = relationship(back_populates="meals")
    items: Mapped[list["MealItem"]] = relationship(back_populates="meal", cascade="all, delete-orphan")
    analyses: Mapped[list["FoodAnalysis"]] = relationship(back_populates="meal")


class FoodAnalysis(Base):
    __tablename__ = "food_analysis_results"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    meal_id: Mapped[UUID | None] = mapped_column(ForeignKey("meals.id", ondelete="SET NULL"), index=True)
    provider: Mapped[str] = mapped_column(String(32))
    model: Mapped[str] = mapped_column(String(100))
    result: Mapped[dict] = mapped_column(JSONB)
    status: Mapped[str] = mapped_column(String(24), default="pending_review")
    latency_ms: Mapped[int | None] = mapped_column(Integer)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    meal: Mapped[Meal | None] = relationship(back_populates="analyses")


class MealItem(Base):
    __tablename__ = "meal_items"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    meal_id: Mapped[UUID] = mapped_column(ForeignKey("meals.id", ondelete="CASCADE"), index=True)
    analysis_id: Mapped[UUID | None] = mapped_column(ForeignKey("food_analysis_results.id", ondelete="SET NULL"))
    name: Mapped[str] = mapped_column(String(200))
    serving: Mapped[str] = mapped_column(String(200), default="1 serving")
    serving_grams: Mapped[Decimal | None] = mapped_column(Numeric(8, 2))
    calories: Mapped[int] = mapped_column(Integer)
    protein_g: Mapped[Decimal] = mapped_column(Numeric(8, 2))
    carbs_g: Mapped[Decimal] = mapped_column(Numeric(8, 2))
    fat_g: Mapped[Decimal] = mapped_column(Numeric(8, 2))
    source: Mapped[str] = mapped_column(String(24), default="ai")
    meal: Mapped[Meal] = relationship(back_populates="items")


class DailyNutrition(Base):
    __tablename__ = "daily_nutrition"
    __table_args__ = (UniqueConstraint("user_id", "nutrition_date"),)

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    nutrition_date: Mapped[date] = mapped_column(Date)
    calories: Mapped[int] = mapped_column(Integer, default=0)
    protein_g: Mapped[Decimal] = mapped_column(Numeric(9, 2), default=0)
    carbs_g: Mapped[Decimal] = mapped_column(Numeric(9, 2), default=0)
    fat_g: Mapped[Decimal] = mapped_column(Numeric(9, 2), default=0)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())


class WeightEntry(Base):
    __tablename__ = "weight_entries"

    id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), primary_key=True, default=uuid4)
    user_id: Mapped[UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    recorded_on: Mapped[date] = mapped_column(Date, index=True)
    weight_kg: Mapped[Decimal] = mapped_column(Numeric(6, 2))
    note: Mapped[str | None] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
