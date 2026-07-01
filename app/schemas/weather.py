from __future__ import annotations

from datetime import date

from pydantic import BaseModel, Field


class WeatherData(BaseModel):
    temperature: float | None = None
    humidity: float | None = None
    rainfall: float | None = None
    wind_speed: float | None = None
    weather_date: date


class WeatherOut(BaseModel):
    farm_id: str
    data: list[WeatherData]
