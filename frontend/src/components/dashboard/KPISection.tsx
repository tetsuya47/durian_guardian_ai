import { Trees, ShieldCheck, Heart, AlertTriangle, TrendingUp } from "lucide-react";
import KPICard from "./KPICard";

interface KPISectionProps {
  totalTrees: number;
  newTreesThisMonth: number;
  healthyPercent: number;
  farmArea: string;
  farmCount: number;
  zoneCount: number;
  emergencyCount: number;
}

export default function KPISection({
  totalTrees, newTreesThisMonth, healthyPercent,
  farmArea, farmCount, zoneCount, emergencyCount,
}: KPISectionProps) {
  return (
    <div className="grid grid-cols-5" style={{ gap: "20px" }}>
      <KPICard
        icon={<Trees className="w-7 h-7 text-emerald-600" />}
        iconBg="bg-emerald-100"
        title="TỔNG SỐ CÂY"
        value={totalTrees.toLocaleString()}
        subtitleLine1={`+${newTreesThisMonth} ${newTreesThisMonth === 1 ? "Cây" : "Cây"} tháng này`}
        subtitleLine2="So với tháng trước"
        valueColor="text-[#111827]"
      />
      <KPICard
        icon={<ShieldCheck className="w-7 h-7 text-emerald-600" />}
        iconBg="bg-amber-100"
        title="DIỆN TÍCH CANH TÁC"
        value={farmArea ? farmArea.split(" ")[0] : "0.0"}
        valueSuffix={farmArea ? farmArea.split(" ").slice(1).join(" ") : "ha"}
        subtitle={`${farmCount} Trang trại • ${zoneCount} Khu vực`}
      />
      <KPICard
        icon={<Heart className="w-7 h-7 text-emerald-600" />}
        iconBg="bg-emerald-100"
        title="SỨC KHỎE VƯỜN CÂY"
        value={`${healthyPercent}%`}
        subtitle="Tỷ lệ cây khỏe mạnh"
        subtitleColor={healthyPercent >= 90 ? "#15803D" : healthyPercent >= 70 ? "#D97706" : "#DC2626"}
        valueColor="text-emerald-600"
      />
      <KPICard
        icon={<AlertTriangle className="w-7 h-7 text-red-600" />}
        iconBg="bg-red-50"
        title="CẢNH BÁO NGUY CƠ CAO"
        value={String(emergencyCount)}
        subtitle="Cây nguy cơ cao (>80%)"
        valueColor="text-red-500"
      />
      <KPICard
        icon={<TrendingUp className="w-7 h-7 text-gray-400" />}
        iconBg="bg-gray-100"
        title="ƯỚC TÍNH SẢN LƯỢNG"
        value="--"
        subtitle="Sẽ khả dụng trong phiên bản AI"
        valueColor="text-gray-400"
      />
    </div>
  );
}
