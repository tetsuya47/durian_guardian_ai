from app.utils.gis import (
    calculate_polygon_area_ha,
    calculate_polygon_perimeter_meters,
    calculate_centroid,
    calculate_bounding_box,
    haversine_distance_meters,
)


def test_haversine_distance():
    # Distance between 2 points approx 1km
    d = haversine_distance_meters(12.6667, 108.0500, 12.6757, 108.0500)
    assert d > 900 and d < 1100


def test_gis_polygon_calculations():
    # Square polygon approx 100m x 100m = 1 hectare approx
    points = [
        {"lat": 12.6660, "lng": 108.0500},
        {"lat": 12.6670, "lng": 108.0500},
        {"lat": 12.6670, "lng": 108.0510},
        {"lat": 12.6660, "lng": 108.0510},
    ]

    area = calculate_polygon_area_ha(points)
    perimeter = calculate_polygon_perimeter_meters(points)
    centroid = calculate_centroid(points)
    bbox = calculate_bounding_box(points)

    assert area > 0.5 and area < 2.0
    assert perimeter > 300 and perimeter < 500
    assert centroid["lat"] == 12.6665
    assert centroid["lng"] == 108.0505
    assert bbox["min_lat"] == 12.666
    assert bbox["max_lat"] == 12.667
