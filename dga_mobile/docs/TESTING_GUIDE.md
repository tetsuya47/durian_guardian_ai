# Testing Guide

This document describes how to execute automated test suites.

## Running Backend Integration Tests
FastAPI integration tests are powered by `pytest`.

```bash
cd backend
python -m pytest
```

The test suites verify:
- User authentication and registration.
- ModelManager initialization and model memory cache states.
- E2E diagnostics pipeline requests with both valid and invalid image files.
- MongoDB persistence and automatic alert dispatch thresholds.
