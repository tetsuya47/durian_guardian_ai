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
  Sliders,
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

export default function App() {
  const [isRunning, setIsRunning] = useState<boolean>(true);
  const [countdown, setCountdown] = useState<number>(30);
  const [latestAnalysis, setLatestAnalysis] = useState<AIAnalysis | null>(null);
  const [history, setHistory] = useState<TelemetryData[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [stepCount, setStepCount] = useState<number>(0);
  const [isConnected, setIsConnected] = useState<boolean>(true);

  // Digital Twin Sliders State
  const [sliderTemp, setSliderTemp] = useState<number>(28.5);
  const [sliderHum, setSliderHum] = useState<number>(78.0);
  const [sliderRain, setSliderRain] = useState<number>(0.0);
  const [sliderMoisture, setSliderMoisture] = useState<number>(68.5);
  const [sliderPh, setSliderPh] = useState<number>(6.2);
  const [sliderN, setSliderN] = useState<number>(120);

  // Sync sliders when telemetry arrives
  useEffect(() => {
    if (latestAnalysis?.telemetry) {
      const t = latestAnalysis.telemetry;
      if (t.temperature != null) setSliderTemp(t.temperature);
      if (t.humidity != null) setSliderHum(t.humidity);
      if (t.rainfall != null) setSliderRain(t.rainfall);
      if (t.soil_moisture != null) setSliderMoisture(t.soil_moisture);
      if (t.soil_ph != null) setSliderPh(t.soil_ph);
      if (t.nitrogen_ppm != null) setSliderN(t.nitrogen_ppm);
    }
  }, [latestAnalysis]);

  const handleSliderChange = (field: keyof TelemetryData, val: number) => {
    switch (field) {
      case 'temperature': setSliderTemp(val); break;
      case 'humidity': setSliderHum(val); break;
      case 'rainfall': setSliderRain(val); break;
      case 'soil_moisture': setSliderMoisture(val); break;
      case 'soil_ph': setSliderPh(val); break;
      case 'nitrogen_ppm': setSliderN(val); break;
    }

    const updated: TelemetryData = {
      soil_moisture: field === 'soil_moisture' ? val : sliderMoisture,
      soil_ph: field === 'soil_ph' ? val : sliderPh,
      temperature: field === 'temperature' ? val : sliderTemp,
      humidity: field === 'humidity' ? val : sliderHum,
      light_intensity: field === 'temperature' ? Math.round(val * 1500) : 42000,
      rainfall: field === 'rainfall' ? val : sliderRain,
      nitrogen_ppm: field === 'nitrogen_ppm' ? val : sliderN,
      phosphorus_ppm: 45,
      potassium_ppm: 180,
      device_id: "SENS-DURIAN-01",
      timestamp: new Date().toISOString(),
    };

    sendTelemetryToMongoDB(updated);
  };

  // Generate realistic sensor data based on biological diurnal curves
  const generateRealisticTelemetry = (): TelemetryData => {
    const now = new Date();
    const minutes = now.getMinutes() + now.getSeconds() / 60;
    const hour = now.getHours() + minutes / 60;

    // Diurnal solar wave
    const tempWave = Math.sin(((hour - 8) / 24) * 2 * Math.PI) * 4.5;
    const temperature = Number((27.0 + tempWave + (Math.random() * 0.8 - 0.4)).toFixed(1));

    const humidityWave = -Math.sin(((hour - 8) / 24) * 2 * Math.PI) * 15.0;
    const humidity = Math.min(95, Math.max(50, Number((75.0 + humidityWave + (Math.random() * 1.5 - 0.75)).toFixed(1))));

    // Soil moisture decay & transpiration
    const moistureStep = (stepCount % 20) * 0.4;
    let soil_moisture = Number((74.0 - moistureStep + (Math.random() * 0.6 - 0.3)).toFixed(1));
    if (soil_moisture < 52.0) soil_moisture = 78.5;

    const soil_ph = Number((6.15 + Math.sin(stepCount * 0.2) * 0.25 + (Math.random() * 0.05 - 0.025)).toFixed(2));

    let light_intensity = 0;
    if (hour >= 6 && hour <= 18) {
      light_intensity = Math.round(Math.sin(((hour - 6) / 12) * Math.PI) * 65000 + Math.random() * 2000);
    }

    return {
      soil_moisture,
      soil_ph,
      temperature,
      humidity,
      light_intensity,
      rainfall: hour > 14 && hour < 16 && Math.random() > 0.6 ? Number((Math.random() * 8.5).toFixed(1)) : 0.0,
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
        setIsConnected(true);
        fetchLatestAnalysis();
        fetchHistory();
      } else {
        setIsConnected(false);
      }
    } catch (err) {
      console.error("Backend connection error:", err);
      setIsConnected(false);
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
          setIsConnected(true);
        }
      }
    } catch (err) {
      setIsConnected(false);
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

  useEffect(() => {
    fetchLatestAnalysis();
    fetchHistory();
  }, []);

  useEffect(() => {
    if (!isRunning) return;

    const timer = setInterval(() => {
      setCountdown((prev) => {
        if (prev <= 1) {
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

  const scenariosList = [
    { id: 's01', name: '01. An Toàn Tuyệt Đối (~5%)', icon: '🌿', color: 'emerald', data: { soil_moisture: 72.0, soil_ph: 6.5, temperature: 26.5, humidity: 70.0, light_intensity: 45000, rainfall: 0.0, nitrogen_ppm: 120, phosphorus_ppm: 45, potassium_ppm: 180 } },
    { id: 's02', name: '02. Khởi Đầu Mùa Khô (~15%)', icon: '☀️', color: 'emerald', data: { soil_moisture: 65.0, soil_ph: 6.3, temperature: 29.0, humidity: 65.0, light_intensity: 52000, rainfall: 0.0, nitrogen_ppm: 115, phosphorus_ppm: 40, potassium_ppm: 175 } },
    { id: 's03', name: '03. Sương Mù Ẩm Ướt (~25%)', icon: '☁️', color: 'teal', data: { soil_moisture: 76.0, soil_ph: 6.1, temperature: 24.5, humidity: 82.0, light_intensity: 22000, rainfall: 0.5, nitrogen_ppm: 125, phosphorus_ppm: 45, potassium_ppm: 180 } },
    { id: 's04', name: '04. Thiếu Nước Nhẹ (~30%)', icon: '💧', color: 'cyan', data: { soil_moisture: 56.0, soil_ph: 6.2, temperature: 31.0, humidity: 58.0, light_intensity: 58000, rainfall: 0.0, nitrogen_ppm: 110, phosphorus_ppm: 42, potassium_ppm: 170 } },
    { id: 's05', name: '05. Đất Chua Cần Vôi (~35%)', icon: '🧪', color: 'yellow', data: { soil_moisture: 68.0, soil_ph: 5.2, temperature: 28.5, humidity: 75.0, light_intensity: 42000, rainfall: 0.0, nitrogen_ppm: 120, phosphorus_ppm: 35, potassium_ppm: 160 } },
    { id: 's06', name: '06. Bọ Trĩ & Rầy Nhảy (~40%)', icon: '🦗', color: 'amber', data: { soil_moisture: 60.0, soil_ph: 6.0, temperature: 32.5, humidity: 60.0, light_intensity: 62000, rainfall: 0.0, nitrogen_ppm: 130, phosphorus_ppm: 45, potassium_ppm: 185 } },
    { id: 's07', name: '07. Mưa Rào Ẩm Cao (~45%)', icon: '🌧️', color: 'amber', data: { soil_moisture: 80.0, soil_ph: 5.8, temperature: 29.5, humidity: 86.0, light_intensity: 18000, rainfall: 8.5, nitrogen_ppm: 115, phosphorus_ppm: 40, potassium_ppm: 165 } },
    { id: 's08', name: '08. Mầm Nấm Thán Thư (~50%)', icon: '🦠', color: 'orange', data: { soil_moisture: 78.0, soil_ph: 5.7, temperature: 31.5, humidity: 84.0, light_intensity: 35000, rainfall: 2.0, nitrogen_ppm: 140, phosphorus_ppm: 38, potassium_ppm: 170 } },
    { id: 's09', name: '09. Đất Ngập Ứng Thối Rễ (~55%)', icon: '⚠️', color: 'orange', data: { soil_moisture: 92.0, soil_ph: 5.3, temperature: 28.0, humidity: 90.0, light_intensity: 15000, rainfall: 25.0, nitrogen_ppm: 105, phosphorus_ppm: 30, potassium_ppm: 150 } },
    { id: 's10', name: '10. Nắng Nóng Hạn Hán (~60%)', icon: '🔥', color: 'rose', data: { soil_moisture: 44.0, soil_ph: 5.5, temperature: 37.0, humidity: 42.0, light_intensity: 75000, rainfall: 0.0, nitrogen_ppm: 85, phosphorus_ppm: 55, potassium_ppm: 210 } },
    { id: 's11', name: '11. Dư Thừa Đạm NPK (~65%)', icon: '💥', color: 'rose', data: { soil_moisture: 75.0, soil_ph: 5.4, temperature: 32.0, humidity: 83.0, light_intensity: 40000, rainfall: 0.0, nitrogen_ppm: 210, phosphorus_ppm: 60, potassium_ppm: 190 } },
    { id: 's12', name: '12. Nấm Phytophthora Thân Gốc (~75%)', icon: '🚨', color: 'red', data: { soil_moisture: 86.0, soil_ph: 5.1, temperature: 33.5, humidity: 89.0, light_intensity: 12000, rainfall: 14.5, nitrogen_ppm: 175, phosphorus_ppm: 30, potassium_ppm: 140 } },
    { id: 's13', name: '13. Dịch Bệnh Bùng Phát (~85%)', icon: '💀', color: 'purple', data: { soil_moisture: 90.0, soil_ph: 4.9, temperature: 34.2, humidity: 93.0, light_intensity: 10000, rainfall: 22.0, nitrogen_ppm: 185, phosphorus_ppm: 25, potassium_ppm: 130 } },
    { id: 's14', name: '14. Thảm Họa Thối Rễ Tơ (~90%)', icon: '☠️', color: 'purple', data: { soil_moisture: 95.0, soil_ph: 4.6, temperature: 35.0, humidity: 95.0, light_intensity: 8000, rainfall: 45.0, nitrogen_ppm: 195, phosphorus_ppm: 20, potassium_ppm: 120 } },
    { id: 's15', name: '15. Can Thiệp Khẩn Cấp Cấp 4 (~95%)', icon: '🆘', color: 'fuchsia', data: { soil_moisture: 96.0, soil_ph: 4.4, temperature: 35.5, humidity: 96.0, light_intensity: 5000, rainfall: 60.0, nitrogen_ppm: 200, phosphorus_ppm: 15, potassium_ppm: 110 } },
  ];

  const sendPresetScenarioById = (scenarioId: string) => {
    const sc = scenariosList.find((s) => s.id === scenarioId);
    const now = new Date().toISOString();
    const presetData: TelemetryData = sc
      ? { ...sc.data, device_id: "SENS-DURIAN-01", timestamp: now }
      : generateRealisticTelemetry();

    sendTelemetryToMongoDB(presetData);
    setStepCount((s) => s + 1);
    setCountdown(30);
  };

  const handleManualTrigger = () => {
    sendPresetScenarioById('s01');
  };

  const telemetry = latestAnalysis?.telemetry;

  return (
    <div className="p-4 md:p-8 max-w-7xl mx-auto space-y-6">
      {/* Header Banner */}
      <header className="glass-card rounded-3xl p-6 md:p-8 flex flex-col md:flex-row justify-between items-start md:items-center gap-6 shadow-2xl relative overflow-hidden">
        <div className="absolute -right-16 -top-16 w-64 h-64 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none" />

        <div className="space-y-2 z-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs font-bold uppercase tracking-wider">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping" />
            Project Độc Lập `iot_simulator_project`
          </div>
          <h1 className="text-2xl md:text-3xl font-extrabold text-white tracking-tight flex items-center gap-3">
            📡 Trạm Cảm Biến Giả Lập IoT Realtime 30s
          </h1>
          <p className="text-sm text-slate-400 max-w-2xl">
            Sinh dữ liệu cảm biến nông nghiệp có quy luật thời gian thật, tự động lưu trường tồn vào MongoDB (<code class="text-emerald-400 font-mono">iot_telemetry</code>) & kích hoạt <b>Model 3 (Risk AI)</b> + <b>Model 4 (AGRONOMIST RAG)</b>.
          </p>

          {/* 15 Scenario Presets Panel */}
          <div className="space-y-2 pt-3">
            <div className="flex items-center justify-between">
              <span className="text-xs font-extrabold text-emerald-400 uppercase tracking-wider flex items-center gap-1.5">
                🎯 15 Kịch Bản Thử Nghiệm Mô Hình AI (Model 3 Risk & Model 4 Agronomist)
              </span>
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-5 gap-2 max-h-48 overflow-y-auto pr-1">
              {scenariosList.map((sc) => (
                <button
                  key={sc.id}
                  onClick={() => sendPresetScenarioById(sc.id)}
                  className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-xl text-xs font-bold bg-slate-900/90 text-slate-200 border border-slate-700/60 hover:border-emerald-400 hover:text-white transition-all shadow-sm active:scale-95 text-left truncate"
                  title={sc.name}
                >
                  <span>{sc.icon}</span>
                  <span className="truncate">{sc.name}</span>
                </button>
              ))}
            </div>
          </div>
        </div>

        {/* Controls Panel */}
        <div className="flex items-center gap-3 z-10 bg-slate-900/80 p-3 rounded-2xl border border-slate-800 shadow-inner">
          <button
            onClick={() => setIsRunning(!isRunning)}
            className={`flex items-center gap-2 px-5 py-2.5 rounded-xl font-bold text-sm transition-all duration-200 ${
              isRunning
                ? "bg-amber-500 hover:bg-amber-400 text-slate-950 shadow-lg shadow-amber-500/20"
                : "bg-emerald-500 hover:bg-emerald-400 text-slate-950 shadow-lg shadow-emerald-500/20"
            }`}
          >
            {isRunning ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4" />}
            {isRunning ? "Tạm Dừng 30s" : "Bật Tự Động 30s"}
          </button>

          <button
            onClick={handleManualTrigger}
            disabled={loading}
            className="flex items-center gap-2 px-4 py-2.5 rounded-xl font-bold text-sm bg-emerald-600/30 hover:bg-emerald-600/50 text-emerald-300 border border-emerald-500/30 transition-all active:scale-95"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin" : ""}`} />
            Gửi Ngay
          </button>

          <div className="flex items-center gap-2 px-4 py-2 bg-slate-950 rounded-xl border border-slate-800 text-emerald-400 font-mono font-bold text-sm">
            <Clock className="w-4 h-4 text-emerald-400" />
            <span>{countdown}s</span>
          </div>
        </div>
      </header>

      {/* 6 Gauge Cards Grid */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
        {/* Moisture */}
        <div className="glass-card glass-card-hover p-4 rounded-2xl transition-all">
          <div className="flex justify-between items-center text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
            <span>Độ Ẩm Đất</span>
            <Droplets className="w-4 h-4 text-blue-400" />
          </div>
          <div className="text-2xl font-extrabold text-white">
            {telemetry?.soil_moisture ?? 68.5}%
          </div>
          <div className="text-xs font-semibold text-blue-400 mt-1">
            {telemetry && telemetry.soil_moisture < 60 ? "⚠️ Cần tưới gốc" : "✅ Đất ẩm tốt"}
          </div>
        </div>

        {/* Soil pH */}
        <div className="glass-card glass-card-hover p-4 rounded-2xl transition-all">
          <div className="flex justify-between items-center text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
            <span>Độ pH Đất</span>
            <Cpu className="w-4 h-4 text-emerald-400" />
          </div>
          <div className="text-2xl font-extrabold text-white">
            pH {telemetry?.soil_ph ?? 6.2}
          </div>
          <div className="text-xs font-semibold text-emerald-400 mt-1">
            {telemetry && telemetry.soil_ph < 5.8 ? "🧪 Bón vôi nâng pH" : "✅ Cân bằng pH"}
          </div>
        </div>

        {/* Temperature */}
        <div className="glass-card glass-card-hover p-4 rounded-2xl transition-all">
          <div className="flex justify-between items-center text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
            <span>Nhiệt Độ Khí</span>
            <Flame className="w-4 h-4 text-orange-400" />
          </div>
          <div className="text-2xl font-extrabold text-white">
            {telemetry?.temperature ?? 28.5}°C
          </div>
          <div className="text-xs font-semibold text-orange-400 mt-1">Khí hậu tự nhiên</div>
        </div>

        {/* Humidity */}
        <div className="glass-card glass-card-hover p-4 rounded-2xl transition-all">
          <div className="flex justify-between items-center text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
            <span>Độ Ẩm Khí</span>
            <Activity className="w-4 h-4 text-teal-400" />
          </div>
          <div className="text-2xl font-extrabold text-white">
            {telemetry?.humidity ?? 78.0}%
          </div>
          <div className="text-xs font-semibold text-teal-400 mt-1">
            {telemetry && telemetry.humidity > 82 ? "⚠️ Nguy cơ nấm" : "✅ Thoáng mát"}
          </div>
        </div>

        {/* Light Lux */}
        <div className="glass-card glass-card-hover p-4 rounded-2xl transition-all">
          <div className="flex justify-between items-center text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
            <span>Bức Xạ Lux</span>
            <Sun className="w-4 h-4 text-amber-400" />
          </div>
          <div className="text-2xl font-extrabold text-white">
            {((telemetry?.light_intensity ?? 42000) / 1000).toFixed(1)}k Lux
          </div>
          <div className="text-xs font-semibold text-amber-400 mt-1">Nắng quang hợp</div>
        </div>

        {/* NPK */}
        <div className="glass-card glass-card-hover p-4 rounded-2xl transition-all">
          <div className="flex justify-between items-center text-xs font-bold text-slate-400 uppercase tracking-wider mb-2">
            <span>Đạm NPK (PPM)</span>
            <Zap className="w-4 h-4 text-purple-400" />
          </div>
          <div className="text-2xl font-extrabold text-purple-300">
            N:{telemetry?.nitrogen_ppm ?? 120}
          </div>
          <div className="text-xs font-semibold text-purple-400 mt-1">
            P:{telemetry?.phosphorus_ppm ?? 45} | K:{telemetry?.potassium_ppm ?? 180}
          </div>
        </div>
      </div>

      {/* Digital Twin Real-Time Interactive Sliders Panel */}
      <div className="glass-card rounded-3xl p-6 border border-emerald-500/30 space-y-4 shadow-2xl">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2">
            <Sliders className="w-5 h-5 text-emerald-400" />
            <h2 className="text-lg font-bold text-white">🕹️ Digital Twin Simulator — Thanh Trượt Điều Khiển Thật</h2>
          </div>
          <span className="text-xs px-3 py-1 rounded-full bg-emerald-500/20 text-emerald-300 font-mono border border-emerald-500/30">
            Realtime AI Sync
          </span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6 pt-2">
          {/* Temperature Slider */}
          <div className="space-y-2 bg-slate-900/80 p-4 rounded-2xl border border-slate-800">
            <div className="flex justify-between text-xs font-bold">
              <span className="text-slate-300">🌡 Nhiệt Độ Khí</span>
              <span className="text-emerald-400 font-mono text-sm">{sliderTemp}°C</span>
            </div>
            <input
              type="range"
              min="10"
              max="50"
              step="0.5"
              value={sliderTemp}
              onChange={(e) => handleSliderChange('temperature', parseFloat(e.target.value))}
              className="w-full accent-emerald-400 cursor-pointer h-2 bg-slate-800 rounded-lg"
            />
            <div className="flex justify-between text-[10px] text-slate-500">
              <span>10°C</span>
              <span>50°C</span>
            </div>
          </div>

          {/* Humidity Slider */}
          <div className="space-y-2 bg-slate-900/80 p-4 rounded-2xl border border-slate-800">
            <div className="flex justify-between text-xs font-bold">
              <span className="text-slate-300">💧 Độ Ẩm Không Khí</span>
              <span className="text-teal-400 font-mono text-sm">{sliderHum}%</span>
            </div>
            <input
              type="range"
              min="0"
              max="100"
              step="1"
              value={sliderHum}
              onChange={(e) => handleSliderChange('humidity', parseFloat(e.target.value))}
              className="w-full accent-teal-400 cursor-pointer h-2 bg-slate-800 rounded-lg"
            />
            <div className="flex justify-between text-[10px] text-slate-500">
              <span>0%</span>
              <span>100%</span>
            </div>
          </div>

          {/* Rainfall Slider */}
          <div className="space-y-2 bg-slate-900/80 p-4 rounded-2xl border border-slate-800">
            <div className="flex justify-between text-xs font-bold">
              <span className="text-slate-300">☔ Lượng Mưa</span>
              <span className="text-blue-400 font-mono text-sm">{sliderRain} mm</span>
            </div>
            <input
              type="range"
              min="0"
              max="100"
              step="1"
              value={sliderRain}
              onChange={(e) => handleSliderChange('rainfall', parseFloat(e.target.value))}
              className="w-full accent-blue-400 cursor-pointer h-2 bg-slate-800 rounded-lg"
            />
            <div className="flex justify-between text-[10px] text-slate-500">
              <span>0 mm</span>
              <span>100 mm</span>
            </div>
          </div>

          {/* Soil Moisture Slider */}
          <div className="space-y-2 bg-slate-900/80 p-4 rounded-2xl border border-slate-800">
            <div className="flex justify-between text-xs font-bold">
              <span className="text-slate-300">🌱 Độ Ẩm Đất</span>
              <span className="text-cyan-400 font-mono text-sm">{sliderMoisture}%</span>
            </div>
            <input
              type="range"
              min="0"
              max="100"
              step="1"
              value={sliderMoisture}
              onChange={(e) => handleSliderChange('soil_moisture', parseFloat(e.target.value))}
              className="w-full accent-cyan-400 cursor-pointer h-2 bg-slate-800 rounded-lg"
            />
            <div className="flex justify-between text-[10px] text-slate-500">
              <span>0%</span>
              <span>100%</span>
            </div>
          </div>

          {/* Soil pH Slider */}
          <div className="space-y-2 bg-slate-900/80 p-4 rounded-2xl border border-slate-800">
            <div className="flex justify-between text-xs font-bold">
              <span className="text-slate-300">🧪 Độ pH Đất</span>
              <span className="text-amber-400 font-mono text-sm">{sliderPh} pH</span>
            </div>
            <input
              type="range"
              min="3"
              max="9"
              step="0.1"
              value={sliderPh}
              onChange={(e) => handleSliderChange('soil_ph', parseFloat(e.target.value))}
              className="w-full accent-amber-400 cursor-pointer h-2 bg-slate-800 rounded-lg"
            />
            <div className="flex justify-between text-[10px] text-slate-500">
              <span>pH 3.0</span>
              <span>pH 9.0</span>
            </div>
          </div>

          {/* Nitrogen / NPK Slider */}
          <div className="space-y-2 bg-slate-900/80 p-4 rounded-2xl border border-slate-800">
            <div className="flex justify-between text-xs font-bold">
              <span className="text-slate-300">⚡ Đạm NPK (N)</span>
              <span className="text-purple-400 font-mono text-sm">{sliderN} ppm</span>
            </div>
            <input
              type="range"
              min="0"
              max="300"
              step="5"
              value={sliderN}
              onChange={(e) => handleSliderChange('nitrogen_ppm', parseFloat(e.target.value))}
              className="w-full accent-purple-400 cursor-pointer h-2 bg-slate-800 rounded-lg"
            />
            <div className="flex justify-between text-[10px] text-slate-500">
              <span>0 ppm</span>
              <span>300 ppm</span>
            </div>
          </div>
        </div>
      </div>

      {/* AI Output Cards Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Model 3 AI Risk Prediction */}
        <div className="glass-card rounded-3xl p-6 shadow-xl flex flex-col justify-between space-y-4">
          <div>
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <ShieldAlert className="w-5 h-5 text-emerald-400" />
                <h2 className="text-lg font-bold text-white">Model 3 — Dự Báo Nguy Cơ Bệnh Nông Trại</h2>
              </div>
              <span className="px-3 py-1 rounded-full text-xs font-extrabold uppercase bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
                MỨC ĐỘ: {latestAnalysis?.model3_risk_level ?? "Low"}
              </span>
            </div>

            <p className="text-sm text-slate-400">
              Model 3 Random Forest phân tích đồng thời 14 chỉ số vi khí hậu IoT & thổ nhưỡng để dự báo tỷ lệ rủi ro bùng phát dịch bệnh:
            </p>

            <div className="mt-4 space-y-2">
              <div className="flex justify-between text-sm font-semibold">
                <span className="text-slate-300">Chỉ số Rủi Ro Dịch Bệnh (Risk Score):</span>
                <span className="text-emerald-400 font-mono font-bold">
                  {((latestAnalysis?.model3_risk_score ?? 0.15) * 100).toFixed(1)}%
                </span>
              </div>
              <div className="w-full bg-slate-900 rounded-full h-3 overflow-hidden p-0.5 border border-slate-800">
                <div
                  className="bg-gradient-to-r from-emerald-500 via-amber-500 to-red-500 h-full rounded-full transition-all duration-500"
                  style={{ width: `${(latestAnalysis?.model3_risk_score ?? 0.15) * 100}%` }}
                />
              </div>
            </div>
          </div>

          <div className="pt-4 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-400">
            <span>MongoDB Collection: <code className="text-emerald-400 font-mono font-bold">iot_telemetry</code></span>
            <span className={isConnected ? "text-emerald-400 font-bold" : "text-red-400 font-bold"}>
              {isConnected ? "● Backend Online (Port 8000)" : "❌ Disconnected from Backend"}
            </span>
          </div>
        </div>

        {/* Model 4 AI Agronomist Recommendations */}
        <div className="glass-card rounded-3xl p-6 shadow-xl flex flex-col justify-between space-y-4">
          <div>
            <div className="flex items-center gap-2 mb-4">
              <Sparkles className="w-5 h-5 text-amber-400" />
              <h2 className="text-lg font-bold text-white">Model 4 — Khuyến Nghị Kỹ Thuật AI Agronomist</h2>
            </div>

            <div className="bg-emerald-950/60 border border-emerald-500/30 p-4 rounded-2xl mb-4">
              <p className="text-sm font-bold text-emerald-200 leading-relaxed">
                {latestAnalysis?.model4_ai_advice ?? "Nông trại hoạt động ổn định. Đang tải khuyến nghị mới nhất từ AI..."}
              </p>
            </div>

            <div className="space-y-2">
              <h3 className="text-xs font-bold uppercase tracking-wider text-slate-400">Hành động được đề xuất từ AI:</h3>
              <div className="space-y-2">
                {(latestAnalysis?.model4_recommendations ?? ["Duy trì độ ẩm đất 60-75%"]).map((r, idx) => (
                  <div key={idx} className="flex items-center gap-2 text-sm text-slate-300">
                    <CheckCircle className="w-4 h-4 text-emerald-400 shrink-0" />
                    <span>{r}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          <div className="pt-4 border-t border-slate-800/80 text-xs text-slate-400 flex items-center justify-between">
            <span>Đồng bộ Realtime ứng dụng Vie-farm Mobile</span>
            <span>Cập nhật 30s/lần</span>
          </div>
        </div>
      </div>

      {/* MongoDB Persistent History Table */}
      <div className="glass-card rounded-3xl p-6 shadow-xl space-y-4">
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-2">
          <div className="flex items-center gap-2">
            <Layers className="w-5 h-5 text-emerald-400" />
            <h2 className="text-lg font-bold text-white">
              Lịch Sử Cảm Biến Trường Tồn Trong MongoDB (<code class="text-emerald-400 font-mono">iot_telemetry</code>)
            </h2>
          </div>
          <span className="text-xs text-slate-400 font-mono">
            Tổng cộng: <strong className="text-white">{history.length}</strong> bản ghi
          </span>
        </div>

        <div className="overflow-x-auto rounded-xl border border-slate-800">
          <table className="w-full text-left border-collapse text-sm">
            <thead>
              <tr className="bg-slate-900/90 border-b border-slate-800 text-slate-400 text-xs uppercase font-mono">
                <th className="py-3 px-4">Thời gian</th>
                <th className="py-3 px-4">Mã trạm</th>
                <th className="py-3 px-4">Độ ẩm đất</th>
                <th className="py-3 px-4">pH đất</th>
                <th className="py-3 px-4">Nhiệt độ</th>
                <th className="py-3 px-4">Độ ẩm khí</th>
                <th className="py-3 px-4">Bức xạ Lux</th>
                <th className="py-3 px-4">Đạm (N)</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-800/60 bg-slate-950/40">
              {history.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-8 text-center text-slate-500">
                    Đang kết nối MongoDB... Bấm "Gửi Ngay" hoặc bật "Tự Động 30s".
                  </td>
                </tr>
              ) : (
                history.map((row, idx) => (
                  <tr key={row.id || idx} className="hover:bg-slate-900/60 transition-colors">
                    <td className="py-3 px-4 font-mono text-slate-400 text-xs">
                      {row.timestamp ? new Date(row.timestamp).toLocaleTimeString() : "--:--"}
                    </td>
                    <td className="py-3 px-4 font-bold text-emerald-400">{row.device_id}</td>
                    <td className="py-3 px-4 font-extrabold text-white">{row.soil_moisture}%</td>
                    <td className="py-3 px-4 text-emerald-300">pH {row.soil_ph}</td>
                    <td className="py-3 px-4">{row.temperature}°C</td>
                    <td className="py-3 px-4">{row.humidity}%</td>
                    <td className="py-3 px-4 font-mono">{row.light_intensity} Lux</td>
                    <td className="py-3 px-4 font-semibold text-purple-300">{row.nitrogen_ppm} ppm</td>
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
