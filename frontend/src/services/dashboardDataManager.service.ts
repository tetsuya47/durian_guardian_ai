import api from "../api";

export interface BackendKpi {
  total_farms: number;
  total_trees: number;
  healthy_trees: number;
  diseased_trees: number;
  high_risk_trees: number;
}

export interface SystemOverviewData {
  inspection_today: number;
  ai_detection_today: number;
  new_alerts_today: number;
  pending_review: number;
  updated_at: string;
}

export interface HeatmapTree {
  tree_id: string;
  tree_code: string;
  zone_id: string;
  zone_name: string;
  farm_id: string;
  status: string;
}

export interface WidgetInspection {
  id: string;
  time: string;
  treeCode: string;
  farm: string;
  zone: string;
  disease: string;
  risk: number;
  inspector: string;
  status: string;
  action: string;
}

export interface WidgetDetection {
  id: string;
  treeCode: string;
  disease: string;
  confidence: number;
  severity: string;
  farm: string;
  zone: string;
  imageUrl: string | null;
  createdAt: string;
}

export interface WidgetPriorityTree {
  id: number;
  treeId: string;
  riskScore: number;
  status: string;
  farm: string;
  zone: string;
  disease: string;
}

export interface WidgetAlertCounts {
  high: number;
  medium: number;
  low: number;
}

export interface WidgetAlert {
  id: string;
  treeId: string;
  priority: string;
  title: string;
  content: string;
  createdAt: string;
}

export interface WidgetFarmOption {
  id: string;
  name: string;
}

export interface WidgetZoneOption {
  id: string;
  name: string;
}

export interface WidgetsData {
  inspections: WidgetInspection[];
  detections: WidgetDetection[];
  priorityTrees: WidgetPriorityTree[];
  alertCounts: WidgetAlertCounts;
  alerts: WidgetAlert[];
  farms: WidgetFarmOption[];
  zones: WidgetZoneOption[];
}

export interface DashboardResult {
  backendKpi: BackendKpi;
  systemOverview: SystemOverviewData;
}

export interface HeatmapResult {
  heatmapData: HeatmapTree[];
}

export interface WidgetsResult {
  widgets: WidgetsData;
}

const DEFAULT_KPI: BackendKpi = {
  total_farms: 0, total_trees: 0, healthy_trees: 0, diseased_trees: 0, high_risk_trees: 0,
};
const DEFAULT_OVERVIEW: SystemOverviewData = {
  inspection_today: 0, ai_detection_today: 0, new_alerts_today: 0, pending_review: 0, updated_at: "",
};
const DEFAULT_WIDGETS: WidgetsData = {
  inspections: [], detections: [], priorityTrees: [],
  alertCounts: { high: 0, medium: 0, low: 0 },
  alerts: [], farms: [], zones: [],
};

export async function loadDashboardCore(): Promise<DashboardResult> {
  try {
    const resp = await api.get("/dashboard").then((r) => r.data);
    return {
      backendKpi: resp?.kpi ?? DEFAULT_KPI,
      systemOverview: resp?.system_overview ?? DEFAULT_OVERVIEW,
    };
  } catch {
    return { backendKpi: DEFAULT_KPI, systemOverview: DEFAULT_OVERVIEW };
  }
}

export async function loadHeatmap(): Promise<HeatmapResult> {
  try {
    const resp = await api.get("/dashboard/heatmap").then((r) => r.data);
    return { heatmapData: resp?.data ?? [] };
  } catch {
    return { heatmapData: [] };
  }
}

export async function loadWidgets(): Promise<WidgetsResult> {
  try {
    const resp = await api.get("/dashboard/widgets").then((r) => r.data);
    return {
      widgets: resp ?? DEFAULT_WIDGETS,
    };
  } catch {
    return { widgets: DEFAULT_WIDGETS };
  }
}

// ── Farm Dashboard ────────────────────────────────────────────────

export interface FarmDashboardKpi {
  total_trees: number;
  total_zones: number;
  healthy_percent: number;
  high_risk_trees: number;
  estimated_yield: string;
}

export interface FarmHealthDistribution {
  healthy: number;
  monitoring: number;
  diseased: number;
}

export interface FarmHeatmapTree {
  tree_id: string;
  tree_code: string;
  zone_id: string;
  zone_name: string;
  status: string;
}

export interface FarmZone {
  id: string;
  name: string;
  tree_count: number;
  healthy_count: number;
  diseased_count: number;
  risk_level: string;
}

export interface FarmYield {
  estimated_yield: string;
  avg_yield_per_tree: string;
  avg_yield_per_hectare: string;
}

export interface FarmAlertSummary {
  high: number;
  medium: number;
  low: number;
}

export interface FarmDashboardData {
  kpi: FarmDashboardKpi;
  health_distribution: FarmHealthDistribution;
  heatmap: FarmHeatmapTree[];
  zones: FarmZone[];
  yield_data: FarmYield;
  alerts: FarmAlertSummary;
}

const DEFAULT_FARM_DASHBOARD: FarmDashboardData = {
  kpi: { total_trees: 0, total_zones: 0, healthy_percent: 0, high_risk_trees: 0, estimated_yield: "--" },
  health_distribution: { healthy: 0, monitoring: 0, diseased: 0 },
  heatmap: [],
  zones: [],
  yield_data: { estimated_yield: "--", avg_yield_per_tree: "--", avg_yield_per_hectare: "--" },
  alerts: { high: 0, medium: 0, low: 0 },
};

export async function loadFarmDashboard(farmId: string): Promise<FarmDashboardData> {
  try {
    const resp = await api.get(`/dashboard/farm/${farmId}`).then((r) => r.data);
    return resp ?? DEFAULT_FARM_DASHBOARD;
  } catch {
    return DEFAULT_FARM_DASHBOARD;
  }
}
