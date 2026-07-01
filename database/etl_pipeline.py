#!/usr/bin/env python3
"""
ETL Pipeline — Durian Guardian AI
===================================

Extract, Transform, Load pipeline for the DGA seed dataset.

The CSV is the ONLY source of truth. This pipeline:
  1. Reads every row from the CSV
  2. Normalizes duplicated values across rows
  3. Generates ObjectIds and foreign key references
  4. Converts strings to correct BSON types
  5. Removes duplicates at every level
  6. Loads into 7 collections (companies, farms, zones, trees,
     diseases, inspections -- users, detection_results,
     disease_history, alerts are schema-only)

Usage:
    python -m database.etl_pipeline
    python -m database.etl_pipeline --drop-existing
    python -m database.etl_pipeline --dry-run
"""

import argparse
import csv
import logging
import math
import sys
import time
from collections import Counter, defaultdict
from datetime import datetime, date, timezone
from typing import Dict, List, Optional, Tuple, Any

from bson import ObjectId
from pymongo import MongoClient
from pymongo.errors import (
    ConnectionFailure,
    DuplicateKeyError,
    OperationFailure,
    ServerSelectionTimeoutError,
)
from pymongo.database import Database
from pymongo.collection import Collection

from database.config import settings
from database.db_schema import Collections, get_collection_validators
from database.indexes import get_index_specs
from database.seed import load_diseases

logger = logging.getLogger("durian_guardian.etl")


# ── Constants ────────────────────────────────────────────────────────

CSV_PATH = "D:/Ten_Classes_of_Durian_Leaf_Diseases/DGA_seed_dataset_10000.csv"

DISEASE_NAME_TO_CODE: Dict[str, str] = {
    "Anthracnose": "anthracnose_disease",
    "Canker": "canker_disease",
    "Fruit Rot": "fruit_rot",
    "Mealybug": "mealybug_infestation",
    "Pink Disease": "pink_disease",
    "Sooty Mold": "sooty_mold",
    "Stem Blight": "stem_blight",
    "Stem Cracking Gummosis": "stem_cracking_gummosis",
    "Yellow Leaf": "yellow_leaf",
    "Healthy": "healthy",
}

# ── Logging ───────────────────────────────────────────────────────────

def _setup_logging(verbose: bool = False) -> None:
    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        handlers=[logging.StreamHandler(sys.stdout)],
    )


# ── CSV Extraction ───────────────────────────────────────────────────

def extract_csv() -> List[Dict[str, str]]:
    """Read and return all rows from the CSV."""
    with open(CSV_PATH, "r", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        rows = list(reader)
    logger.info("Extracted %d rows from CSV", len(rows))
    return rows


# ── Helpers ──────────────────────────────────────────────────────────

def parse_date(val: str) -> Optional[datetime]:
    """Parse date string to datetime, return None on failure."""
    if not val or not val.strip():
        return None
    val = val.strip()
    for fmt in ("%Y-%m-%dT%H:%M:%S", "%Y-%m-%d", "%Y/%m/%d"):
        try:
            return datetime.strptime(val, fmt)
        except ValueError:
            continue
    try:
        return datetime.fromisoformat(val)
    except (ValueError, TypeError):
        return None


def parse_float(val: str) -> Optional[float]:
    """Parse string to float, return None on failure."""
    if not val or not val.strip():
        return None
    try:
        return round(float(val.strip()), 6)
    except (ValueError, TypeError):
        return None


def parse_int(val: str) -> Optional[int]:
    """Parse string to int, return None on failure."""
    if not val or not val.strip():
        return None
    try:
        return int(float(val.strip()))
    except (ValueError, TypeError):
        return None


def mode_value(values: List[str]) -> str:
    """Return the most common value from a list."""
    counter = Counter(values)
    return counter.most_common(1)[0][0]


def extract_province(district: str) -> Tuple[str, str]:
    """Split 'Đắk Lắk - Buôn Hồ' into province='Đắk Lắk', district='Buôn Hồ'."""
    if not district or "-" not in district:
        return "", district or ""
    parts = [p.strip() for p in district.split("-", 1)]
    return parts[0], parts[1] if len(parts) > 1 else ""


# ── ETL Statistics ───────────────────────────────────────────────────

class ETLStats:
    def __init__(self) -> None:
        self.csv_rows: int = 0
        self.companies_loaded: int = 0
        self.farms_loaded: int = 0
        self.zones_loaded: int = 0
        self.trees_loaded: int = 0
        self.diseases_loaded: int = 0
        self.inspections_loaded: int = 0

        self.companies_removed_duplicates: int = 0
        self.farms_removed_duplicates: int = 0
        self.zones_removed_duplicates: int = 0
        self.trees_removed_duplicates: int = 0
        self.inspections_removed_duplicates: int = 0

        self.invalid_dates: int = 0
        self.orphan_farms: int = 0
        self.orphan_zones: int = 0
        self.orphan_trees: int = 0
        self.orphan_inspections: int = 0
        self.errors: List[str] = []

    def add_error(self, msg: str) -> None:
        self.errors.append(msg)
        logger.error(msg)


# ── TRANSFORM: Companies ─────────────────────────────────────────────

def transform_companies(rows: List[Dict[str, str]]) -> List[Dict[str, Any]]:
    """Extract unique companies from CSV rows."""
    seen = {}  # company_name -> doc
    for r in rows:
        name = r["company"].strip()
        if not name or name in seen:
            continue
        province, district = extract_province(r["district"])
        seen[name] = {
            "_id": ObjectId(),
            "company_code": "",  # filled below
            "company_name": name,
            "owner": None,
            "phone": None,
            "email": None,
            "district": district,
            "province": province,
            "created_at": datetime.now(timezone.utc),
        }

    # Assign company codes
    companies = list(seen.values())
    for i, comp in enumerate(companies, 1):
        comp["company_code"] = f"COMP{i:03d}"

    logger.info("Transformed %d unique companies", len(companies))
    return companies


# ── TRANSFORM: Farms ─────────────────────────────────────────────────

def transform_farms(
    rows: List[Dict[str, str]],
    company_map: Dict[str, ObjectId],
) -> List[Dict[str, Any]]:
    """Extract unique farms with references to companies."""
    seen = {}
    tree_counts: Dict[str, int] = defaultdict(int)

    for r in rows:
        farm_id = r["farm_id"].strip()
        if not farm_id:
            continue
        tree_counts[farm_id] += 1
        if farm_id in seen:
            continue

        province, district_val = extract_province(r["district"])
        seen[farm_id] = {
            "_id": ObjectId(),
            "farm_code": farm_id,
            "farm_name": r["farm_name"].strip(),
            "company_id": company_map.get(r["company"].strip()),
            "owner": None,
            "phone": None,
            "district": district_val,
            "commune": None,
            "latitude": None,
            "longitude": None,
            "area_hectare": None,
            "tree_count": 0,  # will update below
            "created_at": datetime.now(timezone.utc),
        }

    farms = list(seen.values())
    for farm in farms:
        farm["tree_count"] = len(
            set(
                (r["farm_id"].strip(), r["tree_code"].strip())
                for r in rows
                if r["farm_id"].strip() == farm["farm_code"]
            )
        )

    logger.info("Transformed %d unique farms", len(farms))
    return farms


# ── TRANSFORM: Zones ─────────────────────────────────────────────────

def transform_zones(
    rows: List[Dict[str, str]],
    farm_map: Dict[str, ObjectId],
) -> List[Dict[str, Any]]:
    """Extract unique farm-zone combinations."""
    zone_keys: Dict[Tuple[str, str], int] = defaultdict(int)
    zone_rows: Dict[Tuple[str, str], str] = {}

    for r in rows:
        key = (r["farm_id"].strip(), r["zone"].strip())
        zone_rows[key] = r["zone"].strip()
        zone_keys[key] += 1

    zones = []
    for (farm_id, zone_name), count in zone_keys.items():
        farm_oid = farm_map.get(farm_id)
        if not farm_oid:
            continue
        zone_code = f"{farm_id}_{zone_name.replace(' ', '_')}"
        zones.append({
            "_id": ObjectId(),
            "zone_code": zone_code,
            "farm_id": farm_oid,
            "zone_name": zone_name,
            "soil_type": None,
            "irrigation": None,
            "tree_count": count,
            "created_at": datetime.now(timezone.utc),
        })

    logger.info("Transformed %d unique zones", len(zones))
    return zones


# ── TRANSFORM: Trees ─────────────────────────────────────────────────

def transform_trees(
    rows: List[Dict[str, str]],
    farm_map: Dict[str, ObjectId],
    zone_map: Dict[str, ObjectId],
    stats: ETLStats,
) -> List[Dict[str, Any]]:
    """Aggregate and normalize tree data from CSV rows.

    Each (farm_id, tree_code) is a unique tree. For inconsistencies
    (multiple zones, dates, varieties), the most common value is used.
    """
    # Collect all values per (farm_id, tree_code)
    tree_data: Dict[Tuple[str, str], Dict[str, List[str]]] = defaultdict(
        lambda: defaultdict(list)
    )
    for r in rows:
        key = (r["farm_id"].strip(), r["tree_code"].strip())
        tree_data[key]["zone"].append(r["zone"].strip())
        tree_data[key]["variety"].append(r["variety"].strip())
        tree_data[key]["planting_date"].append(r["planting_date"].strip())
        tree_data[key]["status"].append(r["status"].strip())
        tree_data[key]["latitude"].append(r["latitude"].strip())
        tree_data[key]["longitude"].append(r["longitude"].strip())
        tree_data[key]["inspection_date"].append(r["inspection_date"].strip())

    trees = []
    for (farm_id, tree_code), data in tree_data.items():
        farm_oid = farm_map.get(farm_id)
        if not farm_oid:
            stats.orphan_trees += 1
            continue

        # Zone: use most common zone for this tree
        most_common_zone = mode_value(data["zone"])
        tree_zone_code = f"{farm_id}_{most_common_zone.replace(' ', '_')}"
        zone_oid = zone_map.get(tree_zone_code)

        # Planting date: most common
        planting_str = mode_value(data["planting_date"])
        planting_dt = parse_date(planting_str)

        # Age
        tree_age = None
        if planting_dt:
            today = datetime.now(timezone.utc).date()
            tree_age = today.year - planting_dt.year
            if (today.month, today.day) < (planting_dt.month, planting_dt.day):
                tree_age -= 1

        # Lat/lng: most common
        lat = parse_float(mode_value(data["latitude"]))
        lng = parse_float(mode_value(data["longitude"]))

        # Last inspection: max date
        insp_dates = [
            parse_date(d) for d in data["inspection_date"]
            if parse_date(d)
        ]
        last_insp = max(insp_dates) if insp_dates else None

        # Status: most common
        status = mode_value(data["status"])

        # Variety: most common
        variety = mode_value(data["variety"])

        # QR code
        qr_code = f"QR-{farm_id}-{tree_code}"

        trees.append({
            "_id": ObjectId(),
            "tree_code": tree_code,
            "farm_id": farm_oid,
            "zone_id": zone_oid,
            "variety": variety,
            "planting_date": planting_dt,
            "tree_age": tree_age,
            "status": status,
            "latitude": lat,
            "longitude": lng,
            "last_inspection": last_insp,
            "qr_code": qr_code,
            "created_at": datetime.now(timezone.utc),
        })

    logger.info("Transformed %d unique trees (deduplicated from CSV)", len(trees))
    return trees


# ── TRANSFORM: Diseases ──────────────────────────────────────────────

def transform_diseases() -> List[Dict[str, Any]]:
    """Load disease master data from seed JSON."""
    docs = load_diseases()
    for doc in docs:
        doc["_id"] = ObjectId()
        doc["created_at"] = datetime.now(timezone.utc)
    logger.info("Loaded %d disease records", len(docs))
    return docs


# ── TRANSFORM: Inspections ───────────────────────────────────────────

def transform_inspections(
    rows: List[Dict[str, str]],
    tree_map: Dict[str, ObjectId],
    disease_map: Dict[str, ObjectId],
    stats: ETLStats,
) -> List[Dict[str, Any]]:
    """Transform every CSV row into an inspection document."""
    inspections = []

    for r in rows:
        tree_key = (r["farm_id"].strip(), r["tree_code"].strip())
        tree_oid = tree_map.get(tree_key)
        if not tree_oid:
            stats.orphan_inspections += 1
            continue

        insp_date = parse_date(r["inspection_date"])
        if not insp_date:
            stats.invalid_dates += 1
            continue

        raw_disease = r["disease"].strip()
        disease_code = DISEASE_NAME_TO_CODE.get(raw_disease, "healthy")
        disease_oid = disease_map.get(disease_code)

        confidence = parse_float(r["confidence"]) or 0.0
        temperature = parse_float(r["temperature"])
        humidity = parse_float(r["humidity"])
        rainfall = parse_float(r["rainfall_mm"])
        wind = parse_float(r["wind_speed"])

        health_status = r["status"].strip()
        severity = r["severity"].strip()
        if severity in ("None", ""):
            severity = None

        zone_code = f"{r['farm_id'].strip()}_{r['zone'].strip().replace(' ', '_')}"
        farm_oid = ObjectId()  # Placeholder, filled from farm_map in load phase

        inspections.append({
            "_id": ObjectId(),
            "inspection_code": r["inspection_id"].strip(),
            "farm_id": None,  # filled during load
            "zone_id": None,  # filled during load
            "tree_id": tree_oid,
            "disease_id": disease_oid,
            "inspection_date": insp_date,
            "temperature": temperature,
            "humidity": humidity,
            "rainfall_mm": rainfall,
            "wind_speed": wind,
            "confidence": confidence,
            "predicted_disease": raw_disease,
            "health_status": health_status,
            "severity": severity,
            "remark": None,
            "created_at": datetime.now(timezone.utc),
        })

    logger.info("Transformed %d inspection records", len(inspections))
    return inspections


# ── LOAD: Create Collections & Indexes ───────────────────────────────

def create_collections_and_indexes(
    db: Database,
    drop_existing: bool = False,
) -> ETLStats:
    """Create all 10 collections with validators and indexes."""
    stats = ETLStats()

    for coll_name in Collections.all():
        try:
            exists = coll_name in db.list_collection_names()
            if drop_existing and exists:
                db.drop_collection(coll_name)
                logger.info("Dropped collection: %s", coll_name)
                exists = False

            schema = get_collection_validators().get(coll_name, {})
            if exists and schema:
                db.command(
                    "collMod",
                    coll_name,
                    validator=schema,
                    validationLevel="strict",
                    validationAction="error",
                )
                logger.info("Updated validator: %s", coll_name)
            elif schema:
                db.create_collection(
                    coll_name,
                    validator=schema,
                    validationLevel="strict",
                    validationAction="error",
                )
                logger.info("Created collection: %s", coll_name)
            elif not exists:
                db.create_collection(coll_name)
                logger.info("Created collection (no validator): %s", coll_name)

        except OperationFailure as exc:
            stats.add_error(f"Failed to create/update '{coll_name}': {exc}")

    # Indexes
    for coll_name, specs in get_index_specs().items():
        if coll_name not in db.list_collection_names():
            continue
        collection: Collection = db[coll_name]
        existing = collection.index_information()
        for spec in specs:
            try:
                name = spec.get("name", "unnamed")
                if name in existing:
                    continue
                keys = spec.pop("keys")
                collection.create_index(keys, **spec)
            except OperationFailure as exc:
                stats.add_error(
                    f"Failed to create index '{spec.get('name', 'unnamed')}' "
                    f"on '{coll_name}': {exc}"
                )

    return stats


# ── LOAD: Insert Documents ───────────────────────────────────────────

def load_documents(
    db: Database,
    companies: List[Dict],
    farms: List[Dict],
    zones: List[Dict],
    trees: List[Dict],
    diseases: List[Dict],
    inspections: List[Dict],
    stats: ETLStats,
) -> None:
    """Insert all documents into MongoDB with relationship validation."""

    # Build lookup maps
    company_by_name: Dict[str, Any] = {}
    for c in companies:
        company_by_name[c["company_name"]] = c

    farm_by_code: Dict[str, Any] = {}
    for f in farms:
        farm_by_code[f["farm_code"]] = f

    zone_by_code: Dict[str, Any] = {}
    for z in zones:
        zone_by_code[z["zone_code"]] = z

    # ── 1. Insert companies ──────────────────────────────────────────
    try:
        result = db.companies.insert_many(companies, ordered=False)
        stats.companies_loaded = len(result.inserted_ids)
        logger.info("Inserted %d companies", stats.companies_loaded)
    except DuplicateKeyError:
        # Fall back to individual inserts
        count = 0
        for c in companies:
            try:
                db.companies.insert_one(c)
                count += 1
            except DuplicateKeyError:
                stats.companies_removed_duplicates += 1
        stats.companies_loaded = count
        logger.info("Inserted %d companies (%d duplicates skipped)",
                     count, stats.companies_removed_duplicates)

    # ── 2. Insert farms ──────────────────────────────────────────────
    try:
        result = db.farms.insert_many(farms, ordered=False)
        stats.farms_loaded = len(result.inserted_ids)
        logger.info("Inserted %d farms", stats.farms_loaded)
    except DuplicateKeyError:
        count = 0
        for f in farms:
            try:
                db.farms.insert_one(f)
                count += 1
            except DuplicateKeyError:
                stats.farms_removed_duplicates += 1
        stats.farms_loaded = count
        logger.info("Inserted %d farms (%d duplicates skipped)",
                     count, stats.farms_removed_duplicates)

    # ── 3. Insert zones ──────────────────────────────────────────────
    try:
        result = db.zones.insert_many(zones, ordered=False)
        stats.zones_loaded = len(result.inserted_ids)
        logger.info("Inserted %d zones", stats.zones_loaded)
    except DuplicateKeyError:
        count = 0
        for z in zones:
            try:
                db.zones.insert_one(z)
                count += 1
            except DuplicateKeyError:
                stats.zones_removed_duplicates += 1
        stats.zones_loaded = count
        logger.info("Inserted %d zones (%d duplicates skipped)",
                     count, stats.zones_removed_duplicates)

    # ── 4. Insert diseases ───────────────────────────────────────────
    try:
        result = db.diseases.insert_many(diseases, ordered=False)
        stats.diseases_loaded = len(result.inserted_ids)
        logger.info("Inserted %d diseases", stats.diseases_loaded)
    except DuplicateKeyError:
        count = 0
        for d in diseases:
            try:
                db.diseases.insert_one(d)
                count += 1
            except DuplicateKeyError:
                pass
        stats.diseases_loaded = count
        logger.info("Inserted %d diseases", stats.diseases_loaded)

    # ── 5. Insert trees ──────────────────────────────────────────────
    # Reload farm and zone maps from DB for accurate _id references
    reloaded_farms = {f["farm_code"]: f for f in db.farms.find()}
    reloaded_zones = {z["zone_code"]: z for z in db.zones.find()}
    reloaded_diseases = {d["code"]: d for d in db.diseases.find()}

    # Update tree references
    for tree in trees:
        farm_code = None
        for fc, fdoc in reloaded_farms.items():
            if fdoc["_id"] == tree["farm_id"]:
                farm_code = fc
                break
        if farm_code:
            # Build expected zone code
            zone_name_from_db = None
            for zc, zdoc in reloaded_zones.items():
                if zdoc["_id"] == tree.get("zone_id"):
                    zone_name_from_db = zc
                    break

    # Re-transform trees with correct OIDs
    final_trees = []
    tree_map: Dict[Tuple[str, str], ObjectId] = {}
    for tree in trees:
        farm_code = tree["farm_id"]  # This is actually a placeholder logic
        # Actually we need to process differently: tree["farm_id"] is already an OID
        # and tree["zone_id"] is already an OID from transform_trees
        # Just insert and build lookup map
        final_trees.append(tree)

    try:
        result = db.trees.insert_many(final_trees, ordered=False)
        stats.trees_loaded = len(result.inserted_ids)
    except DuplicateKeyError:
        count = 0
        for t in final_trees:
            try:
                db.trees.insert_one(t)
                count += 1
            except DuplicateKeyError:
                stats.trees_removed_duplicates += 1
        stats.trees_loaded = count
    logger.info("Inserted %d trees (%d duplicates skipped)",
                 stats.trees_loaded, stats.trees_removed_duplicates)

    # Build tree_map from actual DB documents
    for tdoc in db.trees.find():
        # Get farm_code from farms collection via farm_id
        farm_doc = db.farms.find_one({"_id": tdoc["farm_id"]})
        if farm_doc:
            tree_map[(farm_doc["farm_code"], tdoc["tree_code"])] = tdoc["_id"]

    # ── 6. Inspections: fix references and insert ────────────────────
    final_inspections = []
    for insp in inspections:
        # Find tree_id in tree_map
        # We need to look up the tree_key for this inspection
        # The tree_key was (farm_id_str, tree_code) during transform
        # Since we lost that info, we need to derive it from what we have
        tree_doc = db.trees.find_one({"_id": insp["tree_id"]})
        if not tree_doc:
            stats.orphan_inspections += 1
            continue

        farm_doc = db.farms.find_one({"_id": tree_doc["farm_id"]})
        if not farm_doc:
            stats.orphan_inspections += 1
            continue

        insp["farm_id"] = tree_doc["farm_id"]

        # zone_id from tree
        zone_oid = tree_doc.get("zone_id")
        insp["zone_id"] = zone_oid

        final_inspections.append(insp)

    if final_inspections:
        try:
            result = db.inspections.insert_many(final_inspections, ordered=False)
            stats.inspections_loaded = len(result.inserted_ids)
        except DuplicateKeyError:
            count = 0
            for ins in final_inspections:
                try:
                    db.inspections.insert_one(ins)
                    count += 1
                except DuplicateKeyError:
                    stats.inspections_removed_duplicates += 1
            stats.inspections_loaded = count
    logger.info("Inserted %d inspections (%d duplicates skipped)",
                 stats.inspections_loaded, stats.inspections_removed_duplicates)


# ── MAIN ETL ─────────────────────────────────────────────────────────

def run_etl(
    drop_existing: bool = False,
    dry_run: bool = False,
    verbose: bool = False,
) -> ETLStats:
    """Execute the full ETL pipeline."""
    _setup_logging(verbose)
    stats = ETLStats()

    logger.info("=" * 60)
    logger.info("  DURIAN GUARDIAN AI - ETL Pipeline")
    logger.info("=" * 60)

    # ── EXTRACT ──────────────────────────────────────────────────────
    logger.info("")
    logger.info(">>> EXTRACT")
    rows = extract_csv()
    stats.csv_rows = len(rows)

    # ── TRANSFORM ────────────────────────────────────────────────────
    logger.info("")
    logger.info(">>> TRANSFORM")

    # Companies
    logger.info("  Normalizing companies...")
    companies = transform_companies(rows)
    company_by_name = {c["company_name"]: c for c in companies}

    # Farms
    logger.info("  Normalizing farms...")
    company_map = {c["company_name"]: c["_id"] for c in companies}
    farms = transform_farms(rows, company_map)
    farm_by_code = {f["farm_code"]: f for f in farms}

    # Zones
    logger.info("  Normalizing zones...")
    farm_map = {f["farm_code"]: f["_id"] for f in farms}
    zones = transform_zones(rows, farm_map)
    zone_by_code = {z["zone_code"]: z for z in zones}

    # Trees
    logger.info("  Normalizing trees...")
    zone_map = {}
    for z in zones:
        zone_map[z["zone_code"]] = z["_id"]
    trees = transform_trees(rows, farm_map, zone_map, stats)

    # Diseases
    logger.info("  Loading disease master data...")
    diseases = transform_diseases()
    disease_by_code = {d["code"]: d for d in diseases}

    # Inspections
    logger.info("  Normalizing inspections...")
    tree_lookup: Dict[Tuple[str, str], ObjectId] = {}
    for t in trees:
        farm_code = None
        for fc, foid in farm_map.items():
            if foid == t["farm_id"]:
                farm_code = fc
                break
        if farm_code:
            tree_lookup[(farm_code, t["tree_code"])] = t["_id"]

    disease_lookup = {d["code"]: d["_id"] for d in diseases}

    inspections = transform_inspections(
        rows, tree_lookup, disease_lookup, stats
    )

    # Fix farm_id and zone_id for inspections
    for insp in inspections:
        tree_doc = next(
            (t for t in trees if t["_id"] == insp["tree_id"]), None
        )
        if tree_doc:
            insp["farm_id"] = tree_doc["farm_id"]
            insp["zone_id"] = tree_doc.get("zone_id")

    if dry_run:
        logger.info("")
        logger.info(">>> DRY RUN - Summary")
        logger.info("  Companies   : %d", len(companies))
        logger.info("  Farms       : %d", len(farms))
        logger.info("  Zones       : %d", len(zones))
        logger.info("  Trees       : %d", len(trees))
        logger.info("  Diseases    : %d", len(diseases))
        logger.info("  Inspections : %d", len(inspections))
        return stats

    # ── LOAD ─────────────────────────────────────────────────────────
    logger.info("")
    logger.info(">>> LOAD")

    # Connect
    try:
        client = MongoClient(
            settings.mongodb_uri_with_credentials,
            **settings.connection_kwargs,
        )
        client.admin.command("ping")
        db = client[settings.DATABASE_NAME]
        logger.info("Connected to MongoDB: %s", settings.DATABASE_NAME)
    except (ConnectionFailure, ServerSelectionTimeoutError) as exc:
        logger.critical("Cannot connect to MongoDB: %s", exc)
        sys.exit(1)

    try:
        # Create collections and indexes first
        logger.info("  Creating collections and indexes...")
        coll_stats = create_collections_and_indexes(db, drop_existing)
        stats.errors.extend(coll_stats.errors)

        # Load documents
        logger.info("  Inserting documents...")
        load_documents(
            db, companies, farms, zones, trees, diseases, inspections, stats
        )

        # ── VALIDATION ───────────────────────────────────────────────
        logger.info("")
        logger.info(">>> VALIDATION")

        # Count documents
        doc_counts = {}
        for coll_name in Collections.all():
            count = db[coll_name].count_documents({})
            doc_counts[coll_name] = count
            logger.info("  %-20s : %d docs", coll_name, count)

        # Check references
        logger.info("")
        logger.info("  Reference integrity checks:")

        # Farms -> Companies
        orphan_farms = 0
        for f in db.farms.find({"company_id": {"$exists": True}}):
            if not db.companies.find_one({"_id": f["company_id"]}):
                orphan_farms += 1
        stats.orphan_farms = orphan_farms
        logger.info("  Orphan farms (no company): %d", orphan_farms)

        # Zones -> Farms
        orphan_zones = 0
        for z in db.zones.find({"farm_id": {"$exists": True}}):
            if not db.farms.find_one({"_id": z["farm_id"]}):
                orphan_zones += 1
        stats.orphan_zones = orphan_zones
        logger.info("  Orphan zones (no farm): %d", orphan_zones)

        # Trees -> Farms, Zones
        orphan_trees_farm = 0
        orphan_trees_zone = 0
        for t in db.trees.find():
            if not db.farms.find_one({"_id": t["farm_id"]}):
                orphan_trees_farm += 1
            if t.get("zone_id") and not db.zones.find_one({"_id": t["zone_id"]}):
                orphan_trees_zone += 1
        stats.orphan_trees = orphan_trees_farm + orphan_trees_zone
        logger.info("  Orphan trees (no farm): %d", orphan_trees_farm)
        logger.info("  Orphan trees (no zone): %d", orphan_trees_zone)

        # Inspections -> Trees, Diseases
        orphan_insp_tree = 0
        orphan_insp_disease = 0
        for ins in db.inspections.find():
            if not db.trees.find_one({"_id": ins["tree_id"]}):
                orphan_insp_tree += 1
            if ins.get("disease_id") and not db.diseases.find_one(
                {"_id": ins["disease_id"]}
            ):
                orphan_insp_disease += 1
        stats.orphan_inspections = orphan_insp_tree + orphan_insp_disease
        logger.info("  Orphan inspections (no tree): %d", orphan_insp_tree)
        logger.info("  Orphan inspections (no disease): %d", orphan_insp_disease)

    except Exception as exc:
        logger.critical("ETL failed: %s", exc)
        stats.add_error(str(exc))
        raise
    finally:
        client.close()
        logger.info("MongoDB connection closed.")

    return stats


# ── PRINT SUMMARY ────────────────────────────────────────────────────

def print_summary(stats: ETLStats) -> None:
    logger.info("")
    logger.info("=" * 60)
    logger.info("  ETL COMPLETE - Database Summary")
    logger.info("=" * 60)
    logger.info("  Imported documents:")
    logger.info("    Companies         : %d", stats.companies_loaded)
    logger.info("    Farms             : %d", stats.farms_loaded)
    logger.info("    Zones             : %d", stats.zones_loaded)
    logger.info("    Trees             : %d", stats.trees_loaded)
    logger.info("    Diseases          : %d", stats.diseases_loaded)
    logger.info("    Inspections       : %d", stats.inspections_loaded)
    logger.info("")
    logger.info("  Duplicates removed:")
    logger.info("    Companies         : %d", stats.companies_removed_duplicates)
    logger.info("    Farms             : %d", stats.farms_removed_duplicates)
    logger.info("    Zones             : %d", stats.zones_removed_duplicates)
    logger.info("    Trees             : %d", stats.trees_removed_duplicates)
    logger.info("    Inspections       : %d", stats.inspections_removed_duplicates)
    logger.info("")
    logger.info("  Relationships:")
    logger.info("    Orphan farms      : %d", stats.orphan_farms)
    logger.info("    Orphan zones      : %d", stats.orphan_zones)
    logger.info("    Orphan trees      : %d", stats.orphan_trees)
    logger.info("    Orphan inspections: %d", stats.orphan_inspections)
    logger.info("")
    logger.info("  Data quality:")
    logger.info("    Invalid dates     : %d", stats.invalid_dates)
    logger.info("")
    if stats.errors:
        logger.info("  Errors (%d):", len(stats.errors))
        for err in stats.errors:
            logger.info("    - %s", err)
    else:
        logger.info("  Errors            : 0")
    logger.info("")
    logger.info("  Status: %s", "SUCCESS" if not stats.errors else "FAILED")
    logger.info("=" * 60)


# ── CLI ──────────────────────────────────────────────────────────────

def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Durian Guardian AI - ETL Pipeline",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  python -m database.etl_pipeline\n"
            "  python -m database.etl_pipeline --drop-existing\n"
            "  python -m database.etl_pipeline --dry-run\n"
            "  python -m database.etl_pipeline --verbose\n"
        ),
    )
    parser.add_argument(
        "--drop-existing",
        action="store_true",
        help="Drop all collections before re-creating",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Transform only, do not insert into MongoDB",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable debug logging",
    )
    return parser.parse_args(argv)


def main() -> None:
    args = parse_args()
    stats = run_etl(
        drop_existing=args.drop_existing,
        dry_run=args.dry_run,
        verbose=args.verbose,
    )
    print_summary(stats)
    if stats.errors:
        sys.exit(1)


if __name__ == "__main__":
    main()
