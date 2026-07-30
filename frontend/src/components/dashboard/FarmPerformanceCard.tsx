import { useState, useEffect, useRef, useCallback } from "react";
import { BarChart3, TrendingUp, AlertTriangle, RefreshCw, Lightbulb, ChevronDown } from "lucide-react";
import Card from "./Shared/Card";
import SectionTitle from "./Shared/SectionTitle";
import { SkeletonBar } from "./Shared/SkeletonCard";
import { loadFarmPerformance, loadWidgets } from "../../services/dashboardDataManager.service";
import type { FarmPerformanceDTO } from "../../services/dashboardDataManager.service";

function statusColor(status: string | null): string {
  if (status === "Tốt") return "text-emerald-700 bg-emerald-50";
  if (status === "Cảnh báo") return "text-amber-700 bg-amber-50";
  if (status === "Nghiêm trọng") return "text-red-700 bg-red-50";
  return "text-gray-500 bg-gray-100";
}

function progressColor(pct: number | null): string {
  if (pct == null) return "bg-gray-200";
  if (pct >= 80) return "bg-emerald-500";
  if (pct >= 50) return "bg-amber-500";
  return "bg-red-500";
}

function dynamicTitle(farmName: string | null): string {
  if (!farmName) return "Farm Performance";
  return `Farm Performance — ${farmName}`;
}

function dynamicSubtitle(farmName: string | null): string {
  if (!farmName) return "Hiệu suất tổng hợp các trang trại";
  return `Hiệu suất trang trại ${farmName}`;
}

export default function FarmPerformanceCard() {
  const [data, setData] = useState<FarmPerformanceDTO | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const [farms, setFarms] = useState<{ id: string; name: string }[]>([]);
  const [selectedFarmId, setSelectedFarmId] = useState<string>("");

  const didInit = useRef(false);

  const fetchPerformance = useCallback(async (farmId: string) => {
    setLoading(true);
    setError(null);
    try {
      const result = await loadFarmPerformance(farmId || undefined);
      setData(result);
    } catch {
      setError("Không thể tải dữ liệu hiệu suất");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (didInit.current) return;
    didInit.current = true;
    loadWidgets()
      .then(({ widgets }) => {
        setFarms(widgets.farms);
      })
      .catch(() => {});
    fetchPerformance("");
  }, [fetchPerformance]);

  const handleFarmChange = (farmId: string) => {
    setSelectedFarmId(farmId);
    fetchPerformance(farmId);
  };

  const handleRetry = () => {
    fetchPerformance(selectedFarmId);
  };

  const selectedFarm = farms.find((f) => f.id === selectedFarmId);
  const farmName = selectedFarm?.name ?? null;

  if (loading) {
    return (
      <Card className="flex flex-col" style={{ height: "100%" }}>
        <div className="flex flex-col gap-4 animate-pulse">
          <div className="flex items-center gap-2">
            <SkeletonBar className="h-5 w-5 rounded" />
            <SkeletonBar className="h-4 w-[160px]" />
          </div>
          <div className="flex flex-col items-center gap-2 py-4">
            <SkeletonBar className="h-[48px] w-[100px]" />
            <SkeletonBar className="h-[8px] w-[140px] rounded-full" />
            <SkeletonBar className="h-[14px] w-[80px]" />
          </div>
          <div className="space-y-2">
            <SkeletonBar className="h-[10px] w-[120px]" />
            <SkeletonBar className="h-[10px] w-[140px]" />
            <SkeletonBar className="h-[12px] w-full rounded-full" />
          </div>
          <div className="space-y-1.5">
            <SkeletonBar className="h-[10px] w-[180px]" />
            <SkeletonBar className="h-[10px] w-[160px]" />
          </div>
          <div className="mt-auto pt-3 border-t border-gray-100">
            <SkeletonBar className="h-[10px] w-full" />
            <SkeletonBar className="h-[10px] w-[80%] mt-1" />
          </div>
        </div>
      </Card>
    );
  }

  if (error) {
    return (
      <Card className="flex flex-col" style={{ height: "100%" }}>
        <SectionTitle
          icon={<TrendingUp className="w-5 h-5 text-emerald-600" />}
          title={dynamicTitle(farmName)}
          subtitle={dynamicSubtitle(farmName)}
          size="card"
        />
        <div className="flex flex-col items-center justify-center flex-1" style={{ minHeight: "160px" }}>
          <AlertTriangle className="w-8 h-8 text-red-400 mb-2" />
          <p className="text-[13px] text-red-600 font-semibold text-center mb-3">{error}</p>
          <button
            type="button"
            onClick={handleRetry}
            className="flex items-center gap-1.5 px-3 py-1.5 text-[12px] font-semibold text-gray-600 bg-white border border-gray-200 rounded-[10px] hover:bg-gray-50 transition-colors"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            Thử lại
          </button>
        </div>
      </Card>
    );
  }

  if (!data || data.total_farms === 0) {
    return (
      <Card className="flex flex-col" style={{ height: "100%" }}>
        <SectionTitle
          icon={<TrendingUp className="w-5 h-5 text-emerald-600" />}
          title={dynamicTitle(farmName)}
          subtitle={dynamicSubtitle(farmName)}
          size="card"
        />
        <div className="flex flex-col items-center justify-center flex-1" style={{ minHeight: "160px" }}>
          <BarChart3 className="w-10 h-10 text-gray-300 mb-2" />
          <p className="text-[14px] font-bold text-gray-400">No performance data found.</p>
          <p className="text-[12px] text-gray-400 font-medium">Thông tin sẽ xuất hiện khi có dữ liệu trang trại</p>
        </div>
      </Card>
    );
  }

  const score = data.average_farm_score;
  const status = data.overall_status;
  const target = data.total_target_yield;
  const actual = data.total_actual_yield;
  const achievement = data.yield_achievement_pct;
  const healthPct = data.healthy_percent;
  const evaluated = data.farms_evaluated;
  const total = data.total_farms;

  return (
    <Card className="flex flex-col" style={{ height: "100%" }}>
      <SectionTitle
        icon={<TrendingUp className="w-5 h-5 text-emerald-600" />}
        title={dynamicTitle(farmName)}
        subtitle={dynamicSubtitle(farmName)}
        size="card"
      />

      {/* Filters */}
      <div className="relative mb-3">
        <select
          value={selectedFarmId}
          onChange={(e) => handleFarmChange(e.target.value)}
          className="w-full appearance-none px-3 py-1.5 text-[12px] font-semibold text-gray-700 bg-white border border-gray-200 rounded-[10px] focus:outline-none focus:ring-2 focus:ring-emerald-300 focus:border-emerald-300 cursor-pointer"
        >
          <option value="">Tất cả trang trại</option>
          {farms.map((f) => (
            <option key={f.id} value={f.id}>{f.name}</option>
          ))}
        </select>
        <ChevronDown className="absolute right-2 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-gray-400 pointer-events-none" />
      </div>

      <div className="flex-1 flex flex-col" style={{ gap: "10px" }}>
        {/* Score section */}
        <div className="flex flex-col items-center py-2">
          <div className="flex items-baseline gap-1">
            <span className="text-[36px] font-bold text-gray-900 leading-none">
              {score != null ? score : "--"}
            </span>
            <span className="text-[14px] font-medium text-gray-400">/100</span>
          </div>
          {status && (
            <span className={`text-[11px] font-bold px-2.5 py-0.5 rounded-full mt-1 ${statusColor(status)}`}>
              {status}
            </span>
          )}
        </div>

        {/* Target vs Achievement */}
        {(target != null || actual != null) && (
          <div className="p-3 bg-gray-50 rounded-[12px]">
            <div className="flex items-center justify-between mb-1">
              <span className="text-[11px] font-bold text-gray-700">Mục tiêu</span>
              <span className="text-[11px] font-bold text-gray-700">
                {target != null ? `${target.toLocaleString(undefined, { maximumFractionDigits: 1 })} kg` : "--"}
              </span>
            </div>
            <div className="flex items-center justify-between mb-1.5">
              <span className="text-[11px] font-bold text-emerald-700">Thực tế</span>
              <span className="text-[11px] font-bold text-emerald-700">
                {actual != null ? `${actual.toLocaleString(undefined, { maximumFractionDigits: 1 })} kg` : "--"}
              </span>
            </div>
            <div className="w-full h-[6px] bg-gray-200 rounded-full overflow-hidden">
              <div
                className={`h-full rounded-full transition-all duration-500 ${progressColor(achievement)}`}
                style={{ width: `${Math.min(achievement ?? 0, 100)}%` }}
              />
            </div>
            <div className="flex justify-between mt-1">
              <span className="text-[10px] font-medium text-gray-400">Đạt</span>
              <span className="text-[10px] font-bold" style={{ color: achievement != null ? (achievement >= 80 ? "#15803D" : achievement >= 50 ? "#D97706" : "#DC2626") : "#9CA3AF" }}>
                {achievement != null ? `${achievement}%` : "--"}
              </span>
            </div>
          </div>
        )}

        {/* Summary */}
        <div className="flex items-center gap-3 text-[12px]">
          <div className="flex items-center gap-1">
            <div className={`w-2 h-2 rounded-full ${evaluated === total ? 'bg-emerald-500' : 'bg-amber-500'}`} />
            <span className="font-semibold text-gray-700">
              {evaluated}/{total} trang trại
            </span>
          </div>
          {healthPct != null && (
            <div className="flex items-center gap-1">
              <TrendingUp className="w-3.5 h-3.5 text-emerald-500" />
              <span className="font-semibold text-gray-700">{healthPct}% sức khỏe</span>
            </div>
          )}
        </div>

        {/* AI Insight */}
        <div className="mt-auto pt-3 border-t border-gray-100">
          <div className="flex items-start gap-2">
            <Lightbulb className="w-4 h-4 text-amber-500 mt-0.5 flex-shrink-0" />
            <p className="text-[11px] text-gray-500 font-medium leading-relaxed">
              {data.ai_insight}
            </p>
          </div>
        </div>
      </div>
    </Card>
  );
}
