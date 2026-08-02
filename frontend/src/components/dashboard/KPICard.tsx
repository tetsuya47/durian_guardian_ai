import { memo } from "react";
import type { ReactNode } from "react";

interface KPICardProps {
  icon: ReactNode;
  title: string;
  value: string;
  valueSuffix?: string;
  subtitle?: string;
  subtitleColor?: string;
  subtitleGreen?: boolean;
  subtitleLine1?: string;
  subtitleLine2?: string;
  sparkline?: ReactNode;
  valueColor?: string;
  iconBg?: string;
}

const BG_MAP: Record<string, string> = {
  "bg-emerald-50": "#DCFCE7",
  "bg-emerald-100": "#DCFCE7",
  "bg-amber-100": "#FEF3C7",
  "bg-red-50": "#FEE2E2",
};

function KPICardInner({
  icon, title, value, valueSuffix, subtitle, subtitleColor, subtitleGreen, subtitleLine1, subtitleLine2, sparkline, valueColor = "text-[#111827]", iconBg,
}: KPICardProps) {
  const iconBgColor = iconBg ? (BG_MAP[iconBg] || "#DCFCE7") : "#DCFCE7";

  const subBlock = subtitleLine1 != null ? (
    <>
      <span className="text-[13px] font-semibold text-[#15803D]" style={{ marginBottom: "2px" }}>{subtitleLine1}</span>
      {subtitleLine2 != null && (
        <span className="text-[12px] font-medium text-[#94A3B8]">{subtitleLine2}</span>
      )}
    </>
  ) : subtitle ? (
    subtitleColor ? (
      <span className="text-[12px] font-medium" style={{ color: subtitleColor }}>{subtitle}</span>
    ) : (
      <span className={`text-[12px] font-medium ${subtitleGreen ? "text-[#15803D]" : "text-[#94A3B8]"}`}>{subtitle}</span>
    )
  ) : null;

  const leftContent = (
    <>
      <span
        className="text-[11px] font-bold text-[#94A3B8] uppercase tracking-wider"
        style={{ marginBottom: "4px", lineHeight: "1" }}
      >
        {title}
      </span>
      {valueSuffix ? (
        <div style={{ display: "flex", alignItems: "baseline", marginBottom: "3px" }}>
          <span className={`text-[32px] 2xl:text-[36px] font-extrabold ${valueColor}`} style={{ lineHeight: "1" }}>{value}</span>
          <span className={`text-[20px] 2xl:text-[22px] font-bold ${valueColor}`} style={{ lineHeight: "1", marginLeft: "4px", whiteSpace: "nowrap" }}>{valueSuffix}</span>
        </div>
      ) : (
        <span className={`text-[32px] 2xl:text-[36px] font-extrabold ${valueColor}`} style={{ marginBottom: "3px", lineHeight: "1" }}>
          {value}
        </span>
      )}
      {subBlock}
    </>
  );

  const iconBlock = (
    <div
      className="flex items-center justify-center rounded-[12px] flex-shrink-0"
      style={{
        width: "44px",
        height: "44px",
        backgroundColor: iconBgColor,
      }}
      aria-hidden="true"
    >
      {icon}
    </div>
  );

  const cardBase = "bg-white border border-[#EEF2F7] rounded-[16px] shadow-[0_4px_16px_rgba(15,23,42,0.04)]";

  if (sparkline) {
    return (
      <div className={cardBase} style={{ height: "92px", padding: "10px 16px", display: "flex", flexDirection: "column" }} role="group" aria-label={`${title}: ${value}`}>
        <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center", flex: "1" }}>
          <div style={{ display: "flex", flexDirection: "column", width: "auto" }}>
            {leftContent}
          </div>
          <div>
            {iconBlock}
          </div>
        </div>
        <div style={{ display: "flex", justifyContent: "flex-end" }}>
          {sparkline}
        </div>
      </div>
    );
  }

  return (
    <div className={cardBase} style={{ height: "92px", padding: "10px 16px", display: "flex", justifyContent: "space-between", alignItems: "center" }} role="group" aria-label={`${title}: ${value}`}>
      <div style={{ display: "flex", flexDirection: "column", width: "auto" }}>
        {leftContent}
      </div>
      <div>
        {iconBlock}
      </div>
    </div>
  );
}

const KPICard = memo(KPICardInner);
export default KPICard;
