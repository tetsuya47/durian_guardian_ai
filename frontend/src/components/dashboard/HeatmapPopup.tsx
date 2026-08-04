import { ChevronDown, ArrowRight } from "lucide-react";
import { useNavigate } from "react-router-dom";

export interface HeatmapPopupProps {
  treeId: string;
  farm?: string;
  zone?: string;
  disease?: string;
  confidence?: number;
  status?: string;
  riskScore: number;
  variety?: string;
  age?: string;
}

export default function HeatmapPopup({
  treeId,
  farm,
  zone,
  disease,
  confidence,
  status,
  riskScore,
  variety = "Ri6",
  age = "4 năm 2 tháng",
}: HeatmapPopupProps) {
  const navigate = useNavigate();

  // Determine display score and color scheme
  const displayScore = riskScore > 0 ? riskScore : status === "Healthy" ? 15 : status === "Monitoring" ? 48 : 91;
  const isDanger = displayScore > 80;
  const isHighRisk = displayScore > 60 && displayScore <= 80;
  const isWarning = displayScore > 30 && displayScore <= 60;

  const scoreColor = isDanger
    ? "text-red-600 font-black"
    : isHighRisk
    ? "text-orange-600 font-black"
    : isWarning
    ? "text-amber-600 font-black"
    : "text-emerald-600 font-black";

  // Trend line points for mini SVG graph (02/25 to 06/25)
  const trendPoints = [
    { month: "02/25", val: Math.max(15, displayScore - 40) },
    { month: "03/25", val: Math.max(20, displayScore - 35) },
    { month: "04/25", val: Math.max(30, displayScore - 20) },
    { month: "05/25", val: Math.max(45, displayScore - 10) },
    { month: "06/25", val: displayScore },
  ];

  // SVG coordinates for mini line chart (width: 210, height: 65)
  const chartW = 210;
  const chartH = 65;
  const padL = 30;
  const padB = 16;
  const padT = 8;
  const usableW = chartW - padL;
  const usableH = chartH - padB - padT;

  const pointsSvg = trendPoints
    .map((p, idx) => {
      const x = padL + (idx / (trendPoints.length - 1)) * usableW;
      const y = padT + (1 - p.val / 100) * usableH;
      return `${x},${y}`;
    })
    .join(" ");

  return (
    <div
      className="bg-white border border-gray-100 rounded-[20px] shadow-[0_12px_36px_rgba(0,0,0,0.22)] p-4 w-[280px] box-border animate-fade-in pointer-events-auto"
      role="dialog"
      aria-label={`Chi tiết cây ${treeId}`}
    >
      {/* Header with Tree ID and Dropdown Arrow */}
      <div className="flex items-center justify-between border-b border-gray-100 pb-2.5 mb-2.5">
        <div className="flex items-center gap-1.5 cursor-pointer">
          <span className="text-sm font-black text-gray-900">Tree ID: {treeId}</span>
          <ChevronDown className="w-4 h-4 text-gray-400" />
        </div>
      </div>

      {/* Details Grid */}
      <div className="space-y-1.5 text-xs">
        <div className="flex items-center justify-between">
          <span className="text-gray-500 font-semibold">Giống:</span>
          <span className="font-bold text-gray-900">{variety}</span>
        </div>

        <div className="flex items-center justify-between">
          <span className="text-gray-500 font-semibold">Tuổi cây:</span>
          <span className="font-bold text-gray-900">{age}</span>
        </div>

        <div className="flex items-center justify-between pt-0.5">
          <span className="text-gray-500 font-semibold">Risk Score hiện tại:</span>
          <span className={`text-sm ${scoreColor}`}>{displayScore}%</span>
        </div>

        {/* Mini Historical Risk Trend Graph */}
        <div className="pt-2">
          <div className="relative w-full h-[70px]">
            <svg className="w-full h-full overflow-visible">
              {/* Horizontal Grid lines */}
              <line x1={padL} y1={padT} x2={chartW} y2={padT} stroke="#F3F4F6" strokeDasharray="2,2" />
              <line x1={padL} y1={padT + usableH / 2} x2={chartW} y2={padT + usableH / 2} stroke="#F3F4F6" strokeDasharray="2,2" />
              <line x1={padL} y1={padT + usableH} x2={chartW} y2={padT + usableH} stroke="#E5E7EB" />

              {/* Y Axis Labels */}
              <text x={padL - 4} y={padT + 3} textAnchor="end" fontSize="9" fontWeight="bold" fill="#9CA3AF">100%</text>
              <text x={padL - 4} y={padT + usableH / 2 + 3} textAnchor="end" fontSize="9" fontWeight="bold" fill="#9CA3AF">50%</text>
              <text x={padL - 4} y={padT + usableH + 3} textAnchor="end" fontSize="9" fontWeight="bold" fill="#9CA3AF">0%</text>

              {/* Red Line Chart Path */}
              <polyline
                fill="none"
                stroke="#EF4444"
                strokeWidth="2.5"
                strokeLinecap="round"
                strokeLinejoin="round"
                points={pointsSvg}
              />

              {/* Red Dot Points */}
              {trendPoints.map((p, idx) => {
                const x = padL + (idx / (trendPoints.length - 1)) * usableW;
                const y = padT + (1 - p.val / 100) * usableH;
                return (
                  <g key={idx}>
                    <circle cx={x} cy={y} r="3.5" fill="#EF4444" stroke="#FFFFFF" strokeWidth="1.5" />
                    {/* X Axis Labels */}
                    <text x={x} y={chartH - 2} textAnchor="middle" fontSize="9" fontWeight="bold" fill="#6B7280">
                      {p.month}
                    </text>
                  </g>
                );
              })}
            </svg>
          </div>
        </div>

        {/* View Profile Link */}
        <div className="pt-2 border-t border-gray-100 flex items-center justify-end">
          <button
            onClick={() => navigate(`/tree/${treeId}`)}
            className="text-emerald-700 hover:text-emerald-800 font-extrabold text-xs flex items-center gap-1 cursor-pointer transition-colors"
          >
            <span>Xem chi tiết hồ sơ</span>
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>
      </div>
    </div>
  );
}
