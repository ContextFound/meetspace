from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi
from fastapi.responses import JSONResponse, PlainTextResponse

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


@app.get("/", include_in_schema=False)
async def root():
    return {
        "name": "meetSpace API",
        "version": "1.0.0",
        "docs_url": "/docs",
        "openapi_url": "/openapi.json",
        "auth_header": "X-API-Key",
        "register": "POST /v1/auth/register",
        "endpoints": [
            "GET  /v1/events/nearby",
            "GET  /v1/events/{event_id}",
            "POST /v1/events",
        ],
    }


@app.get("/.well-known/llms.txt", include_in_schema=False)
async def llms_txt():
    return PlainTextResponse(
        "# meetSpace API\n"
        "\n"
        "## Purpose\n"
        "Local IRL events API — agent-queryable by geographic proximity.\n"
        "Events are discoverable by lat/lng and radius.\n"
        "\n"
        "## Auth\n"
        "All endpoints (except registration) require an X-API-Key header.\n"
        "Obtain a key: POST /v1/auth/register with {email, agent_name}.\n"
        "\n"
        "## OpenAPI\n"
        "Schema: /openapi.json\n"
        "Interactive docs: /docs\n"
        "\n"
        "## Endpoints\n"
        "POST /v1/auth/register  — register an agent, receive API key\n"
        "GET  /v1/events/nearby  — find events by lat/lng/radius\n"
        "GET  /v1/events/{id}    — get single event by ULID\n"
        "POST /v1/events         — create event (readwrite tier)\n"
    )


@app.get("/health")
async def health():
    return {"status": "ok"}


def custom_openapi():
    if app.openapi_schema:
        return app.openapi_schema
    schema = get_openapi(
        title=app.title,
        version=app.version,
        description=app.description,
        routes=app.routes,
        tags=app.openapi_tags,
    )
    schema.setdefault("components", {})["securitySchemes"] = {
        "apiKeyAuth": {
            "type": "apiKey",
            "in": "header",
            "name": "X-API-Key",
            "description": "Register via POST /v1/auth/register to obtain a key.",
        }
    }
    schema["security"] = [{"apiKeyAuth": []}]
    app.openapi_schema = schema
    return schema


app.openapi = custom_openapi
