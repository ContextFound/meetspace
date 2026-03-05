from datetime import datetime
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies.auth import require_api_key, require_tier
from app.models.api_key import ApiKey
from app.schemas.common import ErrorDetail, ErrorResponse
from app.schemas.event import Audience, EventCreate, EventResponse, EventType, EventsNearbyResponse, EventUpdate
from app.services.event_service import create_event, delete_event, get_event_by_id, get_events_nearby, update_event

router = APIRouter()

RADIUS_MIN = 0.1
RADIUS_MAX = 100.0


@router.get(
    "/nearby",
    response_model=EventsNearbyResponse,
    summary="Find events by location",
    response_description="Up to 30 soonest upcoming events matching the filters. Response includes count/total so callers know if results were capped.",
)
async def nearby(
    lat: float = Query(..., ge=-90, le=90, description="Latitude"),
    lng: float = Query(..., ge=-180, le=180, description="Longitude"),
    radius: Optional[float] = Query(None, ge=RADIUS_MIN, le=RADIUS_MAX, description="Radius in miles. Omit for all events."),
    event_type: Optional[List[EventType]] = Query(None, description="Filter by event type(s). Omit for all types."),
    audience: Optional[List[Audience]] = Query(None, description="Filter by audience(s). Omit for all audiences."),
    starts_after: Optional[datetime] = Query(None, description="Only events starting at or after this time (inclusive, ISO 8601). Past events are always excluded."),
    starts_before: Optional[datetime] = Query(None, description="Only events starting before this time (exclusive, ISO 8601)."),
    db: AsyncSession = Depends(get_db),
    api_key: ApiKey = Depends(require_api_key),
):
    event_type_values = [e.value for e in event_type] if event_type else None
    audience_values = [a.value for a in audience] if audience else None
    events, count, total = await get_events_nearby(
        db, lat, lng, radius,
        event_types=event_type_values,
        audiences=audience_values,
        starts_after=starts_after,
        starts_before=starts_before,
    )
    return EventsNearbyResponse(events=events, count=count, total=total)


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


def _not_found(event_id: str) -> HTTPException:
    return HTTPException(
        status_code=status.HTTP_404_NOT_FOUND,
        detail=ErrorResponse(
            error=ErrorDetail(
                code="NOT_FOUND",
                message=f"Event {event_id} not found",
                status=404,
            )
        ).model_dump(),
    )


@router.patch(
    "/{event_id}",
    response_model=EventResponse,
    summary="Update event",
    response_description="Updated event. Requires readwrite tier and ownership.",
)
async def update(
    event_id: str,
    req: EventUpdate,
    db: AsyncSession = Depends(get_db),
    api_key: ApiKey = Depends(require_tier("readwrite", "admin")),
):
    try:
        result = await update_event(
            db, event_id, api_key.id, req, is_admin=api_key.tier == "admin"
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=ErrorResponse(
                error=ErrorDetail(
                    code="VALIDATION_ERROR",
                    message=str(e),
                    status=422,
                )
            ).model_dump(),
        )
    if result is None:
        raise _not_found(event_id)
    return result


@router.delete(
    "/{event_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Delete event",
    response_description="Event deleted. Requires readwrite tier and ownership.",
)
async def delete(
    event_id: str,
    db: AsyncSession = Depends(get_db),
    api_key: ApiKey = Depends(require_tier("readwrite", "admin")),
):
    deleted = await delete_event(
        db, event_id, api_key.id, is_admin=api_key.tier == "admin"
    )
    if not deleted:
        raise _not_found(event_id)
