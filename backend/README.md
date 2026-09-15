# CrashLens AI — Cloud Fallback Backend

This is an **optional** FastAPI server. The app works fully offline without it.

It is only invoked when:
1. The user explicitly enables "Cloud Fallback" in Settings, AND
2. The on-device Gemma model is unavailable.

## Setup

```bash
# 1. Create a virtual environment
python -m venv venv
source venv/bin/activate   # Windows: venv\Scripts\activate

# 2. Install dependencies
pip install -r requirements.txt

# 3. Set your Gemini API key
export GEMINI_API_KEY="your-key-here"

# 4. Run
uvicorn main:app --host 0.0.0.0 --port 8000
```

## Endpoints

| Method | Path | Description |
|---|---|---|
| `POST` | `/analyze-fallback` | Analyze a crash stack trace |
| `GET` | `/health` | Health check |

## Privacy

The server receives only the stack trace text provided by the user. No device identifiers, user accounts, or source code is ever collected.
