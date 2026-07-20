# Changelog — Durian Guardian AI

## [1.0.0] — 2026-07-19
### Added
- Created PyTorch `ModelManager` weight cache singleton.
- Implemented multi-stage diagnostics pipeline (Quality -> Detection -> Risk -> Recommendation).
- Integrated Grad-CAM explainability visuals on target layer (`features.6`).
- Added database recommendation history persistence to MongoDB.
- Implemented stateful `ImagePreviewCard` in Flutter to support AI heatmap overlays.
- Created automated integration tests.
- Formulated technical project documentation guides.
