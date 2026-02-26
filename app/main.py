from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings
from app.routers import auth, events
from app.schemas.common import ErrorDetail, ErrorResponse


def error_response(code: str, message: str, status: int) -> dict:
    return ErrorResponse(error=ErrorDetail(code=code, message=message, status=status)).model_dump()


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


async def validation_exception_handler(request: Request, exc: RequestValidationError):
    errors = exc.errors()
    messages = [f"{e['loc'][-1]}: {e['msg']}" for e in errors]
    return JSONResponse(
        status_code=422,
        content=error_response("VALIDATION_ERROR", "; ".join(messages), 422),
    )


app = FastAPI(
    title="meetSpace API",
    description="Local IRL events API — agent-queryable by geographic proximity. Events are discoverable by lat/lng and radius. Authentication via X-API-Key header.",
    version="1.0.0",
    lifespan=lifespan,
    openapi_tags=[
        {"name": "auth", "description": "Agent registration and API key management"},
        {"name": "events", "description": "Event discovery and creation"},
    ],
)

app.add_exception_handler(RequestValidationError, validation_exception_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.effective_cors_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "X-API-Key"],
)

app.include_router(auth.router, prefix="/v1/auth", tags=["auth"])
app.include_router(events.router, prefix="/v1/events", tags=["events"])


@app.get("/health")
async def health():
    return {"status": "ok"}
