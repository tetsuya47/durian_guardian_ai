import { useState, useEffect } from "react";
import { ShieldAlert, AlertTriangle, CheckCircle2, AlertCircle, RefreshCw, Sprout } from "lucide-react";
import api from "../../api";

interface AIAlert {
  id: string;
  tree_id?: string;
  tree_code?: string;
  farm_name?: string;
  zone_name?: string;
  disease_name?: string;
  severity: "high" | "medium" | "low" | string;
  title: string;
  description: string;
  recommendation: string;
  created_at: string;
}

export default function AIAlertsPage() {
  const [alerts, setAlerts] = useState<AIAlert[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterSeverity, setFilterSeverity] = useState<string>("all");

  const fetchAlerts = async () => {
    setLoading(true);
    try {
      const res = await api.get<{ data: { items?: AIAlert[] } | AIAlert[] }>("/api/v1/alerts");
      const list = Array.isArray(res.data) ? res.data : (res.data as any)?.data?.items || (res.data as any)?.data || [];
      setAlerts(list);
    } catch {
      setAlerts([]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAlerts();
  }, []);

  const filteredAlerts = alerts.filter((a) => {
    if (filterSeverity === "all") return true;
    return a.severity.toLowerCase() === filterSeverity.toLowerCase();
  });

  const highRiskCount = alerts.filter((a) => a.severity.toLowerCase() === "high").length;
  const mediumRiskCount = alerts.filter((a) => a.severity.toLowerCase() === "medium").length;

  return (
    <div className="flex flex-col gap-5 p-2 md:p-4 max-w-7xl mx-auto w-full">
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-5 rounded-[20px] border border-gray-100 shadow-sm">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-[14px] bg-red-100 flex items-center justify-center flex-shrink-0">
            <ShieldAlert className="w-6 h-6 text-red-600" />
          </div>
          <div>
            <h1 className="text-[22px] font-bold text-gray-900 leading-tight">Trung tâm Cảnh báo AI Vườn cây</h1>
            <p className="text-[13px] text-gray-500 font-medium">Phân tích rủi ro dịch bệnh & Khuyến nghị xử lý thời gian thực từ AI Engine</p>
          </div>
        </div>

        <button
          onClick={fetchAlerts}
          className="inline-flex items-center gap-2 px-4 py-2.5 bg-emerald-600 hover:bg-emerald-700 text-white font-semibold text-sm rounded-[12px] transition-all shadow-sm self-start md:self-auto"
        >
          <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
          Cập nhật Cảnh báo
        </button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-white p-4 rounded-[16px] border border-red-100 bg-red-50/30 flex items-center gap-4">
          <div className="w-11 h-11 rounded-[12px] bg-red-100 flex items-center justify-center text-red-600">
            <AlertTriangle className="w-5 h-5" />
          </div>
          <div>
            <span className="text-[12px] font-bold uppercase tracking-wider text-red-600">Nguy cơ Cao (High Risk)</span>
            <p className="text-[24px] font-black text-gray-900">{highRiskCount} Cây</p>
          </div>
        </div>

        <div className="bg-white p-4 rounded-[16px] border border-amber-100 bg-amber-50/30 flex items-center gap-4">
          <div className="w-11 h-11 rounded-[12px] bg-amber-100 flex items-center justify-center text-amber-600">
            <AlertCircle className="w-5 h-5" />
          </div>
          <div>
            <span className="text-[12px] font-bold uppercase tracking-wider text-amber-600">Nguy cơ Trung Bình</span>
            <p className="text-[24px] font-black text-gray-900">{mediumRiskCount} Cây</p>
          </div>
        </div>

        <div className="bg-white p-4 rounded-[16px] border border-emerald-100 bg-emerald-50/30 flex items-center gap-4">
          <div className="w-11 h-11 rounded-[12px] bg-emerald-100 flex items-center justify-center text-emerald-600">
            <CheckCircle2 className="w-5 h-5" />
          </div>
          <div>
            <span className="text-[12px] font-bold uppercase tracking-wider text-emerald-600">Cây Khỏe Mạnh</span>
            <p className="text-[24px] font-black text-gray-900">{alerts.length > 0 ? "Ổn định" : "0 Cây"}</p>
          </div>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-2 border-b border-gray-200 pb-2">
        <button
          onClick={() => setFilterSeverity("all")}
          className={`px-4 py-2 text-xs font-bold rounded-[10px] transition-all ${
            filterSeverity === "all" ? "bg-emerald-600 text-white" : "bg-gray-100 text-gray-600 hover:bg-gray-200"
          }`}
        >
          Tất cả cảnh báo ({alerts.length})
        </button>
        <button
          onClick={() => setFilterSeverity("high")}
          className={`px-4 py-2 text-xs font-bold rounded-[10px] transition-all ${
            filterSeverity === "high" ? "bg-red-600 text-white" : "bg-gray-100 text-gray-600 hover:bg-gray-200"
          }`}
        >
          Nguy cơ cao ({highRiskCount})
        </button>
        <button
          onClick={() => setFilterSeverity("medium")}
          className={`px-4 py-2 text-xs font-bold rounded-[10px] transition-all ${
            filterSeverity === "medium" ? "bg-amber-600 text-white" : "bg-gray-100 text-gray-600 hover:bg-gray-200"
          }`}
        >
          Nguy cơ trung bình ({mediumRiskCount})
        </button>
      </div>

      {/* Alert List */}
      <div className="space-y-4">
        {loading ? (
          <div className="p-8 text-center bg-white rounded-[16px] text-gray-400">Đang phân tích dữ liệu rủi ro AI...</div>
        ) : filteredAlerts.length === 0 ? (
          <div className="p-8 text-center bg-white rounded-[20px] border border-gray-100 shadow-sm flex flex-col items-center justify-center gap-3">
            <div className="w-12 h-12 rounded-[16px] bg-emerald-100 text-emerald-700 flex items-center justify-center">
              <Sprout className="w-6 h-6" />
            </div>
            <h3 className="text-base font-extrabold text-gray-900">Vườn Của Bạn Chưa Có Cảnh Báo AI</h3>
            <p className="text-xs text-gray-500 max-w-md text-center font-medium">
              Vui lòng đăng ký trang trại mới và hoàn tất lắp đặt thiết bị cảm biến IoT để hệ thống AI Agronomist bắt đầu thu thập dữ liệu & cảnh báo dịch bệnh tự động.
            </p>
            <div className="flex items-center gap-2 mt-1">
              <a
                href="/register-farm"
                className="px-4 py-2 bg-emerald-700 hover:bg-emerald-800 text-white font-extrabold text-xs rounded-[10px] shadow-sm transition-all"
              >
                🌱 Đăng Ký Vườn Mới
              </a>
              <a
                href="/iot-setup-guide"
                className="px-4 py-2 bg-amber-400 hover:bg-amber-300 text-gray-900 font-extrabold text-xs rounded-[10px] shadow-sm transition-all"
              >
                🚀 Hướng Dẫn Lắp Đặt IoT
              </a>
            </div>
          </div>
        ) : (
          filteredAlerts.map((alert) => {
            const isHigh = alert.severity.toLowerCase() === "high";
            return (
              <div
                key={alert.id}
                className={`bg-white rounded-[16px] p-5 border-l-4 shadow-sm border transition-all ${
                  isHigh ? "border-l-red-500 border-gray-100 hover:border-red-200" : "border-l-amber-500 border-gray-100 hover:border-amber-200"
                }`}
              >
                <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 mb-3">
                  <div className="flex items-center gap-2">
                    <span
                      className={`px-2.5 py-1 text-[11px] font-extrabold uppercase rounded-md ${
                        isHigh ? "bg-red-100 text-red-700" : "bg-amber-100 text-amber-700"
                      }`}
                    >
                      {isHigh ? "Nghiêm trọng (High)" : "Cảnh báo (Medium)"}
                    </span>
                    <span className="text-xs font-bold text-gray-700">{alert.tree_code || "Cây sầu riêng"}</span>
                    <span className="text-xs text-gray-400">• {alert.zone_name || "Khu vực A"}</span>
                  </div>
                  <span className="text-xs text-gray-400 font-medium">
                    {new Date(alert.created_at).toLocaleString("vi-VN")}
                  </span>
                </div>

                <h3 className="text-[16px] font-bold text-gray-900 mb-1">{alert.title}</h3>
                <p className="text-xs text-gray-600 leading-relaxed mb-3">{alert.description}</p>

                <div className="bg-emerald-50/60 p-3 rounded-[12px] border border-emerald-100 flex items-start gap-2.5">
                  <Sprout className="w-4 h-4 text-emerald-600 flex-shrink-0 mt-0.5" />
                  <div>
                    <span className="text-[11px] font-bold uppercase tracking-wider text-emerald-800 block mb-0.5">Khuyến nghị xử lý kỹ thuật:</span>
                    <p className="text-xs font-medium text-emerald-950 leading-normal">{alert.recommendation}</p>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
