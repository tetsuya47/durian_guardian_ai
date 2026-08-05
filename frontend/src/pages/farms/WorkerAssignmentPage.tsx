import { useState } from "react";
import { UserPlus, Users, CheckCircle2, Clock, MapPin, Search } from "lucide-react";
import Card from "@/components/dashboard/Shared/Card";
import SectionTitle from "@/components/dashboard/Shared/SectionTitle";

interface WorkerTask {
  id: string;
  workerName: string;
  role: string;
  taskTitle: string;
  zoneName: string;
  deadline: string;
  status: "Chờ thực hiện" | "Đang làm" | "Hoàn thành";
}

const INITIAL_WORKER_TASKS: WorkerTask[] = [
  {
    id: "task-1",
    workerName: "Nguyễn Văn Tèo",
    role: "Kỹ thuật viên Trưởng",
    taskTitle: "Kiểm tra rệp sáp & xịt nấm trắng cây SR-EAYONG-088",
    zoneName: "Khu B - Sầu Riêng Ri6",
    deadline: "Hôm nay 17:00",
    status: "Đang làm",
  },
  {
    id: "task-2",
    workerName: "Trần Văn Bình",
    role: "Nhân công vận hành tưới",
    taskTitle: "Mở hệ thống van tưới nhỏ giọt DGA SmartValve 30 phút",
    zoneName: "Khu C & D",
    deadline: "Hôm nay 16:30",
    status: "Chờ thực hiện",
  },
  {
    id: "task-3",
    workerName: "Lê Thị Hoa",
    role: "Nhân công tỉa cành & cắt đọt",
    taskTitle: "Bón 2kg phân hữu cơ nở cho 50 cây khu A",
    zoneName: "Khu A - Sầu Riêng Thái",
    deadline: "06/08/2026 11:00",
    status: "Chờ thực hiện",
  },
];

export default function WorkerAssignmentPage() {
  const [tasks, setTasks] = useState<WorkerTask[]>(INITIAL_WORKER_TASKS);
  const [searchTerm, setSearchTerm] = useState("");

  const filteredTasks = tasks.filter(
    (t) =>
      t.workerName.toLowerCase().includes(searchTerm.toLowerCase()) ||
      t.taskTitle.toLowerCase().includes(searchTerm.toLowerCase()) ||
      t.zoneName.toLowerCase().includes(searchTerm.toLowerCase())
  );

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto">
      {/* HEADER BAR */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-[20px] border border-gray-200/90 shadow-xs">
        <div>
          <h1 className="text-xl font-black text-gray-900 flex items-center gap-2">
            <UserPlus className="w-6 h-6 text-emerald-600" />
            <span>Giao Việc Cho Nhân Công & Kỹ Thuật Viên</span>
          </h1>
          <p className="text-xs text-gray-500 font-medium mt-1">
            Phân công nhiệm vụ thực địa, giao ca & theo dõi tiến độ công nhân tại trang trại
          </p>
        </div>
      </div>

      {/* STATS OVERVIEW */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-emerald-50 border border-emerald-200 p-4 rounded-2xl flex items-center justify-between">
          <div>
            <span className="text-xs font-bold text-emerald-800">Tổng Nhân công</span>
            <div className="text-2xl font-black text-emerald-950 mt-1">5 nhân sự</div>
          </div>
          <Users className="w-8 h-8 text-emerald-600 opacity-80" />
        </div>

        <div className="bg-amber-50 border border-amber-200 p-4 rounded-2xl flex items-center justify-between">
          <div>
            <span className="text-xs font-bold text-amber-800">Nhiệm vụ Đang làm</span>
            <div className="text-2xl font-black text-amber-950 mt-1">
              {tasks.filter((t) => t.status === "Đang làm").length} ca
            </div>
          </div>
          <Clock className="w-8 h-8 text-amber-600 opacity-80" />
        </div>

        <div className="bg-blue-50 border border-blue-200 p-4 rounded-2xl flex items-center justify-between">
          <div>
            <span className="text-xs font-bold text-blue-800">Đã Hoàn Thành</span>
            <div className="text-2xl font-black text-blue-950 mt-1">
              {tasks.filter((t) => t.status === "Hoàn thành").length} ca
            </div>
          </div>
          <CheckCircle2 className="w-8 h-8 text-blue-600 opacity-80" />
        </div>
      </div>

      {/* SEARCH & TASK BOARD */}
      <Card className="p-5 border border-gray-200/90 shadow-md rounded-[20px] bg-white space-y-4">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <SectionTitle
            icon={<Users className="w-5 h-5 text-emerald-600" />}
            title="Bảng Phân Công Nhiệm Vụ Hàng Ngày"
            size="section"
            subtitle="Danh sách ca trực và công việc được giao"
          />

          <div className="relative max-w-xs w-full">
            <Search className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Tìm nhân công, công việc..."
              className="w-full pl-9 pr-4 py-2 bg-gray-50 border border-gray-200 rounded-xl text-xs text-gray-800 focus:outline-none focus:ring-2 focus:ring-emerald-500 font-medium"
            />
          </div>
        </div>

        <div className="space-y-3">
          {filteredTasks.map((t) => (
            <div
              key={t.id}
              className="p-4 rounded-2xl bg-gray-50/90 border border-gray-200 hover:border-emerald-300 transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs"
            >
              <div className="space-y-1.5 min-w-0">
                <div className="flex items-center gap-2">
                  <span className="font-extrabold text-xs bg-slate-200 text-slate-800 px-2 py-0.5 rounded">
                    {t.workerName} ({t.role})
                  </span>
                </div>
                <h3 className="font-extrabold text-sm text-gray-900">{t.taskTitle}</h3>
                <div className="flex items-center gap-4 text-gray-500 font-medium">
                  <span className="flex items-center gap-1 text-emerald-700 font-bold">
                    <MapPin className="w-3.5 h-3.5" /> {t.zoneName}
                  </span>
                  <span className="flex items-center gap-1 font-mono text-slate-400">
                    <Clock className="w-3.5 h-3.5" /> Hạn: {t.deadline}
                  </span>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <span
                  className={`px-3 py-1 rounded-full text-xs font-black border ${
                    t.status === "Đang làm"
                      ? "bg-amber-100 text-amber-800 border-amber-300"
                      : t.status === "Hoàn thành"
                      ? "bg-emerald-100 text-emerald-800 border-emerald-300"
                      : "bg-blue-100 text-blue-800 border-blue-300"
                  }`}
                >
                  {t.status}
                </span>
              </div>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}
