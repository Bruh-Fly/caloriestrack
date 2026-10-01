import asyncio
import time
from datetime import UTC, date, datetime
from uuid import UUID

from fastapi import APIRouter, Depends, File, Header, HTTPException, Response, UploadFile, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db import get_db
from app.food_image import normalize_food_image
from app.models import (
    AuthIdentity,
    AuthSession,
    DailyNutrition,
    FoodAnalysis as FoodAnalysisRow,
    Meal,
    MealItem,
    User,
    WeightEntry,
)
from app.recognition.factory import get_food_recognition_service
from app.schemas import (
    FoodAnalysisOut,
    DailyNutritionOut,
    GoogleLoginRequest,
    MealCreate,
    MealItemUpdate,
    NutritionGoalsIn,
    RecipeTranslationIn,
    RecipeTranslationOut,
    RecipeTitlesTranslationIn,
    RecipeTitlesTranslationOut,
    RefreshRequest,
    TokenPair,
    UserProfileIn,
    UserProfileOut,
    WeightEntryIn,
    WeightEntryOut,
)
from app.security import (
    create_refresh_token,
    current_user,
    decode_token,
    hash_refresh_token,
    issue_access_token,
    verify_google_id_token,
)

router = APIRouter(prefix="/api/v1")


@router.post("/auth/google", response_model=TokenPair)
async def google_login(body: GoogleLoginRequest, db: AsyncSession = Depends(get_db)) -> TokenPair:
    claims = await asyncio.to_thread(verify_google_id_token, body.id_token)
    subject = claims["sub"]
    identity = await db.scalar(
        select(AuthIdentity).where(
            AuthIdentity.provider == "google",
            AuthIdentity.provider_subject == subject,
        )
    )
    if identity:
        user = await db.get(User, identity.user_id)
    else:
        email = claims.get("email", "")
        user = await db.scalar(select(User).where(User.email == email))
        if user is None:
            user = User(
                email=email,
                display_name=claims.get("name", ""),
                photo_url=claims.get("picture"),
            )
            db.add(user)
            await db.flush()
        db.add(AuthIdentity(user_id=user.id, provider_subject=subject))
    if user is None:
        raise HTTPException(status_code=401, detail="Google identity is not linked to a user")
    raw_refresh, refresh_hash, expiry = create_refresh_token(user.id)
    db.add(AuthSession(user_id=user.id, refresh_token_hash=refresh_hash, expires_at=expiry))
    await db.commit()
    return TokenPair(access_token=issue_access_token(user.id), refresh_token=raw_refresh)


@router.post("/auth/refresh", response_model=TokenPair)
async def refresh_session(body: RefreshRequest, db: AsyncSession = Depends(get_db)) -> TokenPair:
    user_id = decode_token(body.refresh_token, "refresh")
    session = await db.scalar(
        select(AuthSession).where(
            AuthSession.refresh_token_hash == hash_refresh_token(body.refresh_token),
            AuthSession.user_id == user_id,
        )
    )
    now = datetime.now(UTC)
    if session is None or session.revoked or session.expires_at <= now:
        raise HTTPException(status_code=401, detail="Refresh session is invalid or expired")
    session.revoked = True
    raw_refresh, refresh_hash, expiry = create_refresh_token(user_id)
    db.add(AuthSession(user_id=user_id, refresh_token_hash=refresh_hash, expires_at=expiry))
    await db.commit()
    return TokenPair(access_token=issue_access_token(user_id), refresh_token=raw_refresh)


@router.post("/auth/logout", status_code=status.HTTP_204_NO_CONTENT)
async def logout(
    body: RefreshRequest,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
) -> None:
    session = await db.scalar(
        select(AuthSession).where(
            AuthSession.refresh_token_hash == hash_refresh_token(body.refresh_token),
            AuthSession.user_id == user.id,
        )
    )
    if session is not None:
        session.revoked = True
        await db.commit()


@router.get("/me/profile", response_model=UserProfileOut)
async def get_profile(user: User = Depends(current_user)) -> UserProfileOut:
    if user.age is None:
        raise HTTPException(status_code=404, detail="Profile has not been completed")
    return _profile_out(user)


@router.put("/me/profile", response_model=UserProfileOut)
async def save_profile(
    body: UserProfileIn,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
) -> UserProfileOut:
    user.display_name = body.name
    user.goal = body.goal
    user.goal_rate = body.goal_rate
    user.sex = body.sex
    user.age = body.age
    user.height_cm = body.height
    user.weight_kg = body.weight
    user.target_weight_kg = body.target_weight
    user.activity = body.activity
    user.diet = body.diet
    user.meals_per_day = body.meals_per_day
    user.exercise = body.exercise
    user.sleep = body.sleep
    user.daily_calories = body.daily_calories
    user.protein_goal_g = body.protein_goal
    user.carbs_goal_g = body.carbs_goal
    user.fat_goal_g = body.fat_goal
    user.photo_url = body.photo_url
    first_weight = await db.scalar(
        select(WeightEntry.id)
        .where(WeightEntry.user_id == user.id)
        .limit(1)
    )
    if first_weight is None:
        db.add(
            WeightEntry(
                user_id=user.id,
                recorded_on=datetime.now(UTC).date(),
                weight_kg=body.weight,
            )
        )
    await db.commit()
    await db.refresh(user)
    return _profile_out(user)


@router.patch("/me/goals", response_model=UserProfileOut)
async def update_nutrition_goals(
    body: NutritionGoalsIn,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
) -> UserProfileOut:
    user.daily_calories = body.daily_calories
    user.protein_goal_g = body.protein_goal
    user.carbs_goal_g = body.carbs_goal
    user.fat_goal_g = body.fat_goal
    await db.commit()
    await db.refresh(user)
    return _profile_out(user)


@router.post("/food/analyze", response_model=FoodAnalysisOut)
async def analyze_food(
    image: UploadFile = File(...),
    locale: str = Header(default="vi", alias="Accept-Language"),
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
) -> FoodAnalysisOut:
    jpeg = await normalize_food_image(image)
    started = time.perf_counter()
    try:
        service = get_food_recognition_service()
        result = await service.analyze(jpeg, locale)
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except Exception as exc:
        raise HTTPException(status_code=502, detail="Food analysis provider is unavailable") from exc

    elapsed_ms = round((time.perf_counter() - started) * 1000)
    row = FoodAnalysisRow(
        user_id=user.id,
        provider=service.provider_name,
        model=service.model_name,
        status="pending_review",
        latency_ms=elapsed_ms,
        result={
            "name": result.name,
            "calories": result.calories,
            "protein": str(result.protein),
            "carbs": str(result.carbs),
            "fat": str(result.fat),
            "serving": result.serving,
            "description": result.description,
        },
    )
    db.add(row)
    await db.commit()
    await db.refresh(row)
    return FoodAnalysisOut(
        analysis_id=row.id,
        name=result.name,
        calories=result.calories,
        protein=result.protein,
        carbs=result.carbs,
        fat=result.fat,
        serving=result.serving,
        description=result.description,
        provider=service.provider_name,
        model=service.model_name,
    )


@router.post("/me/meals", status_code=status.HTTP_201_CREATED)
async def log_meal(
    body: MealCreate,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    if any(item.analysis_id not in (None, body.analysis_id) for item in body.items):
        raise HTTPException(status_code=422, detail="Meal items must reference the submitted analysis")
    analysis = None
    if body.analysis_id:
        analysis = await db.scalar(
            select(FoodAnalysisRow).where(
                FoodAnalysisRow.id == body.analysis_id,
                FoodAnalysisRow.user_id == user.id,
            )
        )
        if analysis is None:
            raise HTTPException(status_code=404, detail="Analysis result was not found")
    meal = Meal(
        user_id=user.id,
        consumed_at=body.consumed_at,
        nutrition_date=body.nutrition_date,
        meal_type=body.meal_type,
    )
    db.add(meal)
    await db.flush()
    item_rows = []
    for item in body.items:
        row = MealItem(
                meal_id=meal.id,
                analysis_id=item.analysis_id or body.analysis_id,
                name=item.name,
                serving=item.serving,
                serving_grams=item.serving_grams,
                calories=item.calories,
                protein_g=item.protein,
                carbs_g=item.carbs,
                fat_g=item.fat,
                source="ai" if (item.analysis_id or body.analysis_id) else "manual",
            )
        item_rows.append(row)
        db.add(row)
    if analysis is not None:
        analysis.meal_id = meal.id
        analysis.status = "confirmed"
    await db.flush()
    item_ids = [str(item.id) for item in item_rows]
    await db.commit()
    await _refresh_daily_nutrition(db, user.id, body.nutrition_date)
    return {
        "id": str(meal.id),
        "item_ids": item_ids,
        "consumed_at": body.consumed_at.isoformat(),
        "status": "logged",
    }


@router.patch("/me/meals/{meal_id}/items/{item_id}")
async def update_meal_item(
    meal_id: UUID,
    item_id: UUID,
    body: MealItemUpdate,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    meal = await db.scalar(select(Meal).where(Meal.id == meal_id, Meal.user_id == user.id))
    item = await db.scalar(
        select(MealItem).where(MealItem.id == item_id, MealItem.meal_id == meal_id)
    )
    if meal is None or item is None:
        raise HTTPException(status_code=404, detail="Meal item was not found")
    item.name = body.name
    item.serving = body.serving
    item.serving_grams = body.serving_grams
    item.calories = body.calories
    item.protein_g = body.protein
    item.carbs_g = body.carbs
    item.fat_g = body.fat
    await db.commit()
    await _refresh_daily_nutrition(db, user.id, meal.nutrition_date)
    return {"status": "updated"}


@router.delete(
    "/me/meals/{meal_id}/items/{item_id}", status_code=status.HTTP_204_NO_CONTENT
)
async def delete_meal_item(
    meal_id: UUID,
    item_id: UUID,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
) -> Response:
    meal = await db.scalar(select(Meal).where(Meal.id == meal_id, Meal.user_id == user.id))
    item = await db.scalar(
        select(MealItem).where(MealItem.id == item_id, MealItem.meal_id == meal_id)
    )
    if meal is None or item is None:
        raise HTTPException(status_code=404, detail="Meal item was not found")
    nutrition_date = meal.nutrition_date
    await db.delete(item)
    await db.flush()
    remaining = await db.scalar(select(MealItem.id).where(MealItem.meal_id == meal_id).limit(1))
    if remaining is None:
        await db.delete(meal)
    await db.commit()
    await _refresh_daily_nutrition(db, user.id, nutrition_date)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.delete("/me/meals/{meal_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_meal(
    meal_id: UUID,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
) -> Response:
    meal = await db.scalar(select(Meal).where(Meal.id == meal_id, Meal.user_id == user.id))
    if meal is None:
        raise HTTPException(status_code=404, detail="Meal was not found")
    nutrition_date = meal.nutrition_date
    await db.delete(meal)
    await db.commit()
    await _refresh_daily_nutrition(db, user.id, nutrition_date)
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.get("/me/meals")
async def meal_history(
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
) -> list[dict]:
    meals = (
        await db.scalars(
            select(Meal)
            .where(Meal.user_id == user.id)
            .order_by(Meal.consumed_at.desc())
        )
    ).all()
    output = []
    for meal in meals:
        items = (
            await db.scalars(select(MealItem).where(MealItem.meal_id == meal.id))
        ).all()
        output.append({
            "id": str(meal.id),
            "timestamp": meal.consumed_at.isoformat(),
            "meal_type": meal.meal_type,
            "items": [{
                "id": str(item.id), "name": item.name, "serving": item.serving,
                "serving_grams": str(item.serving_grams) if item.serving_grams is not None else None,
                "calories": item.calories, "protein": str(item.protein_g),
                "carbs": str(item.carbs_g), "fat": str(item.fat_g),
            } for item in items],
        })
    return output


@router.post("/recipes/translate", response_model=RecipeTranslationOut)
async def translate_recipe(
    body: RecipeTranslationIn,
    _: User = Depends(current_user),
) -> RecipeTranslationOut:
    try:
        translated = await get_food_recognition_service().translate_recipe(body.model_dump())
    except (RuntimeError, ValueError) as exc:
        raise HTTPException(status_code=502, detail="Recipe translation is unavailable") from exc
    return RecipeTranslationOut.model_validate(translated)


@router.post("/recipes/translate-titles", response_model=RecipeTitlesTranslationOut)
async def translate_recipe_titles(
    body: RecipeTitlesTranslationIn,
    _: User = Depends(current_user),
) -> RecipeTitlesTranslationOut:
    try:
        translated = await get_food_recognition_service().translate_recipe_titles(
            [item.model_dump() for item in body.recipes], body.language
        )
    except (RuntimeError, ValueError) as exc:
        raise HTTPException(status_code=502, detail="Recipe title translation is unavailable") from exc
    return RecipeTitlesTranslationOut.model_validate({"recipes": translated})


@router.post("/me/weight", response_model=WeightEntryOut, status_code=status.HTTP_201_CREATED)
async def add_weight_entry(
    body: WeightEntryIn,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
) -> WeightEntryOut:
    entry = WeightEntry(user_id=user.id, **body.model_dump())
    db.add(entry)
    user.weight_kg = body.weight_kg
    await db.commit()
    await db.refresh(entry)
    return WeightEntryOut(id=entry.id, recorded_on=entry.recorded_on, weight_kg=entry.weight_kg, note=entry.note)


@router.get("/me/weight", response_model=list[WeightEntryOut])
async def list_weight_entries(
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
) -> list[WeightEntryOut]:
    entries = (
        await db.scalars(
            select(WeightEntry)
            .where(WeightEntry.user_id == user.id)
            .order_by(WeightEntry.recorded_on.desc())
        )
    ).all()
    return [
        WeightEntryOut(id=e.id, recorded_on=e.recorded_on, weight_kg=e.weight_kg, note=e.note)
        for e in entries
    ]


@router.get("/me/nutrition/{nutrition_date}", response_model=DailyNutritionOut)
async def get_daily_nutrition(
    nutrition_date: date,
    user: User = Depends(current_user),
    db: AsyncSession = Depends(get_db),
) -> DailyNutritionOut:
    row = await db.scalar(
        select(DailyNutrition).where(
            DailyNutrition.user_id == user.id,
            DailyNutrition.nutrition_date == nutrition_date,
        )
    )
    if row is None:
        return DailyNutritionOut(
            nutrition_date=nutrition_date,
            calories=0,
            protein_g=0,
            carbs_g=0,
            fat_g=0,
        )
    return DailyNutritionOut(
        nutrition_date=row.nutrition_date,
        calories=row.calories,
        protein_g=row.protein_g,
        carbs_g=row.carbs_g,
        fat_g=row.fat_g,
    )


def _profile_out(user: User) -> UserProfileOut:
    return UserProfileOut(
        uid=user.id,
        name=user.display_name,
        email=user.email,
        goal=user.goal,
        goal_rate=user.goal_rate,
        sex=user.sex,
        age=user.age,
        height=user.height_cm,
        weight=user.weight_kg,
        target_weight=user.target_weight_kg,
        activity=user.activity,
        diet=user.diet,
        meals_per_day=user.meals_per_day,
        exercise=user.exercise,
        sleep=user.sleep,
        daily_calories=user.daily_calories,
        protein_goal=user.protein_goal_g,
        carbs_goal=user.carbs_goal_g,
        fat_goal=user.fat_goal_g,
        photo_url=user.photo_url,
        created_at=user.created_at,
    )


async def _refresh_daily_nutrition(db: AsyncSession, user_id: UUID, nutrition_date: date) -> None:
    totals = (
        await db.execute(
            select(
                func.coalesce(func.sum(MealItem.calories), 0),
                func.coalesce(func.sum(MealItem.protein_g), 0),
                func.coalesce(func.sum(MealItem.carbs_g), 0),
                func.coalesce(func.sum(MealItem.fat_g), 0),
            )
            .join(Meal, Meal.id == MealItem.meal_id)
            .where(
                Meal.user_id == user_id,
                Meal.nutrition_date == nutrition_date,
            )
        )
    ).one()
    row = await db.scalar(
        select(DailyNutrition).where(
            DailyNutrition.user_id == user_id,
            DailyNutrition.nutrition_date == nutrition_date,
        )
    )
    if row is None:
        row = DailyNutrition(user_id=user_id, nutrition_date=nutrition_date)
        db.add(row)
    row.calories = int(totals[0])
    row.protein_g = totals[1]
    row.carbs_g = totals[2]
    row.fat_g = totals[3]
    row.updated_at = datetime.now(UTC)
    await db.commit()
