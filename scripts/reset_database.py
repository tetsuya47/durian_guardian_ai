#!/usr/bin/env python3
"""
Reset Database
==============

Complete database reset: drop ALL collections, recreate with
validators and indexes, then import all data from Excel.

Usage:
    python scripts/reset_database.py
    python scripts/reset_database.py --verbose
"""

import argparse
import logging
import sys
import time
from pathlib import Path
from typing import Optional, List

from pymongo import MongoClient
from pymongo.errors import ConnectionFailure, ServerSelectionTimeoutError

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

from database.config import settings
from database.db_schema import Collections
from scripts.import_excel_to_mongodb import (
    run_import, print_summary, setup_file_logging,
)
from scripts.import_excel_to_mongodb import logger as import_logger

logger = logging.getLogger("durian_guardian.reset")


def drop_everything(client: MongoClient, db_name: str) -> None:
    """Drop all collections and indexes in the database."""
    db = client[db_name]
    cols = db.list_collection_names()
    for coll in cols:
        db.drop_collection(coll)
        logger.info("Dropped collection: %s", coll)

    # Clean up any system collections that might remain
    remaining = db.list_collection_names()
    if remaining:
        logger.warning("Remaining collections: %s", remaining)
    else:
        logger.info("Database is completely clean.")


def parse_args(argv: Optional[List[str]] = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Durian Guardian AI - Reset Database",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=(
            "Examples:\n"
            "  python scripts/reset_database.py\n"
            "  python scripts/reset_database.py --verbose\n"
        ),
    )
    parser.add_argument("--verbose", action="store_true", help="Enable debug logging")
    return parser.parse_args(argv)


def main() -> None:
    args = parse_args()
    setup_file_logging(args.verbose)

    logger.info("=" * 70)
    logger.info("  DURIAN GUARDIAN AI - Database Reset")
    logger.info("=" * 70)
    logger.info("  DB: %s", settings.DATABASE_NAME)

    logger.info("")
    logger.info(">>> Connecting to MongoDB...")
    try:
        client = MongoClient(
            settings.mongodb_uri_with_credentials,
            **settings.connection_kwargs,
        )
        client.admin.command("ping")
        logger.info("Connected.")
    except (ConnectionFailure, ServerSelectionTimeoutError) as exc:
        logger.critical("Cannot connect: %s", exc)
        sys.exit(1)

    logger.info("")
    logger.info(">>> Dropping all collections...")
    drop_everything(client, settings.DATABASE_NAME)

    client.close()

    logger.info("")
    logger.info(">>> Running import...")
    stats = run_import(
        drop_existing=False,
        dry_run=False,
        verbose=args.verbose,
    )
    print_summary(stats)

    if stats.errors:
        logger.error("Reset completed with %d error(s).", len(stats.errors))
        sys.exit(1)
    else:
        logger.info("Reset completed successfully.")
        sys.exit(0)


if __name__ == "__main__":
    main()
