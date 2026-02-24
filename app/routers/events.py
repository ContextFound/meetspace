from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies.auth import require_api_key, require_tier
from app.models.api_key import ApiKey
from app.schemas.common import ErrorDetail, ErrorResponse
from app.schemas.event import EventCreate, EventResponse, EventsNearbyResponse
from app.services.event_service import create_event, get_event_by_id, get_events_nearby

router = APIRouter()

RADIUS_MIN = 0.1
RADIUS_MAX = 100.0


@router.get(
    "/nearby",
    response_model=EventsNearbyResponse,
    summary="Find events by location",
    response_description="Events within the specified radius, excluding past events. Use next_cursor for pagination.",
)
async def nearby(
    lat: float = Query(..., ge=-90, le=90, description="Latitude"),
    lng: float = Query(..., ge=-180, le=180, description="Longitude"),
    radius: float = Query(..., ge=RADIUS_MIN, le=RADIUS_MAX, description="Radius in miles"),
    cursor: Optional[str] = Query(None, description="Pagination cursor"),
    limit: int = Query(20, ge=1, le=100, description="Page size"),
    db: AsyncSession = Depends(get_db),
    api_key: ApiKey = Depends(require_api_key),
):
    events, next_cursor = await get_events_nearby(db, lat, lng, radius, cursor, limit)
    return EventsNearbyResponse(events=events, next_cursor=next_cursor)


@router.get(
    "/{event_id}",
    response_model=EventResponse,
    summary="Get event by ID",
    response_description="Single event by ULID.",
)
async def get_event(
    event_id: str,
    db: AsyncSession = Depends(get_db),
    api_key: ApiKey = Depends(require_api_key),
):
    event = await get_event_by_id(db, event_id)
    if event is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=ErrorResponse(
                error=ErrorDetail(
                    code="NOT_FOUND",
                    message=f"Event {event_id} not found",
                    status=404,
                )
            ).model_dump(),
        )
    return event


@router.post(
    "",
    response_model=EventResponse,
    summary="Create event",
    response_description="Created event with server-assigned event_id and agent_id. Requires readwrite tier.",
)
async def create(
    req: EventCreate,
    db: AsyncSession = Depends(get_db),
    api_key: ApiKey = Depends(require_tier("readwrite")),
):
    return await create_event(db, api_key.id, req)
