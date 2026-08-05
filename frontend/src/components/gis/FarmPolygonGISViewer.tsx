import { useEffect, useRef, useState } from "react";
import L from "leaflet";
import "leaflet/dist/leaflet.css";

interface LatLngPoint {
  lat: number;
  lng: number;
}

interface FarmPolygonGISViewerProps {
  boundaryPoints: LatLngPoint[];
  centerLat?: number;
  centerLng?: number;
  farmName?: string;
  areaHectare?: number;
  perimeterMeters?: number;
}

const TILE_LAYERS = {
  satellite: {
    name: "Vệ tinh (Esri)",
    url: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}",
    attribution: "&copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS",
  },
  osm: {
    name: "Bản đồ (OSM)",
    url: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    attribution: "&copy; OpenStreetMap contributors",
  },
  terrain: {
    name: "Địa hình (Esri Topo)",
    url: "https://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/tile/{z}/{y}/{x}",
    attribution: "&copy; Esri Topo",
  },
};

export default function FarmPolygonGISViewer({
  boundaryPoints,
  centerLat,
  centerLng,
  farmName = "Trang trại",
  areaHectare,
  perimeterMeters,
}: FarmPolygonGISViewerProps) {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<L.Map | null>(null);
  const tileLayerRef = useRef<L.TileLayer | null>(null);
  const polygonRef = useRef<L.Polygon | null>(null);

  const [activeLayer, setActiveLayer] = useState<"satellite" | "osm" | "terrain">("satellite");

  // Fix Leaflet icons
  useEffect(() => {
    delete (L.Icon.Default.prototype as any)._getIconUrl;
    L.Icon.Default.mergeOptions({
      iconRetinaUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon-2x.png",
      iconUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-icon.png",
      shadowUrl: "https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.7.1/images/marker-shadow.png",
    });
  }, []);

  // Compute map center
  const initialLat = centerLat || (boundaryPoints.length > 0 ? boundaryPoints[0].lat : 12.6667);
  const initialLng = centerLng || (boundaryPoints.length > 0 ? boundaryPoints[0].lng : 108.0500);

  // Initialize map
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
        weight: 3,
        fillColor: "#10B981",
        fillOpacity: 0.35,
        dashArray: "6, 6",
      }).addTo(map);

      polygonRef.current = poly;

      // Fit map bounds to polygon
      map.fitBounds(poly.getBounds(), { padding: [30, 30] });

      // Add vertex marker pins
      boundaryPoints.forEach((pt, idx) => {
        L.marker([pt.lat, pt.lng], {
          icon: L.divIcon({
            className: "polygon-vertex-icon",
            html: `<div style="background:#ffffff;border:2.5px solid #059669;width:12px;height:12px;border-radius:50%;box-shadow:0 2px 6px rgba(0,0,0,0.4);"></div>`,
            iconSize: [12, 12],
            iconAnchor: [6, 6],
          }),
        }).addTo(map).bindTooltip(`Góc Ranh Giới #${idx + 1}`, { permanent: false, direction: "top" });
      });

      // Add Center Pin
      const bounds = poly.getBounds();
      const center = bounds.getCenter();
      L.marker([center.lat, center.lng], {
        icon: L.divIcon({
          className: "custom-center-pin",
          html: `<div style="background-color:#059669;width:22px;height:22px;border-radius:50%;border:2px solid #ffffff;box-shadow:0 4px 10px rgba(0,0,0,0.5);display:flex;align-items:center;justify-content:center;color:#ffffff;font-size:11px;">📍</div>`,
          iconSize: [22, 22],
          iconAnchor: [11, 11],
        }),
      }).addTo(map).bindTooltip(`Tâm Trang Trại: ${farmName}`, { permanent: false, direction: "top" });
    } else {
      // Just a marker at initial Lat/Lng
      L.marker([initialLat, initialLng]).addTo(map).bindTooltip(farmName, { permanent: true });
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

  return (
    <div className="relative w-full h-full min-h-[300px] rounded-[16px] overflow-hidden border border-gray-200 shadow-inner">
      {/* MAP CANVAS */}
      <div ref={mapContainerRef} className="w-full h-full z-0" />

      {/* FLOATING TOP-RIGHT TILE LAYER SWITCHER */}
      <div className="absolute top-3 right-3 z-[400] bg-white/95 backdrop-blur-md p-1 rounded-xl shadow-lg border border-gray-200/90 flex items-center gap-1 text-[11px] font-bold">
        {(Object.keys(TILE_LAYERS) as Array<keyof typeof TILE_LAYERS>).map((key) => (
          <button
            key={key}
            type="button"
            onClick={() => setActiveLayer(key)}
            className={`px-2.5 py-1 rounded-lg transition-all cursor-pointer ${
              activeLayer === key
                ? "bg-emerald-600 text-white shadow-xs font-black"
                : "text-gray-600 hover:text-emerald-700 hover:bg-emerald-50"
            }`}
          >
            {TILE_LAYERS[key].name}
          </button>
        ))}
      </div>

      {/* FLOATING BOTTOM METRICS OVERLAY BAR */}
      <div className="absolute bottom-3 left-3 right-3 z-[400] bg-gray-900/90 text-white backdrop-blur-md px-3 py-2 rounded-xl border border-gray-700/80 flex items-center justify-between flex-wrap gap-2 text-xs font-bold shadow-xl">
        <div className="flex items-center gap-3">
          <span className="flex items-center gap-1 text-emerald-400 font-extrabold">
            <span>🌐 Ranh Giới GIS:</span>
            <span>{farmName}</span>
          </span>
          {areaHectare && (
            <span className="bg-emerald-500/20 text-emerald-300 border border-emerald-500/40 px-2 py-0.5 rounded-md text-[11px]">
              Diện tích: <b>{areaHectare} ha</b>
            </span>
          )}
          {perimeterMeters && (
            <span className="bg-blue-500/20 text-blue-300 border border-blue-500/40 px-2 py-0.5 rounded-md text-[11px]">
              Chu vi: <b>{perimeterMeters} m</b>
            </span>
          )}
        </div>
        <div className="text-[11px] text-gray-300 font-medium">
          {boundaryPoints.length} điểm mốc Polygon
        </div>
      </div>
    </div>
  );
}
