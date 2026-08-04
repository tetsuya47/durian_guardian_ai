"""Standardize system users: 
1 Admin account for Web Dashboard,
1 User / Farm Owner account for Mobile App.
"""
from datetime import datetime, timezone
from pymongo import MongoClient
from passlib.context import CryptContext

pwd = CryptContext(schemes=["bcrypt"], deprecated="auto")
client = MongoClient("mongodb://localhost:27017")
db = client["durian_guardian_ai"]

# Clear non-standard test users
db.users.delete_many({"email": {"$nin": ["bao@gmail.com", "nguyen.van.an@durianguardian.ai"]}})

# Admin Web Account
db.users.replace_one(
    {"email": "bao@gmail.com"},
    {
        "user_code": "USR0001",
        "full_name": "Bảo Quản trị",
        "email": "bao@gmail.com",
        "password_hash": pwd.hash("123456"),
        "role": "Admin",
        "refresh_token": "",
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    },
    upsert=True
)

# Mobile App User Account
db.users.replace_one(
    {"email": "nguyen.van.an@durianguardian.ai"},
    {
        "user_code": "USR0002",
        "full_name": "Nguyễn Văn An",
        "email": "nguyen.van.an@durianguardian.ai",
        "password_hash": pwd.hash("123456"),
        "role": "Farm Manager",
        "refresh_token": "",
        "created_at": datetime.now(timezone.utc),
        "updated_at": datetime.now(timezone.utc),
    },
    upsert=True
)

print("Standardized database users successfully:")
for u in db.users.find({}, {"_id": 0, "user_code": 1, "email": 1, "role": 1}):
    print(f" - {u['email']} | Role: {u['role']} | Code: {u['user_code']}")
