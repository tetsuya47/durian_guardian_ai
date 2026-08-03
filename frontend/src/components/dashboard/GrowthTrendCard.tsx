import { useState, useEffect } from "react";
import { TrendingUp, Users, Building2, Calendar } from "lucide-react";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from "recharts";
import Card from "./Shared/Card";
import SectionTitle from "./Shared/SectionTitle";
import api from "../../api";

export interface GrowthTrendItem {
  month: string;
  newUsers: number;
  newFarms: number;
}

const DEFAULT_GROWTH_DATA: GrowthTrendItem[] = [
  { month: "Tháng 3", newUsers: 8, newFarms: 1 },
  { month: "Tháng 4", newUsers: 12, newFarms: 2 },
  { month: "Tháng 5", newUsers: 15, newFarms: 2 },
  { month: "Tháng 6", newUsers: 10, newFarms: 3 },
  { month: "Tháng 7", newUsers: 18, newFarms: 2 },
  { month: "Tháng 8", newUsers: 22, newFarms: 3 },
];

export default function GrowthTrendCard() {
  const [data, setData] = useState<GrowthTrendItem[]>(DEFAULT_GROWTH_DATA);
  const [timeRange, setTimeRange] = useState("6m");

  useEffect(() => {
    // Dynamic fetch if backend provides growth_trend
    api.get<{ data: { growth_trend?: any[] } }>("/dashboard")
      .then((res) => {
        const trend = res.data?.data?.growth_trend;
        if (Array.isArray(trend) && trend.length > 0) {
          setData(
            trend.map((item: any) => ({
              month: item.month,
              newUsers: item.new_users || item.newUsers || 0,
              newFarms: item.new_farms || item.newFarms || 0,
            }))
          );
        }
      })
      .catch(() => {});
  }, []);

  const totalNewUsers = data.reduce((sum, item) => sum + item.newUsers, 0);
  const totalNewFarms = data.reduce((sum, item) => sum + item.newFarms, 0);

  return (
    <Card className="flex flex-col h-full overflow-hidden" padding={false} hover={false}>
      <div className="flex flex-col justify-between h-full p-4 space-y-2">
        {/* Header */}
        <div className="flex flex-wrap items-center justify-between gap-2 pb-2 border-b border-gray-100 flex-shrink-0">
          <SectionTitle
            icon={<TrendingUp className="w-5 h-5 text-blue-600" />}
            title="Biểu đồ Tăng Trưởng Người Dùng & Nông Trại Theo Tháng"
            size="section"
            subtitle="Thống kê số lượng tài khoản người dùng mới & nông trại gia nhập hệ thống"
          />

          <div className="flex items-center gap-1.5">
            <span className="text-[11px] font-bold text-gray-500 flex items-center gap-1">
              <Calendar className="w-3.5 h-3.5 text-gray-400" />
              Kỳ báo cáo:
            </span>
            <select
              value={timeRange}
              onChange={(e) => setTimeRange(e.target.value)}
              className="text-[11px] font-bold text-gray-700 bg-gray-100 border border-gray-200 rounded-[8px] px-2 py-1 focus:outline-none"
            >
              <option value="6m">6 tháng gần nhất</option>
              <option value="12m">1 năm gần nhất</option>
            </select>
          </div>
        </div>

        {/* LINE CHART CONTAINER */}
        <div className="w-full h-[180px] my-auto">
          <ResponsiveContainer width="100%" height="100%">
            <LineChart data={data} margin={{ top: 10, right: 15, left: -20, bottom: 0 }}>
              <CartesianGrid strokeDasharray="3 3" stroke="#F1F5F9" />
              <XAxis dataKey="month" stroke="#64748B" fontSize={11} fontWeight="bold" tickLine={false} />
              <YAxis stroke="#64748B" fontSize={11} fontWeight="bold" tickLine={false} />
              <Tooltip
                contentStyle={{ borderRadius: "12px", border: "1px solid #E2E8F0", fontSize: "11px", fontWeight: "bold" }}
                formatter={(value: number, name: string) => [
                  `${value} ${name.includes("Người dùng") ? "người dùng" : "nông trại"}`,
                  name,
                ]}
              />
              <Legend wrapperStyle={{ fontSize: "11px", fontWeight: "bold", paddingTop: "4px" }} />
              <Line
                type="monotone"
                dataKey="newUsers"
                name="👤 Người dùng mới"
                stroke="#2563EB"
                strokeWidth={3}
                dot={{ r: 4, fill: "#2563EB" }}
                activeDot={{ r: 6 }}
              />
              <Line
                type="monotone"
                dataKey="newFarms"
                name="🌴 Nông trại mới"
                stroke="#10B981"
                strokeWidth={3}
                dot={{ r: 4, fill: "#10B981" }}
                activeDot={{ r: 6 }}
              />
            </LineChart>
          </ResponsiveContainer>
        </div>

        {/* Summary Footer */}
        <div className="pt-2 border-t border-gray-100 flex items-center justify-between text-[11px] font-semibold text-gray-600 flex-shrink-0">
          <div className="flex items-center gap-4">
            <span className="flex items-center gap-1 text-blue-700 font-bold">
              <Users className="w-3.5 h-3.5 text-blue-600" />
              Tổng người dùng mới: <strong>+{totalNewUsers}</strong>
            </span>
            <span className="flex items-center gap-1 text-emerald-700 font-bold">
              <Building2 className="w-3.5 h-3.5 text-emerald-600" />
              Tổng nông trại mới: <strong>+{totalNewFarms}</strong>
            </span>
          </div>
          <span className="text-[10px] font-bold text-gray-500 bg-gray-100 px-2 py-0.5 rounded-md">
            Cập nhật theo tháng
          </span>
        </div>
      </div>
    </Card>
  );
}
