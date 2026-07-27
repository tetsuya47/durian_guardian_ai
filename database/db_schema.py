"""
Schema Definitions
==================

Collection names, JSON Schema validators, and type hints
for all 10 MongoDB collections in Durian Guardian AI.

Validators match the EXACT document structure produced
by the Excel ETL pipeline — never reject valid data.
"""

from typing import Dict, Any, List


class Collections:
    """Central registry of all collection names."""

    COMPANIES: str = "companies"
    FARMS: str = "farms"
    ZONES: str = "zones"
    TREES: str = "trees"
    USERS: str = "users"
    DISEASES: str = "diseases"
    INSPECTIONS: str = "inspections"
    DETECTION_RESULTS: str = "detection_results"
    DISEASE_HISTORY: str = "disease_history"
    ALERTS: str = "alerts"

    @classmethod
    def all(cls) -> List[str]:
        return [
            cls.COMPANIES, cls.FARMS, cls.ZONES, cls.TREES,
            cls.USERS, cls.DISEASES, cls.INSPECTIONS,
            cls.DETECTION_RESULTS, cls.DISEASE_HISTORY, cls.ALERTS,
        ]

    @classmethod
    def seed_collections(cls) -> List[str]:
        """Collections that receive seed data from Excel."""
        return [
            cls.COMPANIES, cls.FARMS, cls.ZONES, cls.TREES,
            cls.USERS, cls.DISEASES, cls.INSPECTIONS,
            cls.DETECTION_RESULTS, cls.DISEASE_HISTORY, cls.ALERTS,
        ]


# ── Vietnamese Localization ──────────────────────────────────────────

HEALTH_STATUS_VI: Dict[str, str] = {
    "Healthy": "Khỏe mạnh",
    "Diseased": "Bị bệnh",
    "Monitoring": "Đang theo dõi",
}

TREE_STATUS_VI: Dict[str, str] = {
    "Healthy": "Khỏe mạnh",
    "Diseased": "Bị bệnh",
    "Monitoring": "Đang theo dõi",
}

SEVERITY_VI: Dict[str, str] = {
    "Very Low": "Rất nhẹ",
    "Low": "Nhẹ",
    "Medium": "Trung bình",
    "High": "Nặng",
    "Critical": "Rất nặng",
}

RISK_LEVEL_VI: Dict[str, str] = {
    "Low": "Thấp",
    "Medium": "Trung bình",
    "High": "Cao",
    "Critical": "Rất cao",
}

ALERT_TYPE_VI: Dict[str, str] = {
    "High Disease Risk": "Nguy cơ mắc bệnh cao",
    "Severe Disease": "Bệnh nghiêm trọng",
    "Rapid Disease Progression": "Bệnh tiến triển nhanh",
    "Repeated Infection": "Tái nhiễm bệnh",
    "New Infection": "Phát hiện bệnh mới",
    "Treatment Reminder": "Nhắc nhở điều trị",
    "Inspection Reminder": "Nhắc kiểm tra",
    "AI Confidence Low": "Độ tin cậy AI thấp",
    "Farm Risk Warning": "Cảnh báo rủi ro trang trại",
}

ALERT_STATUS_VI: Dict[str, str] = {
    "unread": "chưa đọc",
    "read": "đã đọc",
    "archived": "đã lưu trữ",
}

ACTION_VI: Dict[str, str] = {
    "Treatment Applied": "Đã điều trị",
    "Treatment Scheduled": "Đã lên lịch điều trị",
    "Observation": "Theo dõi",
    "Recovered": "Đã phục hồi",
}


def get_collection_validators() -> Dict[str, Dict[str, Any]]:
    """Return MongoDB JSON Schema validators for all collections."""
    return {
        Collections.COMPANIES: {
            "$jsonSchema": {
                "bsonType": "object",
                "title": "Company Validation",
                "required": ["company_code", "company_name", "district", "province"],
                "properties": {
                    "_id": {"bsonType": "objectId"},
                    "company_code": {"bsonType": "string", "description": "COMP001-COMP010"},
                    "company_name": {"bsonType": "string", "description": "Company legal name"},
                    "owner": {"bsonType": ["string", "null"]},
                    "phone": {"bsonType": ["string", "null"]},
                    "email": {"bsonType": ["string", "null"]},
                    "district": {"bsonType": "string", "description": "District location"},
                    "province": {"bsonType": "string", "description": "All in Dak Lak"},
                    "created_at": {"bsonType": "date"},
                },
            }
        },
        Collections.FARMS: {
            "$jsonSchema": {
                "bsonType": "object",
                "title": "Farm Validation",
                "required": ["farm_code", "farm_name", "company_id", "district"],
                "properties": {
                    "_id": {"bsonType": "objectId"},
                    "farm_code": {"bsonType": "string", "description": "FARM001-FARM010"},
                    "farm_name": {"bsonType": "string", "description": "Farm display name"},
                    "company_id": {"bsonType": "objectId", "description": "Ref companies._id"},
                    "owner_user_id": {"bsonType": ["objectId", "null"], "description": "Ref users._id (Farm Owner)"},
                    "manager_user_id": {"bsonType": ["objectId", "null"], "description": "Ref users._id (Company Manager)"},
                    "owner": {"bsonType": ["string", "null"]},
                    "phone": {"bsonType": ["string", "null"]},
                    "district": {"bsonType": "string", "description": "District location"},
                    "commune": {"bsonType": ["string", "null"]},
                    "latitude": {"bsonType": ["double", "null"]},
                    "longitude": {"bsonType": ["double", "null"]},
                    "area_hectare": {"bsonType": "double", "minimum": 0},
                    "tree_count": {"bsonType": "int", "minimum": 0},
                    "created_at": {"bsonType": "date"},
                },
            }
        },
        Collections.ZONES: {
            "$jsonSchema": {
                "bsonType": "object",
                "title": "Zone Validation",
                "required": ["farm_id", "zone_name", "tree_count"],
                "properties": {
                    "_id": {"bsonType": "objectId"},
                    "zone_code": {"bsonType": "string"},
                    "farm_id": {"bsonType": "objectId", "description": "Ref farms._id"},
                    "zone_name": {"bsonType": "string", "description": "ZONE_A to ZONE_J"},
                    "soil_type": {"bsonType": ["string", "null"]},
                    "irrigation": {"bsonType": ["string", "null"]},
                    "tree_count": {"bsonType": "int", "minimum": 0},
                    "created_at": {"bsonType": "date"},
                },
            }
        },
        Collections.TREES: {
            "$jsonSchema": {
                "bsonType": "object",
                "title": "Tree Validation",
                "required": ["tree_code", "farm_id", "zone_id", "variety", "planting_date", "tree_age", "status"],
                "properties": {
                    "_id": {"bsonType": "objectId"},
                    "tree_code": {"bsonType": "string", "description": "Unique tree ID (TREE00001+)"},
                    "farm_id": {"bsonType": "objectId", "description": "Ref farms._id"},
                    "zone_id": {"bsonType": "objectId", "description": "Ref zones._id"},
                    "variety": {"bsonType": "string", "description": "Monthong/Dona/Musang King/Ri6"},
                    "planting_date": {"bsonType": "date"},
                    "tree_age": {"bsonType": "int", "minimum": 0},
                    "status": {"enum": list(TREE_STATUS_VI.values())},
                    "latitude": {"bsonType": ["double", "null"]},
                    "longitude": {"bsonType": ["double", "null"]},
                    "last_inspection": {"bsonType": ["date", "null"]},
                    "qr_code": {"bsonType": ["string", "null"]},
                    "created_at": {"bsonType": "date"},
                },
            }
        },
        Collections.USERS: {
            "$jsonSchema": {
                "bsonType": "object",
                "title": "User Validation",
                "required": ["user_code", "full_name", "role"],
                "properties": {
                    "_id": {"bsonType": "objectId"},
                    "user_code": {"bsonType": "string", "description": "USR001-USR050"},
                    "full_name": {"bsonType": "string"},
                    "role": {"enum": ["Admin", "Company Manager", "Farm Manager", "Farm Owner", "Inspector", "Technician"]},
                    "email": {"bsonType": ["string", "null"]},
                    "password_hash": {"bsonType": ["string", "null"]},
                    "refresh_token": {"bsonType": ["string", "null"]},
                    "created_at": {"bsonType": "date"},
                    "updated_at": {"bsonType": ["date", "null"]},
                },
            }
        },
        Collections.DISEASES: {
            "$jsonSchema": {
                "bsonType": "object",
                "title": "Disease Validation",
                "required": ["code", "name"],
                "properties": {
                    "_id": {"bsonType": "objectId"},
                    "code": {"bsonType": "string", "description": "Normalized code from name"},
                    "name": {"bsonType": "string", "description": "Disease display name (Vietnamese)"},
                    "affected_part": {"bsonType": ["string", "null"]},
                    "severity": {"bsonType": ["string", "null"]},
                    "description": {"bsonType": ["string", "null"]},
                    "recommendation": {"bsonType": ["string", "null"]},
                    "created_at": {"bsonType": "date"},
                },
            }
        },
        Collections.INSPECTIONS: {
            "$jsonSchema": {
                "bsonType": "object",
                "title": "Inspection Validation",
                "required": [
                    "inspection_code", "tree_id", "farm_id",
                    "inspection_date", "health_status",
                    "predicted_disease", "confidence",
                ],
                "properties": {
                    "_id": {"bsonType": "objectId"},
                    "inspection_code": {"bsonType": "string"},
                    "tree_id": {"bsonType": "objectId", "description": "Ref trees._id"},
                    "farm_id": {"bsonType": "objectId", "description": "Ref farms._id"},
                    "zone_id": {"bsonType": ["objectId", "null"]},
                    "disease_id": {"bsonType": ["objectId", "null"], "description": "Ref diseases._id"},
                    "inspection_date": {"bsonType": "date"},
                    "temperature": {"bsonType": "double"},
                    "humidity": {"bsonType": "double"},
                    "rainfall_mm": {"bsonType": "double", "minimum": 0},
                    "wind_speed": {"bsonType": ["double", "null"]},
                    "health_status": {"enum": list(HEALTH_STATUS_VI.values())},
                    "predicted_disease": {"bsonType": "string", "description": "Vietnamese disease name"},
                    "confidence": {"bsonType": "double", "minimum": 0, "maximum": 100},
                    "severity": {"bsonType": ["string", "null"]},
                    "remark": {"bsonType": ["string", "null"]},
                    "created_at": {"bsonType": "date"},
                },
            }
        },
        Collections.DETECTION_RESULTS: {
            "$jsonSchema": {
                "bsonType": "object",
                "title": "Detection Result Validation",
                "required": ["inspection_id", "model", "prediction", "confidence"],
                "properties": {
                    "_id": {"bsonType": "objectId"},
                    "detection_code": {"bsonType": ["string", "null"]},
                    "inspection_id": {"bsonType": "objectId", "description": "Ref inspections._id"},
                    "tree_id": {"bsonType": ["objectId", "null"], "description": "Ref trees._id"},
                    "farm_id": {"bsonType": ["objectId", "null"], "description": "Ref farms._id"},
                    "company_id": {"bsonType": ["objectId", "null"], "description": "Ref companies._id"},
                    "model": {"bsonType": "string"},
                    "prediction": {"bsonType": "string", "description": "Vietnamese disease name"},
                    "confidence": {"bsonType": "double", "minimum": 0, "maximum": 100},
                    "image_path": {"bsonType": ["string", "null"]},
                    "image_quality": {"bsonType": ["string", "null"]},
                    "model_version": {"bsonType": ["string", "null"]},
                    "processing_time_ms": {"bsonType": ["double", "null"]},
                    "recommendation": {"bsonType": ["string", "null"]},
                    "lat": {"bsonType": ["double", "null"]},
                    "lon": {"bsonType": ["double", "null"]},
                    "captured_at": {"bsonType": ["date", "null"]},
                    "updated_at": {"bsonType": ["date", "null"]},
                    "created_at": {"bsonType": "date"},
                },
            }
        },
        Collections.DISEASE_HISTORY: {
            "$jsonSchema": {
                "bsonType": "object",
                "title": "Disease History Validation",
                "required": ["tree_id", "disease", "date", "action"],
                "properties": {
                    "_id": {"bsonType": "objectId"},
                    "tree_id": {"bsonType": "objectId", "description": "Ref trees._id"},
                    "farm_id": {"bsonType": ["objectId", "null"]},
                    "company_id": {"bsonType": ["objectId", "null"]},
                    "disease": {"bsonType": "string", "description": "Vietnamese disease name"},
                    "date": {"bsonType": "date"},
                    "action": {"bsonType": "string", "description": "Vietnamese action name"},
                    "severity": {"bsonType": ["string", "null"]},
                    "symptoms": {"bsonType": ["string", "null"]},
                    "diagnosis_method": {"bsonType": ["string", "null"]},
                    "detected_by_user_id": {"bsonType": ["objectId", "null"]},
                    "detection_result_id": {"bsonType": ["objectId", "null"]},
                    "resolved_at": {"bsonType": ["date", "null"]},
                    "resolution_notes": {"bsonType": ["string", "null"]},
                    "updated_at": {"bsonType": ["date", "null"]},
                    "created_at": {"bsonType": "date"},
                },
            }
        },
        Collections.ALERTS: {
            "$jsonSchema": {
                "bsonType": "object",
                "title": "Alert Validation",
                "required": ["farm_id", "tree_id", "alert_type", "priority", "date"],
                "properties": {
                    "_id": {"bsonType": "objectId"},
                    "alert_code": {"bsonType": ["string", "null"]},
                    "farm_id": {"bsonType": "objectId", "description": "Ref farms._id"},
                    "tree_id": {"bsonType": "objectId", "description": "Ref trees._id"},
                    "company_id": {"bsonType": ["objectId", "null"]},
                    "inspection_id": {"bsonType": ["objectId", "null"]},
                    "detection_result_id": {"bsonType": ["objectId", "null"]},
                    "disease_history_id": {"bsonType": ["objectId", "null"]},
                    "disease_id": {"bsonType": ["objectId", "null"]},
                    "alert_type": {"bsonType": "string", "description": "Vietnamese alert type"},
                    "alert_level": {"bsonType": ["string", "null"]},
                    "title": {"bsonType": ["string", "null"]},
                    "message": {"bsonType": ["string", "null"]},
                    "recommendation": {"bsonType": ["string", "null"]},
                    "priority": {"bsonType": "string", "description": "Vietnamese risk level"},
                    "status": {"bsonType": ["string", "null"]},
                    "is_read": {"bsonType": ["bool", "null"]},
                    "acknowledged_by": {"bsonType": ["objectId", "null"]},
                    "acknowledged_at": {"bsonType": ["date", "null"]},
                    "date": {"bsonType": "date"},
                    "updated_at": {"bsonType": ["date", "null"]},
                    "created_at": {"bsonType": "date"},
                },
            }
        },
    }
