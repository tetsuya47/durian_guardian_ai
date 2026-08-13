import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

enum MapLayerMode { satellite, osm, terrain }
enum GISToolMode { polygon, centroid }

class FarmGISMapPicker extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final List<Map<String, double>> initialPolygon;
  final Function(double lat, double lng)? onCenterChanged;
  final Function(List<Map<String, double>> boundaryPoints, double areaHa, int perimeterMeters)? onPolygonChanged;

  const FarmGISMapPicker({
    super.key,
    this.initialLat = 12.6851,
    this.initialLng = 108.0387,
    this.initialPolygon = const [],
    this.onCenterChanged,
    this.onPolygonChanged,
  });

  @override
  State<FarmGISMapPicker> createState() => _FarmGISMapPickerState();
}

class _FarmGISMapPickerState extends State<FarmGISMapPicker> {
  late final MapController _mapController;
  late MapLayerMode _layerMode;
  late GISToolMode _toolMode;

  late LatLng _centerPos;
  late List<LatLng> _polygonPoints;

  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _layerMode = MapLayerMode.satellite;
    _toolMode = GISToolMode.polygon;

    _centerPos = LatLng(widget.initialLat, widget.initialLng);
    _polygonPoints = widget.initialPolygon
        .map((p) => LatLng(p['lat'] ?? widget.initialLat, p['lng'] ?? widget.initialLng))
        .toList();

    // Auto-locate GPS on initialization if points are default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoLocateGPS(silent: true);
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // ── GIS CALCULATIONS ──────────────────────────────────────────────────────
  double _rad(double deg) => deg * math.pi / 180.0;

  double _haversineDistMeters(LatLng p1, LatLng p2) {
    const r = 6371008.8;
    final dLat = _rad(p2.latitude - p1.latitude);
    final dLng = _rad(p2.longitude - p1.longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_rad(p1.latitude)) * math.cos(_rad(p2.latitude)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _calculatePolygonAreaSqM(List<LatLng> points) {
    if (points.length < 3) return 0;
    const r = 6371008.8;
    double total = 0;
    final n = points.length;
    for (int i = 0; i < n; i++) {
      final p1 = points[i];
      final p2 = points[(i + 1) % n];
      final lat1 = _rad(p1.latitude);
      final lng1 = _rad(p1.longitude);
      final lat2 = _rad(p2.latitude);
      final lng2 = _rad(p2.longitude);
      total += (lng2 - lng1) * (2 + math.sin(lat1) + math.sin(lat2));
    }
    return ((total * r * r) / 2).abs();
  }

  int _calculatePerimeterMeters(List<LatLng> points) {
    if (points.length < 2) return 0;
    double total = 0;
    final n = points.length;
    for (int i = 0; i < n; i++) {
      total += _haversineDistMeters(points[i], points[(i + 1) % n]);
    }
    return total.round();
  }

  void _notifyParents() {
    final areaSqM = _calculatePolygonAreaSqM(_polygonPoints);
    final areaHa = double.parse((areaSqM / 10000.0).toStringAsFixed(3));
    final perimeterM = _calculatePerimeterMeters(_polygonPoints);

    final rawBoundary = _polygonPoints
        .map((pt) => {
              'lat': double.parse(pt.latitude.toStringAsFixed(6)),
              'lng': double.parse(pt.longitude.toStringAsFixed(6)),
            })
        .toList();

    widget.onCenterChanged?.call(
      double.parse(_centerPos.latitude.toStringAsFixed(6)),
      double.parse(_centerPos.longitude.toStringAsFixed(6)),
    );

    widget.onPolygonChanged?.call(rawBoundary, areaHa, perimeterM);
  }

  // ── GPS AUTO-LOCATE ──────────────────────────────────────────────────────
  Future<void> _tryAutoLocateGPS({bool silent = false}) async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng bật dịch vụ định vị GPS trên điện thoại.')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (!silent && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ứng dụng bị từ chối quyền truy cập vị trí GPS.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quyền GPS bị từ chối vĩnh viễn. Hãy cài đặt trong ứng dụng.')),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newCenter = LatLng(position.latitude, position.longitude);
      setState(() {
        _centerPos = newCenter;
      });

      _mapController.move(newCenter, 16.5);
      _notifyParents();
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xác định vị trí GPS: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  // ── MAP TILE URL ──────────────────────────────────────────────────────────
  String get _tileUrl {
    switch (_layerMode) {
      case MapLayerMode.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case MapLayerMode.osm:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
      case MapLayerMode.terrain:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}';
    }
  }

  // ── USER TAP ON MAP ───────────────────────────────────────────────────────
  void _handleMapTap(TapPosition tapPos, LatLng point) {
    setState(() {
      if (_toolMode == GISToolMode.polygon) {
        _polygonPoints.add(point);
      } else {
        _centerPos = point;
      }
    });
    _notifyParents();
  }

  void _undoLastPoint() {
    if (_polygonPoints.isNotEmpty) {
      setState(() {
        _polygonPoints.removeLast();
      });
      _notifyParents();
    }
  }

  void _clearPolygon() {
    if (_polygonPoints.isNotEmpty) {
      setState(() {
        _polygonPoints.clear();
      });
      _notifyParents();
    }
  }

  @override
  Widget build(BuildContext context) {
    final areaSqM = _calculatePolygonAreaSqM(_polygonPoints);
    final areaHa = (areaSqM / 10000.0).toStringAsFixed(2);
    final perimeterM = _calculatePerimeterMeters(_polygonPoints);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 1. Tool Mode Switcher Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: const Color(0xFFF1F5F9),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _toolMode = GISToolMode.polygon),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
                      decoration: BoxDecoration(
                        color: _toolMode == GISToolMode.polygon ? const Color(0xFF2E7D32) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _toolMode == GISToolMode.polygon ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_road_rounded,
                            size: 14,
                            color: _toolMode == GISToolMode.polygon ? Colors.white : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Vẽ Ranh Giới',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _toolMode == GISToolMode.polygon ? Colors.white : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _toolMode = GISToolMode.centroid),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
                      decoration: BoxDecoration(
                        color: _toolMode == GISToolMode.centroid ? const Color(0xFF2E7D32) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _toolMode == GISToolMode.centroid ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: _toolMode == GISToolMode.centroid ? Colors.white : Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Đánh Dấu Tâm',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _toolMode == GISToolMode.centroid ? Colors.white : Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Layer Switcher & Auto GPS Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Layer Selector Buttons
                Row(
                  children: [
                    _buildLayerButton('🛰️ Vệ Tinh', MapLayerMode.satellite),
                    const SizedBox(width: 4),
                    _buildLayerButton('🗺️ Bản Đồ', MapLayerMode.osm),
                    const SizedBox(width: 4),
                    _buildLayerButton('⛰️ Địa Hình', MapLayerMode.terrain),
                  ],
                ),

                // GPS Auto locate button
                InkWell(
                  onTap: _isLocating ? null : () => _tryAutoLocateGPS(silent: false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFA5D6A7)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isLocating
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E7D32)),
                              )
                            : const Icon(Icons.my_location_rounded, size: 14, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 4),
                        const Text(
                          'GPS Hiện Tại',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF1B5E20)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Interactive FlutterMap Canvas Container
          SizedBox(
            height: 260,
            width: double.infinity,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _centerPos,
                    initialZoom: 16.0,
                    minZoom: 4.0,
                    maxZoom: 19.0,
                    onTap: _handleMapTap,
                  ),
                  children: [
                    // Tile Layer
                    TileLayer(
                      urlTemplate: _tileUrl,
                      userAgentPackageName: 'com.durian.guardian.ai',
                      maxZoom: 19,
                    ),

                    // Polygon & Polyline Layer
                    if (_polygonPoints.length >= 3)
                      PolygonLayer(
                        polygons: [
                          Polygon(
                            points: _polygonPoints,
                            color: const Color(0xFF10B981).withOpacity(0.35),
                            borderColor: const Color(0xFF047857),
                            borderStrokeWidth: 3.0,
                            isDotted: true,
                          ),
                        ],
                      )
                    else if (_polygonPoints.length == 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _polygonPoints,
                            color: const Color(0xFF10B981),
                            strokeWidth: 3.0,
                            isDotted: true,
                          ),
                        ],
                      ),

                    // Vertex & Centroid Marker Layer
                    MarkerLayer(
                      markers: [
                        // Center Farm Pin Marker
                        Marker(
                          point: _centerPos,
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFD32F2F),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 18),
                          ),
                        ),

                        // Polygon Vertex Nodes
                        ..._polygonPoints.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final pt = entry.value;
                          return Marker(
                            point: pt,
                            width: 20,
                            height: 20,
                            alignment: Alignment.center,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF10B981), width: 3.0),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black26, blurRadius: 3),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '${idx + 1}',
                                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),

                // Helper Mode Overlay Banner (Top left)
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _toolMode == GISToolMode.polygon
                          ? '📌 Chế độ: Tap trên bản đồ để nối điểm ranh giới Polygon (${_polygonPoints.length} điểm)'
                          : '📍 Chế độ: Tap trên bản đồ để chọn tọa độ tâm trang trại',
                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

                // Polygon Action Floating Buttons (Bottom left & right)
                if (_toolMode == GISToolMode.polygon)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    right: 8,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _polygonPoints.isEmpty ? null : _undoLastPoint,
                          icon: const Icon(Icons.undo_rounded, size: 14, color: Colors.white),
                          label: const Text('Hoàn tác', style: TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.75),
                            disabledBackgroundColor: Colors.grey.shade400,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _polygonPoints.isEmpty ? null : _clearPolygon,
                          icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.white),
                          label: const Text('Xóa ranh giới', style: TextStyle(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            disabledBackgroundColor: Colors.grey.shade400,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // 4. Realtime Metrics GIS Calculation Bar (Bottom)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: const Color(0xFF1B2E25),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tâm: ${_centerPos.latitude.toStringAsFixed(4)}, ${_centerPos.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(color: Colors.white70, fontSize: 10.5, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text('Diện tích: ', style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 11, fontWeight: FontWeight.w600)),
                          Text('$areaHa ha', style: const TextStyle(color: Color(0xFFFDE047), fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Text('• Chu vi: $perimeterM m', style: const TextStyle(color: Color(0xFF99F6E4), fontSize: 10.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF047857),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 12),
                      const SizedBox(width: 4),
                      Text(
                        '${_polygonPoints.length} điểm',
                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerButton(String label, MapLayerMode mode) {
    final isSelected = _layerMode == mode;
    return InkWell(
      onTap: () => setState(() => _layerMode = mode),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1B2E25) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
