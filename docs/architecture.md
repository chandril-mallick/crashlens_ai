# CrashLens AI — Architecture

## Overview

CrashLens AI is a Flutter application with a layered architecture designed for privacy-first, on-device LLM inference. The key design constraint is that **no user data leaves the device by default**.

---

## Layer Breakdown

### 1. UI Layer (`lib/screens/`, `lib/widgets/`)

Six screens connected via a bottom navigation shell (`AppShell`):

```
AppShell (BottomNavigationBar)
├── HomeScreen      — dashboard, recent crashes, quick-import FAB
├── ImportScreen    — text paste, file picker, ADB pull
├── AnalyzingScreen — animated step progress (auto-navigated)
├── ResultScreen    — confidence score, diff viewer, explanation
├── HistoryScreen   — searchable crash archive
└── SettingsScreen  — model manager, privacy config
```

All screens consume state via `Provider` — no business logic in widgets.

---

### 2. State Layer (`lib/providers/`)

| Provider | Responsibility |
|---|---|
| `CrashAnalysisProvider` | Pipeline orchestrator: input → parse → infer → result |
| `HistoryProvider` | SQLite CRUD for past crash analyses |
| `SettingsProvider` | Persists user preferences via `shared_preferences` |

`CrashAnalysisProvider` accepts an injected `LLMInferenceService`, making it easy to swap Mock ↔ Real ↔ Cloud.

---

### 3. Service Layer (`lib/services/`)

```
LLMInferenceService (abstract interface)
├── MockAnalysisService      — instant canned responses, used in demo mode
├── RealAnalysisService      — on-device Gemma via flutter_gemma
│   ├── Runs in Isolate.run() to prevent UI jank
│   ├── 25-second timeout guard
│   └── JSON prompt → regex parse → structured CrashReport
└── CloudFallbackService     — opt-in POST /analyze-fallback
```

```
StackTraceParser             — regex-based crash frame extractor
DatabaseService              — sqflite wrapper (crashes table)
ModelManagerService          — download, persist, delete Gemma model file
```

---

### 4. Data Layer (`lib/models/`)

| Model | Fields |
|---|---|
| `ParsedCrashContext` | exceptionType, message, frames[], firstPartyFrame |
| `CrashReport` | id, rawTrace, parsedContext, timestamp |
| `AnalysisResult` | rootCause, explanation, suggestedFix, confidence, patchDiff |

---

## Data Flow

```
User pastes / imports crash log
          │
          ▼
   StackTraceParser.parse()
          │
          ▼
   CrashAnalysisProvider.analyze()
          │
    ┌─────┴──────┐
    │            │
    ▼            ▼
MockAnalysis  RealAnalysisService
Service       (Isolate.run → flutter_gemma → JSON parse)
    │            │
    └─────┬──────┘
          │
          ▼
   AnalysisResult
          │
    ┌─────┴──────┐
    │            │
    ▼            ▼
ResultScreen  DatabaseService.saveResult()
```

---

## Privacy Architecture

```
On-Device Boundary
┌─────────────────────────────────────────┐
│  StackTraceParser                       │
│  RealAnalysisService (flutter_gemma)    │
│  DatabaseService (SQLite)               │
│  ModelManagerService                    │
└────────────────────┬────────────────────┘
                     │ opt-in only, explicit toggle
                     ▼
            CloudFallbackService
            POST /analyze-fallback
            (user-controlled URL)
```

The `CloudFallbackService` is only invoked when:
1. User has explicitly toggled "Enable Cloud Fallback" in Settings, AND
2. The on-device model is unavailable (not downloaded or inference failed)

---

## Backend (Optional)

`backend/main.py` is a minimal FastAPI server that proxies to a hosted Gemma instance. It is **not required** to run the app — it exists purely as a fallback for devices that cannot run the ~1.5 GB model locally.

See [`backend/README.md`](../backend/README.md) for deployment instructions.
