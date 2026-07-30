import { ClipboardList } from "lucide-react";
import Card from "./Shared/Card";
import SectionTitle from "./Shared/SectionTitle";
import InspectionTable from "./InspectionTable";
import type { InspectionRow } from "./InspectionTable";

interface RealtimeInspectionCardProps {
  data: InspectionRow[];
}

export default function RealtimeInspectionCard({ data }: RealtimeInspectionCardProps) {
  return (
    <Card className="flex flex-col overflow-hidden h-full">
      <SectionTitle
        icon={<ClipboardList className="w-5 h-5 text-emerald-600" />}
        title="Hoạt động kiểm tra gần đây"
        size="section"
        subtitle="Các kết quả kiểm tra mới nhất từ hiện trường."
      />
      <div className="flex-1 flex flex-col min-h-0">
        <div className="flex-1 overflow-y-auto">
          <InspectionTable data={data} />
        </div>
      </div>
    </Card>
  );
}
