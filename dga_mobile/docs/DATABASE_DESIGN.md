# Database Design — MongoDB Schema

This document details the MongoDB Atlas collection mapping, fields, and indexing guidelines.

## Collections Profile

### 1. `users`
- Tracks farm technician profiles and system roles.
- **Fields**: `full_name`, `email`, `password_hash`, `role`, `created_at`, `updated_at`.
- **Index**: Unique index on `email` to prevent duplicate user registrations.

### 2. `farms`
- Represents durian plantation zones.
- **Fields**: `farm_name`, `area`, `location`, `owner_id`, `created_at`, `updated_at`.

### 3. `zones`
- Sub-compartments within a farm.
- **Fields**: `zone_name`, `zone_code`, `farm_id`, `tree_count`, `created_at`, `updated_at`.

### 4. `trees`
- Individual durian trees tracked by code.
- **Fields**: `tree_code`, `variety`, `tree_age`, `status`, `zone_id`, `created_at`, `updated_at`.

### 5. `disease_history`
- Log records of diagnostic pipeline outcomes (historical library).
- **Fields**: `tree_id`, `disease_name`, `confidence`, `severity`, `image_url`, `risk_level`, `risk_probability`, `recommendation`, `priority`, `urgency_score`, `estimated_loss`, `next_inspection_date`, `inference_time_ms`, `processing_time_ms`, `model_version`, `heatmap_url`, `overlay_url`, `created_at`, `updated_at`.

### 6. `alerts`
- High-priority operational events.
- **Fields**: `farm_id`, `tree_id`, `alert_type`, `priority`, `date`, `created_at`, `updated_at`.
