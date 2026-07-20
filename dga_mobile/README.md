# Durian Guardian AI (Hapii Green)

Durian Guardian AI (Hapii Green) is a mobile-first, AI-driven diagnostics and farm management platform designed to help durian growers monitor tree health, detect foliage diseases, assess leaf sample photo quality, estimate risk factors, and access expert agronomy recommendations.

This repository contains both:
1. **Flutter Mobile Application**: A Riverpod-based mobile client with auto-provisioning diagnostics sheets, care timelines, and visual interpretability toggles.
2. **FastAPI Python Backend**: A high-performance REST API backend with a thread-safe in-memory model execution layer, automatic MongoDB persistence, and critical alerts dispatch.

---

## Technical Highlights
- **Multi-Stage AI Pipeline**: Executes validation and diagnosis sequentially in <180ms:
  - **Image Quality (Model 2)**: MobileNet-V3-Small + Laplacian blur + brightness heuristics.
  - **Disease Detection (Model 1)**: EfficientNet-B0 foliage classifier (11 classes).
  - **Risk Prediction (Model 3)**: Random Forest classifier calculating risk scoring.
  - **Recommendation (Model 4)**: Random Forest ensemble determining care priorities and inspection timelines.
- **Explainability**: Integrated Grad-CAM activations on target layer (`features.6`), generating Jet-color overlay images.
- **Clean Architecture**: Adheres to Layered boundaries (Data -> Domain -> Presentation) in both client and server codebases.
- **Robust Network Layer**: Automatic JWT access-refresh token handshake interceptors with on-device keychain encryption.

---

## Project Directory Map
```
dga_mobile/
├── backend/                  # FastAPI Python backend service
│   ├── app/
│   │   ├── ai/               # ModelManager, loaders, and inference pipelines
│   │   ├── api/              # Versioned endpoints (Auth, AI, Trees, etc.)
│   │   ├── core/             # JWT, exception filters, config parameters
│   │   ├── database/         # MongoDB motor client wrappers
│   │   └── models/           # ODM schemas
│   └── tests/                # Automated pytest suites
├── lib/                      # Flutter mobile client source code
│   ├── core/                 # Theme configs, exceptions, API configurations
│   ├── features/             # Feature domains (Auth, Dashboard, AI, etc.)
│   └── shared/               # Reusable UI widgets and layout modules
└── docs/                     # Comprehensive technical documentation guides
```
