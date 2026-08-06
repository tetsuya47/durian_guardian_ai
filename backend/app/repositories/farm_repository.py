from __future__ import annotations

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories.base import BaseRepository


class FarmRepository(BaseRepository):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "farms")

    async def exists_by_id(self, farm_id: str) -> bool:
        from bson import ObjectId
        if not ObjectId.is_valid(farm_id):
            return False
        return await self.collection.find_one({"_id": ObjectId(farm_id)}) is not None

    async def list_by_owner(
        self, owner_id: str, page: int = 1, per_page: int = 20, keyword: str | None = None
    ) -> tuple[list[dict], int]:
        import re
        from bson import ObjectId

        filter_query: dict = {}
        if owner_id:
            user_oid = ObjectId(owner_id) if ObjectId.is_valid(owner_id) else owner_id
            user_doc = await self.collection.database["users"].find_one({"_id": user_oid})
            user_role = (user_doc.get("role") or "").lower() if user_doc else "user"
            is_admin = user_role in ["admin", "system admin"]

            if not is_admin:
                filter_query["$or"] = [
                    {"user_id": owner_id},
                    {"user_id": str(owner_id)},
                    {"owner_id": owner_id},
                    {"owner_id": str(owner_id)},
                    {"created_by": owner_id},
                    {"created_by": str(owner_id)},
                    {"owner_user_id": user_oid},
                    {"owner_user_id": str(owner_id)},
                ]

        if keyword:
            filter_query["farm_name"] = {"$regex": re.escape(keyword), "$options": "i"}
        return await self.list(
            filter_query=filter_query,
            page=page,
            per_page=per_page,
            sort=[("farm_code", 1)],
        )
