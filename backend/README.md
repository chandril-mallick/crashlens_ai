# CrashLens AI — Companion Backend Service

This is an **optional** FastAPI server. The CrashLens AI mobile app functions 100% offline without it.

It is strictly scoped per Section 7 of the Master Brief:
1. `POST /telemetry` — Accepts anonymized aggregate metrics only (crash category counts, never raw logs or code).
2. `GET /model-manifest` — Returns available on-device model versions and SHA256 checksums.
3. `POST /analyze-fallback` — Opt-in cloud fallback when enabled by user.

## Setup & Execution

```bash
# 1. Create a virtual environment
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Set Gemini API key (only needed for cloud fallback option)
export GEMINI_API_KEY="your-key-here"

# 4. Run the backend server
uvicorn main:app --host 0.0.0.0 --port 8000
```

## API Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/telemetry` | Accept anonymized, aggregate crash metrics only |
| `GET` | `/model-manifest` | Retrieve on-device model version & SHA256 checksums |
| `POST` | `/analyze-fallback` | Opt-in cloud fallback analysis via Gemini API |
| `GET` | `/health` | Service health check |

## Strict Privacy Boundary

The backend **never** receives raw stack traces or source code unless the user explicitly opts in to cloud fallback mode in Settings. Telemetry only accepts high-level aggregate exception categories.
