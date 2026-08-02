"""
Index Definitions
=================

MongoDB index specifications for all 15 collections.
Optimized for production query patterns.
"""

from typing import Dict, Any, List

from database.db_schema import Collections


def get_index_specs() -> Dict[str, List[Dict[str, Any]]]:
    """Return index definitions for all collections."""
    return {
        Collections.COMPANIES: [
            {"keys": [("company_name", 1)], "name": "idx_companies_name", "unique": True},
            {"keys": [("company_code", 1)], "name": "idx_companies_code", "unique": True},
        ],
        Collections.FARMS: [
            {"keys": [("company_id", 1)], "name": "idx_farms_company_id"},
            {"keys": [("farm_name", 1)], "name": "idx_farms_name"},
            {"keys": [("farm_code", 1)], "name": "idx_farms_code", "unique": True},
            {"keys": [("owner_user_id", 1)], "name": "idx_farms_owner_id"},
            {"keys": [("district", 1)], "name": "idx_farms_district"},
        ],
        Collections.ZONES: [
            {"keys": [("farm_id", 1), ("zone_name", 1)], "name": "idx_zones_farm_zone", "unique": True},
        ],
        Collections.TREES: [
            {"keys": [("tree_code", 1)], "name": "idx_trees_code_unique", "unique": True},
            {"keys": [("farm_id", 1)], "name": "idx_trees_farm_id"},
            {"keys": [("zone_id", 1)], "name": "idx_trees_zone_id"},
            {"keys": [("status", 1)], "name": "idx_trees_status"},
            {"keys": [("variety", 1)], "name": "idx_trees_variety"},
        ],
        Collections.USERS: [
            {"keys": [("user_code", 1)], "name": "idx_users_code_unique", "unique": True},
            {"keys": [("role", 1)], "name": "idx_users_role"},
            {"keys": [("email", 1)], "name": "idx_users_email", "unique": True, "sparse": True},
        ],
        Collections.DISEASES: [
            {"keys": [("code", 1)], "name": "idx_diseases_code_unique", "unique": True},
        ],
        Collections.INSPECTIONS: [
            {"keys": [("tree_id", 1)], "name": "idx_inspections_tree_id"},
            {"keys": [("inspection_date", -1)], "name": "idx_inspections_date_desc"},
            {"keys": [("predicted_disease", 1)], "name": "idx_inspections_disease"},
            {"keys": [("health_status", 1)], "name": "idx_inspections_health"},
            {"keys": [("farm_id", 1)], "name": "idx_inspections_farm_id"},
            {"keys": [("confidence", -1)], "name": "idx_inspections_confidence_desc"},
        ],
        Collections.DETECTION_RESULTS: [
            {"keys": [("inspection_id", 1)], "name": "idx_detections_inspection_id"},
            {"keys": [("tree_id", 1)], "name": "idx_detections_tree_id"},
            {"keys": [("farm_id", 1)], "name": "idx_detections_farm_id"},
            {"keys": [("company_id", 1)], "name": "idx_detections_company_id"},
            {"keys": [("prediction", 1)], "name": "idx_detections_prediction"},
            {"keys": [("created_at", -1)], "name": "idx_detections_created_at"},
        ],
        Collections.DISEASE_HISTORY: [
            {"keys": [("tree_id", 1)], "name": "idx_disease_history_tree_id"},
            {"keys": [("farm_id", 1)], "name": "idx_disease_history_farm_id"},
            {"keys": [("company_id", 1)], "name": "idx_disease_history_company_id"},
            {"keys": [("disease", 1)], "name": "idx_disease_history_disease"},
            {"keys": [("date", -1)], "name": "idx_disease_history_date_desc"},
            {"keys": [("action", 1)], "name": "idx_disease_history_action"},
        ],
        Collections.ALERTS: [
            {"keys": [("created_at", -1)], "name": "idx_alerts_created_at"},
            {"keys": [("priority", 1)], "name": "idx_alerts_priority"},
            {"keys": [("farm_id", 1)], "name": "idx_alerts_farm_id"},
            {"keys": [("tree_id", 1)], "name": "idx_alerts_tree_id"},
            {"keys": [("company_id", 1)], "name": "idx_alerts_company_id"},
            {"keys": [("alert_type", 1)], "name": "idx_alerts_type"},
            {"keys": [("status", 1)], "name": "idx_alerts_status"},
            {"keys": [("is_read", 1), ("created_at", -1)], "name": "idx_alerts_unread"},
            {"keys": [("date", -1)], "name": "idx_alerts_date_desc"},
        ],
        Collections.SEASONS: [
            {"keys": [("farm_id", 1)], "name": "idx_seasons_farm_id"},
            {"keys": [("farm_id", 1), ("season_year", 1)], "name": "idx_seasons_farm_year"},
            {"keys": [("season_year", 1)], "name": "idx_seasons_year"},
            {"keys": [("status", 1)], "name": "idx_seasons_status"},
        ],
        Collections.HARVESTS: [
            {"keys": [("farm_id", 1)], "name": "idx_harvests_farm_id"},
            {"keys": [("season_id", 1)], "name": "idx_harvests_season_id"},
            {"keys": [("farm_id", 1), ("season_id", 1)], "name": "idx_harvests_farm_season"},
            {"keys": [("harvest_date", -1)], "name": "idx_harvests_date_desc"},
        ],
        Collections.FARM_TARGETS: [
            {"keys": [("farm_id", 1)], "name": "idx_targets_farm_id"},
            {"keys": [("season_id", 1)], "name": "idx_targets_season_id"},
            {"keys": [("farm_id", 1), ("season_id", 1)], "name": "idx_targets_farm_season"},
        ],
        Collections.FARM_PERFORMANCE: [
            {"keys": [("farm_id", 1)], "name": "idx_performance_farm_id"},
            {"keys": [("season_id", 1)], "name": "idx_performance_season_id"},
            {"keys": [("farm_id", 1), ("season_id", 1)], "name": "idx_performance_farm_season"},
            {"keys": [("overall_status", 1)], "name": "idx_performance_status"},
            {"keys": [("farm_score", -1)], "name": "idx_performance_score_desc"},
        ],
        Collections.NEIGHBOR_CONTACT_REQUESTS: [
            {"keys": [("request_code", 1)], "name": "idx_ncr_request_code", "unique": True},
            {"keys": [("source_farm_id", 1)], "name": "idx_ncr_source_farm"},
            {"keys": [("target_farm_id", 1)], "name": "idx_ncr_target_farm"},
            {"keys": [("source_user_id", 1)], "name": "idx_ncr_source_user"},
            {"keys": [("target_user_id", 1)], "name": "idx_ncr_target_user"},
            {"keys": [("inspection_id", 1)], "name": "idx_ncr_inspection"},
            {"keys": [("status", 1)], "name": "idx_ncr_status"},
            {"keys": [("created_at", -1)], "name": "idx_ncr_created_at"},
            {"keys": [("expires_at", 1)], "name": "idx_ncr_expires_at"},
        ],
        Collections.WEATHER_CACHE: [
            {"keys": [("farm_id", 1)], "name": "idx_weather_cache_farm_id"},
            {"keys": [("updated_at", -1)], "name": "idx_weather_cache_updated_at_desc"},
            {"keys": [("cache_expired_at", 1)], "name": "idx_weather_cache_cache_expired_at_ttl", "expireAfterSeconds": 86400},
        ],
    }
