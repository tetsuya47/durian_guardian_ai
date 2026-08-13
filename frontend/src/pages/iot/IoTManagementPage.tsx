import { useState, useEffect } from "react";
import {
  Cpu,
  ShoppingBag,
  Truck,
  Package,
  Plus,
  Search,
  Radio,
  Sparkles,
  Wifi,
  WifiOff,
  Edit,
  Trash2,
  X,
  Eye,
  Check,
  Ban,
  Star,
  Box,
  Wrench,
  AlertTriangle,
  CheckCircle2,
  Clock,
  UserCheck,
  PhoneCall,
  FileText,
} from "lucide-react";
import SmartGardenCard from "../../components/dashboard/SmartGardenCard";
import {
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from "recharts";
import api from "../../api";

interface IoTProduct {
  id: string;
  device_type: string;
  name: string;
  category: string;
  price: number;
  stock: number;
  rating: number;
  desc: string;
  badge: string;
  imageUrl: string;
}

interface IoTOrderItem {
  device_type: string;
  device_name: string;
  quantity: number;
  unit_price: number;
}

interface IoTOrder {
  id: string;
  order_code: string;
  user_name?: string;
  farm_name: string;
  area_hectare: number;
  tree_count: number;
  items: IoTOrderItem[];
  total_amount: number;
  status: "Pending" | "Approved" | "Paid" | "Shipping" | "Delivered" | "Rejected" | string;
  notes?: string;
  created_at: string;
}

interface FaultReport {
  id: string;
  report_code: string;
  device_code: string;
  device_name: string;
  device_type: string;
  farm_name: string;
  user_name: string;
  phone: string;
  issue_title: string;
  issue_desc: string;
  severity: "Low" | "Medium" | "High" | "Critical" | string;
  severity_label: string;
  status: "Pending" | "In_Progress" | "Resolved" | "Rejected" | string;
  created_at: string;
  image_url: string;
  technician?: string;
  admin_notes?: string;
}

const INITIAL_PRODUCTS: IoTProduct[] = [
  {
    id: "prod-1",
    device_type: "soil_sensor",
    name: "Cảm biến độ ẩm & NPK đất DurianSense Pro",
    category: "Cảm biến đất",
    price: 1200000,
    stock: 145,
    rating: 4.9,
    desc: "Đo độ ẩm đất 0-100%, nhiệt độ, pH và nồng độ NPK trực tiếp tại gốc sầu riêng.",
    badge: "Bán chạy nhất",
    imageUrl: "/assets/iot/soil_sensor.png",
  },
  {
    id: "prod-2",
    device_type: "weather_station",
    name: "Trạm thời tiết vi khí hậu DGA-Weather 5G",
    category: "Trạm thời tiết",
    price: 8500000,
    stock: 32,
    rating: 5.0,
    desc: "Đo lượng mưa, bức xạ UV, đốm nấm lá, độ ẩm không khí và tốc độ gió theo vùng.",
    badge: "Công nghệ AI 5G",
    imageUrl: "/assets/iot/weather_station.png",
  },
  {
    id: "prod-3",
    device_type: "gateway_hub",
    name: "Bộ trung tâm IoT Gateway Hub Edge AI",
    category: "IoT Gateway",
    price: 3500000,
    stock: 58,
    rating: 4.8,
    desc: "Thu thập dữ liệu LoRaWAN bán kính 5km, xử lý dữ liệu tại biên và đẩy lên đám mây.",
    badge: "Kết nối 5km",
    imageUrl: "/assets/iot/gateway_hub.png",
  },
  {
    id: "prod-4",
    device_type: "smart_valve",
    name: "Van tưới tự động thông minh DGA SmartValve",
    category: "Van tự động",
    price: 1800000,
    stock: 90,
    rating: 4.7,
    desc: "Mở/tắt nước bù áp tự động theo lịch khuyến nghị AI Agronomist và thời tiết.",
    badge: "Tiết kiệm 40% nước",
    imageUrl: "/assets/iot/smart_valve.png",
  },
];

const INITIAL_ORDERS: IoTOrder[] = [
  {
    id: "ord-101",
    order_code: "ORD-892401",
    user_name: "Nguyễn Văn Bảo",
    farm_name: "Farm Ea Kar Đắk Lắk",
    area_hectare: 50.0,
    tree_count: 506,
    items: [
      { device_type: "soil_sensor", device_name: "Cảm biến độ ẩm & NPK đất DurianSense Pro", quantity: 10, unit_price: 1200000 },
      { device_type: "gateway_hub", device_name: "Bộ trung tâm IoT Gateway Hub Edge AI", quantity: 1, unit_price: 3500000 },
    ],
    total_amount: 15500000,
    status: "Pending",
    notes: "Giao gấp trước mùa tưới nước Đắk Lắk",
    created_at: "02/06/2026 14:30",
  },
  {
    id: "ord-102",
    order_code: "ORD-892402",
    user_name: "Trần Văn Minh",
    farm_name: "Farm Krông Pắc Đắk Lắk",
    area_hectare: 45.0,
    tree_count: 562,
    items: [
      { device_type: "weather_station", device_name: "Trạm thời tiết vi khí hậu DGA-Weather 5G", quantity: 1, unit_price: 8500000 },
      { device_type: "smart_valve", device_name: "Van tưới tự động thông minh DGA SmartValve", quantity: 4, unit_price: 1800000 },
    ],
    total_amount: 15700000,
    status: "Approved",
    notes: "Đã xác nhận chuyển khoản ngân hàng",
    created_at: "01/06/2026 09:15",
  },
];

const INITIAL_FAULT_REPORTS: FaultReport[] = [
  {
    id: "REP-9921",
    report_code: "REP-9921",
    device_code: "IOT-SOIL-0801",
    device_name: "Cảm biến độ ẩm & NPK đất DurianSense Pro",
    device_type: "soil_sensor",
    farm_name: "Farm Ea Kar Đắk Lắk",
    user_name: "Nguyễn Văn Bảo",
    phone: "0988 123 456",
    issue_title: "Mất tín hiệu kết nối & chỉ số NPK bằng 0",
    issue_desc: "Sau đợt mưa bão lớn kéo dài 2 ngày, cảm biến bị mất kết nối LoRaWAN. Màn hình đầu đo có vết ố kim loại và trả dữ liệu NPK = 0 mg/kg liên tục.",
    severity: "High",
    severity_label: "Khẩn cấp (Ưu tiên)",
    status: "Pending",
    created_at: "02/06/2026 16:45",
    image_url: "/assets/iot/soil_sensor.png",
    technician: "Đoàn Văn Nam (Kỹ thuật Đắk Lắk)",
    admin_notes: "Cần gửi kỹ thuật viên mang cảm biến dự phòng tới hỗ trợ kiểm tra",
  },
  {
    id: "REP-9922",
    report_code: "REP-9922",
    device_code: "IOT-WEATH-0012",
    device_name: "Trạm thời tiết vi khí hậu DGA-Weather 5G",
    device_type: "weather_station",
    farm_name: "Farm Krông Pắc Đắk Lắk",
    user_name: "Trần Văn Minh",
    phone: "0912 345 678",
    issue_title: "Cánh quạt đo tốc độ gió bị kẹt",
    issue_desc: "Cánh quạt đo gió anemometer trên trạm thời tiết bị côn trùng chui vào kẹt cánh, chỉ số tốc độ gió báo 0 km/h.",
    severity: "Medium",
    severity_label: "Trung bình",
    status: "In_Progress",
    created_at: "01/06/2026 10:20",
    image_url: "/assets/iot/weather_station.png",
    technician: "Lê Hoàng Long",
    admin_notes: "Kỹ thuật đã nhận nhiệm vụ, đang di chuyển đến vườn thay trục xoay",
  },
  {
    id: "REP-9923",
    report_code: "REP-9923",
    device_code: "IOT-VALVE-0045",
    device_name: "Van tưới tự động thông minh DGA SmartValve",
    device_type: "smart_valve",
    farm_name: "Farm Cư M'gar Đắk Lắk",
    user_name: "Phạm Quốc Hùng",
    phone: "0977 888 999",
    issue_title: "Van solenoid không ngắt nước khi có lệnh",
    issue_desc: "Khi ra lệnh đóng van tưới trên ứng dụng di động, van vẫn chảy nước nhỏ giọt không ngắt hoàn toàn do cặn rác kẹt cuộn dây solenoid.",
    severity: "Critical",
    severity_label: "Rất Khẩn Cấp",
    status: "Pending",
    created_at: "02/06/2026 18:10",
    image_url: "/assets/iot/smart_valve.png",
    technician: "Chưa phân công",
    admin_notes: "Ưu tiên xử lý tránh ngập úng gốc sầu riêng",
  },
  {
    id: "REP-9924",
    report_code: "REP-9924",
    device_code: "IOT-GATE-0005",
    device_name: "Bộ trung tâm IoT Gateway Hub Edge AI",
    device_type: "gateway_hub",
    farm_name: "Farm Gia Nghĩa Đắk Nông",
    user_name: "Vũ Đình Trọng",
    phone: "0933 555 777",
    issue_title: "Đèn pin năng lượng mặt trời chập chập",
    issue_desc: "Đã tự vệ sinh tấm pin mặt trời và thiết bị đã khởi động lại bình thường.",
    severity: "Low",
    severity_label: "Thấp",
    status: "Resolved",
    created_at: "28/05/2026 14:00",
    image_url: "/assets/iot/gateway_hub.png",
    technician: "Đoàn Văn Nam",
    admin_notes: "Khách hàng xác nhận thiết bị đã hoạt động ổn định trở lại",
  },
];

const STATUS_BADGES: Record<string, { label: string; color: string; bg: string }> = {
  Pending: { label: "Chờ Phê Duyệt", color: "text-amber-700", bg: "bg-amber-100 border-amber-300" },
  Approved: { label: "Đã Phê Duyệt", color: "text-blue-700", bg: "bg-blue-100 border-blue-300" },
  Paid: { label: "Đã Thanh Toán", color: "text-purple-700", bg: "bg-purple-100 border-purple-300" },
  Shipping: { label: "Đang Giao Hàng", color: "text-indigo-700", bg: "bg-indigo-100 border-indigo-300" },
  Delivered: { label: "Hoàn Tất Lắp Đặt", color: "text-emerald-700", bg: "bg-emerald-100 border-emerald-300" },
  Rejected: { label: "Đã Từ Chối", color: "text-red-700", bg: "bg-red-100 border-red-300" },
};

const FAULT_STATUS_BADGES: Record<string, { label: string; color: string; bg: string }> = {
  Pending: { label: "🔴 Chờ Tiếp Nhận", color: "text-red-700", bg: "bg-red-100 border-red-300" },
  In_Progress: { label: "🟡 Đang Sửa Chữa", color: "text-amber-800", bg: "bg-amber-100 border-amber-300" },
  Resolved: { label: "🟢 Đã Khắc Phục", color: "text-emerald-800", bg: "bg-emerald-100 border-emerald-300" },
  Rejected: { label: "⚪ Từ Chối Bảo Hành", color: "text-gray-700", bg: "bg-gray-100 border-gray-300" },
};

const SEVERITY_BADGES: Record<string, { label: string; color: string; bg: string }> = {
  Critical: { label: "🔥 Rất Khẩn Cấp", color: "text-red-800 font-black", bg: "bg-red-200 border-red-400" },
  High: { label: "⚡ Khẩn Cấp (Ưu Tiên)", color: "text-amber-800 font-black", bg: "bg-amber-200 border-amber-400" },
  Medium: { label: "⚠️ Trung Bình", color: "text-blue-800 font-bold", bg: "bg-blue-100 border-blue-300" },
  Low: { label: "ℹ️ Thấp", color: "text-gray-700 font-semibold", bg: "bg-gray-100 border-gray-200" },
};

export default function IoTManagementPage() {
  const [activeTab, setActiveTab] = useState<"overview" | "store" | "orders" | "fault_reports">("overview");

  const [summaryData, setSummaryData] = useState<{
    total_devices: number;
    online_devices: number;
    offline_devices: number;
    maintenance_devices: number;
    by_type: { soil_sensor: number; weather_station: number; gateway_hub: number; smart_valve: number };
    online_by_type: { soil_sensor: number; weather_station: number; gateway_hub: number; smart_valve: number };
    offline_by_type: { soil_sensor: number; weather_station: number; gateway_hub: number; smart_valve: number };
  }>({
    total_devices: 835,
    online_devices: 776,
    offline_devices: 58,
    maintenance_devices: 1,
    by_type: { soil_sensor: 683, weather_station: 80, gateway_hub: 36, smart_valve: 36 },
    online_by_type: { soil_sensor: 673, weather_station: 63, gateway_hub: 20, smart_valve: 20 },
    offline_by_type: { soil_sensor: 10, weather_station: 16, gateway_hub: 16, smart_valve: 16 },
  });

  const [products, setProducts] = useState<IoTProduct[]>(INITIAL_PRODUCTS);
  const [orders, setOrders] = useState<IoTOrder[]>(INITIAL_ORDERS);
  const [faultReports, setFaultReports] = useState<FaultReport[]>(INITIAL_FAULT_REPORTS);

  const [orderStatusFilter, setOrderStatusFilter] = useState("all");
  const [faultStatusFilter, setFaultStatusFilter] = useState("all");
  const [searchQuery, setSearchQuery] = useState("");

  const [isProductModalOpen, setIsProductModalOpen] = useState(false);
  const [editingProduct, setEditingProduct] = useState<IoTProduct | null>(null);
  const [productForm, setProductForm] = useState<Partial<IoTProduct>>({
    name: "",
    category: "Cảm biến đất",
    device_type: "soil_sensor",
    price: 1200000,
    stock: 50,
    rating: 5.0,
    desc: "",
    badge: "Mới",
    imageUrl: "",
  });

  const [selectedOrder, setSelectedOrder] = useState<IoTOrder | null>(null);
  const [selectedFaultReport, setSelectedFaultReport] = useState<FaultReport | null>(null);
  const [reportTechnicianInput, setReportTechnicianInput] = useState("");
  const [reportNotesInput, setReportNotesInput] = useState("");

  useEffect(() => {
    api.get("/api/v1/iot/summary")
      .then((res) => {
        const data = (res.data as any)?.data || res.data;
        if (data && data.total_devices !== undefined) {
          setSummaryData({
            total_devices: data.total_devices || 835,
            online_devices: data.online_devices ?? data.active_devices ?? 776,
            offline_devices: data.offline_devices ?? data.in_stock_devices ?? 58,
            maintenance_devices: data.maintenance_devices ?? 1,
            by_type: data.by_type || { soil_sensor: 683, weather_station: 80, gateway_hub: 36, smart_valve: 36 },
            online_by_type: data.online_by_type || { soil_sensor: 673, weather_station: 63, gateway_hub: 20, smart_valve: 20 },
            offline_by_type: data.offline_by_type || { soil_sensor: 10, weather_station: 16, gateway_hub: 16, smart_valve: 16 },
          });
        }
      })
      .catch(() => {});

    api.get("/api/v1/admin/iot/orders")
      .then((res) => {
        const items = Array.isArray(res.data)
          ? res.data
          : (res.data as any)?.data?.items || (res.data as any)?.data || [];
        if (items.length > 0) {
          setOrders(items);
        }
      })
      .catch(() => {});

    const fetchFaultReports = () => {
      api.get("/api/v1/iot/fault-reports")
        .then((res) => {
          const items = (res.data as any)?.data || res.data;
          if (Array.isArray(items)) {
            setFaultReports(items);
          }
        })
        .catch(() => {
          api.get("/api/v1/admin/iot/fault-reports")
            .then((res) => {
              const items = (res.data as any)?.data || res.data;
              if (Array.isArray(items)) {
                setFaultReports(items);
              }
            })
            .catch(() => {});
        });
    };

    fetchFaultReports();
  }, []);

  const handleOpenProductModal = (prod?: IoTProduct) => {
    if (prod) {
      setEditingProduct(prod);
      setProductForm(prod);
    } else {
      setEditingProduct(null);
      setProductForm({
        name: "",
        category: "Cảm biến đất",
        device_type: "soil_sensor",
        price: 1200000,
        stock: 50,
        rating: 4.8,
        desc: "",
        badge: "Công nghệ AI",
        imageUrl: "/assets/iot/soil_sensor.png",
      });
    }
    setIsProductModalOpen(true);
  };

  const handleSaveProduct = (e: React.FormEvent) => {
    e.preventDefault();
    if (!productForm.name || !productForm.price) return;

    if (editingProduct) {
      setProducts((prev) =>
        prev.map((p) => (p.id === editingProduct.id ? ({ ...p, ...productForm } as IoTProduct) : p))
      );
    } else {
      const newProd: IoTProduct = {
        id: `prod-${Date.now()}`,
        device_type: productForm.device_type || "soil_sensor",
        name: productForm.name || "Thiết bị IoT",
        category: productForm.category || "Cảm biến đất",
        price: Number(productForm.price) || 1000000,
        stock: Number(productForm.stock) || 10,
        rating: Number(productForm.rating) || 5.0,
        desc: productForm.desc || "",
        badge: productForm.badge || "Mới",
        imageUrl: productForm.imageUrl || "/assets/iot/soil_sensor.png",
      };
      setProducts((prev) => [newProd, ...prev]);
    }
    setIsProductModalOpen(false);
  };

  const handleDeleteProduct = (id: string) => {
    if (window.confirm("Bạn có chắc chắn muốn xóa sản phẩm thiết bị IoT này khỏi trang bán hàng?")) {
      setProducts((prev) => prev.filter((p) => p.id !== id));
    }
  };

  const handleUpdateOrderStatus = (orderId: string, newStatus: string) => {
    api.put(`/api/v1/admin/iot/orders/${orderId}/status`, { status: newStatus }).catch(() => {});
    setOrders((prev) =>
      prev.map((o) => (o.id === orderId || o.order_code === orderId ? { ...o, status: newStatus } : o))
    );
    if (selectedOrder && (selectedOrder.id === orderId || selectedOrder.order_code === orderId)) {
      setSelectedOrder((prev) => (prev ? { ...prev, status: newStatus } : null));
    }
  };

  const handleUpdateFaultReportStatus = (reportId: string, newStatus: string, technician?: string, notes?: string) => {
    api.put(`/api/v1/admin/iot/fault-reports/${reportId}/status`, {
      status: newStatus,
      technician: technician || reportTechnicianInput,
      admin_notes: notes || reportNotesInput,
    }).catch(() => {});

    setFaultReports((prev) =>
      prev.map((r) =>
        r.id === reportId || r.report_code === reportId
          ? {
              ...r,
              status: newStatus,
              technician: technician !== undefined ? technician : reportTechnicianInput || r.technician,
              admin_notes: notes !== undefined ? notes : reportNotesInput || r.admin_notes,
            }
          : r
      )
    );

    if (selectedFaultReport && (selectedFaultReport.id === reportId || selectedFaultReport.report_code === reportId)) {
      setSelectedFaultReport((prev) =>
        prev
          ? {
              ...prev,
              status: newStatus,
              technician: technician !== undefined ? technician : reportTechnicianInput || prev.technician,
              admin_notes: notes !== undefined ? notes : reportNotesInput || prev.admin_notes,
            }
          : null
      );
    }
  };

  const handleOpenFaultModal = (report: FaultReport) => {
    setSelectedFaultReport(report);
    setReportTechnicianInput(report.technician || "");
    setReportNotesInput(report.admin_notes || "");
  };

  // Metrics
  const onlineCount = summaryData.online_devices;
  const offlineCount = summaryData.offline_devices;
  const maintenanceCount = summaryData.maintenance_devices;
  const totalHardwareDevices = summaryData.total_devices;

  const onlinePct = ((onlineCount / totalHardwareDevices) * 100).toFixed(1);
  const offlinePct = ((offlineCount / totalHardwareDevices) * 100).toFixed(1);

  // Doughnut Pie Chart
  const deviceStatusPieData = [
    { name: "Online (Đã bán ra)", value: onlineCount, color: "#10B981" },
    { name: "Offline (Trong kho)", value: offlineCount, color: "#EF4444" },
    { name: "Bảo trì", value: maintenanceCount, color: "#F59E0B" },
  ];

  // Overall Bar Chart
  const overallTypeBarData = [
    { name: "Cảm biến NPK", count: summaryData.by_type.soil_sensor, color: "#10B981" },
    { name: "Trạm 5G", count: summaryData.by_type.weather_station, color: "#2563EB" },
    { name: "Gateway AI", count: summaryData.by_type.gateway_hub, color: "#8B5CF6" },
    { name: "Van tự động", count: summaryData.by_type.smart_valve, color: "#F59E0B" },
  ];

  // Bar Chart 1: Online (777 bộ)
  const onlineBarData = [
    { name: "Cảm biến NPK", count: summaryData.online_by_type.soil_sensor, color: "#10B981" },
    { name: "Trạm 5G", count: summaryData.online_by_type.weather_station, color: "#059669" },
    { name: "Gateway AI", count: summaryData.online_by_type.gateway_hub, color: "#047857" },
    { name: "Van tự động", count: summaryData.online_by_type.smart_valve, color: "#065F46" },
  ];

  // Bar Chart 2: Offline (58 bộ)
  const offlineBarData = [
    { name: "Cảm biến NPK", count: summaryData.offline_by_type.soil_sensor, color: "#EF4444" },
    { name: "Trạm 5G", count: summaryData.offline_by_type.weather_station, color: "#DC2626" },
    { name: "Gateway AI", count: summaryData.offline_by_type.gateway_hub, color: "#B91C1C" },
    { name: "Van tự động", count: summaryData.offline_by_type.smart_valve, color: "#991B1B" },
  ];

  const filteredOrders = orders.filter((o) => {
    const matchStatus = orderStatusFilter === "all" || o.status === orderStatusFilter;
    const matchSearch =
      o.order_code.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (o.user_name && o.user_name.toLowerCase().includes(searchQuery.toLowerCase())) ||
      o.farm_name.toLowerCase().includes(searchQuery.toLowerCase());
    return matchStatus && matchSearch;
  });

  const filteredFaultReports = faultReports.filter((r) => {
    const matchStatus = faultStatusFilter === "all" || r.status === faultStatusFilter;
    const matchSearch =
      r.report_code.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.device_code.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.user_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.farm_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.issue_title.toLowerCase().includes(searchQuery.toLowerCase());
    return matchStatus && matchSearch;
  });

  const pendingFaultCount = faultReports.filter((r) => r.status === "Pending").length;

  return (
    <div className="flex flex-col space-y-4 font-sans text-gray-900">
      {/* Top Banner Header */}
      <div className="bg-white p-4.5 rounded-[20px] border border-gray-200/80 shadow-xs flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-[14px] bg-emerald-100 text-emerald-800 flex items-center justify-center border border-emerald-200/80">
            <Cpu className="w-5 h-5" />
          </div>
          <div>
            <h1 className="text-xl font-black text-gray-900 tracking-tight flex items-center gap-2">
              Quản lý Thiết bị IoT & Đơn hàng
              <Sparkles className="w-4 h-4 text-amber-500 fill-amber-400" />
            </h1>
            <p className="text-xs text-gray-500 font-medium mt-0.5">
              Theo dõi 835 thiết bị phần cứng trong MongoDB — Phân loại Online (Đã bán ra) & Offline (Còn trong kho)
            </p>
          </div>
        </div>

        {/* 4 Nav Tabs */}
        <div className="flex items-center bg-gray-100/80 p-1.5 rounded-[16px] border border-gray-200 gap-1 overflow-x-auto">
          <button
            type="button"
            onClick={() => setActiveTab("overview")}
            className={`px-3.5 py-2 rounded-[12px] text-xs font-black transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap ${
              activeTab === "overview"
                ? "bg-emerald-600 text-white shadow-sm"
                : "text-gray-600 hover:text-gray-900 hover:bg-gray-200/50"
            }`}
          >
            <Radio className="w-3.5 h-3.5" />
            <span>Tổng quan thiết bị ({totalHardwareDevices})</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab("store")}
            className={`px-3.5 py-2 rounded-[12px] text-xs font-black transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap ${
              activeTab === "store"
                ? "bg-emerald-600 text-white shadow-sm"
                : "text-gray-600 hover:text-gray-900 hover:bg-gray-200/50"
            }`}
          >
            <ShoppingBag className="w-3.5 h-3.5" />
            <span>Trang bán thiết bị ({products.length})</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab("orders")}
            className={`px-3.5 py-2 rounded-[12px] text-xs font-black transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap ${
              activeTab === "orders"
                ? "bg-emerald-600 text-white shadow-sm"
                : "text-gray-600 hover:text-gray-900 hover:bg-gray-200/50"
            }`}
          >
            <Truck className="w-3.5 h-3.5" />
            <span>Duyệt đơn mua hàng ({orders.filter((o) => o.status === "Pending").length} chờ)</span>
          </button>

          {/* TAB 4: QUẢN LÝ BÁO CÁO THIẾT BỊ LỖI TỪ NGƯỜI DÙNG */}
          <button
            type="button"
            onClick={() => setActiveTab("fault_reports")}
            className={`px-3.5 py-2 rounded-[12px] text-xs font-black transition-all flex items-center gap-2 cursor-pointer whitespace-nowrap ${
              activeTab === "fault_reports"
                ? "bg-red-600 text-white shadow-sm"
                : "text-gray-600 hover:text-gray-900 hover:bg-gray-200/50"
            }`}
          >
            <Wrench className="w-3.5 h-3.5" />
            <span>Quản lý thiết bị lỗi ({pendingFaultCount} chờ)</span>
            {pendingFaultCount > 0 && (
              <span className="w-2 h-2 rounded-full bg-amber-400 animate-ping" />
            )}
          </button>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* TAB 1: TỔNG QUAN THIẾT BỊ IOT */}
      {/* ========================================================================= */}
      {activeTab === "overview" && (
        <div className="flex flex-col space-y-4">
          <SmartGardenCard />
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <div className="bg-white border border-gray-200/80 p-4 rounded-[18px] shadow-xs flex items-center justify-between">
              <div>
                <span className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider block">THIẾT BỊ ONLINE (ĐÃ BÁN RA)</span>
                <p className="text-2xl font-black text-gray-900 mt-1">
                  {onlineCount} <span className="text-xs font-bold text-emerald-600">({onlinePct}%)</span>
                </p>
                <span className="text-[10px] font-bold text-emerald-700 flex items-center gap-1 mt-1">
                  <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" /> Đã bán & Lắp đặt tại các nông trại
                </span>
              </div>
              <div className="w-11 h-11 rounded-[14px] bg-emerald-100 text-emerald-700 flex items-center justify-center">
                <Wifi className="w-5 h-5" />
              </div>
            </div>

            <div className="bg-white border border-gray-200/80 p-4 rounded-[18px] shadow-xs flex items-center justify-between">
              <div>
                <span className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider block">THIẾT BỊ OFFLINE (CÒN TRONG KHO)</span>
                <p className="text-2xl font-black text-gray-900 mt-1">
                  {offlineCount} <span className="text-xs font-bold text-red-600">({offlinePct}%)</span>
                </p>
                <span className="text-[10px] font-bold text-red-600 flex items-center gap-1 mt-1">
                  <Box className="w-3 h-3 text-red-500" /> Sẵn sàng xuất bán cho nông trại mới
                </span>
              </div>
              <div className="w-11 h-11 rounded-[14px] bg-red-100 text-red-700 flex items-center justify-center">
                <WifiOff className="w-5 h-5" />
              </div>
            </div>

            <div className="bg-white border border-gray-200/80 p-4 rounded-[18px] shadow-xs flex items-center justify-between">
              <div>
                <span className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider block">TỔNG SỐ THIẾT BỊ HỆ THỐNG</span>
                <p className="text-2xl font-black text-gray-900 mt-1">{totalHardwareDevices} <span className="text-xs font-bold text-blue-600">(100%)</span></p>
                <span className="text-[10px] font-bold text-blue-600 flex items-center gap-1 mt-1">
                  <Package className="w-3 h-3" /> Tổng đếm từ collection `iot_devices`
                </span>
              </div>
              <div className="w-11 h-11 rounded-[14px] bg-blue-100 text-blue-700 flex items-center justify-center">
                <Package className="w-5 h-5" />
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-4 items-stretch">
            <div className="lg:col-span-5 bg-white border border-gray-200/80 p-4 rounded-[20px] shadow-xs flex flex-col justify-between h-full">
              <div className="flex items-center justify-between mb-1">
                <h3 className="text-sm font-extrabold text-gray-900 tracking-tight">Tỷ lệ Trạng thái Thiết bị (MongoDB)</h3>
                <span className="text-[10px] font-bold text-gray-500 bg-gray-100 px-2 py-0.5 rounded-md">Realtime</span>
              </div>

              <div className="flex items-center gap-4 my-auto py-2">
                <div className="w-[125px] h-[125px] relative flex-shrink-0">
                  <ResponsiveContainer width="100%" height="100%">
                    <PieChart>
                      <Pie data={deviceStatusPieData} cx="50%" cy="50%" innerRadius={36} outerRadius={56} paddingAngle={3} dataKey="value">
                        {deviceStatusPieData.map((entry, idx) => (
                          <Cell key={`status-${idx}`} fill={entry.color} />
                        ))}
                      </Pie>
                    </PieChart>
                  </ResponsiveContainer>
                  <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                    <span className="text-sm font-black text-gray-900">{totalHardwareDevices}</span>
                    <span className="text-[8px] text-gray-500 font-bold uppercase">thiết bị</span>
                  </div>
                </div>

                <div className="flex-1 space-y-2 text-xs">
                  {deviceStatusPieData.map((item) => (
                    <div key={item.name} className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <div className="w-2.5 h-2.5 rounded-full flex-shrink-0" style={{ backgroundColor: item.color }} />
                        <span className="text-gray-700 font-bold text-[11px]">{item.name}</span>
                      </div>
                      <strong className="font-black text-gray-900 text-[11px]">{item.value}</strong>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            <div className="lg:col-span-7 bg-white border border-gray-200/80 p-4 rounded-[20px] shadow-xs flex flex-col justify-between h-full">
              <div className="flex items-center justify-between mb-1">
                <h3 className="text-sm font-extrabold text-gray-900 tracking-tight">Phân bổ số lượng theo Chủng loại (MongoDB `iot_devices`)</h3>
                <span className="text-[10px] font-bold text-gray-500 bg-gray-100 px-2 py-0.5 rounded-md">Chủng loại</span>
              </div>

              <div className="w-full h-[135px] my-auto">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={overallTypeBarData} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#F1F5F9" />
                    <XAxis dataKey="name" stroke="#64748B" fontSize={10} fontWeight="bold" tickLine={false} />
                    <YAxis stroke="#64748B" fontSize={10} fontWeight="bold" tickLine={false} />
                    <Tooltip formatter={(val: number) => [`${val} bộ`, "Số lượng tổng"]} contentStyle={{ borderRadius: "10px", fontSize: "11px", fontWeight: "bold" }} />
                    <Bar dataKey="count" radius={[6, 6, 0, 0]}>
                      {overallTypeBarData.map((entry, index) => (
                        <Cell key={`bar-${index}`} fill={entry.color} />
                      ))}
                    </Bar>
                  </BarChart>
                </ResponsiveContainer>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-2 gap-4 items-stretch">
            <div className="bg-white border border-gray-200/80 p-4 rounded-[20px] shadow-xs flex flex-col justify-between h-full space-y-2.5">
              <div>
                <div className="flex items-center justify-between mb-1">
                  <div className="flex items-center gap-2">
                    <Wifi className="w-4 h-4 text-emerald-600" />
                    <h3 className="text-sm font-extrabold text-gray-900 tracking-tight">Biểu đồ Thiết bị ĐÃ BÁN RA (Online)</h3>
                  </div>
                  <span className="text-[10px] font-black text-emerald-800 bg-emerald-100 px-2.5 py-0.5 rounded-full border border-emerald-300">
                    {onlineCount} thiết bị
                  </span>
                </div>
                <p className="text-[11px] text-gray-500 font-medium mb-2">Số lượng từng loại thiết bị IoT đã bán & đang lắp đặt tại các trang trại</p>

                <div className="w-full h-[155px] bg-gray-50/80 p-2.5 rounded-[16px] border border-gray-100">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={onlineBarData} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#F1F5F9" />
                      <XAxis dataKey="name" stroke="#64748B" fontSize={10} fontWeight="bold" tickLine={false} />
                      <YAxis stroke="#64748B" fontSize={10} fontWeight="bold" tickLine={false} />
                      <Tooltip formatter={(val: number) => [`${val} bộ`, "Đã bán (Online)"]} contentStyle={{ borderRadius: "10px", fontSize: "11px", fontWeight: "bold" }} />
                      <Bar dataKey="count" radius={[6, 6, 0, 0]}>
                        {onlineBarData.map((entry, index) => (
                          <Cell key={`online-cell-${index}`} fill={entry.color} />
                        ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2 text-xs pt-1 border-t border-gray-100">
                {onlineBarData.map((item) => (
                  <div key={item.name} className="p-2 rounded-[10px] bg-emerald-50/60 border border-emerald-100 flex items-center justify-between">
                    <span className="text-gray-700 font-bold text-[11px]">{item.name}</span>
                    <strong className="text-emerald-900 font-black text-[11px]">{item.count} bộ</strong>
                  </div>
                ))}
              </div>
            </div>

            <div className="bg-white border border-gray-200/80 p-4 rounded-[20px] shadow-xs flex flex-col justify-between h-full space-y-2.5">
              <div>
                <div className="flex items-center justify-between mb-1">
                  <div className="flex items-center gap-2">
                    <WifiOff className="w-4 h-4 text-red-600" />
                    <h3 className="text-sm font-extrabold text-gray-900 tracking-tight">Biểu đồ Thiết bị CÒN LẠI TRONG KHO (Offline)</h3>
                  </div>
                  <span className="text-[10px] font-black text-red-800 bg-red-100 px-2.5 py-0.5 rounded-full border border-red-300">
                    {offlineCount} thiết bị
                  </span>
                </div>
                <p className="text-[11px] text-gray-500 font-medium mb-2">Số lượng từng loại thiết bị phần cứng đang sẵn sàng lưu trữ trong kho</p>

                <div className="w-full h-[155px] bg-gray-50/80 p-2.5 rounded-[16px] border border-gray-100">
                  <ResponsiveContainer width="100%" height="100%">
                    <BarChart data={offlineBarData} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
                      <CartesianGrid strokeDasharray="3 3" stroke="#F1F5F9" />
                      <XAxis dataKey="name" stroke="#64748B" fontSize={10} fontWeight="bold" tickLine={false} />
                      <YAxis stroke="#64748B" fontSize={10} fontWeight="bold" tickLine={false} />
                      <Tooltip formatter={(val: number) => [`${val} bộ`, "Trong kho (Offline)"]} contentStyle={{ borderRadius: "10px", fontSize: "11px", fontWeight: "bold" }} />
                      <Bar dataKey="count" radius={[6, 6, 0, 0]}>
                        {offlineBarData.map((entry, index) => (
                          <Cell key={`offline-cell-${index}`} fill={entry.color} />
                        ))}
                      </Bar>
                    </BarChart>
                  </ResponsiveContainer>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2 text-xs pt-1 border-t border-gray-100">
                {offlineBarData.map((item) => (
                  <div key={item.name} className="p-2 rounded-[10px] bg-red-50/60 border border-red-100 flex items-center justify-between">
                    <span className="text-gray-700 font-bold text-[11px]">{item.name}</span>
                    <strong className="text-red-900 font-black text-[11px]">{item.count} bộ</strong>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 2: STORE CATALOG */}
      {/* ========================================================================= */}
      {activeTab === "store" && (
        <div className="flex flex-col space-y-4">
          <div className="bg-white p-4.5 rounded-[20px] border border-gray-200/80 shadow-xs flex flex-wrap items-center justify-between gap-3">
            <div>
              <h2 className="text-sm font-black text-gray-900 uppercase tracking-wider">Quản lý Danh mục & Sản phẩm Trang Bán Thiết Bị IoT</h2>
              <p className="text-xs text-gray-500 font-medium mt-0.5">Thêm mới, sửa thông số, điều chỉnh giá bán và hình ảnh hiển thị trên trang mua sắm của nhà vườn</p>
            </div>

            <button
              type="button"
              onClick={() => handleOpenProductModal()}
              className="bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold text-xs px-4 py-2.5 rounded-[12px] flex items-center gap-2 shadow-sm transition-all cursor-pointer"
            >
              <Plus className="w-4 h-4" />
              <span>+ Thêm Thiết Bị Mới</span>
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {products.map((p) => (
              <div key={p.id} className="bg-white border border-gray-200/80 rounded-[20px] p-4 shadow-xs flex flex-col justify-between hover:shadow-md transition-all group">
                <div>
                  <div className="relative w-full h-40 bg-gray-100 rounded-[14px] overflow-hidden mb-3 border border-gray-100">
                    <img src={p.imageUrl} alt={p.name} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" />
                    <span className="absolute top-2.5 left-2.5 bg-emerald-600 text-white font-extrabold text-[10px] px-2.5 py-0.5 rounded-full shadow-2xs">
                      {p.badge}
                    </span>
                    <span className="absolute top-2.5 right-2.5 bg-amber-500 text-white font-black text-[10px] px-2 py-0.5 rounded-full flex items-center gap-0.5 shadow-2xs">
                      <Star className="w-3 h-3 fill-white" /> {p.rating}
                    </span>
                  </div>

                  <span className="text-[10px] font-extrabold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-md uppercase tracking-wider block w-max mb-1">
                    {p.category}
                  </span>
                  <h3 className="text-sm font-black text-gray-900 leading-snug line-clamp-2">{p.name}</h3>
                  <p className="text-xs text-gray-500 font-medium mt-1 line-clamp-2">{p.desc}</p>
                </div>

                <div className="mt-4 pt-3 border-t border-gray-100 flex items-center justify-between">
                  <div>
                    <span className="text-[10px] font-bold text-gray-400 block uppercase">Giá bán lẻ</span>
                    <strong className="text-base font-black text-emerald-700">{p.price.toLocaleString()} đ</strong>
                    <span className="text-[10px] text-gray-500 block font-semibold">Tồn kho: {p.stock} bộ</span>
                  </div>

                  <div className="flex items-center gap-1">
                    <button
                      type="button"
                      onClick={() => handleOpenProductModal(p)}
                      className="p-2 rounded-[10px] bg-blue-50 text-blue-700 hover:bg-blue-100 transition-colors cursor-pointer"
                      title="Sửa thiết bị"
                    >
                      <Edit className="w-3.5 h-3.5" />
                    </button>
                    <button
                      type="button"
                      onClick={() => handleDeleteProduct(p.id)}
                      className="p-2 rounded-[10px] bg-red-50 text-red-700 hover:bg-red-100 transition-colors cursor-pointer"
                      title="Xóa thiết bị"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 3: ORDERS APPROVAL */}
      {/* ========================================================================= */}
      {activeTab === "orders" && (
        <div className="flex flex-col space-y-4">
          <div className="bg-white p-4.5 rounded-[20px] border border-gray-200/80 shadow-xs flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-1 overflow-x-auto">
              {[
                { key: "all", label: "Tất cả đơn" },
                { key: "Pending", label: "Chờ phê duyệt" },
                { key: "Approved", label: "Đã phê duyệt" },
                { key: "Delivered", label: "Hoàn tất" },
                { key: "Rejected", label: "Đã từ chối" },
              ].map((st) => (
                <button
                  key={st.key}
                  type="button"
                  onClick={() => setOrderStatusFilter(st.key)}
                  className={`px-3 py-1.5 rounded-[10px] text-xs font-extrabold cursor-pointer transition-all ${
                    orderStatusFilter === st.key
                      ? "bg-emerald-600 text-white shadow-2xs"
                      : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                  }`}
                >
                  {st.label}
                </button>
              ))}
            </div>

            <div className="relative">
              <Search className="w-3.5 h-3.5 text-gray-400 absolute left-3 top-3" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Tìm mã đơn, tên nông trại..."
                className="bg-gray-50 border border-gray-200 rounded-[12px] pl-8 pr-3 py-2 text-xs font-medium text-gray-900 w-56 focus:outline-none focus:ring-2 focus:ring-emerald-300"
              />
            </div>
          </div>

          <div className="bg-white border border-gray-200/80 p-4.5 rounded-[20px] shadow-xs">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-[11px] text-gray-700">
                <thead className="text-[10px] uppercase font-bold text-gray-500 bg-gray-50 border-b border-gray-200">
                  <tr>
                    <th className="py-2.5 px-3 whitespace-nowrap">Mã đơn</th>
                    <th className="py-2.5 px-3 whitespace-nowrap">Ngày đặt</th>
                    <th className="py-2.5 px-3 whitespace-nowrap">Khách hàng / Nông trại</th>
                    <th className="py-2.5 px-3 whitespace-nowrap">Danh sách thiết bị mua</th>
                    <th className="py-2.5 px-3 text-right whitespace-nowrap">Tổng tiền (VNĐ)</th>
                    <th className="py-2.5 px-3 text-center whitespace-nowrap">Trạng thái</th>
                    <th className="py-2.5 px-3 text-center whitespace-nowrap">Thao tác Admin</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 font-medium">
                  {filteredOrders.map((ord) => {
                    const st = STATUS_BADGES[ord.status] || { label: ord.status, color: "text-gray-700", bg: "bg-gray-100" };
                    return (
                      <tr key={ord.id} className="hover:bg-emerald-50/30 transition-colors">
                        <td className="py-3 px-3 font-mono font-black text-emerald-800 whitespace-nowrap">{ord.order_code}</td>
                        <td className="py-3 px-3 text-gray-500 font-semibold whitespace-nowrap">{ord.created_at}</td>
                        <td className="py-3 px-3 whitespace-nowrap">
                          <strong className="text-gray-900 block font-black">{ord.user_name || "Chủ vườn"}</strong>
                          <span className="text-[10px] text-gray-500 block font-semibold">{ord.farm_name} ({ord.area_hectare} ha)</span>
                        </td>
                        <td className="py-3 px-3">
                          <div className="space-y-0.5">
                            {ord.items.map((it, i) => (
                              <div key={i} className="text-[10px] font-semibold text-gray-800">
                                • {it.device_name} <span className="font-bold text-emerald-700">x{it.quantity}</span>
                              </div>
                            ))}
                          </div>
                        </td>
                        <td className="py-3 px-3 text-right font-black text-amber-700 text-xs whitespace-nowrap">
                          {ord.total_amount.toLocaleString()} đ
                        </td>
                        <td className="py-3 px-3 text-center whitespace-nowrap">
                          <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-black border ${st.bg} ${st.color}`}>
                            {st.label}
                          </span>
                        </td>
                        <td className="py-3 px-3 text-center whitespace-nowrap">
                          <div className="flex items-center justify-center gap-1.5">
                            {ord.status === "Pending" && (
                              <>
                                <button
                                  type="button"
                                  onClick={() => handleUpdateOrderStatus(ord.order_code, "Approved")}
                                  className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-[8px] font-black text-[10px] flex items-center gap-1 cursor-pointer transition-colors"
                                >
                                  <Check className="w-3 h-3" /> Duyệt đơn
                                </button>
                                <button
                                  type="button"
                                  onClick={() => handleUpdateOrderStatus(ord.order_code, "Rejected")}
                                  className="px-2 py-1 bg-red-100 hover:bg-red-200 text-red-700 rounded-[8px] font-black text-[10px] flex items-center gap-1 cursor-pointer transition-colors"
                                >
                                  <Ban className="w-3 h-3" /> Từ chối
                                </button>
                              </>
                            )}

                            <button
                              type="button"
                              onClick={() => setSelectedOrder(ord)}
                              className="px-2 py-1 bg-gray-100 hover:bg-gray-200 text-gray-700 rounded-[8px] font-bold text-[10px] flex items-center gap-1 cursor-pointer"
                            >
                              <Eye className="w-3 h-3" /> Xem chi tiết
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* ========================================================================= */}
      {/* TAB 4: QUẢN LÝ BÁO CÁO THIẾT BỊ LỖI TỪ NGƯỜI DÙNG */}
      {/* ========================================================================= */}
      {activeTab === "fault_reports" && (
        <div className="flex flex-col space-y-4">
          {/* KPI Stat Cards for Fault Reports */}
          <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
            <div className="bg-white border border-gray-200/80 p-4 rounded-[18px] shadow-xs flex items-center justify-between">
              <div>
                <span className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider block">BÁO CÁO MỚI CHỜ XỬ LÝ</span>
                <p className="text-2xl font-black text-red-600 mt-1">
                  {faultReports.filter((r) => r.status === "Pending").length} <span className="text-xs font-bold text-gray-500">báo cáo</span>
                </p>
                <span className="text-[10px] font-bold text-red-600 flex items-center gap-1 mt-1">
                  <span className="w-2 h-2 rounded-full bg-red-500 animate-ping" /> Cần phân công kỹ thuật
                </span>
              </div>
              <div className="w-11 h-11 rounded-[14px] bg-red-100 text-red-700 flex items-center justify-center">
                <AlertTriangle className="w-5 h-5" />
              </div>
            </div>

            <div className="bg-white border border-gray-200/80 p-4 rounded-[18px] shadow-xs flex items-center justify-between">
              <div>
                <span className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider block">ĐANG KỸ THUẬT SỬA CHỮA</span>
                <p className="text-2xl font-black text-amber-600 mt-1">
                  {faultReports.filter((r) => r.status === "In_Progress").length} <span className="text-xs font-bold text-gray-500">thiết bị</span>
                </p>
                <span className="text-[10px] font-bold text-amber-700 flex items-center gap-1 mt-1">
                  <Clock className="w-3 h-3 text-amber-600" /> Kỹ thuật viên đang di chuyển
                </span>
              </div>
              <div className="w-11 h-11 rounded-[14px] bg-amber-100 text-amber-700 flex items-center justify-center">
                <Wrench className="w-5 h-5" />
              </div>
            </div>

            <div className="bg-white border border-gray-200/80 p-4 rounded-[18px] shadow-xs flex items-center justify-between">
              <div>
                <span className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider block">ĐÃ BẢO HÀNH KHẮC PHỤC</span>
                <p className="text-2xl font-black text-emerald-600 mt-1">
                  {faultReports.filter((r) => r.status === "Resolved").length} <span className="text-xs font-bold text-gray-500">báo cáo</span>
                </p>
                <span className="text-[10px] font-bold text-emerald-700 flex items-center gap-1 mt-1">
                  <CheckCircle2 className="w-3 h-3 text-emerald-600" /> Khách hàng đã nghiệm thu
                </span>
              </div>
              <div className="w-11 h-11 rounded-[14px] bg-emerald-100 text-emerald-700 flex items-center justify-center">
                <CheckCircle2 className="w-5 h-5" />
              </div>
            </div>

            <div className="bg-white border border-gray-200/80 p-4 rounded-[18px] shadow-xs flex items-center justify-between">
              <div>
                <span className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider block">MỨC ĐỘ NGUY CẤP (ƯU TIÊN)</span>
                <p className="text-2xl font-black text-purple-700 mt-1">
                  {faultReports.filter((r) => r.severity === "Critical" || r.severity === "High").length} <span className="text-xs font-bold text-gray-500">sự cố</span>
                </p>
                <span className="text-[10px] font-bold text-purple-700 flex items-center gap-1 mt-1">
                  ⚡ Cần cử kỹ thuật trong 24h
                </span>
              </div>
              <div className="w-11 h-11 rounded-[14px] bg-purple-100 text-purple-700 flex items-center justify-center">
                <Sparkles className="w-5 h-5" />
              </div>
            </div>
          </div>

          {/* Filter & Search Controls */}
          <div className="bg-white p-4.5 rounded-[20px] border border-gray-200/80 shadow-xs flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-1 overflow-x-auto">
              {[
                { key: "all", label: "Tất cả báo cáo" },
                { key: "Pending", label: "🔴 Chờ tiếp nhận" },
                { key: "In_Progress", label: "🟡 Đang sửa chữa" },
                { key: "Resolved", label: "🟢 Đã khắc phục" },
                { key: "Rejected", label: "⚪ Từ chối bảo hành" },
              ].map((st) => (
                <button
                  key={st.key}
                  type="button"
                  onClick={() => setFaultStatusFilter(st.key)}
                  className={`px-3 py-1.5 rounded-[10px] text-xs font-extrabold cursor-pointer transition-all ${
                    faultStatusFilter === st.key
                      ? "bg-red-600 text-white shadow-2xs"
                      : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                  }`}
                >
                  {st.label}
                </button>
              ))}
            </div>

            <div className="relative">
              <Search className="w-3.5 h-3.5 text-gray-400 absolute left-3 top-3" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Tìm mã báo cáo, thiết bị, nông dân..."
                className="bg-gray-50 border border-gray-200 rounded-[12px] pl-8 pr-3 py-2 text-xs font-medium text-gray-900 w-64 focus:outline-none focus:ring-2 focus:ring-red-300"
              />
            </div>
          </div>

          {/* Fault Reports Data Table */}
          <div className="bg-white border border-gray-200/80 p-4.5 rounded-[20px] shadow-xs">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-[11px] text-gray-700">
                <thead className="text-[10px] uppercase font-bold text-gray-500 bg-gray-50 border-b border-gray-200">
                  <tr>
                    <th className="py-2.5 px-3 whitespace-nowrap">Mã báo cáo</th>
                    <th className="py-2.5 px-3 whitespace-nowrap">Thời gian báo</th>
                    <th className="py-2.5 px-3 whitespace-nowrap">Nông dân & Nông trại</th>
                    <th className="py-2.5 px-3 whitespace-nowrap">Thiết bị báo lỗi</th>
                    <th className="py-2.5 px-3 whitespace-nowrap">Mô tả hỏng hóc từ người dùng</th>
                    <th className="py-2.5 px-3 text-center whitespace-nowrap">Mức độ nguy cấp</th>
                    <th className="py-2.5 px-3 text-center whitespace-nowrap">Trạng thái xử lý</th>
                    <th className="py-2.5 px-3 text-center whitespace-nowrap">Thao tác Admin</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 font-medium">
                  {filteredFaultReports.map((rep) => {
                    const st = FAULT_STATUS_BADGES[rep.status] || { label: rep.status, color: "text-gray-700", bg: "bg-gray-100" };
                    const sev = SEVERITY_BADGES[rep.severity] || { label: rep.severity_label || rep.severity, color: "text-gray-700", bg: "bg-gray-100" };
                    return (
                      <tr key={rep.id} className="hover:bg-red-50/30 transition-colors">
                        <td className="py-3 px-3 font-mono font-black text-red-800 whitespace-nowrap">
                          {rep.report_code}
                          <span className="block text-[9px] text-gray-400 font-semibold font-mono">{rep.device_code}</span>
                        </td>
                        <td className="py-3 px-3 text-gray-500 font-semibold whitespace-nowrap">{rep.created_at}</td>
                        <td className="py-3 px-3 whitespace-nowrap">
                          <strong className="text-gray-900 block font-black">{rep.user_name}</strong>
                          <span className="text-[10px] text-gray-500 block font-semibold">{rep.farm_name} • {rep.phone}</span>
                        </td>
                        <td className="py-3 px-3 whitespace-nowrap">
                          <strong className="text-emerald-900 block font-extrabold">{rep.device_name}</strong>
                          <span className="text-[10px] text-gray-500 font-semibold">Mã: {rep.device_code}</span>
                        </td>
                        <td className="py-3 px-3 max-w-xs">
                          <strong className="text-gray-900 block font-bold truncate">{rep.issue_title}</strong>
                          <p className="text-[10px] text-gray-500 line-clamp-2 leading-tight mt-0.5">{rep.issue_desc}</p>
                        </td>
                        <td className="py-3 px-3 text-center whitespace-nowrap">
                          <span className={`px-2.5 py-0.5 rounded-full text-[10px] border ${sev.bg} ${sev.color}`}>
                            {sev.label}
                          </span>
                        </td>
                        <td className="py-3 px-3 text-center whitespace-nowrap">
                          <span className={`px-2.5 py-0.5 rounded-full text-[10px] font-black border ${st.bg} ${st.color}`}>
                            {st.label}
                          </span>
                        </td>
                        <td className="py-3 px-3 text-center whitespace-nowrap">
                          <div className="flex items-center justify-center gap-1.5">
                            {rep.status === "Pending" && (
                              <button
                                type="button"
                                onClick={() => handleUpdateFaultReportStatus(rep.report_code, "In_Progress", "Đoàn Văn Nam (Kỹ thuật Đắk Lắk)", "Đã phân công kỹ thuật viên kiểm tra")}
                                className="px-2.5 py-1 bg-amber-600 hover:bg-amber-700 text-white rounded-[8px] font-black text-[10px] flex items-center gap-1 cursor-pointer transition-colors shadow-2xs"
                              >
                                <Wrench className="w-3 h-3" /> Tiếp nhận & Sửa
                              </button>
                            )}

                            {rep.status === "In_Progress" && (
                              <button
                                type="button"
                                onClick={() => handleUpdateFaultReportStatus(rep.report_code, "Resolved", rep.technician, "Kỹ thuật đã hoàn tất bảo hành và kiểm tra lại tín hiệu")}
                                className="px-2.5 py-1 bg-emerald-600 hover:bg-emerald-700 text-white rounded-[8px] font-black text-[10px] flex items-center gap-1 cursor-pointer transition-colors shadow-2xs"
                              >
                                <Check className="w-3 h-3" /> Xử lý xong
                              </button>
                            )}

                            <button
                              type="button"
                              onClick={() => handleOpenFaultModal(rep)}
                              className="px-2.5 py-1 bg-gray-100 hover:bg-gray-200 text-gray-800 rounded-[8px] font-bold text-[10px] flex items-center gap-1 cursor-pointer"
                            >
                              <Eye className="w-3 h-3" /> Chi tiết lỗi
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      )}

      {/* MODAL: ADD / EDIT PRODUCT */}
      {isProductModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-[24px] max-w-lg w-full p-6 shadow-2xl border border-gray-200 space-y-4 animate-in fade-in zoom-in duration-200">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <h3 className="text-base font-black text-gray-900 flex items-center gap-2">
                {editingProduct ? "Chỉnh sửa thông số Thiết bị IoT" : "Thêm mới Thiết bị IoT vào Trang bán hàng"}
              </h3>
              <button type="button" onClick={() => setIsProductModalOpen(false)} className="text-gray-400 hover:text-gray-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSaveProduct} className="space-y-3 text-xs">
              <div>
                <label className="block font-extrabold text-gray-700 mb-1">Tên thiết bị IoT (*)</label>
                <input
                  type="text"
                  required
                  value={productForm.name}
                  onChange={(e) => setProductForm({ ...productForm, name: e.target.value })}
                  className="w-full bg-gray-50 border border-gray-200 rounded-[10px] px-3 py-2 font-bold text-gray-900 focus:ring-2 focus:ring-emerald-300 focus:outline-none"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-extrabold text-gray-700 mb-1">Danh mục</label>
                  <select
                    value={productForm.category}
                    onChange={(e) => setProductForm({ ...productForm, category: e.target.value })}
                    className="w-full bg-gray-50 border border-gray-200 rounded-[10px] px-3 py-2 font-bold text-gray-900"
                  >
                    <option value="Cảm biến đất">Cảm biến đất</option>
                    <option value="Trạm thời tiết">Trạm thời tiết</option>
                    <option value="IoT Gateway">IoT Gateway</option>
                    <option value="Van tự động">Van tự động</option>
                  </select>
                </div>

                <div>
                  <label className="block font-extrabold text-gray-700 mb-1">Huy hiệu (Badge)</label>
                  <input
                    type="text"
                    value={productForm.badge}
                    onChange={(e) => setProductForm({ ...productForm, badge: e.target.value })}
                    className="w-full bg-gray-50 border border-gray-200 rounded-[10px] px-3 py-2 font-bold text-gray-900"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-extrabold text-gray-700 mb-1">Giá bán lẻ (VNĐ) (*)</label>
                  <input
                    type="number"
                    required
                    value={productForm.price}
                    onChange={(e) => setProductForm({ ...productForm, price: Number(e.target.value) })}
                    className="w-full bg-gray-50 border border-gray-200 rounded-[10px] px-3 py-2 font-bold text-gray-900"
                  />
                </div>

                <div>
                  <label className="block font-extrabold text-gray-700 mb-1">Số lượng tồn kho (Bộ)</label>
                  <input
                    type="number"
                    value={productForm.stock}
                    onChange={(e) => setProductForm({ ...productForm, stock: Number(e.target.value) })}
                    className="w-full bg-gray-50 border border-gray-200 rounded-[10px] px-3 py-2 font-bold text-gray-900"
                  />
                </div>
              </div>

              <div>
                <label className="block font-extrabold text-gray-700 mb-1">URL Hình ảnh thực tế</label>
                <input
                  type="text"
                  value={productForm.imageUrl}
                  onChange={(e) => setProductForm({ ...productForm, imageUrl: e.target.value })}
                  className="w-full bg-gray-50 border border-gray-200 rounded-[10px] px-3 py-2 font-medium text-gray-900"
                />
              </div>

              <div>
                <label className="block font-extrabold text-gray-700 mb-1">Mô tả thông số kỹ thuật</label>
                <textarea
                  rows={3}
                  value={productForm.desc}
                  onChange={(e) => setProductForm({ ...productForm, desc: e.target.value })}
                  className="w-full bg-gray-50 border border-gray-200 rounded-[10px] p-2.5 font-medium text-gray-900"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-2 border-t border-gray-100">
                <button
                  type="button"
                  onClick={() => setIsProductModalOpen(false)}
                  className="px-4 py-2 bg-gray-100 text-gray-700 rounded-[10px] font-bold cursor-pointer hover:bg-gray-200"
                >
                  Hủy bỏ
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-[10px] font-black cursor-pointer shadow-sm"
                >
                  Lưu thay đổi
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* MODAL: ORDER DETAILS */}
      {selectedOrder && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-[24px] max-w-lg w-full p-6 shadow-2xl border border-gray-200 space-y-4">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <div>
                <h3 className="text-base font-black text-gray-900">Chi tiết Đơn hàng #{selectedOrder.order_code}</h3>
                <span className="text-xs text-gray-500 font-semibold">Ngày tạo: {selectedOrder.created_at}</span>
              </div>
              <button type="button" onClick={() => setSelectedOrder(null)} className="text-gray-400 hover:text-gray-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              <div className="p-3 bg-gray-50 rounded-[14px] space-y-1">
                <p className="font-extrabold text-gray-900">Khách hàng: <span className="text-emerald-800 font-black">{selectedOrder.user_name || "Chủ vườn sầu riêng"}</span></p>
                <p className="text-gray-600 font-medium">Nông trại: <span className="font-bold text-gray-900">{selectedOrder.farm_name}</span> ({selectedOrder.area_hectare} ha)</p>
                {selectedOrder.notes && <p className="text-amber-800 font-semibold pt-1">Ghi chú: "{selectedOrder.notes}"</p>}
              </div>

              <div className="border border-gray-200 rounded-[14px] overflow-hidden">
                <div className="bg-gray-100 px-3 py-2 font-bold text-gray-700 text-[11px] uppercase">Danh sách thiết bị mua</div>
                <div className="divide-y divide-gray-100">
                  {selectedOrder.items.map((it, idx) => (
                    <div key={idx} className="p-3 flex items-center justify-between">
                      <div>
                        <strong className="text-gray-900 block font-extrabold">{it.device_name}</strong>
                        <span className="text-gray-500 text-[10px]">Đơn giá: {it.unit_price.toLocaleString()} đ</span>
                      </div>
                      <span className="font-black text-emerald-800">x{it.quantity} = {(it.quantity * it.unit_price).toLocaleString()} đ</span>
                    </div>
                  ))}
                </div>
                <div className="bg-emerald-50 p-3 flex items-center justify-between border-t border-emerald-100 font-black text-sm">
                  <span className="text-emerald-900">Tổng thanh toán:</span>
                  <span className="text-amber-700">{selectedOrder.total_amount.toLocaleString()} đ</span>
                </div>
              </div>
            </div>

            <div className="flex items-center justify-between pt-2 border-t border-gray-100">
              <button
                type="button"
                onClick={() => setSelectedOrder(null)}
                className="px-4 py-2 bg-gray-100 text-gray-700 rounded-[10px] font-bold text-xs cursor-pointer"
              >
                Đóng
              </button>

              {selectedOrder.status === "Pending" && (
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => handleUpdateOrderStatus(selectedOrder.order_code, "Approved")}
                    className="px-4 py-2 bg-emerald-600 text-white rounded-[10px] font-black text-xs cursor-pointer shadow-sm"
                  >
                    Duyệt đơn này
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* MODAL: FAULT REPORT DETAILS & TECHNICAL ASSIGNMENT */}
      {selectedFaultReport && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-[24px] max-w-xl w-full p-6 shadow-2xl border border-gray-200 space-y-4 animate-in fade-in zoom-in duration-200">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <div>
                <h3 className="text-base font-black text-gray-900 flex items-center gap-2">
                  <AlertTriangle className="w-5 h-5 text-red-600" />
                  Báo Cáo Sự Cố Thiết Bị #{selectedFaultReport.report_code}
                </h3>
                <span className="text-xs text-gray-500 font-semibold">Gửi lúc: {selectedFaultReport.created_at}</span>
              </div>
              <button type="button" onClick={() => setSelectedFaultReport(null)} className="text-gray-400 hover:text-gray-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3 text-xs">
              {/* User & Farm Info */}
              <div className="p-3 bg-red-50/50 border border-red-100 rounded-[14px] flex items-start justify-between gap-3">
                <div className="space-y-1">
                  <p className="font-extrabold text-gray-900">
                    Chủ vườn báo hỏng: <span className="text-red-900 font-black">{selectedFaultReport.user_name}</span>
                  </p>
                  <p className="text-gray-600 font-medium flex items-center gap-1">
                    <PhoneCall className="w-3 h-3 text-gray-400" /> Điện thoại: <strong className="text-gray-900">{selectedFaultReport.phone}</strong>
                  </p>
                  <p className="text-gray-600 font-medium">
                    Nông trại: <strong className="text-gray-900">{selectedFaultReport.farm_name}</strong>
                  </p>
                </div>

                <div className="text-right">
                  <span className={`px-2.5 py-1 rounded-full text-[10px] border inline-block ${
                    SEVERITY_BADGES[selectedFaultReport.severity]?.bg || "bg-gray-100"
                  } ${SEVERITY_BADGES[selectedFaultReport.severity]?.color || "text-gray-700"}`}>
                    {selectedFaultReport.severity_label}
                  </span>
                </div>
              </div>

              {/* Fault Device Info & Photo */}
              <div className="grid grid-cols-1 sm:grid-cols-12 gap-3 p-3 bg-gray-50 rounded-[14px] border border-gray-100">
                <div className="sm:col-span-4 w-full h-28 bg-gray-200 rounded-[10px] overflow-hidden border border-gray-200">
                  <img src={selectedFaultReport.image_url} alt="Hư hại thiết bị" className="w-full h-full object-cover" />
                </div>
                <div className="sm:col-span-8 space-y-1">
                  <strong className="text-sm font-black text-gray-900 block">{selectedFaultReport.device_name}</strong>
                  <span className="text-[10px] font-mono text-emerald-800 bg-emerald-100 px-2 py-0.5 rounded-md inline-block font-bold">
                    Mã TB: {selectedFaultReport.device_code}
                  </span>
                  <p className="font-extrabold text-red-700 text-xs mt-1">Sự cố: "{selectedFaultReport.issue_title}"</p>
                  <p className="text-[11px] text-gray-600 leading-snug">{selectedFaultReport.issue_desc}</p>
                </div>
              </div>

              {/* Technician Assignment & Admin Notes */}
              <div className="space-y-2 pt-1">
                <div>
                  <label className="block font-extrabold text-gray-700 mb-1 flex items-center gap-1">
                    <UserCheck className="w-3.5 h-3.5 text-blue-600" />
                    Kỹ thuật viên phụ trách bảo hành:
                  </label>
                  <input
                    type="text"
                    value={reportTechnicianInput}
                    onChange={(e) => setReportTechnicianInput(e.target.value)}
                    placeholder="Nhập tên kỹ thuật viên (e.g. Đoàn Văn Nam - Kỹ thuật Đắk Lắk)"
                    className="w-full bg-gray-50 border border-gray-200 rounded-[10px] px-3 py-2 font-bold text-gray-900 text-xs focus:ring-2 focus:ring-amber-300 focus:outline-none"
                  />
                </div>

                <div>
                  <label className="block font-extrabold text-gray-700 mb-1 flex items-center gap-1">
                    <FileText className="w-3.5 h-3.5 text-gray-500" />
                    Ghi chú xử lý / Biên bản kiểm tra Admin:
                  </label>
                  <textarea
                    rows={2}
                    value={reportNotesInput}
                    onChange={(e) => setReportNotesInput(e.target.value)}
                    placeholder="Ghi chú kết quả kiểm tra hoặc linh kiện cần thay thế..."
                    className="w-full bg-gray-50 border border-gray-200 rounded-[10px] p-2 font-medium text-gray-900 text-xs"
                  />
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="flex flex-wrap items-center justify-between gap-2 pt-3 border-t border-gray-100">
              <button
                type="button"
                onClick={() => setSelectedFaultReport(null)}
                className="px-4 py-2 bg-gray-100 text-gray-700 rounded-[10px] font-bold text-xs cursor-pointer hover:bg-gray-200"
              >
                Đóng
              </button>

              <div className="flex items-center gap-2">
                {selectedFaultReport.status !== "Rejected" && (
                  <button
                    type="button"
                    onClick={() => handleUpdateFaultReportStatus(selectedFaultReport.report_code, "Rejected")}
                    className="px-3 py-2 bg-gray-200 text-gray-800 rounded-[10px] font-bold text-xs cursor-pointer hover:bg-gray-300"
                  >
                    Từ chối BH
                  </button>
                )}

                {selectedFaultReport.status === "Pending" && (
                  <button
                    type="button"
                    onClick={() => handleUpdateFaultReportStatus(selectedFaultReport.report_code, "In_Progress")}
                    className="px-4 py-2 bg-amber-600 hover:bg-amber-700 text-white rounded-[10px] font-black text-xs cursor-pointer shadow-sm flex items-center gap-1"
                  >
                    <Wrench className="w-3.5 h-3.5" /> Tiếp nhận & Phân công kỹ thuật
                  </button>
                )}

                {selectedFaultReport.status !== "Resolved" && (
                  <button
                    type="button"
                    onClick={() => handleUpdateFaultReportStatus(selectedFaultReport.report_code, "Resolved")}
                    className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-[10px] font-black text-xs cursor-pointer shadow-sm flex items-center gap-1"
                  >
                    <Check className="w-3.5 h-3.5" /> Xác nhận Đã Hoàn Tất Xử Lý
                  </button>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
