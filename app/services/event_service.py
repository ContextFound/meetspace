import base64
import math
from datetime import datetime, timezone
from typing import List, Optional, Tuple

from sqlalchemy import and_, delete, func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from ulid import ULID

from zoneinfo import ZoneInfo

from app.models.event import Event
from app.schemas.event import EventCreate, EventResponse, EventUpdate

MILES_TO_METERS = 1609.34
METERS_PER_DEG_LAT = 111_320.0
NEARBY_LIMIT_DEFAULT = 30
NEARBY_LIMIT_MAX = 100


def _encode_cursor(start_at: datetime, event_id: str) -> str:
    raw = f"{start_at.isoformat()}|{event_id}"
    return base64.urlsafe_b64encode(raw.encode()).decode()


def _decode_cursor(cursor: str) -> Tuple[datetime, str]:
    raw = base64.urlsafe_b64decode(cursor.encode()).decode()
    iso, event_id = raw.rsplit("|", 1)
    return datetime.fromisoformat(iso), event_id


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
        cost=e.cost,
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
        cost=req.cost,
        audience=req.audience.value,
        event_type=req.event_type.value,
        created_at=now,
        updated_at=now,
    )
    db.add(event)
    try:
        await db.flush()
    except IntegrityError:
        await db.rollback()
        existing = await db.execute(
            select(Event).where(
                and_(
                    Event.agent_id == api_key_id,
                    Event.title == req.title,
                    Event.start_at == req.start_at,
                    Event.lat == req.lat,
                    Event.lng == req.lng,
                )
            )
        )
        return _event_to_response(existing.scalar_one())
    await db.refresh(event)
    return _event_to_response(event)


async def get_event_by_id(db: AsyncSession, event_id: str) -> Optional[EventResponse]:
    result = await db.execute(select(Event).where(Event.event_id == event_id))
    event = result.scalar_one_or_none()
    if event is None:
        return None
    return _event_to_response(event)


async def update_event(
    db: AsyncSession,
    event_id: str,
    api_key_id,
    req: EventUpdate,
    *,
    is_admin: bool = False,
) -> Optional[EventResponse]:
    result = await db.execute(select(Event).where(Event.event_id == event_id))
    event = result.scalar_one_or_none()
    if event is None or (not is_admin and event.agent_id != api_key_id):
        return None

    for field in req.model_fields_set:
        value = getattr(req, field)
        if field in ("audience", "event_type") and value is not None:
            value = value.value
        setattr(event, field, value)

    if event.end_at is not None:
        if event.end_at <= event.start_at:
            raise ValueError("end_at must be after start_at")
        if event.end_at <= datetime.now(timezone.utc):
            raise ValueError("end_at must be in the future")
        try:
            tz = ZoneInfo(event.timezone)
            if event.start_at.astimezone(tz).date() != event.end_at.astimezone(tz).date():
                raise ValueError(
                    "events cannot span multiple days: "
                    "end_at must be on the same date as start_at "
                    f"in {event.timezone}"
                )
        except KeyError:
            pass

    event.updated_at = datetime.now(timezone.utc)
    await db.flush()
    await db.refresh(event)
    return _event_to_response(event)


async def delete_event(
    db: AsyncSession,
    event_id: str,
    api_key_id,
    *,
    is_admin: bool = False,
) -> bool:
    result = await db.execute(select(Event).where(Event.event_id == event_id))
    event = result.scalar_one_or_none()
    if event is None or (not is_admin and event.agent_id != api_key_id):
        return False
    await db.delete(event)
    await db.flush()
    return True


async def delete_events_by_agent(db: AsyncSession, agent_id) -> int:
    result = await db.execute(
        delete(Event).where(Event.agent_id == agent_id)
    )
    await db.flush()
    return result.rowcount


async def get_events_nearby(
    db: AsyncSession,
    lat: float,
    lng: float,
    radius_miles: Optional[float] = None,
    event_types: Optional[List[str]] = None,
    audiences: Optional[List[str]] = None,
    starts_after: Optional[datetime] = None,
    starts_before: Optional[datetime] = None,
    limit: int = NEARBY_LIMIT_DEFAULT,
    cursor: Optional[str] = None,
) -> Tuple[List[EventResponse], int, int, Optional[str]]:
    now = datetime.now(timezone.utc)

    filters = [or_(Event.end_at.is_(None), Event.end_at >= now)]

    if starts_after is not None:
        filters.append(Event.start_at >= starts_after)
    if starts_before is not None:
        filters.append(Event.start_at < starts_before)
    if radius_miles is not None:
        radius_m = radius_miles * MILES_TO_METERS
        dlat = radius_m / METERS_PER_DEG_LAT
        dlng = radius_m / (METERS_PER_DEG_LAT * math.cos(math.radians(lat)))
        filters.append(Event.lat.between(lat - dlat, lat + dlat))
        filters.append(Event.lng.between(lng - dlng, lng + dlng))
    if event_types:
        filters.append(Event.event_type.in_(event_types))
    if audiences:
        filters.append(Event.audience.in_(audiences))

    total_result = await db.execute(
        select(func.count()).select_from(Event).where(*filters)
    )
    total = total_result.scalar_one()

    if cursor is not None:
        cursor_start_at, cursor_event_id = _decode_cursor(cursor)
        filters.append(
            or_(
                Event.start_at > cursor_start_at,
                and_(Event.start_at == cursor_start_at, Event.event_id > cursor_event_id),
            )
        )

    stmt = (
        select(Event)
        .where(*filters)
        .order_by(Event.start_at.asc(), Event.event_id.asc())
        .limit(limit + 1)
    )
    result = await db.execute(stmt)
    rows = result.scalars().all()

    next_cursor: Optional[str] = None
    if len(rows) > limit:
        rows = rows[:limit]
        last = rows[-1]
        next_cursor = _encode_cursor(last.start_at, last.event_id)

    events = [_event_to_response(e) for e in rows]
    return events, len(events), total, next_cursor
