import asyncio
from datetime import datetime, timezone, timedelta
from app.database.mongodb import MongoDBManager

async def seed_work_planning_data():
    db = MongoDBManager.get_db()
    now = datetime.now(timezone.utc)
    
    # 1. Seed farm_activities (Work Plans)
    act_count = await db["farm_activities"].count_documents({})
    print(f"Current farm_activities count: {act_count}")
    
    if act_count == 0:
        sample_activities = [
            {
                "title": "Phun phân bón lá Canxi-Bo & Vi lượng đọt non",
                "activity_type": "Bón phân",
                "farm_zone": "Khu A - Sầu Riêng Thái",
                "scheduled_date": (now - timedelta(days=1)).strftime("%d/%m/%Y"),
                "activity_date": now - timedelta(days=1),
                "assignee": "Nguyễn Văn Tèo",
                "priority": "Cao",
                "status": "Đang thực hiện",
                "note": "Pha đúng tỷ lệ 1:500 cho 120 cây khu A",
                "created_at": now,
                "updated_at": now,
            },
            {
                "title": "Xử lý quét vôi gốc & rải Ridomil phòng nấm xì mủ",
                "activity_type": "Phun thuốc",
                "farm_zone": "Khu B - Sầu Riêng Ri6",
                "scheduled_date": now.strftime("%d/%m/%Y"),
                "activity_date": now,
                "assignee": "Trần Văn Bình",
                "priority": "Cao",
                "status": "Chưa bắt đầu",
                "note": "Rải 500g Vôi bột/gốc sát trùng nâng pH đất",
                "created_at": now,
                "updated_at": now,
            },
            {
                "title": "Kiểm tra hệ thống van tưới nhỏ giọt LoRaWAN Drip",
                "activity_type": "Tưới nước",
                "farm_zone": "Khu C & D (140 cây)",
                "scheduled_date": (now + timedelta(days=1)).strftime("%d/%m/%Y"),
                "activity_date": now + timedelta(days=1),
                "assignee": "Kỹ thuật viên Vie-farm",
                "priority": "Trung bình",
                "status": "Chưa bắt đầu",
                "note": "Kiểm tra áp suất van solenoid khu C",
                "created_at": now,
                "updated_at": now,
            },
            {
                "title": "Tỉa cành rậm rạp & vệ sinh tán dưới sầu riêng",
                "activity_type": "Cắt cành",
                "farm_zone": "Khu A - Sầu Riêng Thái",
                "scheduled_date": (now + timedelta(days=2)).strftime("%d/%m/%Y"),
                "activity_date": now + timedelta(days=2),
                "assignee": "Nguyễn Văn Tèo",
                "priority": "Thường",
                "status": "Chưa bắt đầu",
                "note": "Cắt cành khô, cành sát đất",
                "created_at": now,
                "updated_at": now,
            },
        ]
        await db["farm_activities"].insert_many(sample_activities)
        print("Seeded 4 work plans into farm_activities collection!")
        
    # 2. Seed work_logs / farm_logs
    log_count = await db["farm_logs"].count_documents({})
    print(f"Current farm_logs count: {log_count}")
    
    if log_count == 0:
        sample_logs = [
            {
                "code": "LOG-2026-0801",
                "submitted_by": "Nguyễn Văn Tèo",
                "task_name": "Đã phun phân bón lá Canxi-Bo & vi lượng đọt non 120 cây",
                "zone_name": "Khu A - Sầu Riêng Thái",
                "submitted_time": "Hôm nay 11:30",
                "note": "Đã pha đúng tỷ lệ 1:500, đọt non nhú đều đẹp.",
                "status": "Chờ duyệt",
                "created_at": now,
            },
            {
                "code": "LOG-2026-0802",
                "submitted_by": "Trần Văn Bình",
                "task_name": "Đã quét vôi gốc & rải Ridomil Gold cây bị xì mủ SR-EAYONG-019",
                "zone_name": "Khu B - Sầu Riêng Ri6",
                "submitted_time": "Hôm nay 10:15",
                "note": "Vết xì mủ cạo sạch vỏ, bôi Boóc-đô 10%.",
                "status": "Chờ duyệt",
                "created_at": now,
            },
            {
                "code": "LOG-2026-0803",
                "submitted_by": "Lê Thị Hoa",
                "task_name": "Bón phân hữu cơ nở 2kg/gốc cho 50 cây khu A",
                "zone_name": "Khu A - Sầu Riêng Thái",
                "submitted_time": "Hôm qua 16:45",
                "note": "Phân rải xung quanh đường hình chiếu tán lá.",
                "status": "Đã phê duyệt",
                "created_at": now - timedelta(days=1),
            },
        ]
        await db["farm_logs"].insert_many(sample_logs)
        print("Seeded 3 log approval entries into farm_logs collection!")

if __name__ == "__main__":
    asyncio.run(seed_work_planning_data())
