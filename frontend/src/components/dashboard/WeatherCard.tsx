import { useState, useEffect } from "react";
import { CloudSun, Droplets, Wind, Thermometer, ShieldAlert, Sparkles, RefreshCw } from "lucide-react";
import Card from "./Shared/Card";
import SectionTitle from "./Shared/SectionTitle";
import api from "../../api";

interface WeatherData {
  location_name: string;
  temp_celsius: number;
  feels_like_celsius: number;
  humidity_percent: number;
  wind_speed_m_s: number;
  description: string;
  icon_url?: string;
  fungal_disease_risk: string;
  agricultural_advice: string;
}

export default function WeatherCard() {
  const [weather, setWeather] = useState<WeatherData>({
    location_name: "Vườn Sầu Riêng Đắk Lắk",
    temp_celsius: 29.5,
    feels_like_celsius: 31.0,
    humidity_percent: 82,
    wind_speed_m_s: 2.8,
    description: "Mây rải rác, độ ẩm cao",
    fungal_disease_risk: "MEDIUM",
    agricultural_advice: "Thời tiết tương đối ẩm. Kiểm tra kỹ mặt dưới lá và gốc cây sầu riêng.",
  });
  const [loading, setLoading] = useState(false);

  const fetchWeather = async () => {
    setLoading(true);
    try {
      const res = await api.get<{ data: WeatherData }>("/weather/current");
      if (res.data?.data) {
        setWeather(res.data.data);
      }
    } catch {
      // fallback handled by initial state
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchWeather();
  }, []);

  return (
    <Card className="flex flex-col h-full overflow-hidden" padding={false} hover={false}>
      <div className="flex flex-col justify-between h-full p-4 space-y-3">
        {/* Header */}
        <div className="flex items-center justify-between pb-2 border-b border-gray-100">
          <SectionTitle
            icon={<CloudSun className="w-5 h-5 text-amber-500" />}
            title="Thời tiết Nông nghiệp Realtime"
            size="section"
            subtitle={weather.location_name || "Vùng Tây Nguyên"}
          />
          <button
            type="button"
            onClick={fetchWeather}
            title="Cập nhật thời tiết"
            className="p-1.5 rounded-[8px] bg-gray-100 hover:bg-gray-200 text-gray-600 transition-all"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? "animate-spin text-emerald-600" : ""}`} />
          </button>
        </div>

        {/* Main Temperature & Weather Info */}
        <div className="bg-gradient-to-r from-amber-50/80 via-emerald-50/60 to-teal-50/80 p-3.5 rounded-[16px] border border-emerald-100 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 rounded-[14px] bg-white/80 backdrop-blur-md border border-amber-200/60 flex items-center justify-center shadow-xs">
              <CloudSun className="w-7 h-7 text-amber-500" />
            </div>
            <div>
              <div className="flex items-baseline gap-1">
                <span className="text-2xl font-black text-gray-900 leading-none">{weather.temp_celsius}°C</span>
                <span className="text-[11px] font-semibold text-gray-500">(Cảm nhận {weather.feels_like_celsius}°C)</span>
              </div>
              <p className="text-xs font-bold text-emerald-800 mt-1 capitalize">{weather.description}</p>
            </div>
          </div>

          <div className="text-right space-y-1">
            <div className="flex items-center justify-end gap-1 text-[11px] font-bold text-gray-700">
              <Droplets className="w-3.5 h-3.5 text-blue-500" />
              <span>Độ ẩm: {weather.humidity_percent}%</span>
            </div>
            <div className="flex items-center justify-end gap-1 text-[11px] font-bold text-gray-700">
              <Wind className="w-3.5 h-3.5 text-teal-600" />
              <span>Gió: {weather.wind_speed_m_s} m/s</span>
            </div>
          </div>
        </div>

        {/* AI Agri-Risk Recommendation */}
        <div className="bg-amber-50/90 p-3 rounded-[14px] border border-amber-200/80 text-xs text-amber-950 font-medium space-y-1">
          <div className="flex items-center justify-between">
            <strong className="font-extrabold text-amber-900 flex items-center gap-1.5 text-[11px]">
              <Sparkles className="w-3.5 h-3.5 text-amber-600" />
              Khuyến nghị AI Agronomist cho vườn:
            </strong>
            <span className="text-[10px] font-black uppercase tracking-wider bg-amber-200/80 text-amber-900 px-2 py-0.5 rounded-md">
              Rủi ro: {weather.fungal_disease_risk === "HIGH" ? "🔴 CAO" : weather.fungal_disease_risk === "MEDIUM" ? "🟡 TRUNG BÌNH" : "🟢 THẤP"}
            </span>
          </div>
          <p className="text-[11px] text-amber-900 leading-relaxed font-semibold">
            {weather.agricultural_advice}
          </p>
        </div>
      </div>
    </Card>
  );
}
