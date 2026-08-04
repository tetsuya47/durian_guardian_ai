import { Link, useLocation } from "react-router-dom";
import {
  Home,
  LayoutDashboard,
  Building2,
  Sprout,
  Grid,
  TreePine,
  Users,
  ClipboardCheck,
  Scan,
  History,
  AlertTriangle,
  Bug,
  ChevronLeft,
  ChevronRight,
  Leaf,
  Cpu,
  ShieldAlert,
  ShoppingBag,
  Wrench,
  Bot,
  TrendingUp,
} from "lucide-react";
import { useAuth } from "../../hooks/useAuth";

interface SidebarProps {
  collapsed: boolean;
  onToggle: () => void;
}

export default function Sidebar({ collapsed, onToggle }: SidebarProps) {
  const location = useLocation();
  const currentPath = location.pathname;
  const { user } = useAuth();

  const isUserAdmin = user?.role === "Admin" || user?.role === "ADMIN" || user?.role === "System Admin";

  const adminMenuItems = [
    { label: "Trang chủ", path: "/home", icon: Home },
    { label: "Bảng điều khiển", path: "/dashboard", icon: LayoutDashboard },
    { label: "Chatbot Trợ lý AI", path: "/ai-chatbot", icon: Bot },
    { label: "Quản lý Người dùng", path: "/users", icon: Users },
    { label: "Quản lý Trang trại", path: "/farms", icon: Sprout },
    { label: "Quản lý Khu vực", path: "/zones", icon: Grid },
    { label: "Quản lý Cây trồng", path: "/trees", icon: TreePine },
    { label: "Năng suất Trang trại", path: "/farm-performance", icon: TrendingUp },
    { label: "Quản lý Thiết bị IoT", path: "/iot-management", icon: Cpu },
    { label: "Lượt Kiểm tra", path: "/inspections", icon: ClipboardCheck },
    { label: "Cảnh báo Hệ thống", path: "/alerts", icon: AlertTriangle },
  ];

  const userMenuItems = [
    { label: "Trang chủ", path: "/home", icon: Home },
    { label: "👥 Cộng đồng Nông dân", path: "/community", icon: Users },
    { label: "Bảng điều khiển Vườn", path: "/dashboard", icon: LayoutDashboard },
    { label: "Chatbot Trợ lý AI", path: "/ai-chatbot", icon: Bot },
    { label: "🌱 Đăng ký Vườn mới", path: "/register-farm", icon: Sprout },
    { label: "📈 Năng suất Trang trại", path: "/farm-performance", icon: TrendingUp },
    { label: "📡 Thiết bị IoT của Vườn", path: "/my-iot-devices", icon: Cpu },
    { label: "🛒 Mua sắm & Đơn IoT", path: "/iot-shop", icon: ShoppingBag },
    { label: "🛠️ Hướng dẫn Lắp đặt", path: "/iot-setup-guide", icon: Wrench },
    { label: "🚨 Cảnh báo AI", path: "/ai-alerts", icon: ShieldAlert },
    { label: "Trang trại của tôi", path: "/farms", icon: Building2 },
  ];

  const menuItems = isUserAdmin ? adminMenuItems : userMenuItems;

  return (
    <aside
      className={`h-screen flex flex-col justify-between text-white flex-shrink-0 transition-all duration-200 lg:static absolute top-0 left-0 z-30 lg:translate-x-0 ${
        collapsed ? "max-lg:-translate-x-full" : "max-lg:translate-x-0"
      }`}
      style={{
        width: collapsed ? "72px" : "210px",
        backgroundColor: "#0F3D2E",
      }}
    >
      {/* Top Vie-farm Logo */}
      <div className={`flex items-center h-[72px] border-b border-emerald-900/40 ${collapsed ? "justify-center px-0" : "px-5 gap-3"}`}>
        <Leaf className="w-6 h-6 text-emerald-400 flex-shrink-0" />
        {!collapsed && (
          <span className="font-bold text-base tracking-wider text-emerald-50 truncate">
            Vie-farm Portal
          </span>
        )}
      </div>

      {/* Middle Menu */}
      <nav className="flex-1 overflow-y-auto py-5 px-3 space-y-1.5">
        {menuItems.map((item) => {
            const Icon = item.icon;
            const isActive =
              item.path === "/dashboard"
                ? currentPath === "/" || currentPath === "/dashboard"
                : currentPath === item.path || currentPath.startsWith(item.path + "/");
            return (
              <Link
                key={item.label}
                to={item.path}
                title={collapsed ? item.label : undefined}
                className={`flex items-center h-[48px] rounded-[12px] transition-colors ${
                  collapsed ? "justify-center px-0" : "gap-3 px-3.5"
                } ${
                  isActive
                    ? "bg-[#1E8449] text-white font-semibold shadow-[0_2px_8px_rgba(30,132,73,0.2)]"
                    : "text-emerald-100/70 hover:text-white hover:bg-emerald-950/20"
                }`}
              >
                <Icon className="w-5 h-5 flex-shrink-0" />
                {!collapsed && (
                  <span className="text-sm font-medium leading-none truncate">
                    {item.label}
                  </span>
                )}
              </Link>
            );
          })}
      </nav>

      {/* Bottom Collapse Button */}
      <div className="border-t border-emerald-900/40 p-3">
        <button
          onClick={onToggle}
          type="button"
          className="w-full flex items-center justify-center h-[48px] rounded-[12px] bg-emerald-950/40 hover:bg-emerald-950/70 text-emerald-300 hover:text-white transition-colors"
          title={collapsed ? "Mở rộng menu" : "Thu gọn menu"}
        >
          {collapsed ? (
            <ChevronRight className="w-5 h-5" />
          ) : (
            <div className="flex items-center gap-2">
              <ChevronLeft className="w-5 h-5" />
              <span className="text-xs font-medium">Thu gọn menu</span>
            </div>
          )}
        </button>
      </div>
    </aside>
  );
}
