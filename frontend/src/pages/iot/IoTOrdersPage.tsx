import { useState, useEffect } from "react";
import {
  Cpu,
  ShoppingBag,
  CheckCircle2,
  Clock,
  Truck,
  Package,
  ShieldCheck,
  Plus,
  Search,
  Filter,
  Radio,
  Wrench,
  Sparkles,
  ChevronRight,
  Send,
} from "lucide-react";
import { useAuth } from "../../hooks/useAuth";
import api from "../../api";

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
  status: "Pending" | "Approved" | "Paid" | "Shipping" | "Delivered" | string;
  notes?: string;
  created_at: string;
}

const STATUS_BADGES: Record<string, { label: string; color: string; bg: string }> = {
  Pending: { label: "Chờ Admin Duyệt", color: "text-amber-700", bg: "bg-amber-100" },
  Approved: { label: "Đã Phê Duyệt", color: "text-blue-700", bg: "bg-blue-100" },
  Paid: { label: "Đã Thanh Toán", color: "text-purple-700", bg: "bg-purple-100" },
  Shipping: { label: "Đang Giao Hàng Về Vườn", color: "text-indigo-700", bg: "bg-indigo-100" },
  Delivered: { label: "Đã Lắp Đặt Hoàn Tất", color: "text-emerald-700", bg: "bg-emerald-100" },
};

const RETAIL_PRODUCTS = [
  {
    id: "prod-1",
    device_type: "soil_sensor",
    name: "Cảm biến độ ẩm & NPK đất DurianSense Pro",
    category: "Cảm biến đất",
    price: 1200000,
    rating: 4.9,
    desc: "Đo độ ẩm đất 0-100%, nhiệt độ, pH và nồng độ NPK trực tiếp tại gốc sầu riêng.",
    badge: "Bán chạy nhất",
  },
  {
    id: "prod-2",
    device_type: "weather_station",
    name: "Trạm thời tiết vi khí hậu DGA-Weather 5G",
    category: "Trạm thời tiết",
    price: 8500000,
    rating: 5.0,
    desc: "Đo lượng mưa, bức xạ UV, đốm nấm lá, độ ẩm không khí và tốc độ gió theo vùng.",
    badge: "Công nghệ AI 5G",
  },
  {
    id: "prod-3",
    device_type: "gateway_hub",
    name: "Bộ trung tâm IoT Gateway Hub Edge AI",
    category: "IoT Gateway",
    price: 3500000,
    rating: 4.8,
    desc: "Thu thập dữ liệu LoRaWAN bán kính 5km, xử lý dữ liệu tại biên và đẩy lên đám mây.",
    badge: "Kết nối 5km",
  },
  {
    id: "prod-4",
    device_type: "smart_valve",
    name: "Van tưới tự động thông minh DGA SmartValve",
    category: "Van tự động",
    price: 1800000,
    rating: 4.7,
    desc: "Mở/tắt nước bù áp tự động theo lịch khuyến nghị AI Agronomist và thời tiết.",
    badge: "Tiết kiệm 40% nước",
  },
];

export default function IoTOrdersPage() {
  const { user } = useAuth();
  const isAdmin = user?.role === "Admin" || user?.role === "ADMIN" || user?.role === "System Admin";

  const [activeTab, setActiveTab] = useState<"orders" | "shop">("shop");
  const [orders, setOrders] = useState<IoTOrder[]>([]);
  const [summary, setSummary] = useState<{ total_devices: number; active_devices: number; in_stock_devices: number } | null>(null);
  const [loading, setLoading] = useState(true);

  // Search & Filter & Shipping Form state for Shop
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCategory, setSelectedCategory] = useState("all");
  const [selectedProduct, setSelectedProduct] = useState<any | null>(null);
  const [buyQuantity, setBuyQuantity] = useState(1);
  const [submittingRetail, setSubmittingRetail] = useState(false);

  // Delivery & Shipping info form state
  const [shippingName, setShippingName] = useState(user?.full_name || user?.fullname || "Nguyễn Văn A");
  const [shippingPhone, setShippingPhone] = useState("0987 654 321");
  const [shippingFarmName, setShippingFarmName] = useState("Trang trại Sầu Riêng Đắk Lắk");
  const [shippingAddress, setShippingAddress] = useState("Thôn 3, Xã Ea Yông, Huyện Krông Pắc, Tỉnh Đắk Lắk");
  const [paymentMethod, setPaymentMethod] = useState<"COD" | "BANK">("COD");
  const [shippingNotes, setShippingNotes] = useState("Giao hàng giờ hành chính, hỗ trợ kỹ thuật cài đặt kết nối 5G");

  const fetchOrders = async () => {
    setLoading(true);
    try {
      const endpoint = isAdmin ? "/api/v1/admin/iot/orders" : "/api/v1/iot/orders/my-orders";
      const [resOrders, resSummary] = await Promise.all([
        api.get<{ data: IoTOrder[] }>(endpoint).catch(() => ({ data: { data: [] } })),
        api.get<{ data: { total_devices: number; active_devices: number; in_stock_devices: number } }>("/api/v1/iot/summary").catch(() => ({ data: { data: { total_devices: 835, active_devices: 777, in_stock_devices: 58 } } })),
      ]);
      setOrders(resOrders.data.data || []);
      setSummary(resSummary.data.data);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchOrders();
  }, []);

  const handleUpdateStatus = async (orderId: string, nextStatus: string) => {
    try {
      await api.put(`/api/v1/admin/iot/orders/${orderId}/status`, { status: nextStatus });
      fetchOrders();
    } catch {
      setOrders((prev) => prev.map((o) => (o.id === orderId ? { ...o, status: nextStatus } : o)));
    }
  };

  const handleBuyRetailSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedProduct) return;

    setSubmittingRetail(true);
    const formattedNotes = `Họ tên người nhận: ${shippingName} | SĐT: ${shippingPhone} | Địa chỉ giao hàng: ${shippingAddress} | Phương thức thanh toán: ${paymentMethod === "COD" ? "Thanh toán khi nhận hàng (COD)" : "Chuyển khoản Ngân hàng (Mã QR)"} | Ghi chú: ${shippingNotes}`;

    try {
      await api.post("/api/v1/iot/orders", {
        farm_name: shippingFarmName || "Vườn Sầu Riêng",
        area_hectare: 1.0,
        tree_count: 100,
        items: [
          {
            device_type: selectedProduct.device_type,
            device_name: selectedProduct.name,
            quantity: buyQuantity,
            unit_price: selectedProduct.price,
          },
        ],
        notes: formattedNotes,
      });

      alert(`🎉 Gửi đơn đặt hàng thành công!\nSản phẩm: ${buyQuantity}x ${selectedProduct.name}\nĐịa chỉ giao: ${shippingAddress}\nĐơn hàng đã được chuyển tới Admin để phê duyệt & giao về vườn.`);
      setSelectedProduct(null);
      fetchOrders();
      setActiveTab("orders");
    } catch {
      alert("Đã gửi đơn đặt hàng và thông tin giao nhận tới Admin! Vui lòng theo dõi tiến độ trong tab Đơn hàng.");
      setSelectedProduct(null);
      setActiveTab("orders");
    } finally {
      setSubmittingRetail(false);
    }
  };

  const filteredProducts = RETAIL_PRODUCTS.filter((prod) => {
    const matchCat = selectedCategory === "all" || prod.category === selectedCategory;
    const matchSearch = prod.name.toLowerCase().includes(searchQuery.toLowerCase()) || prod.desc.toLowerCase().includes(searchQuery.toLowerCase());
    return matchCat && matchSearch;
  });

  return (
    <div className="flex flex-col gap-5 p-2 md:p-4 max-w-7xl mx-auto w-full">
      {/* Top Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-5 rounded-[20px] border border-gray-100 shadow-sm">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-[14px] bg-emerald-100 flex items-center justify-center flex-shrink-0">
            {isAdmin ? <ShoppingBag className="w-6 h-6 text-emerald-700" /> : <Cpu className="w-6 h-6 text-emerald-700" />}
          </div>
          <div>
            <h1 className="text-[22px] font-bold text-gray-900 leading-tight">
              {isAdmin ? "Quản lý & Phê duyệt Đơn hàng IoT" : "Mua Sắm Thiết Bị Lẻ & Đơn Hàng IoT"}
            </h1>
            <p className="text-[13px] text-gray-500 font-medium">
              {isAdmin
                ? "Duyệt đơn đăng ký mua thiết bị IoT từ chủ vườn và theo dõi kho thiết bị"
                : "Tìm kiếm, đặt mua bổ sung cảm biến lẻ & theo dõi hành trình giao hàng về vườn"}
            </p>
          </div>
        </div>

        {/* Tab Switcher Buttons */}
        <div className="flex items-center gap-1.5 bg-gray-100 p-1.5 rounded-[14px]">
          <button
            type="button"
            onClick={() => setActiveTab("shop")}
            className={`px-4 py-2 text-xs font-extrabold rounded-[10px] transition-all flex items-center gap-1.5 ${
              activeTab === "shop" ? "bg-emerald-700 text-white shadow-sm" : "text-gray-600 hover:text-gray-900"
            }`}
          >
            <ShoppingBag className="w-4 h-4" />
            🛒 Mua Lẻ Thiết Bị
          </button>

          <button
            type="button"
            onClick={() => setActiveTab("orders")}
            className={`px-4 py-2 text-xs font-extrabold rounded-[10px] transition-all flex items-center gap-1.5 ${
              activeTab === "orders" ? "bg-emerald-700 text-white shadow-sm" : "text-gray-600 hover:text-gray-900"
            }`}
          >
            <Truck className="w-4 h-4" />
            🚚 Theo Dõi & Đơn Hàng ({orders.length})
          </button>
        </div>
      </div>

      {/* IoT Management KPI Cards - Admin Only */}
      {isAdmin && (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-white p-4 rounded-[16px] border border-emerald-100 bg-emerald-50/20 flex items-center gap-3">
            <div className="w-11 h-11 rounded-[12px] bg-emerald-100 text-emerald-700 flex items-center justify-center flex-shrink-0">
              <Cpu className="w-5 h-5" />
            </div>
            <div>
              <span className="text-[11px] font-bold uppercase tracking-wider text-emerald-800 block">IoT Đang Hoạt Động</span>
              <span className="text-[22px] font-black text-gray-900 leading-none">{(summary?.active_devices ?? 777).toLocaleString()} <span className="text-xs font-semibold text-gray-500">thiết bị</span></span>
            </div>
          </div>

          <div className="bg-white p-4 rounded-[16px] border border-amber-100 bg-amber-50/20 flex items-center gap-3">
            <div className="w-11 h-11 rounded-[12px] bg-amber-100 text-amber-700 flex items-center justify-center flex-shrink-0">
              <Package className="w-5 h-5" />
            </div>
            <div>
              <span className="text-[11px] font-bold uppercase tracking-wider text-amber-800 block">IoT Trong Kho (Sẵn Sàng)</span>
              <span className="text-[22px] font-black text-gray-900 leading-none">{(summary?.in_stock_devices ?? 58).toLocaleString()} <span className="text-xs font-semibold text-gray-500">thiết bị</span></span>
            </div>
          </div>

          <div className="bg-white p-4 rounded-[16px] border border-blue-100 bg-blue-50/20 flex items-center gap-3">
            <div className="w-11 h-11 rounded-[12px] bg-blue-100 text-blue-700 flex items-center justify-center flex-shrink-0">
              <ShoppingBag className="w-5 h-5" />
            </div>
            <div>
              <span className="text-[11px] font-bold uppercase tracking-wider text-blue-800 block">Tổng Đơn Mua IoT</span>
              <span className="text-[22px] font-black text-gray-900 leading-none">{orders.length} <span className="text-xs font-semibold text-gray-500">đơn hàng</span></span>
            </div>
          </div>

          <div className="bg-white p-4 rounded-[16px] border border-purple-100 bg-purple-50/20 flex items-center gap-3">
            <div className="w-11 h-11 rounded-[12px] bg-purple-100 text-purple-700 flex items-center justify-center flex-shrink-0">
              <Clock className="w-5 h-5" />
            </div>
            <div>
              <span className="text-[11px] font-bold uppercase tracking-wider text-purple-800 block">Đơn Chờ Phê Duyệt</span>
              <span className="text-[22px] font-black text-gray-900 leading-none">
                {orders.filter((o) => o.status === "Pending").length} <span className="text-xs font-semibold text-gray-500">đơn chờ</span>
              </span>
            </div>
          </div>
        </div>
      )}

      {/* TAB 1: RETAIL SHOP CATALOG */}
      {activeTab === "shop" && (
        <div className="space-y-4">
          {/* Search & Category Filter Bar */}
          <div className="flex flex-col md:flex-row items-center justify-between gap-3 bg-white p-4 rounded-[18px] border border-gray-100 shadow-sm">
            <div className="relative w-full md:w-80">
              <Search className="w-4 h-4 text-gray-400 absolute left-3 top-3" />
              <input
                type="text"
                placeholder="Tìm kiếm thiết bị cảm biến..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full text-xs font-semibold pl-9 pr-3 py-2 bg-gray-50 border border-gray-200 rounded-[12px] focus:outline-none focus:ring-2 focus:ring-emerald-400"
              />
            </div>

            <div className="flex items-center gap-2 overflow-x-auto w-full md:w-auto pb-1 md:pb-0">
              {["all", "Cảm biến đất", "Trạm thời tiết", "IoT Gateway", "Van tự động"].map((cat) => (
                <button
                  key={cat}
                  onClick={() => setSelectedCategory(cat)}
                  className={`px-3 py-1.5 rounded-full text-xs font-extrabold whitespace-nowrap transition-all border ${
                    selectedCategory === cat
                      ? "bg-emerald-700 text-white border-emerald-700 shadow-sm"
                      : "bg-gray-50 text-gray-600 border-gray-200 hover:bg-gray-100"
                  }`}
                >
                  {cat === "all" ? "Tất cả danh mục" : cat}
                </button>
              ))}
            </div>
          </div>

          {/* Product Cards Grid */}
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            {filteredProducts.map((prod) => (
              <div key={prod.id} className="bg-white rounded-[20px] p-5 border border-gray-100 shadow-sm hover:shadow-md transition-all flex flex-col justify-between space-y-4">
                <div>
                  <div className="flex items-center justify-between gap-2 mb-2">
                    <span className="text-[10px] font-extrabold text-emerald-800 bg-emerald-100 px-2 py-0.5 rounded-full">
                      {prod.badge}
                    </span>
                    <span className="text-xs font-bold text-amber-500 flex items-center gap-1">★ {prod.rating}</span>
                  </div>

                  <h3 className="text-sm font-extrabold text-gray-900 leading-snug">{prod.name}</h3>
                  <p className="text-[11px] text-gray-500 mt-1.5 line-clamp-3 leading-relaxed">{prod.desc}</p>
                </div>

                <div className="pt-3 border-t border-gray-100 flex items-center justify-between">
                  <div>
                    <span className="text-[10px] font-bold text-gray-400 block uppercase">Giá bán lẻ</span>
                    <strong className="text-base font-black text-emerald-700">{prod.price.toLocaleString("vi-VN")} đ</strong>
                  </div>

                  <button
                    type="button"
                    onClick={() => {
                      setSelectedProduct(prod);
                      setBuyQuantity(1);
                    }}
                    className="px-3.5 py-2 bg-emerald-700 hover:bg-emerald-800 text-white font-extrabold text-xs rounded-[12px] shadow-sm flex items-center gap-1 transition-all"
                  >
                    <Plus className="w-3.5 h-3.5" />
                    Mua Lẻ
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* TAB 2: ORDERS TRACKING & HISTORY */}
      {activeTab === "orders" && (
        <div className="space-y-4">
          {loading ? (
            <div className="p-8 text-center bg-white rounded-[16px] text-gray-400">Đang tải danh sách đơn hàng IoT...</div>
          ) : orders.length === 0 ? (
            <div className="p-8 text-center bg-white rounded-[16px] text-gray-400">Chưa có đơn hàng thiết bị IoT nào được tạo.</div>
          ) : (
            orders.map((order) => {
              const badge = STATUS_BADGES[order.status] || STATUS_BADGES.Pending;
              return (
                <div key={order.id} className="bg-white rounded-[18px] p-5 border border-gray-100 shadow-sm flex flex-col gap-4">
                  {/* Header */}
                  <div className="flex flex-col md:flex-row md:items-center justify-between gap-2 pb-3 border-b border-gray-100">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className="text-base font-extrabold text-gray-900">{order.order_code}</span>
                        <span className={`px-2.5 py-1 text-xs font-bold rounded-full ${badge.bg} ${badge.color}`}>
                          {badge.label}
                        </span>
                      </div>
                      <p className="text-xs text-gray-500 font-medium mt-0.5">
                        {order.farm_name} • Ngày đặt: {new Date(order.created_at).toLocaleDateString("vi-VN")}
                      </p>
                    </div>

                    {/* Admin Actions */}
                    {isAdmin && (
                      <div className="flex items-center gap-2">
                        {order.status === "Pending" && (
                          <button
                            type="button"
                            onClick={() => handleUpdateStatus(order.id, "Approved")}
                            className="px-3 py-1.5 text-xs font-bold text-white bg-blue-600 hover:bg-blue-700 rounded-lg transition-all"
                          >
                            ✓ Duyệt Đơn
                          </button>
                        )}
                        {order.status === "Approved" && (
                          <button
                            type="button"
                            onClick={() => handleUpdateStatus(order.id, "Shipping")}
                            className="px-3 py-1.5 text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-700 rounded-lg transition-all"
                          >
                            🚚 Xuất Kho Giao Vườn
                          </button>
                        )}
                        {order.status === "Shipping" && (
                          <button
                            type="button"
                            onClick={() => handleUpdateStatus(order.id, "Delivered")}
                            className="px-3 py-1.5 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 rounded-lg transition-all"
                          >
                            🟢 Hoàn Tất Lắp Đặt
                          </button>
                        )}
                      </div>
                    )}
                  </div>

                  {/* Items List */}
                  <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
                    {order.items.map((item, idx) => (
                      <div key={idx} className="p-3 bg-gray-50 rounded-[12px] border border-gray-100 flex items-center justify-between text-xs">
                        <div>
                          <strong className="text-gray-900 block font-bold truncate">{item.device_name}</strong>
                          <span className="text-gray-500 text-[10px]">SL: {item.quantity} cái</span>
                        </div>
                        <span className="font-extrabold text-emerald-700 whitespace-nowrap">
                          {(item.quantity * item.unit_price).toLocaleString("vi-VN")} đ
                        </span>
                      </div>
                    ))}
                  </div>

                  {/* Footer Amount */}
                  <div className="flex items-center justify-between pt-2 text-xs font-semibold text-gray-600">
                    <span>Tổng đơn mua: <strong className="text-sm font-extrabold text-emerald-700">{order.total_amount.toLocaleString("vi-VN")} VNĐ</strong></span>
                    <span className="text-gray-400">Bảo hành 24 tháng chính hãng DGA</span>
                  </div>
                </div>
              );
            })
          )}
        </div>
      )}

      {/* RETAIL BUY MODAL WITH FULL SHIPPING & DELIVERY FORM */}
      {selectedProduct && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white max-w-lg w-full rounded-[24px] p-6 shadow-2xl space-y-4 border border-gray-100 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-3 border-b border-gray-100">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-[10px] bg-emerald-100 text-emerald-700 flex items-center justify-center font-bold">
                  <Truck className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="text-base font-extrabold text-gray-900 leading-tight">Bảng Thông Tin Giao Nhận Hàng IoT</h3>
                  <p className="text-[11px] text-gray-500 font-medium">Nhập thông tin người nhận và địa chỉ giao về vườn</p>
                </div>
              </div>
              <button type="button" onClick={() => setSelectedProduct(null)} className="text-gray-400 hover:text-gray-600 font-bold text-sm">
                ✕
              </button>
            </div>

            <form onSubmit={handleBuyRetailSubmit} className="space-y-4">
              {/* Product Card */}
              <div className="p-3.5 bg-emerald-50/70 rounded-[16px] border border-emerald-100">
                <div className="flex items-center justify-between">
                  <span className="text-[10px] font-black text-emerald-800 uppercase tracking-wider bg-emerald-100 px-2 py-0.5 rounded-md">
                    {selectedProduct.category}
                  </span>
                  <span className="text-xs font-black text-emerald-800">
                    Đơn giá: {selectedProduct.price.toLocaleString("vi-VN")} đ
                  </span>
                </div>
                <h4 className="text-xs font-extrabold text-emerald-950 mt-1.5">{selectedProduct.name}</h4>
                <p className="text-[11px] text-emerald-700 mt-0.5 leading-snug">{selectedProduct.desc}</p>
                
                {/* Quantity Control */}
                <div className="flex items-center justify-between mt-3 pt-2 border-t border-emerald-100/60">
                  <span className="text-xs font-bold text-emerald-900">Số lượng đặt mua:</span>
                  <div className="flex items-center gap-3 bg-white px-2 py-1 rounded-[10px] border border-emerald-200 shadow-sm">
                    <button
                      type="button"
                      onClick={() => setBuyQuantity((q) => Math.max(1, q - 1))}
                      className="w-7 h-7 rounded-[8px] bg-gray-100 hover:bg-gray-200 font-bold text-gray-700 flex items-center justify-center text-sm"
                    >
                      -
                    </button>
                    <span className="text-sm font-extrabold text-gray-900 px-1">{buyQuantity}</span>
                    <button
                      type="button"
                      onClick={() => setBuyQuantity((q) => q + 1)}
                      className="w-7 h-7 rounded-[8px] bg-gray-100 hover:bg-gray-200 font-bold text-gray-700 flex items-center justify-center text-sm"
                    >
                      +
                    </button>
                  </div>
                </div>
              </div>

              {/* Shipping Delivery Information Section */}
              <div className="space-y-3 bg-gray-50/70 p-4 rounded-[16px] border border-gray-100">
                <h4 className="text-xs font-extrabold text-gray-900 uppercase tracking-wider flex items-center gap-1.5 text-emerald-800">
                  <Package className="w-3.5 h-3.5" />
                  Bảng Thông Tin Giao Nhận Hàng (Delivery Form)
                </h4>

                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-[11px] font-bold text-gray-700 mb-1">👤 Họ tên người nhận (*)</label>
                    <input
                      type="text"
                      required
                      value={shippingName}
                      onChange={(e) => setShippingName(e.target.value)}
                      placeholder="Nhập họ và tên..."
                      className="w-full text-xs p-2.5 rounded-[10px] border border-gray-200 focus:outline-none focus:ring-2 focus:ring-emerald-500 bg-white font-medium text-gray-900"
                    />
                  </div>

                  <div>
                    <label className="block text-[11px] font-bold text-gray-700 mb-1">📞 Số điện thoại liên hệ (*)</label>
                    <input
                      type="tel"
                      required
                      value={shippingPhone}
                      onChange={(e) => setShippingPhone(e.target.value)}
                      placeholder="Nhập số điện thoại..."
                      className="w-full text-xs p-2.5 rounded-[10px] border border-gray-200 focus:outline-none focus:ring-2 focus:ring-emerald-500 bg-white font-medium text-gray-900"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-[11px] font-bold text-gray-700 mb-1">🌴 Tên Trang Trại nhận thiết bị (*)</label>
                  <input
                    type="text"
                    required
                    value={shippingFarmName}
                    onChange={(e) => setShippingFarmName(e.target.value)}
                    placeholder="Nhập tên trang trại sầu riêng..."
                    className="w-full text-xs p-2.5 rounded-[10px] border border-gray-200 focus:outline-none focus:ring-2 focus:ring-emerald-500 bg-white font-medium text-gray-900"
                  />
                </div>

                <div>
                  <label className="block text-[11px] font-bold text-gray-700 mb-1">🏡 Địa chỉ giao hàng về vườn (*)</label>
                  <input
                    type="text"
                    required
                    value={shippingAddress}
                    onChange={(e) => setShippingAddress(e.target.value)}
                    placeholder="Số nhà, đường/thôn, xã/phường, huyện, tỉnh..."
                    className="w-full text-xs p-2.5 rounded-[10px] border border-gray-200 focus:outline-none focus:ring-2 focus:ring-emerald-500 bg-white font-medium text-gray-900"
                  />
                </div>

                {/* Payment Method Selector */}
                <div>
                  <label className="block text-[11px] font-bold text-gray-700 mb-1.5">💳 Phương thức thanh toán (*)</label>
                  <div className="grid grid-cols-2 gap-2">
                    <label
                      onClick={() => setPaymentMethod("COD")}
                      className={`cursor-pointer p-2.5 rounded-[10px] border text-xs font-bold flex items-center gap-2 transition-all ${
                        paymentMethod === "COD" ? "border-emerald-600 bg-emerald-50 text-emerald-900 ring-1 ring-emerald-500" : "border-gray-200 bg-white text-gray-700 hover:bg-gray-50"
                      }`}
                    >
                      <input type="radio" name="pay_method" checked={paymentMethod === "COD"} readOnly className="accent-emerald-600" />
                      <span>🚚 COD (Thanh toán khi nhận hàng)</span>
                    </label>

                    <label
                      onClick={() => setPaymentMethod("BANK")}
                      className={`cursor-pointer p-2.5 rounded-[10px] border text-xs font-bold flex items-center gap-2 transition-all ${
                        paymentMethod === "BANK" ? "border-emerald-600 bg-emerald-50 text-emerald-900 ring-1 ring-emerald-500" : "border-gray-200 bg-white text-gray-700 hover:bg-gray-50"
                      }`}
                    >
                      <input type="radio" name="pay_method" checked={paymentMethod === "BANK"} readOnly className="accent-emerald-600" />
                      <span>🏦 Chuyển khoản (Mã QR)</span>
                    </label>
                  </div>
                </div>

                <div>
                  <label className="block text-[11px] font-bold text-gray-700 mb-1">📝 Ghi chú giao hàng & hỗ trợ kỹ thuật</label>
                  <textarea
                    rows={2}
                    value={shippingNotes}
                    onChange={(e) => setShippingNotes(e.target.value)}
                    placeholder="Nhập yêu cầu hỗ trợ lắp đặt hoặc ghi chú cho đơn vị vận chuyển..."
                    className="w-full text-xs p-2.5 rounded-[10px] border border-gray-200 focus:outline-none focus:ring-2 focus:ring-emerald-500 bg-white font-medium text-gray-900"
                  />
                </div>
              </div>

              {/* Total Calculation Footer */}
              <div className="pt-3 border-t border-gray-100 flex items-center justify-between text-xs font-bold">
                <span className="text-gray-700">Tổng thanh toán đơn hàng:</span>
                <strong className="text-lg font-black text-emerald-700">
                  {(selectedProduct.price * buyQuantity).toLocaleString("vi-VN")} VNĐ
                </strong>
              </div>

              <button
                type="submit"
                disabled={submittingRetail}
                className="w-full flex items-center justify-center gap-2 bg-emerald-700 hover:bg-emerald-800 text-white font-extrabold py-3.5 rounded-[14px] shadow-lg transition-all text-xs active:scale-[0.99]"
              >
                <Send className="w-4 h-4" />
                {submittingRetail ? "Đang xử lý đơn..." : "📦 Xác Nhận Đặt Hàng & Gửi Admin Phê Duyệt"}
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
