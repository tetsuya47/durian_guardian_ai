# System Architecture — Durian Guardian AI

This document details the clean architecture separation boundaries utilized in the Hapii Green codebase.

```
                  ┌──────────────────────┐
                  │ Flutter Mobile App   │
                  │ (Riverpod State)     │
                  └──────────┬───────────┘
                             │ REST JSON
                             ▼
                  ┌──────────────────────┐
                  │ FastAPI REST API     │
                  │ (Uvicorn Gateway)    │
                  └──────────┬───────────┘
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
   ┌─────────────────┐               ┌─────────────────┐
   │  MongoDB Atlas  │               │   AI Inference  │
   │  (NoSQL Storage)│               │   (ModelManager)│
   └─────────────────┘               └─────────────────┘
```

---

## 1. Frontend Layer Separation (Flutter)
Adheres to Clean Architecture boundaries:
- **Presentation Layer**: Riverpod controllers (`StateNotifierProvider`) feeding stateless widgets. Refrains from executing business calculations.
- **Domain Layer**: Contains plain Dart domain models, entities, and repository interface signatures.
- **Data Layer**: Concrete data mapping classes (`RepositoryImpl` and `RemoteDataSourceImpl`) invoking HTTP payloads via `DioApiClient`.

---

## 2. Backend Layer Separation (FastAPI)
Adheres to Router-Service-Repository boundaries:
- **API Routing**: Exposes endpoint signatures in `app/api/v1/` validating Pydantic models.
- **Service Layer**: Governs business workflows and runs multi-stage orchestrations (e.g. `AIService`).
- **Repository Layer**: Coordinates MongoDB collections with BaseRepository helpers to guarantee query safety.
- **AI Runtime Layer**: Isolates weight management in a thread-safe singleton cache (`ModelManager`).
