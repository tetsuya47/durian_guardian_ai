from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, EmailStr, Field

from app.models import UserRole


class UserRegister(BaseModel):
    fullname: str = Field(..., min_length=1, max_length=255)
    email: EmailStr
    password: str = Field(..., min_length=6, max_length=128)
    role: UserRole = UserRole.farmer


class UserLogin(BaseModel):
    email: EmailStr
    password: str


class UserOut(BaseModel):
    id: str
    fullname: str
    email: str
    role: str
    created_at: datetime


class UserProfileUpdate(BaseModel):
    fullname: str | None = Field(None, min_length=1, max_length=255)
    email: EmailStr | None = None


class TokenOut(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


class TokenRefresh(BaseModel):
    refresh_token: str


class ChangePassword(BaseModel):
    old_password: str = Field(..., min_length=1)
    new_password: str = Field(..., min_length=6, max_length=128)
