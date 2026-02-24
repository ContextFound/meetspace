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
