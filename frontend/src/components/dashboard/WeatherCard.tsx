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
      const res = await api.get<{ data: WeatherData }>("/api/v1/weather/current");
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
      <div className="flex flex-col justify-between h-full p-3.5 space-y-2.5">
        {/* Header */}
        <div className="flex items-center justify-between pb-2 border-b border-gray-100">
          <SectionTitle
            icon={<CloudSun className="w-5 h-5 text-amber-500" />}
            title="Thời tiết Realtime"
            size="section"
            subtitle={weather.location_name || "Vùng Tây Nguyên"}
          />
          <button
            type="button"
            onClick={fetchWeather}
            title="Cập nhật thời tiết"
            className="p-1 rounded-[8px] bg-gray-100 hover:bg-gray-200 text-gray-600 transition-all flex-shrink-0"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? "animate-spin text-emerald-600" : ""}`} />
          </button>
        </div>

        {/* Main Temperature & Weather Info (Compact Stacked Grid) */}
        <div className="bg-gradient-to-br from-amber-50/90 via-emerald-50/70 to-teal-50/90 p-3 rounded-[14px] border border-emerald-100/80 space-y-2">
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <div className="w-10 h-10 rounded-[12px] bg-white/90 backdrop-blur-md border border-amber-200/60 flex items-center justify-center shadow-2xs flex-shrink-0">
                <CloudSun className="w-6 h-6 text-amber-500" />
              </div>
              <div>
                <div className="flex items-baseline gap-1">
                  <span className="text-xl font-black text-gray-900 leading-none">{weather.temp_celsius}°C</span>
                  <span className="text-[10px] font-semibold text-gray-500">({weather.feels_like_celsius}°C)</span>
                </div>
                <p className="text-[11px] font-bold text-emerald-800 mt-0.5 capitalize truncate max-w-[130px]">
                  {weather.description}
                </p>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-1.5 pt-1 border-t border-emerald-100/60 text-[10px] font-extrabold text-gray-700">
            <div className="flex items-center gap-1 bg-white/70 p-1 rounded-md border border-emerald-100/40">
              <Droplets className="w-3 h-3 text-blue-500 flex-shrink-0" />
              <span className="truncate">Độ ẩm: <b>{weather.humidity_percent}%</b></span>
            </div>
            <div className="flex items-center gap-1 bg-white/70 p-1 rounded-md border border-emerald-100/40">
              <Wind className="w-3 h-3 text-teal-600 flex-shrink-0" />
              <span className="truncate">Gió: <b>{weather.wind_speed_m_s} m/s</b></span>
            </div>
          </div>
        </div>

        {/* AI Agri-Risk Recommendation */}
        <div className="bg-amber-50/90 p-2.5 rounded-[12px] border border-amber-200/80 text-[11px] text-amber-950 font-medium space-y-1 my-auto">
          <div className="flex items-center justify-between gap-1 flex-wrap">
            <strong className="font-extrabold text-amber-900 flex items-center gap-1 text-[10px] truncate">
              <Sparkles className="w-3 h-3 text-amber-600 flex-shrink-0" />
              Khuyến nghị AI:
            </strong>
            <span className="text-[9px] font-black uppercase bg-amber-200/90 text-amber-950 px-1.5 py-0.5 rounded">
              RỦI RO: {weather.fungal_disease_risk === "HIGH" ? "CAO" : weather.fungal_disease_risk === "MEDIUM" ? "TRUNG BÌNH" : "THẤP"}
            </span>
          </div>
          <p className="text-[10px] text-amber-900 leading-snug font-semibold line-clamp-2">
            {weather.agricultural_advice}
          </p>
        </div>
      </div>
    </Card>
  );
}
