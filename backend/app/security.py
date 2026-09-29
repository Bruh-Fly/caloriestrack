import hashlib
import secrets
from datetime import UTC, datetime, timedelta
from uuid import UUID

import jwt
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from google.auth.transport.requests import Request
from google.auth.exceptions import TransportError
from google.oauth2 import id_token
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import get_settings
from app.db import get_db
from app.models import AuthSession, User

_bearer = HTTPBearer(auto_error=False)


class _BoundedGoogleRequest(Request):
    def __call__(self, url, method="GET", body=None, headers=None, timeout=8, **kwargs):
        return super().__call__(
            url, method=method, body=body, headers=headers, timeout=timeout, **kwargs
        )


def verify_google_id_token(raw_token: str) -> dict:
    settings = get_settings()
    try:
        claims = id_token.verify_oauth2_token(
            raw_token, _BoundedGoogleRequest(), settings.google_client_id
        )
    except TransportError as exc:
        raise HTTPException(
            status_code=503,
            detail="Google token verification is temporarily unavailable. Check backend internet access and retry.",
        ) from exc
    except Exception as exc:
        raise HTTPException(status_code=401, detail="Google ID token is invalid or expired") from exc
    if not claims.get("sub") or not claims.get("email_verified") or not claims.get("email"):
        raise HTTPException(status_code=401, detail="Google account is not verified")
    return claims


def _encode_token(user_id: UUID, token_type: str, expires: datetime, jti: str | None = None) -> str:
    settings = get_settings()
    payload = {"sub": str(user_id), "type": token_type, "exp": expires}
    if jti:
        payload["jti"] = jti
    return jwt.encode(payload, settings.jwt_secret, algorithm="HS256")


def issue_access_token(user_id: UUID) -> str:
    expiry = datetime.now(UTC) + timedelta(minutes=get_settings().access_token_minutes)
    return _encode_token(user_id, "access", expiry)


def create_refresh_token(user_id: UUID) -> tuple[str, str, datetime]:
    expiry = datetime.now(UTC) + timedelta(days=get_settings().refresh_token_days)
    raw = _encode_token(user_id, "refresh", expiry, jti=secrets.token_urlsafe(24))
    return raw, hashlib.sha256(raw.encode()).hexdigest(), expiry


def decode_token(raw: str, expected_type: str) -> UUID:
    try:
        claims = jwt.decode(raw, get_settings().jwt_secret, algorithms=["HS256"])
        if claims.get("type") != expected_type:
            raise ValueError("Wrong token type")
        return UUID(claims["sub"])
    except (jwt.PyJWTError, ValueError, KeyError) as exc:
        raise HTTPException(status_code=401, detail="Session token is invalid or expired") from exc


async def current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer),
    db: AsyncSession = Depends(get_db),
) -> User:
    if credentials is None:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Authentication required")
    user_id = decode_token(credentials.credentials, "access")
    user = await db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=401, detail="User account no longer exists")
    return user


def hash_refresh_token(raw: str) -> str:
    return hashlib.sha256(raw.encode()).hexdigest()
