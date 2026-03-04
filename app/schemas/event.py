from datetime import datetime
from decimal import Decimal
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field, model_validator


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
    title: str = Field(..., min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=10000)
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
    audience: Audience = Audience.ALL
    event_type: EventType

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
                    "description": "Monthly gathering for local developers to share projects and ideas.",
                    "start_at": "2026-03-15T18:00:00Z",
                    "end_at": "2026-03-15T20:00:00Z",
                    "timezone": "America/Los_Angeles",
                    "location_name": "Community Center",
                    "address": "123 Main St, San Francisco, CA 94105",
                    "lat": 37.7749,
                    "lng": -122.4194,
                    "url": "https://example.com/tech-meetup",
                    "price": 0,
                    "currency": "USD",
                    "audience": "adults",
                    "event_type": "meetup",
                }
            ]
        }
    }


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

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "event_id": "01JAXYZ1234567890ABCDEFGH",
                    "agent_id": "01JABC9876543210ZYXWVUTSR",
                    "title": "Tech Meetup",
                    "description": "Monthly gathering for local developers.",
                    "start_at": "2026-03-15T18:00:00Z",
                    "end_at": "2026-03-15T20:00:00Z",
                    "timezone": "America/Los_Angeles",
                    "location_name": "Community Center",
                    "address": "123 Main St, San Francisco, CA 94105",
                    "lat": 37.7749,
                    "lng": -122.4194,
                    "url": "https://example.com/tech-meetup",
                    "price": 0,
                    "currency": "USD",
                    "audience": "adults",
                    "event_type": "meetup",
                    "created_at": "2026-03-01T12:00:00Z",
                }
            ]
        }
    }


class EventsNearbyResponse(BaseModel):
    events: List[EventResponse]
    count: int = Field(..., description="Number of events returned in this response")
    total: int = Field(..., description="Total matching events (may exceed count)")

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "events": [
                        {
                            "event_id": "01JAXYZ1234567890ABCDEFGH",
                            "agent_id": "01JABC9876543210ZYXWVUTSR",
                            "title": "Tech Meetup",
                            "description": "Monthly gathering for local developers.",
                            "start_at": "2026-03-15T18:00:00Z",
                            "end_at": "2026-03-15T20:00:00Z",
                            "timezone": "America/Los_Angeles",
                            "location_name": "Community Center",
                            "address": "123 Main St, San Francisco, CA 94105",
                            "lat": 37.7749,
                            "lng": -122.4194,
                            "url": "https://example.com/tech-meetup",
                            "price": 0,
                            "currency": "USD",
                            "audience": "adults",
                            "event_type": "meetup",
                            "created_at": "2026-03-01T12:00:00Z",
                        },
                        {
                            "event_id": "01JAQRS5678901234MNOPQRST",
                            "agent_id": "01JABC9876543210ZYXWVUTSR",
                            "title": "Farmers Market",
                            "description": None,
                            "start_at": "2026-03-16T08:00:00Z",
                            "end_at": "2026-03-16T13:00:00Z",
                            "timezone": "America/Los_Angeles",
                            "location_name": "Ferry Building",
                            "address": "1 Ferry Building, San Francisco, CA 94111",
                            "lat": 37.7956,
                            "lng": -122.3933,
                            "url": None,
                            "price": None,
                            "currency": None,
                            "audience": "all",
                            "event_type": "market",
                            "created_at": "2026-03-02T09:30:00Z",
                        },
                    ],
                    "count": 2,
                    "total": 45,
                }
            ]
        }
    }
