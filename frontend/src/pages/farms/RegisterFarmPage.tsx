import { useState, useCallback } from "react";
import { useNavigate } from "react-router-dom";
import {
  Sprout,
  Calculator,
  ShoppingBag,
  Plus,
  Minus,
  CheckCircle2,
  Cpu,
  Layers,
  Map,
  ArrowLeft,
  Save,
  ChevronRight,
  Wifi,
  CloudSun,
  Activity,
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
    device_name: "Cảm biến đất & NPK",
    quantity: 6,
    unit_price: 1200000,
    description: "DurianSense Pro - Đo độ ẩm, pH, nhiệt độ và dinh dưỡng NPK đất",
  },
  {
    device_type: "weather_station",
    device_name: "Trạm thời tiết 5G",
    quantity: 1,
    unit_price: 8500000,
    description: "DGA-Weather 5G - Giám sát lượng mưa, bức xạ UV, hướng gió và đốm nấm",
  },
  {
    device_type: "gateway_hub",
    device_name: "Gateway Hub",
    quantity: 2,
    unit_price: 7000000,
    description: "Edge AI LoRaWAN - Kết nối không dây LoRaWAN / 4G thu thập dữ liệu và xử lý tại biên",
  },
  {
    device_type: "smart_valve",
    device_name: "Van tưới thông minh",
    quantity: 2,
    unit_price: 3600000,
    description: "SmartValve - Điều khiển tưới bù áp tự động theo lịch khuyến nghị AI Agronomist",
  },
];

export default function RegisterFarmPage() {
  const navigate = useNavigate();

  // Step 1: General Info
  const [farmName, setFarmName] = useState("");
  const [areaHectare, setAreaHectare] = useState<number>(3.5);
  const [district, setDistrict] = useState("Krông Pắc, Đắk Lắk");
  const [treeCount, setTreeCount] = useState<number>(600);
  const [selectedVarieties, setSelectedVarieties] = useState<string[]>(["Ri6", "Monthong (Dona)"]);

  // Step 2 & 3: GIS Location & Polygon Boundary
  const [gpsLat, setGpsLat] = useState<number>(12.6851);
  const [gpsLng, setGpsLng] = useState<number>(108.0387);
  const [boundaryPoints, setBoundaryPoints] = useState<LatLngPoint[]>([]);
  const [gisAreaHa, setGisAreaHa] = useState<number>(3.48);
  const [gisPerimeterMeters, setGisPerimeterMeters] = useState<number>(815);

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
    if (areaHa > 0) {
      setGisAreaHa(areaHa);
      setAreaHectare(areaHa);
    }
    if (perimeterM > 0) {
      setGisPerimeterMeters(perimeterM);
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
        device_name: "Cảm biến đất & NPK",
        quantity: recommendedSoil,
        unit_price: 1200000,
        description: "DurianSense Pro - Đo độ ẩm, pH, nhiệt độ và dinh dưỡng NPK đất",
      },
      {
        device_type: "weather_station",
        device_name: "Trạm thời tiết 5G",
        quantity: recommendedWeather,
        unit_price: 8500000,
        description: "DGA-Weather 5G - Giám sát lượng mưa, bức xạ UV, hướng gió và đốm nấm",
      },
      {
        device_type: "gateway_hub",
        device_name: "Gateway Hub",
        quantity: recommendedGateway,
        unit_price: 7000000,
        description: "Edge AI LoRaWAN - Kết nối không dây LoRaWAN / 4G thu thập dữ liệu và xử lý tại biên",
      },
      {
        device_type: "smart_valve",
        device_name: "Van tưới thông minh",
        quantity: recommendedValve,
        unit_price: 3600000,
        description: "SmartValve - Điều khiển tưới bù áp tự động theo lịch khuyến nghị AI Agronomist",
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

  const totalDeviceCount = iotItems.reduce((sum, item) => sum + item.quantity, 0);
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
    <div className="max-w-7xl mx-auto p-6 lg:p-8 space-y-6 bg-[#F8FAFC] min-h-screen text-[#111827] font-['Plus_Jakarta_Sans',sans-serif] select-none">
      {/* ── TOP HERO BANNER & WIZARD STEPPER ── */}
      <div className="bg-white p-6 rounded-[20px] border border-[#E5E7EB] shadow-saas flex flex-col lg:flex-row lg:items-center justify-between gap-6">
        {/* Title & Description */}
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-[16px] bg-[#D1FAE5] text-[#10B981] flex items-center justify-center flex-shrink-0">
            <Sprout className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-xl sm:text-2xl font-bold text-[#111827] tracking-tight">
              Đăng ký trang trại mới
            </h1>
            <p className="text-xs text-[#6B7280] font-medium mt-0.5">
              Xác định vị trí, thông tin và thiết bị để quản lý trang trại một cách thông minh.
            </p>
          </div>
        </div>

        {/* Stepper Wizard Indicator */}
        <div className="flex items-center gap-3 sm:gap-6 overflow-x-auto pb-1 lg:pb-0">
          {/* Step 1 */}
          <div className="flex items-center gap-2 flex-shrink-0">
            <div className="w-8 h-8 rounded-full bg-[#10B981] text-white flex items-center justify-center text-xs font-bold shadow-xs">
              1
            </div>
            <div>
              <div className="text-xs font-bold text-[#111827] leading-tight">Thông tin</div>
              <div className="text-[10px] text-[#6B7280] font-medium">Trang trại</div>
            </div>
            <div className="w-8 h-[1.5px] bg-[#E5E7EB] hidden sm:block ml-2" />
          </div>

          {/* Step 2 */}
          <div className="flex items-center gap-2 flex-shrink-0 opacity-70">
            <div className="w-8 h-8 rounded-full bg-[#F8FAFC] border border-[#E5E7EB] text-[#6B7280] flex items-center justify-center text-xs font-bold">
              2
            </div>
            <div>
              <div className="text-xs font-bold text-[#111827] leading-tight">Bản đồ</div>
              <div className="text-[10px] text-[#6B7280] font-medium">GIS & Vị trí</div>
            </div>
            <div className="w-8 h-[1.5px] bg-[#E5E7EB] hidden sm:block ml-2" />
          </div>

          {/* Step 3 */}
          <div className="flex items-center gap-2 flex-shrink-0 opacity-70">
            <div className="w-8 h-8 rounded-full bg-[#F8FAFC] border border-[#E5E7EB] text-[#6B7280] flex items-center justify-center text-xs font-bold">
              3
            </div>
            <div>
              <div className="text-xs font-bold text-[#111827] leading-tight">Thiết bị IoT</div>
              <div className="text-[10px] text-[#6B7280] font-medium">Đề xuất thiết bị</div>
            </div>
            <div className="w-8 h-[1.5px] bg-[#E5E7EB] hidden sm:block ml-2" />
          </div>

          {/* Step 4 */}
          <div className="flex items-center gap-2 flex-shrink-0 opacity-70">
            <div className="w-8 h-8 rounded-full bg-[#F8FAFC] border border-[#E5E7EB] text-[#6B7280] flex items-center justify-center text-xs font-bold">
              4
            </div>
            <div>
              <div className="text-xs font-bold text-[#111827] leading-tight">Xác nhận</div>
              <div className="text-[10px] text-[#6B7280] font-medium">Hoàn tất</div>
            </div>
          </div>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* ── SECTION 1 & SECTION 2: FORM & GIS MAP (GRID 12 COLUMNS) ── */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
          {/* STEP 1: FORM AREA (5 COLUMNS) */}
          <div className="lg:col-span-5 bg-white p-6 rounded-[20px] border border-[#E5E7EB] shadow-saas space-y-5">
            <div className="flex items-center gap-2 pb-3 border-b border-[#E5E7EB]">
              <div className="w-7 h-7 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center flex-shrink-0">
                <Sprout className="w-4 h-4" />
              </div>
              <h2 className="text-base font-bold text-[#111827]">Thông tin trang trại</h2>
            </div>

            <div className="space-y-4">
              {/* Farm Name */}
              <div>
                <label className="block text-xs font-semibold text-[#111827] mb-1.5">
                  Tên trang trại / Vườn sầu riêng <span className="text-rose-500">*</span>
                </label>
                <input
                  type="text"
                  required
                  placeholder="VD: Trang trại Sầu Riêng Bến Tre - Vườn Số 1"
                  value={farmName}
                  onChange={(e) => setFarmName(e.target.value)}
                  className="w-full text-xs font-medium bg-[#F8FAFC] border border-[#E5E7EB] rounded-[14px] px-3.5 py-2.5 focus:outline-none focus:ring-2 focus:ring-[#10B981] focus:bg-white text-[#111827] placeholder-[#6B7280] transition-all"
                />
              </div>

              {/* District / Province */}
              <div>
                <label className="block text-xs font-semibold text-[#111827] mb-1.5">
                  Tỉnh thành / Huyện / Địa chỉ <span className="text-rose-500">*</span>
                </label>
                <input
                  type="text"
                  required
                  value={district}
                  onChange={(e) => setDistrict(e.target.value)}
                  className="w-full text-xs font-medium bg-[#F8FAFC] border border-[#E5E7EB] rounded-[14px] px-3.5 py-2.5 focus:outline-none focus:ring-2 focus:ring-[#10B981] focus:bg-white text-[#111827] transition-all"
                />
              </div>

              {/* Area & Tree Count Row */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-[#111827] mb-1.5">
                    Diện tích dự kiến (hecta) <span className="text-rose-500">*</span>
                  </label>
                  <div className="relative">
                    <input
                      type="number"
                      step="0.01"
                      min="0.01"
                      required
                      value={areaHectare}
                      onChange={(e) => setAreaHectare(Number(e.target.value))}
                      className="w-full text-xs font-bold bg-[#F8FAFC] border border-[#E5E7EB] rounded-[14px] pl-3.5 pr-8 py-2.5 focus:outline-none focus:ring-2 focus:ring-[#10B981] focus:bg-white text-[#111827] transition-all"
                    />
                    <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-medium text-[#6B7280]">ha</span>
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-[#111827] mb-1.5">
                    Tổng số cây sầu riêng <span className="text-rose-500">*</span>
                  </label>
                  <div className="relative">
                    <input
                      type="number"
                      min="1"
                      required
                      value={treeCount}
                      onChange={(e) => setTreeCount(Number(e.target.value))}
                      className="w-full text-xs font-bold bg-[#F8FAFC] border border-[#E5E7EB] rounded-[14px] pl-3.5 pr-10 py-2.5 focus:outline-none focus:ring-2 focus:ring-[#10B981] focus:bg-white text-[#111827] transition-all"
                    />
                    <span className="absolute right-3 top-1/2 -translate-y-1/2 text-xs font-medium text-[#6B7280]">cây</span>
                  </div>
                </div>
              </div>

              {/* Durian Variety Selector Chips */}
              <div>
                <label className="block text-xs font-semibold text-[#111827] mb-2">
                  Giống sầu riêng canh tác trong vườn <span className="text-rose-500">*</span>
                </label>
                <div className="flex flex-wrap gap-2">
                  {["Ri6", "Monthong (Dona)", "Musang King", "Black Thorn (Gai Đen)"].map((v) => {
                    const active = selectedVarieties.includes(v);
                    return (
                      <button
                        key={v}
                        type="button"
                        onClick={() => handleToggleVariety(v)}
                        className={`px-3 py-1.5 rounded-full text-xs font-semibold transition-all border cursor-pointer ${
                          active
                            ? "bg-[#10B981] text-white border-[#10B981] shadow-xs"
                            : "bg-[#F8FAFC] text-[#6B7280] border-[#E5E7EB] hover:bg-[#D1FAE5]/40 hover:text-[#111827]"
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
          </div>

          {/* STEP 2 & 3: MAP AREA (7 COLUMNS) */}
          <div className="lg:col-span-7 bg-white p-6 rounded-[20px] border border-[#E5E7EB] shadow-saas space-y-4">
            <div className="flex items-center justify-between pb-3 border-b border-[#E5E7EB]">
              <div className="flex items-center gap-2">
                <div className="w-7 h-7 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center flex-shrink-0">
                  <Map className="w-4 h-4" />
                </div>
                <h2 className="text-base font-bold text-[#111827]">Xác định vị trí trang trại trên bản đồ</h2>
              </div>
            </div>

            {/* FarmGISMapPicker Component */}
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
        </div>

        {/* ── STEP 4: IOT RECOMMENDATION SECTION ── */}
        <div className="bg-white p-6 rounded-[20px] border border-[#E5E7EB] shadow-saas space-y-5">
          <div className="flex flex-wrap items-center justify-between gap-3 pb-3 border-b border-[#E5E7EB]">
            <div className="flex items-center gap-2">
              <div className="w-7 h-7 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center flex-shrink-0">
                <Cpu className="w-4 h-4" />
              </div>
              <div>
                <h2 className="text-base font-bold text-[#111827]">Thiết bị IoT đề xuất</h2>
                <p className="text-xs text-[#6B7280] font-medium">
                  Hệ thống gợi ý thiết bị phù hợp với quy mô và nhu cầu của trang trại
                </p>
              </div>
            </div>

            <button
              type="button"
              onClick={handleCalculateIoT}
              className="px-3.5 py-1.5 bg-[#D1FAE5] hover:bg-[#10B981] text-[#10B981] hover:text-white font-semibold text-xs rounded-full border border-emerald-200 transition-all cursor-pointer flex items-center gap-1.5"
            >
              <Calculator className="w-4 h-4" />
              <span>{calculated ? "Tính toán lại AI" : "Tự động tính toán IoT"}</span>
            </button>
          </div>

          {/* 4 IoT Device Cards Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {iotItems.map((item, idx) => (
              <div
                key={item.device_type}
                className="p-4 bg-[#F8FAFC] rounded-[16px] border border-[#E5E7EB] hover:border-[#10B981] transition-all flex flex-col justify-between space-y-3 hover:-translate-y-0.5"
              >
                <div className="space-y-2">
                  <div className="w-8 h-8 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center">
                    {item.device_type === "soil_sensor" && <Sprout className="w-4 h-4" />}
                    {item.device_type === "weather_station" && <CloudSun className="w-4 h-4" />}
                    {item.device_type === "gateway_hub" && <Wifi className="w-4 h-4" />}
                    {item.device_type === "smart_valve" && <Activity className="w-4 h-4" />}
                  </div>

                  <div>
                    <h4 className="text-xs font-bold text-[#111827] leading-tight">{item.device_name}</h4>
                    <p className="text-[10px] text-[#6B7280] font-medium leading-relaxed mt-1">{item.description}</p>
                  </div>
                </div>

                <div className="space-y-2 pt-2 border-t border-[#E5E7EB]">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-bold text-[#10B981]">{item.unit_price.toLocaleString("vi-VN")}đ <span className="text-[10px] text-[#6B7280] font-normal">/ cái</span></span>
                  </div>

                  <div className="flex items-center justify-between bg-white rounded-[10px] border border-[#E5E7EB] p-1">
                    <button
                      type="button"
                      onClick={() => handleUpdateQuantity(idx, -1)}
                      className="w-6 h-6 rounded-[6px] flex items-center justify-center bg-[#F8FAFC] hover:bg-gray-200 text-[#111827] cursor-pointer transition-colors"
                    >
                      <Minus className="w-3.5 h-3.5" />
                    </button>
                    <span className="text-xs font-bold text-[#111827] px-2">{item.quantity}</span>
                    <button
                      type="button"
                      onClick={() => handleUpdateQuantity(idx, 1)}
                      className="w-6 h-6 rounded-[6px] flex items-center justify-center bg-[#F8FAFC] hover:bg-gray-200 text-[#111827] cursor-pointer transition-colors"
                    >
                      <Plus className="w-3.5 h-3.5" />
                    </button>
                  </div>

                  <div className="text-right text-xs font-bold text-[#10B981]">
                    {(item.unit_price * item.quantity).toLocaleString("vi-VN")}đ
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* ── SECTION 5: TOTAL COST & BOTTOM ACTION AREA ── */}
        <div className="bg-white p-6 rounded-[20px] border border-[#E5E7EB] shadow-saas flex flex-col md:flex-row items-center justify-between gap-6">
          {/* Total Cost Display */}
          <div>
            <span className="text-xs font-medium text-[#6B7280] block">Tổng chi phí thiết bị IoT ước tính</span>
            <div className="flex items-baseline gap-3 mt-0.5">
              <span className="text-2xl font-bold text-[#10B981]">{totalAmount.toLocaleString("vi-VN")} VNĐ</span>
              <span className="text-xs font-medium text-[#6B7280] bg-[#F8FAFC] px-2.5 py-0.5 rounded-full border border-[#E5E7EB]">
                Bao gồm {totalDeviceCount} thiết bị
              </span>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center gap-3 w-full md:w-auto">
            <button
              type="button"
              onClick={() => navigate(-1)}
              className="flex-1 md:flex-none px-4 py-2.5 rounded-[14px] bg-[#F8FAFC] hover:bg-gray-100 text-[#111827] font-semibold text-xs border border-[#E5E7EB] transition-all cursor-pointer flex items-center justify-center gap-1.5"
            >
              <ArrowLeft className="w-4 h-4" />
              <span>Quay lại</span>
            </button>

            <button
              type="button"
              onClick={() => alert("Đã lưu nháp thông tin trang trại thành công!")}
              className="flex-1 md:flex-none px-4 py-2.5 rounded-[14px] bg-[#F8FAFC] hover:bg-gray-100 text-[#111827] font-semibold text-xs border border-[#E5E7EB] transition-all cursor-pointer flex items-center justify-center gap-1.5"
            >
              <Save className="w-4 h-4 text-[#6B7280]" />
              <span>Lưu nháp</span>
            </button>

            <button
              type="submit"
              disabled={submitting}
              className="flex-1 md:flex-none px-6 py-2.5 rounded-[14px] bg-[#10B981] hover:bg-[#059669] text-white font-semibold text-xs transition-all cursor-pointer shadow-sm flex items-center justify-center gap-2 disabled:opacity-50"
            >
              <span>{submitting ? "Đang xử lý..." : "Tiếp tục: Xác nhận & Hoàn tất"}</span>
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </form>
    </div>
  );
}
