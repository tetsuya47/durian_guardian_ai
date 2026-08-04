import { useState } from "react";
import { Maximize2, Minimize2, RefreshCw } from "lucide-react";
import Card from "./Shared/Card";
import HeatmapGrid from "./HeatmapGrid";
import type { ZoneSection } from "./HeatmapGrid";

interface HeatmapCardProps {
  sections: ZoneSection[];
  lastUpdated: string;
  summaryCounts: { healthy: number; monitor: number; diseased: number };
  onRefresh?: () => void;
  farmOptions?: { value: string; label: string }[];
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
  farmOptions,
  zoneOptions,
  selectedFarm,
  selectedZone,
  onFarmChange,
  onZoneChange,
}: HeatmapCardProps) {
  const [isFullscreen, setIsFullscreen] = useState(false);

  return (
    <Card
      className={`flex flex-col transition-all duration-300 ${
        isFullscreen ? "fixed inset-4 z-[9999] shadow-2xl rounded-[24px] bg-white border border-gray-200" : "h-full"
      }`}
      padding={false}
      style={{ overflow: "hidden" }}
    >
      <div className="flex flex-col flex-1 min-h-0 p-4 space-y-3">
        {/* ROW 1: TITLE & ACTION BUTTONS */}
        <div className="flex items-center justify-between gap-3 pb-2 border-b border-gray-100">
          <h2 className="text-sm sm:text-base font-black text-gray-900 tracking-tight uppercase truncate">
            BẢN ĐỒ NHIỆT RỦI RO DỊCH BỆNH (HEATMAP)
          </h2>

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

        {/* ROW 2: INTEGRATED CONTROLS FILTER BAR */}
        <div className="flex flex-wrap items-center justify-between gap-2.5 text-xs font-bold text-gray-700 bg-gray-50/80 p-2.5 rounded-[14px] border border-gray-200/60">
          <div className="flex items-center gap-3 flex-wrap">
            <div className="flex items-center gap-1.5">
              <span className="text-gray-500 font-semibold whitespace-nowrap">Trang trại:</span>
              <select
                className="bg-white border border-gray-200/90 rounded-[8px] px-2.5 py-1 text-xs font-bold text-gray-800 cursor-pointer focus:outline-none focus:ring-2 focus:ring-emerald-400 shadow-2xs"
                aria-label="Chọn trang trại"
                value={selectedFarm || "all"}
                onChange={(e) => onFarmChange?.(e.target.value)}
              >
                {(farmOptions || []).map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label === "Tất cả trang trại" ? "Trang trại Bến Tre" : opt.label}
                  </option>
                ))}
              </select>
            </div>

            <div className="flex items-center gap-1.5">
              <span className="text-gray-500 font-semibold whitespace-nowrap">Khu vực:</span>
              <select
                className="bg-white border border-gray-200/90 rounded-[8px] px-2.5 py-1 text-xs font-bold text-gray-800 cursor-pointer focus:outline-none focus:ring-2 focus:ring-emerald-400 shadow-2xs"
                aria-label="Chọn khu vực"
                value={selectedZone || "all"}
                onChange={(e) => onZoneChange?.(e.target.value)}
              >
                {(zoneOptions || []).map((opt) => (
                  <option key={opt.value} value={opt.value}>
                    {opt.label === "Tất cả khu vực" ? "Tất cả" : opt.label}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="flex items-center gap-2 text-[11px] font-bold flex-wrap">
            <span className="text-emerald-900 bg-emerald-100/90 px-2.5 py-0.5 rounded-full border border-emerald-300 flex items-center gap-1">
              <span>🌐 Ranh giới GIS (Polygon)</span>
            </span>
            <span className="text-gray-700 bg-gray-200/80 px-2.5 py-0.5 rounded-full">
              50 Cây sầu riêng
            </span>
          </div>
        </div>

        {/* HEATMAP TREE GRID WITH SATELLITE FIELD BACKDROP */}
        <div className="flex-1 min-h-0 overflow-x-auto overflow-y-auto">
          <HeatmapGrid sections={sections} />
        </div>

        {/* DARK GREEN RISK LEGEND BAR MATCHING USER MOCKUP */}
        <div className="bg-[#143525] text-white p-3 rounded-[14px] flex items-center justify-around flex-wrap gap-2.5 shadow-md border border-emerald-950/60 text-xs font-extrabold">
          {RISK_TIER_LEGENDS.map((item) => (
            <div key={item.label} className="flex items-center gap-2">
              <div className={`w-3.5 h-3.5 rounded-[4px] ${item.color} shadow-xs`} aria-hidden="true" />
              <span>{item.label}</span>
            </div>
          ))}
        </div>

        {/* FOOTER TIMESTAMP & QUICK SUMMARY */}
        <div className="flex items-center justify-between text-xs text-gray-500 font-bold pt-1 border-t border-gray-100">
          <div className="flex items-center gap-1.5">
            <span>Cập nhật: {lastUpdated && lastUpdated !== "—" ? lastUpdated : "09:30:15"}</span>
          </div>

          <div className="flex items-center gap-2 text-[10px] font-bold">
            <span className="text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-md border border-emerald-200">
              Khỏe mạnh: {summaryCounts.healthy}
            </span>
            <span className="text-amber-700 bg-amber-50 px-2 py-0.5 rounded-md border border-amber-200">
              Cảnh báo: {summaryCounts.monitor}
            </span>
            <span className="text-red-700 bg-red-50 px-2 py-0.5 rounded-md border border-red-200">
              Nguy hiểm: {summaryCounts.diseased}
            </span>
          </div>
        </div>
      </div>
    </Card>
  );
}
