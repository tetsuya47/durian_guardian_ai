import api from "../api";

export interface BackendKpi {
  total_users?: number;
  total_farms: number;
  total_trees: number;
  healthy_trees: number;
  diseased_trees: number;
  high_risk_trees: number;
  area_hectare?: number;
  total_zones?: number;
  estimated_yield?: number;
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

// ── EXACT ORIGINAL DATA FOR WEB USER DASHBOARD (350 TREES / 3.5 HA / KRÔNG PẮC POLYGON) ──
const FALLBACK_KPI: BackendKpi = {
  total_farms: 1,
  total_trees: 350,
  healthy_trees: 342,
  diseased_trees: 8,
  high_risk_trees: 4,
  area_hectare: 3.5,
  total_zones: 2,
  estimated_yield: 12,
};

const FALLBACK_OVERVIEW: SystemOverviewData = {
  inspection_today: 4,
  ai_detection_today: 2,
  new_alerts_today: 1,
  pending_review: 0,
  updated_at: "Hôm nay, 19:30",
};

const FALLBACK_FARMS: WidgetFarmOption[] = [
  {
    id: "farm-1",
    name: "Trang trại Sầu Riêng Krông Pắc (Đắk Lắk)",
    gps_lat: 12.6851,
    gps_lng: 108.0387,
    calculated_area_hectare: 3.48,
    calculated_perimeter_meters: 815,
    elevation_msl_meters: 525,
    slope_gradient_percent: 8.2,
    slope_aspect_heading: "Đông - Đông Nam",
    soil_texture_type: "Đất đỏ Bazan nguyên sinh",
    boundary_points: [
      { lat: 12.6862, lng: 108.0375 },
      { lat: 12.6870, lng: 108.0398 },
      { lat: 12.6845, lng: 108.0405 },
      { lat: 12.6838, lng: 108.0380 },
    ],
  },
  {
    id: "farm-2",
    name: "Trang trại Sầu Riêng Cư M'gar (Đắk Lắk)",
    gps_lat: 12.7210,
    gps_lng: 108.0820,
    calculated_area_hectare: 4.25,
    calculated_perimeter_meters: 940,
    elevation_msl_meters: 480,
    slope_gradient_percent: 6.5,
    slope_aspect_heading: "Nam - Đông Nam",
    soil_texture_type: "Đất phù sa cổ",
    boundary_points: [
      { lat: 12.7225, lng: 108.0805 },
      { lat: 12.7232, lng: 108.0835 },
      { lat: 12.7198, lng: 108.0840 },
      { lat: 12.7190, lng: 108.0810 },
    ],
  },
  {
    id: "farm-3",
    name: "Trang trại Sầu Riêng Ea Kar (Đắk Lắk)",
    gps_lat: 12.6500,
    gps_lng: 108.0100,
    calculated_area_hectare: 5.10,
    calculated_perimeter_meters: 1050,
    elevation_msl_meters: 550,
    slope_gradient_percent: 9.0,
    slope_aspect_heading: "Tây Bắc",
    soil_texture_type: "Đất đỏ Bazan",
    boundary_points: [
      { lat: 12.6515, lng: 108.0085 },
      { lat: 12.6522, lng: 108.0115 },
      { lat: 12.6485, lng: 108.0120 },
      { lat: 12.6480, lng: 108.0090 },
    ],
  },
];

const FALLBACK_HEATMAP: HeatmapTree[] = [
  { tree_id: "t1", tree_code: "SR-001", zone_id: "z1", zone_name: "Khu A1 (Ri6)", farm_id: "farm-1", status: "HEALTHY" },
  { tree_id: "t2", tree_code: "SR-002", zone_id: "z1", zone_name: "Khu A1 (Ri6)", farm_id: "farm-1", status: "HEALTHY" },
  { tree_id: "t3", tree_code: "SR-003", zone_id: "z1", zone_name: "Khu A1 (Ri6)", farm_id: "farm-1", status: "WARNING" },
  { tree_id: "t4", tree_code: "SR-004", zone_id: "z1", zone_name: "Khu A1 (Ri6)", farm_id: "farm-1", status: "DISEASED" },
  { tree_id: "t5", tree_code: "SR-005", zone_id: "z2", zone_name: "Khu B1 (Monthong)", farm_id: "farm-1", status: "HEALTHY" },
  { tree_id: "t6", tree_code: "SR-006", zone_id: "z2", zone_name: "Khu B1 (Monthong)", farm_id: "farm-1", status: "HEALTHY" },
  { tree_id: "t7", tree_code: "SR-007", zone_id: "z2", zone_name: "Khu B1 (Monthong)", farm_id: "farm-1", status: "DISEASED" },
];

const FALLBACK_WIDGETS: WidgetsData = {
  inspections: [
    {
      id: "insp-1",
      time: "10:30 Hôm nay",
      treeCode: "SR-004",
      farm: "Krông Pắc",
      zone: "Khu A1",
      disease: "Bệnh Thán Thư",
      risk: 85,
      inspector: "Nguyễn Văn Tèo",
      status: "Cần xử lý",
      action: "Phun thuốc Ridomil Gold",
    },
    {
      id: "insp-2",
      time: "08:15 Hôm nay",
      treeCode: "SR-007",
      farm: "Krông Pắc",
      zone: "Khu B1",
      disease: "Nấm Phytophthora",
      risk: 92,
      inspector: "Nguyễn Văn Tèo",
      status: "Đang theo dõi",
      action: "Quét vôi gốc & thoát nước",
    },
  ],
  detections: [],
  priorityTrees: [
    { id: 1, treeId: "SR-004", riskScore: 92, status: "NGUY CƠ CAO", farm: "Krông Pắc", zone: "Khu A1", disease: "Nấm Phytophthora" },
    { id: 2, treeId: "SR-007", riskScore: 85, status: "NGUY CƠ CAO", farm: "Krông Pắc", zone: "Khu B1", disease: "Thán Thư Lá" },
  ],
  alertCounts: { high: 2, medium: 2, low: 0 },
  alerts: [
    { id: "a1", treeId: "SR-004", priority: "HIGH", title: "Cảnh báo nấm Phytophthora", content: "Phát hiện xì mủ thối gốc tại cây SR-004", createdAt: "2026-08-05T08:00:00Z" },
    { id: "a2", treeId: "SR-007", priority: "HIGH", title: "Cảnh báo bệnh Thán Thư", content: "Vết bệnh lan rộng 15% diện tích lá tại SR-007", createdAt: "2026-08-05T09:30:00Z" },
  ],
  farms: FALLBACK_FARMS,
  zones: [
    { id: "z1", name: "Khu A1 (Ri6)" },
    { id: "z2", name: "Khu B1 (Monthong)" },
  ],
};

export const EMPTY_USER_KPI: BackendKpi = {
  total_farms: 0,
  total_trees: 0,
  healthy_trees: 0,
  diseased_trees: 0,
  high_risk_trees: 0,
  area_hectare: 0,
  total_zones: 0,
  estimated_yield: 0,
};

export const EMPTY_USER_WIDGETS: WidgetsData = {
  inspections: [],
  detections: [],
  priorityTrees: [],
  alertCounts: { high: 0, medium: 0, low: 0 },
  alerts: [],
  farms: [],
  zones: [],
};

export async function loadDashboardCore(): Promise<DashboardResult> {
  try {
    const res = await api.get("/api/v1/dashboard");
    const rawData = res.data?.data || res.data;
    const backendKpi = rawData?.kpi || res.data?.kpi;
    const systemOverview = rawData?.system_overview || res.data?.system_overview;
    if (backendKpi !== undefined && backendKpi !== null) {
      return {
        backendKpi,
        systemOverview: systemOverview || FALLBACK_OVERVIEW,
      };
    }
    return {
      backendKpi: FALLBACK_KPI,
      systemOverview: FALLBACK_OVERVIEW,
    };
  } catch {
    return {
      backendKpi: FALLBACK_KPI,
      systemOverview: FALLBACK_OVERVIEW,
    };
  }
}

export async function loadHeatmap(): Promise<HeatmapResult> {
  try {
    const res = await api.get("/api/v1/dashboard/heatmap");
    const rawData = res.data?.data || res.data;
    const list = Array.isArray(rawData) ? rawData : rawData?.data || rawData?.trees;
    return { heatmapData: Array.isArray(list) ? list : FALLBACK_HEATMAP };
  } catch {
    return { heatmapData: FALLBACK_HEATMAP };
  }
}

export async function loadWidgets(): Promise<WidgetsResult> {
  try {
    const res = await api.get("/api/v1/dashboard/widgets");
    const rawData = res.data?.data || res.data;
    if (rawData && (Array.isArray(rawData.farms) || Array.isArray(rawData.inspections))) {
      return {
        widgets: {
          inspections: rawData.inspections || [],
          detections: rawData.detections || [],
          priorityTrees: rawData.priorityTrees || [],
          alertCounts: rawData.alertCounts || { high: 0, medium: 0, low: 0 },
          alerts: rawData.alerts || [],
          farms: rawData.farms || [],
          zones: rawData.zones || [],
        },
      };
    }
    return {
      widgets: FALLBACK_WIDGETS,
    };
  } catch {
    return {
      widgets: FALLBACK_WIDGETS,
    };
  }
}

// ── Farm Dashboard ────────────────────────────────────────────────

export interface FarmDashboardKpi {
  total_trees: number;
  total_zones: number;
  healthy_percent: number;
  high_risk_trees: number;
  estimated_yield: string;
  farm_score?: number;
  health_score?: number;
  yield_score?: number;
  risk_index?: number;
  overall_status?: string;
  target_yield?: number;
  target_tree_health?: number;
  target_disease_rate?: number;
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
  yield_kg?: number;
  average_weight?: number;
  grade_a?: number;
  grade_b?: number;
  grade_c?: number;
  selling_price?: number;
  total_revenue?: number;
  buyer?: string;
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
  season_name?: string;
  season_year?: number;
}

const DEFAULT_FARM_DASHBOARD: FarmDashboardData = {
  kpi: { total_trees: 350, total_zones: 2, healthy_percent: 97.7, high_risk_trees: 4, estimated_yield: "12 Tấn" },
  health_distribution: { healthy: 342, monitoring: 4, diseased: 4 },
  heatmap: [],
  zones: [],
  yield_data: { estimated_yield: "12 Tấn", avg_yield_per_tree: "34 kg", avg_yield_per_hectare: "3.4 Tấn" },
  alerts: { high: 2, medium: 2, low: 0 },
};

export async function loadFarmDashboard(farmId: string): Promise<FarmDashboardData> {
  try {
    const resp = await api.get(`/api/v1/dashboard/farm/${farmId}`).then((r) => r.data);
    return resp ?? DEFAULT_FARM_DASHBOARD;
  } catch {
    return DEFAULT_FARM_DASHBOARD;
  }
}

// ── Farm Performance (Enterprise Dashboard) ─────────────────────────

export interface FarmPerformanceDTO {
  average_farm_score: number | null;
  farms_evaluated: number;
  total_farms: number;
  healthy_percent: number | null;
  high_risk_count: number;
  total_target_yield: number | null;
  total_actual_yield: number | null;
  yield_achievement_pct: number | null;
  overall_status: string | null;
  ai_insight: string;
}

const DEFAULT_FARM_PERFORMANCE: FarmPerformanceDTO = {
  average_farm_score: 92,
  farms_evaluated: 1,
  total_farms: 1,
  healthy_percent: 97.7,
  high_risk_count: 4,
  total_target_yield: 15,
  total_actual_yield: 12,
  yield_achievement_pct: 80.0,
  overall_status: "Tốt",
  ai_insight: "Sức khỏe vườn sầu riêng Krông Pắc đạt 97.7%. Khuyến nghị chú ý phòng ngừa nấm Phytophthora mùa mưa.",
};

export async function loadFarmPerformance(farmId?: string): Promise<FarmPerformanceDTO> {
  try {
    const params: Record<string, string> = {};
    if (farmId) params.farm_id = farmId;
    const resp = await api.get("/api/v1/dashboard/farm-performance", { params }).then((r) => r.data);
    return resp ?? DEFAULT_FARM_PERFORMANCE;
  } catch {
    return DEFAULT_FARM_PERFORMANCE;
  }
}
