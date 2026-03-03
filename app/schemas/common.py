from typing import Optional

from pydantic import BaseModel, Field


class ErrorDetail(BaseModel):
    code: str
    message: str
    status: int


class ErrorResponse(BaseModel):
    error: ErrorDetail

    model_config = {
        "json_schema_extra": {
            "examples": [
                {
                    "error": {
                        "code": "VALIDATION_ERROR",
                        "message": "start_at: Field required; event_type: Field required",
                        "status": 422,
                    }
                }
            ]
        }
    }


class PaginatedResponse(BaseModel):
    next_cursor: Optional[str] = Field(None, description="Cursor for next page; null if no more results")
    limit: int = Field(default=20, description="Page size")
