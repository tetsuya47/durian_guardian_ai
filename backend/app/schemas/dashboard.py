from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel


class DetectionBrief(BaseModel):
    disease: str
    confidence: float
    severity: str
    tree_code: str
    image_url: str | None = None
    created_at: datetime


class AlertBrief(BaseModel):
    title: str
    content: str
    created_at: datetime


class KpiData(BaseModel):
    total_users: int = 0
    total_farms: int
    total_trees: int
    healthy_trees: int
    diseased_trees: int
    high_risk_trees: int


class RiskTrendItem(BaseModel):
    date: str
    avg_risk: float


class GrowthTrendItem(BaseModel):
    month: str
    new_users: int
    new_farms: int


class SystemOverview(BaseModel):
    inspection_today: int
    ai_detection_today: int
    new_alerts_today: int
    pending_review: int
    active_iot_devices: int = 0
    in_stock_iot_devices: int = 0
    maintenance_iot_devices: int = 0
    updated_at: datetime


class DashboardOut(BaseModel):
    kpi: KpiData
    system_overview: SystemOverview
    recent_detection: list[DetectionBrief]
    alerts: list[AlertBrief]
    risk_trend: list[RiskTrendItem]
    growth_trend: list[GrowthTrendItem] = []


class WidgetInspection(BaseModel):
    id: str
    time: str
    treeCode: str
    farm: str
    zone: str
    disease: str
    risk: float
    inspector: str
    status: str
    action: str


class WidgetDetection(BaseModel):
    id: str
    treeCode: str
    disease: str
    confidence: float
    severity: str
    farm: str
    zone: str
    imageUrl: str | None = None
    createdAt: str


class WidgetPriorityTree(BaseModel):
    id: int
    treeId: str
    riskScore: int
    status: str
    farm: str
    zone: str
    disease: str


class WidgetAlert(BaseModel):
    id: str
    treeId: str
    priority: str
    title: str
    content: str
    createdAt: str


class WidgetAlertCounts(BaseModel):
    high: int
    medium: int
    low: int


class WidgetFarmOption(BaseModel):
    id: str
    name: str


class WidgetZoneOption(BaseModel):
    id: str
    name: str


class WidgetsOut(BaseModel):
    inspections: list[WidgetInspection]
    detections: list[WidgetDetection]
    priorityTrees: list[WidgetPriorityTree]
    alertCounts: WidgetAlertCounts
    alerts: list[WidgetAlert]
    farms: list[WidgetFarmOption]
    zones: list[WidgetZoneOption]


# ── Farm Dashboard DTOs ──────────────────────────────────────────────


class FarmDashboardKpi(BaseModel):
    total_trees: int
    total_zones: int
    healthy_percent: float
    high_risk_trees: int
    estimated_yield: str
    farm_score: float | None = None
    health_score: float | None = None
    yield_score: float | None = None
    risk_index: float | None = None
    overall_status: str | None = None
    target_yield: float | None = None
    target_tree_health: float | None = None
    target_disease_rate: float | None = None


class FarmHealthDistribution(BaseModel):
    healthy: int
    monitoring: int
    diseased: int


class FarmHeatmapTree(BaseModel):
    tree_id: str
    tree_code: str
    zone_id: str
    zone_name: str
    status: str


class FarmZone(BaseModel):
    id: str
    name: str
    tree_count: int
    healthy_count: int
    diseased_count: int
    risk_level: str


class FarmYield(BaseModel):
    estimated_yield: str
    avg_yield_per_tree: str
    avg_yield_per_hectare: str
    yield_kg: float | None = None
    average_weight: float | None = None
    grade_a: float | None = None
    grade_b: float | None = None
    grade_c: float | None = None
    selling_price: float | None = None
    total_revenue: float | None = None
    buyer: str | None = None


class FarmAlertSummary(BaseModel):
    high: int
    medium: int
    low: int


class FarmDashboardOut(BaseModel):
    kpi: FarmDashboardKpi
    health_distribution: FarmHealthDistribution
    heatmap: list[FarmHeatmapTree]
    zones: list[FarmZone]
    yield_data: FarmYield
    alerts: FarmAlertSummary
    season_name: str | None = None
    season_year: int | None = None
