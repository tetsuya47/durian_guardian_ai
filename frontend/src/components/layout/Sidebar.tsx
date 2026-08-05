import { useState, useEffect } from "react";
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
  AlertTriangle,
  ChevronLeft,
  ChevronRight,
  ChevronDown,
  Leaf,
  Cpu,
  ShieldAlert,
  ShoppingBag,
  Wrench,
  Bot,
  TrendingUp,
  Globe,
  Map,
  PlusCircle,
  Activity,
  CloudSun,
  BarChart3,
  FileText,
  Target,
  PieChart,
  CalendarPlus,
  UserPlus,
  CheckSquare,
} from "lucide-react";
import { useAuth } from "../../hooks/useAuth";

interface SidebarProps {
  collapsed: boolean;
  onToggle: () => void;
}

interface SubMenuItem {
  label: string;
  path: string;
  icon?: any;
}

interface MenuGroup {
  id: string;
  label: string;
  icon: any;
  path?: string;
  children?: SubMenuItem[];
}

const USER_MENU_GROUPS: MenuGroup[] = [
  {
    id: "home",
    label: "Trang chủ",
    path: "/home",
    icon: Home,
  },
  {
    id: "farm-mgmt",
    label: "Quản lý trang trại",
    icon: Sprout,
    children: [
      { label: "Trang trại của tôi", path: "/farms", icon: Building2 },
      { label: "Đăng ký trang trại mới", path: "/register-farm", icon: PlusCircle },
      { label: "Bảng điều khiển", path: "/dashboard", icon: LayoutDashboard },
      { label: "Lập kế hoạch công việc", path: "/work-planning", icon: CalendarPlus },
    ],
  },
  {
    id: "ai-mon",
    label: "AI & Giám sát",
    icon: Bot,
    children: [
      { label: "Cảnh báo AI", path: "/ai-alerts", icon: ShieldAlert },
    ],
  },
  {
    id: "analytics",
    label: "Phân tích",
    icon: TrendingUp,
    children: [
      { label: "Năng suất trang trại", path: "/farm-performance", icon: BarChart3 },
      { label: "Báo cáo", path: "/farm-performance", icon: FileText },
      { label: "Thống kê", path: "/farm-performance", icon: PieChart },
    ],
  },
  {
    id: "ecosystem",
    label: "Hệ sinh thái",
    icon: Globe,
    children: [
      { label: "Cộng đồng", path: "/community", icon: Users },
      { label: "Mua sắm & Đơn IoT", path: "/iot-shop", icon: ShoppingBag },
      { label: "Hướng dẫn lắp đặt", path: "/iot-setup-guide", icon: Wrench },
    ],
  },
];

export default function Sidebar({ collapsed, onToggle }: SidebarProps) {
  const location = useLocation();
  const currentPath = location.pathname;
  const { user } = useAuth();

  const isUserAdmin = user?.role === "Admin" || user?.role === "ADMIN" || user?.role === "System Admin";

  const adminMenuItems = [
    { label: "Bảng điều khiển", path: "/dashboard", icon: LayoutDashboard },
    { label: "Quản lý Người dùng", path: "/users", icon: Users },
    { label: "Quản lý Trang trại", path: "/farms", icon: Sprout },
    { label: "Quản lý Khu vực", path: "/zones", icon: Grid },
    { label: "Quản lý Cây trồng", path: "/trees", icon: TreePine },
    { label: "Năng suất Trang trại", path: "/farm-performance", icon: TrendingUp },
    { label: "Quản lý Thiết bị IoT", path: "/iot-management", icon: Cpu },
    { label: "Lượt Kiểm tra", path: "/inspections", icon: ClipboardCheck },
    { label: "Cảnh báo Hệ thống", path: "/alerts", icon: AlertTriangle },
  ];

  const [openGroupId, setOpenGroupId] = useState<string | null>(() => {
    const activeGroup = USER_MENU_GROUPS.find((g) =>
      g.children?.some(
        (child) =>
          currentPath === child.path ||
          (child.path !== "/" && child.path !== "/dashboard" && currentPath.startsWith(child.path))
      )
    );
    return activeGroup ? activeGroup.id : "ai-mon";
  });

  useEffect(() => {
    const activeGroup = USER_MENU_GROUPS.find((g) =>
      g.children?.some(
        (child) =>
          currentPath === child.path ||
          (child.path !== "/" && child.path !== "/dashboard" && currentPath.startsWith(child.path))
      )
    );
    if (activeGroup && activeGroup.id !== openGroupId) {
      setOpenGroupId(activeGroup.id);
    }
  }, [currentPath]);

  const toggleGroup = (groupId: string) => {
    setOpenGroupId((prev) => (prev === groupId ? null : groupId));
  };

  return (
    <aside
      className={`h-screen flex flex-col justify-between text-white flex-shrink-0 transition-all duration-200 lg:static absolute top-0 left-0 z-30 lg:translate-x-0 ${
        collapsed ? "max-lg:-translate-x-full" : "max-lg:translate-x-0"
      }`}
      style={{
        width: collapsed ? "72px" : "220px",
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
      <nav className="flex-1 overflow-y-auto py-4 px-3 space-y-1.5 no-scrollbar">
        {isUserAdmin ? (
          /* FLAT MENU FOR ADMIN */
          adminMenuItems.map((item) => {
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
                className={`flex items-center h-[46px] rounded-[12px] transition-colors ${
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
          })
        ) : (
          /* V2.0 ACCORDION 2-LEVEL MENU FOR WEB USER */
          USER_MENU_GROUPS.map((group) => {
            const GroupIcon = group.icon;
            const hasChildren = group.children && group.children.length > 0;
            const isOpen = openGroupId === group.id;

            const isGroupActive = hasChildren
              ? group.children?.some(
                  (c) =>
                    currentPath === c.path ||
                    (c.path !== "/" && c.path !== "/dashboard" && currentPath.startsWith(c.path))
                )
              : currentPath === group.path;

            if (!hasChildren && group.path) {
              return (
                <Link
                  key={group.id}
                  to={group.path}
                  title={collapsed ? group.label : undefined}
                  className={`flex items-center h-[46px] rounded-[12px] transition-all ${
                    collapsed ? "justify-center px-0" : "gap-3 px-3.5"
                  } ${
                    isGroupActive
                      ? "bg-[#1E8449] text-white font-black shadow-md"
                      : "text-emerald-100/80 hover:text-white hover:bg-emerald-900/40"
                  }`}
                >
                  <GroupIcon className="w-5 h-5 flex-shrink-0 text-emerald-400" />
                  {!collapsed && (
                    <span className="text-sm font-bold truncate">{group.label}</span>
                  )}
                </Link>
              );
            }

            return (
              <div key={group.id} className="space-y-1">
                {/* Level 1 Group Header */}
                <button
                  type="button"
                  onClick={() => toggleGroup(group.id)}
                  title={collapsed ? group.label : undefined}
                  className={`w-full flex items-center justify-between h-[46px] rounded-[12px] transition-all cursor-pointer ${
                    collapsed ? "justify-center px-0" : "px-3.5"
                  } ${
                    isGroupActive
                      ? "bg-emerald-900/70 text-white font-extrabold border-l-4 border-emerald-400"
                      : "text-emerald-100/80 hover:text-white hover:bg-emerald-900/40"
                  }`}
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <GroupIcon className={`w-5 h-5 flex-shrink-0 ${isGroupActive ? "text-emerald-300" : "text-emerald-400/80"}`} />
                    {!collapsed && (
                      <span className="text-sm font-bold truncate">{group.label}</span>
                    )}
                  </div>
                  {!collapsed && (
                    <ChevronDown
                      className={`w-4 h-4 text-emerald-300/80 transition-transform duration-200 ${
                        isOpen ? "rotate-180 text-white" : ""
                      }`}
                    />
                  )}
                </button>

                {/* Level 2 Submenu Items */}
                {isOpen && !collapsed && (
                  <div className="pl-4 space-y-1 py-1 border-l border-emerald-800/40 ml-4">
                    {group.children?.map((child, idx) => {
                      const ChildIcon = child.icon;
                      const isChildActive =
                        child.path === "/dashboard"
                          ? currentPath === "/" || currentPath === "/dashboard"
                          : currentPath === child.path;

                      return (
                        <Link
                          key={`${child.label}-${idx}`}
                          to={child.path}
                          className={`flex items-center gap-2.5 h-[38px] px-3 rounded-lg text-xs transition-all ${
                            isChildActive
                              ? "bg-[#1E8449] text-white font-black shadow-sm"
                              : "text-emerald-200/70 hover:text-white hover:bg-emerald-900/50 font-semibold"
                          }`}
                        >
                          {ChildIcon && <ChildIcon className="w-3.5 h-3.5 flex-shrink-0" />}
                          <span className="truncate">{child.label}</span>
                        </Link>
                      );
                    })}
                  </div>
                )}
              </div>
            );
          })
        )}
      </nav>

      {/* Bottom Collapse Button */}
      <div className="border-t border-emerald-900/40 p-3">
        <button
          onClick={onToggle}
          type="button"
          className="w-full flex items-center justify-center h-[44px] rounded-[12px] bg-emerald-950/40 hover:bg-emerald-950/70 text-emerald-300 hover:text-white transition-colors cursor-pointer"
          title={collapsed ? "Mở rộng menu" : "Thu gọn menu"}
        >
          {collapsed ? (
            <ChevronRight className="w-5 h-5" />
          ) : (
            <div className="flex items-center gap-2">
              <ChevronLeft className="w-5 h-5" />
              <span className="text-xs font-bold">Thu gọn menu</span>
            </div>
          )}
        </button>
      </div>
    </aside>
  );
}
