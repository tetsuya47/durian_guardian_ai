from __future__ import annotations

from pydantic import BaseModel, Field

class WeatherForecastItem(BaseModel):
    dt: int | None = Field(default=None)
    temperature: float = Field(..., description="Nhiệt độ dự báo (°C)")
    humidity: int = Field(..., description="Độ ẩm (%)")
    weather: str = Field(default="")
    description: str = Field(default="")
    icon: str = Field(default="")

class WeatherCurrentResponse(BaseModel):
    location_name: str = Field(..., description="Tên khu vực / trang trại")
    temp_celsius: float = Field(..., description="Nhiệt độ hiện tại (°C)")
    feels_like_celsius: float = Field(..., description="Nhiệt độ cảm nhận (°C)")
    humidity_percent: int = Field(..., description="Độ ẩm không khí (%)")
    wind_speed_m_s: float = Field(..., description="Tốc độ gió (m/s)")
    description: str = Field(..., description="Mô tả thời tiết (tiếng Việt)")
    icon_url: str = Field(..., description="URL biểu tượng thời tiết")
    fungal_disease_risk: str = Field(..., description="Mức độ nguy cơ nấm lá/bệnh sầu riêng: LOW, MEDIUM, HIGH")
    agricultural_advice: str = Field(..., description="Khuyến nghị nông nghiệp thông minh")
    forecast: list[WeatherForecastItem] | None = Field(default=None, description="Dự báo thời tiết nhiều giờ/ngày")

