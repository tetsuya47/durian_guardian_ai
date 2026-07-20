# Developer Guide

## Coding Standards
- **Python**: PEP-8 compliant. Use type annotations on functions and models. Keep asynchronous database operations isolated inside services.
- **Dart/Flutter**: Avoid inline business calculations in widgets. Leverage Riverpod providers to govern view states. Make widgets stateless when possible.

## Adding a New AI Model
1. Place model files in a subdirectory inside `backend/app/ai/models/`.
2. Add weight loading pathways inside `app/ai/model_manager.py`.
3. Create an inference wrapper module inside `app/ai/infer/`.
4. Register the step execution in the `AIService` pipeline.
