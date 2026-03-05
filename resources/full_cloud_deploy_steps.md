# Full Cloud Deploy Runbook

The deployment has three independent tracks: **database migrations**, **API container to Cloud Run**, and **Flutter web to Firebase Hosting**. The API deploy depends on migrations being run first; the web deploy is fully independent.

---

## Step 0 -- Pre-flight checks

```bash
# Confirm you're on the right GCP project
gcloud config get-value project
# Should print: meetspace-events

# Confirm you're logged in
gcloud auth list
firebase login:list
```

---

## Step 1 -- Database migrations (Alembic via Cloud SQL Auth Proxy)

If you have pending Alembic migrations, run them **before** deploying the new API code.

```bash
# Terminal 1: Start the Cloud SQL Auth Proxy
cloud-sql-proxy meetspace-events:us-central1:meetspace-id

# Terminal 2: Run migrations against the proxied DB
DATABASE_URL="postgresql+asyncpg://USER:PASS@127.0.0.1:5432/meetspace" \
  alembic upgrade head
```

- Replace `USER:PASS` with your Cloud SQL credentials (or pull `DATABASE_URL` from Secret Manager: `gcloud secrets versions access latest --secret=meetspace-database-url`).
- If there are **no** new migrations, skip this step entirely.

---

## Step 2 -- API deploy (Cloud Run)

### 2a. Build and push the container image

```bash
# From the repo root (where Dockerfile lives)
gcloud builds submit --tag us-central1-docker.pkg.dev/meetspace-events/cloud-run-source-deploy/meetspace-api:latest
```

### 2b. Deploy to Cloud Run

```bash
gcloud run deploy meetspace-api \
  --image us-central1-docker.pkg.dev/meetspace-events/cloud-run-source-deploy/meetspace-api:latest \
  --region=us-central1 \
  --service-account=meetspace-api-sa@meetspace-events.iam.gserviceaccount.com \
  --add-cloudsql-instances=meetspace-events:us-central1:meetspace-id \
  --set-secrets=DATABASE_URL=meetspace-database-url:latest \
  --port=8000 \
  --allow-unauthenticated
```

Notes:

- `gcloud run deploy` both creates and updates a service (prefer it over `services update` since it also sets the image in one shot).
- `--port=8000` matches the Uvicorn port in the Dockerfile.

### 2c. Smoke test

```bash
curl https://api.meetspace.events/health
```

---

## Step 3 -- Web deploy (Firebase Hosting)

### 3a. Build the Flutter web app

```bash
cd web
flutter build web
```

The build output lands in `web/build/web`, which is what `firebase.json` points `"public"` at.

If you ever need to target a different API URL:

```bash
flutter build web --dart-define=MEETSPACE_API_URL=https://some-other-url.run.app
```

The default is `https://api.meetspace.events` (set in `web/lib/api/config.dart`).

### 3b. Deploy to Firebase Hosting

```bash
# Still inside web/
firebase deploy --only hosting
```

### 3c. Verify

Open your Firebase Hosting domain and confirm the site loads.

---

## Quick-reference: full push copy-paste block

```bash
# -- API --
gcloud builds submit --tag us-central1-docker.pkg.dev/meetspace-events/cloud-run-source-deploy/meetspace-api:latest

gcloud run deploy meetspace-api \
  --image us-central1-docker.pkg.dev/meetspace-events/cloud-run-source-deploy/meetspace-api:latest \
  --region=us-central1 \
  --service-account=meetspace-api-sa@meetspace-events.iam.gserviceaccount.com \
  --add-cloudsql-instances=meetspace-events:us-central1:meetspace-id \
  --set-secrets=DATABASE_URL=meetspace-database-url:latest \
  --port=8000 \
  --allow-unauthenticated

curl https://api.meetspace.events/health

# -- Web --
cd web
flutter build web
firebase deploy --only hosting
```

---

## Configuration reference

- **Container registry**: Artifact Registry at `us-central1-docker.pkg.dev/meetspace-events/cloud-run-source-deploy/meetspace-api`
- **Public access**: `--allow-unauthenticated` is included
- **Database credentials for migrations**: Pull from Secret Manager or use a local `.env`
