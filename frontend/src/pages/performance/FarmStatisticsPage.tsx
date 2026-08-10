import { useState, useEffect } from "react";
import {
  PieChart as PieChartIcon,
  BarChart3,
  TrendingUp,
  Activity,
  TreePine,
  ShieldAlert,
  Calendar,
  Filter,
  CheckCircle2,
  AlertTriangle,
  HeartPulse,
  PlusCircle,
} from "lucide-react";
import { Link } from "react-router-dom";
import {
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  Legend,
} from "recharts";
import api from "@/api";

interface HealthStat {
  statusName: string;
  count: number;
  color: string;
}

interface DiseaseStat {
  diseaseName: string;
  cases: number;
  color: string;
}

export default function FarmStatisticsPage() {
  const [timeRange, setTimeRange] = useState("30days");
  const [loading, setLoading] = useState(true);
  const [hasData, setHasData] = useState(false);

  const [statsData, setStatsData] = useState<{
    totalTrees: number;
    healthyCount: number;
    diseasedCount: number;
    monitoringCount: number;
    inspectionTotal: number;
    healthStats: HealthStat[];
    diseaseStats: DiseaseStat[];
    monthlyHarvest: any[];
  }>({
    totalTrees: 0,
    healthyCount: 0,
    diseasedCount: 0,
    monitoringCount: 0,
    inspectionTotal: 0,
    healthStats: [],
    diseaseStats: [],
    monthlyHarvest: [],
  });

  useEffect(() => {
    const loadLiveStats = async () => {
      setLoading(true);
      try {
        const [treesRes, inspRes, detRes] = await Promise.allSettled([
          api.get("/api/v1/trees?per_page=1000"),
          api.get("/api/v1/inspections?per_page=100"),
          api.get("/api/v1/detection-results?per_page=100"),
        ]);

        let healthy = 0;
        let diseased = 0;
        let monitoring = 0;
        let treeItems: any[] = [];

        if (treesRes.status === "fulfilled" && treesRes.value.data) {
          treeItems = Array.isArray(treesRes.value.data)
            ? treesRes.value.data
            : (treesRes.value.data as any)?.items || [];
          treeItems.forEach((t: any) => {
            const st = (t.health_status || t.status || "").toLowerCase();
            if (st.includes("bệnh") || st.includes("bị bệnh")) diseased++;
            else if (st.includes("theo dõi")) monitoring++;
            else healthy++;
          });
        }

        let diseaseCounts: Record<string, number> = {
          "Thán thư (Colletotrichum)": 0,
          "Xì mủ gốc (Phytophthora)": 0,
          "Đốm lá (Rhizoctonia)": 0,
          "Nấm hồng thân": 0,
        };

        let detItems: any[] = [];
        if (detRes.status === "fulfilled" && detRes.value.data) {
          detItems = Array.isArray(detRes.value.data)
            ? detRes.value.data
            : (detRes.value.data as any)?.items || [];
          detItems.forEach((d: any) => {
            const dis = d.disease || d.disease_name || d.prediction || "";
            if (dis.includes("Thán Thư") || dis.includes("Anthracnose")) diseaseCounts["Thán thư (Colletotrichum)"]++;
            else if (dis.includes("Xì Mủ") || dis.includes("Phytophthora")) diseaseCounts["Xì mủ gốc (Phytophthora)"]++;
            else if (dis.includes("Đốm Lá") || dis.includes("Cháy Lá") || dis.includes("Rhizoctonia")) diseaseCounts["Đốm lá (Rhizoctonia)"]++;
            else if (dis.includes("Nấm Hồng") || dis.includes("Pink")) diseaseCounts["Nấm hồng thân"]++;
          });
        }

        let inspItems: any[] = [];
        if (inspRes.status === "fulfilled" && inspRes.value.data) {
          inspItems = Array.isArray(inspRes.value.data)
            ? inspRes.value.data
            : (inspRes.value.data as any)?.items || [];
        }

        const totalTrees = treeItems.length;
        const totalInscriptions = inspItems.length || detItems.length;

        if (totalTrees === 0 && detItems.length === 0) {
          setHasData(false);
          setStatsData({
            totalTrees: 0,
            healthyCount: 0,
            diseasedCount: 0,
            monitoringCount: 0,
            inspectionTotal: 0,
            healthStats: [],
            diseaseStats: [],
            monthlyHarvest: [],
          });
        } else {
          setHasData(true);
          const diseaseStatsList: DiseaseStat[] = [
            { diseaseName: "Thán thư (Colletotrichum)", cases: diseaseCounts["Thán thư (Colletotrichum)"], color: "#F59E0B" },
            { diseaseName: "Xì mủ gốc (Phytophthora)", cases: diseaseCounts["Xì mủ gốc (Phytophthora)"], color: "#EF4444" },
            { diseaseName: "Đốm lá (Rhizoctonia)", cases: diseaseCounts["Đốm lá (Rhizoctonia)"], color: "#3B82F6" },
            { diseaseName: "Nấm hồng thân", cases: diseaseCounts["Nấm hồng thân"], color: "#8B5CF6" },
          ];

          setStatsData({
            totalTrees,
            healthyCount: healthy,
            diseasedCount: diseased,
            monitoringCount: monitoring,
            inspectionTotal: totalInscriptions,
            healthStats: [
              { statusName: "Khỏe mạnh", count: healthy, color: "#10B981" },
              { statusName: "Đang theo dõi", count: monitoring, color: "#F59E0B" },
              { statusName: "Bị bệnh", count: diseased, color: "#EF4444" },
            ],
            diseaseStats: diseaseStatsList,
            monthlyHarvest: [],
          });
        }
      } catch (err) {
        console.error("Error fetching live statistics from MongoDB:", err);
      } finally {
        setLoading(false);
      }
    };

    loadLiveStats();
  }, []);

  const healthyPct = statsData.totalTrees > 0
    ? ((statsData.healthyCount / statsData.totalTrees) * 100).toFixed(1)
    : "0.0";

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto font-['Plus_Jakarta_Sans',sans-serif]">
      {/* HEADER BAR */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-[20px] border border-gray-200/90 shadow-xs">
        <div>
          <h1 className="text-xl font-black text-gray-900 flex items-center gap-2">
            <PieChartIcon className="w-6 h-6 text-emerald-600" />
            <span>Thống Kê Chi Tiết Sức Khỏe & Sản Lượng Vườn</span>
          </h1>
          <p className="text-xs text-gray-500 font-medium mt-1">
            Tổng hợp dữ liệu thống kê từ chẩn đoán AI, mật độ bệnh hại & sản lượng thu hoạch theo thời gian (Dữ liệu MongoDB Realtime)
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2 bg-gray-50 border border-gray-200 rounded-xl px-3 py-2 text-xs font-bold text-gray-700">
            <Filter className="w-3.5 h-3.5 text-emerald-600" />
            <span>Khoảng thời gian:</span>
            <select
              value={timeRange}
              onChange={(e) => setTimeRange(e.target.value)}
              className="bg-transparent text-emerald-800 font-black focus:outline-none cursor-pointer"
            >
              <option value="30days">30 ngày qua</option>
              <option value="6months">6 tháng đầu năm</option>
              <option value="1year">Cả năm 2026</option>
            </select>
          </div>
        </div>
      </div>

      {/* NO DATA ALERT FOR NEW USER */}
      {!hasData && !loading && (
        <div className="p-6 bg-amber-50 border border-amber-200 rounded-2xl text-amber-900 flex flex-col sm:flex-row items-center justify-between gap-4">
          <div>
            <h3 className="font-extrabold text-sm flex items-center gap-2">
              <PlusCircle className="w-5 h-5 text-amber-600" />
              Tài khoản mới - Chưa có dữ liệu thống kê cây trồng trong MongoDB
            </h3>
            <p className="text-xs text-amber-700 mt-1">
              Bạn chưa có cây trồng hoặc lượt kiểm tra chẩn đoán bệnh nào trong cơ sở dữ liệu MongoDB. Hãy đăng ký trang trại để tải dữ liệu thống kê.
            </p>
          </div>
          <Link
            to="/register-farm"
            className="px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold text-xs rounded-xl shadow-xs transition-all whitespace-nowrap"
          >
            + Đăng ký trang trại ngay
          </Link>
        </div>
      )}

      {/* KPI SUMMARY TOP CARDS */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="bg-white border border-gray-200 p-5 rounded-2xl shadow-xs space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500">Tổng Cây Sầu Riêng</span>
            <TreePine className="w-5 h-5 text-emerald-600" />
          </div>
          <p className="text-2xl font-black text-gray-900">{statsData.totalTrees.toLocaleString()} cây</p>
          <p className="text-[11px] font-bold text-emerald-700">Dữ liệu từ MongoDB</p>
        </div>

        <div className="bg-white border border-gray-200 p-5 rounded-2xl shadow-xs space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500">Tỷ Lệ Khỏe Mạnh</span>
            <HeartPulse className="w-5 h-5 text-emerald-600" />
          </div>
          <p className="text-2xl font-black text-emerald-700">{healthyPct}%</p>
          <p className="text-[11px] font-bold text-emerald-800">{statsData.healthyCount} cây đạt chuẩn</p>
        </div>

        <div className="bg-white border border-gray-200 p-5 rounded-2xl shadow-xs space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500">Đang Theo Dõi & Bệnh</span>
            <AlertTriangle className="w-5 h-5 text-amber-500" />
          </div>
          <p className="text-2xl font-black text-amber-700">{statsData.diseasedCount + statsData.monitoringCount} cây</p>
          <p className="text-[11px] font-bold text-amber-800">Cần ưu tiên chăm sóc</p>
        </div>

        <div className="bg-white border border-gray-200 p-5 rounded-2xl shadow-xs space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-gray-500">Lượt Chẩn Đoán AI</span>
            <Activity className="w-5 h-5 text-blue-600" />
          </div>
          <p className="text-2xl font-black text-blue-900">{statsData.inspectionTotal} lượt</p>
          <p className="text-[11px] font-bold text-blue-700">Mô hình AI ResNet50 / YOLOv8</p>
        </div>
      </div>

      {/* CHARTS GRID */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        {/* PIE CHART: HEALTH STATUS */}
        <div className="lg:col-span-5 bg-white border border-gray-200/90 p-5 rounded-[24px] shadow-sm flex flex-col justify-between">
          <div className="flex items-center justify-between mb-2">
            <h3 className="text-sm font-black text-gray-900">Thống Kê Tỷ Lệ Sức Khỏe Cây Trong Vườn</h3>
          </div>

          <div className="w-full h-[220px] my-auto relative flex items-center justify-center">
            {hasData && statsData.healthStats.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={statsData.healthStats}
                    cx="50%"
                    cy="50%"
                    innerRadius={55}
                    outerRadius={85}
                    paddingAngle={4}
                    dataKey="count"
                  >
                    {statsData.healthStats.map((entry, idx) => (
                      <Cell key={`cell-${idx}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(val: number) => [`${val} cây`, "Số lượng"]} />
                </PieChart>
              </ResponsiveContainer>
            ) : (
              <div className="text-center text-xs text-gray-400 font-bold">
                Chưa có dữ liệu phân bổ sức khỏe cây trồng trong MongoDB
              </div>
            )}
            {hasData && (
              <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                <span className="text-xl font-black text-gray-900">{statsData.totalTrees}</span>
                <span className="text-[10px] text-gray-500 font-bold uppercase">Tổng Số Cây</span>
              </div>
            )}
          </div>

          <div className="grid grid-cols-3 gap-2 pt-3 border-t border-gray-100 text-center text-xs">
            {statsData.healthStats.length > 0 ? (
              statsData.healthStats.map((item) => (
                <div key={item.statusName} className="p-2 rounded-xl bg-gray-50 border border-gray-100">
                  <span className="text-gray-500 text-[10px] font-bold block">{item.statusName}</span>
                  <strong className="text-gray-900 text-sm">{item.count} cây</strong>
                </div>
              ))
            ) : (
              <div className="col-span-3 text-center text-[11px] text-gray-400 font-semibold py-1">
                Không có dữ liệu
              </div>
            )}
          </div>
        </div>

        {/* BAR CHART: DISEASE CASES */}
        <div className="lg:col-span-7 bg-white border border-gray-200/90 p-5 rounded-[24px] shadow-sm flex flex-col justify-between">
          <div className="flex items-center justify-between mb-2">
            <div>
              <h3 className="text-sm font-black text-gray-900">Thống Kê Mật Độ Bệnh Hại Thường Gặp</h3>
              <p className="text-xs text-gray-500 font-medium">Số ca phát hiện trong MongoDB AI Detection Results</p>
            </div>
          </div>

          <div className="w-full h-[220px] my-auto flex items-center justify-center">
            {hasData && statsData.diseaseStats.some((d) => d.cases > 0) ? (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={statsData.diseaseStats} margin={{ top: 10, right: 10, left: -10, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#F1F5F9" />
                  <XAxis dataKey="diseaseName" stroke="#64748B" fontSize={10} fontWeight="bold" tickLine={false} />
                  <YAxis stroke="#64748B" fontSize={11} fontWeight="bold" />
                  <Tooltip formatter={(val: number) => [`${val} ca`, "Số ca phát hiện"]} />
                  <Bar dataKey="cases" radius={[8, 8, 0, 0]}>
                    {statsData.diseaseStats.map((entry, idx) => (
                      <Cell key={`bar-${idx}`} fill={entry.color} />
                    ))}
                  </Bar>
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="text-center text-xs text-gray-400 font-bold p-6">
                Chưa ghi nhận ca bệnh hại nào trong MongoDB cho tài khoản này
              </div>
            )}
          </div>

          <div className="flex items-center justify-between pt-3 border-t border-gray-100 text-xs text-gray-600 font-medium">
            <span>⚡ Dữ liệu chẩn đoán AI quét trực tiếp từ hệ thống MongoDB</span>
          </div>
        </div>
      </div>
    </div>
  );
}
