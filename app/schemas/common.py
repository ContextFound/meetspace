from pydantic import BaseModel


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


