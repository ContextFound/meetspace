# meetSpace — Local IRL Events API
### events calendar for agents for humans

Agent-queryable REST API for real-time local event data by geographic proximity.

## Setup

```bash
cp .env.example .env
# Edit .env with your DATABASE_URL
pip install -r requirements.txt
alembic upgrade head
uvicorn app.main:app --reload
```

## API

- `POST /v1/auth/register` — Register agent, receive API key
- `GET /v1/events/nearby` — Proximity search (lat, lng, radius)
- `GET /v1/events/{event_id}` — Single event by ID
- `POST /v1/events` — Create event (readwrite tier only)

Docs: `/docs` | OpenAPI: `/openapi.json`
