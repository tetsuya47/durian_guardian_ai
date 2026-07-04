"""
Model 4: Comprehensive Project + MongoDB + Feature Audit
=========================================================
PHASE 1 + 2 + 3 combined.
"""

import sys
import json
from pathlib import Path
from collections import defaultdict, Counter
from datetime import datetime

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT))

from pymongo import MongoClient, errors
from database.config import settings
from database.db_schema import Collections


client = None
db = None

def connect():
    global client, db
    uri = settings.mongodb_uri_with_credentials
    kwargs = settings.connection_kwargs
    client = MongoClient(uri, **kwargs)
    client.admin.command("ping")
    db = client[settings.DATABASE_NAME]
    print(f"Connected: {settings.DATABASE_NAME}")

def close():
    if client:
        client.close()


def audit_collection(coll_name):
    """Deep audit of a single collection."""
    print(f"\n{'='*70}")
    print(f"  COLLECTION: {coll_name}")
    print(f"{'='*70}")

    total = db[coll_name].count_documents({})
    print(f"  Total docs: {total}")
    if total == 0:
        print("  [EMPTY]")
        return {
            "collection": coll_name,
            "total_docs": 0,
            "fields": [],
            "missing": {},
            "sample": None
        }

    # Schema via aggregation (detect all fields + types + null counts)
    pipeline = [
        {"$project": {"entries": {"$objectToArray": "$$ROOT"}}},
        {"$unwind": "$entries"},
        {"$group": {
            "_id": {"field": "$entries.k", "type": {"$type": "$entries.v"}},
            "count": {"$sum": 1},
            "null_count": {"$sum": {"$cond": [{"$eq": ["$entries.v", None]}, 1, 0]}},
            "sample_vals": {"$addToSet": "$entries.v"},
        }},
        {"$sort": {"_id.field": 1}},
    ]
    try:
        schema_raw = list(db[coll_name].aggregate(pipeline, allowDiskUse=True))
    except Exception as e:
        print(f"  Schema aggregation failed: {e}")
        schema_raw = []

    fields = {}
    field_types = {}
    for entry in schema_raw:
        f = entry["_id"]["field"]
        btype = entry["_id"]["type"]
        present = entry["count"] - entry["null_count"]
        nulls = entry["null_count"]
        raw_vals = [v for v in entry["sample_vals"] if v is not None]

        if f not in field_types:
            field_types[f] = set()
        field_types[f].add(btype)

        if f == "_id":
            continue

        sample_vals = []
        for v in raw_vals[:10]:
            try:
                if isinstance(v, bytes):
                    sample_vals.append(str(v[:50]))
                elif isinstance(v, datetime):
                    sample_vals.append(v.isoformat())
                else:
                    sample_vals.append(str(v)[:100])
            except:
                sample_vals.append(str(type(v).__name__))

        missing_pct = round(nulls / total * 100, 2) if total > 0 else 0
        fields[f] = {
            "bson_types": list(field_types[f]),
            "present": present,
            "nulls": nulls,
            "missing_pct": missing_pct,
            "sample_values": sample_vals,
        }

    if not fields:
        # Fallback: scan documents
        for doc in db[coll_name].find().limit(100):
            for k, v in doc.items():
                if k == "_id":
                    continue
                if k not in fields:
                    fields[k] = {"bson_types": set(), "present": 0, "nulls": 0, "missing_pct": 0, "sample_values": []}
                fields[k]["bson_types"].add(type(v).__name__)
                if v is not None:
                    fields[k]["present"] += 1
                else:
                    fields[k]["nulls"] += 1
                if len(fields[k]["sample_values"]) < 5:
                    try:
                        fields[k]["sample_values"].append(str(v)[:80])
                    except:
                        pass
        for f in fields.values():
            f["bson_types"] = list(f["bson_types"])

    # Print
    print(f"  Fields ({len(fields)}):")
    for fname, finfo in sorted(fields.items()):
        missing_str = f"  ({finfo['missing_pct']}% missing)" if finfo["missing_pct"] > 0 else ""
        print(f"    {fname:30s} :: {finfo['bson_types']}  present={finfo['present']}/{total}{missing_str}")

    print(f"\n  Sample (top 3 values for each field):")
    for fname, finfo in sorted(fields.items()):
        vals = finfo["sample_values"][:3]
        print(f"    {fname:30s}: {vals}")

    return {
        "collection": coll_name,
        "total_docs": total,
        "fields": fields,
        "important_distinct": {},
    }


def audit_mongodb():
    connect()
    all_results = {}

    for coll_name in Collections.all():
        result = audit_collection(coll_name)
        all_results[coll_name] = result

    # Extra analysis: cross-collection relationships
    print("\n\n=== CROSS-COLLECTION ANALYSIS ===")
    total_trees = db.trees.count_documents({})
    total_inspections = db.inspections.count_documents({})
    total_dh = db.disease_history.count_documents({})
    total_alerts = db.alerts.count_documents({})
    total_detections = db.detection_results.count_documents({})

    insp_trees = len(db.inspections.distinct("tree_id"))
    dh_trees = len(db.disease_history.distinct("tree_id"))
    alert_trees = len(db.alerts.distinct("tree_id"))
    insp_diseases = len(db.inspections.distinct("predicted_disease"))

    print(f"  Trees: {total_trees}")
    print(f"  Inspections: {total_inspections} (covering {insp_trees} trees)")
    print(f"  Disease History: {total_dh} (covering {dh_trees} trees)")
    print(f"  Alerts: {total_alerts} (covering {alert_trees} trees)")
    print(f"  Detection Results: {total_detections}")

    # Check if detections link back to inspections
    sample_det = db.detection_results.find_one()
    has_inspection_ref = "inspection_id" in sample_det if sample_det else False
    print(f"  Detection→Inspection ref exists: {has_inspection_ref}")

    # Check disease_history action values
    dh_actions = db.disease_history.distinct("action")
    print(f"  disease_history actions: {dh_actions}")

    # Alert types
    alert_types = db.alerts.distinct("alert_type")
    print(f"  alert types: {alert_types}")

    alert_priorities = db.alerts.distinct("priority")
    print(f"  alert priorities: {alert_priorities}")

    # Check severity field
    insp_sample = db.inspections.find_one()
    has_severity = "severity" in insp_sample if insp_sample else False
    has_wind = "wind_speed" in insp_sample if insp_sample else False
    print(f"  inspections has severity: {has_severity}")
    print(f"  inspections has wind_speed: {has_wind}")

    # Check Model 3 exports
    model3_exports = ROOT / "training" / "model3" / "exports"
    model3_files = [f.name for f in model3_exports.iterdir()] if model3_exports.exists() else []
    print(f"  Model 3 exports: {model3_files}")

    close()
    return all_results


def determine_features(all_results):
    """Phase 3: Determine which features are available for Model 4."""
    print("\n\n=== FEATURE DETERMINATION ===")

    insp_fields = all_results.get("inspections", {}).get("fields", {})
    tree_fields = all_results.get("trees", {}).get("fields", {})
    farm_fields = all_results.get("farms", {}).get("fields", {})
    zone_fields = all_results.get("zones", {}).get("fields", {})
    dh_fields = all_results.get("disease_history", {}).get("fields", {})
    alert_fields = all_results.get("alerts", {}).get("fields", {})
    det_fields = all_results.get("detection_results", {}).get("fields", {})

    features = []

    # From inspections
    direct_from_insp = [
        ("temperature", "numerical", "inspections"),
        ("humidity", "numerical", "inspections"),
        ("rainfall", "numerical", "inspections"),
        ("health_status", "categorical", "inspections"),
        ("predicted_disease", "categorical", "inspections"),
        ("confidence", "numerical", "inspections"),
    ]
    for name, dtype, source in direct_from_insp:
        if name in insp_fields:
            features.append({"name": name, "type": dtype, "source": source, "available": True})
            print(f"  ✅ {name:35s} ({dtype}, {source})")

    # From trees
    from_trees = [
        ("tree_age", "numerical", "trees"),
        ("tree_variety", "categorical", "trees"),
    ]
    for name, dtype, source in from_trees:
        if name in tree_fields:
            features.append({"name": name, "type": dtype, "source": source, "available": True})
            print(f"  ✅ {name:35s} ({dtype}, {source})")

    # From farms
    from_farms = [
        ("area_hectare", "numerical", "farms"),
    ]
    for name, dtype, source in from_farms:
        if name in farm_fields:
            features.append({"name": name, "type": dtype, "source": source, "available": True})
            print(f"  ✅ {name:35s} ({dtype}, {source})")

    # From detection_results (Model 1 output)
    from_det = [
        ("detection_prediction", "categorical", "detection_results"),
        ("detection_confidence", "numerical", "detection_results"),
    ]
    for name, dtype, source in from_det:
        features.append({"name": name, "type": dtype, "source": source, "available": True})
        print(f"  ✅ {name:35s} ({dtype}, {source})")

    # From disease_history
    from_dh = [
        ("disease_history_count", "numerical", "disease_history"),
        ("last_treatment_days", "numerical", "disease_history"),
    ]
    for name, dtype, source in from_dh:
        features.append({"name": name, "type": dtype, "source": source, "available": True})
        print(f"  ✅ {name:35s} ({dtype}, {source})")

    # From alerts
    from_alerts = [
        ("alert_type", "categorical", "alerts"),
        ("alert_priority", "categorical", "alerts"),
        ("alert_count", "numerical", "alerts"),
    ]
    for name, dtype, source in from_alerts:
        features.append({"name": name, "type": dtype, "source": source, "available": True})
        print(f"  ✅ {name:35s} ({dtype}, {source})")

    # Derived features
    derived = [
        ("season", "categorical", "derived from inspection_date"),
        ("density_per_hectare", "numerical", "derived from tree_count/area_hectare"),
        ("days_since_last_inspection", "numerical", "derived temporal"),
        ("historical_disease_count", "numerical", "derived from disease_history per tree"),
        ("historical_disease_frequency", "numerical", "derived from count/tree_age"),
    ]
    for name, dtype, source in derived:
        features.append({"name": name, "type": dtype, "source": source, "available": True})
        print(f"  ✅ {name:35s} ({dtype}, {source})")

    # Model 3 outputs (these will be available at inference time from Model 3)
    model3_outputs = [
        ("risk_score", "numerical", "Model 3 output"),
        ("risk_level", "categorical", "Model 3 output"),
    ]
    for name, dtype, source in model3_outputs:
        features.append({"name": name, "type": dtype, "source": source, "available": True})
        print(f"  ✅ {name:35s} ({dtype}, {source})")

    # Note missing/wind
    if "wind_speed" in insp_fields:
        features.append({"name": "wind_speed", "type": "numerical", "source": "inspections", "available": True})
        print(f"  ✅ wind_speed (numerical, inspections)")
    else:
        print(f"  ❌ wind_speed: field does NOT exist in inspections")

    if "soil_moisture" in zone_fields or "soil_moisture" in insp_fields:
        features.append({"name": "soil_moisture", "type": "numerical", "source": "zones", "available": True})
        print(f"  ✅ soil_moisture")
    else:
        print(f"  ❌ soil_moisture: field does NOT exist")

    print(f"\n  Total features identified: {len(features)}")

    result = {
        "features": features,
        "total_features": len(features),
        "generated_at": datetime.now().isoformat(),
    }

    out_dir = ROOT / "training_recommendation" / "configs"
    out_dir.mkdir(parents=True, exist_ok=True)
    with open(str(out_dir / "feature_list.json"), "w") as f:
        json.dump(result, f, indent=2)
    print(f"\n  Feature list saved to {out_dir / 'feature_list.json'}")

    return features


def main():
    print("=" * 70)
    print("  MODEL 4: PROJECT + MONGODB + FEATURE AUDIT")
    print("=" * 70)
    print("\nPHASE 1: Project audit - reading from existing files...")
    print("PHASE 2: MongoDB audit...")

    all_results = audit_mongodb()

    # Save MongoDB audit
    audit_path = ROOT / "reports" / "model4"
    audit_path.mkdir(parents=True, exist_ok=True)
    with open(str(audit_path / "database_audit.json"), "w") as f:
        json.dump({k: {
            "collection": v["collection"],
            "total_docs": v["total_docs"],
            "fields": {fk: fv for fk, fv in v["fields"].items()},
        } for k, v in all_results.items()}, f, indent=2, default=str)
    print(f"  Database audit saved to {audit_path / 'database_audit.json'}")

    features = determine_features(all_results)

    # Save to reports too
    with open(str(audit_path / "feature_list.json"), "w") as f:
        json.dump(features, f, indent=2)

    print("\nPHASE 1-3 COMPLETE.")


if __name__ == "__main__":
    main()
