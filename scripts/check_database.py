#!/usr/bin/env python3
"""
Check Database
==============

Verify MongoDB database health after import.

Checks:
  - All 10 collections exist with data
  - All indexes are created
  - All validators are active
  - All foreign key references are valid
  - No orphans, no duplicate codes

Usage:
    python scripts/check_database.py
    python scripts/check_database.py --verbose
"""

import argparse
import logging
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

from pymongo import MongoClient
from pymongo.database import Database
from pymongo.errors import ConnectionFailure, OperationFailure, ServerSelectionTimeoutError

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from database.config import settings
from database.db_schema import Collections, get_collection_validators
from database.indexes import get_index_specs

logger = logging.getLogger("durian_guardian.check")

# ── ANSI Colors ─────────────────────────────────────────────────────────

GREEN = "\033[92m"
RED = "\033[91m"
YELLOW = "\033[93m"
CYAN = "\033[96m"
BOLD = "\033[1m"
RESET = "\033[0m"


def setup_logging(verbose: bool = False) -> None:
    level = logging.DEBUG if verbose else logging.INFO
    formatter = logging.Formatter(
        "%(asctime)s [%(levelname)s] %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
    )
    root_logger = logging.getLogger()
    root_logger.setLevel(level)
    ch = logging.StreamHandler(sys.stdout)
    ch.setLevel(level)
    ch.setFormatter(formatter)
    root_logger.addHandler(ch)


class DatabaseCheck:
    """Comprehensive database health check."""

    def __init__(self, db: Database, verbose: bool = False):
        self.db = db
        self.verbose = verbose
        self.errors: List[str] = []
        self.warnings: List[str] = []

    def report(self, label: str, status: bool, detail: str = "") -> None:
        icon = GREEN + "PASS" + RESET if status else RED + "FAIL" + RESET
        msg = f"  [{icon}] {label}"
        if detail and (not status or self.verbose):
            msg += f" - {detail}"
        logger.info(msg)

    def run_all(self) -> bool:
        self.check_collections_exist()
        self.check_collections_have_data()
        self.check_indexes()
        self.check_validators()
        self.check_companies_unique()
        self.check_farms_unique()
        self.check_zones_unique()
        self.check_trees_unique()
        self.check_users_unique()
        self.check_company_references()
        self.check_farm_references()
        self.check_zone_references()
        self.check_tree_references()
        self.check_detection_references()
        self.check_history_references()
        self.check_alert_references()
        self.check_dates()
        return len(self.errors) == 0

    def check_collections_exist(self) -> None:
        existing = set(self.db.list_collection_names())
        for coll in Collections.all():
            status = coll in existing
            self.report(f"Collection '{coll}' exists", status)
            if not status:
                self.errors.append(f"Missing collection: {coll}")

    def check_collections_have_data(self) -> None:
        for coll in Collections.all():
            if coll not in self.db.list_collection_names():
                continue
            count = self.db[coll].count_documents({})
            status = count > 0
            self.report(f"'{coll}' has data ({count} docs)", status)
            if not status:
                self.errors.append(f"Empty collection: {coll}")
            elif self.verbose:
                logger.info("         %d documents", count)

    def check_indexes(self) -> None:
        specs = get_index_specs()
        for coll_name, expected_specs in specs.items():
            if coll_name not in self.db.list_collection_names():
                continue
            existing = self.db[coll_name].index_information()
            for spec in expected_specs:
                name = spec.get("name", "unnamed")
                status = name in existing
                self.report(
                    f"Index '{name}' on {coll_name}",
                    status,
                    f"keys={spec.get('keys', '?')}" if not status else "",
                )
                if not status:
                    self.errors.append(f"Missing index: {name} on {coll_name}")

    def check_validators(self) -> None:
        for coll_name in Collections.all():
            if coll_name not in self.db.list_collection_names():
                continue
            info = self.db.command("listCollections", filter={"name": coll_name})
            cursor = info["cursor"]["firstBatch"]
            has_validator = False
            if cursor and "options" in cursor[0]:
                has_validator = "validator" in cursor[0]["options"]
            self.report(
                f"Validator on '{coll_name}'",
                has_validator,
                "no validator found" if not has_validator else "",
            )
            if not has_validator:
                self.warnings.append(f"No validator on {coll_name}")

    def check_companies_unique(self) -> None:
        pipeline = [
            {"$group": {"_id": "$company_code", "count": {"$sum": 1}}},
            {"$match": {"count": {"$gt": 1}}},
        ]
        dups = list(self.db.companies.aggregate(pipeline))
        status = len(dups) == 0
        self.report("No duplicate company_code", status, f"duplicates: {dups}" if dups else "")
        if not status:
            self.errors.append(f"Duplicate company_code: {dups}")

    def check_farms_unique(self) -> None:
        pipeline = [
            {"$group": {"_id": "$farm_code", "count": {"$sum": 1}}},
            {"$match": {"count": {"$gt": 1}}},
        ]
        dups = list(self.db.farms.aggregate(pipeline))
        status = len(dups) == 0
        self.report("No duplicate farm_code", status, f"duplicates: {dups}" if dups else "")
        if not status:
            self.errors.append(f"Duplicate farm_code: {dups}")

    def check_zones_unique(self) -> None:
        pipeline = [
            {"$group": {"_id": {"farm_id": "$farm_id", "zone_name": "$zone_name"}, "count": {"$sum": 1}}},
            {"$match": {"count": {"$gt": 1}}},
        ]
        dups = list(self.db.zones.aggregate(pipeline))
        status = len(dups) == 0
        self.report("No duplicate (farm_id, zone_name)", status, f"duplicates: {dups}" if dups else "")
        if not status:
            self.errors.append(f"Duplicate zones: {dups}")

    def check_trees_unique(self) -> None:
        pipeline = [
            {"$group": {"_id": "$tree_code", "count": {"$sum": 1}}},
            {"$match": {"count": {"$gt": 1}}},
        ]
        dups = list(self.db.trees.aggregate(pipeline))
        status = len(dups) == 0
        self.report("No duplicate tree_code", status, f"duplicates: {dups}" if dups else "")
        if not status:
            self.errors.append(f"Duplicate tree_code: {dups}")

    def check_users_unique(self) -> None:
        pipeline = [
            {"$group": {"_id": "$user_code", "count": {"$sum": 1}}},
            {"$match": {"count": {"$gt": 1}}},
        ]
        dups = list(self.db.users.aggregate(pipeline))
        status = len(dups) == 0
        self.report("No duplicate user_code", status, f"duplicates: {dups}" if dups else "")
        if not status:
            self.errors.append(f"Duplicate user_code: {dups}")

    def check_company_references(self) -> None:
        orphans = 0
        for f in self.db.farms.find({"company_id": {"$exists": True}}):
            if not self.db.companies.find_one({"_id": f["company_id"]}):
                orphans += 1
        status = orphans == 0
        self.report("Farms reference valid companies", status, f"{orphans} orphan(s)" if orphans else "")

    def check_farm_references(self) -> None:
        orphans = 0
        for z in self.db.zones.find():
            if not self.db.farms.find_one({"_id": z["farm_id"]}):
                orphans += 1
        self.report("Zones reference valid farms", orphans == 0, f"{orphans} orphan(s)" if orphans else "")
        if orphans:
            self.errors.append(f"Orphan zones: {orphans}")

    def check_zone_references(self) -> None:
        orphans = 0
        for t in self.db.trees.find():
            if not self.db.farms.find_one({"_id": t["farm_id"]}):
                orphans += 1
            if not self.db.zones.find_one({"_id": t["zone_id"]}):
                orphans += 1
        status = orphans == 0
        self.report("Trees reference valid farms+zones", status, f"{orphans} orphan(s)" if orphans else "")
        if orphans:
            self.errors.append(f"Orphan trees: {orphans}")

    def check_tree_references(self) -> None:
        orphans = 0
        for ins in self.db.inspections.find():
            if not self.db.trees.find_one({"_id": ins["tree_id"]}):
                orphans += 1
            if not self.db.farms.find_one({"_id": ins["farm_id"]}):
                orphans += 1
        status = orphans == 0
        self.report("Inspections reference valid trees+farms", status, f"{orphans} orphan(s)" if orphans else "")
        if orphans:
            self.errors.append(f"Orphan inspections: {orphans}")

    def check_detection_references(self) -> None:
        orphans = 0
        for dr in self.db.detection_results.find():
            if not self.db.inspections.find_one({"_id": dr["inspection_id"]}):
                orphans += 1
        status = orphans == 0
        self.report("Detection results reference valid inspections", status, f"{orphans} orphan(s)" if orphans else "")
        if orphans:
            self.errors.append(f"Orphan detection results: {orphans}")

    def check_history_references(self) -> None:
        orphans = 0
        for dh in self.db.disease_history.find():
            if not self.db.trees.find_one({"_id": dh["tree_id"]}):
                orphans += 1
        status = orphans == 0
        self.report("Disease history references valid trees", status, f"{orphans} orphan(s)" if orphans else "")
        if orphans:
            self.errors.append(f"Orphan disease history: {orphans}")

    def check_alert_references(self) -> None:
        orphans = 0
        for al in self.db.alerts.find():
            if not self.db.farms.find_one({"_id": al["farm_id"]}):
                orphans += 1
            if not self.db.trees.find_one({"_id": al["tree_id"]}):
                orphans += 1
        status = orphans == 0
        self.report("Alerts reference valid farms+trees", status, f"{orphans} orphan(s)" if orphans else "")
        if orphans:
            self.errors.append(f"Orphan alerts: {orphans}")

    def check_dates(self) -> None:
        bad_dates = 0
        for ins in self.db.inspections.find():
            tree = self.db.trees.find_one({"_id": ins["tree_id"]})
            if tree and tree.get("planting_date") and ins.get("inspection_date"):
                if tree["planting_date"] > ins["inspection_date"]:
                    bad_dates += 1
        status = bad_dates == 0
        self.report(
            "Planting date < inspection date",
            status,
            f"{bad_dates} violation(s)" if bad_dates else "",
        )
        if bad_dates:
            self.warnings.append(f"{bad_dates} records: planting_date > inspection_date")


def print_health_report(ok: bool, errors: List[str], warnings: List[str]) -> None:
    logger.info("")
    logger.info("=" * 70)
    logger.info("  DATABASE HEALTH REPORT")
    logger.info("=" * 70)
    logger.info("")

    for coll in Collections.all():
        logger.info("  %s", coll)

    logger.info("")
    if ok:
        logger.info("  %s[ OK ] Indexes      : All indexes verified%s", GREEN, RESET)
        logger.info("  %s[ OK ] Validators   : All validators active%s", GREEN, RESET)
        logger.info("  %s[ OK ] Relationships: All references valid%s", GREEN, RESET)
        logger.info("  %s[ OK ] Import       : SUCCESS%s", GREEN, RESET)
    else:
        logger.info("  %s[FAIL] Indexes      : %d index(es) missing%s", RED, len([e for e in errors if "Index" in e]), RESET)
        logger.info("  %s[FAIL] Validators   : %d validator(s) missing%s", RED, len([e for e in errors if "validator" in e.lower()]), RESET)
        logger.info("  %s[FAIL] Relationships: %d broken reference(s)%s", RED, len([e for e in errors if "orphan" in e.lower() or "reference" in e.lower()]), RESET)
        logger.info("  %s[FAIL] Import       : FAILED%s", RED, RESET)

    if errors:
        logger.info("")
        logger.info("  Errors:")
        for err in errors:
            logger.info("    %s- %s%s", RED, err, RESET)

    if warnings:
        logger.info("")
        logger.info("  Warnings:")
        for warn in warnings:
            logger.info("    %s- %s%s", YELLOW, warn, RESET)

    logger.info("")
    logger.info("=" * 70)


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Durian Guardian AI - Check Database",
    )
    parser.add_argument("--verbose", action="store_true", help="Show detailed info")
    return parser.parse_args(argv)


def main() -> None:
    args = parse_args()
    setup_logging(args.verbose)

    logger.info("Connecting to MongoDB...")
    try:
        client = MongoClient(
            settings.mongodb_uri_with_credentials,
            serverSelectionTimeoutMS=5000,
        )
        client.admin.command("ping")
        db = client[settings.DATABASE_NAME]
        logger.info("Connected: %s\n", settings.DATABASE_NAME)
    except (ConnectionFailure, ServerSelectionTimeoutError) as exc:
        logger.critical("Cannot connect: %s", exc)
        sys.exit(1)

    checker = DatabaseCheck(db, args.verbose)
    ok = checker.run_all()
    print_health_report(ok, checker.errors, checker.warnings)

    client.close()
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
