import React, { useState, useEffect } from "react";
import {
  Activity,
  Cpu,
  Database,
  Droplets,
  Flame,
  Play,
  Pause,
  RefreshCw,
  Sun,
  ShieldAlert,
  Sparkles,
  CheckCircle,
  Zap,
  Clock,
  Layers,
} from "lucide-react";

interface TelemetryData {
  id?: string;
  soil_moisture: number;
  soil_ph: number;
  temperature: number;
  humidity: number;
  light_intensity: number;
  rainfall: number;
  nitrogen_ppm: number;
  phosphorus_ppm: number;
  potassium_ppm: number;
  device_id: string;
  timestamp?: string;
}

interface AIAnalysis {
  telemetry: TelemetryData;
  model3_risk_level: string;
  model3_risk_score: number;
  model4_ai_advice: string;
  model4_recommendations: string[];
}

export default function IoTSimulatorPage() {
  const [isRunning, setIsRunning] = useState<boolean>(true);
  const [countdown, setCountdown] = useState<number>(30);
  const [latestAnalysis, setLatestAnalysis] = useState<AIAnalysis | null>(null);
  const [history, setHistory] = useState<TelemetryData[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [stepCount, setStepCount] = useState<number>(0);

  // Realistic Simulation Engine parameters
  const [simState, setSimState] = useState({
    baseTemp: 28.5,
    baseMoisture: 72.0,
    basePh: 6.2,
    baseHumidity: 78.0,
  });

  // Generate realistic sensor data based on time and realistic biological curves
  const generateRealisticTelemetry = (): TelemetryData => {
    const now = new Date();
    const minutes = now.getMinutes() + now.getSeconds() / 60;
    const hour = now.getHours() + minutes / 60;

    // Temperature follows diurnal solar curve (peak ~14:00, lowest ~05:00)
    const tempWave = Math.sin(((hour - 8) / 24) * 2 * Math.PI) * 4.5;
    const temperature = Number((27.0 + tempWave + (Math.random() * 0.8 - 0.4)).toFixed(1));

    // Humidity inversely correlates with temperature
    const humidityWave = -Math.sin(((hour - 8) / 24) * 2 * Math.PI) * 15.0;
    const humidity = Math.min(95, Math.max(50, Number((75.0 + humidityWave + (Math.random() * 1.5 - 0.75)).toFixed(1))));

    // Soil moisture decays slowly over time (simulating transpiration & evaporation)
    const moistureStep = (stepCount % 20) * 0.4;
    let soil_moisture = Number((simState.baseMoisture - moistureStep + (Math.random() * 0.6 - 0.3)).toFixed(1));
    if (soil_moisture < 52.0) soil_moisture = 78.5; // Irrigation trigger simulation reset

    // Soil pH fluctuates smoothly around 6.2
    const soil_ph = Number((6.15 + Math.sin(stepCount * 0.2) * 0.25 + (Math.random() * 0.05 - 0.025)).toFixed(2));

    // Light intensity Lux based on day/night hours
    let light_intensity = 0;
    if (hour >= 6 && hour <= 18) {
      light_intensity = Math.round(Math.sin(((hour - 6) / 12) * Math.PI) * 65000 + Math.random() * 2000);
    }

    const rainfall = hour > 14 && hour < 16 && Math.random() > 0.6 ? Number((Math.random() * 8.5).toFixed(1)) : 0.0;

    return {
      soil_moisture,
      soil_ph,
      temperature,
      humidity,
      light_intensity,
      rainfall,
      nitrogen_ppm: Math.round(120 + Math.sin(stepCount * 0.1) * 10),
      phosphorus_ppm: Math.round(45 + Math.cos(stepCount * 0.1) * 5),
      potassium_ppm: Math.round(180 + Math.sin(stepCount * 0.15) * 15),
      device_id: "SENS-DURIAN-01",
      timestamp: now.toISOString(),
    };
  };

  const sendTelemetryToMongoDB = async (data: TelemetryData) => {
    try {
      setLoading(true);
      const res = await fetch("/api/v1/iot/telemetry", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      });

      if (res.ok) {
        fetchLatestAnalysis();
        fetchHistory();
      }
    } catch (err) {
      console.error("Failed to post IoT telemetry:", err);
    } finally {
      setLoading(false);
    }
  };

  const fetchLatestAnalysis = async () => {
    try {
      const res = await fetch("/api/v1/iot/telemetry/latest");
      if (res.ok) {
        const json = await res.json();
        if (json.data) {
          setLatestAnalysis(json.data);
        }
      }
    } catch (err) {
      console.error("Failed to fetch latest analysis:", err);
    }
  };

  const fetchHistory = async () => {
    try {
      const res = await fetch("/api/v1/iot/telemetry/history?limit=15");
      if (res.ok) {
        const json = await res.json();
        if (json.data) {
          setHistory(json.data);
        }
      }
    } catch (err) {
      console.error("Failed to fetch history:", err);
    }
  };

  // 30-Second Countdown & Telemetry Dispatch Loop
  useEffect(() => {
    fetchLatestAnalysis();
    fetchHistory();
  }, []);

  useEffect(() => {
    if (!isRunning) return;

    const timer = setInterval(() => {
      setCountdown((prev) => {
        if (prev <= 1) {
          // Trigger 30s telemetry dispatch
          const newTelemetry = generateRealisticTelemetry();
          sendTelemetryToMongoDB(newTelemetry);
          setStepCount((s) => s + 1);
          return 30;
        }
        return prev - 1;
      });
    }, 1000);

    return () => clearInterval(timer);
  }, [isRunning, stepCount]);

  const handleManualTrigger = () => {
    const newTelemetry = generateRealisticTelemetry();
    sendTelemetryToMongoDB(newTelemetry);
    setStepCount((s) => s + 1);
    setCountdown(30);
  };

  const telemetry = latestAnalysis?.telemetry;

  return (
    <div className="p-6 max-w-7xl mx-auto space-y-6">
      {/* Header Banner */}
      <div className="bg-gradient-to-r from-emerald-800 via-green-700 to-teal-800 text-white rounded-2xl p-6 shadow-xl flex flex-col md:flex-row justify-between items-start md:items-center gap-4">
        <div>
          <div className="inline-flex items-center gap-2 bg-emerald-600/40 text-emerald-200 border border-emerald-400/30 px-3 py-1 rounded-full text-xs font-semibold uppercase tracking-wider mb-2">
            <Activity className="w-3.5 h-3.5 animate-pulse text-emerald-400" />
            Giả Lập Telemetry Cảm Biến Realtime (30s / Lần)
          </div>
          <h1 className="text-2xl font-extrabold flex items-center gap-2">
            📡 Trạm Cảm Biến Đất & Khí Hậu IoT Trang Trại Sầu Riêng
          </h1>
          <p className="text-sm text-emerald-100/80 mt-1">
            Sinh dữ liệu cảm biến có quy luật thời gian thật, lưu trường tồn vào MongoDB & kích hoạt Model 3 (Risk AI) + Model 4 (AGRONOMIST RAG).
          </p>
        </div>

        {/* Controls */}
        <div className="flex items-center gap-3 bg-black/20 p-2.5 rounded-xl border border-white/10">
          <button
            onClick={() => setIsRunning(!isRunning)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg font-bold text-sm transition-all shadow-md ${
              isRunning
                ? "bg-amber-500 hover:bg-amber-600 text-black"
                : "bg-emerald-500 hover:bg-emerald-600 text-white"
            }`}
          >
            {isRunning ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
            {isRunning ? "Tạm Dừng 30s" : "Bật Tự Động 30s"}
          </button>

          <button
            onClick={handleManualTrigger}
            disabled={loading}
            className="flex items-center gap-2 bg-white/10 hover:bg-white/20 text-white px-3.5 py-2 rounded-lg font-medium text-sm transition-all border border-white/20"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
            Gửi Ngay
          </button>

          <div className="flex items-center gap-1.5 px-3 py-1.5 bg-black/30 rounded-lg text-emerald-300 font-mono text-sm font-bold border border-emerald-500/30">
            <Clock className="w-4 h-4 text-emerald-400" />
            {countdown}s
          </div>
        </div>
      </div>

      {/* Sensor Gauges Grid */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        {/* Moisture */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 p-4 rounded-xl shadow-sm">
          <div className="flex items-center justify-between text-slate-500 text-xs font-bold uppercase mb-1">
            <span>Độ Ẩm Đất</span>
            <Droplets className="w-4 h-4 text-blue-500" />
          </div>
          <div className="text-2xl font-black text-slate-900 dark:text-white">
            {telemetry?.soil_moisture ?? 68.5}%
          </div>
          <span className="text-xs text-blue-600 font-medium mt-1 inline-block">
            {telemetry && telemetry.soil_moisture < 60 ? "⚠️ Cần tưới gốc" : "✅ Ẩm tối ưu"}
          </span>
        </div>

        {/* Soil pH */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 p-4 rounded-xl shadow-sm">
          <div className="flex items-center justify-between text-slate-500 text-xs font-bold uppercase mb-1">
            <span>Độ pH Đất</span>
            <Cpu className="w-4 h-4 text-emerald-500" />
          </div>
          <div className="text-2xl font-black text-slate-900 dark:text-white">
            pH {telemetry?.soil_ph ?? 6.2}
          </div>
          <span className="text-xs text-emerald-600 font-medium mt-1 inline-block">
            {telemetry && telemetry.soil_ph < 5.8 ? "🧪 Đất chua (Bón vôi)" : "✅ Cân bằng pH"}
          </span>
        </div>

        {/* Temperature */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 p-4 rounded-xl shadow-sm">
          <div className="flex items-center justify-between text-slate-500 text-xs font-bold uppercase mb-1">
            <span>Nhiệt Độ</span>
            <Flame className="w-4 h-4 text-orange-500" />
          </div>
          <div className="text-2xl font-black text-slate-900 dark:text-white">
            {telemetry?.temperature ?? 28.5}°C
          </div>
          <span className="text-xs text-orange-600 font-medium mt-1 inline-block">
            Khí hậu tự nhiên
          </span>
        </div>

        {/* Humidity */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 p-4 rounded-xl shadow-sm">
          <div className="flex items-center justify-between text-slate-500 text-xs font-bold uppercase mb-1">
            <span>Độ Ẩm Khí</span>
            <Activity className="w-4 h-4 text-teal-500" />
          </div>
          <div className="text-2xl font-black text-slate-900 dark:text-white">
            {telemetry?.humidity ?? 78.0}%
          </div>
          <span className="text-xs text-teal-600 font-medium mt-1 inline-block">
            {telemetry && telemetry.humidity > 82 ? "⚠️ Nguy cơ nấm" : "✅ Thoáng mát"}
          </span>
        </div>

        {/* Light */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 p-4 rounded-xl shadow-sm">
          <div className="flex items-center justify-between text-slate-500 text-xs font-bold uppercase mb-1">
            <span>Bức Xạ Nắng</span>
            <Sun className="w-4 h-4 text-amber-500" />
          </div>
          <div className="text-2xl font-black text-slate-900 dark:text-white">
            {((telemetry?.light_intensity ?? 42000) / 1000).toFixed(1)}k Lux
          </div>
          <span className="text-xs text-amber-600 font-medium mt-1 inline-block">
            Quang hợp tự nhiên
          </span>
        </div>

        {/* NPK */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 p-4 rounded-xl shadow-sm">
          <div className="flex items-center justify-between text-slate-500 text-xs font-bold uppercase mb-1">
            <span>Đạm NPK (PPM)</span>
            <Zap className="w-4 h-4 text-purple-500" />
          </div>
          <div className="text-2xl font-black text-purple-600 dark:text-purple-400">
            N:{telemetry?.nitrogen_ppm ?? 120}
          </div>
          <span className="text-xs text-slate-500 font-medium mt-1 inline-block">
            P:{telemetry?.phosphorus_ppm ?? 45} | K:{telemetry?.potassium_ppm ?? 180}
          </span>
        </div>
      </div>

      {/* Model 3 & Model 4 AI Feedback Section */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Model 3 Risk Prediction */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-6 shadow-sm flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <ShieldAlert className="w-5 h-5 text-emerald-600" />
                <h2 className="text-lg font-bold text-slate-900 dark:text-white">
                  Model 3 — Dự Báo Nguy Cơ Bệnh Nông Trại (Random Forest)
                </h2>
              </div>
              <span
                className={`px-3 py-1 rounded-full text-xs font-bold ${
                  latestAnalysis?.model3_risk_level === "High" || latestAnalysis?.model3_risk_level === "Bệnh nặng"
                    ? "bg-red-100 text-red-700 border border-red-200"
                    : "bg-emerald-100 text-emerald-800 border border-emerald-200"
                }`}
              >
                MỨC ĐỘ: {latestAnalysis?.model3_risk_level ?? "Low"}
              </span>
            </div>

            <p className="text-sm text-slate-600 dark:text-slate-400 mb-4">
              Model 3 phân tích đồng thời 14 chỉ số vi khí hậu IoT, lịch sử bệnh hại & đặc trưng thổ nhưỡng để dự báo chỉ số rủi ro dịch bệnh:
            </p>

            <div className="space-y-3">
              <div>
                <div className="flex justify-between text-sm font-semibold mb-1">
                  <span>Chỉ số Nguy Cơ Nấm Bệnh (Risk Score):</span>
                  <span className="text-emerald-700 font-mono">
                    {((latestAnalysis?.model3_risk_score ?? 0.15) * 100).toFixed(1)}%
                  </span>
                </div>
                <div className="w-full bg-slate-100 dark:bg-slate-800 h-3 rounded-full overflow-hidden">
                  <div
                    className="bg-gradient-to-r from-emerald-500 via-amber-500 to-red-500 h-full transition-all duration-500"
                    style={{ width: `${(latestAnalysis?.model3_risk_score ?? 0.15) * 100}%` }}
                  />
                </div>
              </div>
            </div>
          </div>

          <div className="mt-4 pt-4 border-t border-slate-100 dark:border-slate-800 flex items-center gap-2 text-xs text-slate-500">
            <Database className="w-4 h-4 text-emerald-600" />
            Lưu trường tồn MongoDB Collection: <code className="bg-slate-100 dark:bg-slate-800 px-2 py-0.5 rounded text-emerald-600 font-bold">iot_telemetry</code>
          </div>
        </div>

        {/* Model 4 AI Agronomist Recommendations */}
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-6 shadow-sm flex flex-col justify-between">
          <div>
            <div className="flex items-center gap-2 mb-4">
              <Sparkles className="w-5 h-5 text-amber-500" />
              <h2 className="text-lg font-bold text-slate-900 dark:text-white">
                Model 4 — Đề Xuất Kỹ Thuật AI Agronomist (RAG Pipeline)
              </h2>
            </div>

            <div className="bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-900 p-4 rounded-xl mb-4">
              <p className="text-sm font-bold text-emerald-900 dark:text-emerald-200">
                {latestAnalysis?.model4_ai_advice ?? "Hệ thống IoT ghi nhận chỉ số nông trại hoạt động ổn định."}
              </p>
            </div>

            <div className="space-y-2">
              <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400">
                Hành động khuyến nghị từ AI:
              </h3>
              {(latestAnalysis?.model4_recommendations ?? [
                "Duy trì độ ẩm đất 60-75%",
                "Bón 500g Vôi bột nâng pH nếu ẩm kéo dài",
              ]).map((rec, idx) => (
                <div key={idx} className="flex items-start gap-2 text-sm text-slate-700 dark:text-slate-300">
                  <CheckCircle className="w-4 h-4 text-emerald-600 mt-0.5 shrink-0" />
                  <span>{rec}</span>
                </div>
              ))}
            </div>
          </div>

          <div className="mt-4 pt-4 border-t border-slate-100 dark:border-slate-800 text-xs text-slate-500">
            Tự động cập nhật đồng bộ lên ứng dụng di động Vie-farm Mobile.
          </div>
        </div>
      </div>

      {/* Persistent MongoDB History Table */}
      <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-6 shadow-sm">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Layers className="w-5 h-5 text-emerald-600" />
            <h2 className="text-lg font-bold text-slate-900 dark:text-white">
              Lịch Sử Cảm Biến Lưu Trong MongoDB (`iot_telemetry`)
            </h2>
          </div>
          <span className="text-xs text-slate-500">
            Tổng ghi nhận: <strong>{history.length}</strong> bản ghi (Cập nhật 30s/lần)
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-sm">
            <thead>
              <tr className="border-b border-slate-200 dark:border-slate-800 text-slate-400 text-xs uppercase">
                <th className="py-2.5 px-3">Thời gian</th>
                <th className="py-2.5 px-3">Mã trạm</th>
                <th className="py-2.5 px-3">Độ ẩm đất</th>
                <th className="py-2.5 px-3">pH đất</th>
                <th className="py-2.5 px-3">Nhiệt độ</th>
                <th className="py-2.5 px-3">Độ ẩm khí</th>
                <th className="py-2.5 px-3">Bức xạ Lux</th>
                <th className="py-2.5 px-3">Đạm (N)</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 dark:divide-slate-800">
              {history.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-6 text-center text-slate-400">
                    Chưa có bản ghi cảm biến. Nhấn "Gửi Ngay" hoặc bật "Tự Động 30s".
                  </td>
                </tr>
              ) : (
                history.map((row, idx) => (
                  <tr key={row.id || idx} className="hover:bg-slate-50 dark:hover:bg-slate-800/50">
                    <td className="py-2.5 px-3 text-slate-500 font-mono text-xs">
                      {row.timestamp ? new Date(row.timestamp).toLocaleTimeString() : "--:--"}
                    </td>
                    <td className="py-2.5 px-3 font-semibold text-emerald-600">{row.device_id}</td>
                    <td className="py-2.5 px-3 font-bold">{row.soil_moisture}%</td>
                    <td className="py-2.5 px-3">pH {row.soil_ph}</td>
                    <td className="py-2.5 px-3">{row.temperature}°C</td>
                    <td className="py-2.5 px-3">{row.humidity}%</td>
                    <td className="py-2.5 px-3">{row.light_intensity} Lux</td>
                    <td className="py-2.5 px-3 text-purple-600 font-semibold">{row.nitrogen_ppm} ppm</td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
