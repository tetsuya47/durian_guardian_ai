from __future__ import annotations
import math

EARTH_RADIUS_METERS = 6371008.8  # Authalic radius of Earth in meters


def haversine_distance_meters(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """
    Calculate the great-circle distance between two points on Earth in meters.
    """
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lng2 - lng1)

    a = (
        math.sin(delta_phi / 2.0) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2.0) ** 2
    )
    c = 2.0 * math.atan2(math.sqrt(a), math.sqrt(1.0 - a))
    return EARTH_RADIUS_METERS * c


def calculate_polygon_area_sq_meters(points: list[dict]) -> float:
    """
    Calculate the geodesic area of a polygon on Earth's surface in square meters.
    points: list of dicts [{"lat": float, "lng": float}, ...]
    """
    if not points or len(points) < 3:
        return 0.0

    n = len(points)
    total_area = 0.0

    for i in range(n):
        p1 = points[i]
        p2 = points[(i + 1) % n]

        lat1 = math.radians(p1["lat"])
        lng1 = math.radians(p1["lng"])
        lat2 = math.radians(p2["lat"])
        lng2 = math.radians(p2["lng"])

        total_area += (lng2 - lng1) * (2.0 + math.sin(lat1) + math.sin(lat2))

    total_area = abs(total_area * (EARTH_RADIUS_METERS**2) / 2.0)
    return total_area


def calculate_polygon_area_ha(points: list[dict]) -> float:
    """
    Calculate geodesic polygon area in Hectares (1 ha = 10,000 sq meters).
    """
    sq_m = calculate_polygon_area_sq_meters(points)
    return round(sq_m / 10000.0, 3)


def calculate_polygon_perimeter_meters(points: list[dict]) -> float:
    """
    Calculate the perimeter of a polygon in meters.
    """
    if not points or len(points) < 2:
        return 0.0

    total_dist = 0.0
    n = len(points)
    for i in range(n):
        p1 = points[i]
        p2 = points[(i + 1) % n]
        total_dist += haversine_distance_meters(p1["lat"], p1["lng"], p2["lat"], p2["lng"])

    return round(total_dist, 2)


def calculate_centroid(points: list[dict]) -> dict:
    """
    Calculate the geometric center (centroid) of a list of points.
    """
    if not points:
        return {"lat": 12.6667, "lng": 108.05}

    avg_lat = sum(p["lat"] for p in points) / len(points)
    avg_lng = sum(p["lng"] for p in points) / len(points)
    return {"lat": round(avg_lat, 6), "lng": round(avg_lng, 6)}


def calculate_bounding_box(points: list[dict]) -> dict:
    """
    Calculate bounding box min/max coordinates.
    """
    if not points:
        return {"min_lat": 0.0, "max_lat": 0.0, "min_lng": 0.0, "max_lng": 0.0}

    lats = [p["lat"] for p in points]
    lngs = [p["lng"] for p in points]

    return {
        "min_lat": round(min(lats), 6),
        "max_lat": round(max(lats), 6),
        "min_lng": round(min(lngs), 6),
        "max_lng": round(max(lngs), 6),
    }
