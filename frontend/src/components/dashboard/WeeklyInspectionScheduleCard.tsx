import { useState, useMemo } from "react";
import { Calendar, ClipboardCheck, ChevronRight, Filter, ShieldAlert, CheckCircle2, Clock, MapPin, User } from "lucide-react";
import Card from "./Shared/Card";
import SectionTitle from "./Shared/SectionTitle";
import type { InspectionRow } from "./InspectionTable";

interface WeeklyInspectionScheduleCardProps {
  data: InspectionRow[];
}

interface DayTab {
  dayName: string;
  dateStr: string;
  fullDate: string;
  isToday: boolean;
}

const DEFAULT_TEO_INSPECTIONS: InspectionRow[] = [
  { id: "insp-1", code: "INSP-2026-0801", date: "Hôm nay 08:30", treeCode: "SR-EAYONG-042", farm: "Ea Yông Krông Pắc", zone: "Khu A - Sầu Riêng Thái", inspector: "Kỹ thuật viên Nguyễn Văn Tèo", status: "Hoàn thành", result: "Khỏe mạnh (Đã phun vi lượng)", action: "Theo dõi định kỳ" },
  { id: "insp-2", code: "INSP-2026-0802", date: "Hôm nay 10:15", treeCode: "SR-EAYONG-088", farm: "Ea Yông Krông Pắc", zone: "Khu B - Sầu Riêng Ri6", inspector: "AI Agronomist Bot", status: "Cảnh báo", result: "Rệp sáp chóp lá (Nhẹ)", action: "Xịt thuốc sinh học Nấm Trắng" },
  { id: "insp-3", code: "INSP-2026-0803", date: "Hôm qua 14:20", treeCode: "SR-EAYONG-115", farm: "Ea Yông Krông Pắc", zone: "Khu C - Sầu Riêng Musang King", inspector: "Kỹ thuật viên Nguyễn Văn Tèo", status: "Hoàn thành", result: "Khỏe mạnh (Phát triển đọt tốt)", action: "Bón phân hữu cơ nở" },
  { id: "insp-4", code: "INSP-2026-0804", date: "Hôm qua 16:45", treeCode: "SR-EAYONG-201", farm: "Ea Yông Krông Pắc", zone: "Khu D - Sầu Riêng Thái", inspector: "Kỹ thuật viên Nguyễn Văn Tèo", status: "Hoàn thành", result: "Khỏe mạnh", action: "Đo độ ẩm đất 68%" },
  { id: "insp-5", code: "INSP-2026-0805", date: "03/08 09:00", treeCode: "SR-EAYONG-019", farm: "Ea Yông Krông Pắc", zone: "Khu A - Sầu Riêng Thái", inspector: "AI Agronomist Bot", status: "Cảnh báo", result: "Nấm Phytophthora thân", action: "Quét vôi gốc & Châm Trichoderma" },
];

export default function WeeklyInspectionScheduleCard({ data }: WeeklyInspectionScheduleCardProps) {
  const activeData = useMemo(() => (data && data.length > 0 ? data : DEFAULT_TEO_INSPECTIONS), [data]);

  // Generate 7 days for current week (Mon -> Sun)
  const weekDays = useMemo<DayTab[]>(() => {
    const today = new Date();
    const currentDay = today.getDay(); // 0 is Sun, 1 is Mon...
    const distanceToMon = currentDay === 0 ? -6 : 1 - currentDay;

    const monday = new Date(today);
    monday.setDate(today.getDate() + distanceToMon);

    const days: DayTab[] = [];
    const dayLabels = ["Thứ 2", "Thứ 3", "Thứ 4", "Thứ 5", "Thứ 6", "Thứ 7", "Chủ Nhật"];

    for (let i = 0; i < 7; i++) {
      const d = new Date(monday);
      d.setDate(monday.getDate() + i);

      const dayNum = String(d.getDate()).padStart(2, "0");
      const monthNum = String(d.getMonth() + 1).padStart(2, "0");
      const dateStr = `${dayNum}/${monthNum}`;
      const fullDate = d.toISOString().split("T")[0];
      const isToday = d.toDateString() === today.toDateString();

      days.push({
        dayName: dayLabels[i],
        dateStr,
        fullDate,
        isToday,
      });
    }
    return days;
  }, []);

  const [selectedDay, setSelectedDay] = useState<string>("all");

  // Group / filter inspections by selected day or show all
  const filteredData = useMemo(() => {
    if (selectedDay === "all") return activeData;
    const targetDayTab = weekDays.find((d) => d.fullDate === selectedDay || d.dateStr === selectedDay);
    return activeData.filter((item) => {
      if (!item.date && !item.time) return true;
      const rawDate = item.date || item.time || "";
      if (targetDayTab) {
        if (rawDate.includes(targetDayTab.dateStr) || rawDate.includes(targetDayTab.fullDate)) return true;
      }
      return rawDate.includes(selectedDay);
    });
  }, [activeData, selectedDay, weekDays]);

  const getStatusBadge = (status?: string, result?: string) => {
    const resText = result || "";
    const statText = status || "";
    if (resText.includes("Khỏe") || statText === "Khỏe mạnh") {
      return (
        <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800 border border-emerald-300">
          <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
          <span>Khỏe mạnh</span>
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-100 text-rose-800 border border-rose-300">
        <ShieldAlert className="w-3.5 h-3.5 text-rose-600" />
        <span>{resText || "Cần xử lý"}</span>
      </span>
    );
  };

  return (
    <Card className="flex flex-col overflow-hidden h-full border border-gray-200/90 shadow-md rounded-[20px] bg-white">
      {/* CARD HEADER */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-gray-100">
        <SectionTitle
          icon={<Calendar className="w-5 h-5 text-emerald-600" />}
          title="Lịch Hoạt Động Kiểm Tra Vườn Trong 1 Tuần"
          size="section"
          subtitle="Kế hoạch & nhật ký thực địa 7 ngày gần nhất của trang trại"
        />
        <div className="flex items-center gap-2">
          <span className="text-xs font-bold text-slate-500 bg-slate-100 px-3 py-1 rounded-full border border-slate-200 flex items-center gap-1">
            <ClipboardCheck className="w-3.5 h-3.5 text-emerald-600" />
            <span>Tổng: <b>{activeData.length} lượt</b></span>
          </span>
        </div>
      </div>

      {/* WEEKLY 7-DAY PICKER TABS */}
      <div className="py-2.5 flex items-center gap-2 overflow-x-auto no-scrollbar border-b border-gray-100">
        <button
          type="button"
          onClick={() => setSelectedDay("all")}
          className={`px-3 py-1.5 rounded-xl text-xs font-black transition-all cursor-pointer whitespace-nowrap flex items-center gap-1.5 ${
            selectedDay === "all"
              ? "bg-emerald-700 text-white shadow-sm"
              : "bg-slate-100 text-slate-600 hover:bg-slate-200"
          }`}
        >
          <Filter className="w-3.5 h-3.5" />
          <span>Tất cả 7 ngày</span>
        </button>

        {weekDays.map((day) => {
          const isSelected = selectedDay === day.fullDate || selectedDay === day.dateStr;
          return (
            <button
              key={day.fullDate}
              type="button"
              onClick={() => setSelectedDay(day.dateStr)}
              className={`flex flex-col items-center px-3.5 py-1.5 rounded-xl text-xs transition-all cursor-pointer min-w-[76px] border ${
                isSelected
                  ? "bg-emerald-600 text-white border-emerald-700 shadow-md font-black"
                  : day.isToday
                  ? "bg-emerald-50 text-emerald-800 border-emerald-300 font-extrabold"
                  : "bg-gray-50 text-gray-700 border-gray-200/80 hover:bg-gray-100 font-semibold"
              }`}
            >
              <span className="text-[10px] uppercase tracking-wider opacity-90">
                {day.dayName} {day.isToday && "📍"}
              </span>
              <span className="text-xs font-black tracking-tight">{day.dateStr}</span>
            </button>
          );
        })}
      </div>

      {/* INSPECTION LIST TABLE / TIMELINE */}
      <div className="flex-1 overflow-y-auto min-h-[220px] max-h-[300px] pt-2">
        {filteredData.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full py-8 text-center space-y-2">
            <div className="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center text-slate-400">
              <Calendar className="w-6 h-6" />
            </div>
            <p className="text-xs font-bold text-slate-500">Chưa có hoạt động kiểm tra nào trong ngày này</p>
          </div>
        ) : (
          <div className="space-y-2">
            {filteredData.map((row) => {
              const codeStr = row.code || row.id || "INSP-01";
              const badgeTag = codeStr.includes("-") ? codeStr.split("-")[1] : "INSP";
              return (
                <div
                  key={row.id || Math.random()}
                  className="flex items-center justify-between p-3 rounded-xl bg-gray-50/80 hover:bg-emerald-50/50 border border-gray-200/70 transition-all gap-3 text-xs"
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="w-9 h-9 rounded-xl bg-emerald-100 text-emerald-800 font-black text-xs flex items-center justify-center flex-shrink-0 border border-emerald-200">
                      {badgeTag}
                    </div>
                    <div className="min-w-0 space-y-0.5">
                      <div className="flex items-center gap-2">
                        <span className="font-extrabold text-slate-900 text-xs truncate">{codeStr}</span>
                        <span className="text-[10px] text-slate-400 font-mono flex items-center gap-0.5">
                          <Clock className="w-3.5 h-3.5 text-slate-400" /> {row.date || "Realtime"}
                        </span>
                      </div>
                      <div className="flex items-center gap-3 text-[11px] text-slate-600 font-medium truncate">
                        <span className="flex items-center gap-1 text-emerald-700 font-bold">
                          <MapPin className="w-3 h-3 text-emerald-600" /> Cây: {row.treeCode || "Gốc sầu riêng"} ({row.zone || "Khu vực"})
                        </span>
                        <span className="flex items-center gap-1 text-slate-500">
                          <User className="w-3 h-3" /> NV: {row.inspector || "Kỹ thuật viên"}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="flex items-center gap-3 flex-shrink-0">
                    {getStatusBadge(row.status, row.result)}
                    <button
                      type="button"
                      className="p-1.5 text-slate-400 hover:text-emerald-700 hover:bg-white rounded-lg transition-all cursor-pointer"
                      title="Xem chi tiết kiểm tra"
                    >
                      <ChevronRight className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </Card>
  );
}
