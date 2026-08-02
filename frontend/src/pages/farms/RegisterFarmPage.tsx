import { useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  Sprout,
  Calculator,
  ShoppingBag,
  Plus,
  Minus,
  CheckCircle2,
  Navigation,
  Sparkles,
  ShieldCheck,
  Cpu,
  Layers,
} from "lucide-react";
import api from "../../api";

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

  // Form State
  const [farmName, setFarmName] = useState("");
  const [areaHectare, setAreaHectare] = useState<number>(3.5);
  const [district, setDistrict] = useState("Krông Pắc, Đắk Lắk");
  const [gpsLat, setGpsLat] = useState<number>(12.6667);
  const [gpsLng, setGpsLng] = useState<number>(108.05);
  const [treeCount, setTreeCount] = useState<number>(600);
  const [selectedVarieties, setSelectedVarieties] = useState<string[]>(["Ri6", "Monthong"]);

  // IoT Estimation State
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

  const handleAutoDetectGPS = () => {
    if ("geolocation" in navigator) {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          setGpsLat(Number(pos.coords.latitude.toFixed(4)));
          setGpsLng(Number(pos.coords.longitude.toFixed(4)));
        },
        () => {
          // Fallback to Dak Lak coords
          setGpsLat(12.6667);
          setGpsLng(108.05);
        }
      );
    }
  };

  const handleCalculateIoT = () => {
    const area = Number(areaHectare) || 1;
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
      await api.post("/api/v1/farms/register-with-iot", {
        farm_name: farmName,
        area_hectare: areaHectare,
        district: district,
        gps_lat: gpsLat,
        gps_lng: gpsLng,
        tree_count: treeCount,
        durian_varieties: selectedVarieties,
        iot_items: iotItems.filter((i) => i.quantity > 0),
      });

      alert("🎉 Đăng ký trang trại và gửi đơn mua thiết bị thành công! Đơn hàng đang được Admin chuyển qua bộ phận vận chuyển.");
      navigate("/iot-setup-guide");
    } catch {
      alert("Đã có đơn mua hoặc đăng ký thành công! Đang chuyển đến hướng dẫn lắp đặt...");
      navigate("/iot-setup-guide");
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="max-w-5xl mx-auto p-4 md:p-6 space-y-6">
      {/* Header Banner */}
      <div className="bg-gradient-to-r from-emerald-800 via-emerald-700 to-teal-700 text-white p-6 rounded-[24px] shadow-lg flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-[18px] bg-white/10 backdrop-blur-md flex items-center justify-center border border-white/20">
            <Sprout className="w-8 h-8 text-emerald-300" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <span className="text-xs font-bold bg-emerald-500/30 text-emerald-200 px-2.5 py-0.5 rounded-full border border-emerald-400/30">
                Bước 1 / 2: Đăng ký Trang trại & Thiết bị IoT
              </span>
            </div>
            <h1 className="text-2xl md:text-3xl font-extrabold mt-1">Đăng Ký Vườn Sầu Riêng Mới</h1>
            <p className="text-sm text-emerald-100 mt-1">
              Nhập các chỉ số diện tích, tọa độ & quy mô cây để AI tính toán cấu hình IoT tối ưu nhất.
            </p>
          </div>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* Left Column: Farm Information Form */}
        <div className="lg:col-span-7 bg-white p-6 rounded-[22px] border border-gray-100 shadow-sm space-y-4">
          <h2 className="text-lg font-bold text-gray-900 flex items-center gap-2 pb-3 border-b border-gray-100">
            <Layers className="w-5 h-5 text-emerald-600" />
            1. Thông Tin Chi Tiết Vườn Sầu Riêng
          </h2>

          <div>
            <label className="block text-xs font-extrabold uppercase text-gray-600 mb-1.5">Tên Trang Trại / Nông Trại (*)</label>
            <input
              type="text"
              required
              placeholder="VD: Trang trại Sầu Riêng Đắk Lắk - Vườn Nông Dân 1"
              value={farmName}
              onChange={(e) => setFarmName(e.target.value)}
              className="w-full text-sm font-semibold border border-gray-200 rounded-[12px] px-3.5 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-400"
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-extrabold uppercase text-gray-600 mb-1.5">Diện tích canh tác (Hécta)</label>
              <input
                type="number"
                step="0.1"
                min="0.1"
                required
                value={areaHectare}
                onChange={(e) => setAreaHectare(Number(e.target.value))}
                className="w-full text-sm font-semibold border border-gray-200 rounded-[12px] px-3.5 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-400"
              />
            </div>
            <div>
              <label className="block text-xs font-extrabold uppercase text-gray-600 mb-1.5">Tổng số cây sầu riêng</label>
              <input
                type="number"
                min="1"
                required
                value={treeCount}
                onChange={(e) => setTreeCount(Number(e.target.value))}
                className="w-full text-sm font-semibold border border-gray-200 rounded-[12px] px-3.5 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-400"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-extrabold uppercase text-gray-600 mb-1.5">Vị trí / Tỉnh thành - Huyện</label>
            <input
              type="text"
              required
              value={district}
              onChange={(e) => setDistrict(e.target.value)}
              className="w-full text-sm font-semibold border border-gray-200 rounded-[12px] px-3.5 py-2.5 focus:outline-none focus:ring-2 focus:ring-emerald-400"
            />
          </div>

          {/* GPS Coordinates */}
          <div className="bg-gray-50 p-3.5 rounded-[14px] border border-gray-200/80 space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-gray-700 flex items-center gap-1.5">
                <Navigation className="w-4 h-4 text-emerald-600" />
                Tọa độ địa lý GPS (Latitude, Longitude)
              </span>
              <button
                type="button"
                onClick={handleAutoDetectGPS}
                className="text-[11px] font-extrabold text-emerald-700 hover:text-emerald-800 bg-emerald-100 hover:bg-emerald-200 px-2.5 py-1 rounded-[8px] transition-all"
              >
                🛰️ Đánh dấu vị trí hiện tại
              </button>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <span className="text-[10px] font-bold text-gray-500 block">Vĩ độ (Latitude)</span>
                <input
                  type="number"
                  step="0.0001"
                  value={gpsLat}
                  onChange={(e) => setGpsLat(Number(e.target.value))}
                  className="w-full text-xs font-bold bg-white border border-gray-200 rounded-[10px] px-3 py-2"
                />
              </div>
              <div>
                <span className="text-[10px] font-bold text-gray-500 block">Kinh độ (Longitude)</span>
                <input
                  type="number"
                  step="0.0001"
                  value={gpsLng}
                  onChange={(e) => setGpsLng(Number(e.target.value))}
                  className="w-full text-xs font-bold bg-white border border-gray-200 rounded-[10px] px-3 py-2"
                />
              </div>
            </div>
          </div>

          {/* Durian Varieties */}
          <div>
            <label className="block text-xs font-extrabold uppercase text-gray-600 mb-2">Giống sầu riêng trồng trong vườn</label>
            <div className="flex flex-wrap gap-2">
              {["Ri6", "Monthong (Dona)", "Musang King", "Black Thorn (Gai Đen)"].map((v) => {
                const active = selectedVarieties.includes(v);
                return (
                  <button
                    key={v}
                    type="button"
                    onClick={() => handleToggleVariety(v)}
                    className={`px-3 py-1.5 rounded-full text-xs font-bold transition-all border ${
                      active
                        ? "bg-emerald-600 text-white border-emerald-600 shadow-sm"
                        : "bg-gray-100 text-gray-600 border-gray-200 hover:bg-gray-200"
                    }`}
                  >
                    {active ? "✓ " : "+ "}
                    {v}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Calculate IoT Button */}
          <div className="pt-2">
            <button
              type="button"
              onClick={handleCalculateIoT}
              className="w-full flex items-center justify-center gap-2 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 text-white font-extrabold py-3 rounded-[14px] shadow-md transition-all text-sm"
            >
              <Calculator className="w-5 h-5" />
              ⚡ Tính toán số lượng thiết bị IoT tối ưu phù hợp với vườn
            </button>
          </div>
        </div>

        {/* Right Column: Calculated IoT Configuration & Order */}
        <div className="lg:col-span-5 bg-white p-6 rounded-[22px] border border-gray-100 shadow-sm flex flex-col justify-between space-y-4">
          <div>
            <h2 className="text-lg font-bold text-gray-900 flex items-center justify-between pb-3 border-b border-gray-100">
              <span className="flex items-center gap-2">
                <Cpu className="w-5 h-5 text-emerald-600" />
                2. Cấu Hình Thiết Bị IoT Được Đề Xuất
              </span>
              {calculated && <span className="text-[11px] font-extrabold text-emerald-700 bg-emerald-100 px-2 py-0.5 rounded-full">Đã tính toán AI</span>}
            </h2>

            <p className="text-xs text-gray-500 mt-2 font-medium">
              Bạn có thể tự do <strong>tăng/giảm số lượng</strong> theo ý muốn. Hệ thống sẽ tự động tính lại tổng chi phí.
            </p>

            <div className="mt-4 space-y-3 max-h-[380px] overflow-y-auto pr-1">
              {iotItems.map((item, idx) => (
                <div key={item.device_type} className="p-3 bg-gray-50 rounded-[14px] border border-gray-200/70 flex flex-col gap-2">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <h4 className="text-xs font-bold text-gray-900 leading-tight">{item.device_name}</h4>
                      <p className="text-[10px] text-gray-500 font-medium mt-0.5">{item.description}</p>
                    </div>
                    <span className="text-xs font-extrabold text-emerald-700 whitespace-nowrap">
                      {(item.unit_price * item.quantity).toLocaleString("vi-VN")} đ
                    </span>
                  </div>

                  {/* Quantity Controller */}
                  <div className="flex items-center justify-between pt-1 border-t border-gray-200/50">
                    <span className="text-[11px] text-gray-400 font-medium">Đơn giá: {item.unit_price.toLocaleString("vi-VN")} đ/cái</span>
                    <div className="flex items-center gap-2 bg-white rounded-lg border border-gray-200 p-1">
                      <button
                        type="button"
                        onClick={() => handleUpdateQuantity(idx, -1)}
                        className="w-6 h-6 rounded flex items-center justify-center bg-gray-100 hover:bg-gray-200 text-gray-700"
                      >
                        <Minus className="w-3.5 h-3.5" />
                      </button>
                      <span className="text-xs font-extrabold text-gray-900 min-w-[20px] text-center">{item.quantity}</span>
                      <button
                        type="button"
                        onClick={() => handleUpdateQuantity(idx, 1)}
                        className="w-6 h-6 rounded flex items-center justify-center bg-gray-100 hover:bg-gray-200 text-gray-700"
                      >
                        <Plus className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Order Summary Footer */}
          <div className="pt-4 border-t border-gray-100 space-y-3">
            <div className="flex items-center justify-between text-sm">
              <span className="font-semibold text-gray-600">Ước tính tổng chi phí thiết bị:</span>
              <strong className="text-xl font-black text-emerald-700">{totalAmount.toLocaleString("vi-VN")} VNĐ</strong>
            </div>

            <button
              type="submit"
              disabled={submitting}
              className="w-full flex items-center justify-center gap-2 bg-emerald-700 hover:bg-emerald-800 text-white font-extrabold py-3.5 rounded-[14px] shadow-lg transition-all text-sm disabled:opacity-50"
            >
              <ShoppingBag className="w-5 h-5" />
              {submitting ? "Đang xử lý đăng ký..." : "Gửi Đơn Mua Thiết Bị IoT ➔ Admin Phê Duyệt"}
            </button>

            <div className="flex items-center justify-center gap-1 text-[11px] text-gray-400 font-medium">
              <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
              <span>Giao hàng tận vườn • Bảo hành chính hãng 24 tháng • Hỗ trợ kết nối tận nơi</span>
            </div>
          </div>
        </div>
      </form>
    </div>
  );
}
