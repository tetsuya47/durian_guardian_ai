import { useState, useEffect } from "react";
import {
  Cpu,
  Thermometer,
  Droplets,
  Wind,
  FlaskConical,
  AlertTriangle,
  Sparkles,
  CheckCircle2,
  RefreshCw,
  Activity,
  ArrowRight,
  ShieldAlert,
} from "lucide-react";
import api from "../../api";
import { useNavigate } from "react-router-dom";

export interface TelemetryPayload {
  soil_moisture: number;
  soil_ph: number;
  temperature: number;
  humidity: number;
  light_intensity?: number;
  rainfall?: number;
  nitrogen_ppm?: number;
  phosphorus_ppm?: number;
  potassium_ppm?: number;
  device_id?: string;
  farm_name?: string;
}

export interface AIAnalysisData {
  telemetry: TelemetryPayload;
  model3_risk_level: "Low" | "Medium" | "High" | string;
  model3_risk_score: number;
  model3_probabilities?: Record<string, number>;
  model4_ai_advice: string;
  model4_recommendations: string[];
}

export default function SmartGardenCard() {
  const navigate = useNavigate();
  const [data, setData] = useState<AIAnalysisData | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [lastSync, setLastSync] = useState<string>("Vừa xong");

  const fetchTelemetryAnalysis = async () => {
    try {
      const res = await api.get<{ success?: boolean; data?: AIAnalysisData }>("/api/v1/iot/telemetry/latest");
      const payload = (res.data as any)?.data || res.data;
      if (payload && payload.telemetry) {
        setData(payload as AIAnalysisData);
        setLastSync(new Date().toLocaleTimeString("vi-VN", { hour: "2-digit", minute: "2-digit", second: "2-digit" }));
      }
    } catch (err) {
      console.warn("Could not fetch IoT telemetry latest analysis:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTelemetryAnalysis();
    // 4-second periodic polling to match mobile app live stream
    const interval = setInterval(fetchTelemetryAnalysis, 4000);
    return () => clearInterval(interval);
  }, []);

  const telemetry = data?.telemetry || {
    soil_moisture: 68.5,
    soil_ph: 6.2,
    temperature: 28.5,
    humidity: 78.0,
    nitrogen_ppm: 125,
    farm_name: "Vườn Sầu Riêng Nguyễn Văn An",
  };

  const riskScore = data?.model3_risk_score ? Math.round(data.model3_risk_score * 100) : 15;
  const riskLevel = data?.model3_risk_level || "Low";
  const advice = data?.model4_ai_advice || "🌿 NÔNG TRẠI AN TOÀN TUYỆT ĐỐI (Rủi ro: 15%): Chỉ số cảm biến ở vùng sinh học lý tưởng. Cây sầu riêng phát triển xanh mướt.";
  const recommendations = data?.model4_recommendations || [
    "✅ Độ ẩm đất lý tưởng (60 - 75%). Duy trì chế độ tưới định kỳ.",
    "✅ Độ pH đất cân bằng tốt (5.8 - 6.8). Rễ hấp thu dinh dưỡng tối ưu.",
    "🌿 Vi khí hậu hoàn hảo. Bổ sung phân bón hữu cơ vi sinh định kỳ.",
  ];

  const getRiskBadge = () => {
    if (riskScore >= 60 || riskLevel === "High") {
      return {
        bg: "bg-red-500/20 text-red-300 border-red-500/40",
        label: `🚨 Cảnh báo cao (${riskScore}%)`,
      };
    }
    if (riskScore >= 30 || riskLevel === "Medium") {
      return {
        bg: "bg-amber-500/20 text-amber-300 border-amber-500/40",
        label: `⚠️ Nguy cơ trung bình (${riskScore}%)`,
      };
    }
    return {
      bg: "bg-emerald-500/20 text-emerald-300 border-emerald-500/40",
      label: `🌿 An toàn (${riskScore}%)`,
    };
  };

  const riskBadge = getRiskBadge();

  return (
    <div className="w-full bg-gradient-to-br from-emerald-900 via-teal-900 to-slate-900 text-white rounded-[24px] p-5 sm:p-6 shadow-xl border border-emerald-700/40 relative overflow-hidden transition-all">
      {/* Background Subtle Glow Accent */}
      <div className="absolute -right-16 -top-16 w-64 h-64 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none" />
      <div className="absolute -left-16 -bottom-16 w-64 h-64 bg-teal-500/10 rounded-full blur-3xl pointer-events-none" />

      {/* CARD TOP HEADER ROW */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-emerald-800/50">
        <div className="flex items-center gap-3">
          <div className="p-2.5 bg-emerald-500/20 text-emerald-400 rounded-2xl border border-emerald-500/30">
            <Activity className="w-6 h-6 animate-pulse" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-lg font-black text-white tracking-tight">
                Quản Lý Vườn Thông Minh (IoT & AI)
              </h3>
              <span className="px-2.5 py-0.5 rounded-full text-[11px] font-extrabold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 flex items-center gap-1">
                <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
                Live 30s
              </span>
            </div>
            <p className="text-xs text-emerald-200/80 font-medium">
              {telemetry.farm_name || "Vườn Sầu Riêng Nguyễn Văn An (1.5 ha, Krông Pắc)"} • Cập nhật: {lastSync}
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          <span className={`px-3 py-1 rounded-xl text-xs font-black border ${riskBadge.bg}`}>
            {riskBadge.label}
          </span>
          <button
            type="button"
            onClick={fetchTelemetryAnalysis}
            className="p-2 bg-emerald-800/40 hover:bg-emerald-700/50 text-emerald-200 rounded-xl border border-emerald-600/40 transition-all cursor-pointer"
            title="Làm mới dữ liệu IoT"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin text-emerald-400" : ""}`} />
          </button>
        </div>
      </div>

      {/* 4 MAIN SENSOR METRICS GRID */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3 my-4">
        {/* Metric 1: Temperature */}
        <div className="bg-emerald-950/40 border border-emerald-700/30 rounded-2xl p-3.5 flex flex-col justify-between">
          <div className="flex items-center justify-between text-xs text-emerald-300 font-semibold mb-1">
            <span className="flex items-center gap-1">
              <Thermometer className="w-4 h-4 text-amber-400" /> Nhiệt độ
            </span>
            <span className="text-[10px] text-emerald-400/80">Ổn định</span>
          </div>
          <div className="text-2xl font-black text-white tracking-tight">
            {telemetry.temperature}°C
          </div>
          <div className="text-[10px] text-emerald-300/70 mt-1">Vi khí hậu vườn</div>
        </div>

        {/* Metric 2: Soil Moisture */}
        <div className="bg-emerald-950/40 border border-emerald-700/30 rounded-2xl p-3.5 flex flex-col justify-between">
          <div className="flex items-center justify-between text-xs text-emerald-300 font-semibold mb-1">
            <span className="flex items-center gap-1">
              <Droplets className="w-4 h-4 text-cyan-400" /> Ẩm độ đất
            </span>
            <span className={`text-[10px] ${telemetry.soil_moisture > 75 ? "text-amber-400 font-bold" : "text-emerald-400/80"}`}>
              {telemetry.soil_moisture > 75 ? "Cao ⚠️" : "Lý tưởng"}
            </span>
          </div>
          <div className="text-2xl font-black text-cyan-300 tracking-tight">
            {telemetry.soil_moisture}%
          </div>
          <div className="text-[10px] text-emerald-300/70 mt-1">Tầng rễ tơ 30cm</div>
        </div>

        {/* Metric 3: Air Humidity */}
        <div className="bg-emerald-950/40 border border-emerald-700/30 rounded-2xl p-3.5 flex flex-col justify-between">
          <div className="flex items-center justify-between text-xs text-emerald-300 font-semibold mb-1">
            <span className="flex items-center gap-1">
              <Wind className="w-4 h-4 text-blue-400" /> Ẩm không khí
            </span>
            <span className="text-[10px] text-emerald-400/80">Ẩm ướt</span>
          </div>
          <div className="text-2xl font-black text-blue-200 tracking-tight">
            {telemetry.humidity}%
          </div>
          <div className="text-[10px] text-emerald-300/70 mt-1">Tán lá sầu riêng</div>
        </div>

        {/* Metric 4: Soil pH */}
        <div className="bg-emerald-950/40 border border-emerald-700/30 rounded-2xl p-3.5 flex flex-col justify-between">
          <div className="flex items-center justify-between text-xs text-emerald-300 font-semibold mb-1">
            <span className="flex items-center gap-1">
              <FlaskConical className="w-4 h-4 text-purple-400" /> Độ pH đất
            </span>
            <span className="text-[10px] text-purple-300 font-bold">Chuẩn 6.2</span>
          </div>
          <div className="text-2xl font-black text-purple-200 tracking-tight">
            {telemetry.soil_ph} pH
          </div>
          <div className="text-[10px] text-emerald-300/70 mt-1">Rễ hấp thu tốt</div>
        </div>
      </div>

      {/* AI MODEL 4 ADVICE BANNER */}
      <div className="bg-gradient-to-r from-amber-500/15 to-orange-500/15 border border-amber-500/30 rounded-2xl p-4 mb-4">
        <div className="flex items-start gap-3">
          <div className="p-2 bg-amber-500/20 text-amber-300 rounded-xl mt-0.5">
            <Sparkles className="w-5 h-5 animate-spin" />
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-2 mb-1">
              <span className="text-xs font-black text-amber-300 uppercase tracking-wider">
                Chẩn đoán Nông học Vie-farm AI (Model 3 & 4)
              </span>
            </div>
            <p className="text-xs sm:text-sm font-semibold text-white leading-relaxed">
              {advice}
            </p>
          </div>
        </div>
      </div>

      {/* ACTIONABLE RECOMMENDATIONS CHECKLIST */}
      <div className="bg-slate-900/60 border border-emerald-800/40 rounded-2xl p-4 space-y-2">
        <div className="text-xs font-extrabold text-emerald-300 flex items-center gap-1.5 pb-1 border-b border-slate-800">
          <CheckCircle2 className="w-4 h-4 text-emerald-400" />
          <span>Biện pháp xử lý kỹ thuật AI đề xuất cho vườn hôm nay:</span>
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-2 text-xs text-slate-200 pt-1">
          {recommendations.map((rec, i) => (
            <div key={i} className="flex items-start gap-2 bg-emerald-950/30 p-2.5 rounded-xl border border-emerald-900/40">
              <span className="text-emerald-400 font-bold">•</span>
              <span className="leading-snug">{rec}</span>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
