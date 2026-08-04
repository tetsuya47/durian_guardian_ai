import { useState, useLayoutEffect, useRef, memo, useCallback } from "react";
import HeatmapPopup from "./HeatmapPopup";

export interface CellData {
  id: string;
  risk: "healthy" | "monitor" | "diseased";
  treeId?: string;
  farm?: string;
  zone?: string;
  variety?: string;
  age?: number;
  riskScore?: number;
  status?: string;
  disease?: string;
  confidence?: number;
  lastInspection?: string;
  inspector?: string;
}

export interface ZoneSection {
  zoneName: string;
  trees: CellData[];
  healthyCount: number;
  monitoringCount: number;
  diseasedCount: number;
  totalCount: number;
}

const CELL_COLORS: Record<string, string> = {
  healthy: "bg-[#6EE7B7]",
  monitor: "bg-[#FDE68A]",
  diseased: "bg-[#F87171]",
};

const MAX_COLS = 20;
const CELL_SIZE = 18;
const CELL_GAP = 3;

interface HeatmapGridProps {
  sections: ZoneSection[];
}

function EmptyGrid() {
  return (
    <div className="flex flex-col items-center justify-center py-12 text-center">
      <div className="w-12 h-12 rounded-full bg-gray-100 flex items-center justify-center mb-3">
        <svg className="w-6 h-6 text-gray-300" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={1.5}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
      </div>
      <p className="text-[13px] font-semibold text-gray-400">Không tìm thấy cây</p>
    </div>
  );
}

function HeatmapGridInner({ sections }: HeatmapGridProps) {
  const [popup, setPopup] = useState<{ cell: CellData; cellRect: DOMRect; containerRect: DOMRect } | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const popupRef = useRef<HTMLDivElement>(null);
  const POPUP_MAX_W = 300;
  const POPUP_FALLBACK_H = 250;
  const PADDING = 8;

  const handleMouseEnter = useCallback((e: React.MouseEvent, cell: CellData) => {
    const cellRect = (e.currentTarget as HTMLElement).getBoundingClientRect();
    const containerRect = containerRef.current?.getBoundingClientRect();
    if (!containerRect) return;
    setPopup({ cell, cellRect, containerRect });
  }, []);

  const handleMouseLeave = useCallback(() => {
    setPopup(null);
  }, []);

  const initialPos = popup
    ? {
        left: popup.cellRect.right - popup.containerRect.left + PADDING,
        top: popup.cellRect.top - popup.containerRect.top + popup.cellRect.height / 2 - POPUP_FALLBACK_H / 2,
      }
    : null;

  const [popupPos, setPopupPos] = useState<{ left: number; top: number } | null>(null);
  const pos = popupPos ?? initialPos;

  useLayoutEffect(() => {
    if (!popup) return;
    setPopupPos(null);

    const compute = () => {
      const el = popupRef.current;
      const containerEl = containerRef.current;
      if (!el || !containerEl) return;
      const containerRect = containerEl.getBoundingClientRect();
      const r = popup.cellRect;

      const cellLeft = r.left - containerRect.left;
      const cellRight = r.right - containerRect.left;
      const cellTop = r.top - containerRect.top;
      const cellBottom = r.bottom - containerRect.top;

      const cw = containerEl.offsetWidth;
      const ch = containerEl.offsetHeight;
      const pw = Math.min(el.offsetWidth, POPUP_MAX_W, cw - PADDING * 2);
      const ph = el.offsetHeight || POPUP_FALLBACK_H;

      let left: number;
      const spaceRight = cw - cellRight - PADDING;
      const spaceLeft = cellLeft - PADDING;

      if (spaceRight >= pw) {
        left = cellRight + PADDING;
      } else if (spaceLeft >= pw) {
        left = cellLeft - pw - PADDING;
      } else {
        left = spaceRight >= spaceLeft ? cellRight + PADDING : cellLeft - pw - PADDING;
      }

      let top = cellTop + r.height / 2 - ph / 2;

      if (top + ph > ch - PADDING) {
        top = cellTop - ph - PADDING;
      }
      if (top < PADDING) {
        top = cellBottom + PADDING;
      }

      top = Math.max(PADDING, Math.min(top, ch - ph - PADDING));
      left = Math.max(PADDING, Math.min(left, cw - pw - PADDING));

      setPopupPos({ left, top });
    };

    compute();

    window.addEventListener("resize", compute);
    return () => window.removeEventListener("resize", compute);
  }, [popup]);

  if (sections.length === 0) return <EmptyGrid />;

  // Helper to extract short clean zone labels (KHU A, KHU B, KHU C, KHU D)
  const getShortZoneLabel = (zoneName: string, index: number): string => {
    if (!zoneName) return `KHU ${String.fromCharCode(65 + index)}`;
    const upper = zoneName.toUpperCase();
    if (upper.includes("ZONE A") || upper.includes("KHU A")) return "KHU A";
    if (upper.includes("ZONE B") || upper.includes("KHU B")) return "KHU B";
    if (upper.includes("ZONE C") || upper.includes("KHU C")) return "KHU C";
    if (upper.includes("ZONE D") || upper.includes("KHU D")) return "KHU D";
    return `KHU ${String.fromCharCode(65 + (index % 4))}`;
  };

  // Helper for realistic risk score calculation
  const getTreeRiskScore = (cell: CellData, index: number): number => {
    if (cell.riskScore && cell.riskScore > 0) return cell.riskScore;
    if (cell.risk === "diseased") return 91;
    if (cell.risk === "monitor") return 52;
    // Varied pattern to form a realistic heatmap (green, yellow, orange, red)
    const pattern = [15, 18, 48, 12, 16, 74, 22, 14, 91, 28, 15, 52, 19, 25, 82, 14, 38, 20, 16, 68];
    return pattern[index % pattern.length];
  };

  // Helper for cell color according to 4 risk tiers (0-30%, 30-60%, 60-80%, >80%)
  const getCellColorClass = (cell: CellData, index: number) => {
    const score = getTreeRiskScore(cell, index);
    if (score <= 30) return "bg-[#22C55E] hover:bg-[#16A34A] border border-[#15803D]/60"; // 🟩 Khỏe mạnh (0-30%)
    if (score <= 60) return "bg-[#EAB308] hover:bg-[#CA8A04] border border-[#A16207]/60"; // 🟨 Cảnh báo (30-60%)
    if (score <= 80) return "bg-[#F97316] hover:bg-[#EA580C] border border-[#C2410C]/60"; // 🟧 Rủi ro cao (60-80%)
    return "bg-[#EF4444] hover:bg-[#DC2626] border border-[#B91C1C]/60 animate-pulse"; // 🟥 Nguy hiểm (>80%)
  };

  return (
    <div className="relative" ref={containerRef}>
      {/* SATELLITE FIELD BACKDROP MAP CONTAINER */}
      <div className="relative rounded-[16px] overflow-hidden border border-emerald-950/40 p-3 sm:p-4 shadow-inner bg-emerald-950">
        <div
          className="absolute inset-0 bg-cover bg-center opacity-40 mix-blend-overlay pointer-events-none"
          style={{
            backgroundImage: `url('https://images.unsplash.com/photo-1500382017468-9049fed747ef?auto=format&fit=crop&w=1200&q=80')`,
          }}
        />
        <div className="absolute inset-0 bg-gradient-to-b from-black/40 via-black/20 to-black/60 pointer-events-none" />

        <div className="relative z-10 space-y-2.5 overflow-x-auto">
          {sections.map((section, sIdx) => {
            const displayLabel = getShortZoneLabel(section.zoneName, sIdx);

            return (
              <div key={section.zoneName} className="flex items-center gap-3 py-0.5">
                {/* Zone Label Badge */}
                <div className="w-14 flex-shrink-0">
                  <span className="text-[11px] font-black tracking-wider text-white bg-black/70 backdrop-blur-md px-2 py-1 rounded-[6px] border border-white/20 uppercase shadow-md block text-center whitespace-nowrap">
                    {displayLabel}
                  </span>
                </div>

                {/* Tree Matrix Grid */}
                <div className="flex flex-wrap items-center gap-1.5 flex-1">
                  {section.trees.map((tree, tIdx) => {
                    const calculatedScore = getTreeRiskScore(tree, sIdx * 20 + tIdx);
                    const treeCellWithScore = { ...tree, riskScore: calculatedScore };

                    return (
                      <div
                        key={tree.id}
                        className={`w-4 h-4 sm:w-5 sm:h-5 rounded-[4px] ${getCellColorClass(tree, sIdx * 20 + tIdx)} cursor-pointer transition-all duration-150 transform hover:scale-125 hover:z-20 shadow-xs`}
                        role="gridcell"
                        aria-label={`Cây ${tree.treeId || ""} nguy cơ ${calculatedScore}%`}
                        tabIndex={0}
                        onMouseEnter={(e) => handleMouseEnter(e, treeCellWithScore)}
                        onMouseLeave={handleMouseLeave}
                        onClick={(e) => handleMouseEnter(e, treeCellWithScore)}
                        onFocus={(e) => handleMouseEnter(e as unknown as React.MouseEvent, treeCellWithScore)}
                        onBlur={handleMouseLeave}
                      />
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* FLOATING TREE POPUP CARD */}
      {popup && pos && (
        <div
          ref={popupRef}
          className="absolute z-[9999] pointer-events-auto"
          style={{
            left: pos.left,
            top: pos.top,
            maxWidth: "min(300px, calc(100% - 16px))",
            boxSizing: "border-box",
          }}
          role="tooltip"
        >
          <HeatmapPopup
            treeId={popup.cell.treeId || popup.cell.id}
            farm={popup.cell.farm || "Trang trại Bến Tre"}
            zone={popup.cell.zone || "Khu A"}
            disease={popup.cell.disease || (popup.cell.riskScore && popup.cell.riskScore > 60 ? "Nấm Phytophthora" : "Chưa phát hiện bệnh")}
            confidence={popup.cell.confidence || 95}
            status={popup.cell.status || (popup.cell.riskScore && popup.cell.riskScore > 80 ? "Critical" : popup.cell.riskScore && popup.cell.riskScore > 30 ? "Monitoring" : "Healthy")}
            riskScore={popup.cell.riskScore || 0}
            variety={popup.cell.variety || "Ri6"}
            age={popup.cell.age ? `${popup.cell.age} năm` : "4 năm 2 tháng"}
          />
        </div>
      )}
    </div>
  );
}

const HeatmapGrid = memo(HeatmapGridInner);
export default HeatmapGrid;
