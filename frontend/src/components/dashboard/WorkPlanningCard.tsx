import { useState, useMemo } from "react";
import { Calendar, Clock, MapPin, User, CheckCircle2, AlertCircle, Filter, Plus, ArrowRight, ShieldAlert } from "lucide-react";
import Card from "./Shared/Card";
import SectionTitle from "./Shared/SectionTitle";

export interface TaskItem {
  id: string;
  time: string;
  taskTitle: string;
  zone: string;
  assignee: string;
  status: "Đang thực hiện" | "Chưa thực hiện" | "Hoàn thành";
  priority: "Cao" | "Trung bình" | "Thường";
  dateGroup: "today" | "upcoming";
}

const DEFAULT_WORK_TASKS: TaskItem[] = [
  {
    id: "task-1",
    time: "08:00",
    taskTitle: "Bón phân NPK vi lượng & Canxi-Bo đọt non",
    zone: "Khu A - Sầu Riêng Thái",
    assignee: "Nguyễn Văn A",
    status: "Đang thực hiện",
    priority: "Cao",
    dateGroup: "today",
  },
  {
    id: "task-2",
    time: "10:30",
    taskTitle: "Phún thuốc nấm vi sinh phòng thán thư lá",
    zone: "Khu B - Sầu Riêng Ri6",
    assignee: "Nguyễn Văn Tèo",
    status: "Chưa thực hiện",
    priority: "Trung bình",
    dateGroup: "today",
  },
  {
    id: "task-3",
    time: "14:00",
    taskTitle: "Kiểm tra AI chẩn đoán rệp sáp & sâu hại",
    zone: "Khu C - Sầu Riêng Musang King",
    assignee: "AI Agronomist Bot",
    status: "Chưa thực hiện",
    priority: "Cao",
    dateGroup: "today",
  },
  {
    id: "task-4",
    time: "16:30",
    taskTitle: "Tưới nhỏ giọt 30 phút bằng van tự động DGA SmartValve",
    zone: "Khu D - Sầu Riêng Thái",
    assignee: "Trần Văn Bình",
    status: "Chưa thực hiện",
    priority: "Thường",
    dateGroup: "today",
  },
  // Upcoming tasks
  {
    id: "task-5",
    time: "07:30 (Ngày mai)",
    taskTitle: "Quét vôi gốc cây & bôi Ridomil Gold xì mủ thân",
    zone: "Khu A - Sầu Riêng Thái",
    assignee: "Nguyễn Văn A",
    status: "Chưa thực hiện",
    priority: "Cao",
    dateGroup: "upcoming",
  },
  {
    id: "task-6",
    time: "09:00 (Ngày mai)",
    taskTitle: "Đo chỉ số EC/pH & độ ẩm đất bằng DurianSense Pro",
    zone: "Khu C - Sầu Riêng Musang King",
    assignee: "Nguyễn Văn Tèo",
    status: "Chưa thực hiện",
    priority: "Trung bình",
    dateGroup: "upcoming",
  },
  {
    id: "task-7",
    time: "15:00 (08/08)",
    taskTitle: "Tỉa cành tạo tán & cắt chồi dại gốc ghép",
    zone: "Khu B - Sầu Riêng Ri6",
    assignee: "Lê Thị Hoa",
    status: "Chưa thực hiện",
    priority: "Thường",
    dateGroup: "upcoming",
  },
];

export default function WorkPlanningCard() {
  const [activeTab, setActiveTab] = useState<"today" | "upcoming">("today");

  const filteredTasks = useMemo(() => {
    return DEFAULT_WORK_TASKS.filter((t) => t.dateGroup === activeTab);
  }, [activeTab]);

  const getStatusBadge = (status: TaskItem["status"]) => {
    if (status === "Đang thực hiện") {
      return (
        <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-black bg-amber-100 text-amber-800 border border-amber-300 shadow-2xs">
          <span className="w-2 h-2 rounded-full bg-amber-500 animate-ping" />
          <span>Đang thực hiện</span>
        </span>
      );
    }
    if (status === "Hoàn thành") {
      return (
        <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-black bg-emerald-100 text-emerald-800 border border-emerald-300">
          <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
          <span>Hoàn thành</span>
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-bold bg-slate-100 text-slate-600 border border-slate-300">
        <Clock className="w-3.5 h-3.5 text-slate-400" />
        <span>Chưa thực hiện</span>
      </span>
    );
  };

  const getPriorityBadge = (priority: TaskItem["priority"]) => {
    if (priority === "Cao") {
      return (
        <span className="px-2 py-0.5 rounded-md text-[10px] font-black bg-rose-100 text-rose-800 border border-rose-200">
          🔥 Cao
        </span>
      );
    }
    if (priority === "Trung bình") {
      return (
        <span className="px-2 py-0.5 rounded-md text-[10px] font-black bg-amber-100 text-amber-800 border border-amber-200">
          ⚡ Trung bình
        </span>
      );
    }
    return (
      <span className="px-2 py-0.5 rounded-md text-[10px] font-bold bg-slate-100 text-slate-600 border border-slate-200">
        🔹 Thường
      </span>
    );
  };

  return (
    <Card className="flex flex-col overflow-hidden h-full border border-gray-200/90 shadow-md rounded-[20px] bg-white p-5 space-y-4">
      {/* HEADER BAR */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-gray-100">
        <SectionTitle
          icon={<Calendar className="w-5.5 h-5.5 text-emerald-600" />}
          title="Lập Kế Hoạch Công Việc"
          size="section"
          subtitle="Danh sách kế hoạch phân công nông vụ & kiểm tra vườn thực địa"
        />

        {/* TODAY / UPCOMING TABS */}
        <div className="flex items-center gap-1.5 bg-slate-100/90 p-1 rounded-xl border border-slate-200">
          <button
            type="button"
            onClick={() => setActiveTab("today")}
            className={`px-3.5 py-1.5 rounded-lg text-xs font-black transition-all cursor-pointer flex items-center gap-1.5 ${
              activeTab === "today"
                ? "bg-emerald-700 text-white shadow-sm"
                : "text-slate-600 hover:text-slate-900 hover:bg-slate-200/70"
            }`}
          >
            <span>📅 Công việc hôm nay</span>
            <span className="px-1.5 py-0.2 rounded-full bg-emerald-900 text-emerald-100 text-[10px]">
              {DEFAULT_WORK_TASKS.filter((t) => t.dateGroup === "today").length}
            </span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab("upcoming")}
            className={`px-3.5 py-1.5 rounded-lg text-xs font-black transition-all cursor-pointer flex items-center gap-1.5 ${
              activeTab === "upcoming"
                ? "bg-emerald-700 text-white shadow-sm"
                : "text-slate-600 hover:text-slate-900 hover:bg-slate-200/70"
            }`}
          >
            <span>⏩ Công việc sắp tới</span>
            <span className="px-1.5 py-0.2 rounded-full bg-slate-300 text-slate-800 text-[10px]">
              {DEFAULT_WORK_TASKS.filter((t) => t.dateGroup === "upcoming").length}
            </span>
          </button>
        </div>
      </div>

      {/* TASK LIST TABLE */}
      <div className="flex-1 overflow-y-auto space-y-2.5 min-h-[260px] max-h-[360px]">
        {filteredTasks.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-10 text-center space-y-2">
            <div className="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center text-slate-400">
              <Calendar className="w-6 h-6" />
            </div>
            <p className="text-xs font-bold text-slate-500">Chưa có kế hoạch công việc nào trong danh mục này</p>
          </div>
        ) : (
          filteredTasks.map((task) => (
            <div
              key={task.id}
              className="p-3.5 rounded-2xl bg-gray-50/80 hover:bg-emerald-50/50 border border-gray-200/80 hover:border-emerald-300 transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs"
            >
              {/* TIME & TITLE & ZONE & ASSIGNEE */}
              <div className="flex items-center gap-3.5 min-w-0 flex-1">
                {/* TIME BADGE */}
                <div className="w-16 h-11 rounded-xl bg-emerald-100/90 text-emerald-900 font-black text-xs flex flex-col items-center justify-center flex-shrink-0 border border-emerald-200 shadow-2xs">
                  <span className="text-[10px] text-emerald-700 uppercase tracking-tighter">Giờ</span>
                  <span className="font-mono text-xs font-black leading-none">{task.time}</span>
                </div>

                {/* CONTENT */}
                <div className="min-w-0 space-y-1">
                  <div className="flex items-center gap-2 flex-wrap">
                    {getPriorityBadge(task.priority)}
                    <h3 className="font-extrabold text-slate-900 text-xs sm:text-sm truncate leading-snug">
                      {task.taskTitle}
                    </h3>
                  </div>

                  <div className="flex items-center gap-4 text-[11px] text-slate-600 font-semibold flex-wrap">
                    <span className="flex items-center gap-1 text-emerald-700 font-bold">
                      <MapPin className="w-3.5 h-3.5 text-emerald-600" /> {task.zone}
                    </span>
                    <span className="flex items-center gap-1 text-slate-600 font-extrabold">
                      <User className="w-3.5 h-3.5 text-slate-400" /> {task.assignee}
                    </span>
                  </div>
                </div>
              </div>

              {/* STATUS BADGE */}
              <div className="flex items-center justify-between sm:justify-end gap-3 flex-shrink-0 border-t sm:border-t-0 pt-2 sm:pt-0 border-gray-200/60">
                {getStatusBadge(task.status)}
              </div>
            </div>
          ))
        )}
      </div>
    </Card>
  );
}
