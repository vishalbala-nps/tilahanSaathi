# Tilahan Saathi

**Tilahan Saathi** ("Oilseed Companion") is an AI-powered decision-support app for Indian oilseed farmers. It recommends crops for a farmer's land (via a trained ML model + LLM-generated "Tilahaan Score" insights), tracks land and oilseed calendars, compares market prices, and surfaces relevant government schemes.

The project is a monorepo with two parts:

| Path | Stack | Purpose |
|---|---|---|
| [`api/`](api/) | FastAPI + SQLAlchemy (async) + scikit-learn | Backend REST API, auth, crop recommendation model, price/scheme data |
| [`tilahan_saathi_nit/`](tilahan_saathi_nit/) | Flutter | Mobile/web client app |

---

## 1. Backend (`api/`)

### Requirements

- Python 3.12+
- [uv](https://docs.astral.sh/uv/) for dependency management
- A database: SQLite (default, local dev) or PostgreSQL (prod, e.g. Supabase or the bundled `docker-compose.yml`)
- A Firebase service account JSON (for Firebase Auth verification)
- (Optional) [Ollama](https://ollama.com/) running locally for the default LLM, or a Gemini API key

### Setup

```bash
cd api
uv sync
```

Copy the example env file and fill in the values:

```bash
cp .env.example .env
```

Key variables in `.env`:

- `DATABASE_URL` — `sqlite+aiosqlite:///./tilahan_saathi.db` for local dev, or a `postgresql+asyncpg://...` URL for prod.
- `JWT_SECRET_KEY` — generate with `python -c "import secrets; print(secrets.token_urlsafe(64))"`.
- `FIREBASE_CREDENTIALS_PATH` — path to your Firebase service account JSON (default `secrets/firebase-service-account.json`). Place the file at `api/secrets/firebase-service-account.json`.
- `LLM_MODEL` — defaults to a local Ollama model (`ollama_chat/gemma4`); run `ollama pull gemma4` first, or switch to `gemini/<model>` and set `GEMINI_API_KEY`.
- `AGMARKNET_API_URL` — used to sync oilseed market prices.

### Database migrations

The app uses Alembic. Run migrations before starting the server:

```bash
uv run alembic upgrade head
```

### Run locally

```bash
uv run uvicorn app.main:app --reload
```

The API will be available at `http://localhost:8000` (interactive docs at `/docs`).

### Run with Docker Compose (API + Postgres)

```bash
cd api
docker compose up --build
```

This starts a Postgres container and the API (which runs migrations automatically on boot via the Dockerfile's `CMD`). Requires `secrets/firebase-service-account.json` to exist locally (it's mounted read-only into the container) and a `.env` file with the LLM/Firebase/JWT settings.

### Admin scripts

Manage government scheme records without a redeploy:

```bash
uv run python scripts/manage_schemes.py list
uv run python scripts/manage_schemes.py show pm_kisan
```

---

## 2. Frontend (`tilahan_saathi_nit/`)

### Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart >=3.2.0 <4.0.0)
- Firebase project configured for the app (`firebase.json` / `firebase_options.dart` already checked in for the `tilahansaathi` project)

### Setup

```bash
cd tilahan_saathi_nit
flutter pub get
```

Copy the example env file:

```bash
cp .env.example .env
```

Set `API_URL` in `.env` to point at your backend (e.g. `http://localhost:8000` for local dev, or your deployed API URL in prod).

### Run locally

```bash
flutter run
```

### Build

```bash
flutter build apk          # Android APK
flutter build appbundle    # Android App Bundle (Play Store)
```

---

## 3. Deployment

### Backend — Render (Docker)

The `api/` service is set up to deploy as a Docker web service on [Render](https://render.com):

1. Create a new **Web Service** on Render, pointing at this repo with the root directory set to `api/`.
2. Render will build using `api/Dockerfile`.
3. Set environment variables in the Render dashboard to match `api/.env.example` (`DATABASE_URL`, `JWT_SECRET_KEY`, `FIREBASE_CREDENTIALS_PATH`, `LLM_MODEL`, `GEMINI_API_KEY` if using Gemini, `AGMARKNET_API_URL`, etc.).
4. Since `secrets/firebase-service-account.json` is gitignored, either add it as a Render **Secret File** at the path referenced by `FIREBASE_CREDENTIALS_PATH`, or set the credentials via an environment variable and adjust the app to read from it.
5. Point `DATABASE_URL` at a managed Postgres instance (e.g. Render Postgres or Supabase) — SQLite is not suitable for production.
6. On boot, the container automatically runs `alembic upgrade head` before starting `uvicorn` (see the `CMD` in `Dockerfile`).

### Frontend — Flutter

- **Android**: `flutter build appbundle` and upload to the Play Console.
- **Web**: `flutter build web`, then deploy the contents of `build/web` to any static host (e.g. Firebase Hosting, Vercel, Netlify).
- Make sure `.env` (`API_URL`) points at the deployed backend before building for release, since Flutter bakes the env file into the build as an asset.

---

## Notes

- The oilseed crop recommendation model is a pre-trained scikit-learn artifact at `api/models/oilseed_model.pkl`, loaded by the API at runtime.
