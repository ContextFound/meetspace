import math
from datetime import datetime, timezone
from typing import List, Optional, Tuple

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from ulid import ULID

from app.models.event import Event
from app.schemas.event import EventCreate, EventResponse

MILES_TO_METERS = 1609.34
METERS_PER_DEG_LAT = 111_320.0
DEFAULT_PAGE_SIZE = 20


def _event_to_response(e: Event) -> EventResponse:
    return EventResponse(
        event_id=e.event_id,
        agent_id=str(e.agent_id),
        title=e.title,
        description=e.description,
        start_at=e.start_at,
        end_at=e.end_at,
        timezone=e.timezone,
        location_name=e.location_name,
        address=e.address,
        lat=e.lat,
        lng=e.lng,
        url=e.url,
        price=e.price,
        currency=e.currency,
        audience=e.audience,
        event_type=e.event_type,
        created_at=e.created_at,
    )


async def create_event(
    db: AsyncSession,
    api_key_id,
    req: EventCreate,
) -> EventResponse:
    event_id = str(ULID())
    now = datetime.now(timezone.utc)
    event = Event(
        event_id=event_id,
        agent_id=api_key_id,
        title=req.title,
        description=req.description,
        start_at=req.start_at,
        end_at=req.end_at,
        timezone=req.timezone,
        location_name=req.location_name,
        address=req.address,
        lat=req.lat,
        lng=req.lng,
        url=req.url,
        price=req.price,
        currency=req.currency,
        audience=req.audience.value,
        event_type=req.event_type.value,
        created_at=now,
        updated_at=now,
    )
    db.add(event)
    await db.flush()
    await db.refresh(event)
    return _event_to_response(event)


async def get_event_by_id(db: AsyncSession, event_id: str) -> Optional[EventResponse]:
    result = await db.execute(select(Event).where(Event.event_id == event_id))
    event = result.scalar_one_or_none()
    if event is None:
        return None
    return _event_to_response(event)


async def get_events_nearby(
    db: AsyncSession,
    lat: float,
    lng: float,
    radius_miles: Optional[float] = None,
    cursor: Optional[str] = None,
    limit: int = DEFAULT_PAGE_SIZE,
) -> Tuple[List[EventResponse], Optional[str]]:
    now = datetime.now(timezone.utc)

    filters = [Event.start_at >= now]
    if radius_miles is not None:
        radius_m = radius_miles * MILES_TO_METERS
        dlat = radius_m / METERS_PER_DEG_LAT
        dlng = radius_m / (METERS_PER_DEG_LAT * math.cos(math.radians(lat)))
        filters.append(Event.lat.between(lat - dlat, lat + dlat))
        filters.append(Event.lng.between(lng - dlng, lng + dlng))

    stmt = (
        select(Event)
        .where(*filters)
        .order_by(Event.event_id)
        .limit(limit + 1)
    )
    if cursor:
        stmt = stmt.where(Event.event_id > cursor)

    result = await db.execute(stmt)
    rows = result.scalars().all()
    next_cursor = None
    if len(rows) > limit:
        rows = list(rows[:limit])
        next_cursor = rows[-1].event_id

    return [_event_to_response(e) for e in rows], next_cursor
