from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.schemas.auth import RegisterRequest, RegisterResponse
from app.services.auth_service import register_agent

router = APIRouter()


@router.post(
    "/register",
    response_model=RegisterResponse,
    summary="Register agent",
    response_description="API key and metadata. The full api_key is shown only once — store it securely.",
)
async def register(
    req: RegisterRequest,
    db: AsyncSession = Depends(get_db),
):
    """Register a new agent and receive an API key. The key is shown only once and cannot be retrieved later. Use the X-API-Key header on subsequent requests."""
    return await register_agent(db, req)
