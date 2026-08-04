import { useState, useEffect, useMemo, useRef } from "react";

import {
  loadDashboardCore,
  loadHeatmap,
  loadWidgets,
} from "../../services/dashboardDataManager.service";
import type {
  BackendKpi,
  SystemOverviewData,
  HeatmapTree,
  WidgetsData,
  WidgetAlertCounts,
} from "../../services/dashboardDataManager.service";

import DashboardHeader from "../../components/dashboard/DashboardHeader";
import KPISection from "../../components/dashboard/KPISection";
import SystemOverviewCard from "../../components/dashboard/SystemOverviewCard";
import HeatmapCard from "../../components/dashboard/HeatmapCard";
import RegionalFarmMapCard from "../../components/dashboard/RegionalFarmMapCard";
import AIChatbotCard from "../../components/dashboard/AIChatbotCard";
import WeatherCard from "../../components/dashboard/WeatherCard";
import GrowthTrendCard from "../../components/dashboard/GrowthTrendCard";
import { useAuth } from "../../hooks/useAuth";
import TreeDistributionCard from "../../components/dashboard/TreeDistributionCard";
import RealtimeInspectionCard from "../../components/dashboard/RealtimeInspectionCard";
import FarmPerformanceCard from "../../components/dashboard/FarmPerformanceCard";
import { KPISkeleton, CardSkeleton } from "../../components/dashboard/Shared/SkeletonCard";
import type { CellData, ZoneSection } from "../../components/dashboard/HeatmapGrid";
import type { InspectionRow } from "../../components/dashboard/InspectionTable";

interface RecommendationRow {
  id: number;
  treeId: string;
  riskScore: number;
  status: string;
  farm: string;
  zone: string;
  disease: string;
}

const EMPTY_KPI: BackendKpi = {
  total_farms: 0, total_trees: 0, healthy_trees: 0, diseased_trees: 0, high_risk_trees: 0,
};
const EMPTY_OVERVIEW: SystemOverviewData = {
  inspection_today: 0, ai_detection_today: 0, new_alerts_today: 0, pending_review: 0, updated_at: "",
};
const EMPTY_WIDGETS: WidgetsData = {
  inspections: [], detections: [], priorityTrees: [],
  alertCounts: { high: 0, medium: 0, low: 0 },
  alerts: [], farms: [], zones: [],
};

export default function DashboardPage() {
  const { user } = useAuth();
  const isAdmin = !user || user.role === "Admin" || user.role === "ADMIN" || user.role === "System Admin";

  const [dashboardLoading, setDashboardLoading] = useState(true);
  const [heatmapLoading, setHeatmapLoading] = useState(true);
  const [widgetsLoading, setWidgetsLoading] = useState(true);

  const [backendKpi, setBackendKpi] = useState<BackendKpi>(EMPTY_KPI);
  const [systemOverview, setSystemOverview] = useState<SystemOverviewData>(EMPTY_OVERVIEW);
  const [heatmapTrees, setHeatmapTrees] = useState<HeatmapTree[]>([]);
  const [widgets, setWidgets] = useState<WidgetsData>(EMPTY_WIDGETS);
  const [error, setError] = useState<string | null>(null);
  const [farmFilter, setFarmFilter] = useState("all");
  const [zoneFilter, setZoneFilter] = useState("all");

  const didInit = useRef(false);

  const fetchDashboard = () => {
    setDashboardLoading(true);
    setError(null);
    loadDashboardCore()
      .then(({ backendKpi, systemOverview }) => {
        setBackendKpi(backendKpi);
        setSystemOverview(systemOverview);
      })
      .catch(() => setError("Không thể tải dữ liệu KPI"))
      .finally(() => setDashboardLoading(false));
  };

  const fetchHeatmap = () => {
    setHeatmapLoading(true);
    setError(null);
    loadHeatmap()
      .then(({ heatmapData }) => { setHeatmapTrees(heatmapData); })
      .catch(() => setError("Không thể tải dữ liệu bản đồ nhiệt"))
      .finally(() => setHeatmapLoading(false));
  };

  const fetchWidgets = () => {
    setWidgetsLoading(true);
    setError(null);
    loadWidgets()
      .then(({ widgets }) => { setWidgets(widgets); })
      .catch(() => setError("Không thể tải dữ liệu widget"))
      .finally(() => setWidgetsLoading(false));
  };

  const fetchAll = () => {
    fetchDashboard();
    fetchHeatmap();
    fetchWidgets();
  };

  useEffect(() => {
    if (didInit.current) return;
    didInit.current = true;
    fetchAll();
  }, []);

  useEffect(() => { setZoneFilter("all"); }, [farmFilter]);

  const anyLoading = dashboardLoading || heatmapLoading || widgetsLoading;

  const kpiTotalTrees = backendKpi.total_trees;
  const kpiHealthyCount = backendKpi.healthy_trees;
  const kpiDiseasedCount = backendKpi.diseased_trees;
  const kpiMonitoringCount = kpiTotalTrees - kpiHealthyCount - kpiDiseasedCount;
  const kpiEmergencyCount = backendKpi.high_risk_trees;

  const farmOptions = useMemo(
    () => [{ value: "all", label: "Tất cả trang trại" }, ...widgets.farms.map((f) => ({ value: f.id, label: f.name }))],
    [widgets.farms],
  );

  const zoneOptions = useMemo(() => {
    const filtered = farmFilter === "all"
      ? widgets.zones
      : widgets.zones.filter((z) => {
          return heatmapTrees.some((t) => t.zone_id === z.id && t.farm_id === farmFilter);
        });
    return [{ value: "all", label: "Tất cả khu vực" }, ...filtered.map((z) => ({ value: z.id, label: z.name }))];
  }, [widgets.zones, farmFilter, heatmapTrees]);

  const filteredHeatmapTrees = useMemo(() => {
    return heatmapTrees.filter((t) => {
      if (farmFilter !== "all" && t.farm_id !== farmFilter) return false;
      if (zoneFilter !== "all" && t.zone_id !== zoneFilter) return false;
      return true;
    });
  }, [heatmapTrees, farmFilter, zoneFilter]);

  const heatmapSummary = useMemo(() => {
    let healthy = 0, monitor = 0, diseased = 0;
    filteredHeatmapTrees.forEach((t) => {
      if (t.status === "Healthy" || t.status === "Khỏe mạnh") healthy++;
      else if (t.status === "Monitoring" || t.status === "Đang theo dõi") monitor++;
      else diseased++;
    });
    return { healthy, monitor, diseased };
  }, [filteredHeatmapTrees]);

  const filteredHealthyPercent = kpiTotalTrees > 0 ? Math.round((kpiHealthyCount / kpiTotalTrees) * 100) : 0;

  const filteredZoneCount = useMemo(() => new Set(filteredHeatmapTrees.map((t) => t.zone_id)).size, [filteredHeatmapTrees]);

  const filteredFarmAreaFormatted = useMemo(() => {
    if (farmFilter !== "all") {
      const farm = widgets.farms.find((f) => f.id === farmFilter);
      return farm ? `${farm.name}` : "0 ha";
    }
    const farmIds = new Set(filteredHeatmapTrees.map((t) => t.farm_id).filter(Boolean));
    return `${farmIds.size} trang trại`;
  }, [filteredHeatmapTrees, farmFilter, widgets.farms]);

  const zoneSections: ZoneSection[] = useMemo(() => {
    const nameGroups = new Map<string, HeatmapTree[]>();
    for (const t of filteredHeatmapTrees) {
      const zoneName = t.zone_name || t.zone_id || "Chưa xác định";
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
  }, [filteredHeatmapTrees]);

  const heatmapLastUpdated = useMemo(() => {
    if (widgets.inspections.length === 0) return "—";
    const latest = widgets.inspections[0]?.time;
    return latest || "—";
  }, [widgets.inspections]);

  const filteredFarmHealthData = useMemo(() => [
    { name: "Khỏe mạnh", value: kpiHealthyCount, color: "#22C55E" },
    { name: "Theo dõi", value: kpiMonitoringCount, color: "#EAB308" },
    { name: "Bị bệnh", value: kpiDiseasedCount, color: "#EF4444" },
  ], [kpiHealthyCount, kpiMonitoringCount, kpiDiseasedCount]);

  const filteredInspectionRows: InspectionRow[] = useMemo(() => {
    if (farmFilter === "all" && zoneFilter === "all") return widgets.inspections;
    return widgets.inspections.filter((i) => {
      const matchesFarm = farmFilter === "all" || i.farm === widgets.farms.find((f) => f.id === farmFilter)?.name;
      const matchesZone = zoneFilter === "all" || i.zone === widgets.zones.find((z) => z.id === zoneFilter)?.name;
      return matchesFarm && matchesZone;
    });
  }, [widgets.inspections, widgets.farms, widgets.zones, farmFilter, zoneFilter]);

  const filteredPriorityTrees: RecommendationRow[] = useMemo(() => {
    if (farmFilter === "all" && zoneFilter === "all") return widgets.priorityTrees;
    return widgets.priorityTrees.filter((t) => {
      const matchesFarm = farmFilter === "all" || t.farm === widgets.farms.find((f) => f.id === farmFilter)?.name;
      const matchesZone = zoneFilter === "all" || t.zone === widgets.zones.find((z) => z.id === zoneFilter)?.name;
      return matchesFarm && matchesZone;
    });
  }, [widgets.priorityTrees, widgets.farms, widgets.zones, farmFilter, zoneFilter]);

  const filteredAlertCounts: WidgetAlertCounts = useMemo(() => {
    if (farmFilter === "all" && zoneFilter === "all") return widgets.alertCounts;
    const filteredAlerts = widgets.alerts.filter((a) => {
      if (!a.treeId) return true;
      return true;
    });
    const high = filteredAlerts.filter((a) => a.priority.toLowerCase() === "high").length;
    const medium = filteredAlerts.filter((a) => a.priority.toLowerCase() === "medium").length;
    const low = filteredAlerts.filter((a) => a.priority.toLowerCase() === "low").length;
    return { high, medium, low };
  }, [widgets.alerts, widgets.alertCounts, farmFilter, zoneFilter]);

  const filteredHighRiskCount = useMemo(
    () => filteredPriorityTrees.filter((t) => t.riskScore >= 90).length,
    [filteredPriorityTrees],
  );

  const farmStatus = useMemo(() => {
    if (filteredPriorityTrees.length === 0) return "Healthy";
    const maxConfidence = Math.max(...filteredPriorityTrees.map((t) => t.riskScore));
    if (maxConfidence >= 90) return "Critical";
    if (maxConfidence >= 80) return "Warning";
    return "Healthy";
  }, [filteredPriorityTrees]);

  return (
    <div className="flex flex-col bg-[#F5F7FB] space-y-5 pb-10 min-h-0 flex-1">
      {/* HEADER */}
      <DashboardHeader loading={anyLoading} onRefresh={fetchAll} />

      {error && (
        <div className="p-4 bg-red-50 border border-red-100 text-red-700 rounded-[16px] text-sm font-semibold" role="alert">
          {error}
        </div>
      )}

      {/* ONBOARDING ACTIVATION BANNER FOR NEW USERS */}
      {!isAdmin && (
        <div className="bg-gradient-to-r from-emerald-800 via-teal-800 to-green-900 text-white p-4.5 rounded-[22px] shadow-md flex flex-col md:flex-row items-start md:items-center justify-between gap-4 border border-emerald-500/30">
          <div className="flex items-center gap-3.5">
            <div className="w-11 h-11 rounded-[16px] bg-white/10 backdrop-blur-md flex items-center justify-center border border-white/20 flex-shrink-0 shadow-inner">
              <span className="text-2xl">🌱</span>
            </div>
            <div>
              <h3 className="text-sm font-black flex items-center gap-2 tracking-tight">
                Bắt Đầu Kích Hoạt Trang Trại & Kết Nối Thiết Bị IoT
                <span className="text-[10px] font-black bg-amber-400 text-gray-900 px-2 py-0.5 rounded-full uppercase tracking-wider">Hướng dẫn Mới</span>
              </h3>
              <p className="text-xs text-emerald-100/90 mt-0.5 font-medium leading-relaxed">
                Vườn của bạn cần hoàn tất kết nối cảm biến IoT để AI mở khóa tính năng tự động Cảnh báo & Khuyến nghị kỹ thuật.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2.5 w-full md:w-auto flex-shrink-0">
            <a
              href="/register-farm"
              className="px-4 py-2.5 bg-emerald-600 hover:bg-emerald-500 text-white font-extrabold text-xs rounded-[14px] shadow-md hover:shadow-lg whitespace-nowrap transition-all cursor-pointer"
            >
              + Đăng Ký Vườn Mới
            </a>
            <a
              href="/iot-setup-guide"
              className="px-4 py-2.5 bg-amber-400 hover:bg-amber-300 text-gray-900 font-extrabold text-xs rounded-[14px] shadow-md hover:shadow-lg whitespace-nowrap transition-all cursor-pointer"
            >
              🚀 Hướng Dẫn Lắp Đặt IoT
            </a>
          </div>
        </div>
      )}

      {/* ROW 1: KPI CARDS */}
      <div className="w-full">
        {dashboardLoading ? (
          <div className={`grid grid-cols-1 ${isAdmin ? "md:grid-cols-3" : "sm:grid-cols-2 lg:grid-cols-5"} gap-4`}>
            {Array.from({ length: isAdmin ? 3 : 5 }).map((_, i) => <KPISkeleton key={i} />)}
          </div>
        ) : (
          <KPISection
            isAdmin={isAdmin}
            totalUsers={backendKpi.total_users || 0}
            totalFarms={backendKpi.total_farms || 0}
            totalTrees={kpiTotalTrees || 0}
            healthyTrees={kpiHealthyCount || 0}
            diseasedTrees={kpiDiseasedCount || 0}
            highRiskTrees={kpiEmergencyCount || 0}
            areaHectare={backendKpi.area_hectare || 0}
            farmCount={backendKpi.total_farms || 0}
            zoneCount={backendKpi.total_zones || 0}
            estimatedYield={backendKpi.estimated_yield || 0}
          />
        )}
      </div>

      {/* ROW 2: MAIN VISUAL & SPATIAL OPERATIONS (HEATMAP 2/3 + WEATHER 1/3) */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-5 items-stretch w-full">
        {/* Col 1-2: Heatmap Card (2/3 width) */}
        <div className="lg:col-span-2 h-[450px] min-h-[450px] w-full min-w-0">
          {heatmapLoading ? (
            <CardSkeleton height="100%"><div className="bg-gray-200 animate-pulse flex-1 w-full rounded-[12px]" /></CardSkeleton>
          ) : (
            <HeatmapCard
              sections={zoneSections}
              lastUpdated={heatmapLastUpdated}
              summaryCounts={heatmapSummary}
              onRefresh={fetchAll}
              farmOptions={farmOptions}
              zoneOptions={zoneOptions}
              selectedFarm={farmFilter}
              selectedZone={zoneFilter}
              onFarmChange={setFarmFilter}
              onZoneChange={setZoneFilter}
            />
          )}
        </div>

        {/* Col 3: Realtime Weather Card (1/3 width) */}
        <div className="lg:col-span-1 h-[450px] min-h-[450px] w-full">
          <WeatherCard />
        </div>
      </div>

      {/* ROW 3: SYSTEM OVERVIEW, TREE HEALTH & PERFORMANCE */}
      {isAdmin ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 items-stretch w-full">
          {/* Col 1: System Overview */}
          <div className="h-[340px] min-h-[340px] w-full">
            {dashboardLoading ? (
              <CardSkeleton height="100%"><div className="flex-1 bg-gray-200 rounded-[12px] animate-pulse" /></CardSkeleton>
            ) : (
              <SystemOverviewCard data={systemOverview} variant="admin" />
            )}
          </div>

          {/* Col 2: Regional Farm Map Card */}
          <div className="h-[340px] min-h-[340px] w-full min-w-0">
            {heatmapLoading ? (
              <CardSkeleton height="100%"><div className="bg-gray-200 animate-pulse flex-1 w-full rounded-[12px]" /></CardSkeleton>
            ) : (
              <RegionalFarmMapCard />
            )}
          </div>

          {/* Col 3: Growth Trend Card */}
          <div className="h-[340px] min-h-[340px] w-full">
            <GrowthTrendCard />
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5 items-stretch w-full">
          {/* Col 1: System Overview (IoT Inventory) */}
          <div className="h-[340px] min-h-[340px] w-full">
            {dashboardLoading ? (
              <CardSkeleton height="100%"><div className="flex-1 bg-gray-200 rounded-[12px] animate-pulse" /></CardSkeleton>
            ) : (
              <SystemOverviewCard data={systemOverview} variant="user" />
            )}
          </div>

          {/* Col 2: Tree Distribution Donut Chart */}
          <div className="h-[340px] min-h-[340px] w-full">
            {dashboardLoading ? (
              <CardSkeleton height="100%"><div className="flex-1 flex items-center gap-4"><div className="bg-gray-200 rounded-full animate-pulse flex-1 h-full" /><div className="bg-gray-200 rounded-[6px] animate-pulse w-[100px] h-16" /></div></CardSkeleton>
            ) : (
              <TreeDistributionCard data={filteredFarmHealthData} total={kpiTotalTrees} />
            )}
          </div>

          {/* Col 3: Farm Performance Card */}
          <div className="h-[340px] min-h-[340px] w-full">
            <FarmPerformanceCard />
          </div>
        </div>
      )}

      {/* ROW 4: REALTIME FIELD INSPECTIONS (DEDICATED FULL/WIDE CARD) */}
      <div className="w-full h-[350px] min-h-[350px]">
        <RealtimeInspectionCard data={filteredInspectionRows} />
      </div>

      {/* FLOATING AI CHATBOT BUBBLE */}
      <AIChatbotCard />
    </div>
  );
}
