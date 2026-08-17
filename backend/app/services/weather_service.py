from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import Any

from motor.motor_asyncio import AsyncIOMotorDatabase

from app.core.config import settings
from app.repositories.farm_repository import FarmRepository
from app.repositories.weather_repository import WeatherRepository
from app.utils.openweather_client import OpenWeatherClient, OpenWeatherClientError
from app.ai.predictor_model3 import Model3Predictor

logger = logging.getLogger(__name__)


class WeatherService:
    """Orchestrates the weather cache-aside workflow and Model 3 Random Forest risk analysis.

    Data flow:
        farm_id
          ↓ resolve coordinates (gps_lat/gps_lng or latitude/longitude)
        WeatherRepository (cache lookup — fresh? return)
          ↓ miss / expired
        OpenWeatherClient (async httpx, real API)
          ↓ raw payload
        Map OpenWeather JSON → DGA cache schema (never expose raw payload)
          ↓
        Analyze agricultural (fungal disease) risk  — existing logic, unchanged
          ↓
        WeatherRepository (delete expired + upsert flattened doc)
          ↓
        Return DGA response schema (unchanged 9 fields)
    """

    DEFAULT_LAT = 12.6667
    DEFAULT_LON = 108.0500

    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.repo = WeatherRepository(db)
        self.client = OpenWeatherClient()
        self.farm_repo = FarmRepository(db)
        try:
            self._model3 = Model3Predictor()
        except Exception as exc:
            logger.warning("Could not initialize Model3Predictor in WeatherService: %s", exc)
            self._model3 = None

    async def get_current_weather(
        self,
        farm_id: str | None = None,
        lat: float = DEFAULT_LAT,
        lon: float = DEFAULT_LON,
        include_forecast: bool = False,
    ) -> dict:
        """Fetch live weather for a farm with cache-aside + Durian risk analysis."""
        # 1. Resolve farm coordinates (only if lat/lon are not explicitly provided).
        if farm_id and (lat == self.DEFAULT_LAT and lon == self.DEFAULT_LON):
            farm = await self.farm_repo.get(farm_id)
            if farm:
                lat, lon = self._resolve_coords(farm, lat, lon)

        # 2. Cache-Aside lookup.
        cached = await self.repo.get_by_coords(lat, lon)
        if cached and self._is_cache_fresh(cached):
            logger.info("Serving weather from MongoDB cache (%s)", cached["_id"])
            return self._build_response(cached)

        # 3. Call OpenWeatherMap API via async httpx client.
        try:
            raw_data = await self.client.get_current_weather(lat, lon)
        except OpenWeatherClientError as exc:
            logger.error("Failed to fetch OpenWeatherMap API: %s", exc)
            if cached:
                logger.warning("Serving stale cached weather as fallback")
                return self._build_response(cached)
            return self._build_fallback_weather()

        # 4. Map OpenWeather payload → DGA cache schema (flattened, required fields only).
        doc = self._map_openweather_to_cache(raw_data, lat, lon, farm_id)

        # Optional normalized forecast (kept out of the default path).
        if include_forecast:
            forecast = await self._fetch_normalized_forecast(lat, lon)
            if forecast:
                doc["forecast"] = forecast

        # Cache identity: the same cache key used by the lookup above.
        doc["_id"] = WeatherRepository.build_cache_key(lat, lon)

        # 5. Update the cache (Cache-Aside write + expired cleanup).
        try:
            await self.repo.delete_expired()
            await self.repo.upsert_weather(
                doc, ttl_minutes=settings.WEATHER_CACHE_TTL_MINUTES
            )
        except Exception as exc:
            logger.warning("Failed to save weather cache: %s", exc)

        # 6. Build the unchanged DGA response.
        return self._build_response(doc)

    # ------------------------------------------------------------------ #
    # Coordinate resolution (Task 5)                                      #
    # ------------------------------------------------------------------ #

    @staticmethod
    def _resolve_coords(farm: dict | None, lat: float, lon: float) -> tuple[float, float]:
        """Resolve GPS coordinates from a Farm document.

        Supports both coordinate field naming schemes used across the project:
        ``gps_lat``/``gps_lng`` (API CRUD layer) and ``latitude``/``longitude``
        (DB JSON-schema validator / ETL seed data). Falls back to the supplied
        lat/lon when the Farm has no coordinates.
        """
        if not farm:
            return lat, lon
        for lat_key, lon_key in (("gps_lat", "gps_lng"), ("latitude", "longitude")):
            candidate_lat = farm.get(lat_key)
            candidate_lon = farm.get(lon_key)
            if candidate_lat is not None and candidate_lon is not None:
                return float(candidate_lat), float(candidate_lon)
        return lat, lon

    # ------------------------------------------------------------------ #
    # Cache-Aside helpers (Task 4)                                        #
    # ------------------------------------------------------------------ #

    def _is_cache_fresh(self, cached: dict) -> bool:
        """Cache-Aside rule: fresh while ``cache_expired_at`` is in the future."""
        now = datetime.now(timezone.utc)
        expires = cached.get("cache_expired_at")
        if expires is not None:
            if expires.tzinfo is None:
                expires = expires.replace(tzinfo=timezone.utc)
            return expires > now

        # Backwards compatibility: old docs only have updated_at.
        updated_at = cached.get("updated_at")
        if updated_at is not None:
            if updated_at.tzinfo is None:
                updated_at = updated_at.replace(tzinfo=timezone.utc)
            age_seconds = (now - updated_at).total_seconds()
            return age_seconds < settings.WEATHER_CACHE_TTL_MINUTES * 60
        return False

    # ------------------------------------------------------------------ #
    # OpenWeather → DGA mapping (Task 6)                                  #
    # ------------------------------------------------------------------ #

    @staticmethod
    def _map_openweather_to_cache(
        raw_data: dict, lat: float, lon: float, farm_id: str | None
    ) -> dict:
        """Map the raw OpenWeather current-weather payload into the DGA schema.

        Only the fields DGA needs are extracted — the raw payload is never
        stored and never exposed.
        """
        main = raw_data.get("main", {}) or {}
        temp = float(main.get("temp", 28.0))
        feels_like = float(main.get("feels_like", temp))
        temp_min = float(main.get("temp_min", temp - 2.0))
        temp_max = float(main.get("temp_max", temp + 3.0))
        humidity = int(main.get("humidity", 75))
        pressure = int(main.get("pressure", 1013))

        wind = raw_data.get("wind", {}) or {}
        wind_speed = float(wind.get("speed", 0.0))

        clouds = int((raw_data.get("clouds", {}) or {}).get("all", 0))
        visibility = int(raw_data.get("visibility", 10000))

        rain = (raw_data.get("rain", {}) or {})
        rainfall = float(rain.get("1h") or rain.get("3h") or 0.0)

        weather_list = raw_data.get("weather") or [{}]
        weather = weather_list[0].get("main", "Clouds")
        description = weather_list[0].get("description", "Thời tiết ổn định")
        icon = weather_list[0].get("icon", "02d")

        location_name = raw_data.get("name") or "Trang trại Đắk Lắk - Đồng Nai"

        return {
            "farm_id": farm_id,
            "latitude": lat,
            "longitude": lon,
            "location_name": location_name,
            "temperature": round(temp, 1),
            "feels_like": round(feels_like, 1),
            "temp_min": round(temp_min, 1),
            "temp_max": round(temp_max, 1),
            "humidity": humidity,
            "pressure": pressure,
            "wind_speed": round(wind_speed, 1),
            "rainfall": round(rainfall, 1),
            "clouds": clouds,
            "visibility": visibility,
            "weather": weather,
            "description": description,
            "icon": icon,
        }

    async def _fetch_normalized_forecast(self, lat: float, lon: float) -> list | None:
        try:
            raw = await self.client.get_forecast(lat, lon)
        except OpenWeatherClientError as exc:
            logger.warning("Forecast fetch failed (%s, %s): %s", lat, lon, exc)
            return None

        entries: list[dict[str, Any]] = []
        for item in (raw.get("list") or [])[:8]:
            item_main = item.get("main", {}) or {}
            item_weather = (item.get("weather") or [{}])[0]
            entries.append(
                {
                    "dt": item.get("dt"),
                    "temperature": float(item_main.get("temp", 0.0)),
                    "humidity": int(item_main.get("humidity", 0)),
                    "weather": item_weather.get("main", ""),
                    "description": item_weather.get("description", ""),
                    "icon": item_weather.get("icon", ""),
                }
            )
        return entries or None

    # ------------------------------------------------------------------ #
    # Response building                                                   #
    # ------------------------------------------------------------------ #

    def _build_response(self, doc: dict) -> dict:
        temp = float(doc.get("temperature", 28.0))
        feels_like = float(doc.get("feels_like", temp))
        temp_min = float(doc.get("temp_min", temp - 2.0))
        temp_max = float(doc.get("temp_max", temp + 3.0))
        humidity = int(doc.get("humidity", 75))
        wind_speed = float(doc.get("wind_speed", 0.0))

        risk, advice = self._analyze_durian_risk(temp, humidity, wind_speed)

        res = {
            "location_name": doc.get("location_name", "Trang trại Đắk Lắk - Đồng Nai"),
            "temp_celsius": round(temp, 1),
            "feels_like_celsius": round(feels_like, 1),
            "temp_min": round(temp_min, 1),
            "temp_max": round(temp_max, 1),
            "humidity_percent": humidity,
            "wind_speed_m_s": round(wind_speed, 1),
            "description": str(doc.get("description", "Thời tiết ổn định")).capitalize(),
            "icon_code": str(doc.get("icon", "02d")),
            "icon_url": f"https://openweathermap.org/img/wn/{doc.get('icon', '02d')}@2x.png",
            "fungal_disease_risk": risk,
            "agricultural_advice": advice,
        }
        if "forecast" in doc and doc["forecast"]:
            res["forecast"] = doc["forecast"]
        return res

    # ------------------------------------------------------------------ #
    # Agricultural risk logic (Task 7 — existing logic, unchanged)        #
    # ------------------------------------------------------------------ #

    def _analyze_durian_risk(self, temp: float, humidity: int, wind_speed: float) -> tuple[str, str]:
        """Agri-Intelligence powered by Model 3 Random Forest Risk Prediction engine."""
        risk = "LOW"
        advice = "Thời tiết lý tưởng cho vườn sầu riêng phát triển tốt. Đảm bảo chế độ chăm sóc định kỳ."

        if self._model3:
            try:
                # Construct 14-feature input for Model 3 Random Forest inference
                sample_features = {
                    "temperature": float(temp),
                    "humidity": float(humidity),
                    "rainfall": 10.0 if humidity >= 80 else 0.0,
                    "tree_age": 5,
                    "variety": "Monthong",
                    "health_status": "Khỏe mạnh",
                    "predicted_disease": "Khỏe mạnh",
                    "confidence": 85.0,
                    "season": "Khô",
                    "density_per_hectare": 50.0,
                    "days_since_last_inspection": 15,
                    "days_since_last_treatment": 30,
                    "historical_disease_count": 0,
                    "historical_disease_frequency": 0.0,
                }
                res = self._model3.predict(sample_features)
                risk_level_raw = res.get("risk_level", "Khỏe mạnh")
                risk_map = {
                    "Khỏe mạnh": "LOW",
                    "Nguy cơ": "MEDIUM",
                    "Bệnh nhẹ": "MEDIUM",
                    "Bệnh nặng": "HIGH",
                }
                risk = risk_map.get(risk_level_raw, "LOW")

                top_factors = res.get("top_factors", [])
                top_feat_str = ", ".join([f["feature"] for f in top_factors[:2]]) if top_factors else "nhiệt độ & độ ẩm"

                if risk == "HIGH":
                    advice = f"CẢNH BÁO AI (Random Forest): Nguy cơ rủi ro cao dựa trên phân tích {top_feat_str}. Nên chủ động phun phòng nấm sinh học và tỉa cành thông thoáng gốc."
                elif risk == "MEDIUM":
                    advice = f"CẢNH BÁO AI (Random Forest): Nguy cơ trung bình dựa trên {top_feat_str}. Kiểm tra kỹ mặt dưới lá và bộ gốc, duy trì độ ẩm vừa phải."
                else:
                    advice = "Dự báo AI (Random Forest): Điều kiện môi trường an toàn. Vườn sầu riêng phát triển bình thường."
                return risk, advice
            except Exception as exc:
                logger.warning("Model 3 inference fallback in WeatherService: %s", exc)

        # Fallback rule logic if Model 3 is unavailable
        if humidity >= 85 and 24.0 <= temp <= 32.0:
            return (
                "HIGH",
                "CẢNH BÁO: Độ ẩm rất cao (>85%) & nhiệt độ lý tưởng cho nấm Phytophthora Palmivora và bệnh Thán thư bùng phát. Nên chủ động phun phòng nấm sinh học và tỉa cành thông thoáng gốc.",
            )
        elif humidity >= 75:
            return (
                "MEDIUM",
                "Thời tiết ẩm vừa phải. Kiểm tra kỹ mặt dưới lá và bộ gốc, hạn chế tưới nước muộn vào chiều tối.",
            )
        elif temp >= 35.0:
            return (
                "MEDIUM",
                "Nhiệt độ nắng nóng cao (>35°C). Cần đảm bảo lượng nước tưới giữ ẩm chân gốc sầu riêng tránh sốc nhiệt rụng trái.",
            )
        else:
            return (
                "LOW",
                "Thời tiết lý tưởng cho vườn sầu riêng phát triển tốt. Đảm bảo chế độ chăm sóc định kỳ.",
            )

    def _build_fallback_weather(self) -> dict:
        now_hour = datetime.now(timezone.utc).hour + 7  # ICT UTC+7
        is_night = (now_hour % 24) >= 18 or (now_hour % 24) < 6
        icon = "04n" if is_night else "04d"
        desc = "Trời nhiều mây, ban đêm" if is_night else "Trời nhiều mây, độ ẩm cao"
        return {
            "location_name": "Vườn Sầu Riêng Đắk Lắk",
            "temp_celsius": 23.5 if is_night else 28.5,
            "feels_like_celsius": 24.5 if is_night else 31.0,
            "humidity_percent": 88 if is_night else 82,
            "wind_speed_m_s": 2.2 if is_night else 2.8,
            "description": desc,
            "icon_code": icon,
            "icon_url": f"https://openweathermap.org/img/wn/{icon}@2x.png",
            "fungal_disease_risk": "MEDIUM",
            "agricultural_advice": "Thời tiết tương đối ẩm. Kiểm tra kỹ mặt dưới lá và gốc cây sầu riêng.",
        }
