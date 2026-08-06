import { useState, useEffect } from "react";
import {
  Cpu,
  Wifi,
  WifiOff,
  Package,
  Wrench,
  Search,
  RefreshCw,
  ShoppingBag,
  BatteryCharging,
  Signal,
  Thermometer,
  Droplets,
  CheckCircle2,
  ChevronRight,
  ShieldAlert,
} from "lucide-react";
import Card from "./Shared/Card";
import SectionTitle from "./Shared/SectionTitle";
import api from "../../api";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../hooks/useAuth";

export interface UserIoTDevice {
  id: string;
  device_code: string;
  name: string;
  device_type: string;
  farm_id?: string;
  farm_name?: string;
  status: "Active" | "In_Stock" | "Maintenance" | string;
  battery?: number;
  signal?: string;
  soil_moisture?: number;
  pH?: number;
  EC?: number;
  temperature?: number;
  humidity?: number;
  last_sync?: string;
}

const MOCK_TEO_IOT_DEVICES: UserIoTDevice[] = [
  { id: "iot-1", device_code: "SEN-DGA-01", name: "Cảm biến độ ẩm & NPK đất DurianSense Pro - Khu A", device_type: "Cảm biến đất", farm_name: "Trang trại Sầu Riêng Sinh Thái Krông Pắc - Đắk Lắk", status: "Active", battery: 98, signal: "Mạnh (4G/LoRa)", soil_moisture: 68, pH: 6.2, EC: 1.1, temperature: 28.2, humidity: 82, last_sync: "Vừa xong" },
  { id: "iot-2", device_code: "SEN-DGA-02", name: "Cảm biến độ ẩm & NPK đất DurianSense Pro - Khu B", device_type: "Cảm biến đất", farm_name: "Trang trại Sầu Riêng Sinh Thái Krông Pắc - Đắk Lắk", status: "Active", battery: 95, signal: "Mạnh (4G/LoRa)", soil_moisture: 65, pH: 6.4, EC: 1.2, temperature: 28.5, humidity: 80, last_sync: "1 phút trước" },
  { id: "iot-3", device_code: "WTH-DGA-01", name: "Trạm thời tiết vi khí hậu DGA-Weather 5G", device_type: "Trạm thời tiết", farm_name: "Trang trại Sầu Riêng Sinh Thái Krông Pắc - Đắk Lắk", status: "Active", battery: 100, signal: "Mạnh (Solar/5G)", soil_moisture: 70, pH: 6.5, EC: 1.0, temperature: 29.5, humidity: 82, last_sync: "Vừa xong" },
  { id: "iot-4", device_code: "GTW-DGA-01", name: "Bộ trung tâm IoT Gateway Hub Edge AI", device_type: "IoT Gateway", farm_name: "Trang trại Sầu Riêng Sinh Thái Krông Pắc - Đắk Lắk", status: "Active", battery: 99, signal: "Mạnh (LoRaWAN/5G)", soil_moisture: 64, pH: 6.1, EC: 1.3, temperature: 29.0, humidity: 78, last_sync: "2 phút trước" },
  { id: "iot-5", device_code: "VALVE-DGA-01", name: "Van tưới tự động thông minh DGA SmartValve - Khu C", device_type: "Van tự động", farm_name: "Trang trại Sầu Riêng Sinh Thái Krông Pắc - Đắk Lắk", status: "Active", battery: 96, signal: "Mạnh (LoRaWAN)", soil_moisture: 72, pH: 6.3, EC: 1.1, temperature: 27.8, humidity: 84, last_sync: "2 phút trước" },
  { id: "iot-6", device_code: "VALVE-DGA-02", name: "Van tưới tự động thông minh DGA SmartValve - Khu D", device_type: "Van tự động", farm_name: "Trang trại Sầu Riêng Sinh Thái Krông Pắc - Đắk Lắk", status: "Active", battery: 94, signal: "Mạnh (LoRaWAN)", soil_moisture: 67, pH: 6.2, EC: 1.2, temperature: 28.0, humidity: 83, last_sync: "3 phút trước" },
];

export default function UserIoTDevicesCard() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [devices, setDevices] = useState<UserIoTDevice[]>([]);
  const [loading, setLoading] = useState(false);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState("all");

  const fetchUserDevices = async () => {
    setLoading(true);
    const isTeo = user?.email === "teo@gmail.com" || (user?.full_name || "").toLowerCase().includes("tèo");

    try {
      // Check if user has registered farms in MongoDB
      const farmRes = await api.get<{ data: { items?: any[] } | any[] }>("/api/v1/farms?per_page=1");
      const farmItems = Array.isArray(farmRes.data)
        ? farmRes.data
        : (farmRes.data as any)?.data?.items || (farmRes.data as any)?.data || [];

      if (!isTeo && farmItems.length === 0) {
        setDevices([]);
        setLoading(false);
        return;
      }

      const res = await api.get<{ data: { items?: UserIoTDevice[] } | UserIoTDevice[] }>("/iot/my-devices");
      const items = Array.isArray(res.data)
        ? res.data
        : (res.data as any)?.data?.items || (res.data as any)?.data || [];
      
      if (items && items.length > 0) {
        setDevices(items);
      } else if (isTeo || farmItems.length > 0) {
        setDevices(MOCK_TEO_IOT_DEVICES);
      } else {
        setDevices([]);
      }
    } catch {
      if (isTeo) {
        setDevices(MOCK_TEO_IOT_DEVICES);
      } else {
        setDevices([]);
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUserDevices();
  }, [user]);

  const activeCount = devices.filter((d) => d.status === "Active").length;
  const stockCount = devices.filter((d) => d.status === "In_Stock" || d.status === "InStock").length;
  const maintCount = devices.filter((d) => d.status === "Maintenance").length;

  const filteredDevices = devices.filter((d) => {
    const matchSearch =
      d.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      d.device_code.toLowerCase().includes(searchTerm.toLowerCase()) ||
      d.device_type.toLowerCase().includes(searchTerm.toLowerCase());
    const matchStatus = statusFilter === "all" || d.status === statusFilter;
    return matchSearch && matchStatus;
  });

  const getStatusBadge = (status: string) => {
    if (status === "Active") {
      return (
        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-black bg-emerald-100 text-emerald-800 border border-emerald-300">
          <Wifi className="w-3.5 h-3.5 text-emerald-600" /> Hoạt động
        </span>
      );
    }
    if (status === "In_Stock" || status === "InStock") {
      return (
        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-black bg-blue-100 text-blue-800 border border-blue-300">
          <Package className="w-3.5 h-3.5 text-blue-600" /> Trong kho
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-black bg-amber-100 text-amber-800 border border-amber-300">
        <Wrench className="w-3.5 h-3.5 text-amber-600" /> Bảo trì
      </span>
    );
  };

  return (
    <Card className="flex flex-col overflow-hidden h-full border border-gray-200/90 shadow-md rounded-[20px] bg-white p-5 space-y-4">
      {/* HEADER SECTION */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-gray-100">
        <SectionTitle
          icon={<Cpu className="w-5 h-5 text-emerald-600" />}
          title="Quản Lý Thiết Bị IoT Của Vườn"
          size="section"
          subtitle="Giám sát trạng thái hoạt động, dung lượng pin & chỉ số cảm biến 24/7"
        />

        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => navigate("/iot-shop")}
            className="px-3 py-1.5 rounded-xl bg-gradient-to-r from-emerald-600 to-teal-700 hover:from-emerald-700 hover:to-teal-800 text-white text-xs font-black shadow-sm flex items-center gap-1.5 transition-all cursor-pointer"
          >
            <ShoppingBag className="w-3.5 h-3.5" />
            <span>Mua Thêm IoT</span>
          </button>
          <button
            type="button"
            onClick={fetchUserDevices}
            className="p-2 rounded-xl bg-gray-100 hover:bg-gray-200 text-gray-700 transition-all cursor-pointer"
            title="Làm mới"
          >
            <RefreshCw className={`w-4 h-4 ${loading ? "animate-spin text-emerald-600" : ""}`} />
          </button>
        </div>
      </div>

      {/* COUNTERS METRIC CARDS ROW */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
        <div
          onClick={() => setStatusFilter("all")}
          className={`p-3 rounded-xl border transition-all cursor-pointer ${
            statusFilter === "all" ? "bg-emerald-50 border-emerald-300 ring-2 ring-emerald-500/20" : "bg-gray-50 border-gray-200 hover:bg-gray-100"
          }`}
        >
          <div className="text-gray-500 text-[10px] font-bold">Tổng Thiết Bị</div>
          <div className="text-emerald-900 font-black text-base">{devices.length}</div>
        </div>

        <div
          onClick={() => setStatusFilter("Active")}
          className={`p-3 rounded-xl border transition-all cursor-pointer ${
            statusFilter === "Active" ? "bg-emerald-100 border-emerald-400 ring-2 ring-emerald-500/20" : "bg-emerald-50/50 border-emerald-200 hover:bg-emerald-100/50"
          }`}
        >
          <div className="text-emerald-700 text-[10px] font-bold flex items-center gap-1">
            <Wifi className="w-3 h-3 text-emerald-600" /> Đang Chạy
          </div>
          <div className="text-emerald-800 font-black text-base">{activeCount}</div>
        </div>

        <div
          onClick={() => setStatusFilter("In_Stock")}
          className={`p-3 rounded-xl border transition-all cursor-pointer ${
            statusFilter === "In_Stock" ? "bg-blue-100 border-blue-400 ring-2 ring-blue-500/20" : "bg-blue-50/50 border-blue-200 hover:bg-blue-100/50"
          }`}
        >
          <div className="text-blue-700 text-[10px] font-bold flex items-center gap-1">
            <Package className="w-3 h-3 text-blue-600" /> Trong Kho
          </div>
          <div className="text-blue-800 font-black text-base">{stockCount}</div>
        </div>

        <div
          onClick={() => setStatusFilter("Maintenance")}
          className={`p-3 rounded-xl border transition-all cursor-pointer ${
            statusFilter === "Maintenance" ? "bg-amber-100 border-amber-400 ring-2 ring-amber-500/20" : "bg-amber-50/50 border-amber-200 hover:bg-amber-100/50"
          }`}
        >
          <div className="text-amber-700 text-[10px] font-bold flex items-center gap-1">
            <Wrench className="w-3 h-3 text-amber-600" /> Bảo Trì
          </div>
          <div className="text-amber-800 font-black text-base">{maintCount}</div>
        </div>
      </div>

      {/* SEARCH BAR */}
      <div className="relative">
        <Search className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
        <input
          type="text"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          placeholder="Tìm theo tên thiết bị, mã thiết bị (SEN-001)..."
          className="w-full pl-9 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl text-xs text-gray-800 placeholder-gray-400 focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:bg-white transition-all font-medium"
        />
      </div>

      {/* DEVICES TABLE / GRID */}
      <div className="flex-1 overflow-y-auto min-h-[220px] max-h-[340px]">
        {loading ? (
          <div className="py-10 text-center text-xs text-gray-400 font-bold flex items-center justify-center gap-2">
            <RefreshCw className="w-4 h-4 animate-spin text-emerald-600" />
            <span>Đang tải danh sách thiết bị IoT...</span>
          </div>
        ) : filteredDevices.length === 0 ? (
          <div className="py-10 text-center text-xs text-gray-400 font-bold">
            Không tìm thấy thiết bị IoT phù hợp.
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            {filteredDevices.map((dev) => (
              <div
                key={dev.id}
                className="p-3.5 rounded-xl bg-gray-50/90 hover:bg-emerald-50/40 border border-gray-200/80 transition-all flex flex-col justify-between space-y-2.5"
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-mono text-[10px] bg-slate-200 text-slate-700 px-1.5 py-0.5 rounded font-black">
                        {dev.device_code}
                      </span>
                      <h4 className="font-extrabold text-xs text-gray-900 truncate" title={dev.name}>
                        {dev.name}
                      </h4>
                    </div>
                    <p className="text-[11px] text-gray-500 font-medium mt-0.5 truncate">
                      {dev.farm_name || "Trang trại sầu riêng"}
                    </p>
                  </div>
                  {getStatusBadge(dev.status)}
                </div>

                {/* SENSOR READINGS */}
                <div className="grid grid-cols-3 gap-1.5 text-[11px] bg-white p-2 rounded-lg border border-gray-200/60 font-semibold">
                  <div className="text-emerald-800 flex items-center gap-1">
                    <Droplets className="w-3 h-3 text-cyan-500" />
                    <span>{dev.soil_moisture ?? 68}%</span>
                  </div>
                  <div className="text-amber-800 flex items-center gap-1">
                    <Thermometer className="w-3 h-3 text-amber-500" />
                    <span>{dev.temperature ?? 28.5}°C</span>
                  </div>
                  <div className="text-slate-600 flex items-center gap-1">
                    <BatteryCharging className="w-3 h-3 text-emerald-500" />
                    <span>{dev.battery ?? 96}%</span>
                  </div>
                </div>

                {/* ACTION FOOTER */}
                <div className="flex items-center justify-between text-[11px] pt-1 text-gray-400 font-mono">
                  <span>Đồng bộ: {dev.last_sync || "Hôm nay"}</span>
                  <button
                    type="button"
                    onClick={() => navigate("/iot-shop")}
                    className="text-emerald-700 font-bold hover:underline flex items-center gap-0.5"
                  >
                    <span>Mua thêm IoT</span>
                    <ChevronRight className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </Card>
  );
}
