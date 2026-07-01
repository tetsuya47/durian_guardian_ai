from __future__ import annotations

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories.base import BaseRepository


class UserRepository(BaseRepository):
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        super().__init__(db, "users")

    async def get_by_email(self, email: str) -> dict | None:
        doc = await self.collection.find_one({"email": email})
        if doc:
            return self._serialize(doc)
        return None

    async def update_refresh_token(
        self, user_id: str, refresh_token: str
    ) -> None:
        await self.collection.update_one(
            {"_id": self._to_oid(user_id)},
            {"$set": {"refresh_token": refresh_token}},
        )

    def _to_oid(self, id: str):
        from bson import ObjectId
        return ObjectId(id)
