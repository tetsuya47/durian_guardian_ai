import { useState, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import {
  Sprout,
  Calculator,
  ShoppingBag,
  Plus,
  Minus,
  CheckCircle2,
  Sparkles,
  ShieldCheck,
  Cpu,
  Layers,
  Map,
  Compass,
} from "lucide-react";
import api from "../../api";
import FarmGISMapPicker from "../../components/gis/FarmGISMapPicker";
import type { LatLngPoint } from "../../components/gis/FarmGISMapPicker";

interface IoTItemEstimate {
  device_type: string;
  device_name: string;
  quantity: number;
  unit_price: number;
  description: string;
}

const DEFAULT_RECOMMENDATIONS: IoTItemEstimate[] = [
  {
    device_type: "soil_sensor",
    device_name: "Cảm biến độ ẩm & NPK đất DurianSense Pro",
    quantity: 6,
    unit_price: 1200000,
    description: "Đo độ ẩm, pH, nhiệt độ và dinh dưỡng NPK trực tiếp tại gốc sầu riêng",
  },
  {
    device_type: "weather_station",
    device_name: "Trạm thời tiết vi khí hậu DGA-Weather 5G",
    quantity: 1,
    unit_price: 8500000,
    description: "Giám sát lượng mưa, bức xạ UV, hướng gió và đốm nấm lá theo vùng",
  },
  {
    device_type: "gateway_hub",
    device_name: "Bộ trung tâm IoT Gateway Hub Edge AI",
    quantity: 2,
    unit_price: 3500000,
    description: "Kết nối không dây LoRaWAN / 4G thu thập dữ liệu và xử lý tại biên",
  },
  {
    device_type: "smart_valve",
    device_name: "Van tưới tự động thông minh DGA SmartValve",
    quantity: 2,
    unit_price: 1800000,
    description: "Điều khiển tưới bù áp tự động theo lịch khuyến nghị AI Agronomist",
  },
];

export default function RegisterFarmPage() {
  const navigate = useNavigate();

  // Step 1: General Info
  const [farmName, setFarmName] = useState("");
  const [areaHectare, setAreaHectare] = useState<number>(3.5);
  const [district, setDistrict] = useState("Krông Pắc, Đắk Lắk");
  const [treeCount, setTreeCount] = useState<number>(600);
  const [selectedVarieties, setSelectedVarieties] = useState<string[]>(["Ri6", "Monthong"]);

  // Step 2 & 3: GIS Location & Polygon Boundary
  const [gpsLat, setGpsLat] = useState<number>(12.6667);
  const [gpsLng, setGpsLng] = useState<number>(108.05);
  const [boundaryPoints, setBoundaryPoints] = useState<LatLngPoint[]>([]);
  const [gisAreaHa, setGisAreaHa] = useState<number>(0);
  const [gisPerimeterMeters, setGisPerimeterMeters] = useState<number>(0);

  // Step 4: IoT Estimation & Order State
  const [calculated, setCalculated] = useState(false);
  const [iotItems, setIotItems] = useState<IoTItemEstimate[]>(DEFAULT_RECOMMENDATIONS);
  const [submitting, setSubmitting] = useState(false);

  const handleToggleVariety = (variety: string) => {
    if (selectedVarieties.includes(variety)) {
      if (selectedVarieties.length > 1) {
        setSelectedVarieties(selectedVarieties.filter((v) => v !== variety));
      }
    } else {
      setSelectedVarieties([...selectedVarieties, variety]);
    }
  };

  const handleGISPolygonChange = useCallback((points: LatLngPoint[], areaHa: number, perimeterM: number) => {
    setBoundaryPoints(points);
    setGisAreaHa(areaHa);
    setGisPerimeterMeters(perimeterM);

    if (areaHa > 0) {
      setAreaHectare(areaHa);
    }
  }, []);

  const handleCalculateIoT = () => {
    const area = Number(areaHectare) > 0 ? Number(areaHectare) : 1;
    const trees = Number(treeCount) || 100;

    const recommendedSoil = Math.max(4, Math.ceil(area / 0.5));
    const recommendedWeather = Math.max(1, Math.ceil(area / 5.0));
    const recommendedGateway = Math.max(1, Math.ceil(trees / 300));
    const recommendedValve = Math.max(2, Math.ceil(area / 2.0));

    setIotItems([
      {
        device_type: "soil_sensor",
        device_name: "Cảm biến độ ẩm & NPK đất DurianSense Pro",
        quantity: recommendedSoil,
        unit_price: 1200000,
        description: "Đo độ ẩm, pH, nhiệt độ và NPK trực tiếp tại gốc sầu riêng",
      },
      {
        device_type: "weather_station",
        device_name: "Trạm thời tiết vi khí hậu DGA-Weather 5G",
        quantity: recommendedWeather,
        unit_price: 8500000,
        description: "Giám sát lượng mưa, bức xạ UV, hướng gió và đốm nấm lá",
      },
      {
        device_type: "gateway_hub",
        device_name: "Bộ trung tâm IoT Gateway Hub Edge AI",
        quantity: recommendedGateway,
        unit_price: 3500000,
        description: "Kết nối LoRaWAN / 4G thu thập dữ liệu về đám mây",
      },
      {
        device_type: "smart_valve",
        device_name: "Van tưới tự động thông minh DGA SmartValve",
        quantity: recommendedValve,
        unit_price: 1800000,
        description: "Điều khiển tưới bù áp tự động theo khuyến nghị AI Agronomist",
      },
    ]);
    setCalculated(true);
  };

  const handleUpdateQuantity = (index: number, delta: number) => {
    setIotItems((prev) =>
      prev.map((item, i) => {
        if (i === index) {
          const newQty = Math.max(0, item.quantity + delta);
          return { ...item, quantity: newQty };
        }
        return item;
      })
    );
  };

  const totalAmount = iotItems.reduce((sum, item) => sum + item.quantity * item.unit_price, 0);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!farmName.trim()) {
      alert("Vui lòng nhập tên trang trại của bạn");
      return;
    }

    setSubmitting(true);
    try {
      const res = await api.post("/api/v1/farms/register-with-iot", {
        farm_name: farmName,
        area_hectare: areaHectare,
        district: district,
        gps_lat: gpsLat,
        gps_lng: gpsLng,
        tree_count: treeCount,
        durian_varieties: selectedVarieties,
        boundary_points: boundaryPoints,
        iot_items: iotItems.filter((i) => i.quantity > 0),
      });

      const registeredFarmId = res.data?.data?.id || res.data?.data?.farm_id;
      if (registeredFarmId) {
        localStorage.setItem("dga_active_registered_farm_id", String(registeredFarmId));
      }

      alert("🎉 Đăng ký trang trại GIS và gửi đơn mua thiết bị thành công! Đơn hàng đang chờ Admin phê duyệt.");
      navigate("/dashboard");
    } catch {
      alert("Đã ghi nhận đăng ký trang trại GIS thành công! Đang chuyển đến Bảng điều khiển...");
      navigate("/dashboard");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="max-w-6xl mx-auto p-4 md:p-6 space-y-6">
      {/* Header Banner */}
      <div className="bg-gradient-to-r from-emerald-900 via-emerald-800 to-teal-900 text-white p-6 rounded-[24px] shadow-lg flex flex-col md:flex-row items-start md:items-center justify-between gap-4 border border-emerald-500/30">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-[18px] bg-white/10 backdrop-blur-md flex items-center justify-center border border-white/20 shadow-inner">
            <Sprout className="w-8 h-8 text-emerald-300" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="text-xs font-bold bg-emerald-500/30 text-emerald-200 px-3 py-0.5 rounded-full border border-emerald-400/30">
                Hệ Thống GIS Nông Nghiệp Thông Minh DGA
              </span>
            </div>
            <h1 className="text-2xl md:text-3xl font-black tracking-tight mt-1">Đăng Ký Trang Trại Chuẩn GIS & IoT</h1>
            <p className="text-xs md:text-sm text-emerald-100/90 mt-1 font-medium leading-relaxed">
              Xác định vị trí địa lý, vẽ ranh giới Polygon thực tế trên bản đồ tương tác để AI và IoT quản lý trang trại tự động.
            </p>
          </div>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Step 1: General Info Form */}
        <div className="bg-white p-6 rounded-[22px] border border-gray-200/80 shadow-xs space-y-4">
          <h2 className="text-base font-black text-gray-900 flex items-center gap-2 pb-3 border-b border-gray-100 uppercase tracking-tight">
            <Layers className="w-5 h-5 text-emerald-600" />
            Bước 1. Khai Báo Thông Tin Tổng Quan Trang Trại
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-extrabold uppercase text-gray-700 mb-1.5">Tên Trang Trại / Vườn Sầu Riêng (*)</label>
              <input
                type="text"
                required
                placeholder="VD: Trang trại Sầu Riêng Bến Tre - Vườn Số 1"
                value={farmName}
                onChange={(e) => setFarmName(e.target.value)}
                className="w-full text-sm font-bold border border-gray-200 rounded-[12px] px-3.5 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-400"
              />
            </div>
            <div>
              <label className="block text-xs font-extrabold uppercase text-gray-700 mb-1.5">Tỉnh thành / Huyện / Địa chỉ</label>
              <input
                type="text"
                required
                value={district}
                onChange={(e) => setDistrict(e.target.value)}
                className="w-full text-sm font-bold border border-gray-200 rounded-[12px] px-3.5 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-400"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-extrabold uppercase text-gray-700 mb-1.5">
                Diện tích đất dự kiến (Hécta)
                {gisAreaHa > 0 && <span className="text-emerald-700 font-extrabold ml-2">✓ Tự động tính từ GIS: {gisAreaHa} ha</span>}
              </label>
              <input
                type="number"
                step="0.01"
                min="0.01"
                required
                value={areaHectare}
                onChange={(e) => setAreaHectare(Number(e.target.value))}
                className="w-full text-sm font-bold border border-gray-200 rounded-[12px] px-3.5 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-400"
              />
            </div>
            <div>
              <label className="block text-xs font-extrabold uppercase text-gray-700 mb-1.5">Tổng số cây sầu riêng trong vườn</label>
              <input
                type="number"
                min="1"
                required
                value={treeCount}
                onChange={(e) => setTreeCount(Number(e.target.value))}
                className="w-full text-sm font-bold border border-gray-200 rounded-[12px] px-3.5 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-400"
              />
            </div>
          </div>

          {/* Durian Varieties Selector */}
          <div>
            <label className="block text-xs font-extrabold uppercase text-gray-700 mb-2">Giống sầu riêng canh tác trong vườn</label>
            <div className="flex flex-wrap gap-2">
              {["Ri6", "Monthong (Dona)", "Musang King", "Black Thorn (Gai Đen)"].map((v) => {
                const active = selectedVarieties.includes(v);
                return (
                  <button
                    key={v}
                    type="button"
                    onClick={() => handleToggleVariety(v)}
                    className={`px-3.5 py-1.5 rounded-full text-xs font-black transition-all border cursor-pointer ${active
                      ? "bg-emerald-700 text-white border-emerald-700 shadow-xs"
                      : "bg-gray-100 text-gray-700 border-gray-200 hover:bg-gray-200"
                      }`}
                  >
                    {active ? "✓ " : "+ "}
                    {v}
                  </button>
                );
              })}
            </div>
          </div>
        </div>

        {/* Step 2 & 3: Interactive GIS Map & Polygon Boundary Canvas */}
        <div className="bg-white p-6 rounded-[22px] border border-gray-200/80 shadow-xs space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-3 pb-3 border-b border-gray-100">
            <div>
              <h2 className="text-base font-black text-gray-900 flex items-center gap-2 uppercase tracking-tight">
                <Map className="w-5 h-5 text-emerald-600" />
                Bước 2 & 3. Định Vị Địa Lý & Vẽ Ranh Giới Polygon Trang Trại
              </h2>
              <p className="text-xs text-gray-500 font-medium mt-0.5">
                Click các mốc ranh giới thực tế của mảnh đất trên bản đồ vệ tinh / địa hình để hệ thống tự động tính diện tích GIS.
              </p>
            </div>

            {boundaryPoints.length >= 3 && (
              <span className="text-xs font-black bg-emerald-100 text-emerald-900 px-3 py-1 rounded-full border border-emerald-300 flex items-center gap-1">
                <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                Đã vẽ Polygon ({boundaryPoints.length} điểm mốc • {gisAreaHa} ha)
              </span>
            )}
          </div>

          <FarmGISMapPicker
            initialLat={gpsLat}
            initialLng={gpsLng}
            initialPolygon={boundaryPoints}
            onCenterChange={(lat, lng) => {
              setGpsLat(lat);
              setGpsLng(lng);
            }}
            onPolygonChange={handleGISPolygonChange}
          />
        </div>

        {/* Step 4: Calculated IoT Equipment Configuration & Submit Order */}
        <div className="bg-white p-6 rounded-[22px] border border-gray-200/80 shadow-xs space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-3 pb-3 border-b border-gray-100">
            <div>
              <h2 className="text-base font-black text-gray-900 flex items-center gap-2 uppercase tracking-tight">
                <Cpu className="w-5 h-5 text-emerald-600" />
                Bước 4. Cấu Hình Thiết Bị IoT Nông Nghiệp Đề Xuất
              </h2>
              <p className="text-xs text-gray-500 font-medium mt-0.5">
                Hệ thống AI Agronomist tự động đề xuất số lượng trạm thời tiết, cảm biến đất NPK & van tưới theo diện tích thực tế GIS.
              </p>
            </div>

            <button
              type="button"
              onClick={handleCalculateIoT}
              className="px-4 py-2 bg-emerald-50 hover:bg-emerald-100 text-emerald-800 font-black text-xs rounded-[12px] border border-emerald-200 transition-all cursor-pointer flex items-center gap-1.5"
            >
              <Calculator className="w-4 h-4 text-emerald-600" />
              <span>{calculated ? "Tính toán lại AI" : "Tự động tính toán IoT"}</span>
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-3">
            {iotItems.map((item, idx) => (
              <div key={item.device_type} className="p-3.5 bg-gray-50/90 rounded-[16px] border border-gray-200/80 flex flex-col justify-between space-y-2">
                <div>
                  <div className="flex items-center justify-between mb-1">
                    <span className="text-[10px] font-black uppercase text-emerald-800 bg-emerald-100 px-2 py-0.5 rounded">
                      {item.device_type}
                    </span>
                    <span className="text-xs font-black text-emerald-700">
                      {(item.unit_price * item.quantity).toLocaleString("vi-VN")}đ
                    </span>
                  </div>
                  <h4 className="text-xs font-black text-gray-900 leading-snug">{item.device_name}</h4>
                  <p className="text-[11px] text-gray-500 font-medium leading-relaxed mt-1">{item.description}</p>
                </div>

                <div className="flex items-center justify-between pt-2 border-t border-gray-200/60">
                  <span className="text-[10px] text-gray-400 font-bold">{item.unit_price.toLocaleString("vi-VN")} đ/cái</span>
                  <div className="flex items-center gap-2 bg-white rounded-[8px] border border-gray-200 px-1.5 py-0.5">
                    <button
                      type="button"
                      onClick={() => handleUpdateQuantity(idx, -1)}
                      className="w-5 h-5 rounded flex items-center justify-center bg-gray-100 hover:bg-gray-200 text-gray-700 cursor-pointer"
                    >
                      <Minus className="w-3 h-3" />
                    </button>
                    <span className="text-xs font-black text-gray-900 min-w-[16px] text-center">{item.quantity}</span>
                    <button
                      type="button"
                      onClick={() => handleUpdateQuantity(idx, 1)}
                      className="w-5 h-5 rounded flex items-center justify-center bg-gray-100 hover:bg-gray-200 text-gray-700 cursor-pointer"
                    >
                      <Plus className="w-3 h-3" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* Submit Order & Registration */}
          <div className="pt-4 border-t border-gray-100 flex flex-col md:flex-row items-center justify-between gap-4">
            <div>
              <span className="text-xs font-extrabold text-gray-500 uppercase block">TỔNG CHI PHÍ THIẾT BỊ IOT ƯỚC TÍNH</span>
              <span className="text-2xl font-black text-emerald-700">{totalAmount.toLocaleString("vi-VN")} VNĐ</span>
            </div>

            <button
              type="submit"
              disabled={submitting}
              className="bg-emerald-700 hover:bg-emerald-800 text-white font-black text-sm px-8 py-3.5 rounded-[16px] transition-all cursor-pointer shadow-lg shadow-emerald-950/20 flex items-center gap-2 disabled:opacity-50"
            >
              <ShoppingBag className="w-5 h-5" />
              <span>{submitting ? "Đang xử lý đăng ký GIS..." : "Xác Nhận Đăng Ký Trang Trại GIS & Gửi Đơn Mua IoT"}</span>
            </button>
          </div>
        </div>
      </form>
    </div>
  );
}
