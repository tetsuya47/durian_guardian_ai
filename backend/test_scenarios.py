import asyncio
import sys
sys.stdout.reconfigure(encoding='utf-8')

from motor.motor_asyncio import AsyncIOMotorClient
from app.services.iot_service import IoTService

async def main():
    client = AsyncIOMotorClient("mongodb://localhost:27017")
    db = client["durian_guardian_ai"]
    service = IoTService(db)

    test_cases = [
        {"name": "s01 An Toàn", "data": {"soil_moisture": 72.0, "soil_ph": 6.5, "temperature": 26.5, "humidity": 70.0}},
        {"name": "s04 Thiếu Nước", "data": {"soil_moisture": 56.0, "soil_ph": 6.2, "temperature": 31.0, "humidity": 58.0}},
        {"name": "s12 Phytophthora", "data": {"soil_moisture": 86.0, "soil_ph": 5.1, "temperature": 33.5, "humidity": 89.0, "rainfall": 14.5}},
        {"name": "s14 Thảm Họa Thối Rễ", "data": {"soil_moisture": 94.0, "soil_ph": 4.7, "temperature": 35.0, "humidity": 95.0, "rainfall": 45.0}},
        {"name": "s15 Cấp 4 Emergency", "data": {"soil_moisture": 96.0, "soil_ph": 4.4, "temperature": 35.5, "humidity": 96.0, "rainfall": 60.0}},
    ]

    for tc in test_cases:
        await service.ingest_telemetry(tc["data"])
        res = await service.get_latest_analysis()
        print(f"[{tc['name']}] -> Risk Score: {res['model3_risk_score'] * 100:.1f}%")
        print(f"  Summary Advice: {res['model4_ai_advice']}")
        print(f"  Recs: {res['model4_recommendations']}\n")

    client.close()

if __name__ == "__main__":
    asyncio.run(main())
