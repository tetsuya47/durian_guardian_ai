from __future__ import annotations

import asyncio
import logging
import sys
from datetime import datetime, timezone
from pathlib import Path

if sys.platform == "win32":
    try:
        asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
    except Exception:
        pass

from fastapi import FastAPI, Request, Response
from fastapi.staticfiles import StaticFiles

from app.api.v1 import api_router
from app.core.config import settings
from app.core.exception_handlers import register_exception_handlers
from app.core.logging import setup_logging
from app.core.security import hash_password
from app.database.mongodb import MongoDBManager
from app.models.enums import UserRole, api_role_to_db
from app.repositories.user_repository import UserRepository

setup_logging()
logger = logging.getLogger(__name__)


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.APP_NAME,
        version=settings.APP_VERSION,
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
    )

    @app.middleware("http")
    async def add_cors_headers(request: Request, call_next):
        origin = request.headers.get("origin")
        if request.method == "OPTIONS":
            response = Response(status_code=204)
        else:
            response = await call_next(request)
        
        if origin:
            response.headers["Access-Control-Allow-Origin"] = origin
            response.headers["Access-Control-Allow-Credentials"] = "true"
            response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, DELETE, OPTIONS, PATCH"
            response.headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization, ngrok-skip-browser-warning, X-Requested-With"
            response.headers["Access-Control-Max-Age"] = "86400"
        return response

    register_exception_handlers(app)

    app.include_router(api_router)

    upload_dir = Path(settings.UPLOAD_DIR)
    upload_dir.mkdir(parents=True, exist_ok=True)
    app.mount("/uploads", StaticFiles(directory=str(upload_dir)), name="uploads")

    @app.get("/health")
    async def health() -> dict:
        return {"status": "ok", "service": settings.APP_NAME}

    @app.on_event("startup")
    async def _seed_admin_user() -> None:
        db = MongoDBManager.get_db()
        repo = UserRepository(db)
        existing = await repo.get_by_email("bao@gmail.com")
        if existing:
            return

        from datetime import datetime, timezone
        now = datetime.now(timezone.utc)
        count = await repo.count_all()
        user_code = f"USR{count + 1:04d}"

        await repo.create(
            {
                "user_code": user_code,
                "full_name": "Bao Admin",
                "email": "bao@gmail.com",
                "password_hash": hash_password("123456"),
                "role": api_role_to_db(UserRole.enterprise_admin.value),
                "refresh_token": "",
            }
        )
        logger.info("Admin user created: bao@gmail.com")

    @app.on_event("startup")
    async def _seed_trees_if_empty() -> None:
        db = MongoDBManager.get_db()
        tree_count = await db["trees"].count_documents({})
        if tree_count < 1200:
            logger.info("Trees collection count is %d (expected 1,200). Auto-seeding 1,200 durian trees...", tree_count)
            try:
                backend_dir = Path(__file__).resolve().parent.parent
                if str(backend_dir) not in sys.path:
                    sys.path.insert(0, str(backend_dir))
                from seed_1200_trees import seed_1200_trees
                await seed_1200_trees()
                logger.info("Auto-seeded 1,200 durian trees successfully.")
            except Exception as exc:
                logger.error("Failed to auto-seed 1,200 trees: %s", exc, exc_info=True)

    return app


app = create_app()
