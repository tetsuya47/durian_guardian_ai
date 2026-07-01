from __future__ import annotations

from datetime import date, timedelta

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories import WeatherRepository
from app.schemas import WeatherData, WeatherOut


class WeatherService:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.repo = WeatherRepository(db)

    async def get_weather(self, farm_id: str) -> WeatherOut:
        existing = await self.repo.list_by_farm(farm_id, limit_days=7)

        if existing:
            data = [
                WeatherData(
                    temperature=w.get("temperature"),
                    humidity=w.get("humidity"),
                    rainfall=w.get("rainfall"),
                    wind_speed=w.get("wind_speed"),
                    weather_date=w.get("weather_date"),
                )
                for w in existing
            ]
        else:
            data = self._mock_weather_data()

        return WeatherOut(farm_id=farm_id, data=data)

    def _mock_weather_data(self) -> list[WeatherData]:
        import random

        today = date.today()
        result = []
        for i in range(7):
            d = today - timedelta(days=i)
            result.append(
                WeatherData(
                    temperature=round(random.uniform(24, 35), 1),
                    humidity=round(random.uniform(60, 95), 1),
                    rainfall=round(random.uniform(0, 50), 1),
                    wind_speed=round(random.uniform(0, 20), 1),
                    weather_date=d,
                )
            )
        return result
