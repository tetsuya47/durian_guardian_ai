import { useState } from "react";
import { FileText, Download, BarChart3, TrendingUp, Calendar, CheckCircle2, DollarSign } from "lucide-react";
import Card from "@/components/dashboard/Shared/Card";
import SectionTitle from "@/components/dashboard/Shared/SectionTitle";

interface ReportSummary {
  seasonName: string;
  totalYieldTon: number;
  healthyPercent: number;
  totalCostVnd: string;
  revenueVnd: string;
  completedTasks: number;
}

const REPORT_DATA: ReportSummary = {
  seasonName: "Vụ Thu Hoạch Sầu Riêng Thái 2026 - Ea Yông Krông Pắc",
  totalYieldTon: 28.5,
  healthyPercent: 86.0,
  totalCostVnd: "145.000.000 đ",
  revenueVnd: "2.280.000.000 đ",
  completedTasks: 35,
};

export default function FarmReportsPage() {
  const [downloading, setDownloading] = useState(false);

  const handleDownloadReport = () => {
    setDownloading(true);
    setTimeout(() => {
      setDownloading(false);
      alert("Đã tải xuống Báo cáo tổng hợp trang trại sầu riêng (PDF/Excel) thành công!");
    }, 1200);
  };

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto">
      {/* HEADER BAR */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-[20px] border border-gray-200/90 shadow-xs">
        <div>
          <h1 className="text-xl font-black text-gray-900 flex items-center gap-2">
            <FileText className="w-6 h-6 text-emerald-600" />
            <span>Báo Cáo Tổng Hợp Trang Trại Sầu Riêng</span>
          </h1>
          <p className="text-xs text-gray-500 font-medium mt-1">
            Báo cáo nông vụ, tổng kết chi phí phân bón, nhật ký công việc & doanh thu sản lượng theo mùa vụ
          </p>
        </div>

        <button
          type="button"
          onClick={handleDownloadReport}
          disabled={downloading}
          className="px-4 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold text-xs shadow-md flex items-center gap-2 transition-all cursor-pointer hover:scale-105 active:scale-95 disabled:opacity-50"
        >
          <Download className={`w-4 h-4 ${downloading ? "animate-bounce" : ""}`} />
          <span>{downloading ? "Đang xuất báo cáo..." : "Tải Báo Cáo (PDF/Excel)"}</span>
        </button>
      </div>

      {/* SEASON HIGHLIGHT CARD */}
      <div className="bg-gradient-to-r from-emerald-900 via-teal-900 to-emerald-950 text-white p-6 rounded-[24px] shadow-xl border border-emerald-700/50 space-y-4">
        <div className="flex items-center justify-between border-b border-emerald-700/60 pb-3">
          <span className="text-xs font-black uppercase tracking-wider text-emerald-300">
            📊 Báo Báo Thu Hoạch & Nông Vụ Mới Nhất
          </span>
          <span className="text-xs bg-emerald-800 text-emerald-100 font-mono px-3 py-1 rounded-full font-bold">
            Vụ Mùa 2026
          </span>
        </div>

        <h2 className="text-lg font-black">{REPORT_DATA.seasonName}</h2>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-xs font-bold pt-2">
          <div className="bg-emerald-800/50 p-3.5 rounded-2xl border border-emerald-700/60 space-y-1">
            <span className="text-emerald-300 text-[11px] block">Sản lượng thu hoạch</span>
            <span className="text-xl font-black text-white">{REPORT_DATA.totalYieldTon} Tấn</span>
          </div>

          <div className="bg-emerald-800/50 p-3.5 rounded-2xl border border-emerald-700/60 space-y-1">
            <span className="text-emerald-300 text-[11px] block">Tỷ lệ cây khỏe</span>
            <span className="text-xl font-black text-emerald-200">{REPORT_DATA.healthyPercent}%</span>
          </div>

          <div className="bg-emerald-800/50 p-3.5 rounded-2xl border border-emerald-700/60 space-y-1">
            <span className="text-emerald-300 text-[11px] block">Doanh thu ước tính</span>
            <span className="text-xl font-black text-amber-300">{REPORT_DATA.revenueVnd}</span>
          </div>

          <div className="bg-emerald-800/50 p-3.5 rounded-2xl border border-emerald-700/60 space-y-1">
            <span className="text-emerald-300 text-[11px] block">Nhật ký đã làm</span>
            <span className="text-xl font-black text-cyan-200">{REPORT_DATA.completedTasks} lượt</span>
          </div>
        </div>
      </div>

      {/* DETAILED SECTIONS */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card className="p-5 border border-gray-200/90 shadow-md rounded-[20px] bg-white space-y-3">
          <SectionTitle
            icon={<BarChart3 className="w-5 h-5 text-emerald-600" />}
            title="Thống Kê Chi Phí Vật Tư & Nông Dược"
            size="section"
            subtitle="Tổng hợp ngân sách phân bón & thuốc bảo vệ thực vật (Tổng: 145 triệu đ)"
          />
          <div className="space-y-2 text-xs font-semibold">
            <div className="flex justify-between p-3 rounded-xl bg-gray-50 border border-gray-200">
              <span className="text-gray-700">Phân bón hữu cơ nở & NPK vi lượng:</span>
              <span className="font-extrabold text-gray-900">75.000.000 đ</span>
            </div>
            <div className="flex justify-between p-3 rounded-xl bg-gray-50 border border-gray-200">
              <span className="text-gray-700">Thuốc sinh học phòng nấm & rệp sáp:</span>
              <span className="font-extrabold text-gray-900">42.000.000 đ</span>
            </div>
            <div className="flex justify-between p-3 rounded-xl bg-gray-50 border border-gray-200">
              <span className="text-gray-700">Chi phí nhân công & điện tưới tự động:</span>
              <span className="font-extrabold text-gray-900">28.000.000 đ</span>
            </div>
          </div>
        </Card>

        <Card className="p-5 border border-gray-200/90 shadow-md rounded-[20px] bg-white space-y-3">
          <SectionTitle
            icon={<TrendingUp className="w-5 h-5 text-emerald-600" />}
            title="Hiệu Suất Canh Tác Theo 4 Khu Vực (350 Gốc)"
            size="section"
            subtitle="Tỷ lệ đạt chuẩn sầu riêng xuất khẩu"
          />
          <div className="space-y-2 text-xs font-semibold">
            <div className="flex justify-between p-3 rounded-xl bg-emerald-50 border border-emerald-200">
              <span className="text-emerald-900 font-bold">Khu A - Sầu Riêng Thái (120 cây):</span>
              <span className="font-black text-emerald-700">92% Loại 1</span>
            </div>
            <div className="flex justify-between p-3 rounded-xl bg-emerald-50 border border-emerald-200">
              <span className="text-emerald-900 font-bold">Khu B - Sầu Riêng Ri6 (90 cây):</span>
              <span className="font-black text-emerald-700">88% Loại 1</span>
            </div>
            <div className="flex justify-between p-3 rounded-xl bg-emerald-50 border border-emerald-200">
              <span className="text-emerald-900 font-bold">Khu C - Musang King (80 cây):</span>
              <span className="font-black text-emerald-700">95% Loại 1</span>
            </div>
            <div className="flex justify-between p-3 rounded-xl bg-emerald-50 border border-emerald-200">
              <span className="text-emerald-900 font-bold">Khu D - Sầu Riêng Thái (60 cây):</span>
              <span className="font-black text-emerald-700">90% Loại 1</span>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}
