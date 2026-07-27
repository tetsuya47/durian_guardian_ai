#!/usr/bin/env py -3
"""
MongoDB Data Migration: English → Vietnamese
=============================================
Connects to MongoDB and updates ALL existing documents
to replace English values with Vietnamese translations.

NO schema changes. NO seed file changes. ONLY document updates.
"""

from pymongo import MongoClient
from typing import Dict
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

# ── Config ───────────────────────────────────────────────────────────
MONGO_URI = "mongodb://localhost:27017"
DB_NAME = "durian_guardian_ai"

# ── Translation Mappings ─────────────────────────────────────────────

DISEASE_NAME_MAP: Dict[str, str] = {
    "Healthy": "Khỏe mạnh",
    "Anthracnose": "Thán thư",
    "Canker": "Sẹo thân",
    "Fruit Rot": "Thối quả",
    "Mealybug": "Rệp sáp",
    "Pink Disease": "Bệnh hồng thân",
    "Sooty Mold": "Nấm bồ hóng",
    "Stem Blight": "Cháy thân",
    "Stem Cracking Gummosis": "Nứt thân chảy nhựa",
    "Thrips": "Bọ trĩ",
    "Yellow Leaf": "Vàng lá",
    "Leaf Blight": "Cháy lá",
    "Leaf Spot": "Đốm lá",
    "Stem Rot": "Thối thân",
    "Root Rot": "Thối rễ",
    "Powdery Mildew": "Bệnh phấn trắng",
    "Rust": "Bệnh gỉ sắt",
    "Downy Mildew": "Bệnh sương mai",
    "Phytophthora": "Bệnh thối rễ Phytophthora",
}

HEALTH_STATUS_MAP: Dict[str, str] = {
    "Healthy": "Khỏe mạnh",
    "Diseased": "Bị bệnh",
    "Monitoring": "Đang theo dõi",
    "Recovered": "Đã phục hồi",
    "Critical": "Nguy hiểm",
}

TREE_STATUS_MAP: Dict[str, str] = {
    "Healthy": "Khỏe mạnh",
    "Diseased": "Bị bệnh",
    "Monitoring": "Đang theo dõi",
}

RISK_LEVEL_MAP: Dict[str, str] = {
    "Low": "Thấp",
    "Medium": "Trung bình",
    "High": "Cao",
    "Critical": "Rất cao",
}

SEVERITY_MAP: Dict[str, str] = {
    "Very Low": "Rất nhẹ",
    "Low": "Nhẹ",
    "Medium": "Trung bình",
    "High": "Nặng",
    "Critical": "Rất nặng",
}

ALERT_TYPE_MAP: Dict[str, str] = {
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

ACTION_MAP: Dict[str, str] = {
    "Treatment Applied": "Đã điều trị",
    "Treatment Scheduled": "Đã lên lịch điều trị",
    "Observation": "Theo dõi",
    "Recovered": "Đã phục hồi",
}

ALERT_STATUS_MAP: Dict[str, str] = {
    "unread": "chưa đọc",
    "read": "đã đọc",
    "archived": "đã lưu trữ",
}


# ── Helpers ──────────────────────────────────────────────────────────

total_matched = 0
total_modified = 0


def run_update(collection, field: str, mapping: Dict[str, str], label: str = "") -> None:
    """Run update_many for each value in the mapping on a specific field."""
    global total_matched, total_modified
    for en_val, vi_val in mapping.items():
        result: UpdateResult = collection.update_many(
            {field: en_val},
            {"$set": {field: vi_val}},
        )
        if result.modified_count > 0:
            print(f"  [{label}] {field}: '{en_val}' -> '{vi_val}' | matched={result.matched_count} modified={result.modified_count}")
            total_matched += result.matched_count
            total_modified += result.modified_count


def run_regex_replace(collection, field: str, en_val: str, vi_val: str, label: str = "") -> None:
    """Replace English substring within a field using $replaceAll."""
    global total_matched, total_modified
    result = collection.update_many(
        {field: {"$regex": en_val, "$options": "i"}},
        [{"$set": {field: {"$replaceAll": {"input": f"${field}", "find": en_val, "replacement": vi_val}}}}],
    )
    if result.modified_count > 0:
        print(f"  [{label}] {field}: regex '{en_val}' -> '{vi_val}' | matched={result.matched_count} modified={result.modified_count}")
        total_matched += result.matched_count
        total_modified += result.modified_count


# ── Migration Functions ──────────────────────────────────────────────

def migrate_diseases(db) -> None:
    print("\n>>> MIGRATE: diseases")
    coll = db.diseases
    run_update(coll, "name", DISEASE_NAME_MAP, "diseases")

    for en_sev, vi_sev in SEVERITY_MAP.items():
        run_regex_replace(coll, "severity", en_sev, vi_sev, "diseases")


def migrate_trees(db) -> None:
    print("\n>>> MIGRATE: trees")
    coll = db.trees
    run_update(coll, "status", TREE_STATUS_MAP, "trees")


def migrate_inspections(db) -> None:
    print("\n>>> MIGRATE: inspections")
    coll = db.inspections
    run_update(coll, "health_status", HEALTH_STATUS_MAP, "inspections")
    run_update(coll, "predicted_disease", DISEASE_NAME_MAP, "inspections")


def migrate_detection_results(db) -> None:
    print("\n>>> MIGRATE: detection_results")
    coll = db.detection_results
    run_update(coll, "prediction", DISEASE_NAME_MAP, "detection_results")


def migrate_disease_history(db) -> None:
    print("\n>>> MIGRATE: disease_history")
    coll = db.disease_history
    run_update(coll, "disease", DISEASE_NAME_MAP, "disease_history")
    run_update(coll, "action", ACTION_MAP, "disease_history")


def migrate_alerts(db) -> None:
    print("\n>>> MIGRATE: alerts")
    coll = db.alerts
    run_update(coll, "alert_type", ALERT_TYPE_MAP, "alerts")
    run_update(coll, "priority", RISK_LEVEL_MAP, "alerts")
    run_update(coll, "status", ALERT_STATUS_MAP, "alerts")

    alert_level_map = {"Low": "Thấp", "Medium": "Trung bình", "High": "Cao", "Critical": "Rất cao"}
    run_update(coll, "alert_level", alert_level_map, "alerts")

    # Translate disease names inside alert titles and messages
    for en_disease, vi_disease in DISEASE_NAME_MAP.items():
        run_regex_replace(coll, "title", en_disease, vi_disease, "alerts")
        run_regex_replace(coll, "message", en_disease, vi_disease, "alerts")

    # Translate alert type names inside titles
    for en_type, vi_type in ALERT_TYPE_MAP.items():
        run_regex_replace(coll, "title", en_type, vi_type, "alerts")


# ── Verification ─────────────────────────────────────────────────────

def show_current_state(db) -> None:
    print("\n=== CURRENT DATA (findOne) ===")

    print("\n--- diseases ---")
    d = db.diseases.find_one()
    if d:
        print(f"  name: {d.get('name')}")
        print(f"  code: {d.get('code')}")

    print("\n--- trees ---")
    t = db.trees.find_one()
    if t:
        print(f"  tree_code: {t.get('tree_code')}")
        print(f"  variety: {t.get('variety')}")
        print(f"  status: {t.get('status')}")

    print("\n--- inspections ---")
    i = db.inspections.find_one()
    if i:
        print(f"  inspection_code: {i.get('inspection_code')}")
        print(f"  predicted_disease: {i.get('predicted_disease')}")
        print(f"  health_status: {i.get('health_status')}")

    print("\n--- detection_results ---")
    dr = db.detection_results.find_one()
    if dr:
        print(f"  model: {dr.get('model')}")
        print(f"  prediction: {dr.get('prediction')}")
        print(f"  confidence: {dr.get('confidence')}")

    print("\n--- disease_history ---")
    dh = db.disease_history.find_one()
    if dh:
        print(f"  disease: {dh.get('disease')}")
        print(f"  action: {dh.get('action')}")

    print("\n--- alerts ---")
    a = db.alerts.find_one()
    if a:
        print(f"  alert_type: {a.get('alert_type')}")
        print(f"  priority: {a.get('priority')}")
        print(f"  title: {a.get('title', 'N/A')}")
        msg = str(a.get("message", "N/A"))
        print(f"  message: {msg[:100]}...")


def verify_remaining_english(db) -> None:
    print("\n=== REMAINING ENGLISH SEARCH ===")

    english_keywords = [
        "Healthy", "Diseased", "Monitoring",
        "Anthracnose", "Canker", "Fruit Rot", "Mealybug",
        "Pink Disease", "Sooty Mold", "Stem Blight",
        "Stem Cracking Gummosis", "Thrips", "Yellow Leaf",
        "Leaf Blight", "Leaf Spot", "Stem Rot", "Root Rot",
        "Powdery Mildew", "Rust", "Downy Mildew",
        "Treatment Applied", "Treatment Scheduled", "Observation",
        "High Disease Risk", "Severe Disease",
        "Repeated Infection", "New Infection",
        "Treatment Reminder", "Inspection Reminder",
        "AI Confidence Low", "Farm Risk Warning",
    ]

    # Fields to search in each collection
    search_fields = {
        "diseases": ["name", "description", "recommendation", "severity"],
        "trees": ["status", "variety"],
        "inspections": ["predicted_disease", "health_status"],
        "detection_results": ["prediction"],
        "disease_history": ["disease", "action"],
        "alerts": ["alert_type", "priority", "title", "message", "recommendation", "status"],
    }

    total_remaining = 0
    for coll_name, fields in search_fields.items():
        for keyword in english_keywords:
            for field in fields:
                count = db[coll_name].count_documents({field: keyword})
                if count > 0:
                    print(f"  {coll_name}.{field}: '{keyword}' => {count} docs")
                    total_remaining += count

    # Also check for mixed content via regex
    print("\n--- Regex scan for remaining English words ---")
    regex_keywords = ["Healthy", "Diseased", "Monitoring", "Anthracnose", "Leaf Spot", "Stem Rot", "Fruit Rot", "Root Rot", "Treatment Applied", "High", "Medium", "Critical"]
    for coll_name, fields in search_fields.items():
        for field in fields:
            for kw in regex_keywords:
                count = db[coll_name].count_documents({field: {"$regex": f"\\b{kw}\\b", "$options": "i"}})
                if count > 0:
                    print(f"  {coll_name}.{field}: regex '{kw}' => {count} docs")
                    total_remaining += count

    print(f"\n  TOTAL remaining English values found: {total_remaining}")


# ── Main ─────────────────────────────────────────────────────────────

def main() -> None:
    global total_matched, total_modified

    print("=" * 60)
    print("  MongoDB Data Migration: English -> Vietnamese")
    print("=" * 60)

    # ── Step 1: Connect ──────────────────────────────────────────────
    print("\n>>> STEP 1: CONNECT TO DATABASE")
    client = MongoClient(MONGO_URI, serverSelectionTimeoutMS=5000)
    try:
        client.admin.command("ping")
        print(f"  Connected to: {MONGO_URI}")
    except Exception as e:
        print(f"  ERROR: Cannot connect to MongoDB: {e}")
        sys.exit(1)

    db = client[DB_NAME]
    print(f"  Database: {DB_NAME}")
    print("\n  Collections:")
    for c in sorted(db.list_collection_names()):
        count = db[c].count_documents({})
        print(f"    {c}: {count} docs")

    # ── Step 2: Show current data ────────────────────────────────────
    print("\n>>> STEP 2: SHOW CURRENT DATA")
    show_current_state(db)

    # ── Step 3: Execute updateMany ───────────────────────────────────
    print("\n>>> STEP 3: EXECUTE updateMany()")
    total_matched = 0
    total_modified = 0

    migrate_diseases(db)
    migrate_trees(db)
    migrate_inspections(db)
    migrate_detection_results(db)
    migrate_disease_history(db)
    migrate_alerts(db)

    print(f"\n{'=' * 60}")
    print(f"  TOTAL: matched={total_matched}  modified={total_modified}")
    print(f"{'=' * 60}")

    if total_modified == 0:
        print("\n  WARNING: modifiedCount == 0. No documents were updated.")
        print("  This may mean the data is already in Vietnamese,")
        print("  or the English values don't match the mapping.")
        print("  Check the verify step below.")
        client.close()
        return

    # ── Step 4: Print results ────────────────────────────────────────
    print("\n>>> STEP 4: DATABASE RESULTS (document counts after migration)")
    for c in sorted(db.list_collection_names()):
        count = db[c].count_documents({})
        print(f"  {c}: {count} docs")

    # ── Step 5: Verify data ──────────────────────────────────────────
    print("\n>>> STEP 5: VERIFY DATA (findOne AFTER migration)")
    show_current_state(db)

    # ── Step 6: Search for remaining English ──────────────────────────
    print("\n>>> STEP 6: SEARCH FOR REMAINING ENGLISH")
    verify_remaining_english(db)

    # ── Step 8: Final summary ────────────────────────────────────────
    print("\n>>> FINAL SUMMARY")
    print(f"  Documents matched:  {total_matched}")
    print(f"  Documents modified: {total_modified}")
    print(f"  Migration status:   {'SUCCESS' if total_modified > 0 else 'NO CHANGES'}")
    print(f"  MongoDB Compass should now display Vietnamese values.")

    client.close()
    print("\n  MongoDB connection closed.")


if __name__ == "__main__":
    main()
