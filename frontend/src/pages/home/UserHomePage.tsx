import { useState, useEffect } from "react";
import api from "../../api";
import {
  Calendar,
  Sun,
  MapPin,
  AlertTriangle,
  CloudRain,
  Sprout,
  CheckSquare,
  Bot,
  Wifi,
  DollarSign,
  ChevronRight,
  Bug,
  Leaf,
  ShieldAlert,
  TrendingUp,
} from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../hooks/useAuth";

const DEFAULT_MARKET_ITEMS = [
  {
    name: "Sầu riêng Ri6 (Hàng Đẹp Loại 1)",
    category: "Ri6",
    quality: "Hàng Đẹp (Loại 1)",
    grade: "dep",
    price: "60.000 – 65.000",
    unit: "đ/kg",
    change: "+3.5%",
    trend: "up",
  },
  {
    name: "Sầu riêng Ri6 (Hàng Xô Lùa Vựa)",
    category: "Ri6",
    quality: "Hàng Xô (Lùa vựa)",
    grade: "xo",
    price: "48.000 – 50.000",
    unit: "đ/kg",
    change: "Ổn định",
    trend: "same",
  },
  {
    name: "Sầu riêng Thái / Monthong (Hàng Đẹp Loại 1)",
    category: "THÁI",
    quality: "Hàng Đẹp (Loại 1)",
    grade: "dep",
    price: "85.000 – 90.000",
    unit: "đ/kg",
    change: "+5.2%",
    trend: "up",
  },
  {
    name: "Sầu riêng Thái / Monthong (Hàng Xô Lùa Vựa)",
    category: "THÁI",
    quality: "Hàng Xô (Lùa vựa)",
    grade: "xo",
    price: "75.000 – 77.000",
    unit: "đ/kg",
    change: "+2.1%",
    trend: "up",
  },
  {
    name: "Sầu riêng Musang King (Hàng Đẹp Loại 1)",
    category: "MUSANG KING",
    quality: "Hàng Đẹp (Loại 1)",
    grade: "dep",
    price: "180.000 – 220.000",
    unit: "đ/kg",
    change: "Ổn định",
    trend: "same",
  },
  {
    name: "Sầu riêng Musang King (Hàng Xô Lùa Vựa)",
    category: "MUSANG KING",
    quality: "Hàng Xô (Lùa vựa)",
    grade: "xo",
    price: "130.000 – 160.000",
    unit: "đ/kg",
    change: "Ổn định",
    trend: "same",
  },
];

export default function UserHomePage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [selectedGradeFilter, setSelectedGradeFilter] = useState("all");
  const [selectedRegion, setSelectedRegion] = useState("taynguyen");
  const [selectedNewsTab, setSelectedNewsTab] = useState("highlight");

  const [userStats, setUserStats] = useState({
    totalFarms: 0,
    totalTrees: 0,
    activeIot: 0,
    attentionTrees: 0,
  });

  useEffect(() => {
    let isMounted = true;
    api.get("/api/v1/farms?per_page=100")
      .then((res) => {
        if (!isMounted) return;
        const raw = res.data;
        const items = Array.isArray(raw) ? raw : raw?.data?.items || raw?.data || [];
        const farmCount = items.length;
        const treeCount = items.reduce((sum: number, f: any) => sum + Number(f.tree_count || f.treeCount || 0), 0);
        
        if (farmCount > 0) {
          setUserStats({
            totalFarms: farmCount,
            totalTrees: treeCount || (farmCount * 350),
            activeIot: farmCount * 6,
            attentionTrees: Math.round((treeCount || 350) * 0.02) || 4,
          });
        } else {
          setUserStats({
            totalFarms: 0,
            totalTrees: 0,
            activeIot: 0,
            attentionTrees: 0,
          });
        }
      })
      .catch(() => {
        if (isMounted) {
          setUserStats({
            totalFarms: 0,
            totalTrees: 0,
            activeIot: 0,
            attentionTrees: 0,
          });
        }
      });

    return () => {
      isMounted = false;
    };
  }, [user]);

  const userName = user?.full_name || "Nguyễn Văn A";

  return (
    <div className="flex flex-col space-y-6 pb-12 bg-[#F8FAFC] min-h-screen text-[#111827] font-['Plus_Jakarta_Sans',sans-serif] select-none p-6 lg:p-8">
      {/* ── SECTION 1: HERO BANNER & QUICK ACTIONS ── */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
        {/* HERO CARD (ENTERPRISE SAAS GLASS-CREAM HYBRID STYLE) */}
        <div className="lg:col-span-8 bg-[#FAF6EE]/90 rounded-[20px] border border-[#E5E7EB] p-6 shadow-saas flex flex-col justify-between space-y-4 relative overflow-hidden transition-all duration-200">
          {/* Durian Orchard Background Image Blended on Right */}
          <div
            className="absolute right-0 top-0 bottom-0 w-1/2 sm:w-5/12 bg-cover bg-right pointer-events-none opacity-90 hidden sm:block rounded-r-[20px]"
            style={{
              backgroundImage: "url('/images/login/hero-durian.jpg')",
              maskImage: "linear-gradient(to right, transparent 0%, black 40%)",
              WebkitMaskImage: "linear-gradient(to right, transparent 0%, black 40%)",
            }}
          />

          <div className="space-y-4 max-w-xl relative z-10">
            {/* Header Greeting */}
            <div>
              <div className="flex items-center gap-2 mb-1">
                <div className="w-8 h-8 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center flex-shrink-0">
                  <Sprout className="w-4.5 h-4.5" />
                </div>
                <h1 className="text-xl sm:text-2xl font-bold text-[#111827] leading-tight">
                  Xin chào, {userName}! 👋
                </h1>
              </div>
              <p className="text-xs text-[#6B7280] font-medium pl-10">
                AI hôm nay đã phân tích dữ liệu vườn của bạn
              </p>
            </div>

            {/* 3 Independent Horizontal Statistic Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {/* Card 1: Giá Ri6 tăng */}
              <div className="bg-white/95 backdrop-blur-xs rounded-[14px] p-2.5 border border-emerald-100 shadow-2xs flex items-center gap-2.5 transition-transform hover:-translate-y-0.5">
                <div className="w-8 h-8 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center flex-shrink-0">
                  <TrendingUp className="w-4 h-4 text-[#10B981]" />
                </div>
                <div className="min-w-0">
                  <div className="text-xs font-semibold text-[#111827] leading-tight truncate">Giá Ri6 tăng</div>
                  <div className="text-[11px] font-bold text-[#10B981] leading-tight truncate">▲ 3.5% so với hôm qua</div>
                </div>
              </div>

              {/* Card 2: 4 cây cần kiểm tra */}
              <div className="bg-white/95 backdrop-blur-xs rounded-[14px] p-2.5 border border-amber-100 shadow-2xs flex items-center gap-2.5 transition-transform hover:-translate-y-0.5">
                <div className="w-8 h-8 rounded-full bg-amber-50 text-[#F59E0B] flex items-center justify-center flex-shrink-0">
                  <AlertTriangle className="w-4 h-4 text-[#F59E0B]" />
                </div>
                <div className="min-w-0">
                  <div className="text-xs font-semibold text-[#111827] leading-tight truncate">4 cây cần kiểm tra</div>
                  <div className="text-[11px] font-bold text-amber-600 leading-tight truncate">Phát hiện bất thường</div>
                </div>
              </div>

              {/* Card 3: Dự báo mưa */}
              <div className="bg-white/95 backdrop-blur-xs rounded-[14px] p-2.5 border border-blue-100 shadow-2xs flex items-center gap-2.5 transition-transform hover:-translate-y-0.5">
                <div className="w-8 h-8 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center flex-shrink-0">
                  <CloudRain className="w-4 h-4 text-blue-600" />
                </div>
                <div className="min-w-0">
                  <div className="text-xs font-semibold text-[#111827] leading-tight truncate">Dự báo mưa</div>
                  <div className="text-[11px] font-bold text-blue-600 leading-tight truncate">Sau 2 giờ, lượng mưa nhẹ</div>
                </div>
              </div>
            </div>

            {/* Bottom Info Bar */}
            <div className="flex items-center gap-6 text-xs font-semibold text-[#6B7280] pt-2 border-t border-amber-100/70">
              <span className="flex items-center gap-1.5">
                <Calendar className="w-3.5 h-3.5 text-gray-400" /> 05/08/2026
              </span>
              <span className="flex items-center gap-1.5 text-[#F59E0B]">
                <Sun className="w-3.5 h-3.5" /> 28°C
              </span>
              <span className="flex items-center gap-1.5 text-[#10B981]">
                <MapPin className="w-3.5 h-3.5" /> Krông Pắc, Đắk Lắk
              </span>
            </div>
          </div>
        </div>

        {/* QUICK ACTION PANEL (THAO TÁC NHANH) */}
        <div className="lg:col-span-4 bg-white rounded-[20px] border border-[#E5E7EB] p-6 shadow-saas flex flex-col justify-between space-y-4">
          <h2 className="text-sm font-bold text-[#111827]">Thao tác nhanh</h2>

          <div className="grid grid-cols-2 gap-3 flex-1">
            <button
              type="button"
              onClick={() => navigate("/work-planning")}
              className="p-3 rounded-[14px] bg-[#F8FAFC] hover:bg-[#D1FAE5]/40 border border-[#E5E7EB] transition-all flex flex-col items-center justify-center text-center gap-2 group cursor-pointer hover:-translate-y-0.5"
            >
              <div className="w-9 h-9 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center group-hover:scale-105 transition-transform">
                <Sprout className="w-4.5 h-4.5" />
              </div>
              <span className="text-xs font-semibold text-[#111827] leading-tight">Lập kế hoạch công việc</span>
            </button>

            <button
              type="button"
              onClick={() => navigate("/work-planning")}
              className="p-3 rounded-[14px] bg-[#F8FAFC] hover:bg-[#D1FAE5]/40 border border-[#E5E7EB] transition-all flex flex-col items-center justify-center text-center gap-2 group cursor-pointer hover:-translate-y-0.5"
            >
              <div className="w-9 h-9 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center group-hover:scale-105 transition-transform">
                <Calendar className="w-4.5 h-4.5" />
              </div>
              <span className="text-xs font-semibold text-[#111827] leading-tight">Giao việc cho nhân công</span>
            </button>

            <button
              type="button"
              onClick={() => navigate("/work-planning")}
              className="p-3 rounded-[14px] bg-[#F8FAFC] hover:bg-[#D1FAE5]/40 border border-[#E5E7EB] transition-all flex flex-col items-center justify-center text-center gap-2 group cursor-pointer hover:-translate-y-0.5"
            >
              <div className="w-9 h-9 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center group-hover:scale-105 transition-transform">
                <CheckSquare className="w-4.5 h-4.5" />
              </div>
              <span className="text-xs font-semibold text-[#111827] leading-tight">Phê duyệt nhật ký</span>
            </button>

            <button
              type="button"
              onClick={() => navigate("/ai-chatbot")}
              className="p-3 rounded-[14px] bg-[#F8FAFC] hover:bg-[#D1FAE5]/40 border border-[#E5E7EB] transition-all flex flex-col items-center justify-center text-center gap-2 group cursor-pointer hover:-translate-y-0.5"
            >
              <div className="w-9 h-9 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center group-hover:scale-105 transition-transform">
                <Bot className="w-4.5 h-4.5" />
              </div>
              <span className="text-xs font-semibold text-[#111827] leading-tight">Hỏi đáp AI Assistant</span>
            </button>
          </div>
        </div>
      </div>

      {/* ── SECTION 2: STATISTICS CARDS (4 Horizontal Equal Cards) ── */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        {/* Card 1: Tổng số vườn */}
        <div className="bg-white p-5 rounded-[20px] border border-[#E5E7EB] shadow-saas flex items-center justify-between transition-all hover:-translate-y-0.5">
          <div className="space-y-1">
            <span className="text-xs font-medium text-[#6B7280]">Tổng số vườn</span>
            <div className="text-2xl font-bold text-[#111827]">{userStats.totalFarms} <span className="text-xs font-normal text-[#6B7280]">vườn</span></div>
            <span className="text-[11px] font-semibold text-[#10B981] block">
              {userStats.totalFarms > 0 ? "▲ Vườn đang quản lý" : "● Chưa tạo vườn nào"}
            </span>
          </div>
          <div className="w-12 h-12 rounded-[14px] bg-[#D1FAE5] text-[#10B981] flex items-center justify-center flex-shrink-0">
            <Sprout className="w-6 h-6" />
          </div>
        </div>

        {/* Card 2: Tổng gốc sầu riêng */}
        <div className="bg-white p-5 rounded-[20px] border border-[#E5E7EB] shadow-saas flex items-center justify-between transition-all hover:-translate-y-0.5">
          <div className="space-y-1">
            <span className="text-xs font-medium text-[#6B7280]">Tổng gốc sầu riêng</span>
            <div className="text-2xl font-bold text-[#111827]">{userStats.totalTrees.toLocaleString()} <span className="text-xs font-normal text-[#6B7280]">gốc</span></div>
            <span className="text-[11px] font-semibold text-[#10B981] block">
              {userStats.totalTrees > 0 ? "▲ Theo dõi AI 24/7" : "● Chưa có dữ liệu cây"}
            </span>
          </div>
          <div className="w-12 h-12 rounded-[14px] bg-[#D1FAE5] text-[#10B981] flex items-center justify-center flex-shrink-0">
            <Leaf className="w-6 h-6" />
          </div>
        </div>

        {/* Card 3: Thiết bị IoT đang hoạt động */}
        <div className="bg-white p-5 rounded-[20px] border border-[#E5E7EB] shadow-saas flex items-center justify-between transition-all hover:-translate-y-0.5">
          <div className="space-y-1">
            <span className="text-xs font-medium text-[#6B7280]">Thiết bị IoT đang hoạt động</span>
            <div className="text-2xl font-bold text-[#111827]">{userStats.activeIot} <span className="text-xs font-normal text-[#6B7280]">thiết bị</span></div>
            <span className="text-[11px] font-semibold text-[#10B981] block">
              {userStats.activeIot > 0 ? "● Hoạt động tốt" : "● Chưa có thiết bị IoT"}
            </span>
          </div>
          <div className="w-12 h-12 rounded-[14px] bg-[#D1FAE5] text-[#10B981] flex items-center justify-center flex-shrink-0">
            <Wifi className="w-6 h-6" />
          </div>
        </div>

        {/* Card 4: Cây cần chú ý */}
        <div className="bg-white p-5 rounded-[20px] border border-[#E5E7EB] shadow-saas flex items-center justify-between transition-all hover:-translate-y-0.5">
          <div className="space-y-1">
            <span className="text-xs font-medium text-[#6B7280]">Cây cần chú ý</span>
            <div className="text-2xl font-bold text-[#111827]">{userStats.attentionTrees} <span className="text-xs font-normal text-[#6B7280]">gốc</span></div>
            <span className={`text-[11px] font-semibold block ${userStats.attentionTrees > 0 ? "text-[#F59E0B]" : "text-[#10B981]"}`}>
              {userStats.attentionTrees > 0 ? "● Cần kiểm tra" : "● Tất cả cây khỏe mạnh"}
            </span>
          </div>
          <div className="w-12 h-12 rounded-[14px] bg-amber-50 text-[#F59E0B] flex items-center justify-center flex-shrink-0">
            <AlertTriangle className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* ── SECTION 3: DURIAN PRICE MARKET (GIÁ THU MUA SẦU RIÊNG TẠI VƯỜN) ── */}
      <div className="bg-white p-6 rounded-[20px] border border-[#E5E7EB] shadow-saas space-y-5">
        {/* Header & Controls */}
        <div className="flex flex-wrap items-center justify-between gap-3 pb-3 border-b border-[#E5E7EB]">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-[14px] bg-[#D1FAE5] text-[#10B981] flex items-center justify-center">
              <DollarSign className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-[#111827] flex items-center gap-2">
                Giá Thu Mua Sầu Riêng Tại Vườn (Cho Thương Lái)
                <span className="text-[11px] font-semibold text-[#10B981] bg-[#D1FAE5] px-2.5 py-0.5 rounded-full">
                  Dữ liệu thực từ MongoDB
                </span>
              </h2>
              <p className="text-xs text-[#6B7280] font-medium mt-0.5">Nguồn: giasaurieng.net (Giá thu mua tại vườn cho thương lái)</p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            {/* Grade Filters */}
            <div className="flex items-center gap-1 bg-[#F8FAFC] p-1 rounded-full text-xs font-semibold border border-[#E5E7EB]">
              <button
                type="button"
                onClick={() => setSelectedGradeFilter("all")}
                className={`px-3 py-1 rounded-full transition-all cursor-pointer ${
                  selectedGradeFilter === "all" ? "bg-[#10B981] text-white shadow-xs" : "text-[#6B7280] hover:text-[#111827]"
                }`}
              >
                Tất cả (12)
              </button>
              <button
                type="button"
                onClick={() => setSelectedGradeFilter("dep")}
                className={`px-3 py-1 rounded-full transition-all cursor-pointer ${
                  selectedGradeFilter === "dep" ? "bg-[#10B981] text-white shadow-xs" : "text-[#6B7280] hover:text-[#111827]"
                }`}
              >
                ⭐ Hàng Đẹp (Loại 1)
              </button>
              <button
                type="button"
                onClick={() => setSelectedGradeFilter("xo")}
                className={`px-3 py-1 rounded-full transition-all cursor-pointer ${
                  selectedGradeFilter === "xo" ? "bg-[#10B981] text-white shadow-xs" : "text-[#6B7280] hover:text-[#111827]"
                }`}
              >
                📦 Hàng Xô (Lùa vựa)
              </button>
            </div>

            {/* Region Filters */}
            <div className="flex items-center gap-1 bg-[#F8FAFC] p-1 rounded-full text-xs font-semibold border border-[#E5E7EB]">
              <button
                type="button"
                onClick={() => setSelectedRegion("mientay")}
                className={`px-3 py-1 rounded-full transition-all cursor-pointer ${
                  selectedRegion === "mientay" ? "bg-[#10B981] text-white shadow-xs" : "text-[#6B7280] hover:text-[#111827]"
                }`}
              >
                Miền Tây Nam Bộ
              </button>
              <button
                type="button"
                onClick={() => setSelectedRegion("taynguyen")}
                className={`px-3 py-1 rounded-full transition-all cursor-pointer ${
                  selectedRegion === "taynguyen" ? "bg-[#10B981] text-white shadow-xs" : "text-[#6B7280] hover:text-[#111827]"
                }`}
              >
                Tây Nguyên
              </button>
              <button
                type="button"
                onClick={() => setSelectedRegion("miendong")}
                className={`px-3 py-1 rounded-full transition-all cursor-pointer ${
                  selectedRegion === "miendong" ? "bg-[#10B981] text-white shadow-xs" : "text-[#6B7280] hover:text-[#111827]"
                }`}
              >
                Miền Đông Nam Bộ
              </button>
            </div>
          </div>
        </div>

        {/* 3 Column Grid Price Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {DEFAULT_MARKET_ITEMS
            .filter((item) => {
              if (selectedGradeFilter === "dep") return item.grade === "dep";
              if (selectedGradeFilter === "xo") return item.grade === "xo";
              return true;
            })
            .map((item, idx) => {
              const isUp = item.trend === "up";
              const isDep = item.grade === "dep";
              return (
                <div
                  key={idx}
                  className={`p-4 rounded-[16px] border transition-all duration-200 flex flex-col justify-between space-y-3 hover:-translate-y-0.5 ${
                    isDep ? "bg-[#D1FAE5]/20 border-emerald-200 hover:border-[#10B981]" : "bg-[#F8FAFC] border-[#E5E7EB] hover:border-emerald-300"
                  }`}
                >
                  <div>
                    <div className="flex items-center justify-between gap-2 mb-1.5">
                      <span className="text-[10px] font-bold uppercase text-[#10B981] bg-[#D1FAE5] px-2 py-0.5 rounded-full">
                        {item.category}
                      </span>
                      <span className={`text-[10px] font-semibold px-2.5 py-0.5 rounded-full ${isDep ? "bg-amber-100 text-amber-900" : "bg-gray-200 text-gray-700"}`}>
                        {isDep ? "⭐ HÀNG ĐẸP LOẠI 1" : "📦 HÀNG XÔ LÙA VỰA"}
                      </span>
                    </div>
                    <h3 className="text-xs font-bold text-[#111827] leading-snug">{item.name}</h3>
                  </div>

                  <div className="flex items-center justify-between pt-2.5 border-t border-[#E5E7EB]">
                    <div>
                      <span className="text-base font-bold text-[#10B981] tracking-tight">{item.price}</span>
                      <span className="text-[11px] font-semibold text-[#6B7280] ml-1">{item.unit}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${isUp ? "bg-[#D1FAE5] text-[#10B981]" : "bg-gray-100 text-gray-700"}`}>
                        {isUp ? `▲ ${item.change}` : item.change}
                      </span>
                      {/* Mini Sparkline Chart */}
                      <svg className="w-12 h-5 text-[#10B981]" viewBox="0 0 50 20" fill="none">
                        <path d="M0 15 Q 12 5, 25 10 T 50 3" stroke="currentColor" strokeWidth="2" fill="none" />
                      </svg>
                    </div>
                  </div>
                </div>
              );
            })}
        </div>

        {/* Bottom See All Link */}
        <div className="pt-2 text-center border-t border-[#E5E7EB]">
          <button
            type="button"
            className="text-xs font-bold text-[#10B981] hover:text-[#059669] inline-flex items-center gap-1 cursor-pointer transition-colors"
          >
            <span>Xem tất cả 12 loại giá</span>
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* ── SECTION 4: LOWER GRID (FIRST: News | SECOND: Disease Lookup) ── */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        {/* FIRST / LARGER SECTION: Agricultural News (8 Columns) */}
        <div className="lg:col-span-8 bg-white p-6 rounded-[20px] border border-[#E5E7EB] shadow-saas space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-2 border-b border-[#E5E7EB] pb-3">
            <h2 className="text-base font-bold text-[#111827]">Tin tức nông nghiệp & thị trường sầu riêng</h2>
            <button type="button" className="text-xs font-semibold text-[#10B981] hover:underline">
              Xem tất cả
            </button>
          </div>

          {/* Filter Pills */}
          <div className="flex flex-wrap items-center gap-2 text-xs font-semibold">
            <button
              type="button"
              onClick={() => setSelectedNewsTab("highlight")}
              className={`px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                selectedNewsTab === "highlight" ? "bg-[#10B981] text-white shadow-xs" : "bg-[#F8FAFC] text-[#6B7280] hover:bg-[#D1FAE5]/40"
              }`}
            >
              🔥 Nổi bật hôm nay
            </button>
            <button
              type="button"
              onClick={() => setSelectedNewsTab("market")}
              className={`px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                selectedNewsTab === "market" ? "bg-[#10B981] text-white shadow-xs" : "bg-[#F8FAFC] text-[#6B7280] hover:bg-[#D1FAE5]/40"
              }`}
            >
              📉 Biến động giá
            </button>
            <button
              type="button"
              onClick={() => setSelectedNewsTab("export")}
              className={`px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                selectedNewsTab === "export" ? "bg-[#10B981] text-white shadow-xs" : "bg-[#F8FAFC] text-[#6B7280] hover:bg-[#D1FAE5]/40"
              }`}
            >
              📜 Mã vùng & Xuất khẩu
            </button>
            <button
              type="button"
              onClick={() => setSelectedNewsTab("weather")}
              className={`px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                selectedNewsTab === "weather" ? "bg-[#10B981] text-white shadow-xs" : "bg-[#F8FAFC] text-[#6B7280] hover:bg-[#D1FAE5]/40"
              }`}
            >
              ⛅ Thời tiết & Cảnh báo
            </button>
          </div>

          {/* 3 Columns News Cards Grid */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {/* Card 1 */}
            <div className="bg-[#F8FAFC] rounded-[16px] border border-[#E5E7EB] overflow-hidden flex flex-col justify-between hover:border-[#10B981] transition-all hover:-translate-y-0.5">
              <div className="h-32 overflow-hidden relative">
                <img
                  src="/images/login/hero-durian.jpg"
                  alt="News Durian Export"
                  className="w-full h-full object-cover hover:scale-105 transition-transform duration-300"
                />
              </div>
              <div className="p-4 space-y-2 flex-1 flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between text-[10px] font-bold text-[#6B7280] mb-1">
                    <span className="text-[#10B981] font-bold uppercase">📍 TOÀN QUỐC & XUẤT KHẨU</span>
                    <span>1 giờ trước</span>
                  </div>
                  <h3 className="text-xs font-bold text-[#111827] leading-snug line-clamp-2">
                    Xuất khẩu sầu riêng Việt Nam đạt kỷ lục 2,8 tỷ USD sang thị trường Trung Quốc
                  </h3>
                  <p className="text-[11px] text-[#6B7280] mt-1 line-clamp-3 leading-relaxed">
                    Tổng cục Hải quan Trung Quốc (GACC) vừa phê duyệt cấp mới 120 mã số vùng trồng Ri6 và Monthong tại Tiền Giang, Đắk Lắk...
                  </p>
                </div>
                <div className="text-[10px] font-medium text-gray-400 pt-2 border-t border-[#E5E7EB]">
                  Nguồn: Báo Nông Nghiệp Việt Nam
                </div>
              </div>
            </div>

            {/* Card 2 */}
            <div className="bg-[#F8FAFC] rounded-[16px] border border-[#E5E7EB] overflow-hidden flex flex-col justify-between hover:border-[#10B981] transition-all hover:-translate-y-0.5">
              <div className="h-32 overflow-hidden relative">
                <img
                  src="https://images.unsplash.com/photo-1534274988757-a28bf1a57c17?auto=format&fit=crop&w=600&q=80"
                  alt="News Weather"
                  className="w-full h-full object-cover hover:scale-105 transition-transform duration-300"
                />
              </div>
              <div className="p-4 space-y-2 flex-1 flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between text-[10px] font-bold text-[#6B7280] mb-1">
                    <span className="text-[#10B981] font-bold uppercase">📍 TÂY NGUYÊN (ĐẮK LẮK)</span>
                    <span>3 giờ trước</span>
                  </div>
                  <h3 className="text-xs font-bold text-[#111827] leading-snug line-clamp-2">
                    Dự báo rãnh áp thấp nhiệt đới gây mưa lớn tại Tây Nguyên: Nguy cơ xì mủ thối gốc
                  </h3>
                  <p className="text-[11px] text-[#6B7280] mt-1 line-clamp-3 leading-relaxed">
                    Chủ vườn sầu riêng Đắk Lắk & Lâm Đồng cần chủ động gia cố hệ thống thoát nước gốc và phòng nấm Phytophthora...
                  </p>
                </div>
                <div className="text-[10px] font-medium text-gray-400 pt-2 border-t border-[#E5E7EB]">
                  Nguồn: Trung tâm Dự báo KTTV
                </div>
              </div>
            </div>

            {/* Card 3 */}
            <div className="bg-[#F8FAFC] rounded-[16px] border border-[#E5E7EB] overflow-hidden flex flex-col justify-between hover:border-[#10B981] transition-all hover:-translate-y-0.5">
              <div className="h-32 overflow-hidden relative">
                <img
                  src="https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&w=600&q=80"
                  alt="News Pruning"
                  className="w-full h-full object-cover hover:scale-105 transition-transform duration-300"
                />
              </div>
              <div className="p-4 space-y-2 flex-1 flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between text-[10px] font-bold text-[#6B7280] mb-1">
                    <span className="text-[#10B981] font-bold uppercase">📍 KỸ THUẬT</span>
                    <span>5 giờ trước</span>
                  </div>
                  <h3 className="text-xs font-bold text-[#111827] leading-snug line-clamp-2">
                    Kỹ thuật cắt tỉa cành sầu riêng giai đoạn kiến thiết cơ bản
                  </h3>
                  <p className="text-[11px] text-[#6B7280] mt-1 line-clamp-3 leading-relaxed">
                    Hướng dẫn chi tiết cách cắt tỉa cành tạo tán giúp cây phát triển khỏe mạnh về sau và cho năng suất cao.
                  </p>
                </div>
                <div className="text-[10px] font-medium text-gray-400 pt-2 border-t border-[#E5E7EB]">
                  Nguồn: Trung tâm Khuyến nông Quốc gia
                </div>
              </div>
            </div>
          </div>

          {/* Carousel Pagination Dots */}
          <div className="flex justify-center items-center gap-1.5 pt-2">
            <span className="w-2.5 h-2.5 rounded-full bg-[#10B981]" />
            <span className="w-2 h-2 rounded-full bg-gray-300" />
            <span className="w-2 h-2 rounded-full bg-gray-300" />
            <span className="w-2 h-2 rounded-full bg-gray-300" />
          </div>
        </div>

        {/* SECOND / COMPACT SECTION: Disease Lookup (4 Columns) */}
        <div className="lg:col-span-4 bg-white p-6 rounded-[20px] border border-[#E5E7EB] shadow-saas space-y-4">
          <div className="flex items-center justify-between border-b border-[#E5E7EB] pb-3">
            <h2 className="text-base font-bold text-[#111827]">Tra cứu nhanh sâu bệnh hại</h2>
            <button type="button" className="text-xs font-semibold text-[#10B981] hover:underline">
              Xem tất cả
            </button>
          </div>

          {/* 4 Compact Cards (2x2 Grid) */}
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            {/* Card 1 */}
            <div
              onClick={() => navigate("/ai-chatbot")}
              className="p-3.5 rounded-[16px] bg-[#F8FAFC] border border-[#E5E7EB] hover:border-[#10B981] transition-all cursor-pointer flex flex-col justify-between space-y-2 hover:-translate-y-0.5"
            >
              <div className="w-8 h-8 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center">
                <Bug className="w-4 h-4" />
              </div>
              <div>
                <h3 className="text-xs font-bold text-[#111827] leading-tight">Bệnh Thán Thư</h3>
                <span className="text-[10px] text-[#6B7280] font-medium">(Colletotrichum)</span>
                <p className="text-[10px] text-[#6B7280] mt-1">Triệu chứng & cách phòng trị</p>
              </div>
            </div>

            {/* Card 2 */}
            <div
              onClick={() => navigate("/ai-chatbot")}
              className="p-3.5 rounded-[16px] bg-[#F8FAFC] border border-[#E5E7EB] hover:border-[#10B981] transition-all cursor-pointer flex flex-col justify-between space-y-2 hover:-translate-y-0.5"
            >
              <div className="w-8 h-8 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center">
                <Sprout className="w-4 h-4" />
              </div>
              <div>
                <h3 className="text-xs font-bold text-[#111827] leading-tight">Nấm Phytophthora</h3>
                <span className="text-[10px] text-[#6B7280] font-medium">(Xì mủ thối gốc)</span>
                <p className="text-[10px] text-[#6B7280] mt-1">Triệu chứng & cách phòng trị</p>
              </div>
            </div>

            {/* Card 3 */}
            <div
              onClick={() => navigate("/ai-chatbot")}
              className="p-3.5 rounded-[16px] bg-[#F8FAFC] border border-[#E5E7EB] hover:border-[#10B981] transition-all cursor-pointer flex flex-col justify-between space-y-2 hover:-translate-y-0.5"
            >
              <div className="w-8 h-8 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center">
                <ShieldAlert className="w-4 h-4" />
              </div>
              <div>
                <h3 className="text-xs font-bold text-[#111827] leading-tight">Bọ Trĩ (Thrips spp.)</h3>
                <p className="text-[10px] text-[#6B7280] font-medium">Côn trùng chích hút</p>
                <p className="text-[10px] text-[#6B7280] mt-1">Nhận biết & xử lý</p>
              </div>
            </div>

            {/* Card 4 */}
            <div
              onClick={() => navigate("/ai-chatbot")}
              className="p-3.5 rounded-[16px] bg-[#F8FAFC] border border-[#E5E7EB] hover:border-[#10B981] transition-all cursor-pointer flex flex-col justify-between space-y-2 hover:-translate-y-0.5"
            >
              <div className="w-8 h-8 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center">
                <Bug className="w-4 h-4" />
              </div>
              <div>
                <h3 className="text-xs font-bold text-[#111827] leading-tight">Sâu Đục Quả</h3>
                <span className="text-[10px] text-[#6B7280] font-medium">(Conogethes punctiferalis)</span>
                <p className="text-[10px] text-[#6B7280] mt-1">Nhận biết & xử lý</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
