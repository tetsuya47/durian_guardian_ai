from __future__ import annotations

import asyncio
import logging
from typing import Any

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)


class OpenWeatherClientError(Exception):
    """Raised when OpenWeather communication fails or is not configured."""


class OpenWeatherClient:
    """Minimal async HTTP client for the OpenWeatherMap API.

    Pure HTTP communication only. No business logic, no MongoDB access,
    no caching. Uses the already-declared ``httpx`` dependency.

    - Async ``httpx.AsyncClient`` (never blocks the event loop).
    - ``timeout`` on the whole request (connect + read).
    - One automatic retry for temporary failures (transport errors and
      HTTP 5xx / 429), with a short backoff. Invalid API key (401) and
      other 4xx errors fail immediately without retry.
    """

    def __init__(
        self,
        api_key: str | None = None,
        base_url: str | None = None,
        timeout: float = 8.0,
        retries: int = 1,
        backoff_seconds: float = 0.3,
    ) -> None:
        self.api_key = api_key if api_key is not None else settings.OPENWEATHER_API_KEY
        self.base_url = (base_url or settings.OPENWEATHER_BASE_URL).rstrip("/")
        self.timeout = timeout
        self.retries = retries
        self.backoff_seconds = backoff_seconds

    async def get_current_weather(self, lat: float, lon: float) -> dict[str, Any]:
        return await self._get("/weather", lat, lon)

    async def get_forecast(self, lat: float, lon: float) -> dict[str, Any]:
        return await self._get("/forecast", lat, lon)

    async def _get(self, path: str, lat: float, lon: float) -> dict[str, Any]:
        if not self.api_key:
            raise OpenWeatherClientError(
                "OPENWEATHER_API_KEY is not configured. "
                "Set it in the .env file (or OPENWEATHER_API_KEY env var)."
            )

        params = {
            "lat": lat,
            "lon": lon,
            "appid": self.api_key,
            "units": "metric",
            "lang": "vi",
        }

        last_exc: Exception | None = None
        for attempt in range(self.retries + 1):
            try:
                async with httpx.AsyncClient(timeout=self.timeout) as client:
                    response = await client.get(
                        f"{self.base_url}{path}", params=params
                    )

                if response.status_code == 401:
                    raise OpenWeatherClientError(
                        f"Invalid OpenWeather API key (HTTP 401) for {path}. "
                        "Check OPENWEATHER_API_KEY in the .env file."
                    )

                if response.status_code >= 400:
                    # Temporary: HTTP 5xx and 429 (rate limit) -> retry once.
                    retryable = response.status_code == 429 or response.status_code >= 500
                    if retryable and attempt < self.retries:
                        await asyncio.sleep(self.backoff_seconds)
                        continue
                    raise OpenWeatherClientError(
                        f"OpenWeather request failed for {path}: "
                        f"HTTP {response.status_code} {response.text[:200]}"
                    )

                response.raise_for_status()
                return response.json()

            except OpenWeatherClientError:
                raise
            except httpx.HTTPStatusError as exc:
                # 5xx from raise_for_status() -> temporary, retry once
                last_exc = exc
                if attempt < self.retries:
                    await asyncio.sleep(self.backoff_seconds)
                    continue
                raise OpenWeatherClientError(
                    f"OpenWeather request failed for {path}: {exc}"
                ) from exc
            except httpx.TransportError as exc:
                # Connection/timeout errors -> temporary, retry once
                last_exc = exc
                if attempt < self.retries:
                    await asyncio.sleep(self.backoff_seconds)
                    continue
                raise OpenWeatherClientError(
                    f"OpenWeather network error for {path}: {exc}"
                ) from exc

        raise OpenWeatherClientError(
            f"OpenWeather request failed for {path}: {last_exc}"
        )
