from typing import Optional

from fastapi import Depends, Header, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.models.api_key import ApiKey
from app.schemas.common import ErrorDetail, ErrorResponse
from app.services.auth_service import get_api_key_by_header, update_last_used


def _unauthorized(code: str, message: str) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=ErrorResponse(
            error=ErrorDetail(code=code, message=message, status=401)
        ).model_dump(),
    )


async def require_api_key(
    x_api_key: Optional[str] = Header(None, alias="X-API-Key"),
    db: AsyncSession = Depends(get_db),
) -> ApiKey:
    if not x_api_key:
        raise _unauthorized("MISSING_API_KEY", "X-API-Key header is required")
    api_key = await get_api_key_by_header(db, x_api_key)
    if api_key is None:
        raise _unauthorized("INVALID_API_KEY", "Invalid or inactive API key")
    await update_last_used(db, api_key)
    return api_key


def require_tier(*allowed: str):
    """Dependency factory that checks API key tier."""

    async def _check(api_key: ApiKey = Depends(require_api_key)) -> ApiKey:
        if api_key.tier not in allowed:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=ErrorResponse(
                    error=ErrorDetail(
                        code="INSUFFICIENT_TIER",
                        message=f"This endpoint requires one of: {', '.join(allowed)}",
                        status=403,
                    )
                ).model_dump(),
            )
        return api_key

    return _check
