import { Sprout, AlertCircle, CheckCircle2, Info, Lightbulb, Clock } from "lucide-react";
import Card from "./Shared/Card";

interface RecommendationRow {
  id: number;
  treeId: string;
  riskScore: number;
  status: string;
  farm: string;
  zone: string;
  disease: string;
}

interface AgronomistPanelProps {
  priorityTrees: RecommendationRow[];
  farmStatus: string;
  kpiHealthyCount: number;
  kpiMonitoringCount: number;
  kpiDiseasedCount: number;
  alertCounts: { high: number; medium: number; low: number };
  highRiskCount: number;
}

export default function AgronomistPanel(props: AgronomistPanelProps) {
  const { kpiHealthyCount, kpiMonitoringCount, kpiDiseasedCount, alertCounts, highRiskCount } = props;

  const totalTrees = kpiHealthyCount + kpiMonitoringCount + kpiDiseasedCount;
  const criticalAlertCount = alertCounts ? alertCounts.high : 0;
  const healthyPercent = totalTrees > 0 ? (kpiHealthyCount / totalTrees) * 100 : 0;
  const detectionRate = totalTrees > 0 ? ((kpiMonitoringCount + kpiDiseasedCount) / totalTrees) * 100 : 0;

  // RULE ENGINE - TÌNH TRẠNG
  let statusText = "Chưa đủ dữ liệu để đưa ra đánh giá.";
  let statusBorder = "border-l-gray-400";
  let statusTextColor = "text-gray-700";
  let StatusIcon = Info;

  if (totalTrees === 0) {
    statusText = "Chưa đủ dữ liệu để đưa ra đánh giá.";
    statusBorder = "border-l-gray-400";
    statusTextColor = "text-gray-700";
    StatusIcon = Info;
  } else if (criticalAlertCount > 0) {
    statusText = "Đã xuất hiện cảnh báo nghiêm trọng.\nCần xử lý sớm để hạn chế lây lan.";
    statusBorder = "border-l-red-500";
    statusTextColor = "text-red-700";
    StatusIcon = AlertCircle;
  } else if (highRiskCount > 0) {
    statusText = "Hệ thống ghi nhận cây có nguy cơ cao.\nCần ưu tiên kiểm tra các khu vực liên quan.";
    statusBorder = "border-l-amber-400";
    statusTextColor = "text-amber-800";
    StatusIcon = AlertCircle;
  } else if (detectionRate > 40) {
    statusText = "Tỷ lệ phát hiện bệnh đang ở mức cao.";
    statusBorder = "border-l-amber-400";
    statusTextColor = "text-amber-800";
    StatusIcon = AlertCircle;
  } else {
    statusText = "Vườn đang ở trạng thái ổn định.\nChưa ghi nhận khu vực có nguy cơ cao.";
    statusBorder = "border-l-emerald-500";
    statusTextColor = "text-emerald-800";
    StatusIcon = CheckCircle2;
  }

  // RULE ENGINE - KHUYẾN NGHỊ
  let recText = "Chưa đủ dữ liệu để đưa ra khuyến nghị.";

  if (totalTrees === 0) {
    recText = "Chưa đủ dữ liệu để đưa ra khuyến nghị.";
  } else if (criticalAlertCount > 0) {
    recText = "Xử lý các cảnh báo nghiêm trọng trước.";
  } else if (highRiskCount > kpiHealthyCount) {
    recText = "Ưu tiên kiểm tra các cây có nguy cơ cao.";
  } else if (healthyPercent > 80) {
    recText = "Duy trì quy trình chăm sóc hiện tại.";
  } else {
    recText = "Nên thực hiện kiểm tra mới.";
  }

  const now = new Date();
  const day = String(now.getDate()).padStart(2, "0");
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const year = now.getFullYear();
  const hours = String(now.getHours()).padStart(2, "0");
  const minutes = String(now.getMinutes()).padStart(2, "0");
  const formattedTimestamp = `${day}/${month}/${year} ${hours}:${minutes}`;

  return (
    <Card className="flex flex-col h-full overflow-hidden" padding={false} hover={false}>
      <div className="flex flex-col h-full p-4 justify-between">
        {/* Header */}
        <div className="flex items-center gap-2.5 mb-2">
          <div className="w-8 h-8 rounded-[10px] bg-emerald-100 flex items-center justify-center flex-shrink-0">
            <Sprout className="w-4.5 h-4.5 text-emerald-600" />
          </div>
          <div>
            <h3 className="text-[15px] font-bold text-gray-900 tracking-tight flex items-center gap-1.5">
              🌱 ĐÁNH GIÁ VƯỜN
            </h3>
            <p className="text-[11px] text-gray-500 font-medium leading-none">Phân tích từ dữ liệu giám sát hiện tại</p>
          </div>
        </div>

        {/* Content Body - 3 Sections */}
        <div className="flex-1 flex flex-col gap-2.5 justify-center min-h-0 py-1">
          {/* Section 1: 📌 TÌNH TRẠNG */}
          <div className={`p-3 rounded-r-[12px] bg-white border border-gray-100 border-l-4 ${statusBorder} shadow-sm flex items-start gap-2.5 transition-all`}>
            <StatusIcon className={`w-4 h-4 flex-shrink-0 mt-0.5 ${statusTextColor}`} />
            <div className="min-w-0 flex-1">
              <span className="text-[11px] font-bold uppercase tracking-wider block mb-1 text-gray-900">📌 TÌNH TRẠNG</span>
              <p className={`text-[12px] font-medium leading-relaxed whitespace-pre-line ${statusTextColor}`}>{statusText}</p>
            </div>
          </div>

          {/* Section 2: 💡 KHUYẾN NGHỊ */}
          <div className="p-3 rounded-r-[12px] bg-white border border-gray-100 border-l-4 border-l-blue-500 shadow-sm flex items-start gap-2.5">
            <Lightbulb className="w-4 h-4 text-blue-600 flex-shrink-0 mt-0.5" />
            <div className="min-w-0 flex-1">
              <span className="text-[11px] font-bold uppercase tracking-wider block mb-1 text-gray-900">💡 KHUYẾN NGHỊ</span>
              <p className="text-[12px] font-medium leading-relaxed text-gray-800">{recText}</p>
            </div>
          </div>
        </div>

        {/* Section 3: CẬP NHẬT */}
        <div className="pt-2 border-t border-gray-100 flex items-center justify-between text-[11px] text-gray-400 font-medium">
          <span>Dựa trên dữ liệu kiểm tra gần nhất.</span>
          <div className="flex items-center gap-1 text-gray-500 font-semibold">
            <Clock className="w-3.5 h-3.5 text-gray-400" />
            <span>Cập nhật: {formattedTimestamp}</span>
          </div>
        </div>
      </div>
    </Card>
  );
}
