# Admin & Operator Guide

This guide details dashboard widgets and notification setup.

## 1. User Account Controls
- Register new agronomist and technician accounts under `POST /api/v1/auth/register`.
- Assign role classifications: `Technician` or `EnterpriseAdmin`.

## 2. Managing System Alerts
- Alerts are generated automatically if a diagnostic scan results in **`Critical`** priority recommendations.
- Administrators can view active alerts on the dashboard to coordinate emergency treatment.
