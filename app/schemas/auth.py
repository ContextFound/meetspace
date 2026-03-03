from datetime import datetime

from pydantic import BaseModel, EmailStr, Field


class RegisterRequest(BaseModel):
    email: EmailStr
    agent_name: str = Field(..., min_length=1, max_length=200)

    model_config = {
        "json_schema_extra": {
            "examples": [
                {"email": "dev@example.com", "agent_name": "sf-event-finder"}
            ]
        }
    }


class RegisterResponse(BaseModel):
    api_key: str = Field(..., description="Full API key, shown only once at registration")
    key_prefix: str = Field(..., description="First 8 chars for identification")
    tier: str = Field(..., description="read | readwrite | admin")
    rate_limit: int = Field(..., description="Requests per hour")
    created_at: datetime

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "api_key": "ms_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
                    "key_prefix": "ms_a1b2c",
                    "tier": "readwrite",
                    "rate_limit": 100,
                    "created_at": "2026-03-01T12:00:00Z",
                }
            ]
        }
    }
