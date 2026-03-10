from datetime import datetime
from typing import List, Optional
from uuid import UUID

from pydantic import BaseModel

from app.schemas.event import EventResponse


class AdminUserResponse(BaseModel):
    email: str
    name: str
    picture: str


class AgentSummary(BaseModel):
    id: UUID
    email: str
    agent_name: str
    tier: str
    is_active: bool
    created_at: datetime
    last_used_at: Optional[datetime] = None
    event_count: int


class AgentListResponse(BaseModel):
    agents: List[AgentSummary]
    total: int


class AgentEventsResponse(BaseModel):
    agent: AgentSummary
    events: List[EventResponse]
