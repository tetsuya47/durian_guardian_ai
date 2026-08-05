import { useState, useEffect, useRef } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { Menu, Search, Bell, ChevronDown } from "lucide-react";
import { alertService } from "@/services/alert.service";
import { formatDateTime } from "@/utils/dateFormatter";
import { useAuth } from "@/hooks/useAuth";
import type { Alert } from "@/types/alert";

interface HeaderProps {
  onToggleSidebar: () => void;
}

export default function Header({ onToggleSidebar }: HeaderProps) {
  const location = useLocation();
  const navigate = useNavigate();
  const { user, logout } = useAuth();
  const currentPath = location.pathname;

  const [searchQuery, setSearchQuery] = useState("");
  const [notifOpen, setNotifOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);
  const [alerts, setAlerts] = useState<Alert[]>([]);

  const userName = user?.full_name || "Nguyễn Văn A";
  const userRole = user?.role === "ADMIN" ? "Administrator" : "Chủ trang trại";

  const notifRef = useRef<HTMLDivElement>(null);
  const profileRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    alertService
      .get<Alert[]>({ params: { per_page: 50 } })
      .then((data) => setAlerts(data))
      .catch(() => {});
  }, []);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      const target = e.target as Node;
      if (notifRef.current && !notifRef.current.contains(target)) setNotifOpen(false);
      if (profileRef.current && !profileRef.current.contains(target)) setProfileOpen(false);
    };
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  const handleSearch = (e: React.FormEvent) => {
    e.preventDefault();
    const q = searchQuery.trim();
    if (q) {
      navigate(`/trees?search=${encodeURIComponent(q)}`);
      setSearchQuery("");
    }
  };

  const handleLogout = async () => {
    await logout();
    navigate("/login", { replace: true });
  };

  const userInitials = userName
    .split(" ")
    .map((w) => w[0])
    .slice(0, 2)
    .join("")
    .toUpperCase() || "NV";

  const highAlertCount = alerts.filter(
    (a) => (a.priority || "").toLowerCase() === "high",
  ).length;
  const badgeCount = highAlertCount > 0 ? highAlertCount : 3;

  const recentAlerts = [...alerts]
    .sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())
    .slice(0, 5);

  const getBreadcrumbLabel = (path: string) => {
    if (path === "/home" || path === "/") return "HOME";
    if (path === "/dashboard") return "BẢNG ĐIỀU KHIỂN";
    if (path === "/farms") return "TRANG TRẠI";
    return path.split("/").pop()?.toUpperCase() || "PORTAL";
  };

  return (
    <header
      className="bg-white border-b border-gray-100 flex items-center justify-between px-4 lg:px-6 flex-shrink-0 select-none z-30"
      style={{ height: "72px" }}
    >
      {/* Left side: Hamburger & Breadcrumb */}
      <div className="flex items-center gap-4">
        <button
          onClick={onToggleSidebar}
          type="button"
          className="w-10 h-10 rounded-[12px] flex items-center justify-center text-gray-600 hover:bg-gray-100 transition-all cursor-pointer"
        >
          <Menu className="w-5 h-5" />
        </button>

        <div className="flex items-center text-xs font-semibold text-gray-400 gap-2">
          <span>PORTAL</span>
          <span className="text-gray-300">/</span>
          <span className="text-gray-900 font-black tracking-wider">
            {getBreadcrumbLabel(currentPath)}
          </span>
        </div>
      </div>

      {/* Right side: Quick Search Bar, Notifications, User Profile Pill */}
      <div className="flex items-center gap-3">
        {/* Quick Search Input */}
        <form onSubmit={handleSearch} className="relative w-48 sm:w-64">
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Tìm kiếm nhanh..."
            className="w-full pl-3.5 pr-9 py-2 text-xs bg-gray-50 border border-gray-200 rounded-[12px] focus:outline-none focus:ring-2 focus:ring-[#118D57] font-medium text-gray-800 placeholder-gray-400 shadow-2xs"
          />
          <button type="submit" className="absolute right-2.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
            <Search className="w-4 h-4" />
          </button>
        </form>

        {/* Notification Bell Badge */}
        <div ref={notifRef} className="relative">
          <button
            type="button"
            onClick={() => setNotifOpen((o) => !o)}
            className="w-9 h-9 rounded-full bg-gray-100 hover:bg-emerald-50 text-gray-700 flex items-center justify-center relative transition-all cursor-pointer"
          >
            <Bell className="w-4 h-4" />
            <span className="absolute -top-0.5 -right-0.5 min-w-[16px] h-[16px] px-1 flex items-center justify-center rounded-full bg-emerald-600 text-white text-[10px] font-black leading-none shadow-xs">
              {badgeCount}
            </span>
          </button>

          {notifOpen && (
            <div className="absolute right-0 top-full mt-2 w-80 bg-white border border-gray-200 rounded-[12px] shadow-lg z-50 overflow-hidden">
              <div className="px-4 py-3 border-b border-gray-100">
                <span className="text-xs font-bold text-gray-800">Thông báo mới</span>
              </div>
              <div className="max-h-80 overflow-y-auto">
                {recentAlerts.length === 0 ? (
                  <div className="px-4 py-6 text-center text-xs text-gray-400">
                    Chưa có thông báo mới
                  </div>
                ) : (
                  recentAlerts.map((a) => (
                    <div
                      key={a._id}
                      className="px-4 py-3 border-b border-gray-50 hover:bg-gray-50 transition-colors cursor-pointer"
                      onClick={() => {
                        navigate("/ai-alerts");
                        setNotifOpen(false);
                      }}
                    >
                      <p className="text-xs font-bold text-gray-800">{a.title}</p>
                      <p className="text-[11px] text-gray-400 mt-0.5">{formatDateTime(a.created_at)}</p>
                    </div>
                  ))
                )}
              </div>
            </div>
          )}
        </div>

        {/* User Profile Pill */}
        <div ref={profileRef} className="relative">
          <button
            type="button"
            onClick={() => setProfileOpen((o) => !o)}
            className="flex items-center gap-2 pl-1 pr-2 py-1 rounded-full hover:bg-gray-50 transition-all cursor-pointer"
          >
            <div className="w-8 h-8 rounded-full bg-gray-600 text-white flex items-center justify-center text-xs font-bold shadow-xs">
              {userInitials}
            </div>
            <div className="text-left hidden sm:block">
              <div className="text-xs font-black text-gray-900 leading-tight">{userName}</div>
              <div className="text-[10px] text-gray-500 font-medium">{userRole}</div>
            </div>
            <ChevronDown className="w-3.5 h-3.5 text-gray-400 hidden sm:block" />
          </button>

          {profileOpen && (
            <div className="absolute right-0 top-full mt-2 w-48 bg-white border border-gray-200 rounded-[12px] shadow-lg z-50 overflow-hidden">
              <div className="px-4 py-3 border-b border-gray-100">
                <p className="text-xs font-bold text-gray-900">{userName}</p>
                <p className="text-[10px] text-gray-500">{userRole}</p>
              </div>
              <div className="py-1">
                <button
                  type="button"
                  onClick={handleLogout}
                  className="w-full px-4 py-2 text-left text-xs font-bold text-rose-600 hover:bg-rose-50 transition-colors"
                >
                  Đăng xuất
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
}
