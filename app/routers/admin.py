from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.dependencies.admin_auth import require_admin
from app.models.api_key import ApiKey
from app.models.event import Event
from app.schemas.admin import (
    AdminUserResponse,
    AgentEventsResponse,
    AgentListResponse,
    AgentSummary,
)
from app.schemas.event import EventResponse

router = APIRouter()


@router.get("/me", response_model=AdminUserResponse)
async def admin_me(user: dict = Depends(require_admin)):
    """Verify the caller's Firebase token and return their profile."""
    return AdminUserResponse(
        email=user["email"],
        name=user["name"],
        picture=user["picture"],
    )


@router.get("/agents", response_model=AgentListResponse)
async def list_agents(
    _user: dict = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    event_count_subq = (
        select(
            Event.agent_id,
            func.count(Event.event_id).label("event_count"),
        )
        .group_by(Event.agent_id)
        .subquery()
    )

    stmt = (
        select(ApiKey, func.coalesce(event_count_subq.c.event_count, 0).label("event_count"))
        .outerjoin(event_count_subq, ApiKey.id == event_count_subq.c.agent_id)
        .order_by(ApiKey.created_at.desc())
    )

    result = await db.execute(stmt)
    rows = result.all()

    agents = [
        AgentSummary(
            id=row.ApiKey.id,
            email=row.ApiKey.email,
            agent_name=row.ApiKey.agent_name,
            tier=row.ApiKey.tier,
            is_active=row.ApiKey.is_active,
            created_at=row.ApiKey.created_at,
            last_used_at=row.ApiKey.last_used_at,
            event_count=row.event_count,
        )
        for row in rows
    ]

    return AgentListResponse(agents=agents, total=len(agents))


@router.get("/agents/{agent_id}/events", response_model=AgentEventsResponse)
async def get_agent_events(
    agent_id: UUID,
    _user: dict = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    agent_result = await db.execute(select(ApiKey).where(ApiKey.id == agent_id))
    agent = agent_result.scalar_one_or_none()
    if agent is None:
        raise HTTPException(status_code=404, detail="Agent not found")

    events_result = await db.execute(
        select(Event)
        .where(Event.agent_id == agent_id)
        .order_by(Event.created_at.desc())
    )
    events = events_result.scalars().all()

    event_count = len(events)
    agent_summary = AgentSummary(
        id=agent.id,
        email=agent.email,
        agent_name=agent.agent_name,
        tier=agent.tier,
        is_active=agent.is_active,
        created_at=agent.created_at,
        last_used_at=agent.last_used_at,
        event_count=event_count,
    )

    event_responses = [
        EventResponse(
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
        for e in events
    ]

    return AgentEventsResponse(agent=agent_summary, events=event_responses)
