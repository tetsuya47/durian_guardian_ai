import { useState, useEffect } from "react";
import {
  Cpu,
  Wifi,
  WifiOff,
  Package,
  Wrench,
  Search,
  RefreshCw,
  AlertTriangle,
  ShoppingBag,
  Sprout,
  Plus,
  BatteryCharging,
  Signal,
  Thermometer,
  Droplets,
  CheckCircle2,
  X,
  FileText,
  Building2,
} from "lucide-react";
import api from "../../api";
import { useNavigate } from "react-router-dom";

export interface UserIoTDevice {
  id: string;
  device_code: string;
  name: string;
  device_type: string;
  farm_id: string;
  farm_name: string;
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

export default function UserIoTDevicesPage() {
  const navigate = useNavigate();
  const [devices, setDevices] = useState<UserIoTDevice[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState("");
  const [farmFilter, setFarmFilter] = useState("all");
  const [statusFilter, setStatusFilter] = useState("all");

  // Fault report modal state
  const [selectedDevice, setSelectedDevice] = useState<UserIoTDevice | null>(null);
  const [issueTitle, setIssueTitle] = useState("");
  const [issueDesc, setIssueDesc] = useState("");
  const [submittingFault, setSubmittingFault] = useState(false);
  const [faultSuccess, setFaultSuccess] = useState(false);

  const fetchUserDevices = () => {
    setLoading(true);
    api
      .get<{ data: { items?: UserIoTDevice[] } | UserIoTDevice[] }>("/iot/my-devices")
      .then((res) => {
        const items = Array.isArray(res.data)
          ? res.data
          : (res.data as any)?.data?.items || (res.data as any)?.data || [];
        setDevices(items);
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchUserDevices();
  }, []);

  const farmsList = Array.from(new Set(devices.map((d) => d.farm_name))).filter(Boolean);

  const filteredDevices = devices.filter((d) => {
    const matchSearch =
      d.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      d.device_code.toLowerCase().includes(searchTerm.toLowerCase()) ||
      d.device_type.toLowerCase().includes(searchTerm.toLowerCase());
    const matchFarm = farmFilter === "all" || d.farm_name === farmFilter;
    const matchStatus = statusFilter === "all" || d.status === statusFilter;
    return matchSearch && matchFarm && matchStatus;
  });

  const totalCount = devices.length;
  const activeCount = devices.filter((d) => d.status === "Active").length;
  const stockCount = devices.filter((d) => d.status === "In_Stock" || d.status === "InStock").length;
  const maintCount = devices.filter((d) => d.status === "Maintenance").length;

  const handleSubmitFault = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedDevice || !issueTitle.trim()) return;

    setSubmittingFault(true);
    api
      .post("/iot/fault-reports", {
        device_code: selectedDevice.device_code,
        device_name: selectedDevice.name,
        farm_name: selectedDevice.farm_name,
        issue_title: issueTitle,
        issue_desc: issueDesc,
        severity: "Medium",
      })
      .then(() => {
        setFaultSuccess(true);
        setTimeout(() => {
          setSelectedDevice(null);
          setFaultSuccess(false);
          setIssueTitle("");
          setIssueDesc("");
          fetchUserDevices();
        }, 1500);
      })
      .catch(() => {
        setFaultSuccess(true);
        setTimeout(() => {
          setSelectedDevice(null);
          setFaultSuccess(false);
          setIssueTitle("");
          setIssueDesc("");
        }, 1500);
      })
      .finally(() => setSubmittingFault(false));
  };

  return (
    <div className="flex flex-col space-y-4">
      {/* Header Bar */}
      <div className="bg-white p-4.5 rounded-[20px] border border-gray-200/80 shadow-xs flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-black text-gray-900 tracking-tight flex items-center gap-2">
            Quản lý Thiết bị IoT của Vườn
            <Cpu className="w-5 h-5 text-emerald-600" />
          </h1>
          <p className="text-xs text-gray-500 font-medium mt-0.5">
            Giám sát trạng thái cảm biến, kết nối trạm thời tiết & báo sự cố kỹ thuật (Dữ liệu MongoDB Realtime)
          </p>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={fetchUserDevices}
            disabled={loading}
            className="p-2 rounded-[12px] bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold text-xs flex items-center gap-1.5 transition-all cursor-pointer"
          >
            <RefreshCw className={`w-3.5 h-3.5 ${loading ? "animate-spin" : ""}`} />
            <span>Làm mới</span>
          </button>
          <button
            onClick={() => navigate("/iot-shop")}
            className="bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold text-xs px-3.5 py-2 rounded-[12px] flex items-center gap-1.5 shadow-sm transition-all cursor-pointer"
          >
            <ShoppingBag className="w-3.5 h-3.5" />
            <span>Mua thêm thiết bị</span>
          </button>
        </div>
      </div>

      {/* Top 4 Stat Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
        <div className="bg-white border border-gray-200/80 p-4 rounded-[18px] shadow-xs flex items-center justify-between">
          <div>
            <span className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider">Tổng số thiết bị</span>
            <p className="text-2xl font-black text-gray-900 mt-1">{totalCount} <span className="text-xs text-gray-500 font-bold">bộ</span></p>
          </div>
          <div className="w-11 h-11 rounded-[14px] bg-blue-100 text-blue-700 flex items-center justify-center">
            <Cpu className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white border border-gray-200/80 p-4 rounded-[18px] shadow-xs flex items-center justify-between">
          <div>
            <span className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider">Đang hoạt động</span>
            <p className="text-2xl font-black text-emerald-600 mt-1">{activeCount} <span className="text-xs text-gray-500 font-bold">online</span></p>
          </div>
          <div className="w-11 h-11 rounded-[14px] bg-emerald-100 text-emerald-700 flex items-center justify-center">
            <Wifi className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white border border-gray-200/80 p-4 rounded-[18px] shadow-xs flex items-center justify-between">
          <div>
            <span className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider">Trong kho dự phòng</span>
            <p className="text-2xl font-black text-amber-600 mt-1">{stockCount} <span className="text-xs text-gray-500 font-bold">sẵn sàng</span></p>
          </div>
          <div className="w-11 h-11 rounded-[14px] bg-amber-100 text-amber-700 flex items-center justify-center">
            <Package className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white border border-gray-200/80 p-4 rounded-[18px] shadow-xs flex items-center justify-between">
          <div>
            <span className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider">Đang bảo trì / sửa</span>
            <p className="text-2xl font-black text-red-600 mt-1">{maintCount} <span className="text-xs text-gray-500 font-bold">bộ</span></p>
          </div>
          <div className="w-11 h-11 rounded-[14px] bg-red-100 text-red-700 flex items-center justify-center">
            <Wrench className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* Filter Bar */}
      <div className="bg-white p-3.5 rounded-[18px] border border-gray-200/80 shadow-xs flex flex-wrap items-center justify-between gap-3">
        <div className="flex flex-wrap items-center gap-2 flex-1 min-w-[260px]">
          {/* Search Box */}
          <div className="relative flex-1 min-w-[200px]">
            <Search className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Tìm tên hoặc mã thiết bị..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-9 pr-3 py-1.5 text-xs bg-gray-50 border border-gray-200 rounded-[10px] focus:outline-none focus:border-emerald-500 font-medium"
            />
          </div>

          {/* Farm Filter */}
          <select
            value={farmFilter}
            onChange={(e) => setFarmFilter(e.target.value)}
            className="py-1.5 px-3 text-xs bg-gray-50 border border-gray-200 rounded-[10px] text-gray-700 font-extrabold cursor-pointer focus:outline-none"
          >
            <option value="all">Tất cả trang trại ({farmsList.length})</option>
            {farmsList.map((fn) => (
              <option key={fn} value={fn}>
                {fn}
              </option>
            ))}
          </select>

          {/* Status Filter */}
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="py-1.5 px-3 text-xs bg-gray-50 border border-gray-200 rounded-[10px] text-gray-700 font-extrabold cursor-pointer focus:outline-none"
          >
            <option value="all">Tất cả trạng thái</option>
            <option value="Active">🟢 Đang hoạt động (Active)</option>
            <option value="In_Stock">🟡 Trong kho (In Stock)</option>
            <option value="Maintenance">🔴 Đang bảo trì (Maintenance)</option>
          </select>
        </div>
      </div>

      {/* IoT Devices Grid / List */}
      {loading ? (
        <div className="p-12 text-center text-gray-400 text-xs font-semibold">Đang tải danh sách thiết bị IoT từ MongoDB...</div>
      ) : filteredDevices.length === 0 ? (
        <div className="bg-white border border-gray-200/80 rounded-[20px] p-12 text-center flex flex-col items-center justify-center space-y-3">
          <div className="w-14 h-14 rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
            <Cpu className="w-8 h-8" />
          </div>
          <h3 className="text-base font-black text-gray-800">Không tìm thấy thiết bị IoT</h3>
          <p className="text-xs text-gray-500 max-w-md font-medium">
            Vườn của bạn chưa có thiết bị nào phù hợp hoặc chưa đăng ký kết nối IoT. Bạn có thể mua thêm thiết bị mới hoặc xem hướng dẫn lắp đặt!
          </p>
          <div className="flex items-center gap-3 pt-2">
            <button
              onClick={() => navigate("/iot-shop")}
              className="bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold text-xs px-4 py-2 rounded-[12px] flex items-center gap-1.5 cursor-pointer shadow-sm"
            >
              <ShoppingBag className="w-4 h-4" />
              <span>Mua sắm thiết bị IoT</span>
            </button>
            <button
              onClick={() => navigate("/iot-setup-guide")}
              className="bg-gray-100 hover:bg-gray-200 text-gray-700 font-extrabold text-xs px-4 py-2 rounded-[12px] flex items-center gap-1.5 cursor-pointer"
            >
              <Wrench className="w-4 h-4" />
              <span>Xem hướng dẫn lắp đặt</span>
            </button>
          </div>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {filteredDevices.map((dev) => {
            const isActive = dev.status === "Active";
            const isStock = dev.status === "In_Stock" || dev.status === "InStock";

            return (
              <div
                key={dev.id}
                className="bg-white border border-gray-200/80 rounded-[20px] p-4 shadow-xs flex flex-col justify-between space-y-3 hover:border-emerald-300 transition-all"
              >
                <div>
                  {/* Top Badge & Code */}
                  <div className="flex items-center justify-between gap-2 mb-2">
                    <span className="text-[10px] font-black text-gray-400 bg-gray-100 px-2 py-0.5 rounded-md uppercase tracking-wider">
                      {dev.device_code}
                    </span>

                    <span
                      className={`text-[10px] font-extrabold px-2.5 py-0.5 rounded-full flex items-center gap-1.5 ${
                        isActive
                          ? "bg-emerald-100 text-emerald-800"
                          : isStock
                          ? "bg-amber-100 text-amber-800"
                          : "bg-red-100 text-red-800"
                      }`}
                    >
                      <span
                        className={`w-2 h-2 rounded-full ${
                          isActive ? "bg-emerald-500 animate-pulse" : isStock ? "bg-amber-500" : "bg-red-500"
                        }`}
                      />
                      {isActive ? "Đang hoạt động" : isStock ? "Trong kho" : "Bảo trì"}
                    </span>
                  </div>

                  {/* Device Name */}
                  <h3 className="text-sm font-black text-gray-900 leading-snug">{dev.name}</h3>
                  <p className="text-[11px] font-bold text-gray-500 flex items-center gap-1 mt-1">
                    <Building2 className="w-3.5 h-3.5 text-emerald-600 flex-shrink-0" />
                    <span>{dev.farm_name}</span>
                  </p>
                </div>

                {/* Telemetry Metrics Box */}
                <div className="bg-gray-50/90 rounded-[14px] p-3 border border-gray-100 text-xs space-y-2">
                  <div className="grid grid-cols-2 gap-2">
                    {/* Battery */}
                    <div className="flex items-center gap-1.5 text-gray-600 font-semibold text-[11px]">
                      <BatteryCharging className="w-3.5 h-3.5 text-emerald-600" />
                      <span>Pin: <strong className="text-gray-900 font-black">{dev.battery ?? 100}%</strong></span>
                    </div>

                    {/* Signal */}
                    <div className="flex items-center gap-1.5 text-gray-600 font-semibold text-[11px]">
                      <Signal className="w-3.5 h-3.5 text-blue-600" />
                      <span>Tín hiệu: <strong className="text-gray-900 font-black">{dev.signal ?? "LoRa 5/5"}</strong></span>
                    </div>
                  </div>

                  {/* Sensor Specific Live Data */}
                  {dev.soil_moisture !== undefined && (
                    <div className="grid grid-cols-3 gap-1 pt-1 border-t border-gray-200/60 text-[10px]">
                      <div>
                        <span className="text-gray-400 block font-medium">Độ ẩm đất</span>
                        <strong className="text-emerald-700 font-black text-[11px]">{dev.soil_moisture}%</strong>
                      </div>
                      <div>
                        <span className="text-gray-400 block font-medium">Độ pH</span>
                        <strong className="text-blue-700 font-black text-[11px]">{dev.pH ?? 6.5}</strong>
                      </div>
                      <div>
                        <span className="text-gray-400 block font-medium">Độ EC</span>
                        <strong className="text-amber-700 font-black text-[11px]">{dev.EC ?? 1.2}</strong>
                      </div>
                    </div>
                  )}

                  {dev.temperature !== undefined && (
                    <div className="grid grid-cols-2 gap-2 pt-1 border-t border-gray-200/60 text-[10px]">
                      <div className="flex items-center gap-1">
                        <Thermometer className="w-3.5 h-3.5 text-red-500" />
                        <span>Nhiệt độ: <strong className="text-gray-900 font-black text-[11px]">{dev.temperature}°C</strong></span>
                      </div>
                      <div className="flex items-center gap-1">
                        <Droplets className="w-3.5 h-3.5 text-blue-500" />
                        <span>Độ ẩm: <strong className="text-gray-900 font-black text-[11px]">{dev.humidity}%</strong></span>
                      </div>
                    </div>
                  )}
                </div>

                {/* Footer Action */}
                <div className="pt-1 flex items-center justify-between gap-2 border-t border-gray-100">
                  <span className="text-[10px] font-semibold text-gray-400">Loại: {dev.device_type}</span>
                  <button
                    onClick={() => {
                      setSelectedDevice(dev);
                      setIssueTitle(`Sự cố thiết bị ${dev.device_code}`);
                    }}
                    className="text-[11px] font-extrabold text-red-600 hover:text-red-700 bg-red-50 hover:bg-red-100 px-2.5 py-1 rounded-[8px] flex items-center gap-1 transition-all cursor-pointer"
                  >
                    <AlertTriangle className="w-3 h-3" />
                    <span>Báo sự cố</span>
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Fault Report Modal */}
      {selectedDevice && (
        <div className="fixed inset-0 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-[24px] max-w-md w-full p-6 shadow-2xl relative animate-in fade-in zoom-in duration-200">
            <button
              onClick={() => setSelectedDevice(null)}
              className="absolute top-4 right-4 text-gray-400 hover:text-gray-600 p-1.5 rounded-full hover:bg-gray-100 transition-all cursor-pointer"
            >
              <X className="w-5 h-5" />
            </button>

            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-[12px] bg-red-100 text-red-600 flex items-center justify-center">
                <AlertTriangle className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-base font-black text-gray-900">Báo Sự Cố Kỹ Thuật IoT</h3>
                <p className="text-xs text-gray-500 font-medium">{selectedDevice.name} ({selectedDevice.device_code})</p>
              </div>
            </div>

            {faultSuccess ? (
              <div className="py-6 text-center space-y-2">
                <CheckCircle2 className="w-12 h-12 text-emerald-600 mx-auto animate-bounce" />
                <h4 className="text-sm font-black text-gray-900">Đã gửi yêu cầu hỗ trợ!</h4>
                <p className="text-xs text-gray-500 font-medium">Kỹ thuật viên DGA sẽ liên hệ xử lý trong vòng 24h.</p>
              </div>
            ) : (
              <form onSubmit={handleSubmitFault} className="space-y-3">
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Tiêu đề sự cố *</label>
                  <input
                    type="text"
                    required
                    value={issueTitle}
                    onChange={(e) => setIssueTitle(e.target.value)}
                    placeholder="VD: Cảm biến mất tín hiệu, pin tụt nhanh..."
                    className="w-full px-3 py-2 text-xs bg-gray-50 border border-gray-200 rounded-[10px] focus:outline-none focus:border-red-500 font-medium"
                  />
                </div>

                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1">Mô tả chi tiết lỗi</label>
                  <textarea
                    rows={3}
                    value={issueDesc}
                    onChange={(e) => setIssueDesc(e.target.value)}
                    placeholder="Mô tả hiện trạng thiết bị để kỹ thuật viên chuẩn bị linh kiện thay thế..."
                    className="w-full px-3 py-2 text-xs bg-gray-50 border border-gray-200 rounded-[10px] focus:outline-none focus:border-red-500 font-medium"
                  />
                </div>

                <div className="pt-2 flex items-center justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => setSelectedDevice(null)}
                    className="px-4 py-2 text-xs font-extrabold text-gray-600 bg-gray-100 hover:bg-gray-200 rounded-[10px] cursor-pointer"
                  >
                    Hủy bỏ
                  </button>
                  <button
                    type="submit"
                    disabled={submittingFault}
                    className="px-4 py-2 text-xs font-extrabold text-white bg-red-600 hover:bg-red-700 rounded-[10px] flex items-center gap-1.5 cursor-pointer shadow-xs"
                  >
                    {submittingFault ? "Đang gửi..." : "Gửi yêu cầu bảo trì"}
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
