"""
CrashLens AI — Cloud Fallback Backend
======================================
Optional FastAPI server. Only used when the user opts in to cloud fallback
in Settings AND the on-device model is unavailable.

Deploy with:
    pip install -r requirements.txt
    uvicorn main:app --host 0.0.0.0 --port 8000

Never receives data unless the user explicitly provides this server's URL
and enables cloud fallback in the app.
"""

import os
import json
import re
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import google.generativeai as genai

app = FastAPI(
    title="CrashLens AI — Cloud Fallback",
    description="Privacy-respecting cloud fallback for on-device crash analysis",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST"],
    allow_headers=["*"],
)

# Configure Gemini API (server-side only — API key never in the app)
genai.configure(api_key=os.environ.get("GEMINI_API_KEY", ""))
model = genai.GenerativeModel("gemini-1.5-flash")

SYSTEM_PROMPT = """You are an expert Android developer and crash analyst.
Analyze the given Android stack trace and respond ONLY with valid JSON matching this schema:
{
  "rootCause": "one-sentence root cause",
  "explanation": "2-3 sentence explanation",
  "suggestedFix": "concrete fix code snippet",
  "confidence": 0.0-1.0,
  "patchDiff": "--- a/File.kt\\n+++ b/File.kt\\n@@ ... @@\\n-old line\\n+new line"
}
No markdown, no prose outside JSON."""


class AnalyzeRequest(BaseModel):
    stack_trace: str
    context: str | None = None


class AnalyzeResponse(BaseModel):
    root_cause: str
    explanation: str
    suggested_fix: str
    confidence: float
    patch_diff: str


@app.post("/analyze-fallback", response_model=AnalyzeResponse)
async def analyze_fallback(req: AnalyzeRequest):
    if not req.stack_trace.strip():
        raise HTTPException(status_code=400, detail="stack_trace is required")

    prompt = f"{SYSTEM_PROMPT}\n\nStack trace:\n{req.stack_trace[:4000]}"

    try:
        response = model.generate_content(prompt)
        raw = response.text.strip()

        # Strip markdown fences if present
        raw = re.sub(r"^```(?:json)?\n?", "", raw)
        raw = re.sub(r"\n?```$", "", raw)

        data = json.loads(raw)
        return AnalyzeResponse(
            root_cause=data.get("rootCause", "Unknown root cause"),
            explanation=data.get("explanation", ""),
            suggested_fix=data.get("suggestedFix", ""),
            confidence=float(data.get("confidence", 0.7)),
            patch_diff=data.get("patchDiff", ""),
        )
    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="Model returned invalid JSON")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
async def health():
    return {"status": "ok", "service": "crashlens-fallback"}
