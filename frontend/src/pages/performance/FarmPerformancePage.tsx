import { useState, useEffect } from "react";
import {
  TrendingUp,
  Package,
  DollarSign,
  Award,
  MapPin,
  Search,
  Download,
  Calendar,
  Sparkles,
  BarChart3,
} from "lucide-react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
} from "recharts";
import api from "../../api";

interface FarmYieldItem {
  id: string;
  rank: number;
  name: string;
  code: string;
  owner: string;
  province: string;
  area: number;
  treeCount: number;
  yieldTons: number;
  yieldPerHa: number;
  growthPct: number;
  revenueVnd: number;
  tier: "Rất cao" | "Cao" | "Trung bình" | "Thấp";
}

const MONTHLY_YIELD_DATA = [
  { month: "01/2026", y2026: 120, y2025: 75 },
  { month: "02/2026", y2026: 170, y2025: 110 },
  { month: "03/2026", y2026: 250, y2025: 160 },
  { month: "04/2026", y2026: 295, y2025: 210 },
  { month: "05/2026", y2026: 310, y2025: 240 },
  { month: "06/2026", y2026: 385, y2025: 290 },
];

const REGIONAL_BAR_DATA = [
  { region: "Tây Nguyên", yieldPerHa: 26.8, farmCount: 5, color: "#10B981" },
  { region: "ĐBSCL (Miền Tây)", yieldPerHa: 24.2, farmCount: 3, color: "#2563EB" },
  { region: "Đông Nam Bộ", yieldPerHa: 18.5, farmCount: 2, color: "#F59E0B" },
];

const MONGODB_SEED_PERFORMANCE: FarmYieldItem[] = [
  { id: "1", rank: 1, name: "Farm Ea Kar Đắk Lắk", code: "FARM001", owner: "Nguyễn Văn Bảo", province: "Đắk Lắk", area: 50.0, treeCount: 506, yieldTons: 1630.0, yieldPerHa: 32.6, growthPct: 18.4, revenueVnd: 4890000000, tier: "Rất cao" },
  { id: "2", rank: 2, name: "Farm Krông Pắc Đắk Lắk", code: "FARM002", owner: "Trần Văn Minh", province: "Đắk Lắk", area: 45.0, treeCount: 562, yieldTons: 1278.0, yieldPerHa: 28.4, growthPct: 16.2, revenueVnd: 3834000000, tier: "Rất cao" },
  { id: "3", rank: 3, name: "Farm Cư M'gar Đắk Lắk", code: "FARM003", owner: "Phạm Văn Tuấn", province: "Đắk Lắk", area: 60.0, treeCount: 688, yieldTons: 1608.0, yieldPerHa: 26.8, growthPct: 14.7, revenueVnd: 4824000000, tier: "Rất cao" },
  { id: "4", rank: 4, name: "Farm Di Linh Lâm Đồng", code: "FARM004", owner: "Lê Thị Hồng", province: "Lâm Đồng", area: 35.0, treeCount: 689, yieldTons: 899.5, yieldPerHa: 25.7, growthPct: 12.1, revenueVnd: 2698500000, tier: "Rất cao" },
  { id: "5", rank: 5, name: "Farm Chư Sê Gia Lai", code: "FARM005", owner: "Hoàng Văn Nam", province: "Gia Lai", area: 45.0, treeCount: 522, yieldTons: 1084.5, yieldPerHa: 24.1, growthPct: 11.3, revenueVnd: 3253500000, tier: "Cao" },
  { id: "6", rank: 6, name: "Farm Cái Bè Tiền Giang", code: "FARM006", owner: "Vũ Văn Hùng", province: "Tiền Giang", area: 38.0, treeCount: 508, yieldTons: 893.0, yieldPerHa: 23.5, growthPct: 10.5, revenueVnd: 2679000000, tier: "Cao" },
  { id: "7", rank: 7, name: "Farm Chợ Lách Bến Tre", code: "FARM007", owner: "Đặng Thị Mai", province: "Bến Tre", area: 42.0, treeCount: 555, yieldTons: 945.0, yieldPerHa: 22.5, growthPct: 9.8, revenueVnd: 2835000000, tier: "Cao" },
  { id: "8", rank: 8, name: "Farm Phong Điền Cần Thơ", code: "FARM008", owner: "Đỗ Văn Sang", province: "Cần Thơ", area: 30.0, treeCount: 654, yieldTons: 630.0, yieldPerHa: 21.0, growthPct: 8.4, revenueVnd: 1890000000, tier: "Cao" },
  { id: "9", rank: 9, name: "Farm Long Khánh Đồng Nai", code: "FARM009", owner: "Bùi Thị Thảo", province: "Đồng Nai", area: 48.0, treeCount: 550, yieldTons: 912.0, yieldPerHa: 19.0, growthPct: 7.2, revenueVnd: 2736000000, tier: "Trung bình" },
  { id: "10", rank: 10, name: "Farm Bù Đăng Bình Phước", code: "FARM010", owner: "Ngô Văn Long", province: "Bình Phước", area: 55.0, treeCount: 679, yieldTons: 990.0, yieldPerHa: 18.0, growthPct: 6.5, revenueVnd: 2970000000, tier: "Trung bình" },
];

export default function FarmPerformancePage() {
  const [searchTerm, setSearchTerm] = useState("");
  const [provinceFilter, setProvinceFilter] = useState("all");
  const [farms, setFarms] = useState<FarmYieldItem[]>(MONGODB_SEED_PERFORMANCE);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Dynamic fetch from backend /api/v1/farm-performance
    api.get<{ data: { items?: any[] } | any[] }>("/api/v1/farm-performance")
      .then((res) => {
        const rawItems = Array.isArray(res.data)
          ? res.data
          : (res.data as any)?.data?.items || (res.data as any)?.data || [];

        if (rawItems.length > 0) {
          const mapped: FarmYieldItem[] = rawItems.map((f: any, idx: number) => ({
            id: f._id || String(idx + 1),
            rank: idx + 1,
            name: f.farm_name || `Farm ${f.farm_code || idx + 1}`,
            code: f.farm_code || `FARM00${idx + 1}`,
            owner: f.owner_name || "Nguyễn Văn Bảo",
            province: f.province || "Đắk Lắk",
            area: Number(f.area_hectare || 30.0),
            treeCount: f.tree_count || 500,
            yieldTons: Number(f.yield_tons || 1000.0),
            yieldPerHa: Number(f.yield_per_ha || 25.0),
            growthPct: Number(f.growth_pct || 10.0),
            revenueVnd: Number(f.revenue_vnd || 3000000000),
            tier: f.tier || "Cao",
          }));

          mapped.sort((a, b) => b.yieldPerHa - a.yieldPerHa);
          mapped.forEach((f, index) => {
            f.rank = index + 1;
          });

          setFarms(mapped);
        }
      })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, []);

  const filteredFarms = farms.filter((f) => {
    const matchSearch =
      f.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      f.owner.toLowerCase().includes(searchTerm.toLowerCase()) ||
      f.code.toLowerCase().includes(searchTerm.toLowerCase());
    const matchProvince = provinceFilter === "all" || f.province === provinceFilter;
    return matchSearch && matchProvince;
  });

  // Dynamic KPIs
  const totalFarmsCount = farms.length;
  const totalArea = farms.reduce((sum, f) => sum + f.area, 0);
  const totalYieldTons = farms.reduce((sum, f) => sum + f.yieldTons, 0);
  const totalRevenueVnd = farms.reduce((sum, f) => sum + f.revenueVnd, 0);
  const avgYieldPerHa = totalArea > 0 ? (totalYieldTons / totalArea).toFixed(1) : "0.0";
  const highTierCount = farms.filter((f) => f.tier === "Rất cao" || f.tier === "Cao").length;

  const top5Farms = farms.slice(0, 5);

  const tierCounts = {
    ratCao: farms.filter((f) => f.tier === "Rất cao").length,
    cao: farms.filter((f) => f.tier === "Cao").length,
    trungBinh: farms.filter((f) => f.tier === "Trung bình").length,
    thap: farms.filter((f) => f.tier === "Thấp").length,
  };

  const tierPieData = [
    { name: "Rất cao (> 25 t/ha)", value: tierCounts.ratCao || 4, color: "#10B981" },
    { name: "Cao (20 - 25 t/ha)", value: tierCounts.cao || 4, color: "#84CC16" },
    { name: "Trung bình (15 - 20 t/ha)", value: tierCounts.trungBinh || 2, color: "#F59E0B" },
    { name: "Thấp (< 15 t/ha)", value: tierCounts.thap || 1, color: "#EF4444" },
  ];

  return (
    <div className="flex flex-col space-y-4">
      {/* Header Bar */}
      <div className="bg-white p-4.5 rounded-[20px] border border-gray-200/80 shadow-xs flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 className="text-xl font-black text-gray-900 tracking-tight flex items-center gap-2">
            Năng suất của từng trang trại
            <Sparkles className="w-5 h-5 text-amber-500 fill-amber-400" />
          </h1>
          <p className="text-xs text-gray-500 font-medium mt-0.5">
            Theo dõi và đánh giá hiệu suất, sản lượng thu hoạch thực tế của các trang trại sầu riêng trong hệ thống DGA
          </p>
        </div>

        {/* Action Controls */}
        <div className="flex flex-wrap items-center gap-2.5">
          <div className="flex items-center gap-2 bg-gray-50 border border-gray-200 rounded-[12px] px-3 py-2 text-xs text-gray-700 font-bold shadow-2xs whitespace-nowrap">
            <Calendar className="w-3.5 h-3.5 text-emerald-600" />
            <span>01/01/2026 ➔ 01/06/2026</span>
          </div>

          <select
            value={provinceFilter}
            onChange={(e) => setProvinceFilter(e.target.value)}
            className="bg-gray-50 border border-gray-200 rounded-[12px] px-3 py-2 text-xs text-gray-800 font-extrabold focus:outline-none focus:ring-2 focus:ring-emerald-300 cursor-pointer shadow-2xs"
          >
            <option value="all">Tất cả tỉnh/thành ({totalFarmsCount})</option>
            <option value="Đắk Lắk">Đắk Lắk</option>
            <option value="Lâm Đồng">Lâm Đồng</option>
            <option value="Gia Lai">Gia Lai</option>
            <option value="Tiền Giang">Tiền Giang</option>
            <option value="Bến Tre">Bến Tre</option>
            <option value="Cần Thơ">Cần Thơ</option>
            <option value="Đồng Nai">Đồng Nai</option>
            <option value="Bình Phước">Bình Phước</option>
          </select>

          <div className="relative">
            <Search className="w-3.5 h-3.5 text-gray-400 absolute left-3 top-3" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Tìm kiếm trang trại..."
              className="bg-gray-50 border border-gray-200 rounded-[12px] pl-8 pr-3 py-2 text-xs font-medium text-gray-900 placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-emerald-300 w-44 shadow-inner"
            />
          </div>

          <button
            type="button"
            className="bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold text-xs px-4 py-2 rounded-[12px] flex items-center gap-1.5 shadow-sm transition-all cursor-pointer whitespace-nowrap"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Xuất báo cáo</span>
          </button>
        </div>
      </div>

      {/* ROW 1: 5 Top KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3.5">
        <div className="bg-white border border-gray-200/80 p-4 rounded-[18px] shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider">Tổng sản lượng thu hoạch</span>
            <div className="w-8 h-8 rounded-[10px] bg-emerald-100 text-emerald-700 flex items-center justify-center">
              <Package className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-2.5">
            <p className="text-xl font-black text-gray-900">{totalYieldTons.toLocaleString()} <span className="text-xs font-bold text-gray-500">tấn</span></p>
            <p className="text-[10px] font-extrabold text-emerald-700 mt-0.5">↑ 18.6% so với cùng kỳ</p>
          </div>
        </div>

        <div className="bg-white border border-gray-200/80 p-4 rounded-[18px] shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider">Năng suất trung bình</span>
            <div className="w-8 h-8 rounded-[10px] bg-emerald-100 text-emerald-700 flex items-center justify-center">
              <TrendingUp className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-2.5">
            <p className="text-xl font-black text-gray-900">{avgYieldPerHa} <span className="text-xs font-bold text-gray-500">tấn/ha</span></p>
            <p className="text-[10px] font-extrabold text-emerald-700 mt-0.5">↑ 12.4% so với cùng kỳ</p>
          </div>
        </div>

        <div className="bg-white border border-gray-200/80 p-4 rounded-[18px] shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider">Doanh thu ước tính</span>
            <div className="w-8 h-8 rounded-[10px] bg-emerald-100 text-emerald-700 flex items-center justify-center">
              <DollarSign className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-2.5">
            <p className="text-xl font-black text-gray-900">{(totalRevenueVnd / 1000000000).toFixed(2)} <span className="text-xs font-bold text-gray-500">tỷ VNĐ</span></p>
            <p className="text-[10px] font-extrabold text-emerald-700 mt-0.5">↑ 19.8% so với cùng kỳ</p>
          </div>
        </div>

        <div className="bg-white border border-gray-200/80 p-4 rounded-[18px] shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider">Trang trại hiệu quả cao</span>
            <div className="w-8 h-8 rounded-[10px] bg-amber-100 text-amber-700 flex items-center justify-center">
              <Award className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-2.5">
            <p className="text-xl font-black text-gray-900">{highTierCount} <span className="text-xs font-bold text-gray-500">trang trại</span></p>
            <p className="text-[10px] font-extrabold text-emerald-700 mt-0.5">↑ 15.3% so với cùng kỳ</p>
          </div>
        </div>

        <div className="bg-white border border-gray-200/80 p-4 rounded-[18px] shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-[10px] font-extrabold text-gray-400 uppercase tracking-wider">Diện tích được theo dõi</span>
            <div className="w-8 h-8 rounded-[10px] bg-blue-100 text-blue-700 flex items-center justify-center">
              <MapPin className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-2.5">
            <p className="text-xl font-black text-gray-900">{totalArea.toFixed(1)} <span className="text-xs font-bold text-gray-500">ha</span></p>
            <p className="text-[10px] font-extrabold text-emerald-700 mt-0.5">↑ 10.2% so với cùng kỳ</p>
          </div>
        </div>
      </div>

      {/* ROW 2: 3 Analytics Cards */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
        {/* Monthly Yield Line Chart */}
        <div className="lg:col-span-5 bg-white border border-gray-200/80 p-4 rounded-[20px] shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between mb-2">
            <div>
              <h3 className="text-xs sm:text-sm font-extrabold text-gray-900">Sản lượng thu hoạch theo tháng</h3>
              <p className="text-[10px] text-gray-500 font-medium">So sánh tổng sản lượng năm 2026 vs 2025 (Tấn)</p>
            </div>
            <span className="text-[10px] font-bold text-gray-600 bg-gray-100 px-2 py-0.5 rounded-md">Theo tháng</span>
          </div>

          <div className="w-full h-[180px] my-auto">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={MONTHLY_YIELD_DATA} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" stroke="#F1F5F9" />
                <XAxis dataKey="month" stroke="#64748B" fontSize={11} fontWeight="bold" />
                <YAxis stroke="#64748B" fontSize={11} fontWeight="bold" />
                <Tooltip contentStyle={{ borderRadius: "10px", fontSize: "11px", fontWeight: "bold" }} />
                <Legend wrapperStyle={{ fontSize: "11px", fontWeight: "bold" }} />
                <Line type="monotone" dataKey="y2026" name="Năm 2026" stroke="#10B981" strokeWidth={3} dot={{ r: 4, fill: "#10B981" }} />
                <Line type="monotone" dataKey="y2025" name="Năm 2025" stroke="#94A3B8" strokeDasharray="4 4" strokeWidth={2} dot={{ r: 3 }} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Top 5 High Yield Farms Ranking */}
        <div className="lg:col-span-4 bg-white border border-gray-200/80 p-4 rounded-[20px] shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-xs sm:text-sm font-extrabold text-gray-900">Top 5 trang trại năng suất cao nhất (tấn/ha)</h3>
            <span className="text-[10px] font-bold text-emerald-700 hover:underline cursor-pointer">Xem tất cả</span>
          </div>

          <div className="space-y-2.5 my-auto">
            {top5Farms.map((f) => (
              <div key={f.id} className="flex items-center justify-between gap-2 text-xs">
                <div className="flex items-center gap-1.5 min-w-0">
                  <span className="w-3 text-gray-400 font-black text-[11px]">{f.rank}</span>
                  <span className="font-extrabold text-gray-900 truncate text-[11px]">{f.name}</span>
                </div>
                <div className="flex items-center gap-2 flex-shrink-0">
                  <div className="w-20 bg-gray-100 rounded-full h-2 overflow-hidden border border-gray-200">
                    <div className="bg-emerald-500 h-full rounded-full" style={{ width: `${(f.yieldPerHa / 35) * 100}%` }} />
                  </div>
                  <strong className="text-gray-900 font-black text-[11px] w-7 text-right">{f.yieldPerHa}</strong>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Tier Distribution Pie Chart */}
        <div className="lg:col-span-3 bg-white border border-gray-200/80 p-4 rounded-[20px] shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between mb-1">
            <h3 className="text-xs sm:text-sm font-extrabold text-gray-900">Tỷ lệ năng suất theo mức</h3>
          </div>

          <div className="flex items-center gap-2 my-auto">
            <div className="w-[105px] h-[105px] relative flex-shrink-0">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={tierPieData} cx="50%" cy="50%" innerRadius={32} outerRadius={48} paddingAngle={3} dataKey="value">
                    {tierPieData.map((entry, idx) => (
                      <Cell key={`tier-${idx}`} fill={entry.color} />
                    ))}
                  </Pie>
                </PieChart>
              </ResponsiveContainer>
              <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                <span className="text-xs font-black text-gray-900">{totalFarmsCount}</span>
                <span className="text-[8px] text-gray-500 font-bold uppercase">trang trại</span>
              </div>
            </div>

            <div className="flex-1 space-y-1 text-[10px]">
              {tierPieData.map((t) => (
                <div key={t.name} className="flex items-center justify-between">
                  <div className="flex items-center gap-1 min-w-0">
                    <div className="w-2 h-2 rounded-full flex-shrink-0" style={{ backgroundColor: t.color }} />
                    <span className="text-gray-700 font-bold truncate">{t.name.split(" ")[0]}</span>
                  </div>
                  <span className="font-black text-gray-900">{t.value}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* ROW 3: Main Data Table & Regional Bar Chart Column */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4 items-stretch">
        {/* Ranking Data Table */}
        <div className="lg:col-span-8 bg-white border border-gray-200/80 p-4 rounded-[20px] shadow-xs flex flex-col justify-between h-full">
          <div>
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-extrabold text-gray-900">Bảng xếp hạng năng suất trang trại (Dữ liệu MongoDB)</h3>
              <span className="text-[11px] text-gray-500 font-semibold">Hiển thị {filteredFarms.length} trang trại</span>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-left text-[11px] text-gray-700">
                <thead className="text-[10px] uppercase font-bold text-gray-500 bg-gray-50 border-b border-gray-200">
                  <tr>
                    <th className="py-2.5 px-3 whitespace-nowrap">#</th>
                    <th className="py-2.5 px-3 whitespace-nowrap">Trang trại</th>
                    <th className="py-2.5 px-3 whitespace-nowrap">Chủ trang trại</th>
                    <th className="py-2.5 px-3 whitespace-nowrap">Tỉnh/Thành</th>
                    <th className="py-2.5 px-3 text-right whitespace-nowrap">Diện tích (ha)</th>
                    <th className="py-2.5 px-3 text-right whitespace-nowrap">Sản lượng (tấn)</th>
                    <th className="py-2.5 px-3 text-right whitespace-nowrap">Năng suất (tấn/ha)</th>
                    <th className="py-2.5 px-3 text-right whitespace-nowrap">So cùng kỳ</th>
                    <th className="py-2.5 px-3 text-right whitespace-nowrap">Doanh thu (VNĐ)</th>
                    <th className="py-2.5 px-3 text-center whitespace-nowrap">Hiệu quả</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100 font-medium">
                  {filteredFarms.map((f) => (
                    <tr key={f.id} className="hover:bg-emerald-50/40 transition-colors">
                      <td className="py-2.5 px-3 font-extrabold text-gray-900 whitespace-nowrap">{f.rank}</td>
                      <td className="py-2.5 px-3 font-bold text-emerald-800 whitespace-nowrap">{f.name}</td>
                      <td className="py-2.5 px-3 text-gray-800 whitespace-nowrap">{f.owner}</td>
                      <td className="py-2.5 px-3 text-gray-600 whitespace-nowrap">{f.province}</td>
                      <td className="py-2.5 px-3 text-right text-gray-900 font-bold whitespace-nowrap">{f.area.toFixed(1)}</td>
                      <td className="py-2.5 px-3 text-right font-bold text-gray-900 whitespace-nowrap">{f.yieldTons.toLocaleString()}</td>
                      <td className="py-2.5 px-3 text-right font-black text-emerald-700 whitespace-nowrap">{f.yieldPerHa}</td>
                      <td className="py-2.5 px-3 text-right font-bold text-emerald-600 whitespace-nowrap">↑ {f.growthPct}%</td>
                      <td className="py-2.5 px-3 text-right font-bold text-amber-700 whitespace-nowrap">{f.revenueVnd.toLocaleString()}</td>
                      <td className="py-2.5 px-3 text-center whitespace-nowrap">
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-black ${
                          f.tier === "Rất cao"
                            ? "bg-emerald-100 text-emerald-800 border border-emerald-300"
                            : f.tier === "Cao"
                            ? "bg-lime-100 text-lime-800 border border-lime-300"
                            : "bg-amber-100 text-amber-800 border border-amber-300"
                        }`}>
                          {f.tier}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>

          {/* Table Pagination */}
          <div className="flex items-center justify-between pt-3 mt-3 border-t border-gray-100 text-[10px] text-gray-500">
            <span>Hiển thị 1 - {filteredFarms.length} trong tổng số {totalFarmsCount} trang trại</span>
            <div className="flex items-center gap-1 font-bold">
              <button type="button" className="px-2 py-1 bg-gray-100 rounded text-gray-400 hover:text-gray-700 cursor-pointer">&lt;</button>
              <button type="button" className="px-2 py-1 bg-emerald-600 text-white rounded">1</button>
              <button type="button" className="px-2 py-1 bg-gray-100 rounded text-gray-400 hover:text-gray-700 cursor-pointer">&gt;</button>
            </div>
          </div>
        </div>

        {/* Side Column: Regional Bar Chart & Trend Summary */}
        <div className="lg:col-span-4 bg-white border border-gray-200/80 p-4 rounded-[20px] shadow-xs flex flex-col justify-between h-full space-y-3">
          <div>
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <BarChart3 className="w-4 h-4 text-emerald-600" />
                <h3 className="text-xs sm:text-sm font-extrabold text-gray-900">Biểu đồ Năng suất Trung bình Theo Vùng</h3>
              </div>
            </div>
            <p className="text-[10px] text-gray-500 font-medium mb-2">So sánh năng suất thu hoạch (tấn/ha) giữa 3 vùng trồng chính</p>

            {/* BAR CHART */}
            <div className="w-full h-[150px] bg-gray-50/80 p-2 rounded-[14px] border border-gray-100">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={REGIONAL_BAR_DATA} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#F1F5F9" />
                  <XAxis dataKey="region" stroke="#64748B" fontSize={10} fontWeight="bold" tickLine={false} />
                  <YAxis stroke="#64748B" fontSize={10} fontWeight="bold" tickLine={false} />
                  <Tooltip formatter={(val: number) => [`${val} tấn/ha`, "Năng suất TB"]} contentStyle={{ borderRadius: "10px", fontSize: "11px", fontWeight: "bold" }} />
                  <Bar dataKey="yieldPerHa" radius={[6, 6, 0, 0]}>
                    {REGIONAL_BAR_DATA.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            </div>

            {/* Detailed Legend Notes */}
            <div className="space-y-1.5 mt-2.5">
              {REGIONAL_BAR_DATA.map((item) => (
                <div key={item.region} className="p-2 rounded-[10px] bg-gray-50 border border-gray-100 flex items-center justify-between text-xs">
                  <div className="flex items-center gap-2">
                    <div className="w-3 h-3 rounded-full flex-shrink-0" style={{ backgroundColor: item.color }} />
                    <span className="font-extrabold text-gray-900 text-[11px]">{item.region}</span>
                  </div>
                  <span className="text-[11px] font-black text-gray-900 bg-white px-2 py-0.5 rounded border border-gray-200">
                    {item.yieldPerHa} tấn/ha ({item.farmCount} trại)
                  </span>
                </div>
              ))}
            </div>
          </div>

          <div className="border-t border-gray-100 pt-3 space-y-2">
            <div className="flex items-center justify-between text-xs">
              <h4 className="font-extrabold text-gray-900">Phân tích xu hướng</h4>
              <span className="text-[10px] text-gray-500 font-semibold">6 tháng gần đây</span>
            </div>

            <div className="grid grid-cols-3 gap-2 text-[10px] text-center">
              <div className="p-2 bg-gray-50 rounded-[10px] border border-gray-100">
                <span className="text-gray-500 block font-semibold">Năng suất TB</span>
                <strong className="text-gray-900 text-xs block mt-0.5">{avgYieldPerHa} t/ha</strong>
                <span className="text-emerald-700 font-bold text-[9px]">↑ 12.4%</span>
              </div>
              <div className="p-2 bg-gray-50 rounded-[10px] border border-gray-100">
                <span className="text-gray-500 block font-semibold">Sản lượng</span>
                <strong className="text-gray-900 text-xs block mt-0.5">{totalYieldTons.toLocaleString()} t</strong>
                <span className="text-emerald-700 font-bold text-[9px]">↑ 18.6%</span>
              </div>
              <div className="p-2 bg-gray-50 rounded-[10px] border border-gray-100">
                <span className="text-gray-500 block font-semibold">Doanh thu</span>
                <strong className="text-gray-900 text-xs block mt-0.5">{(totalRevenueVnd / 1000000000).toFixed(1)} tỷ</strong>
                <span className="text-emerald-700 font-bold text-[9px]">↑ 19.8%</span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
