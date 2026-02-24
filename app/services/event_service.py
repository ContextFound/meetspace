from datetime import datetime, timezone
from typing import List, Optional, Tuple


from geoalchemy2.elements import WKTElement
from shapely import wkb
from sqlalchemy import and_, func, select
from sqlalchemy.ext.asyncio import AsyncSession
from ulid import ULID

from app.models.event import Event
from app.schemas.event import EventCreate, EventResponse, Audience, EventType

MILES_TO_METERS = 1609.34
DEFAULT_PAGE_SIZE = 20


def _wkt_point(lng: float, lat: float) -> WKTElement:
    return WKTElement(f"POINT({lng} {lat})", srid=4326)


def _extract_lng_lat(coord) -> Tuple[float, float]:
    """Extract (lng, lat) from GeoAlchemy2 Geography/WKB."""
    if coord is None:
        return 0.0, 0.0
    data = coord.data
    try:
        geom = wkb.loads(bytes(data))
    except (TypeError, ValueError):
        geom = wkb.loads(data, hex=True)
    return float(geom.x), float(geom.y)


def _event_to_response(e: Event, lng: float, lat: float) -> EventResponse:
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
        lat=lat,
        lng=lng,
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
    coordinates = _wkt_point(req.lng, req.lat)
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
        coordinates=coordinates,
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
    return _event_to_response(event, req.lng, req.lat)


async def get_event_by_id(db: AsyncSession, event_id: str) -> Optional[EventResponse]:
    result = await db.execute(select(Event).where(Event.event_id == event_id))
    event = result.scalar_one_or_none()
    if event is None:
        return None
    lng, lat = _extract_lng_lat(event.coordinates)
    return _event_to_response(event, lng, lat)


async def get_events_nearby(
    db: AsyncSession,
    lat: float,
    lng: float,
    radius_miles: float,
    cursor: Optional[str] = None,
    limit: int = DEFAULT_PAGE_SIZE,
) -> Tuple[List[EventResponse], Optional[str]]:
    radius_m = radius_miles * MILES_TO_METERS
    now = datetime.now(timezone.utc)
    point_wkt = f"SRID=4326;POINT({lng} {lat})"

    stmt = (
        select(Event)
        .where(
            Event.start_at >= now,
            func.ST_DWithin(
                Event.coordinates,
                func.ST_GeogFromText(point_wkt),
                radius_m,
            ),
        )
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

    events = []
    for e in rows:
        lng_e, lat_e = _extract_lng_lat(e.coordinates)
        events.append(_event_to_response(e, lng_e, lat_e))

    return events, next_cursor
