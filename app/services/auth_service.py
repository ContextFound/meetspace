import secrets
import uuid
from datetime import datetime, timezone
from typing import Optional, Tuple

from passlib.context import CryptContext
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.models.api_key import ApiKey
from app.schemas.auth import RegisterRequest, RegisterResponse

pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

KEY_PREFIX_LEN = 8
KEY_SECRET_LEN = 32
KEY_CHARS = "abcdefghijklmnopqrstuvwxyz0123456789"


def generate_api_key() -> Tuple[str, str]:
    """Generate a new API key and its prefix. Returns (full_key, prefix)."""
    prefix = settings.api_key_prefix
    secret = "".join(secrets.choice(KEY_CHARS) for _ in range(KEY_SECRET_LEN))
    full_key = f"{prefix}{secret}"
    key_prefix = full_key[: len(prefix) + KEY_PREFIX_LEN]
    return full_key, key_prefix


def hash_key(key: str) -> str:
    return pwd_context.hash(key)


def verify_key(plain_key: str, hashed: str) -> bool:
    return pwd_context.verify(plain_key, hashed)


async def register_agent(db: AsyncSession, req: RegisterRequest) -> RegisterResponse:
    full_key, key_prefix = generate_api_key()
    key_hash = hash_key(full_key)

    api_key = ApiKey(
        id=uuid.uuid4(),
        email=req.email,
        agent_name=req.agent_name,
        key_hash=key_hash,
        key_prefix=key_prefix,
        tier="readwrite",
        rate_limit=50,
        is_active=True,
    )
    db.add(api_key)
    await db.flush()
    await db.refresh(api_key)
    return RegisterResponse(
        api_key=full_key,
        key_prefix=key_prefix,
        tier=api_key.tier,
        rate_limit=api_key.rate_limit,
        created_at=api_key.created_at,
    )


async def get_api_key_by_header(db: AsyncSession, api_key: str) -> Optional[ApiKey]:
    if not api_key or len(api_key) < len(settings.api_key_prefix) + KEY_PREFIX_LEN:
        return None
    key_prefix = api_key[: len(settings.api_key_prefix) + KEY_PREFIX_LEN]
    result = await db.execute(
        select(ApiKey).where(
            ApiKey.key_prefix == key_prefix,
            ApiKey.is_active == True,
        )
    )
    row = result.scalar_one_or_none()
    if row is None:
        return None
    if not verify_key(api_key, row.key_hash):
        return None
    return row


async def update_last_used(db: AsyncSession, api_key: ApiKey) -> None:
    api_key.last_used_at = datetime.now(timezone.utc)
    await db.flush()
