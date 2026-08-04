import { useState, useEffect, useRef, useCallback } from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import {
  MapPin,
  Layers,
  Search,
  Navigation,
  Trash2,
  Undo2,
  CheckCircle2,
  Pencil,
  Maximize2,
  Minimize2,
  Sparkles,
} from "lucide-react";

export interface LatLngPoint {
  lat: number;
  lng: number;
}

interface FarmGISMapPickerProps {
  initialLat?: number;
  initialLng?: number;
  initialPolygon?: LatLngPoint[];
  onCenterChange?: (lat: number, lng: number) => void;
  onPolygonChange?: (points: LatLngPoint[], areaHa: number, perimeterMeters: number) => void;
}

const TILE_LAYERS = {
  osm: {
    name: "Bản đồ Giao thông (OSM)",
    url: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    maxZoom: 19,
    maxNativeZoom: 19,
    attribution: "&copy; OpenStreetMap contributors",
  },
  satellite: {
    name: "Bản đồ Vệ tinh (Esri)",
    url: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
    maxZoom: 19,
    maxNativeZoom: 19,
    attribution: "Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community",
  },
  terrain: {
    name: "Bản đồ Địa hình (Esri Topo)",
    url: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}",
    maxZoom: 19,
    maxNativeZoom: 19,
    attribution: "Tiles &copy; Esri &mdash; Esri, DeLorme, NAVTEQ, TomTom, Intermap, iPC, USGS, FAO, NPS, NRCAN, GeoBase, Kadaster NL, Ordnance Survey",
  },
};

// Helper for geodesic distance
function haversineDistMeters(p1: LatLngPoint, p2: LatLngPoint): number {
  const R = 6371008.8;
  const rad = Math.PI / 180;
  const lat1 = p1.lat * rad;
  const lat2 = p2.lat * rad;
  const dLat = (p2.lat - p1.lat) * rad;
  const dLng = (p2.lng - p1.lng) * rad;

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Helper for geodesic spherical area
function calculatePolygonAreaSqM(points: LatLngPoint[]): number {
  if (points.length < 3) return 0;
  const R = 6371008.8;
  const rad = Math.PI / 180;
  let total = 0;
  const n = points.length;

  for (let i = 0; i < n; i++) {
    const p1 = points[i];
    const p2 = points[(i + 1) % n];
    const lat1 = p1.lat * rad;
    const lng1 = p1.lng * rad;
    const lat2 = p2.lat * rad;
    const lng2 = p2.lng * rad;

    total += (lng2 - lng1) * (2 + Math.sin(lat1) + Math.sin(lat2));
  }

  return Math.abs((total * R * R) / 2);
}

function calculatePerimeterMeters(points: LatLngPoint[]): number {
  if (points.length < 2) return 0;
  let total = 0;
  const n = points.length;
  for (let i = 0; i < n; i++) {
    total += haversineDistMeters(points[i], points[(i + 1) % n]);
  }
  return total;
}

export default function FarmGISMapPicker({
  initialLat = 12.6667,
  initialLng = 108.05,
  initialPolygon = [],
  onCenterChange,
  onPolygonChange,
}: FarmGISMapPickerProps) {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const tileLayerRef = useRef<L.TileLayer | null>(null);

  const centerMarkerRef = useRef<L.Marker | null>(null);
  const polygonLayerRef = useRef<L.Polygon | null>(null);
  const vertexMarkersRef = useRef<L.Marker[]>([]);

  const [activeLayer, setActiveLayer] = useState<"osm" | "satellite" | "terrain">("satellite");
  const [activeTool, setActiveTool] = useState<"center" | "polygon">("polygon");

  const [centerPos, setCenterPos] = useState<LatLngPoint>({ lat: initialLat, lng: initialLng });
  const [polygonPoints, setPolygonPoints] = useState<LatLngPoint[]>(initialPolygon);
  const [searchQuery, setSearchQuery] = useState("");
  const [isSearching, setIsSearching] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);

  const areaSqM = calculatePolygonAreaSqM(polygonPoints);
  const areaHa = Number((areaSqM / 10000).toFixed(3));
  const perimeterMeters = Number(calculatePerimeterMeters(polygonPoints).toFixed(1));

  // Refs for callbacks to prevent infinite re-render loops
  const onPolygonChangeRef = useRef(onPolygonChange);
  const onCenterChangeRef = useRef(onCenterChange);

  useEffect(() => {
    onPolygonChangeRef.current = onPolygonChange;
    onCenterChangeRef.current = onCenterChange;
  });

  // Safe notify parent component on polygon update
  useEffect(() => {
    onPolygonChangeRef.current?.(polygonPoints, areaHa, perimeterMeters);
  }, [polygonPoints, areaHa, perimeterMeters]);

  // Safe notify parent on center update
  useEffect(() => {
    onCenterChangeRef.current?.(centerPos.lat, centerPos.lng);
  }, [centerPos.lat, centerPos.lng]);

  // Initialize Map safely
  useEffect(() => {
    if (!mapContainerRef.current || mapRef.current) return;

    // Safe Leaflet Icon setup
    try {
      if (L?.Icon?.Default?.prototype) {
        delete (L.Icon.Default.prototype as any)._getIconUrl;
        L.Icon.Default.mergeOptions({
          iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png",
          iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png",
          shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png",
        });
      }
    } catch {
      // Ignore if icon prototype modification is non-configurable
    }

    const map = L.map(mapContainerRef.current, {
      center: [initialLat, initialLng],
      zoom: 16,
      zoomControl: false,
    });

    // Custom zoom control in bottom right
    L.control.zoom({ position: "bottomright" }).addTo(map);

    // Initial tile layer
    const layerCfg = TILE_LAYERS[activeLayer];
    const tileLayer = L.tileLayer(layerCfg.url, {
      maxZoom: layerCfg.maxZoom || 19,
      maxNativeZoom: layerCfg.maxNativeZoom || 18,
      attribution: layerCfg.attribution,
    }).addTo(map);

    tileLayerRef.current = tileLayer;
    mapRef.current = map;

    // Center marker
    const cMarker = L.marker([initialLat, initialLng], {
      draggable: true,
      icon: L.divIcon({
        className: "custom-center-pin",
        html: `<div style="background-color:#059669;width:24px;height:24px;border-radius:50%;border:3px solid #ffffff;box-shadow:0 4px 12px rgba(0,0,0,0.4);display:flex;align-items:center;justify-content:center;color:#ffffff;font-weight:bold;font-size:11px;">📍</div>`,
        iconSize: [24, 24],
        iconAnchor: [12, 12],
      }),
    }).addTo(map);

    cMarker.on("dragend", () => {
      const p = cMarker.getLatLng();
      setCenterPos({ lat: Number(p.lat.toFixed(6)), lng: Number(p.lng.toFixed(6)) });
    });

    centerMarkerRef.current = cMarker;

    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, []);

  // Update Tile Layer
  useEffect(() => {
    if (!mapRef.current || !tileLayerRef.current) return;
    mapRef.current.removeLayer(tileLayerRef.current);

    const layerCfg = TILE_LAYERS[activeLayer];
    const newTileLayer = L.tileLayer(layerCfg.url, {
      maxZoom: layerCfg.maxZoom || 19,
      maxNativeZoom: layerCfg.maxNativeZoom || 18,
      attribution: layerCfg.attribution,
    }).addTo(mapRef.current);

    tileLayerRef.current = newTileLayer;
  }, [activeLayer]);

  // Render Polygon and Vertex Markers
  const renderPolygonOnMap = useCallback(() => {
    if (!mapRef.current) return;
    const map = mapRef.current;

    // Remove old polygon
    if (polygonLayerRef.current) {
      map.removeLayer(polygonLayerRef.current);
      polygonLayerRef.current = null;
    }

    // Remove old vertex markers
    vertexMarkersRef.current.forEach((m) => map.removeLayer(m));
    vertexMarkersRef.current = [];

    if (polygonPoints.length === 0) return;

    // Draw Polygon shape
    const latLngs = polygonPoints.map((p) => [p.lat, p.lng] as [number, number]);
    if (polygonPoints.length >= 3) {
      const poly = L.polygon(latLngs, {
        color: "#10B981",
        weight: 3,
        fillColor: "#059669",
        fillOpacity: 0.35,
        dashArray: "4, 4",
      }).addTo(map);

      polygonLayerRef.current = poly;
    } else if (polygonPoints.length === 2) {
      const poly = L.polyline(latLngs, {
        color: "#10B981",
        weight: 3,
        dashArray: "4, 4",
      }).addTo(map);
      polygonLayerRef.current = poly as any;
    }

    // Draw editable vertex markers
    polygonPoints.forEach((pt, idx) => {
      const vMarker = L.marker([pt.lat, pt.lng], {
        draggable: true,
        icon: L.divIcon({
          className: "polygon-vertex-node",
          html: `<div style="background:#ffffff;border:3px solid #10B981;width:14px;height:14px;border-radius:50%;box-shadow:0 2px 6px rgba(0,0,0,0.3);cursor:grab;"></div>`,
          iconSize: [14, 14],
          iconAnchor: [7, 7],
        }),
      }).addTo(map);

      vMarker.on("dragend", () => {
        const newPos = vMarker.getLatLng();
        setPolygonPoints((prev) =>
          prev.map((p, i) => (i === idx ? { lat: Number(newPos.lat.toFixed(6)), lng: Number(newPos.lng.toFixed(6)) } : p))
        );
      });

      vertexMarkersRef.current.push(vMarker);
    });
  }, [polygonPoints]);

  useEffect(() => {
    renderPolygonOnMap();
  }, [polygonPoints, renderPolygonOnMap]);

  // Handle Map Click
  useEffect(() => {
    if (!mapRef.current) return;
    const map = mapRef.current;

    const handleMapClick = (e: L.LeafletMouseEvent) => {
      const lat = Number(e.latlng.lat.toFixed(6));
      const lng = Number(e.latlng.lng.toFixed(6));

      if (activeTool === "center") {
        setCenterPos({ lat, lng });
        if (centerMarkerRef.current) {
          centerMarkerRef.current.setLatLng([lat, lng]);
        }
      } else if (activeTool === "polygon") {
        setPolygonPoints((prev) => [...prev, { lat, lng }]);
      }
    };

    map.on("click", handleMapClick);
    return () => {
      map.off("click", handleMapClick);
    };
  }, [activeTool]);

  // Geolocation Auto-Detect
  const handleAutoLocate = () => {
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const lat = Number(pos.coords.latitude.toFixed(6));
          const lng = Number(pos.coords.longitude.toFixed(6));
          setCenterPos({ lat, lng });

          if (mapRef.current) {
            mapRef.current.flyTo([lat, lng], 17);
          }
          if (centerMarkerRef.current) {
            centerMarkerRef.current.setLatLng([lat, lng]);
          }
        },
        () => {
          alert("Không thể tự động lấy vị trí GPS hiện tại. Vui lòng cho phép quyền vị trí trên trình duyệt.");
        }
      );
    }
  };

  // Search Address Location
  const handleSearchAddress = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!searchQuery.trim()) return;

    setIsSearching(true);
    try {
      const res = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(searchQuery)}`
      );
      const data = await res.json();
      if (data && data.length > 0) {
        const first = data[0];
        const lat = Number(parseFloat(first.lat).toFixed(6));
        const lng = Number(parseFloat(first.lon).toFixed(6));

        setCenterPos({ lat, lng });
        if (mapRef.current) {
          mapRef.current.flyTo([lat, lng], 16);
        }
        if (centerMarkerRef.current) {
          centerMarkerRef.current.setLatLng([lat, lng]);
        }
      } else {
        alert("Không tìm thấy địa điểm. Vui lòng thử nhập tên Tỉnh/Huyện/Xã cụ thể hơn.");
      }
    } catch {
      alert("Lỗi tìm kiếm vị trí. Vui lòng thử lại.");
    } finally {
      setIsSearching(false);
    }
  };

  const handleUndoPoint = () => {
    setPolygonPoints((prev) => prev.slice(0, prev.length - 1));
  };

  const handleClearPolygon = () => {
    setPolygonPoints([]);
  };

  return (
    <div
      className={`relative rounded-[22px] overflow-hidden border border-gray-200 shadow-md bg-white flex flex-col transition-all duration-300 ${
        isFullscreen ? "fixed inset-4 z-[9999] shadow-2xl bg-white" : "w-full"
      }`}
    >
      {/* Top Bar Controls */}
      <div className="p-3 bg-gray-50 border-b border-gray-200/80 flex flex-wrap items-center justify-between gap-3 text-xs">
        {/* Tool Mode Switcher */}
        <div className="flex items-center gap-1.5 bg-gray-200/70 p-1 rounded-[12px] font-bold">
          <button
            type="button"
            onClick={() => setActiveTool("polygon")}
            className={`px-3 py-1.5 rounded-[9px] flex items-center gap-1.5 transition-all cursor-pointer ${
              activeTool === "polygon" ? "bg-emerald-600 text-white shadow-sm" : "text-gray-700 hover:text-gray-900"
            }`}
          >
            <Pencil className="w-3.5 h-3.5" />
            <span>Vẽ Ranh Giới (Polygon)</span>
          </button>
          <button
            type="button"
            onClick={() => setActiveTool("center")}
            className={`px-3 py-1.5 rounded-[9px] flex items-center gap-1.5 transition-all cursor-pointer ${
              activeTool === "center" ? "bg-emerald-600 text-white shadow-sm" : "text-gray-700 hover:text-gray-900"
            }`}
          >
            <MapPin className="w-3.5 h-3.5" />
            <span>Đánh Dấu Tâm Trang Trại</span>
          </button>
        </div>

        {/* Layer Switcher Dropdown */}
        <div className="flex items-center gap-2">
          <div className="flex items-center gap-1 bg-white border border-gray-200 rounded-[12px] p-1 font-bold">
            <Layers className="w-3.5 h-3.5 text-gray-500 ml-1.5" />
            {(["satellite", "osm", "terrain"] as const).map((layerKey) => (
              <button
                key={layerKey}
                type="button"
                onClick={() => setActiveLayer(layerKey)}
                className={`px-2.5 py-1 rounded-[8px] transition-all cursor-pointer ${
                  activeLayer === layerKey ? "bg-gray-900 text-white shadow-2xs" : "text-gray-600 hover:bg-gray-100"
                }`}
              >
                {layerKey === "satellite" ? "🛰️ Vệ Tinh" : layerKey === "osm" ? "🗺️ Bản Đồ" : "⛰️ Địa Hình"}
              </button>
            ))}
          </div>

          <button
            type="button"
            onClick={() => setIsFullscreen(!isFullscreen)}
            className="p-2 rounded-[12px] bg-white border border-gray-200 text-gray-700 hover:bg-gray-100 transition-all cursor-pointer"
            title={isFullscreen ? "Thu nhỏ" : "Toàn màn hình"}
          >
            {isFullscreen ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
          </button>
        </div>
      </div>

      {/* Address Search Bar */}
      <div className="p-3 bg-white border-b border-gray-100 flex flex-wrap items-center justify-between gap-3">
        <form onSubmit={handleSearchAddress} className="flex items-center gap-2 flex-1 min-w-[280px]">
          <div className="relative flex-1">
            <Search className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Nhập tên địa chỉ / Tỉnh / Huyện để tìm vị trí trên bản đồ..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-9 pr-3 py-1.5 text-xs font-semibold bg-gray-50 border border-gray-200 rounded-[10px] focus:outline-none focus:ring-2 focus:ring-emerald-400"
            />
          </div>
          <button
            type="submit"
            disabled={isSearching}
            className="px-3.5 py-1.5 bg-gray-900 hover:bg-black text-white font-extrabold text-xs rounded-[10px] transition-all cursor-pointer whitespace-nowrap"
          >
            {isSearching ? "Đang tìm..." : "Tìm Kiếm"}
          </button>
        </form>

        <button
          type="button"
          onClick={handleAutoLocate}
          className="px-3 py-1.5 bg-emerald-50 hover:bg-emerald-100 text-emerald-800 border border-emerald-200 font-extrabold text-xs rounded-[10px] transition-all cursor-pointer flex items-center gap-1.5 whitespace-nowrap"
        >
          <Navigation className="w-3.5 h-3.5 text-emerald-600" />
          <span>GPS Hiện Tại</span>
        </button>
      </div>

      {/* Main Map Container */}
      <div className="relative w-full h-[380px] bg-gray-100">
        <div ref={mapContainerRef} className="w-full h-full" />

        {/* Live Drawing Instructions Overlay */}
        <div className="absolute top-3 left-3 z-[1000] bg-white/90 backdrop-blur-md p-2.5 rounded-[14px] border border-gray-200 shadow-md text-xs font-semibold text-gray-800 space-y-1 max-w-xs pointer-events-none">
          <p className="font-extrabold text-emerald-800 flex items-center gap-1">
            <Sparkles className="w-3.5 h-3.5 text-amber-500" />
            {activeTool === "polygon" ? "Chế độ: Vẽ ranh giới Polygon" : "Chế độ: Định vị Tâm trang trại"}
          </p>
          <p className="text-[11px] text-gray-600 leading-tight">
            {activeTool === "polygon"
              ? "Click chọn các điểm góc trên bản đồ để bao quanh toàn bộ ranh giới khu đất vườn."
              : "Click hoặc kéo ghim đỏ đến vị trí trung tâm của vườn."}
          </p>
        </div>

        {/* Polygon Polygon Quick Actions Floating Bar */}
        {activeTool === "polygon" && (
          <div className="absolute bottom-4 left-4 z-[1000] bg-white/95 backdrop-blur-md p-2 rounded-[14px] border border-gray-200 shadow-lg flex items-center gap-2 text-xs">
            <button
              type="button"
              onClick={handleUndoPoint}
              disabled={polygonPoints.length === 0}
              className="px-2.5 py-1.5 bg-gray-100 hover:bg-gray-200 disabled:opacity-40 text-gray-700 font-bold rounded-[8px] flex items-center gap-1 transition-all cursor-pointer"
            >
              <Undo2 className="w-3.5 h-3.5" />
              <span>Hoàn tác</span>
            </button>
            <button
              type="button"
              onClick={handleClearPolygon}
              disabled={polygonPoints.length === 0}
              className="px-2.5 py-1.5 bg-red-50 hover:bg-red-100 disabled:opacity-40 text-red-700 font-bold rounded-[8px] flex items-center gap-1 transition-all cursor-pointer"
            >
              <Trash2 className="w-3.5 h-3.5" />
              <span>Xóa ranh giới</span>
            </button>
          </div>
        )}
      </div>

      {/* Realtime GIS Metric Calculation Bar */}
      <div className="p-3 bg-emerald-950 text-white flex flex-wrap items-center justify-between gap-3 text-xs">
        <div className="flex items-center gap-4 flex-wrap">
          <div className="flex items-center gap-1.5">
            <span className="text-emerald-300 font-semibold">Tâm trang trại:</span>
            <strong className="text-white font-mono">
              {centerPos.lat.toFixed(4)}, {centerPos.lng.toFixed(4)}
            </strong>
          </div>

          <div className="flex items-center gap-1.5 border-l border-emerald-800 pl-4">
            <span className="text-emerald-300 font-semibold">Diện tích thực tế (GIS):</span>
            <strong className="text-amber-300 font-black text-sm">{areaHa} ha</strong>
            <span className="text-[10px] text-emerald-200">({areaSqM.toLocaleString("vi-VN")} m²)</span>
          </div>

          <div className="flex items-center gap-1.5 border-l border-emerald-800 pl-4">
            <span className="text-emerald-300 font-semibold">Chu vi ranh giới:</span>
            <strong className="text-teal-200 font-bold">{perimeterMeters.toLocaleString("vi-VN")} m</strong>
          </div>
        </div>

        <div className="flex items-center gap-1 text-[11px] text-emerald-200 font-semibold">
          <CheckCircle2 className="w-4 h-4 text-emerald-400" />
          <span>{polygonPoints.length} điểm ranh giới Polygon</span>
        </div>
      </div>
    </div>
  );
}
