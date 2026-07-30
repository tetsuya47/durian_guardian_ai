import { memo, useState } from "react";
import { Eye } from "lucide-react";
import RecordDetailDrawer from "../common/RecordDetailDrawer";
import type { DetailSection } from "../common/RecordDetailDrawer";

export interface InspectionRow {
  id: string;
  time: string;
  treeCode: string;
  farm: string;
  zone: string;
  disease: string;
  risk: number;
  inspector: string;
  status: string;
  action: string;
}

interface InspectionTableProps {
  data: InspectionRow[];
}

function diseaseBadge(disease: string, risk: number): { label: string; className: string } {
  if (!disease || disease === "Chưa phát hiện") return { label: "Chưa xác định", className: "bg-gray-100 text-gray-500" };
  const lower = disease.toLowerCase();
  if (lower === "khỏe mạnh") return { label: disease, className: "bg-emerald-100 text-emerald-700" };
  if (risk >= 90) return { label: disease, className: "bg-red-100 text-red-700" };
  if (risk >= 70) return { label: disease, className: "bg-orange-100 text-orange-700" };
  return { label: disease, className: "bg-amber-100 text-amber-700" };
}

function buildDrawerSections(row: InspectionRow): DetailSection[] {
  return [
    {
      title: "Thông tin kiểm tra",
      fields: [
        { label: "Mã cây", value: row.treeCode },
        { label: "Trang trại", value: row.farm },
        { label: "Khu vực", value: row.zone },
        { label: "Thời gian", value: row.time },
        { label: "Kết quả AI", value: row.disease },
      ],
    },
    {
      title: "Kết quả đánh giá",
      fields: [
        { label: "Chỉ số rủi ro", value: `${row.risk}%` },
        { label: "Người kiểm tra", value: row.inspector },
        {
          label: "Mức độ",
          value:
            row.risk >= 90 ? "Nghiêm trọng" :
            row.risk >= 70 ? "Cao" :
            row.risk >= 50 ? "Trung bình" :
            "Thấp",
        },
      ],
    },
  ];
}

function EmptyState() {
  return (
    <div className="flex flex-col items-center justify-center py-12 text-center">
      <div className="w-12 h-12 rounded-full bg-gray-100 flex items-center justify-center mb-3">
        <svg className="w-6 h-6 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
      </div>
      <p className="text-[13px] font-semibold text-gray-400">Chưa có dữ liệu kiểm tra.</p>
    </div>
  );
}

function InspectionCard({ row, onView }: { row: InspectionRow; onView: () => void }) {
  const badge = diseaseBadge(row.disease, row.risk);
  return (
    <div className="flex items-start gap-3 px-3 py-3 rounded-[12px] hover:bg-gray-50 transition-colors duration-150">
      <div className="flex-1 min-w-0 space-y-1">
        <div className="flex items-center justify-between">
          <span className="text-[15px] font-bold text-gray-900 leading-tight truncate">{row.treeCode}</span>
        </div>
        <div className="text-[12px] text-gray-500 font-medium truncate">
          {row.farm} &bull; {row.time}
        </div>
        <div>
          <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-semibold ${badge.className}`}>
            {badge.label}
          </span>
        </div>
      </div>
      <button
        type="button"
        onClick={onView}
        className="shrink-0 mt-0.5 inline-flex items-center justify-center w-8 h-8 text-gray-400 hover:text-emerald-600 hover:bg-emerald-50 rounded-[10px] transition-colors"
        title="Xem chi tiết"
      >
        <Eye className="w-4 h-4" />
      </button>
    </div>
  );
}

function InspectionTableInner({ data }: InspectionTableProps) {
  const [detailItem, setDetailItem] = useState<InspectionRow | null>(null);

  if (data.length === 0) return <EmptyState />;

  return (
    <>
      <div className="space-y-0.5">
        {data.map((row) => (
          <InspectionCard
            key={row.id}
            row={row}
            onView={() => setDetailItem(row)}
          />
        ))}
      </div>

      {detailItem && (
        <RecordDetailDrawer
          title={`Kiểm tra — ${detailItem.treeCode}`}
          open={!!detailItem}
          onClose={() => setDetailItem(null)}
          sections={buildDrawerSections(detailItem)}
        />
      )}
    </>
  );
}

const InspectionTable = memo(InspectionTableInner);
export default InspectionTable;
