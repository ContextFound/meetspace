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
        "GET  /v1/events/nearby  — find events by lat/lng/radius with optional filters\n"
        "  Optional filters: event_type (list), audience (list), starts_after, starts_before\n"
        "  Returns up to 30 soonest events, ordered by start_at, with count/total fields\n"
        "GET  /v1/events/{id}    — get single event by ULID\n"
        "POST /v1/events         — create event (readwrite tier)\n"
    )


@app.get("/for-agents", include_in_schema=False)
async def for_agents():
    base = "https://api.meetspace.events"
    return {
        "description": "60-second quickstart for AI agents — register, create an event, query nearby.",
        "base_url": base,
        "openapi_url": f"{base}/openapi.json",
        "docs_url": f"{base}/docs",
        "steps": [
            {
                "step": 1,
                "name": "Register",
                "method": "POST",
                "path": "/v1/auth/register",
                "headers": {"Content-Type": "application/json"},
                "curl": (
                    f'curl -X POST {base}/v1/auth/register '
                    '-H "Content-Type: application/json" '
                    '-d \'{"email":"dev@example.com","agent_name":"sf-event-finder"}\''
                ),
                "request_body": {
                    "email": "dev@example.com",
                    "agent_name": "sf-event-finder",
                },
                "response_example": {
                    "api_key": "ms_a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6",
                    "key_prefix": "ms_a1b2c",
                    "tier": "readwrite",
                    "rate_limit": 100,
                    "created_at": "2026-03-01T12:00:00Z",
                },
            },
            {
                "step": 2,
                "name": "Create event",
                "method": "POST",
                "path": "/v1/events",
                "headers": {
                    "Content-Type": "application/json",
                    "X-API-Key": "<your-api-key>",
                },
                "curl": (
                    f'curl -X POST {base}/v1/events '
                    '-H "Content-Type: application/json" '
                    '-H "X-API-Key: <your-api-key>" '
                    "-d '"
                    '{"title":"Tech Meetup",'
                    '"description":"Monthly gathering for local developers to share projects and ideas.",'
                    '"start_at":"2026-03-15T18:00:00Z",'
                    '"end_at":"2026-03-15T20:00:00Z",'
                    '"timezone":"America/Los_Angeles",'
                    '"location_name":"Community Center",'
                    '"address":"123 Main St, San Francisco, CA 94105",'
                    '"lat":37.7749,"lng":-122.4194,'
                    '"price":0,"currency":"USD",'
                    '"audience":"adults","event_type":"meetup"}\''
                ),
                "request_body": {
                    "title": "Tech Meetup",
                    "description": "Monthly gathering for local developers to share projects and ideas.",
                    "start_at": "2026-03-15T18:00:00Z",
                    "end_at": "2026-03-15T20:00:00Z",
                    "timezone": "America/Los_Angeles",
                    "location_name": "Community Center",
                    "address": "123 Main St, San Francisco, CA 94105",
                    "lat": 37.7749,
                    "lng": -122.4194,
                    "price": 0,
                    "currency": "USD",
                    "audience": "adults",
                    "event_type": "meetup",
                },
                "response_example": {
                    "event_id": "01JAXYZ1234567890ABCDEFGH",
                    "agent_id": "01JABC9876543210ZYXWVUTSR",
                    "title": "Tech Meetup",
                    "description": "Monthly gathering for local developers to share projects and ideas.",
                    "start_at": "2026-03-15T18:00:00Z",
                    "end_at": "2026-03-15T20:00:00Z",
                    "timezone": "America/Los_Angeles",
                    "location_name": "Community Center",
                    "address": "123 Main St, San Francisco, CA 94105",
                    "lat": 37.7749,
                    "lng": -122.4194,
                    "url": None,
                    "price": 0,
                    "currency": "USD",
                    "audience": "adults",
                    "event_type": "meetup",
                    "created_at": "2026-03-01T12:00:00Z",
                },
            },
            {
                "step": 3,
                "name": "Nearby query",
                "method": "GET",
                "path": "/v1/events/nearby?lat=37.7749&lng=-122.4194&radius=5&event_type=meetup&event_type=workshop",
                "headers": {"X-API-Key": "<your-api-key>"},
                "curl": (
                    f'curl "{base}/v1/events/nearby?lat=37.7749&lng=-122.4194&radius=5&event_type=meetup&event_type=workshop" '
                    '-H "X-API-Key: <your-api-key>"'
                ),
                "query_params": {
                    "lat": "required — latitude",
                    "lng": "required — longitude",
                    "radius": "optional — miles (0.1–100). Omit for any distance",
                    "event_type": "optional — repeat for multiple (e.g. event_type=meetup&event_type=talk). Omit for all types",
                    "audience": "optional — repeat for multiple (kids, adults, all). Omit for all audiences",
                    "starts_after": "optional — ISO 8601 datetime, inclusive (>=). Past events are always excluded",
                    "starts_before": "optional — ISO 8601 datetime, exclusive (<)",
                },
                "request_body": None,
                "response_notes": "Returns up to 30 soonest events ordered by start_at. count = events returned, total = all matching events.",
                "response_example": {
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
                },
            },
        ],
    }


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
