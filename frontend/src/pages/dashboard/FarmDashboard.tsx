import { useState, useEffect, useMemo, useRef } from "react";
import { useParams, Link } from "react-router-dom";
import {
  Trees,
  Heart,
  AlertTriangle,
  TrendingUp,
  ArrowLeft,
  MapPin,
  Wheat,
  RefreshCw,
} from "lucide-react";

import {
  loadFarmDashboard,
  type FarmDashboardData,
  type FarmHeatmapTree,
} from "../../services/dashboardDataManager.service";

import KPICard from "../../components/dashboard/KPICard";
import SmartGardenCard from "../../components/dashboard/SmartGardenCard";
import TreeDistributionCard from "../../components/dashboard/TreeDistributionCard";
import HeatmapGrid from "../../components/dashboard/HeatmapGrid";
import Card from "../../components/dashboard/Shared/Card";
import SectionTitle from "../../components/dashboard/Shared/SectionTitle";
import { KPISkeleton, CardSkeleton } from "../../components/dashboard/Shared/SkeletonCard";
import type { ZoneSection, CellData } from "../../components/dashboard/HeatmapGrid";

const EMPTY_DATA: FarmDashboardData = {
  kpi: { total_trees: 0, total_zones: 0, healthy_percent: 0, high_risk_trees: 0, estimated_yield: "--" },
  health_distribution: { healthy: 0, monitoring: 0, diseased: 0 },
  heatmap: [],
  zones: [],
  yield_data: { estimated_yield: "--", avg_yield_per_tree: "--", avg_yield_per_hectare: "--" },
  alerts: { high: 0, medium: 0, low: 0 },
};

export default function FarmDashboard() {
  const { farmId } = useParams<{ farmId: string }>();
  const [data, setData] = useState<FarmDashboardData>(EMPTY_DATA);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const didInit = useRef(false);

  const fetchData = () => {
    if (!farmId) return;
    setLoading(true);
    setError(null);
    loadFarmDashboard(farmId)
      .then((result) => setData(result))
      .catch(() => setError("Không thể tải dữ liệu trang trại"))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    if (didInit.current) return;
    didInit.current = true;
    fetchData();
  }, [farmId]);

  const zoneSections: ZoneSection[] = useMemo(() => {
    const nameGroups = new Map<string, FarmHeatmapTree[]>();
    for (const t of data.heatmap) {
      const zoneName = t.zone_name || "Chưa xác định";
      const g = nameGroups.get(zoneName);
      if (g) g.push(t);
      else nameGroups.set(zoneName, [t]);
    }

    const sections: ZoneSection[] = [];
    for (const [zoneName, zoneTrees] of nameGroups) {
      zoneTrees.sort((a, b) => (a.tree_code || "").localeCompare(b.tree_code || ""));
      let h = 0, m = 0, d = 0;
      const cells: CellData[] = zoneTrees.map((tree) => {
        if (tree.status === "Healthy" || tree.status === "Khỏe mạnh") h++;
        else if (tree.status === "Monitoring" || tree.status === "Đang theo dõi") m++;
        else d++;
        return {
          id: tree.tree_id,
          risk: tree.status === "Healthy" || tree.status === "Khỏe mạnh" ? "healthy" : tree.status === "Monitoring" || tree.status === "Đang theo dõi" ? "monitor" : "diseased",
          treeId: tree.tree_code || tree.tree_id,
          zone: zoneName,
          riskScore: 0,
          status: tree.status || "Healthy",
          disease: "",
        };
      });
      sections.push({
        zoneName,
        trees: cells,
        healthyCount: h,
        monitoringCount: m,
        diseasedCount: d,
        totalCount: zoneTrees.length,
      });
    }
    sections.sort((a, b) => a.zoneName.localeCompare(b.zoneName));
    return sections;
  }, [data.heatmap]);

  const heatmapSummary = useMemo(() => {
    let healthy = 0, monitor = 0, diseased = 0;
    data.heatmap.forEach((t) => {
      if (t.status === "Healthy" || t.status === "Khỏe mạnh") healthy++;
      else if (t.status === "Monitoring" || t.status === "Đang theo dõi") monitor++;
      else diseased++;
    });
    return { healthy, monitor, diseased };
  }, [data.heatmap]);

  const healthChartData = useMemo(() => [
    { name: "Khỏe mạnh", value: data.health_distribution.healthy, color: "#22C55E" },
    { name: "Theo dõi", value: data.health_distribution.monitoring, color: "#EAB308" },
    { name: "Bị bệnh", value: data.health_distribution.diseased, color: "#EF4444" },
  ], [data.health_distribution]);

  const topRiskZones = useMemo(() => {
    return [...data.zones]
      .sort((a, b) => {
        const riskA = a.tree_count > 0 ? a.diseased_count / a.tree_count : 0;
        const riskB = b.tree_count > 0 ? b.diseased_count / b.tree_count : 0;
        return riskB - riskA;
      })
      .slice(0, 5);
  }, [data.zones]);

  const riskColor = (level: string) => {
    if (level === "Nghiêm trọng") return "text-red-600 bg-red-50";
    if (level === "Cảnh báo") return "text-amber-600 bg-amber-50";
    return "text-emerald-600 bg-emerald-50";
  };

  if (!farmId) {
    return (
      <div className="flex flex-col items-center justify-center h-64 text-gray-500">
        <p className="text-lg font-semibold">Không tìm thấy trang trại</p>
        <Link to="/dashboard" className="mt-2 text-emerald-600 hover:underline text-sm">
          Quay lại Dashboard
        </Link>
      </div>
    );
  }

  return (
    <div className="flex flex-col bg-[#F5F7FB]" style={{ gap: "20px", flex: "1 1 0%", minHeight: 0 }}>
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <Link
            to="/dashboard"
            className="flex items-center justify-center w-9 h-9 rounded-full bg-white border border-[#EEF2F7] shadow-sm hover:bg-gray-50 transition-colors"
          >
            <ArrowLeft className="w-4 h-4 text-gray-600" />
          </Link>
          <div>
            <h1 className="text-[22px] font-bold text-gray-900 tracking-tight">Farm Dashboard</h1>
            <p className="text-[13px] text-gray-500 font-medium">{data.season_name ? `${data.season_name}${data.season_year ? ` ${data.season_year}` : ''}` : 'Phân tích hiệu suất trang trại'}</p>
          </div>
        </div>
        <button
          type="button"
          onClick={fetchData}
          className="flex items-center gap-1.5 px-3 py-1.5 text-[12px] font-semibold text-gray-600 bg-white border border-[#EEF2F7] rounded-[10px] hover:bg-gray-50 transition-colors"
        >
          <RefreshCw className="w-3.5 h-3.5" />
          Làm mới
        </button>
      </div>

      {error && (
        <div className="p-4 bg-red-50 border border-red-100 text-red-700 rounded-[16px] text-sm font-semibold">
          {error}
        </div>
      )}

      {/* SMART GARDEN REALTIME TELEMETRY & AI ADVICE CARD */}
      <div className="w-full">
        <SmartGardenCard />
      </div>

      {/* ROW 1: KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5" style={{ gap: "20px" }}>
        {loading ? (
          Array.from({ length: 5 }).map((_, i) => <KPISkeleton key={i} />)
        ) : (
          <>
            <KPICard
              icon={<Trees className="w-7 h-7 text-emerald-600" />}
              iconBg="bg-emerald-100"
              title="TỔNG SỐ CÂY"
              value={data.kpi.total_trees.toLocaleString()}
              subtitle={`${data.kpi.total_zones} khu vực`}
              valueColor="text-[#111827]"
            />
            <KPICard
              icon={<MapPin className="w-7 h-7 text-blue-600" />}
              iconBg="bg-blue-50"
              title="TỔNG SỐ KHU VỰC"
              value={String(data.kpi.total_zones)}
              subtitle="Khu vực canh tác"
              valueColor="text-[#111827]"
            />
            <KPICard
              icon={<Heart className="w-7 h-7 text-emerald-600" />}
              iconBg="bg-emerald-100"
              title="SỨC KHỎE VƯỜN CÂY"
              value={`${data.kpi.healthy_percent}%`}
              subtitle={data.kpi.healthy_percent >= 80 ? "Khỏe mạnh" : data.kpi.healthy_percent >= 60 ? "Cần chú ý" : "Nghiêm trọng"}
              subtitleColor={data.kpi.healthy_percent >= 80 ? "#15803D" : data.kpi.healthy_percent >= 60 ? "#D97706" : "#DC2626"}
              valueColor="text-emerald-600"
            />
            <KPICard
              icon={<AlertTriangle className="w-7 h-7 text-red-600" />}
              iconBg="bg-red-50"
              title="CÂY NGUY CƠ CAO"
              value={String(data.kpi.high_risk_trees)}
              subtitle="Cảnh báo ưu tiên"
              valueColor="text-red-500"
            />
            <KPICard
              icon={<TrendingUp className={`w-7 h-7 ${data.kpi.farm_score != null ? 'text-emerald-600' : 'text-gray-400'}`} />}
              iconBg={data.kpi.farm_score != null ? 'bg-emerald-100' : 'bg-gray-100'}
              title="ĐIỂM TRANG TRẠI"
              value={data.kpi.farm_score != null ? String(data.kpi.farm_score) : '--'}
              subtitle={data.kpi.overall_status ?? 'Sẽ khả dụng trong phiên bản AI'}
              subtitleColor={data.kpi.farm_score != null ? (data.kpi.farm_score >= 70 ? '#15803D' : data.kpi.farm_score >= 50 ? '#D97706' : '#DC2626') : undefined}
              valueColor={data.kpi.farm_score != null ? 'text-emerald-600' : 'text-gray-400'}
            />
          </>
        )}
      </div>

      {/* ROW 2: Heatmap + Top Risk Zones */}
      <div className="flex flex-col lg:grid lg:grid-cols-3" style={{ gap: "20px" }}>
        {/* Heatmap */}
        {loading ? (
          <CardSkeleton><div className="bg-gray-200 rounded-[6px] animate-pulse flex-1 w-full h-full" /></CardSkeleton>
        ) : (
          <div className="lg:col-span-2">
            <Card className="flex flex-col lg:h-[480px]" padding={false} style={{ minHeight: "480px", overflow: "hidden" }}>
              <div className="flex flex-col flex-1 min-h-0" style={{ padding: "10px" }}>
                <div className="flex items-center gap-2.5" style={{ marginBottom: "4px" }}>
                  <MapPin className="w-5 h-5 text-emerald-600" />
                  <div>
                    <h3 className="text-[16px] font-bold text-gray-900 tracking-tight">Bản đồ giám sát</h3>
                    <span className="text-[12px] text-gray-500 font-medium">Tất cả cây trong trang trại</span>
                  </div>
                </div>

                <div className="flex items-center gap-4 mb-2 overflow-x-auto" style={{ padding: "0 2px" }}>
                  <span className="text-[11px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-[4px] whitespace-nowrap">An toàn {heatmapSummary.healthy}</span>
                  <span className="text-[11px] font-bold text-yellow-700 bg-yellow-50 px-2 py-0.5 rounded-[4px] whitespace-nowrap">Cần theo dõi {heatmapSummary.monitor}</span>
                  <span className="text-[11px] font-bold text-red-700 bg-red-50 px-2 py-0.5 rounded-[4px] whitespace-nowrap">Nguy cơ cao {heatmapSummary.diseased}</span>
                </div>

                <div className="flex-1 min-h-0 overflow-x-auto overflow-y-auto">
                  <HeatmapGrid sections={zoneSections} />
                </div>

                <div className="flex items-center gap-4 flex-wrap" style={{ paddingTop: "6px", borderTop: "1px solid #EEF2F7", marginTop: "4px" }}>
                  <div className="flex items-center" style={{ gap: "4px" }}>
                    <div className="w-2.5 h-2.5 rounded-[3px] bg-[#6EE7B7]" />
                    <span className="text-[12px] font-bold text-gray-500">An toàn</span>
                  </div>
                  <div className="flex items-center" style={{ gap: "4px" }}>
                    <div className="w-2.5 h-2.5 rounded-[3px] bg-[#FDE68A]" />
                    <span className="text-[12px] font-bold text-gray-500">Cần theo dõi</span>
                  </div>
                  <div className="flex items-center" style={{ gap: "4px" }}>
                    <div className="w-2.5 h-2.5 rounded-[3px] bg-[#F87171]" />
                    <span className="text-[12px] font-bold text-gray-500">Nguy cơ cao</span>
                  </div>
                </div>
              </div>
            </Card>
          </div>
        )}

        {/* Top Risk Zones */}
        {loading ? (
          <CardSkeleton height="480px"><div className="bg-gray-200 rounded-[6px] animate-pulse flex-1 w-full" /></CardSkeleton>
        ) : (
          <Card className="flex flex-col" style={{ height: "480px" }}>
            <SectionTitle
              icon={<AlertTriangle className="w-5 h-5 text-red-500" />}
              title="Khu vực rủi ro cao"
              subtitle="Top 5 khu vực"
              size="section"
            />
            <div className="flex-1 flex flex-col" style={{ gap: "10px" }}>
              {topRiskZones.length === 0 ? (
                <div className="flex-1 flex items-center justify-center text-gray-400 text-sm font-medium">
                  Không có dữ liệu
                </div>
              ) : (
                topRiskZones.map((zone, idx) => {
                  const pct = zone.tree_count > 0 ? Math.round((zone.diseased_count / zone.tree_count) * 100) : 0;
                  return (
                    <div
                      key={zone.id}
                      className="flex items-center gap-3 p-3 bg-gray-50 rounded-[12px] hover:bg-gray-100 transition-colors"
                    >
                      <div className="flex items-center justify-center w-8 h-8 rounded-full bg-white border border-gray-200 flex-shrink-0">
                        <span className="text-[13px] font-bold text-gray-600">{idx + 1}</span>
                      </div>
                      <div className="flex-1 min-w-0">
      <div className="flex items-center justify-between gap-2 flex-wrap">
                          <span className="text-[13px] font-bold text-gray-900 truncate">{zone.name}</span>
                          <span className={`text-[11px] font-bold px-2 py-0.5 rounded-full ${riskColor(zone.risk_level)}`}>
                            {zone.risk_level}
                          </span>
                        </div>
                        <div className="flex items-center gap-2 mt-1">
                          <span className="text-[11px] text-gray-500 font-medium">{zone.tree_count} cây</span>
                          <span className="text-[11px] text-gray-400">·</span>
                          <span className="text-[11px] text-red-500 font-medium">{zone.diseased_count} bệnh</span>
                          <span className="text-[11px] text-gray-400">·</span>
                          <span className="text-[11px] font-semibold" style={{ color: pct > 30 ? "#DC2626" : pct > 10 ? "#D97706" : "#16A34A" }}>
                            {pct}%
                          </span>
                        </div>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </Card>
        )}
      </div>

      {/* ROW 3: Health Distribution + Yield + Alerts */}
      <div className="flex flex-col lg:grid lg:grid-cols-3" style={{ gap: "20px" }}>
        {/* Health Distribution */}
        <div>
          {loading ? (
            <CardSkeleton height="280px"><div className="bg-gray-200 rounded-full animate-pulse flex-1 h-full" /></CardSkeleton>
          ) : (
            <div style={{ height: "280px" }}>
              <TreeDistributionCard data={healthChartData} total={data.kpi.total_trees} />
            </div>
          )}
        </div>

        {/* Yield Card */}
        <div>
          {loading ? (
            <CardSkeleton height="280px"><div className="bg-gray-200 rounded-[6px] animate-pulse flex-1 w-full" /></CardSkeleton>
          ) : (
            <Card className="flex flex-col" style={{ height: "280px" }}>
              <SectionTitle
                icon={<Wheat className="w-5 h-5 text-amber-600" />}
                title="Sản lượng thu hoạch"
                subtitle={data.yield_data.yield_kg != null ? 'Dữ liệu thu hoạch thực tế' : 'Dữ liệu sẽ có khi tích hợp AI'}
                size="section"
              />
              {data.yield_data.yield_kg != null ? (
                <div className="flex-1 flex flex-col justify-center" style={{ gap: "6px", padding: "0 16px 12px" }}>
                  <div className="text-center">
                    <span className="text-[32px] font-bold text-amber-700">{data.yield_data.yield_kg.toLocaleString()}</span>
                    <span className="text-[13px] text-gray-500 font-medium ml-1">kg</span>
                  </div>
                  <div className="grid grid-cols-2 gap-1 text-center text-[11px]">
                    {data.yield_data.average_weight != null && (
                      <div className="p-1.5 bg-gray-50 rounded-[6px]">
                        <span className="font-bold text-gray-800">{data.yield_data.average_weight}g</span>
                        <span className="text-gray-400 ml-1">/quả</span>
                      </div>
                    )}
                    {data.yield_data.selling_price != null && (
                      <div className="p-1.5 bg-gray-50 rounded-[6px]">
                        <span className="font-bold text-gray-800">{data.yield_data.selling_price.toLocaleString()}đ</span>
                        <span className="text-gray-400 ml-1">/kg</span>
                      </div>
                    )}
                    {data.yield_data.total_revenue != null && (
                      <div className="p-1.5 bg-gray-50 rounded-[6px]">
                        <span className="font-bold text-gray-800">{data.yield_data.total_revenue.toLocaleString()}đ</span>
                        <span className="text-gray-400 ml-1">doanh thu</span>
                      </div>
                    )}
                    {data.yield_data.buyer && (
                      <div className="p-1.5 bg-gray-50 rounded-[6px]">
                        <span className="font-bold text-gray-800 truncate block">{data.yield_data.buyer}</span>
                        <span className="text-gray-400">người mua</span>
                      </div>
                    )}
                  </div>
                  {(data.yield_data.grade_a != null || data.yield_data.grade_b != null || data.yield_data.grade_c != null) && (
                    <div className="flex gap-2 justify-center">
                      {data.yield_data.grade_a != null && (
                        <span className="text-[11px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-[4px]">Loại A {data.yield_data.grade_a}%</span>
                      )}
                      {data.yield_data.grade_b != null && (
                        <span className="text-[11px] font-bold text-amber-700 bg-amber-50 px-2 py-0.5 rounded-[4px]">Loại B {data.yield_data.grade_b}%</span>
                      )}
                      {data.yield_data.grade_c != null && (
                        <span className="text-[11px] font-bold text-red-700 bg-red-50 px-2 py-0.5 rounded-[4px]">Loại C {data.yield_data.grade_c}%</span>
                      )}
                    </div>
                  )}
                  {(data.kpi.target_yield != null || data.kpi.target_tree_health != null) && (
                    <div className="flex gap-3 justify-center text-[11px] text-gray-500 font-medium">
                      {data.kpi.target_yield != null && <span>Mục tiêu: {data.kpi.target_yield.toLocaleString()} kg</span>}
                      {data.kpi.target_tree_health != null && <span>Sức khỏe: {data.kpi.target_tree_health}%</span>}
                    </div>
                  )}
                </div>
              ) : (
                <div className="flex-1 flex flex-col items-center justify-center" style={{ gap: "16px" }}>
                  <div className="text-center">
                    <span className="text-[36px] font-bold text-gray-300">--</span>
                    <span className="text-[13px] text-gray-400 font-medium ml-1">kg/ha</span>
                  </div>
                  <div className="grid grid-cols-2 gap-4 w-full max-w-[240px]">
                    <div className="text-center p-3 bg-gray-50 rounded-[10px]">
                      <span className="text-[14px] font-bold text-gray-400 block">--</span>
                      <span className="text-[11px] text-gray-400 font-medium">kg/cây</span>
                    </div>
                    <div className="text-center p-3 bg-gray-50 rounded-[10px]">
                      <span className="text-[14px] font-bold text-gray-400 block">--</span>
                      <span className="text-[11px] text-gray-400 font-medium">kg/ha</span>
                    </div>
                  </div>
                </div>
              )}
            </Card>
          )}
        </div>

        {/* Alert Summary */}
        <div>
          {loading ? (
            <CardSkeleton height="280px"><div className="bg-gray-200 rounded-[6px] animate-pulse flex-1 w-full" /></CardSkeleton>
          ) : (
            <Card className="flex flex-col" style={{ height: "280px" }}>
              <SectionTitle
                icon={<AlertTriangle className="w-5 h-5 text-red-500" />}
                title="Cảnh báo"
                subtitle="Tổng hợp cảnh báo trang trại"
                size="section"
              />
              <div className="flex-1 flex flex-col justify-center" style={{ gap: "12px" }}>
                <div className="flex items-center justify-between p-3 bg-red-50 rounded-[10px]">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full bg-red-500" />
                    <span className="text-[13px] font-bold text-gray-800">Ưu tiên cao</span>
                  </div>
                  <span className="text-[18px] font-bold text-red-600">{data.alerts.high}</span>
                </div>
                <div className="flex items-center justify-between p-3 bg-amber-50 rounded-[10px]">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full bg-amber-500" />
                    <span className="text-[13px] font-bold text-gray-800">Ưu tiên trung bình</span>
                  </div>
                  <span className="text-[18px] font-bold text-amber-600">{data.alerts.medium}</span>
                </div>
                <div className="flex items-center justify-between p-3 bg-emerald-50 rounded-[10px]">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full bg-emerald-500" />
                    <span className="text-[13px] font-bold text-gray-800">Ưu tiên thấp</span>
                  </div>
                  <span className="text-[18px] font-bold text-emerald-600">{data.alerts.low}</span>
                </div>
              </div>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
