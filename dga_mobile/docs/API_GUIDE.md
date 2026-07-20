# API Documentation — Durian Guardian AI

This document provides a guide to the backend endpoints.

## 1. Authentication
- **POST `/api/v1/auth/register`**: Registers a new user.
- **POST `/api/v1/auth/login`**: Authenticates credentials and issues access & refresh tokens.
- **POST `/api/v1/auth/refresh`**: Exchanges a refresh token for a new access token.

## 2. Diagnosis Pipeline (AI)
- **POST `/api/v1/ai/detect`**:
  - Form parameters: `tree_id` (str), File payload: `file` (multipart/form-data).
  - Returns the unified pipeline JSON payload containing image quality checks, classification indices, Grad-CAM heatmap paths, risk scores, and agronomist recommendations.
- **POST `/api/v1/ai/image-quality`**:
  - File payload: `file` (multipart/form-data).
  - Returns a quality validation check status (`blur`, `brightness`, `passed`).

## 3. History Retrieval
- **GET `/api/v1/history/{tree_id}`**: Retrieves chronological disease history list logs and generated recommendations for a specific tree.
