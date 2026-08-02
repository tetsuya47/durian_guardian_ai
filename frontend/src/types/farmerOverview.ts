export interface FarmerAddress {
  province?: string | null;
  district?: string | null;
  ward?: string | null;
  detail?: string | null;
}

export interface FarmerProfile {
  user_id: string;
  user_code: string;
  full_name: string;
  email?: string | null;
  phone?: string | null;
  role: string;
  status?: string | null;
  address?: FarmerAddress | null;
  avatar?: string | null;
  farm_name?: string | null;
  company_name?: string | null;
  created_at?: string | null;
}

export interface FarmOverview {
  total_farms: number;
  total_zones: number;
  total_trees: number;
  total_area_hectare: number;
  districts: string[];
}

export interface InspectionStats {
  total_inspections: number;
  last_inspection?: string | null;
}

export interface DetectionStats {
  healthy: number;
  diseased: number;
  detection_rate: number;
}

export interface InspectionOverview {
  inspection: InspectionStats;
  detection: DetectionStats;
}

export interface AlertOverview {
  total_alerts: number;
  critical: number;
  warning: number;
  normal: number;
  raw_priority: Record<string, number>;
}

export interface NeighborOverview {
  sent_requests: number;
  received_requests: number;
  pending: number;
  waiting_source_consent: number;
  waiting_target_consent: number;
  contact_shared: number;
  rejected: number;
  cancelled: number;
}

export interface ActivityItem {
  type: string;
  source: "inspection" | "detection" | "alert" | "neighbor";
  timestamp: string;
  entity_id?: string | null;
  entity_code?: string | null;
  detail: string;
}

export interface FarmerOverview {
  profile: FarmerProfile;
  farm: FarmOverview;
  inspection: InspectionOverview;
  alerts: AlertOverview;
  neighbor: NeighborOverview;
  activities: ActivityItem[];
}
