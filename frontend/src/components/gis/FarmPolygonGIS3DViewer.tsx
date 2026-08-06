import { useEffect, useRef, useState } from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { RotateCcw } from "lucide-react";

interface LatLngPoint {
  lat: number;
  lng: number;
}

export interface FarmPolygonItem {
  value: string;
  label: string;
  gps_lat?: number;
  gps_lng?: number;
  boundary_points?: LatLngPoint[];
  calculated_area_hectare?: number;
  calculated_perimeter_meters?: number;
  elevation_msl_meters?: number;
  slope_gradient_percent?: number;
  slope_aspect_heading?: string;
  soil_texture_type?: string;
}

interface FarmPolygonGIS3DViewerProps {
  boundaryPoints?: LatLngPoint[];
  centerLat?: number;
  centerLng?: number;
  farmName?: string;
  areaHectare?: number;
  perimeterMeters?: number;
  elevationMsl?: number;
  slopePercent?: number;
  slopeAspect?: string;
  soilType?: string;
  farms?: FarmPolygonItem[];
  selectedFarmId?: string;
}

const TILE_LAYERS = {
  satellite: {
    name: "Vệ tinh 3D (Esri)",
    url: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
    attribution: "&copy; Esri &mdash; High-Res 3D Satellite Imagery",
  },
  terrain: {
    name: "Địa hình 3D (Esri Topo)",
    url: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}",
    attribution: "&copy; Esri Topo & Elevation Shading",
  },
  osm: {
    name: "Bản đồ Giao thông 3D",
    url: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    attribution: "&copy; OpenStreetMap contributors",
  },
};

const POLYGON_COLORS = [
  { stroke: "#10B981", fill: "#059669" }, // Emerald Green
  { stroke: "#3B82F6", fill: "#2563EB" }, // Royal Blue
  { stroke: "#F59E0B", fill: "#D97706" }, // Amber Gold
  { stroke: "#8B5CF6", fill: "#7C3AED" }, // Purple
  { stroke: "#EC4899", fill: "#DB2777" }, // Pink
  { stroke: "#14B8A6", fill: "#0D9488" }, // Teal
];

export default function FarmPolygonGIS3DViewer({
  boundaryPoints,
  centerLat,
  centerLng,
  farmName = "Trang trại Sầu Riêng",
  areaHectare,
  perimeterMeters,
  elevationMsl = 520,
  slopePercent = 8.5,
  slopeAspect = "Đông - Đông Nam",
  soilType = "Đất đỏ Bazan nguyên sinh",
  farms = [],
  selectedFarmId = "all",
}: FarmPolygonGIS3DViewerProps) {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const tileLayerRef = useRef<L.TileLayer | null>(null);

  const [activeLayer, setActiveLayer] = useState<"satellite" | "terrain" | "osm">("satellite");

  // Fix Leaflet marker icons
  useEffect(() => {
    delete (L.Icon.Default.prototype as any)._getIconUrl;
    L.Icon.Default.mergeOptions({
      iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png",
      iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png",
      shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png",
    });
  }, []);

  const resetMapView = () => {
    if (!mapRef.current) return;
    mapRef.current.invalidateSize();

    const validFarms: FarmPolygonItem[] = farms.filter(
      (f) => f.value !== "all" && f.boundary_points && f.boundary_points.length >= 3
    );

    if (selectedFarmId && selectedFarmId !== "all") {
      const selected = validFarms.find((f) => f.value === selectedFarmId);
      if (selected && selected.boundary_points && selected.boundary_points.length >= 3) {
        const bounds = L.latLngBounds(selected.boundary_points.map((p) => [p.lat, p.lng]));
        mapRef.current.fitBounds(bounds, { padding: [50, 50], maxZoom: 18 });
        return;
      }
    }

    const allPts: [number, number][] = [];
    validFarms.forEach((f) => {
      f.boundary_points?.forEach((p) => allPts.push([p.lat, p.lng]));
    });

    if (allPts.length > 0) {
      mapRef.current.fitBounds(L.latLngBounds(allPts), { padding: [50, 50], maxZoom: 17 });
    } else if (boundaryPoints && boundaryPoints.length >= 3) {
      const bounds = L.latLngBounds(boundaryPoints.map((p) => [p.lat, p.lng]));
      mapRef.current.fitBounds(bounds, { padding: [50, 50], maxZoom: 18 });
    }
  };

  // Initialize Leaflet Map and render polygons
  useEffect(() => {
    if (!mapContainerRef.current) return;
    if (mapRef.current) {
      mapRef.current.remove();
      mapRef.current = null;
    }

    // Determine list of farms to display
    let farmListToRender: FarmPolygonItem[] = farms.filter(
      (f) => f.value !== "all" && f.boundary_points && f.boundary_points.length >= 3
    );

    // Fallback single farm if no farms list provided
    if (farmListToRender.length === 0 && boundaryPoints && boundaryPoints.length >= 3) {
      farmListToRender = [
        {
          value: "single",
          label: farmName,
          gps_lat: centerLat || boundaryPoints[0].lat,
          gps_lng: centerLng || boundaryPoints[0].lng,
          boundary_points: boundaryPoints,
          calculated_area_hectare: areaHectare,
          calculated_perimeter_meters: perimeterMeters,
          elevation_msl_meters: elevationMsl,
          slope_gradient_percent: slopePercent,
          slope_aspect_heading: slopeAspect,
          soil_texture_type: soilType,
        },
      ];
    }

    let startLat = centerLat || 12.6851;
    let startLng = centerLng || 108.0387;

    if (farmListToRender.length > 0) {
      const first = farmListToRender[0];
      startLat = first.gps_lat || (first.boundary_points ? first.boundary_points[0].lat : startLat);
      startLng = first.gps_lng || (first.boundary_points ? first.boundary_points[0].lng : startLng);
    }

    const map = L.map(mapContainerRef.current, {
      center: [startLat, startLng],
      zoom: 15,
      zoomControl: false,
    });

    L.control.zoom({ position: "bottomright" }).addTo(map);

    const layerCfg = TILE_LAYERS[activeLayer];
    const tileLayer = L.tileLayer(layerCfg.url, {
      maxZoom: 19,
      maxNativeZoom: 19,
      attribution: layerCfg.attribution,
    }).addTo(map);

    tileLayerRef.current = tileLayer;
    mapRef.current = map;

    const allPts: [number, number][] = [];

    // Draw polygons for ALL farms
    farmListToRender.forEach((farm, idx) => {
      if (!farm.boundary_points || farm.boundary_points.length < 3) return;

      const latLngs: [number, number][] = farm.boundary_points.map((p) => {
        allPts.push([p.lat, p.lng]);
        return [p.lat, p.lng];
      });

      const colorScheme = POLYGON_COLORS[idx % POLYGON_COLORS.length];
      const isSelected = selectedFarmId !== "all" && farm.value === selectedFarmId;

      const poly = L.polygon(latLngs, {
        color: isSelected ? "#EF4444" : colorScheme.stroke,
        weight: isSelected ? 4.5 : 3.5,
        fillColor: isSelected ? "#DC2626" : colorScheme.fill,
        fillOpacity: isSelected ? 0.5 : 0.35,
        dashArray: isSelected ? undefined : "6, 6",
      }).addTo(map);

      const popupHtml = `
        <div style="font-family: system-ui, sans-serif; padding: 4px; min-width: 190px;">
          <div style="font-weight: 800; font-size: 13px; color: #111827; margin-bottom: 6px; border-bottom: 1.5px solid ${colorScheme.stroke}; padding-bottom: 4px;">
            📍 ${farm.label}
          </div>
          <div style="font-size: 11px; color: #374151; line-height: 1.6;">
            <div>📐 <strong>Diện tích:</strong> ${farm.calculated_area_hectare || "N/A"} ha</div>
            <div>📏 <strong>Chu vi:</strong> ${farm.calculated_perimeter_meters || "N/A"} m</div>
            <div>⛰️ <strong>Độ cao MSL:</strong> ${farm.elevation_msl_meters || 520} m</div>
            <div>🌱 <strong>Thổ nhưỡng:</strong> ${farm.soil_texture_type?.split("(")[0] || "Đất đỏ Bazan"}</div>
          </div>
        </div>
      `;
      poly.bindPopup(popupHtml);

      // Farm Center Marker & Label Badge
      const bounds = poly.getBounds();
      const center = bounds.getCenter();

      const centerPin = L.divIcon({
        className: "custom-farm-pin-gis",
        html: `
          <div style="
            background: linear-gradient(135deg, ${colorScheme.fill}, ${colorScheme.stroke});
            color: #ffffff;
            padding: 4px 10px;
            border-radius: 12px;
            border: 2px solid #ffffff;
            box-shadow: 0 4px 12px rgba(0,0,0,0.5);
            font-size: 11px;
            font-weight: 800;
            white-space: nowrap;
            display: flex;
            align-items: center;
            gap: 4px;
            transform: translate(-50%, -50%);
            cursor: pointer;
          ">
            <span>📍 ${farm.label}</span>
          </div>
        `,
        iconSize: [0, 0],
        iconAnchor: [0, 0],
      });

      const marker = L.marker([center.lat, center.lng], { icon: centerPin }).addTo(map);
      marker.bindPopup(popupHtml);

      // Render vertex markers if selected or few farms
      if (farmListToRender.length <= 2 || isSelected) {
        farm.boundary_points.forEach((pt, vIdx) => {
          L.marker([pt.lat, pt.lng], {
            icon: L.divIcon({
              className: "polygon-vertex-icon-gis",
              html: `<div style="background:#ffffff;border:2.5px solid ${colorScheme.stroke};width:16px;height:16px;border-radius:50%;box-shadow:0 2px 6px rgba(0,0,0,0.4);display:flex;align-items:center;justify-content:center;color:${colorScheme.fill};font-size:9px;font-weight:bold;">${vIdx + 1}</div>`,
              iconSize: [16, 16],
              iconAnchor: [8, 8],
            }),
          }).addTo(map).bindTooltip(`${farm.label} - Mốc #${vIdx + 1}`, { permanent: false, direction: "top" });
        });
      }
    });

    // Auto-fit bounds
    setTimeout(() => {
      if (mapRef.current) {
        mapRef.current.invalidateSize();

        if (selectedFarmId !== "all") {
          const selected = farmListToRender.find((f) => f.value === selectedFarmId);
          if (selected && selected.boundary_points) {
            const selectedBounds = L.latLngBounds(selected.boundary_points.map((p) => [p.lat, p.lng]));
            mapRef.current.fitBounds(selectedBounds, { padding: [50, 50], maxZoom: 18 });
            return;
          }
        }

        if (allPts.length > 0) {
          mapRef.current.fitBounds(L.latLngBounds(allPts), { padding: [50, 50], maxZoom: 17 });
        }
      }
    }, 150);

    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, [boundaryPoints, farms, selectedFarmId, centerLat, centerLng]);

  // Handle Layer Switch
  useEffect(() => {
    if (!mapRef.current || !tileLayerRef.current) return;
    mapRef.current.removeLayer(tileLayerRef.current);

    const layerCfg = TILE_LAYERS[activeLayer];
    const newTileLayer = L.tileLayer(layerCfg.url, {
      maxZoom: 19,
      maxNativeZoom: 19,
      attribution: layerCfg.attribution,
    }).addTo(mapRef.current);

    tileLayerRef.current = newTileLayer;
  }, [activeLayer]);

  return (
    <div className="relative w-full h-full min-h-[460px] rounded-[20px] overflow-hidden border border-emerald-900/30 shadow-lg bg-emerald-950">
      {/* DIRECT LEAFLET MAP CONTAINER - CLEAN REAL SATELLITE VIEW */}
      <div ref={mapContainerRef} className="w-full h-full z-0" />

      {/* FLOATING TOP-RIGHT CAMERA CONTROLS & LAYER SWITCHER */}
      <div className="absolute top-3.5 right-3.5 z-[400] flex flex-col items-end gap-2">
        {/* Layer Switcher */}
        <div className="bg-emerald-950/90 text-white backdrop-blur-md p-1 rounded-xl shadow-xl border border-emerald-500/30 flex items-center gap-1 text-[11px] font-bold">
          {(Object.keys(TILE_LAYERS) as Array<keyof typeof TILE_LAYERS>).map((key) => (
            <button
              key={key}
              type="button"
              onClick={() => setActiveLayer(key)}
              className={`px-3 py-1.5 rounded-lg transition-all cursor-pointer ${
                activeLayer === key
                  ? "bg-emerald-600 text-white shadow-sm font-black"
                  : "text-emerald-200/80 hover:text-white hover:bg-emerald-900/70"
              }`}
            >
              {TILE_LAYERS[key].name}
            </button>
          ))}
        </div>

        {/* Reset Viewport Bounds Button */}
        <button
          type="button"
          onClick={resetMapView}
          className="bg-emerald-950/90 hover:bg-emerald-900/90 text-emerald-200 backdrop-blur-md px-3.5 py-1.5 rounded-xl shadow-xl border border-emerald-500/30 flex items-center gap-1.5 text-xs font-bold transition-all cursor-pointer hover:scale-105 active:scale-95"
        >
          <RotateCcw className="w-3.5 h-3.5 text-emerald-400" />
          <span>{selectedFarmId === "all" ? "Zoom xem tất cả nông trại" : "Zoom về Ranh giới Vườn"}</span>
        </button>
      </div>
    </div>
  );
}
