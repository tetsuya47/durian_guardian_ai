import { useEffect, useState } from "react";
import { useParams, useNavigate } from "react-router-dom";
import {
  ArrowLeft,
  UserRound,
  MapPin,
  Building2,
  Trees,
  Grid3x3,
  Ruler,
  ClipboardList,
  ScanLine,
  AlertTriangle,
  UsersRound,
  Activity,
  Mail,
  Phone,
  CalendarDays,
  Send,
  Inbox,
  ShieldCheck,
  Clock3,
} from "lucide-react";
import StatCard from "../../components/common/StatCard";
import PageHeader from "../../components/common/PageHeader";
import LoadingState from "../../components/common/LoadingState";
import StatusChip from "../../components/common/StatusChip";
import { farmerOverviewService } from "../../services/farmerOverview.service";
import type { FarmerOverview } from "../../types/farmerOverview";
import { formatDateTime } from "../../utils/dateFormatter";
import { vi, ROLE_VI, NCR_STATUS_VI } from "../../utils/translate";

const SOURCE_META: Record<string, { label: string; icon: typeof Activity; color: string }> = {
  inspection: { label: "Kiểm tra", icon: ClipboardList, color: "text-blue-600 bg-blue-50" },
  detection: { label: "Phát hiện AI", icon: ScanLine, color: "text-violet-600 bg-violet-50" },
  alert: { label: "Cảnh báo", icon: AlertTriangle, color: "text-amber-600 bg-amber-50" },
  neighbor: { label: "Liên hệ hàng xóm", icon: UsersRound, color: "text-emerald-600 bg-emerald-50" },
};

function getRoleChipVariant(role: string): "Success" | "Warning" | "Info" | "Pending" {
  if (role === "Farm Owner" || role === "farmer") return "Success";
  return "Info";
}

function getNcrChipVariant(status: string): "Pending" | "Warning" | "Success" | "Error" | "Info" {
  switch (status) {
    case "contact_shared":
      return "Success";
    case "rejected":
      return "Error";
    case "pending":
      return "Pending";
    case "waiting_source_consent":
    case "waiting_target_consent":
      return "Warning";
    default:
      return "Info";
  }
}

function AddressText({ address }: { address?: FarmerOverview["profile"]["address"] | null }) {
  if (!address) return <span>—</span>;
  const parts = [address.detail, address.ward, address.district, address.province].filter(Boolean);
  return <span>{parts.join(", ") || "—"}</span>;
}

export default function FarmerOverviewPage() {
  const { user_id = "" } = useParams();
  const navigate = useNavigate();

  const [data, setData] = useState<FarmerOverview | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [retryKey, setRetryKey] = useState(0);

  useEffect(() => {
    let cancelled = false;
    farmerOverviewService
      .getOverview(user_id)
      .then((res) => {
        if (cancelled) return;
        setData(res);
        setError(null);
      })
      .catch((err: unknown) => {
        if (cancelled) return;
        const msg =
          err instanceof Error ? err.message : "Không thể tải dữ liệu tổng quan.";
        setError(msg);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [user_id, retryKey]);

  const back = () => navigate("/users");

  if (loading) {
    return (
      <div className="flex flex-col h-full space-y-4">
        <PageHeader compact title="Tổng quan nông dân" />
        <LoadingState variant="Card" />
        <LoadingState variant="List" />
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="flex flex-col h-full space-y-4">
        <PageHeader compact title="Tổng quan nông dân" />
        <div className="bg-white border border-gray-100 rounded-[18px] p-8 text-center">
          <p className="text-red-600 text-sm font-semibold">
            {error || "Không có dữ liệu."}
          </p>
          <div className="mt-4 flex items-center justify-center gap-3">
            {error && (
              <button
                onClick={() => setRetryKey((k) => k + 1)}
                type="button"
                className="px-4 py-2 border border-[#1E8449] text-[#1E8449] rounded-[12px] text-sm font-semibold hover:bg-emerald-50 transition-all"
              >
                Thử lại
              </button>
            )}
            <button
              onClick={back}
              type="button"
              className="px-4 py-2 bg-[#1E8449] text-white rounded-[12px] text-sm font-semibold hover:bg-emerald-700 transition-all"
            >
              Quay lại danh sách người dùng
            </button>
          </div>
        </div>
      </div>
    );
  }

  const { profile, farm, inspection, alerts, neighbor, activities } = data;
  const initials = profile.full_name
    .split(" ")
    .filter(Boolean)
    .slice(-2)
    .map((w) => w[0])
    .join("")
    .toUpperCase();

  return (
    <div className="flex flex-col h-full space-y-4 overflow-y-auto">
      <PageHeader
        compact
        title="Tổng quan nông dân"
        actions={
          <button
            onClick={back}
            type="button"
            className="inline-flex items-center gap-2 px-4 py-2 border border-gray-200 bg-white rounded-[12px] text-sm font-semibold text-gray-700 hover:bg-gray-50 transition-all"
          >
            <ArrowLeft className="w-4 h-4" />
            Người dùng
          </button>
        }
      />

      {/* Profile */}
      <div className="bg-white border border-gray-100 rounded-[18px] p-5 shadow-[0_2px_8px_rgba(0,0,0,0.05)]">
        <div className="flex items-start gap-4">
          <div className="w-16 h-16 rounded-full bg-emerald-50 border border-emerald-100 flex items-center justify-center text-[#1E8449] font-bold text-[20px] flex-shrink-0">
            {initials || <UserRound className="w-8 h-8" />}
          </div>
          <div className="flex-1 min-w-0">
            <div className="flex items-center gap-3 flex-wrap">
              <h2 className="text-[20px] font-bold text-gray-900 tracking-tight">
                {profile.full_name}
              </h2>
              <StatusChip
                label={vi(ROLE_VI, profile.role) || profile.role}
                variant={getRoleChipVariant(profile.role)}
              />
              <StatusChip
                label={profile.status === "ACTIVE" || profile.status === "Active" ? "Hoạt động" : profile.status || "—"}
                variant={profile.status === "ACTIVE" || profile.status === "Active" ? "Healthy" : "Pending"}
              />
            </div>
            <div className="mt-1 text-[12px] font-semibold text-gray-400 uppercase tracking-wider">
              {profile.user_code}
            </div>
            <div className="mt-3 grid grid-cols-1 md:grid-cols-2 gap-x-8 gap-y-2 text-[13px] text-gray-600">
              <div className="flex items-center gap-2">
                <Mail className="w-4 h-4 text-gray-400" />
                <span className="truncate">{profile.email || "—"}</span>
              </div>
              <div className="flex items-center gap-2">
                <Phone className="w-4 h-4 text-gray-400" />
                <span>{profile.phone || "—"}</span>
              </div>
              <div className="flex items-center gap-2">
                <MapPin className="w-4 h-4 text-gray-400" />
                <span className="truncate">
                  <AddressText address={profile.address} />
                </span>
              </div>
              <div className="flex items-center gap-2">
                <Building2 className="w-4 h-4 text-gray-400" />
                <span className="truncate">{profile.company_name || "—"}</span>
              </div>
              <div className="flex items-center gap-2">
                <Trees className="w-4 h-4 text-gray-400" />
                <span className="truncate">{profile.farm_name || "—"}</span>
              </div>
              <div className="flex items-center gap-2">
                <CalendarDays className="w-4 h-4 text-gray-400" />
                <span>{formatDateTime(profile.created_at)}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Farm overview */}
      <div>
        <div className="text-[12px] font-semibold text-gray-400 uppercase tracking-wider mb-2">
          Trang trại
        </div>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          <StatCard compact title="Số trang trại" value={farm.total_farms} icon={Building2} />
          <StatCard compact title="Khu vực" value={farm.total_zones} icon={Grid3x3} color="text-indigo-600" />
          <StatCard compact title="Cây trồng" value={farm.total_trees} icon={Trees} color="text-amber-600" />
          <StatCard compact title="Diện tích (ha)" value={farm.total_area_hectare} icon={Ruler} color="text-blue-600" />
        </div>
        {farm.districts.length > 0 && (
          <p className="mt-2 text-[12px] text-gray-500">
            Huyện: <span className="font-semibold text-gray-700">{farm.districts.join(", ")}</span>
          </p>
        )}
      </div>

      {/* Inspection & AI detection (separate blocks) */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="bg-white border border-gray-100 rounded-[18px] p-4 shadow-[0_2px_8px_rgba(0,0,0,0.05)]">
          <div className="flex items-center gap-2 mb-3">
            <ClipboardList className="w-4 h-4 text-blue-600" />
            <span className="text-[13px] font-bold text-gray-800">Kiểm tra</span>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <div className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider">Tổng lượt kiểm tra</div>
              <div className="text-[24px] font-bold text-gray-900">{inspection.inspection.total_inspections}</div>
            </div>
            <div>
              <div className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider">Kiểm tra gần nhất</div>
              <div className="text-[16px] font-bold text-gray-900">{formatDateTime(inspection.inspection.last_inspection)}</div>
            </div>
          </div>
        </div>

        <div className="bg-white border border-gray-100 rounded-[18px] p-4 shadow-[0_2px_8px_rgba(0,0,0,0.05)]">
          <div className="flex items-center gap-2 mb-3">
            <ScanLine className="w-4 h-4 text-violet-600" />
            <span className="text-[13px] font-bold text-gray-800">Phát hiện AI</span>
          </div>
          <div className="grid grid-cols-3 gap-3">
            <div>
              <div className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider">Khỏe mạnh</div>
              <div className="text-[24px] font-bold text-emerald-600">{inspection.detection.healthy}</div>
            </div>
            <div>
              <div className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider">Bị bệnh</div>
              <div className="text-[24px] font-bold text-red-600">{inspection.detection.diseased}</div>
            </div>
            <div>
              <div className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider">Tỷ lệ bệnh</div>
              <div className="text-[24px] font-bold text-gray-900">{inspection.detection.detection_rate}%</div>
            </div>
          </div>
        </div>
      </div>

      {/* Alerts */}
      <div>
        <div className="text-[12px] font-semibold text-gray-400 uppercase tracking-wider mb-2">
          Cảnh báo
        </div>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          <StatCard compact title="Tổng cảnh báo" value={alerts.total_alerts} icon={AlertTriangle} color="text-amber-600" />
          <StatCard compact title="Nguy cơ cao" value={alerts.critical} icon={AlertTriangle} color="text-red-600" />
          <StatCard compact title="Nguy cơ trung bình" value={alerts.warning} icon={AlertTriangle} color="text-amber-500" />
          <StatCard compact title="Nguy cơ thấp" value={alerts.normal} icon={AlertTriangle} color="text-emerald-600" />
        </div>
      </div>

      {/* Neighbor contact */}
      <div>
        <div className="text-[12px] font-semibold text-gray-400 uppercase tracking-wider mb-2">
          Liên hệ hàng xóm
        </div>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3">
          <StatCard compact title="Đã gửi" value={neighbor.sent_requests} icon={Send} color="text-blue-600" />
          <StatCard compact title="Đã nhận" value={neighbor.received_requests} icon={Inbox} color="text-indigo-600" />
          <StatCard compact title="Đã chia sẻ liên hệ" value={neighbor.contact_shared} icon={ShieldCheck} color="text-emerald-600" />
          <StatCard compact title="Chờ đồng ý" value={neighbor.waiting_source_consent + neighbor.waiting_target_consent} icon={Clock3} color="text-amber-600" />
        </div>
        <div className="mt-2 flex flex-wrap gap-2">
          {[
            ["pending", neighbor.pending],
            ["waiting_source_consent", neighbor.waiting_source_consent],
            ["waiting_target_consent", neighbor.waiting_target_consent],
            ["rejected", neighbor.rejected],
            ["cancelled", neighbor.cancelled],
          ].map(([status, count]) => (
            <span
              key={status as string}
              className="inline-flex items-center gap-2 px-3 py-1.5 bg-white border border-gray-100 rounded-[10px] text-[12px] font-semibold text-gray-600"
            >
              <StatusChip label={vi(NCR_STATUS_VI, status as string) || (status as string)} variant={getNcrChipVariant(status as string)} />
              <span className="text-gray-900">{count as number}</span>
            </span>
          ))}
        </div>
      </div>

      {/* Activities */}
      <div>
        <div className="text-[12px] font-semibold text-gray-400 uppercase tracking-wider mb-2">
          Hoạt động gần đây
        </div>
        <div className="bg-white border border-gray-100 rounded-[18px] shadow-[0_2px_8px_rgba(0,0,0,0.05)] divide-y divide-gray-50">
          {activities.length === 0 ? (
            <div className="p-6 text-center text-[13px] text-gray-400">
              <Activity className="w-6 h-6 mx-auto mb-2 text-gray-300" />
              Chưa có hoạt động nào.
            </div>
          ) : (
            activities.map((item, idx) => {
              const meta = SOURCE_META[item.source] || SOURCE_META.neighbor;
              const Icon = meta.icon;
              return (
                <div key={`${item.source}-${idx}-${item.timestamp}`} className="flex items-start gap-3 px-5 py-3">
                  <div className={`w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0 ${meta.color}`}>
                    <Icon className="w-4 h-4" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2 min-w-0">
                      <span className="text-[13px] font-bold text-gray-800 truncate min-w-0">{item.type}</span>
                      <span className="text-[12px] text-gray-400 whitespace-nowrap shrink-0">{formatDateTime(item.timestamp)}</span>
                    </div>
                    <div className="text-[12px] text-gray-500 truncate">{item.detail}</div>
                  </div>
                </div>
              );
            })
          )}
        </div>
      </div>
    </div>
  );
}
