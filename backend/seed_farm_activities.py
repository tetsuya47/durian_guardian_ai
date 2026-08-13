import asyncio
from datetime import datetime, timezone, timedelta
import random
from motor.motor_asyncio import AsyncIOMotorClient
from app.core.config import settings

async def seed():
    client = AsyncIOMotorClient(settings.MONGODB_URL)
    db_names = set([settings.MONGODB_DB_NAME, "durian_guardian_ai", "durian_guardian_ai_1"])
    
    activity_types = [
        {"type": "Irrigation", "title": "Tưới nước tự động SmartValve", "icon": "water_drop", "unit": "45 phút", "category": "Tưới nước"},
        {"type": "Fertilizer", "title": "Bón phân NPK 15-15-15 & Hữu cơ vi sinh", "icon": "eco", "unit": "500g/gốc", "category": "Bón phân"},
        {"type": "Pesticide", "title": "Phun phòng ngừa nấm bệnh Ridomil Gold", "icon": "shield", "unit": "200 lít", "category": "Phun thuốc"},
        {"type": "Pruning", "title": "Tỉa cành gầm & khơi thông ánh sáng tán", "icon": "content_cut", "unit": "Toàn vườn", "category": "Tỉa cành"},
        {"type": "Harvest", "title": "Thu hoạch sầu riêng Ri6 loại 1", "icon": "agriculture", "unit": "1.2 Tấn", "category": "Thu hoạch"},
        {"type": "Inspection", "title": "Kiểm tra trạm cảm biến IoT & quét AI", "icon": "qr_code_scanner", "unit": "8 Cảm biến", "category": "Kiểm tra IoT"},
        {"type": "SoilTreatment", "title": "Rải vôi bột nâng pH đất về 6.5", "icon": "science", "unit": "50kg Vôi", "category": "Xử lý đất"},
    ]

    performers = ["Phan Hải (Chủ vườn)", "Nguyễn Văn Tuấn (Kỹ thuật viên)", "Tự động từ IoT SmartValve", "Đội thu hoạch Đắk Lắk"]
    now = datetime.now(timezone.utc)

    for db_name in db_names:
        db = client[db_name]
        farms = await db["farms"].find({}).to_list(length=100)
        if not farms:
            continue

        await db["farm_activities"].delete_many({})
        docs = []
        for i in range(80):
            days_ago = random.randint(0, 700)
            act_date = now - timedelta(days=days_ago)
            farm = random.choice(farms)
            farm_id = str(farm["_id"])
            farm_name = farm.get("farm_name", "Vườn Sầu Riêng Krông Pắk")
            district = farm.get("district", "Krông Pắc, Đắk Lắk")

            act = random.choice(activity_types)
            
            m = act_date.month
            if m in [5, 6, 7, 8, 9, 10, 11]:
                season = "Mùa Mưa"
            else:
                season = "Mùa Khô"
                
            if m in [1, 2, 3]:
                crop_season = "Mùa Ra Hoa & Đậu Trái"
            elif m in [4, 5, 6, 7]:
                crop_season = "Mùa Nuôi Trái & Thu Hoạch"
            else:
                crop_season = "Mùa Dưỡng Cơi Đọt"

            doc = {
                "farm_id": farm_id,
                "farm_name": farm_name,
                "district": district,
                "activity_type": act["type"],
                "category": act["category"],
                "title": f"{act['title']}",
                "description": f"Thực hiện công việc {act['category'].lower()} định kỳ tại {farm_name}. Khuyến nghị từ AI Agronomist.",
                "unit_amount": act["unit"],
                "performed_by": random.choice(performers),
                "status": "Hoàn thành",
                "activity_date": act_date,
                "year": act_date.year,
                "month": act_date.month,
                "season": season,
                "crop_season": crop_season,
                "created_at": act_date,
                "updated_at": act_date,
            }
            docs.append(doc)

        await db["farm_activities"].insert_many(docs)
        print(f"[{db_name}] Seeded {len(docs)} farm activity history records.")

asyncio.run(seed())
