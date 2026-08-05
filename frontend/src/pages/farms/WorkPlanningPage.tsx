import { useState } from "react";
import { Calendar, Plus, Clock, CheckCircle2, MapPin, User, CheckSquare, Users, XCircle, Search, FileText } from "lucide-react";
import Card from "@/components/dashboard/Shared/Card";
import SectionTitle from "@/components/dashboard/Shared/SectionTitle";

// Interface for Task Assignment (Tab 1)
interface PlanTask {
  id: string;
  title: string;
  farmZone: string;
  scheduledDate: string;
  assignee: string;
  priority: "Cao" | "Trung bình" | "Thường";
  status: "Chưa bắt đầu" | "Đang thực hiện" | "Hoàn thành";
}

// Interface for Log Approval (Tab 2)
interface LogEntry {
  id: string;
  code: string;
  submittedBy: string;
  taskName: string;
  zoneName: string;
  submittedTime: string;
  note: string;
  status: "Chờ duyệt" | "Đã phê duyệt" | "Yêu cầu làm lại";
}

const INITIAL_PLANS: PlanTask[] = [
  {
    id: "plan-1",
    title: "Phun phân bón lá Canxi-Bo & Vi lượng đọt non",
    farmZone: "Khu A - Sầu Riêng Thái (120 cây)",
    scheduledDate: "06/08/2026",
    assignee: "Nguyễn Văn Tèo",
    priority: "Cao",
    status: "Đang thực hiện",
  },
  {
    id: "plan-2",
    title: "Xử lý quét vôi gốc & rải Ridomil phòng nấm xì mủ",
    farmZone: "Khu B - Sầu Riêng Ri6 (90 cây)",
    scheduledDate: "07/08/2026",
    assignee: "Trần Văn Bình",
    priority: "Cao",
    status: "Chưa bắt đầu",
  },
  {
    id: "plan-3",
    title: "Kiểm tra hệ thống van tưới nhỏ giọt LoRaWAN Drip",
    farmZone: "Khu C & D (140 cây)",
    scheduledDate: "08/08/2026",
    assignee: "Kỹ thuật viên Vie-farm",
    priority: "Trung bình",
    status: "Chưa bắt đầu",
  },
];

const INITIAL_LOGS: LogEntry[] = [
  {
    id: "log-1",
    code: "LOG-2026-0801",
    submittedBy: "Nguyễn Văn Tèo",
    taskName: "Đã phun phân bón lá Canxi-Bo & vi lượng đọt non 120 cây",
    zoneName: "Khu A - Sầu Riêng Thái",
    submittedTime: "Hôm nay 11:30",
    note: "Đã pha đúng tỷ lệ 1:500, đọt non nhú đều đẹp.",
    status: "Chờ duyệt",
  },
  {
    id: "log-2",
    code: "LOG-2026-0802",
    submittedBy: "Trần Văn Bình",
    taskName: "Đã quét vôi gốc & rải Ridomil Gold cây bị xì mủ SR-EAYONG-019",
    zoneName: "Khu B - Sầu Riêng Ri6",
    submittedTime: "Hôm nay 10:15",
    note: "Vết xì mủ cạo sạch vỏ, bôi Boóc-đô 10%.",
    status: "Chờ duyệt",
  },
  {
    id: "log-3",
    code: "LOG-2026-0803",
    submittedBy: "Lê Thị Hoa",
    taskName: "Bón phân hữu cơ nở 2kg/gốc cho 50 cây khu A",
    zoneName: "Khu A - Sầu Riêng Thái",
    submittedTime: "Hôm qua 16:45",
    note: "Phân rải xung quanh đường hình chiếu tán lá.",
    status: "Đã phê duyệt",
  },
];

export default function WorkPlanningPage() {
  const [activeTab, setActiveTab] = useState<"assignment" | "approval">("assignment");

  // Tab 1 States
  const [plans, setPlans] = useState<PlanTask[]>(INITIAL_PLANS);
  const [showAddModal, setShowAddModal] = useState(false);
  const [newTitle, setNewTitle] = useState("");
  const [newZone, setNewZone] = useState("Khu A - Sầu Riêng Thái");
  const [newAssignee, setNewAssignee] = useState("Nguyễn Văn Tèo");

  // Tab 2 States
  const [logs, setLogs] = useState<LogEntry[]>(INITIAL_LOGS);

  const handleAddPlan = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTitle.trim()) return;
    const item: PlanTask = {
      id: `plan-${Date.now()}`,
      title: newTitle,
      farmZone: newZone,
      scheduledDate: new Date().toLocaleDateString("vi-VN"),
      assignee: newAssignee,
      priority: "Trung bình",
      status: "Chưa bắt đầu",
    };
    setPlans([item, ...plans]);
    setNewTitle("");
    setShowAddModal(false);
  };

  const handleApproveLog = (id: string) => {
    setLogs(logs.map((l) => (l.id === id ? { ...l, status: "Đã phê duyệt" } : l)));
  };

  const handleRejectLog = (id: string) => {
    setLogs(logs.map((l) => (l.id === id ? { ...l, status: "Yêu cầu làm lại" } : l)));
  };

  const pendingLogCount = logs.filter((l) => l.status === "Chờ duyệt").length;

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto">
      {/* HEADER BAR & SUB-TABS */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-5 rounded-[20px] border border-gray-200/90 shadow-xs">
        <div>
          <h1 className="text-xl font-black text-gray-900 flex items-center gap-2">
            <Calendar className="w-6 h-6 text-emerald-600" />
            <span>Kế Hoạch & Nhật Ký Công Việc Trang Trại</span>
          </h1>
          <p className="text-xs text-gray-500 font-medium mt-1">
            Giao việc cho nhân công thực địa & phê duyệt nhật ký chăm sóc sầu riêng
          </p>
        </div>

        {/* 2 SUB TABS */}
        <div className="flex items-center gap-2 bg-slate-100 p-1.5 rounded-2xl border border-slate-200">
          <button
            type="button"
            onClick={() => setActiveTab("assignment")}
            className={`px-4 py-2 rounded-xl text-xs font-black transition-all cursor-pointer flex items-center gap-2 ${
              activeTab === "assignment"
                ? "bg-emerald-700 text-white shadow-sm"
                : "text-slate-600 hover:text-slate-900 hover:bg-slate-200/70"
            }`}
          >
            <Users className="w-4 h-4" />
            <span>👥 Giao Việc Cho Nhân Công</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab("approval")}
            className={`px-4 py-2 rounded-xl text-xs font-black transition-all cursor-pointer flex items-center gap-2 ${
              activeTab === "approval"
                ? "bg-emerald-700 text-white shadow-sm"
                : "text-slate-600 hover:text-slate-900 hover:bg-slate-200/70"
            }`}
          >
            <CheckSquare className="w-4 h-4" />
            <span>☑️ Phê Duyệt Nhật Ký</span>
            {pendingLogCount > 0 && (
              <span className="px-2 py-0.5 rounded-full bg-rose-500 text-white text-[10px] font-black">
                {pendingLogCount}
              </span>
            )}
          </button>
        </div>
      </div>

      {/* TAB 1: GIAO VIỆC CHO NHÂN CÔNG */}
      {activeTab === "assignment" && (
        <div className="space-y-6">
          {/* TOP ACTIONS */}
          <div className="flex justify-between items-center">
            <div className="text-xs font-bold text-slate-500">
              Tổng số công việc tuần này: <b className="text-emerald-700 font-black">{plans.length} nhiệm vụ</b>
            </div>
            <button
              type="button"
              onClick={() => setShowAddModal(true)}
              className="px-4 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold text-xs shadow-md flex items-center gap-2 transition-all cursor-pointer hover:scale-105 active:scale-95"
            >
              <Plus className="w-4 h-4" />
              <span>+ Phân Công Công Việc Mới</span>
            </button>
          </div>

          {/* STATS CARDS */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-emerald-50 border border-emerald-200 p-4 rounded-2xl flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-emerald-800">Tổng Công Việc Tuần</span>
                <div className="text-2xl font-black text-emerald-950 mt-1">{plans.length} ca</div>
              </div>
              <Calendar className="w-8 h-8 text-emerald-600 opacity-80" />
            </div>

            <div className="bg-amber-50 border border-amber-200 p-4 rounded-2xl flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-amber-800">Đang Thực Hiện</span>
                <div className="text-2xl font-black text-amber-950 mt-1">
                  {plans.filter((p) => p.status === "Đang thực hiện").length} ca
                </div>
              </div>
              <Clock className="w-8 h-8 text-amber-600 opacity-80" />
            </div>

            <div className="bg-blue-50 border border-blue-200 p-4 rounded-2xl flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-blue-800">Đã Hoàn Thành</span>
                <div className="text-2xl font-black text-blue-950 mt-1">
                  {plans.filter((p) => p.status === "Hoàn thành").length} ca
                </div>
              </div>
              <CheckCircle2 className="w-8 h-8 text-blue-600 opacity-80" />
            </div>
          </div>

          {/* TASK LIST TABLE */}
          <Card className="p-5 border border-gray-200/90 shadow-md rounded-[20px] bg-white space-y-4">
            <SectionTitle
              icon={<Users className="w-5 h-5 text-emerald-600" />}
              title="Danh Sách Nhiệm Vụ Đã Phân Công Nhân Công"
              size="section"
              subtitle="Theo dõi tiến độ thực hiện thực địa tại từng khu vực"
            />

            <div className="space-y-3">
              {plans.map((p) => (
                <div
                  key={p.id}
                  className="p-4 rounded-2xl bg-gray-50/90 border border-gray-200 hover:border-emerald-300 transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs"
                >
                  <div className="space-y-1.5 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="px-2 py-0.5 rounded-md font-black bg-emerald-100 text-emerald-800 text-[10px]">
                        {p.priority}
                      </span>
                      <h3 className="font-extrabold text-sm text-gray-900 truncate">{p.title}</h3>
                    </div>
                    <div className="flex items-center gap-4 text-gray-600 font-medium flex-wrap">
                      <span className="flex items-center gap-1 text-emerald-700 font-bold">
                        <MapPin className="w-3.5 h-3.5" /> {p.farmZone}
                      </span>
                      <span className="flex items-center gap-1 text-slate-700 font-extrabold">
                        <User className="w-3.5 h-3.5 text-slate-400" /> Nhân công: {p.assignee}
                      </span>
                      <span className="flex items-center gap-1 font-mono text-slate-400">
                        <Clock className="w-3.5 h-3.5" /> Hạn: {p.scheduledDate}
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center gap-3 flex-shrink-0">
                    <span
                      className={`px-3 py-1 rounded-full text-xs font-black border ${
                        p.status === "Đang thực hiện"
                          ? "bg-amber-100 text-amber-800 border-amber-300"
                          : p.status === "Hoàn thành"
                          ? "bg-emerald-100 text-emerald-800 border-emerald-300"
                          : "bg-slate-100 text-slate-700 border-slate-300"
                      }`}
                    >
                      {p.status}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </Card>
        </div>
      )}

      {/* TAB 2: PHÊ DUYỆT NHẬT KÝ */}
      {activeTab === "approval" && (
        <div className="space-y-6">
          {/* STATS CARDS */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-amber-50 border border-amber-200 p-4 rounded-2xl flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-amber-800">Nhật ký Chờ Duyệt</span>
                <div className="text-2xl font-black text-amber-950 mt-1">
                  {logs.filter((l) => l.status === "Chờ duyệt").length} nhật ký
                </div>
              </div>
              <Clock className="w-8 h-8 text-amber-600 opacity-80" />
            </div>

            <div className="bg-emerald-50 border border-emerald-200 p-4 rounded-2xl flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-emerald-800">Đã Phê Duyệt</span>
                <div className="text-2xl font-black text-emerald-950 mt-1">
                  {logs.filter((l) => l.status === "Đã phê duyệt").length} nhật ký
                </div>
              </div>
              <CheckCircle2 className="w-8 h-8 text-emerald-600 opacity-80" />
            </div>

            <div className="bg-rose-50 border border-rose-200 p-4 rounded-2xl flex items-center justify-between">
              <div>
                <span className="text-xs font-bold text-rose-800">Yêu cầu Làm lại</span>
                <div className="text-2xl font-black text-rose-950 mt-1">
                  {logs.filter((l) => l.status === "Yêu cầu làm lại").length} nhật ký
                </div>
              </div>
              <XCircle className="w-8 h-8 text-rose-600 opacity-80" />
            </div>
          </div>

          {/* APPROVAL LIST CONTAINER */}
          <Card className="p-5 border border-gray-200/90 shadow-md rounded-[20px] bg-white space-y-4">
            <SectionTitle
              icon={<CheckSquare className="w-5 h-5 text-emerald-600" />}
              title="Danh Sách Nhật Ký Nông Vụ Cần Chủ Vườn Duyệt"
              size="section"
              subtitle="Xác nhận báo cáo công việc từ công nhân thực địa"
            />

            <div className="space-y-3">
              {logs.map((l) => (
                <div
                  key={l.id}
                  className="p-4 rounded-2xl bg-gray-50/90 border border-gray-200 hover:border-emerald-300 transition-all space-y-2 text-xs"
                >
                  <div className="flex items-center justify-between gap-2">
                    <div className="flex items-center gap-2">
                      <span className="font-mono text-[11px] bg-slate-200 text-slate-800 px-2 py-0.5 rounded font-black">
                        {l.code}
                      </span>
                      <span className="font-extrabold text-xs text-emerald-800 flex items-center gap-1">
                        <User className="w-3.5 h-3.5" /> Công nhân: {l.submittedBy}
                      </span>
                    </div>

                    <span
                      className={`px-2.5 py-0.5 rounded-full text-[11px] font-black border ${
                        l.status === "Chờ duyệt"
                          ? "bg-amber-100 text-amber-800 border-amber-300"
                          : l.status === "Đã phê duyệt"
                          ? "bg-emerald-100 text-emerald-800 border-emerald-300"
                          : "bg-rose-100 text-rose-800 border-rose-300"
                      }`}
                    >
                      {l.status}
                    </span>
                  </div>

                  <p className="font-black text-sm text-gray-900">{l.taskName}</p>

                  <div className="flex items-center justify-between pt-2 border-t border-gray-200/60 text-gray-600 flex-wrap gap-2">
                    <div className="flex items-center gap-4">
                      <span className="flex items-center gap-1 text-emerald-700 font-bold">
                        <MapPin className="w-3.5 h-3.5" /> {l.zoneName}
                      </span>
                      <span className="italic text-gray-500">Ghi chú: "{l.note}"</span>
                    </div>

                    {l.status === "Chờ duyệt" && (
                      <div className="flex items-center gap-2">
                        <button
                          type="button"
                          onClick={() => handleRejectLog(l.id)}
                          className="px-3 py-1 rounded-lg bg-rose-100 hover:bg-rose-200 text-rose-700 font-bold transition-all cursor-pointer"
                        >
                          Từ chối
                        </button>
                        <button
                          type="button"
                          onClick={() => handleApproveLog(l.id)}
                          className="px-3 py-1 rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold transition-all cursor-pointer shadow-xs"
                        >
                          Phê Duyệt ☑️
                        </button>
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </Card>
        </div>
      )}

      {/* CREATE MODAL FOR TASK ASSIGNMENT */}
      {showAddModal && (
        <div className="fixed inset-0 z-50 bg-black/50 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-3xl p-6 w-full max-w-md shadow-2xl border border-emerald-100 space-y-4">
            <h3 className="text-base font-black text-gray-900 border-b border-gray-100 pb-3">
              + Phân Công Công Việc Cho Nhân Công
            </h3>
            <form onSubmit={handleAddPlan} className="space-y-3 text-xs">
              <div>
                <label className="block font-bold text-gray-700 mb-1">Nội dung công việc:</label>
                <input
                  type="text"
                  required
                  value={newTitle}
                  onChange={(e) => setNewTitle(e.target.value)}
                  placeholder="Ví dụ: Phun vi lượng đọt non Khu A..."
                  className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500"
                />
              </div>

              <div>
                <label className="block font-bold text-gray-700 mb-1">Khu vực trang trại:</label>
                <select
                  value={newZone}
                  onChange={(e) => setNewZone(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500"
                >
                  <option value="Khu A - Sầu Riêng Thái">Khu A - Sầu Riêng Thái</option>
                  <option value="Khu B - Sầu Riêng Ri6">Khu B - Sầu Riêng Ri6</option>
                  <option value="Khu C - Sầu Riêng Musang King">Khu C - Sầu Riêng Musang King</option>
                  <option value="Khu D - Sầu Riêng Thái">Khu D - Sầu Riêng Thái</option>
                </select>
              </div>

              <div>
                <label className="block font-bold text-gray-700 mb-1">Công nhân phụ trách:</label>
                <input
                  type="text"
                  value={newAssignee}
                  onChange={(e) => setNewAssignee(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500"
                />
              </div>

              <div className="flex items-center justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowAddModal(false)}
                  className="px-4 py-2 rounded-xl bg-gray-100 hover:bg-gray-200 text-gray-700 font-bold"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white font-extrabold shadow-sm"
                >
                  Lưu phân công
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
