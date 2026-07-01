from __future__ import annotations

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.exceptions import (
    BadRequestException,
    ConflictException,
    UnauthorizedException,
)
from app.core.security import (
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
)
from app.repositories import UserRepository
from app.schemas import TokenOut, UserOut, UserProfileUpdate, UserRegister


class AuthService:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.repo = UserRepository(db)

    async def register(self, data: UserRegister) -> UserOut:
        existing = await self.repo.get_by_email(data.email)
        if existing:
            raise ConflictException("Email already registered")
        password_hash = hash_password(data.password)
        user_id = await self.repo.create(
            {
                "fullname": data.fullname,
                "email": data.email,
                "password_hash": password_hash,
                "role": data.role.value,
            }
        )
        user = await self.repo.get(user_id)
        if not user:
            raise BadRequestException("Registration failed")
        return UserOut(
            id=user["id"],
            fullname=user["fullname"],
            email=user["email"],
            role=user["role"],
            created_at=user["created_at"],
        )

    async def login(self, email: str, password: str) -> TokenOut:
        user = await self.repo.get_by_email(email)
        if not user or not verify_password(password, user["password_hash"]):
            raise UnauthorizedException("Invalid email or password")
        refresh_token = create_refresh_token(
            sub=user["id"], role=user["role"]
        )
        await self.repo.update_refresh_token(user["id"], refresh_token)
        return TokenOut(
            access_token=create_access_token(
                sub=user["id"], role=user["role"]
            ),
            refresh_token=refresh_token,
        )

    async def refresh(self, refresh_token: str) -> TokenOut:
        payload = decode_token(refresh_token)
        if not payload or payload.get("type") != "refresh":
            raise UnauthorizedException("Invalid refresh token")
        sub = payload.get("sub")
        if sub is None:
            raise UnauthorizedException("Invalid refresh token")
        user = await self.repo.get(sub)
        if not user:
            raise UnauthorizedException("User not found")
        stored = user.get("refresh_token")
        if stored and stored != refresh_token:
            raise UnauthorizedException("Refresh token has been revoked")
        new_refresh = create_refresh_token(
            sub=user["id"], role=user["role"]
        )
        await self.repo.update_refresh_token(user["id"], new_refresh)
        return TokenOut(
            access_token=create_access_token(
                sub=user["id"], role=user["role"]
            ),
            refresh_token=new_refresh,
        )

    async def logout(self, user_id: str) -> None:
        await self.repo.update_refresh_token(user_id, "")

    async def get_me(self, user_id: str) -> UserOut:
        user = await self.repo.get(user_id)
        if not user:
            raise UnauthorizedException("User not found")
        return UserOut(
            id=user["id"],
            fullname=user["fullname"],
            email=user["email"],
            role=user["role"],
            created_at=user["created_at"],
        )

    async def update_profile(
        self, user_id: str, data: UserProfileUpdate
    ) -> UserOut:
        update_data = data.model_dump(exclude_none=True)
        if "email" in update_data:
            existing = await self.repo.get_by_email(update_data["email"])
            if existing and existing["id"] != user_id:
                raise ConflictException("Email already in use")
        updated = await self.repo.update(user_id, update_data)
        if not updated:
            raise BadRequestException("Update failed")
        return UserOut(
            id=updated["id"],
            fullname=updated["fullname"],
            email=updated["email"],
            role=updated["role"],
            created_at=updated["created_at"],
        )

    async def change_password(
        self, user_id: str, old_password: str, new_password: str
    ) -> None:
        user = await self.repo.get(user_id)
        if not user:
            raise BadRequestException("User not found")
        if not verify_password(old_password, user["password_hash"]):
            raise UnauthorizedException("Old password is incorrect")
        new_hash = hash_password(new_password)
        await self.repo.update(user_id, {"password_hash": new_hash})
