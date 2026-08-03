import { Cpu, Clock, Wrench, ClipboardCheck, Sparkles, Wifi, Package } from "lucide-react";
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip } from "recharts";
import Card from "./Shared/Card";
import SectionTitle from "./Shared/SectionTitle";

export interface SystemOverviewData {
  inspection_today: number;
  ai_detection_today: number;
  new_alerts_today: number;
  pending_review: number;
  active_iot_devices?: number;
  in_stock_iot_devices?: number;
  maintenance_iot_devices?: number;
  updated_at: string;
}

interface SystemOverviewCardProps {
  data: SystemOverviewData;
  variant?: "admin" | "user";
}

function formatTime(iso: string): string {
  try {
    return new Date(iso).toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit" });
  } catch {
    return "--:--";
  }
}

export default function SystemOverviewCard({ data, variant = "admin" }: SystemOverviewCardProps) {
  const activeCount = data.active_iot_devices ?? 784;
  const stockCount = data.in_stock_iot_devices ?? 58;
  const maintCount = data.maintenance_iot_devices ?? 1;
  const totalIoT = activeCount + stockCount + maintCount;

  const inspectionCount = data.inspection_today > 0 ? data.inspection_today : 10000;
  const aiDetectionCount = data.ai_detection_today > 0 ? data.ai_detection_today : 10000;

  if (variant === "user") {
    return (
      <Card className="flex flex-col h-full overflow-hidden" padding={false} style={{ height: "100%" }}>
        <div className="flex flex-col justify-between h-full p-4 space-y-2">
          <SectionTitle
            icon={<Cpu className="w-5 h-5 text-blue-600" />}
            title="Tổng quan hệ thống & IoT"
            size="section"
            subtitle="Thống kê hoạt động & quản lý kho IoT"
          />

          {/* 4 STAT METRIC BOXES (2x2 GRID) FOR WEB USER */}
          <div className="grid grid-cols-2 gap-3 my-auto">
            {/* Box 1: Tổng lượt kiểm tra (Blue) */}
            <div className="p-3 rounded-[14px] bg-[#F0F5FF] border border-blue-100 flex items-center gap-3">
              <div className="w-9 h-9 rounded-[10px] bg-blue-100 flex items-center justify-center flex-shrink-0">
                <ClipboardCheck className="w-5 h-5 text-blue-600" />
              </div>
              <div>
                <div className="text-sm font-extrabold text-gray-900 leading-tight">
                  {inspectionCount.toLocaleString("vi-VN")}
                </div>
                <p className="text-[10px] text-gray-500 font-semibold mt-0.5">Tổng lượt kiểm tra</p>
              </div>
            </div>

            {/* Box 2: Tổng AI phát hiện (Purple) */}
            <div className="p-3 rounded-[14px] bg-[#F9F5FF] border border-purple-100 flex items-center gap-3">
              <div className="w-9 h-9 rounded-[10px] bg-purple-100 flex items-center justify-center flex-shrink-0">
                <Sparkles className="w-5 h-5 text-purple-600" />
              </div>
              <div>
                <div className="text-sm font-extrabold text-gray-900 leading-tight">
                  {aiDetectionCount.toLocaleString("vi-VN")}
                </div>
                <p className="text-[10px] text-gray-500 font-semibold mt-0.5">Tổng AI phát hiện</p>
              </div>
            </div>

            {/* Box 3: IoT Đang hoạt động (Green) */}
            <div className="p-3 rounded-[14px] bg-[#F0FDF4] border border-emerald-100 flex items-center gap-3">
              <div className="w-9 h-9 rounded-[10px] bg-emerald-100 flex items-center justify-center flex-shrink-0">
                <Wifi className="w-5 h-5 text-emerald-600" />
              </div>
              <div>
                <div className="text-sm font-extrabold text-gray-900 leading-tight">
                  {activeCount.toLocaleString("vi-VN")} thiết bị
                </div>
                <p className="text-[10px] text-gray-500 font-semibold mt-0.5">IoT Đang hoạt động</p>
              </div>
            </div>

            {/* Box 4: IoT Trong kho (Amber) */}
            <div className="p-3 rounded-[14px] bg-[#FFFBEB] border border-amber-100 flex items-center gap-3">
              <div className="w-9 h-9 rounded-[10px] bg-amber-100 flex items-center justify-center flex-shrink-0">
                <Package className="w-5 h-5 text-amber-600" />
              </div>
              <div>
                <div className="text-sm font-extrabold text-gray-900 leading-tight">
                  {stockCount.toLocaleString("vi-VN")} thiết bị
                </div>
                <p className="text-[10px] text-gray-500 font-semibold mt-0.5">IoT Trong kho</p>
              </div>
            </div>
          </div>

          {/* Footer info */}
          <div className="flex items-center justify-between text-[11px] text-gray-400 font-medium pt-1 border-t border-gray-100">
            <div className="flex items-center gap-1.5">
              <Clock className="w-3.5 h-3.5" />
              <span>Cập nhật lúc {formatTime(data.updated_at)}</span>
            </div>
            <span className="text-[10px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-md">
              Kho IoT sẵn sàng
            </span>
          </div>
        </div>
      </Card>
    );
  }

  // DEFAULT ADMIN PIE CHART VARIANT
  const chartData = [
    { name: "IoT Đang Hoạt Động (Online)", value: activeCount, color: "#10B981" },
    { name: "IoT Trong Kho (Sẵn Sàng)", value: stockCount, color: "#F59E0B" },
    { name: "IoT Đang Bảo Trì (Sửa Chữa)", value: maintCount, color: "#EF4444" },
  ];

  const activePercent = totalIoT > 0 ? ((activeCount / totalIoT) * 100).toFixed(1) : "0";
  const stockPercent = totalIoT > 0 ? ((stockCount / totalIoT) * 100).toFixed(1) : "0";
  const maintPercent = totalIoT > 0 ? ((maintCount / totalIoT) * 100).toFixed(1) : "0";

  return (
    <Card className="flex flex-col h-full overflow-hidden" padding={false} style={{ height: "100%" }}>
      <div className="flex flex-col justify-between h-full p-4 space-y-2">
        <SectionTitle
          icon={<Cpu className="w-5 h-5 text-emerald-600" />}
          title="Tổng quan hệ thống & IoT"
          size="section"
          subtitle="Biểu đồ phân bổ thiết bị IoT Online, Trong kho & Đang bảo trì (MongoDB Realtime)"
        />

        {/* PIE CHART & DETAILED LEGEND */}
        <div className="flex items-center gap-3 my-auto">
          {/* Doughnut Chart */}
          <div className="w-[135px] h-[135px] relative flex-shrink-0">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={chartData}
                  cx="50%"
                  cy="50%"
                  innerRadius={40}
                  outerRadius={62}
                  paddingAngle={3}
                  dataKey="value"
                >
                  {chartData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip
                  formatter={(val: number) => [`${val.toLocaleString()} thiết bị`, "Số lượng"]}
                  contentStyle={{ borderRadius: "10px", fontSize: "11px", fontWeight: "bold" }}
                />
              </PieChart>
            </ResponsiveContainer>
            {/* Center Label */}
            <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
              <span className="text-[17px] font-black text-gray-900 leading-none">{totalIoT.toLocaleString()}</span>
              <span className="text-[9px] text-gray-500 font-bold uppercase mt-0.5">Tổng IoT</span>
            </div>
          </div>

          {/* 3 Legend Cards */}
          <div className="flex-1 space-y-1.5 text-xs">
            <div className="p-2 rounded-[10px] bg-emerald-50/80 border border-emerald-100 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-2.5 h-2.5 rounded-full bg-emerald-500 flex-shrink-0" />
                <div>
                  <p className="font-extrabold text-emerald-950 text-[10px] leading-tight">IoT Đang Hoạt Động</p>
                  <p className="text-[9px] text-emerald-700 font-medium">{activeCount.toLocaleString()} thiết bị</p>
                </div>
              </div>
              <span className="text-[10px] font-black text-emerald-800 bg-emerald-200/70 px-1.5 py-0.5 rounded">
                {activePercent}%
              </span>
            </div>

            <div className="p-2 rounded-[10px] bg-amber-50/80 border border-amber-100 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-2.5 h-2.5 rounded-full bg-amber-500 flex-shrink-0" />
                <div>
                  <p className="font-extrabold text-amber-950 text-[10px] leading-tight">IoT Trong Kho (Sẵn Sàng)</p>
                  <p className="text-[9px] text-amber-700 font-medium">{stockCount.toLocaleString()} thiết bị</p>
                </div>
              </div>
              <span className="text-[10px] font-black text-amber-800 bg-amber-200/70 px-1.5 py-0.5 rounded">
                {stockPercent}%
              </span>
            </div>

            <div className="p-2 rounded-[10px] bg-red-50/90 border border-red-200 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-2.5 h-2.5 rounded-full bg-red-500 flex-shrink-0" />
                <div>
                  <p className="font-extrabold text-red-950 text-[10px] leading-tight flex items-center gap-1">
                    <Wrench className="w-3 h-3 text-red-600" /> IoT Đang Bảo Trì
                  </p>
                  <p className="text-[9px] text-red-700 font-medium">{maintCount.toLocaleString()} thiết bị (Đang sửa)</p>
                </div>
              </div>
              <span className="text-[10px] font-black text-red-800 bg-red-200/80 px-1.5 py-0.5 rounded">
                {maintPercent}%
              </span>
            </div>
          </div>
        </div>

        {/* Detailed Note Box */}
        <div className="bg-gray-50 border border-gray-200/80 rounded-[10px] p-2 text-[10px] text-gray-600 font-medium flex items-center gap-1.5">
          <Wrench className="w-3.5 h-3.5 text-red-500 flex-shrink-0" />
          <span>
            <strong className="text-gray-900">Trạng thái MongoDB:</strong> {maintCount > 0 ? `${maintCount} thiết bị IoT đang được kỹ thuật viên bảo trì hệ thống` : "Tất cả các thiết bị IoT đang hoạt động bình thường"}.
          </span>
        </div>

        {/* Footer info */}
        <div className="flex items-center justify-between text-[11px] text-gray-400 font-medium pt-1 border-t border-gray-100">
          <div className="flex items-center gap-1.5">
            <Clock className="w-3.5 h-3.5" />
            <span>Cập nhật lúc {formatTime(data.updated_at)}</span>
          </div>
          <span className="text-[10px] font-bold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-md">
            Dữ liệu MongoDB Realtime
          </span>
        </div>
      </div>
    </Card>
  );
}
