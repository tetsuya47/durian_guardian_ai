import { useState, useMemo } from "react";
import { Link } from "react-router-dom";
import { Maximize2, Minimize2, RefreshCw, Map, Grid, MapPinOff, PlusCircle } from "lucide-react";
import Card from "./Shared/Card";
import HeatmapGrid from "./HeatmapGrid";
import FarmPolygonGIS3DViewer from "../gis/FarmPolygonGIS3DViewer";
import type { ZoneSection } from "./HeatmapGrid";

export interface ExtendedFarmOption {
  value: string;
  label: string;
  gps_lat?: number;
  gps_lng?: number;
  boundary_points?: { lat: number; lng: number }[];
  calculated_area_hectare?: number;
  calculated_perimeter_meters?: number;
  elevation_msl_meters?: number;
  slope_gradient_percent?: number;
  slope_aspect_heading?: string;
  soil_texture_type?: string;
}

interface HeatmapCardProps {
  sections: ZoneSection[];
  lastUpdated: string;
  summaryCounts: { healthy: number; monitor: number; diseased: number };
  onRefresh?: () => void;
  farmOptions?: ExtendedFarmOption[];
  zoneOptions?: { value: string; label: string }[];
  selectedFarm?: string;
  selectedZone?: string;
  onFarmChange?: (value: string) => void;
  onZoneChange?: (value: string) => void;
}

const RISK_TIER_LEGENDS = [
  { label: "Khỏe mạnh (0 - 30%)", color: "bg-[#22C55E]" },
  { label: "Cảnh báo (30 - 60%)", color: "bg-[#EAB308]" },
  { label: "Rủi ro cao (60 - 80%)", color: "bg-[#F97316]" },
  { label: "Nguy hiểm (> 80%)", color: "bg-[#EF4444]" },
];

export default function HeatmapCard({
  sections,
  lastUpdated,
  summaryCounts,
  onRefresh,
  farmOptions = [],
  zoneOptions = [],
  selectedFarm = "all",
  selectedZone = "all",
  onFarmChange,
  onZoneChange,
}: HeatmapCardProps) {
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [viewMode, setViewMode] = useState<"gis" | "grid">("gis");

  // Determine active farm data - PRIORITIZES USER'S REGISTERED FARM REAL DATA
  const activeFarm = useMemo(() => {
    const savedFarmId = localStorage.getItem("dga_active_registered_farm_id");
    if (savedFarmId) {
      const matched = farmOptions.find((f) => f.value === savedFarmId);
      if (matched && matched.boundary_points && matched.boundary_points.length >= 3) {
        return matched;
      }
    }
    if (selectedFarm !== "all") {
      return farmOptions.find((f) => f.value === selectedFarm) || null;
    }
    // Find first farm with boundary points (user-owned farm is placed first by API)
    return farmOptions.find((f) => f.boundary_points && f.boundary_points.length >= 3) || farmOptions[0] || null;
  }, [farmOptions, selectedFarm]);

  const hasGISBoundary = useMemo(() => {
    return Boolean(activeFarm && activeFarm.boundary_points && activeFarm.boundary_points.length >= 3);
  }, [activeFarm]);

  return (
    <Card
      className={`flex flex-col transition-all duration-300 ${
        isFullscreen ? "fixed inset-4 z-[9999] shadow-2xl rounded-[24px] bg-white border border-gray-200" : "h-full min-h-[580px]"
      }`}
      padding={false}
      style={{ overflow: "hidden" }}
    >
      <div className="flex flex-col flex-1 min-h-0 p-4 space-y-3">
        {/* ROW 1: TITLE & ACTION BUTTONS */}
        <div className="flex items-center justify-between gap-3 pb-2 border-b border-gray-100">
          <div className="flex items-center gap-2">
            <h2 className="text-sm sm:text-base font-black text-gray-900 tracking-tight uppercase truncate">
              BẢN ĐỒ NHIỆT RỦI RO DỊCH BỆNH (HEATMAP)
            </h2>
            {hasGISBoundary && (
              <span className="text-[10px] font-extrabold text-emerald-800 bg-emerald-100 px-2 py-0.5 rounded-full border border-emerald-300">
                GIS Live 3D
              </span>
            )}
          </div>

          <div className="flex items-center gap-1.5 flex-shrink-0">
            {onRefresh && (
              <button
                type="button"
                onClick={onRefresh}
                title="Làm mới bản đồ"
                className="p-1.5 text-gray-400 hover:text-emerald-700 hover:bg-emerald-50 rounded-[10px] transition-all cursor-pointer border border-gray-200/80 shadow-2xs"
              >
                <RefreshCw className="w-3.5 h-3.5" />
              </button>
            )}
            <button
              type="button"
              onClick={() => setIsFullscreen(!isFullscreen)}
              title={isFullscreen ? "Thu nhỏ" : "Toàn màn hình"}
              className="p-1.5 text-gray-500 hover:text-emerald-700 hover:bg-emerald-50 rounded-[10px] transition-all cursor-pointer border border-gray-200/80 shadow-2xs"
            >
              {isFullscreen ? <Minimize2 className="w-3.5 h-3.5" /> : <Maximize2 className="w-3.5 h-3.5" />}
            </button>
          </div>
        </div>

        {/* ROW 2: 3D GIS MAP DISPLAY */}
        <div className="flex-1 min-h-0 relative rounded-[16px] overflow-hidden">
          {hasGISBoundary && activeFarm ? (
            <FarmPolygonGIS3DViewer
              boundaryPoints={activeFarm.boundary_points || []}
              centerLat={activeFarm.gps_lat}
              centerLng={activeFarm.gps_lng}
              farmName={activeFarm.label}
              areaHectare={activeFarm.calculated_area_hectare}
              perimeterMeters={activeFarm.calculated_perimeter_meters}
              elevationMsl={activeFarm.elevation_msl_meters}
              slopePercent={activeFarm.slope_gradient_percent}
              slopeAspect={activeFarm.slope_aspect_heading}
              soilType={activeFarm.soil_texture_type}
            />
          ) : (
            /* EMPTY STATE: USER HAS NOT DRAWN POLYGON MAP YET */
            <div className="w-full h-full min-h-[300px] bg-gradient-to-br from-emerald-50/40 via-gray-50 to-emerald-100/30 border-2 border-dashed border-emerald-200 rounded-[16px] flex flex-col items-center justify-center p-6 text-center space-y-3.5 shadow-inner">
              <div className="w-14 h-14 rounded-2xl bg-emerald-100/80 border border-emerald-300 flex items-center justify-center text-emerald-700 shadow-sm">
                <MapPinOff className="w-7 h-7" />
              </div>
              <div className="max-w-md space-y-1">
                <h3 className="text-base font-extrabold text-gray-900 tracking-tight">
                  Chưa khai báo Ranh giới GIS cho Trang trại này
                </h3>
                <p className="text-xs text-gray-600 leading-relaxed font-medium">
                  Tài khoản/Trang trại <span className="font-bold text-emerald-800">"{activeFarm?.label || "được chọn"}"</span> chưa vẽ ranh giới đất Polygon trên bản đồ vệ tinh. Vui lòng bấm bên dưới để thực hiện vẽ ranh giới thực tế.
                </p>
              </div>
              <Link
                to="/register-farm"
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold text-xs shadow-md transition-all hover:scale-105 active:scale-95"
              >
                <PlusCircle className="w-4 h-4" />
                <span>+ Đăng ký Ranh giới Vườn (GIS Map)</span>
              </Link>
            </div>
          )}
        </div>

        {/* 3D GIS TERRAIN ANALYTICS PANEL (MOVED BELOW MAP) */}
        {hasGISBoundary && activeFarm && (
          <div className="bg-emerald-950 text-white p-3.5 rounded-[16px] border border-emerald-900/60 shadow-md space-y-2.5">
            <div className="flex items-center justify-between border-b border-emerald-800/60 pb-2">
              <div className="flex items-center gap-2 text-xs font-black text-emerald-300 uppercase tracking-wider">
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                <span>PHÂN TÍCH 3D GIS TERRAIN & NÔNG TRẠI</span>
              </div>
              <span className="text-[11px] font-extrabold text-emerald-200 bg-emerald-900/80 px-2.5 py-0.5 rounded-full border border-emerald-700/60">
                🌐 {activeFarm.label}
              </span>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-6 gap-2 text-xs font-bold">
              <div className="bg-emerald-900/50 p-2 rounded-xl border border-emerald-800/60 flex flex-col justify-center">
                <span className="text-emerald-300/80 text-[10px] font-medium">Diện tích</span>
                <span className="text-emerald-100 font-extrabold text-xs">{activeFarm.calculated_area_hectare || 5.85} ha</span>
              </div>
              <div className="bg-emerald-900/50 p-2 rounded-xl border border-emerald-800/60 flex flex-col justify-center">
                <span className="text-cyan-300/80 text-[10px] font-medium">Chu vi</span>
                <span className="text-cyan-100 font-extrabold text-xs">{activeFarm.calculated_perimeter_meters || 985.4} m</span>
              </div>
              <div className="bg-emerald-900/50 p-2 rounded-xl border border-emerald-800/60 flex flex-col justify-center">
                <span className="text-emerald-300/80 text-[10px] font-medium">Độ cao MSL</span>
                <span className="text-emerald-100 font-extrabold text-xs">{activeFarm.elevation_msl_meters || 525} m</span>
              </div>
              <div className="bg-emerald-900/50 p-2 rounded-xl border border-emerald-800/60 flex flex-col justify-center">
                <span className="text-amber-300/80 text-[10px] font-medium">Độ dốc triền</span>
                <span className="text-amber-100 font-extrabold text-xs">{activeFarm.slope_gradient_percent || 8.2} %</span>
              </div>
              <div className="bg-emerald-900/50 p-2 rounded-xl border border-emerald-800/60 flex flex-col justify-center">
                <span className="text-cyan-300/80 text-[10px] font-medium">Hướng triền</span>
                <span className="text-cyan-100 font-extrabold text-xs truncate" title={activeFarm.slope_aspect_heading}>
                  {activeFarm.slope_aspect_heading || "Đông - Đông Nam"}
                </span>
              </div>
              <div className="bg-emerald-900/50 p-2 rounded-xl border border-emerald-800/60 flex flex-col justify-center">
                <span className="text-amber-300/80 text-[10px] font-medium">Thổ nhưỡng</span>
                <span className="text-amber-100 font-extrabold text-xs truncate" title={activeFarm.soil_texture_type}>
                  {activeFarm.soil_texture_type?.split("(")[0] || "Đất đỏ Bazan"}
                </span>
              </div>
            </div>
          </div>
        )}
      </div>
    </Card>
  );
}
