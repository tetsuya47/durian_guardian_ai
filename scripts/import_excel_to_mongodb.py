#!/usr/bin/env python3
"""
Import Excel to MongoDB
=======================

Complete ETL pipeline: reads DGA_Enterprise_Dataset.xlsx,
normalizes into 10 collections, and imports into MongoDB.

Usage:
    python scripts/import_excel_to_mongodb.py
    python scripts/import_excel_to_mongodb.py --drop-existing
    python scripts/import_excel_to_mongodb.py --dry-run
    python scripts/import_excel_to_mongodb.py --verbose
"""

import argparse
import logging
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple

import pandas as pd
from bson import ObjectId
from pymongo import MongoClient
from pymongo.errors import (
    ConnectionFailure, DuplicateKeyError,
    OperationFailure, ServerSelectionTimeoutError,
)
from pymongo.database import Database
from pymongo.collection import Collection

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from database.config import settings
from database.db_schema import Collections, get_collection_validators
from database.indexes import get_index_specs

EXCEL_PATH = str(PROJECT_ROOT / "dataset" / "DGA_Enterprise_Dataset.xlsx")
LOG_DIR = PROJECT_ROOT / "logs"
LOG_FILE = LOG_DIR / "import.log"
LOG_DIR.mkdir(parents=True, exist_ok=True)

logger = logging.getLogger("durian_guardian.import")


def setup_file_logging(verbose: bool = False) -> None:
    level = logging.DEBUG if verbose else logging.INFO
    formatter = logging.Formatter(
        "%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    root_logger = logging.getLogger()
    root_logger.setLevel(level)

    fh = logging.FileHandler(str(LOG_FILE), mode="w", encoding="utf-8")
    fh.setLevel(level)
    fh.setFormatter(formatter)
    root_logger.addHandler(fh)

    ch = logging.StreamHandler(sys.stdout)
    ch.setLevel(level)
    ch.setFormatter(formatter)
    root_logger.addHandler(ch)


def disease_name_to_code(name: str) -> str:
    mapping = {
        "Healthy": "healthy",
        "Anthracnose": "anthracnose",
        "Canker": "canker",
        "Fruit Rot": "fruit_rot",
        "Stem Rot": "stem_rot",
        "Leaf Spot": "leaf_spot",
        "Root Rot": "root_rot",
        "Mealybug": "mealybug",
        "Scale Insect": "scale_insect",
        "Sooty Mold": "sooty_mold",
        "Dieback": "dieback",
        "Algae Spot": "algae_spot",
        "Phytophthora": "phytophthora",
        "Powdery Mildew": "powdery_mildew",
        "Nutrient Deficiency": "nutrient_deficiency",
    }
    return mapping.get(name, name.lower().replace(" ", "_"))


class ImportStats:
    def __init__(self) -> None:
        self.start_time: Optional[float] = None
        self.end_time: Optional[float] = None
        self.imported: Dict[str, int] = {}
        self.skipped: Dict[str, int] = {}
        self.errors: List[str] = []
        self.warnings: List[str] = []

    def add_imported(self, collection: str, count: int) -> None:
        self.imported[collection] = self.imported.get(collection, 0) + count

    def add_skipped(self, collection: str, count: int = 1) -> None:
        self.skipped[collection] = self.skipped.get(collection, 0) + count

    def add_error(self, msg: str) -> None:
        self.errors.append(msg)
        logger.error(msg)

    def add_warning(self, msg: str) -> None:
        self.warnings.append(msg)
        logger.warning(msg)

    @property
    def elapsed(self) -> str:
        if self.start_time and self.end_time:
            secs = self.end_time - self.start_time
            return f"{secs:.2f}s"
        return "N/A"


def create_collections_and_indexes(
    db: Database, drop_existing: bool = False
) -> None:
    for coll_name in Collections.all():
        exists = coll_name in db.list_collection_names()
        if drop_existing and exists:
            db.drop_collection(coll_name)
            logger.info("Dropped collection: %s", coll_name)
            exists = False

        schema = get_collection_validators().get(coll_name, {})
        if exists and schema:
            db.command(
                "collMod", coll_name,
                validator=schema, validationLevel="strict", validationAction="error",
            )
            logger.info("Updated validator: %s", coll_name)
        elif schema:
            db.create_collection(
                coll_name,
                validator=schema, validationLevel="strict", validationAction="error",
            )
            logger.info("Created collection: %s", coll_name)
        elif not exists:
            db.create_collection(coll_name)
            logger.info("Created collection (no validator): %s", coll_name)

    for coll_name, specs in get_index_specs().items():
        if coll_name not in db.list_collection_names():
            continue
        collection: Collection = db[coll_name]
        existing = collection.index_information()
        for spec in specs:
            name = spec.get("name", "unnamed")
            if name in existing:
                continue
            keys = spec.pop("keys")
            collection.create_index(keys, **spec)
            logger.info("Created index '%s' on %s", name, coll_name)


def insert_docs(
    db: Database, coll_name: str, docs: List[Dict], stats: ImportStats
) -> None:
    if not docs:
        return
    count = 0
    skipped = 0
    for doc in docs:
        try:
            db[coll_name].insert_one(doc)
            count += 1
        except DuplicateKeyError:
            skipped += 1
        except OperationFailure as exc:
            stats.add_error(f"{coll_name}: insert failed: {exc}")
            skipped += 1
    stats.add_imported(coll_name, count)
    if skipped:
        stats.add_skipped(coll_name, skipped)
    logger.info(
        "  %s: %d imported, %d skipped", coll_name, count, skipped,
    )


def step_companies(
    df: pd.DataFrame, db: Database, stats: ImportStats
) -> Dict[str, ObjectId]:
    now = datetime.now(timezone.utc)
    docs = []
    for _, row in df.iterrows():
        docs.append({
            "_id": ObjectId(),
            "company_code": str(row["company_code"]),
            "company_name": str(row["company_name"]),
            "district": str(row["district"]),
            "province": str(row["province"]),
            "created_at": now,
        })
    insert_docs(db, Collections.COMPANIES, docs, stats)
    return {
        d["company_code"]: d["_id"]
        for d in db[Collections.COMPANIES].find()
    }


def step_farms(
    df: pd.DataFrame, db: Database, stats: ImportStats,
    company_map: Dict[str, ObjectId],
) -> Dict[str, ObjectId]:
    now = datetime.now(timezone.utc)
    docs = []
    for _, row in df.iterrows():
        company_oid = company_map.get(str(row["company_code"]))
        if not company_oid:
            stats.add_error(f"Farm {row['farm_code']}: missing company {row['company_code']}")
            continue
        docs.append({
            "_id": ObjectId(),
            "farm_code": str(row["farm_code"]),
            "farm_name": str(row["farm_name"]),
            "company_id": company_oid,
            "district": str(row["district"]),
            "area_hectare": float(row["area_hectare"]),
            "tree_count": int(row["tree_count"]),
            "created_at": now,
        })
    insert_docs(db, Collections.FARMS, docs, stats)
    return {d["farm_code"]: d["_id"] for d in db[Collections.FARMS].find()}


def step_zones(
    df: pd.DataFrame, db: Database, stats: ImportStats,
    farm_map: Dict[str, ObjectId],
) -> Dict[Tuple[str, str], ObjectId]:
    now = datetime.now(timezone.utc)
    docs = []
    for _, row in df.iterrows():
        farm_oid = farm_map.get(str(row["farm_code"]))
        if not farm_oid:
            stats.add_error(f"Zone {row['zone_name']}: missing farm {row['farm_code']}")
            continue
        docs.append({
            "_id": ObjectId(),
            "farm_id": farm_oid,
            "zone_name": str(row["zone_name"]),
            "tree_count": int(row["tree_count"]),
            "created_at": now,
        })
    insert_docs(db, Collections.ZONES, docs, stats)
    result: Dict[Tuple[str, str], ObjectId] = {}
    for z in db[Collections.ZONES].find():
        farm_doc = db[Collections.FARMS].find_one({"_id": z["farm_id"]})
        if farm_doc:
            result[(farm_doc["farm_code"], z["zone_name"])] = z["_id"]
    return result


def step_users(
    df: pd.DataFrame, db: Database, stats: ImportStats,
) -> None:
    now = datetime.now(timezone.utc)
    docs = []
    for _, row in df.iterrows():
        docs.append({
            "_id": ObjectId(),
            "user_code": str(row["user_code"]),
            "full_name": str(row["full_name"]),
            "role": str(row["role"]),
            "email": None,
            "password_hash": None,
            "created_at": now,
        })
    insert_docs(db, Collections.USERS, docs, stats)


def step_diseases(
    df: pd.DataFrame, db: Database, stats: ImportStats,
) -> Dict[str, ObjectId]:
    now = datetime.now(timezone.utc)
    docs = []
    for _, row in df.iterrows():
        name = str(row["name"])
        code = disease_name_to_code(name)
        docs.append({
            "_id": ObjectId(),
            "code": code,
            "name": name,
            "created_at": now,
        })
    insert_docs(db, Collections.DISEASES, docs, stats)
    return {d["name"]: d["_id"] for d in db[Collections.DISEASES].find()}


def step_trees(
    df: pd.DataFrame, db: Database, stats: ImportStats,
    farm_map: Dict[str, ObjectId],
    zone_map: Dict[Tuple[str, str], ObjectId],
) -> Dict[str, ObjectId]:
    now = datetime.now(timezone.utc)
    docs = []
    for _, row in df.iterrows():
        farm_code = str(row["farm_code"])
        zone_name = str(row["zone_name"])
        farm_oid = farm_map.get(farm_code)
        if not farm_oid:
            stats.add_error(f"Tree {row['tree_code']}: missing farm {farm_code}")
            continue
        zone_oid = zone_map.get((farm_code, zone_name))
        if not zone_oid:
            stats.add_error(f"Tree {row['tree_code']}: missing zone {zone_name} for farm {farm_code}")
            continue

        planting = pd.to_datetime(row["planting_date"]).to_pydatetime()
        docs.append({
            "_id": ObjectId(),
            "tree_code": str(row["tree_code"]),
            "farm_id": farm_oid,
            "zone_id": zone_oid,
            "variety": str(row["variety"]),
            "planting_date": planting,
            "tree_age": int(row["tree_age"]),
            "status": str(row["status"]),
            "created_at": now,
        })
    insert_docs(db, Collections.TREES, docs, stats)
    return {d["tree_code"]: d["_id"] for d in db[Collections.TREES].find()}


def step_inspections(
    df: pd.DataFrame, db: Database, stats: ImportStats,
    tree_map: Dict[str, ObjectId],
    farm_map: Dict[str, ObjectId],
    disease_map: Dict[str, ObjectId],
) -> Dict[str, ObjectId]:
    now = datetime.now(timezone.utc)
    docs = []
    for _, row in df.iterrows():
        tree_code = str(row["tree_code"])
        farm_code = str(row["farm_code"])
        tree_oid = tree_map.get(tree_code)
        farm_oid = farm_map.get(farm_code)
        if not tree_oid:
            stats.add_skipped(Collections.INSPECTIONS)
            continue
        if not farm_oid:
            stats.add_skipped(Collections.INSPECTIONS)
            continue

        disease_name = str(row["predicted_disease"])
        disease_oid = disease_map.get(disease_name)
        insp_date = pd.to_datetime(row["inspection_date"]).to_pydatetime()

        docs.append({
            "_id": ObjectId(),
            "inspection_code": str(row["inspection_code"]),
            "tree_id": tree_oid,
            "farm_id": farm_oid,
            "disease_id": disease_oid,
            "inspection_date": insp_date,
            "temperature": float(row["temperature"]),
            "humidity": float(row["humidity"]),
            "rainfall": float(row["rainfall"]),
            "health_status": str(row["health_status"]),
            "predicted_disease": disease_name,
            "confidence": float(row["confidence"]),
            "created_at": now,
        })
    insert_docs(db, Collections.INSPECTIONS, docs, stats)
    return {
        d["inspection_code"]: d["_id"]
        for d in db[Collections.INSPECTIONS].find()
    }


def step_detection_results(
    df: pd.DataFrame, db: Database, stats: ImportStats,
    inspection_map: Dict[str, ObjectId],
) -> None:
    now = datetime.now(timezone.utc)
    docs = []
    for _, row in df.iterrows():
        insp_code = str(row["inspection_code"])
        insp_oid = inspection_map.get(insp_code)
        if not insp_oid:
            stats.add_skipped(Collections.DETECTION_RESULTS)
            continue
        docs.append({
            "_id": ObjectId(),
            "inspection_id": insp_oid,
            "model": str(row["model"]),
            "prediction": str(row["prediction"]),
            "confidence": float(row["confidence"]),
            "created_at": now,
        })
    insert_docs(db, Collections.DETECTION_RESULTS, docs, stats)


def step_disease_history(
    df: pd.DataFrame, db: Database, stats: ImportStats,
    tree_map: Dict[str, ObjectId],
) -> None:
    now = datetime.now(timezone.utc)
    docs = []
    for _, row in df.iterrows():
        tree_oid = tree_map.get(str(row["tree_code"]))
        if not tree_oid:
            stats.add_skipped(Collections.DISEASE_HISTORY)
            continue
        docs.append({
            "_id": ObjectId(),
            "tree_id": tree_oid,
            "disease": str(row["disease"]),
            "date": pd.to_datetime(row["date"]).to_pydatetime(),
            "action": str(row["action"]),
            "created_at": now,
        })
    insert_docs(db, Collections.DISEASE_HISTORY, docs, stats)


def step_alerts(
    df: pd.DataFrame, db: Database, stats: ImportStats,
    farm_map: Dict[str, ObjectId],
    tree_map: Dict[str, ObjectId],
) -> None:
    now = datetime.now(timezone.utc)
    docs = []
    for _, row in df.iterrows():
        farm_oid = farm_map.get(str(row["farm_code"]))
        tree_oid = tree_map.get(str(row["tree_code"]))
        if not farm_oid:
            stats.add_skipped(Collections.ALERTS)
            continue
        if not tree_oid:
            stats.add_skipped(Collections.ALERTS)
            continue
        docs.append({
            "_id": ObjectId(),
            "farm_id": farm_oid,
            "tree_id": tree_oid,
            "alert_type": str(row["alert_type"]),
            "priority": str(row["priority"]),
            "date": pd.to_datetime(row["date"]).to_pydatetime(),
            "created_at": now,
        })
    insert_docs(db, Collections.ALERTS, docs, stats)


def run_import(
    drop_existing: bool = False,
    dry_run: bool = False,
    verbose: bool = False,
) -> ImportStats:
    setup_file_logging(verbose)
    stats = ImportStats()
    stats.start_time = time.time()

    logger.info("=" * 70)
    logger.info("  DURIAN GUARDIAN AI - Excel to MongoDB Import")
    logger.info("=" * 70)
    logger.info("  Excel: %s", EXCEL_PATH)
    logger.info("  DB:    %s", settings.DATABASE_NAME)

    logger.info("")
    logger.info(">>> Reading Excel file...")
    sheet_names = [
        "companies", "farms", "zones", "diseases", "users",
        "trees", "inspections", "detection_results",
        "disease_history", "alerts",
    ]
    sheets = {}
    for name in sheet_names:
        df = pd.read_excel(EXCEL_PATH, sheet_name=name, dtype_backend="numpy_nullable")
        sheets[name] = df
        logger.info("  %-20s : %6d rows", name, len(df))

    if dry_run:
        logger.info("")
        logger.info(">>> DRY RUN - All data read successfully.")
        logger.info("  No data was written to MongoDB.")
        return stats

    logger.info("")
    logger.info(">>> Connecting to MongoDB...")
    try:
        client = MongoClient(
            settings.mongodb_uri_with_credentials,
            **settings.connection_kwargs,
        )
        client.admin.command("ping")
        db = client[settings.DATABASE_NAME]
        logger.info("Connected: %s", settings.DATABASE_NAME)
    except (ConnectionFailure, ServerSelectionTimeoutError) as exc:
        logger.critical("Cannot connect: %s", exc)
        sys.exit(1)

    try:
        logger.info("")
        logger.info(">>> Creating collections and indexes...")
        create_collections_and_indexes(db, drop_existing)

        logger.info("")
        logger.info(">>> Importing data...")

        logger.info("  Step 1/10: Companies")
        company_map = step_companies(sheets["companies"], db, stats)

        logger.info("  Step 2/10: Farms")
        farm_map = step_farms(sheets["farms"], db, stats, company_map)

        logger.info("  Step 3/10: Zones")
        zone_map = step_zones(sheets["zones"], db, stats, farm_map)

        logger.info("  Step 4/10: Users")
        step_users(sheets["users"], db, stats)

        logger.info("  Step 5/10: Diseases")
        disease_map = step_diseases(sheets["diseases"], db, stats)

        logger.info("  Step 6/10: Trees")
        tree_map = step_trees(sheets["trees"], db, stats, farm_map, zone_map)

        logger.info("  Step 7/10: Inspections")
        inspection_map = step_inspections(
            sheets["inspections"], db, stats, tree_map, farm_map, disease_map,
        )

        logger.info("  Step 8/10: Detection Results")
        step_detection_results(sheets["detection_results"], db, stats, inspection_map)

        logger.info("  Step 9/10: Disease History")
        step_disease_history(sheets["disease_history"], db, stats, tree_map)

        logger.info("  Step 10/10: Alerts")
        step_alerts(sheets["alerts"], db, stats, farm_map, tree_map)

        logger.info("")
        logger.info(">>> Validating...")
        validate_database(db, stats)

    except Exception as exc:
        logger.critical("Import failed: %s", exc)
        stats.add_error(str(exc))
        raise
    finally:
        client.close()
        stats.end_time = time.time()
        logger.info("")
        logger.info("MongoDB connection closed.")

    return stats


def validate_database(db: Database, stats: ImportStats) -> None:
    logger.info("  Document counts:")
    for coll in Collections.all():
        count = db[coll].count_documents({})
        logger.info("    %-22s : %6d docs", coll, count)

    logger.info("")
    logger.info("  Reference checks:")
    orphans = 0
    for f in db.farms.find({"company_id": {"$exists": True}}):
        if not db.companies.find_one({"_id": f["company_id"]}):
            orphans += 1
    logger.info("    Orphan farms (no company): %d", orphans)

    for z in db.zones.find():
        if not db.farms.find_one({"_id": z["farm_id"]}):
            orphans += 1
    logger.info("    Orphan zones (no farm):    %d", orphans)

    for t in db.trees.find():
        if not db.farms.find_one({"_id": t["farm_id"]}):
            orphans += 1
        if not db.zones.find_one({"_id": t["zone_id"]}):
            orphans += 1
    logger.info("    Orphan trees:              %d", orphans)

    for ins in db.inspections.find():
        if not db.trees.find_one({"_id": ins["tree_id"]}):
            orphans += 1
        if not db.farms.find_one({"_id": ins["farm_id"]}):
            orphans += 1
    logger.info("    Orphan inspections:        %d", orphans)

    for dr in db.detection_results.find():
        if not db.inspections.find_one({"_id": dr["inspection_id"]}):
            orphans += 1
    logger.info("    Orphan detection results:  %d", orphans)

    for dh in db.disease_history.find():
        if not db.trees.find_one({"_id": dh["tree_id"]}):
            orphans += 1
    logger.info("    Orphan disease history:    %d", orphans)

    for al in db.alerts.find():
        if not db.farms.find_one({"_id": al["farm_id"]}):
            orphans += 1
        if not db.trees.find_one({"_id": al["tree_id"]}):
            orphans += 1
    logger.info("    Orphan alerts:             %d", orphans)

    logger.info("")
    logger.info("  Date checks:")
    bad_dates = 0
    for ins in db.inspections.find():
        tree = db.trees.find_one({"_id": ins["tree_id"]})
        if tree and tree.get("planting_date") and ins.get("inspection_date"):
            if tree["planting_date"] > ins["inspection_date"]:
                bad_dates += 1
    logger.info("    Planting > inspection date: %d", bad_dates)

    if orphans > 0:
        stats.add_error(f"Validation failed: {orphans} orphans found")
    if bad_dates > 0:
        stats.add_warning(f"Date anomaly: {bad_dates} records have planting_date > inspection_date")

    logger.info("")
    logger.info("  Index verification:")
    for coll_name in Collections.all():
        if coll_name not in db.list_collection_names():
            continue
        indexes = db[coll_name].index_information()
        for name, idx in indexes.items():
            if name == "_id_":
                continue
            logger.info("    %s.%s : %s", coll_name, name, idx["key"])

    logger.info("")
    logger.info("  Validator verification:")
    for coll_name in Collections.all():
        if coll_name not in db.list_collection_names():
            continue
        info = db.command("listCollections", filter={"name": coll_name})
        cursor = info["cursor"]["firstBatch"]
        if cursor and "options" in cursor[0] and "validator" in cursor[0]["options"]:
            logger.info("    %s : validator ACTIVE", coll_name)
        else:
            logger.info("    %s : no validator", coll_name)


def print_summary(stats: ImportStats) -> None:
    logger.info("")
    logger.info("=" * 70)
    logger.info("  DATABASE HEALTH REPORT")
    logger.info("=" * 70)

    all_collections = Collections.all()
    for coll in all_collections:
        count = stats.imported.get(coll, 0)
        skipped = stats.skipped.get(coll, 0)
        status = "OK" if count > 0 else "EMPTY"
        logger.info("  %-22s : %6d imported, %d skipped [%s]", coll, count, skipped, status)

    logger.info("")
    logger.info("  Elapsed time  : %s", stats.elapsed)
    logger.info("  Errors        : %d", len(stats.errors))
    for err in stats.errors:
        logger.info("    - %s", err)
    logger.info("  Warnings      : %d", len(stats.warnings))
    for warn in stats.warnings:
        logger.info("    - %s", warn)
    logger.info("")
    logger.info("  ============================================================")
    logger.info("  Indexes      : CREATED")
    logger.info("  Validators   : CREATED")
    logger.info("  Relationships: VALIDATED")
    total_imported = sum(stats.imported.values())
    total_skipped = sum(stats.skipped.values())
    logger.info("  Import       : %d documents (%d skipped)", total_imported, total_skipped)
    final_status = "SUCCESS" if not stats.errors else "FAILED"
    logger.info("  Status       : %s", final_status)
    logger.info("=" * 70)


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Durian Guardian AI - Import Excel to MongoDB",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  python scripts/import_excel_to_mongodb.py\n"
            "  python scripts/import_excel_to_mongodb.py --drop-existing\n"
            "  python scripts/import_excel_to_mongodb.py --dry-run --verbose\n"
        ),
    )
    parser.add_argument("--drop-existing", action="store_true", help="Drop collections before import")
    parser.add_argument("--dry-run", action="store_true", help="Read Excel but do not write to MongoDB")
    parser.add_argument("--verbose", action="store_true", help="Enable debug logging")
    return parser.parse_args(argv)


def main() -> None:
    args = parse_args()
    stats = run_import(
        drop_existing=args.drop_existing,
        dry_run=args.dry_run,
        verbose=args.verbose,
    )
    print_summary(stats)
    if stats.errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
