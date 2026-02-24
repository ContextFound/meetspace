from datetime import datetime
from decimal import Decimal
from enum import Enum
from html.parser import HTMLParser
from typing import List, Optional

from pydantic import BaseModel, Field, field_validator, model_validator


class _HTMLTagStripper(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.result: list[str] = []

    def handle_data(self, data: str) -> None:
        self.result.append(data)

    def get_result(self) -> str:
        return "".join(self.result)


class Audience(str, Enum):
    KIDS = "kids"
    ADULTS = "adults"
    ALL = "all"


class EventType(str, Enum):
    WORKSHOP = "workshop"
    PERFORMANCE = "performance"
    FESTIVAL = "festival"
    MARKET = "market"
    COMPETITION = "competition"
    GAME = "game"
    SOCIAL = "social"
    MEETUP = "meetup"
    CLUB = "club"
    SUPPORT = "support"
    TALK = "talk"
    CONFERENCE = "conference"
    EXHIBITION = "exhibition"
    TOUR = "tour"
    CEREMONY = "ceremony"


class EventCreate(BaseModel):
    title: str = Field(
        ...,
        min_length=1,
        max_length=200,
        description="Plain text. No markdown or HTML.",
    )
    description: Optional[str] = Field(
        None,
        max_length=10000,
        description="Markdown. Rendered by clients (e.g. Flutter). Raw HTML is stripped.",
    )
    start_at: datetime
    end_at: Optional[datetime] = None
    timezone: str = Field(..., description="IANA timezone, e.g. America/New_York")
    location_name: str = Field(..., min_length=1, max_length=200)
    address: Optional[str] = Field(None, max_length=500)
    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)
    url: Optional[str] = Field(None, max_length=2000)
    price: Optional[Decimal] = Field(None, ge=0, description="Absent = not specified, 0 = free")
    currency: Optional[str] = Field(None, pattern="^[A-Z]{3}$", description="ISO 4217; required if price present")
    audience: Audience
    event_type: EventType

    @field_validator("description")
    @classmethod
    def strip_html_from_description(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return None
        stripper = _HTMLTagStripper()
        stripper.feed(v)
        return stripper.get_result()

    @model_validator(mode="after")
    def price_requires_currency(self):
        if self.price is not None and self.currency is None:
            raise ValueError("currency is required when price is present")
        return self

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "title": "Tech Meetup",
                    "start_at": "2026-03-01T18:00:00Z",
                    "timezone": "America/Los_Angeles",
                    "location_name": "Community Center",
                    "lat": 37.7749,
                    "lng": -122.4194,
                    "audience": "adults",
                    "event_type": "meetup",
                }
            ]
        }
    }


class EventsNearbyResponse(BaseModel):
    events: List["EventResponse"]
    next_cursor: Optional[str] = None


class EventResponse(BaseModel):
    event_id: str
    agent_id: str
    title: str
    description: Optional[str] = None
    start_at: datetime
    end_at: Optional[datetime] = None
    timezone: str
    location_name: str
    address: Optional[str] = None
    lat: float
    lng: float
    url: Optional[str] = None
    price: Optional[Decimal] = None
    currency: Optional[str] = None
    audience: str
    event_type: str
    created_at: datetime


EventsNearbyResponse.model_rebuild()
