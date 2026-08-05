import { useState, useMemo } from "react";
import { Link } from "react-router-dom";
import {
  Maximize2,
  Minimize2,
  RefreshCw,
  MapPinOff,
  PlusCircle,
  Layers,
  Compass,
  Mountain,
  Activity,
  Navigation,
  Sprout,
  Building2,
} from "lucide-react";
import Card from "./Shared/Card";
import FarmPolygonGIS3DViewer from "../gis/FarmPolygonGIS3DViewer";

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
  sections?: any[];
  lastUpdated?: string;
  summaryCounts?: { healthy: number; monitor: number; diseased: number };
  onRefresh?: () => void;
  farmOptions?: ExtendedFarmOption[];
  zoneOptions?: { value: string; label: string }[];
  selectedFarm?: string;
  selectedZone?: string;
  onFarmChange?: (value: string) => void;
  onZoneChange?: (value: string) => void;
}

export default function HeatmapCard({
  onRefresh,
  farmOptions = [],
  selectedFarm = "all",
}: HeatmapCardProps) {
  const [isFullscreen, setIsFullscreen] = useState(false);

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
    // Find first farm with boundary points
    return farmOptions.find((f) => f.boundary_points && f.boundary_points.length >= 3) || farmOptions[0] || null;
  }, [farmOptions, selectedFarm]);

  const hasGISBoundary = useMemo(() => {
    return Boolean(activeFarm && activeFarm.boundary_points && activeFarm.boundary_points.length >= 3);
  }, [activeFarm]);

  return (
    <Card
      className={`flex flex-col transition-all duration-300 ${
        isFullscreen ? "fixed inset-4 z-[9999] shadow-2xl rounded-[24px] bg-white border border-[#E5E7EB]" : "h-full min-h-[580px]"
      }`}
      padding={false}
      style={{ overflow: "hidden" }}
    >
      <div className="flex flex-col flex-1 min-h-0 p-5 space-y-4">
        {/* ROW 1: TITLE & ACTION BUTTONS */}
        <div className="flex items-center justify-between gap-3 pb-3 border-b border-[#E5E7EB]">
          <div className="flex items-center gap-2">
            <h2 className="text-sm sm:text-base font-bold text-[#111827] tracking-tight uppercase truncate">
              BẢN ĐỒ NHIỆT RỦI RO DỊCH BỆNH (HEATMAP)
            </h2>
            {hasGISBoundary && (
              <span className="text-[11px] font-semibold text-[#10B981] bg-[#D1FAE5] px-2.5 py-0.5 rounded-full">
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
                className="p-2 text-gray-500 hover:text-[#10B981] hover:bg-[#D1FAE5]/40 rounded-[12px] transition-all cursor-pointer border border-[#E5E7EB]"
              >
                <RefreshCw className="w-4 h-4" />
              </button>
            )}
            <button
              type="button"
              onClick={() => setIsFullscreen(!isFullscreen)}
              title={isFullscreen ? "Thu nhỏ" : "Toàn màn hình"}
              className="p-2 text-gray-500 hover:text-[#10B981] hover:bg-[#D1FAE5]/40 rounded-[12px] transition-all cursor-pointer border border-[#E5E7EB]"
            >
              {isFullscreen ? <Minimize2 className="w-4 h-4" /> : <Maximize2 className="w-4 h-4" />}
            </button>
          </div>
        </div>

        {/* ROW 2: 3D GIS MAP DISPLAY */}
        <div className="flex-1 min-h-0 relative rounded-[18px] overflow-hidden border border-[#E5E7EB]">
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
            <div className="w-full h-full min-h-[320px] bg-gradient-to-br from-emerald-50/40 via-gray-50 to-emerald-100/30 border-2 border-dashed border-emerald-200 rounded-[18px] flex flex-col items-center justify-center p-6 text-center space-y-3.5 shadow-inner">
              <div className="w-14 h-14 rounded-2xl bg-emerald-100/80 border border-emerald-300 flex items-center justify-center text-emerald-700 shadow-sm">
                <MapPinOff className="w-7 h-7" />
              </div>
              <div className="max-w-md space-y-1">
                <h3 className="text-base font-bold text-[#111827] tracking-tight">
                  Chưa khai báo Ranh giới GIS cho Trang trại này
                </h3>
                <p className="text-xs text-[#6B7280] leading-relaxed font-medium">
                  Tài khoản/Trang trại <span className="font-bold text-[#10B981]">"{activeFarm?.label || "được chọn"}"</span> chưa vẽ ranh giới đất Polygon trên bản đồ vệ tinh. Vui lòng bấm bên dưới để thực hiện vẽ ranh giới thực tế.
                </p>
              </div>
              <Link
                to="/register-farm"
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-[14px] bg-[#10B981] hover:bg-[#059669] text-white font-semibold text-xs shadow-sm transition-all hover:scale-105 active:scale-95"
              >
                <PlusCircle className="w-4 h-4" />
                <span>+ Đăng ký Ranh giới Vườn (GIS Map)</span>
              </Link>
            </div>
          )}
        </div>

        {/* ── 3D GIS TERRAIN ANALYTICS PANEL (MODERN ENTERPRISE SAAS CARDS) ── */}
        {hasGISBoundary && activeFarm && (
          <div className="bg-[#F8FAFC] p-4 rounded-[20px] border border-[#E5E7EB] shadow-saas space-y-3">
            {/* Header */}
            <div className="flex items-center justify-between border-b border-[#E5E7EB] pb-2.5">
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-[#10B981] animate-pulse" />
                <h3 className="text-xs font-bold text-[#111827] tracking-tight uppercase">
                  PHÂN TÍCH 3D GIS TERRAIN & NÔNG TRẠI
                </h3>
              </div>
              <span className="text-[11px] font-semibold text-[#10B981] bg-[#D1FAE5] px-3 py-0.5 rounded-full border border-emerald-200/80">
                🌐 Trang trại: {activeFarm.label}
              </span>
            </div>

            {/* Individual Clean Metric Cards Grid (Preserves exact content & order) */}
            <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-7 gap-3">
              {/* Metric 1: Diện tích */}
              <div className="bg-white p-3 rounded-[16px] border border-[#E5E7EB] shadow-2xs flex flex-col justify-between space-y-1 hover:-translate-y-0.5 transition-all duration-200">
                <div className="flex items-center gap-1.5 text-[#6B7280]">
                  <Layers className="w-3.5 h-3.5 text-[#10B981]" />
                  <span className="text-[11px] font-medium">Diện tích</span>
                </div>
                <div className="text-sm font-bold text-[#111827]">
                  {activeFarm.calculated_area_hectare || 3.48} <span className="text-xs font-medium text-[#10B981]">ha</span>
                </div>
              </div>

              {/* Metric 2: Chu vi */}
              <div className="bg-white p-3 rounded-[16px] border border-[#E5E7EB] shadow-2xs flex flex-col justify-between space-y-1 hover:-translate-y-0.5 transition-all duration-200">
                <div className="flex items-center gap-1.5 text-[#6B7280]">
                  <Compass className="w-3.5 h-3.5 text-[#10B981]" />
                  <span className="text-[11px] font-medium">Chu vi</span>
                </div>
                <div className="text-sm font-bold text-[#111827]">
                  {activeFarm.calculated_perimeter_meters || 815} <span className="text-xs font-medium text-[#10B981]">m</span>
                </div>
              </div>

              {/* Metric 3: Độ cao MSL */}
              <div className="bg-white p-3 rounded-[16px] border border-[#E5E7EB] shadow-2xs flex flex-col justify-between space-y-1 hover:-translate-y-0.5 transition-all duration-200">
                <div className="flex items-center gap-1.5 text-[#6B7280]">
                  <Mountain className="w-3.5 h-3.5 text-[#10B981]" />
                  <span className="text-[11px] font-medium">Độ cao MSL</span>
                </div>
                <div className="text-sm font-bold text-[#111827]">
                  {activeFarm.elevation_msl_meters || 525} <span className="text-xs font-medium text-[#10B981]">m</span>
                </div>
              </div>

              {/* Metric 4: Độ dốc */}
              <div className="bg-white p-3 rounded-[16px] border border-[#E5E7EB] shadow-2xs flex flex-col justify-between space-y-1 hover:-translate-y-0.5 transition-all duration-200">
                <div className="flex items-center gap-1.5 text-[#6B7280]">
                  <Activity className="w-3.5 h-3.5 text-[#10B981]" />
                  <span className="text-[11px] font-medium">Độ dốc</span>
                </div>
                <div className="text-sm font-bold text-[#111827]">
                  {activeFarm.slope_gradient_percent || 8.2} <span className="text-xs font-medium text-[#10B981]">%</span>
                </div>
              </div>

              {/* Metric 5: Hướng triền */}
              <div className="bg-white p-3 rounded-[16px] border border-[#E5E7EB] shadow-2xs flex flex-col justify-between space-y-1 hover:-translate-y-0.5 transition-all duration-200">
                <div className="flex items-center gap-1.5 text-[#6B7280]">
                  <Navigation className="w-3.5 h-3.5 text-[#10B981]" />
                  <span className="text-[11px] font-medium">Hướng triền</span>
                </div>
                <div className="text-xs font-bold text-[#111827] truncate" title={activeFarm.slope_aspect_heading}>
                  {activeFarm.slope_aspect_heading || "Đông - Đông Nam"}
                </div>
              </div>

              {/* Metric 6: Thổ nhưỡng */}
              <div className="bg-white p-3 rounded-[16px] border border-[#E5E7EB] shadow-2xs flex flex-col justify-between space-y-1 hover:-translate-y-0.5 transition-all duration-200">
                <div className="flex items-center gap-1.5 text-[#6B7280]">
                  <Sprout className="w-3.5 h-3.5 text-[#10B981]" />
                  <span className="text-[11px] font-medium">Thổ nhưỡng</span>
                </div>
                <div className="text-xs font-bold text-[#111827] truncate" title={activeFarm.soil_texture_type}>
                  {activeFarm.soil_texture_type?.split("(")[0] || "Đất đỏ Bazan"}
                </div>
              </div>

              {/* Metric 7: Trang trại */}
              <div className="bg-white p-3 rounded-[16px] border border-[#E5E7EB] shadow-2xs flex flex-col justify-between space-y-1 hover:-translate-y-0.5 transition-all duration-200 col-span-2 sm:col-span-1">
                <div className="flex items-center gap-1.5 text-[#6B7280]">
                  <Building2 className="w-3.5 h-3.5 text-[#10B981]" />
                  <span className="text-[11px] font-medium">Trang trại</span>
                </div>
                <div className="text-xs font-bold text-[#111827] truncate" title={activeFarm.label}>
                  {activeFarm.label}
                </div>
              </div>
            </div>
          </div>
        )}
      </div>
    </Card>
  );
}
