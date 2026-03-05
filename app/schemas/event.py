from datetime import datetime, timezone
from enum import Enum
from typing import List, Optional
from urllib.parse import urlparse
from zoneinfo import ZoneInfo

from pydantic import BaseModel, Field, field_validator, model_validator


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
    cost: Optional[str] = Field(None, max_length=200, description="Free-text cost, e.g. '$10', 'Free', 'Donation-based'")
    audience: Audience = Audience.ALL
    event_type: EventType

    @field_validator("url")
    @classmethod
    def url_must_be_http(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        parsed = urlparse(v)
        if parsed.scheme not in ("http", "https") or not parsed.netloc:
            raise ValueError("url must be a valid HTTP or HTTPS URL")
        return v

    @model_validator(mode="after")
    def _cross_field_checks(self):
        if self.end_at is not None:
            if self.end_at <= self.start_at:
                raise ValueError("end_at must be after start_at")
            if self.end_at <= datetime.now(timezone.utc):
                raise ValueError("end_at must be in the future")
            try:
                tz = ZoneInfo(self.timezone)
                start_local = self.start_at.astimezone(tz).date()
                end_local = self.end_at.astimezone(tz).date()
                if start_local != end_local:
                    raise ValueError(
                        "events cannot span multiple days: "
                        "end_at must be on the same date as start_at "
                        f"in {self.timezone}"
                    )
            except KeyError:
                pass
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
                    "cost": "Free",
                    "audience": "adults",
                    "event_type": "meetup",
                }
            ]
        }
    }


class EventUpdate(BaseModel):
    """Partial update — only fields present in the request body are changed.
    Send null for nullable fields (description, end_at, address, url, cost) to
    clear them.  Non-nullable fields reject null."""

    title: Optional[str] = Field(None, min_length=1, max_length=200)
    description: Optional[str] = Field(None, max_length=10000)
    start_at: Optional[datetime] = None
    end_at: Optional[datetime] = None
    timezone: Optional[str] = None
    location_name: Optional[str] = Field(None, min_length=1, max_length=200)
    address: Optional[str] = Field(None, max_length=500)
    lat: Optional[float] = Field(None, ge=-90, le=90)
    lng: Optional[float] = Field(None, ge=-180, le=180)
    url: Optional[str] = Field(None, max_length=2000)
    cost: Optional[str] = Field(None, max_length=200, description="Free-text cost, e.g. '$10', 'Free', 'Donation-based'")
    audience: Optional[Audience] = None
    event_type: Optional[EventType] = None

    @field_validator("url")
    @classmethod
    def url_must_be_http(cls, v: Optional[str]) -> Optional[str]:
        if v is None:
            return v
        parsed = urlparse(v)
        if parsed.scheme not in ("http", "https") or not parsed.netloc:
            raise ValueError("url must be a valid HTTP or HTTPS URL")
        return v

    @model_validator(mode="after")
    def _checks(self):
        non_nullable = {"title", "start_at", "timezone", "location_name", "lat", "lng", "audience", "event_type"}
        for field in non_nullable:
            if field in self.model_fields_set and getattr(self, field) is None:
                raise ValueError(f"{field} cannot be null")

        if (
            "end_at" in self.model_fields_set
            and "start_at" in self.model_fields_set
            and self.end_at is not None
            and self.start_at is not None
        ):
            if self.end_at <= self.start_at:
                raise ValueError("end_at must be after start_at")
            tz_str = self.timezone
            if tz_str:
                try:
                    tz = ZoneInfo(tz_str)
                    if self.start_at.astimezone(tz).date() != self.end_at.astimezone(tz).date():
                        raise ValueError(
                            "events cannot span multiple days: "
                            "end_at must be on the same date as start_at "
                            f"in {tz_str}"
                        )
                except KeyError:
                    pass
        return self


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
    cost: Optional[str] = None
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
                    "cost": "Free",
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
                            "cost": "Free",
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
                            "cost": None,
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
