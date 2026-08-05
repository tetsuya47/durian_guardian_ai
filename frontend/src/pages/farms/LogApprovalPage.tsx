import { useState } from "react";
import { CheckSquare, CheckCircle2, XCircle, Clock, MapPin, User, FileText } from "lucide-react";
import Card from "@/components/dashboard/Shared/Card";
import SectionTitle from "@/components/dashboard/Shared/SectionTitle";

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

export default function LogApprovalPage() {
  const [logs, setLogs] = useState<LogEntry[]>(INITIAL_LOGS);

  const handleApprove = (id: string) => {
    setLogs(logs.map((l) => (l.id === id ? { ...l, status: "Đã phê duyệt" } : l)));
  };

  const handleReject = (id: string) => {
    setLogs(logs.map((l) => (l.id === id ? { ...l, status: "Yêu cầu làm lại" } : l)));
  };

  return (
    <div className="p-6 space-y-6 max-w-7xl mx-auto">
      {/* HEADER BAR */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-[20px] border border-gray-200/90 shadow-xs">
        <div>
          <h1 className="text-xl font-black text-gray-900 flex items-center gap-2">
            <CheckSquare className="w-6 h-6 text-emerald-600" />
            <span>Phê Duyệt Nhật Ký Nông Vụ Thực Địa</span>
          </h1>
          <p className="text-xs text-gray-500 font-medium mt-1">
            Duyệt báo cáo công việc & nhật ký chăm sóc sầu riêng do nhân công/kỹ thuật viên gửi lên
          </p>
        </div>
      </div>

      {/* STATS CARDS */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <div className="bg-amber-50 border border-amber-200 p-4 rounded-2xl flex items-center justify-between">
          <div>
            <span className="text-xs font-bold text-amber-800">Nhật ký Chờ duyệt</span>
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
          icon={<FileText className="w-5 h-5 text-emerald-600" />}
          title="Danh Sách Nhật Ký Nông Vụ Cần Phê Duyệt"
          size="section"
          subtitle="Kiểm tra chi tiết và xác nhận hoàn thành công việc"
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
                    <User className="w-3.5 h-3.5" /> {l.submittedBy}
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

              <div className="flex items-center justify-between pt-1 border-t border-gray-200/60 text-gray-600">
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
                      onClick={() => handleReject(l.id)}
                      className="px-3 py-1 rounded-lg bg-rose-100 hover:bg-rose-200 text-rose-700 font-bold transition-all cursor-pointer"
                    >
                      Từ chối
                    </button>
                    <button
                      type="button"
                      onClick={() => handleApprove(l.id)}
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
  );
}
