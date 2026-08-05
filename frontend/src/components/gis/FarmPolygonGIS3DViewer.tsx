import { useEffect, useRef, useState } from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import { Mountain, Compass, Layers, RotateCcw, Box } from "lucide-react";

interface LatLngPoint {
  lat: number;
  lng: number;
}

interface FarmPolygonGIS3DViewerProps {
  boundaryPoints: LatLngPoint[];
  centerLat?: number;
  centerLng?: number;
  farmName?: string;
  areaHectare?: number;
  perimeterMeters?: number;
  elevationMsl?: number;
  slopePercent?: number;
  slopeAspect?: string;
  soilType?: string;
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
}: FarmPolygonGIS3DViewerProps) {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const tileLayerRef = useRef<L.TileLayer | null>(null);
  const polygonRef = useRef<L.Polygon | null>(null);

  const [activeLayer, setActiveLayer] = useState<"satellite" | "terrain" | "osm">("satellite");
  const [pitch, setPitch] = useState<number>(45); // 3D Pitch tilt angle in degrees
  const [bearing, setBearing] = useState<number>(15); // 3D Rotation bearing in degrees
  const [showMesh, setShowMesh] = useState<boolean>(true);

  // Fix Leaflet marker icons
  useEffect(() => {
    delete (L.Icon.Default.prototype as any)._getIconUrl;
    L.Icon.Default.mergeOptions({
      iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png",
      iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png",
      shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png",
    });
  }, []);

  const initialLat = centerLat || (boundaryPoints.length > 0 ? boundaryPoints[0].lat : 12.6667);
  const initialLng = centerLng || (boundaryPoints.length > 0 ? boundaryPoints[0].lng : 108.0500);

  // Initialize Leaflet Map
  useEffect(() => {
    if (!mapContainerRef.current) return;
    if (mapRef.current) {
      mapRef.current.remove();
      mapRef.current = null;
    }

    const map = L.map(mapContainerRef.current, {
      center: [initialLat, initialLng],
      zoom: 16,
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

    // Draw Polygon if points exist
    if (boundaryPoints && boundaryPoints.length >= 3) {
      const latLngs: [number, number][] = boundaryPoints.map((p) => [p.lat, p.lng]);
      const poly = L.polygon(latLngs, {
        color: "#10B981",
        weight: 3.5,
        fillColor: "#059669",
        fillOpacity: 0.35,
        dashArray: "6, 6",
      }).addTo(map);

      polygonRef.current = poly;

      // Add vertex marker pins
      boundaryPoints.forEach((pt, idx) => {
        L.marker([pt.lat, pt.lng], {
          icon: L.divIcon({
            className: "polygon-vertex-icon-gis",
            html: `<div style="background:#ffffff;border:3px solid #10B981;width:18px;height:18px;border-radius:50%;box-shadow:0 3px 8px rgba(0,0,0,0.5);display:flex;align-items:center;justify-content:center;color:#059669;font-size:10px;font-weight:bold;">${idx + 1}</div>`,
            iconSize: [18, 18],
            iconAnchor: [9, 9],
          }),
        }).addTo(map).bindTooltip(`Góc mốc #${idx + 1}`, { permanent: false, direction: "top" });
      });

      // Add Center Pin with Badge
      const bounds = poly.getBounds();
      const center = bounds.getCenter();
      L.marker([center.lat, center.lng], {
        icon: L.divIcon({
          className: "custom-center-pin-gis",
          html: `<div style="background:linear-gradient(135deg,#059669,#047857);width:32px;height:32px;border-radius:50%;border:3px solid #ffffff;box-shadow:0 6px 14px rgba(0,0,0,0.6);display:flex;align-items:center;justify-content:center;color:#ffffff;font-size:16px;">📍</div>`,
          iconSize: [32, 32],
          iconAnchor: [16, 16],
        }),
      }).addTo(map).bindTooltip(`Tâm Vườn: ${farmName}<br/>Độ cao MSL: ${elevationMsl}m`, { permanent: false, direction: "top" });

      // Invalidate size and fit bounds tightly after render
      setTimeout(() => {
        if (mapRef.current) {
          mapRef.current.invalidateSize();
          mapRef.current.fitBounds(poly.getBounds(), { padding: [50, 50], maxZoom: 18 });
        }
      }, 150);
    } else {
      setTimeout(() => {
        if (mapRef.current) {
          mapRef.current.invalidateSize();
        }
      }, 150);
    }

    return () => {
      map.remove();
      mapRef.current = null;
    };
  }, [boundaryPoints, initialLat, initialLng]);

  // Handle Layer Toggle
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

  const handleResetBounds = () => {
    if (mapRef.current && polygonRef.current) {
      mapRef.current.invalidateSize();
      mapRef.current.fitBounds(polygonRef.current.getBounds(), { padding: [50, 50], maxZoom: 18 });
    }
  };

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
          onClick={handleResetBounds}
          className="bg-emerald-950/90 hover:bg-emerald-900/90 text-emerald-200 backdrop-blur-md px-3.5 py-1.5 rounded-xl shadow-xl border border-emerald-500/30 flex items-center gap-1.5 text-xs font-bold transition-all cursor-pointer hover:scale-105 active:scale-95"
        >
          <RotateCcw className="w-3.5 h-3.5 text-emerald-400" />
          <span>Zoom về Ranh giới Vườn</span>
        </button>
      </div>
    </div>
  );
}
