import { Users, Building2, Trees, ShieldAlert, TrendingUp, HeartPulse, Compass } from "lucide-react";
import KPICard from "./KPICard";

interface KPISectionProps {
  isAdmin?: boolean;
  totalUsers?: number;
  totalFarms?: number;
  totalTrees?: number;
  healthyTrees?: number;
  diseasedTrees?: number;
  highRiskTrees?: number;
  areaHectare?: number;
  farmCount?: number;
  zoneCount?: number;
  estimatedYield?: number;
}

export default function KPISection({
  isAdmin = true,
  totalUsers = 0,
  totalFarms = 0,
  totalTrees = 0,
  healthyTrees = 0,
  highRiskTrees = 0,
  areaHectare = 0,
  farmCount = 0,
  zoneCount = 0,
  estimatedYield = 0,
}: KPISectionProps) {
  // 1. ADMIN DASHBOARD VIEW: 3 Core System Metrics (UNTOUCHED FOR WEB ADMIN)
  if (isAdmin) {
    return (
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4" style={{ gap: "16px" }}>
        <KPICard
          icon={<Users className="w-7 h-7 text-blue-600" />}
          iconBg="bg-blue-100"
          title="TỔNG SỐ NGƯỜI DÙNG"
          value={totalUsers.toLocaleString()}
          valueSuffix="người dùng"
          subtitle="Tài khoản khách hàng & quản trị"
          valueColor="text-[#111827]"
        />
        <KPICard
          icon={<Building2 className="w-7 h-7 text-amber-600" />}
          iconBg="bg-amber-100"
          title="TỔNG NÔNG TRẠI"
          value={totalFarms.toLocaleString()}
          valueSuffix="trang trại"
          subtitle="Nông trại đang quản lý"
          valueColor="text-[#111827]"
        />
        <KPICard
          icon={<Trees className="w-7 h-7 text-emerald-600" />}
          iconBg="bg-emerald-100"
          title="TỔNG CÂY ĐANG QUẢN LÝ"
          value={totalTrees.toLocaleString()}
          valueSuffix="cây trồng"
          subtitle="Toàn bộ cây sầu riêng hệ thống"
          valueColor="text-[#111827]"
        />
      </div>
    );
  }

  // 2. USER DASHBOARD VIEW: 5 Farmer-Centric KPI Metrics (WEB USER ONLY)
  const healthPercent = totalTrees > 0 ? ((healthyTrees / totalTrees) * 100).toFixed(1) : "0.0";

  return (
    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4" style={{ gap: "16px" }}>
      {/* Card 1: Tổng Số Cây */}
      <KPICard
        icon={<Trees className="w-6 h-6 text-emerald-600" />}
        iconBg="bg-emerald-100"
        title="TỔNG SỐ CÂY"
        value={totalTrees.toLocaleString()}
        valueSuffix="cây"
        subtitle="+0 Cây tháng này"
        subtitleColor="#15803D"
        valueColor="text-[#111827]"
      />

      {/* Card 2: Diện Tích Canh Tác */}
      <KPICard
        icon={<Compass className="w-6 h-6 text-emerald-600" />}
        iconBg="bg-emerald-100"
        title="DIỆN TÍCH CANH TÁC"
        value={areaHectare.toString()}
        valueSuffix="ha"
        subtitle={`${farmCount} Trang trại · ${zoneCount} Khu vực`}
        subtitleColor="#475569"
        valueColor="text-[#111827]"
      />

      {/* Card 3: Sức Khỏe Vườn Cây */}
      <KPICard
        icon={<HeartPulse className="w-6 h-6 text-emerald-600" />}
        iconBg="bg-emerald-100"
        title="SỨC KHỎE VƯỜN CÂY"
        value={`${healthPercent}%`}
        subtitle="Tỷ lệ cây khỏe mạnh"
        subtitleColor="#15803D"
        valueColor="text-[#15803D]"
      />

      {/* Card 4: Cảnh Báo Nguy Cơ Cao */}
      <KPICard
        icon={<ShieldAlert className="w-6 h-6 text-red-600" />}
        iconBg="bg-red-50"
        title="CẢNH BÁO NGUY CƠ CAO"
        value={highRiskTrees.toLocaleString()}
        valueSuffix="cây"
        subtitle="Cây nguy cơ cao (>80%)"
        subtitleColor="#DC2626"
        valueColor="text-[#DC2626]"
      />

      {/* Card 5: Ước Tính Sản Lượng */}
      <KPICard
        icon={<TrendingUp className="w-6 h-6 text-emerald-600" />}
        iconBg="bg-emerald-100"
        title="ƯỚC TÍNH SẢN LƯỢNG"
        value={estimatedYield.toString()}
        valueSuffix="Tấn"
        subtitle="Ước tính vụ 2026"
        subtitleColor="#15803D"
        valueColor="text-[#111827]"
      />
    </div>
  );
}
