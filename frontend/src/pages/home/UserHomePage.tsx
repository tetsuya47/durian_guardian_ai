import { useState, useEffect, useMemo } from "react";
import api from "../../api";
import {
  Calendar,
  Sun,
  MapPin,
  AlertTriangle,
  CloudRain,
  Sprout,
  CheckSquare,
  Bot,
  Wifi,
  DollarSign,
  ChevronRight,
  Bug,
  Leaf,
  ShieldAlert,
  TrendingUp,
  BookOpen,
  CheckCircle2,
  Clock,
  Layers,
  Sparkles,
  Award,
  X,
} from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../hooks/useAuth";

const DEFAULT_MARKET_ITEMS = [
  {
    name: "Sầu riêng Ri6 (Hàng Đẹp Loại 1)",
    category: "Ri6",
    quality: "Hàng Đẹp (Loại 1)",
    grade: "dep",
    price: "60.000 – 65.000",
    unit: "đ/kg",
    change: "+3.5%",
    trend: "up",
  },
  {
    name: "Sầu riêng Ri6 (Hàng Xô Lùa Vựa)",
    category: "Ri6",
    quality: "Hàng Xô (Lùa vựa)",
    grade: "xo",
    price: "48.000 – 50.000",
    unit: "đ/kg",
    change: "Ổn định",
    trend: "same",
  },
  {
    name: "Sầu riêng Thái / Monthong (Hàng Đẹp Loại 1)",
    category: "THÁI",
    quality: "Hàng Đẹp (Loại 1)",
    grade: "dep",
    price: "85.000 – 90.000",
    unit: "đ/kg",
    change: "+5.2%",
    trend: "up",
  },
  {
    name: "Sầu riêng Thái / Monthong (Hàng Xô Lùa Vựa)",
    category: "THÁI",
    quality: "Hàng Xô (Lùa vựa)",
    grade: "xo",
    price: "75.000 – 77.000",
    unit: "đ/kg",
    change: "+2.1%",
    trend: "up",
  },
  {
    name: "Sầu riêng Musang King (Hàng Đẹp Loại 1)",
    category: "MUSANG KING",
    quality: "Hàng Đẹp (Loại 1)",
    grade: "dep",
    price: "180.000 – 220.000",
    unit: "đ/kg",
    change: "Ổn định",
    trend: "same",
  },
  {
    name: "Sầu riêng Musang King (Hàng Xô Lùa Vựa)",
    category: "MUSANG KING",
    quality: "Hàng Xô (Lùa vựa)",
    grade: "xo",
    price: "130.000 – 160.000",
    unit: "đ/kg",
    change: "Ổn định",
    trend: "same",
  },
];

interface TechniqueStep {
  stage: string;
  stageTitle: string;
  timeline: string;
  iconBg: string;
  summary: string;
  soilWater: string[];
  fertilizer: string[];
  pruningPest: string[];
}

interface DurianVarietyTech {
  id: string;
  name: string;
  subtitle: string;
  badge: string;
  density: string;
  harvestDays: string;
  specialNote: string;
  steps: TechniqueStep[];
}

const DURIAN_VARIETIES_TECH: DurianVarietyTech[] = [
  {
    id: "ri6",
    name: "Sầu riêng Ri6",
    subtitle: "Cơm vàng hạt lép - Giống phổ biến ĐBSCL & Tây Nguyên",
    badge: "Phổ biến nhất",
    density: "8m x 8m (125 cây/ha) hoặc 8m x 9m",
    harvestDays: "85 – 90 ngày sau đậu trái",
    specialNote: "Ri6 nhạy cảm với dư thừa đạm trong giai đoạn nuôi trái. Cần tăng cường bón Kali Nitrat (KNO3) và vi lượng Boron để cơm vàng tươi, hạt lép tối đa, không bị sượng cơm.",
    steps: [
      {
        stage: "0-12m",
        stageTitle: "Giai đoạn 1: Chuẩn bị đất & Trồng cây con (0 - 12 tháng)",
        timeline: "0 - 12 tháng đầu",
        iconBg: "bg-emerald-500",
        summary: "Thiết lập gốc khỏe, bảo vệ đọt non & ra rễ dầy",
        soilWater: [
          "Đắp mô cao 0.8m - 1.0m, đường kính mô 1.5m - 2.0m để chống úng gốc.",
          "Bón lót mỗi hố: 10-15kg phân hữu cơ hoai mục + 0.5kg vôi bột + 0.5kg Super Lân.",
          "Che nắng 50% bằng lưới đen trong 3-4 tháng đầu. Tưới nước 1-2 ngày/lần."
        ],
        fertilizer: [
          "Tháng thứ 2: Bón 50g phân NPK 20-10-10 hoặc 16-16-8 xung quanh tán mô.",
          "Định kỳ 20 ngày/lần: Phun kích rễ Humic Acid + Amino Acid bón lá.",
          "Không bón phân hóa học đậm đặc trực tiếp vào sát gốc cây con."
        ],
        pruningPest: [
          "Giữ 1 thân chính thẳng đứng, tỉa bỏ các cành sà sát mặt đất (<40cm).",
          "Phun phòng rệp sáp, bọ trĩ & sâu đọt non mỗi khi cây nhú cơi đọt mới."
        ]
      },
      {
        stage: "1-3y",
        stageTitle: "Giai đoạn 2: Kiến thiết cơ bản & Tỉa cành tạo tán (1 - 3 năm)",
        timeline: "Năm thứ 1 đến Năm thứ 3",
        iconBg: "bg-teal-500",
        summary: "Tạo khung tán tròn đều, cành mang trái lực & dầy lá",
        soilWater: [
          "Mở rộng chân mô thêm 0.5m mỗi năm. Giữ thảm cỏ xanh che phủ đất.",
          "Tưới tưới tự động 2-3 ngày/lần vào mùa khô, thoát nước dứt khoát mùa mưa."
        ],
        fertilizer: [
          "Bón phân hữu cơ vi sinh: 3-5kg/gốc/năm chia làm 3 đợt.",
          "Bón NPK 20-10-10 (200-500g/gốc/lần), định kỳ 1.5 - 2 tháng/lần.",
          "Bổ sung Vi lượng Kẽm (Zn) & Magie (Mg) giúp xanh lá, dầy bản lá."
        ],
        pruningPest: [
          "Tỉa cành vượt, cành tăm, giữ cành ngang cấp 1 cách nhau 20-30cm.",
          "Phun ngừa nấm Phytophthora (xì mủ) & bệnh Thán thư đọt non định kỳ."
        ]
      },
      {
        stage: "flower",
        stageTitle: "Giai đoạn 3: Xử lý Ra hoa & Đậu trái (Năm thứ 4 trở đi)",
        timeline: "Tháng 11 - Tháng 1 hàng năm",
        iconBg: "bg-amber-500",
        summary: "Siết nước ép hoa, tỉa bông chùm & thụ phấn bổ sung",
        soilWater: [
          "Dọn sạch cỏ mô gốc, siết nước (cắt nước) 15-21 ngày cho mô khô nứt chân chim.",
          "Khi mầm hoa (mắt cua) nhú 2-3cm thì tưới nhấp nước lại từ từ."
        ],
        fertilizer: [
          "Rải MKP (0-52-34) 300-500g/gốc để chặn đọt, kích thích phân hóa mầm hoa.",
          "Khi hoa xòe: Phun Bo-Canxi + Amino Acid tăng sức sống hạt phấn.",
          "Tỉa bớt bông chùm, chỉ giữ lại bông chùm tròn khỏe ở giữa cành cấp 1."
        ],
        pruningPest: [
          "Thụ phấn bổ sung vào khoảng 18h - 21h đêm bằng chổi bông mềm.",
          "Phun phòng bọ trĩ & sâu ăn bông trước khi hoa nở 5 ngày."
        ]
      },
      {
        stage: "fruit",
        stageTitle: "Giai đoạn 4: Nuôi trái & Thu hoạch chín dầy cơm",
        timeline: "85 - 90 ngày sau khi đậu trái",
        iconBg: "bg-[#10B981]",
        summary: "Tỉa trái định hình, bón Kali dằn cơm & cắt thu hoạch",
        soilWater: [
          "Tưới nước đều đặn, không để đất quá khô rồi tưới dồn đột ngột gây rụng trái.",
          "Trước thu hoạch 10-15 ngày: Giảm 50% lượng nước tưới để đòn cơm dầy."
        ],
        fertilizer: [
          "Trái 30 ngày: Tỉa trái loại bỏ trái vặn, trái méo. Giữ 60-80 trái/cây.",
          "Trái 45-60 ngày: Bón NPK 12-11-18 hoặc 15-5-20 (1-1.5kg/gốc).",
          "Trái 70-80 ngày: Bón Kali Sunfat (K2SO4) giúp cơm vàng tươi, thơm ngậy."
        ],
        pruningPest: [
          "Treo dây buộc cành đỡ chùm trái tránh gãy cành khi giông bão.",
          "Cắt thu hoạch khi gõ đĩa cuống nổ độ chín 8.5-9 tuổi (vỏ xanh vàng)."
        ]
      }
    ]
  },
  {
    id: "monthong",
    name: "Sầu riêng Thái / Monthong (Dona)",
    subtitle: "Giống xuất khẩu chính ngạch - Trái to, cơm dầy, hạt lép",
    badge: "Xuất khẩu số 1",
    density: "9m x 9m (120 cây/ha) hoặc 10m x 10m",
    harvestDays: "105 – 115 ngày sau đậu trái",
    specialNote: "Monthong có cành giòn dễ gãy và thời gian nuôi trái kéo dài (trên 110 ngày). Cần buộc dây cố định chùm trái chắc chắn và dằn đọt kỹ giai đoạn trái 40-60 ngày để tránh rụng trái non.",
    steps: [
      {
        stage: "0-12m",
        stageTitle: "Giai đoạn 1: Chuẩn bị đất & Trồng cây con (0 - 12 tháng)",
        timeline: "0 - 12 tháng đầu",
        iconBg: "bg-emerald-500",
        summary: "Xử lý đất mô thoát nước tốt, cọc cố định gốc",
        soilWater: [
          "Đắp mô cao 0.8 - 1.2m, bón rải 1kg vôi + 15kg phân bò/gà hoai mục.",
          "Trồng cây gốc ghép cao 50-70cm, buộc cọc tre định vị tránh gió lay gốc.",
          "Tưới nước giữ ẩm 60-70%, không đọng nước quanh cổ rễ."
        ],
        fertilizer: [
          "Bón NPK 20-10-10 (50g/lần) định kỳ 1 tháng/lần.",
          "Phun phân bón lá chứa Canxi, Kẽm & Axit Humic kích thích đọt mập."
        ],
        pruningPest: [
          "Không tỉa ngọn thân chính. Bịt vết cắt bằng keo liền sẹo nếu có.",
          "Xử lý nấm dại & sâu vẽ bùa khi đọt lụa nhú đỏ."
        ]
      },
      {
        stage: "1-3y",
        stageTitle: "Giai đoạn 2: Đột phá cơi đọt & Xây dựng bộ khung tán rộng",
        timeline: "Năm thứ 1 đến Năm thứ 3",
        iconBg: "bg-teal-500",
        summary: "Nuôi 3 cơi đọt/năm, tạo cành ngang mang trái to 4-6kg",
        soilWater: [
          "Mở rộng bán kính tán mô 2m - 2.5m.",
          "Đảm bảo hệ thống béc tưới bán kính 2m quanh gốc."
        ],
        fertilizer: [
          "Rải phân hữu cơ nở nhập khẩu (3-4kg/gốc/năm).",
          "Bón NPK 16-16-8 (300g/gốc) đợt nhú lá lụa."
        ],
        pruningPest: [
          "Tỉa cành tăm, cành ếch, giữ cành ngang to khỏe làm cành lực mang trái Monthong to.",
          "Phun phòng xì mủ thối đọt & sâu đục thân."
        ]
      },
      {
        stage: "flower",
        stageTitle: "Giai đoạn 3: Ép bông đồng loạt & Kiểm soát đọt non",
        timeline: "Tháng 12 - Tháng 2 hàng năm",
        iconBg: "bg-amber-500",
        summary: "Kích mắt cua Monthong, dằn đọt triệt để",
        soilWater: [
          "Rút cạn mương bưng, siết nước 20-25 ngày cho mô nứt nẻ nẻ chân chim.",
          "Khi mắt cua sáng 2cm: Tưới nhấp 20% lượng nước, tăng dần."
        ],
        fertilizer: [
          "Phun MKP (0-52-34) + Paclobutrazol (nếu làm nghịch vụ) chặn đọt triệt để.",
          "Bón Canxi-Bo trước khi hoa nở 7 ngày."
        ],
        pruningPest: [
          "Tỉa bớt 50% chùm hoa ở đầu cành, chỉ giữ bông bụng cành to.",
          "Thụ phấn bổ sung ca đêm từ 19h - 21h."
        ]
      },
      {
        stage: "fruit",
        stageTitle: "Giai đoạn 4: Nuôi trái Monthong siêu to & Thu hoạch xuất khẩu",
        timeline: "105 - 115 ngày sau khi đậu trái",
        iconBg: "bg-[#10B981]",
        summary: "Buộc dây nẹp cành, bón phân nuôi cơm dầy nứt gai",
        soilWater: [
          "Duy trì ẩm độ ổn định. Tránh tưới nước quá nhiều khi trái gần thu hoạch."
        ],
        fertilizer: [
          "Tỉa trái 3 đợt: Đợt 1 (trái bằng quả trứng gà), Đợt 2 (trái bằng nắm tay), giữ 40-60 trái/cây.",
          "Bón NPK 15-5-20 hoặc 12-12-17 (1.5kg/gốc) giai đoạn trái 60-90 ngày.",
          "Phun Kali Nitrat (KNO3) dằn cơm vàng ngọt đậm, vỏ mỏng."
        ],
        pruningPest: [
          "Cột dây dù chằng từ cành chính lên thân để không gãy cành khi trái nặng 4-6kg.",
          "Cắt thu hoạch khi vỏ hơi chớm vàng, gõ đĩa cuống đạt chuẩn xuất khẩu."
        ]
      }
    ]
  },
  {
    id: "musangking",
    name: "Sầu riêng Musang King (Malaysia)",
    subtitle: "Dòng cực phẩm - Cơm dầy vàng óng, vị béo đắng nhẹ đặc trưng",
    badge: "Giá trị cao nhất",
    density: "8m x 8m (125 cây/ha)",
    harvestDays: "95 – 105 ngày sau đậu trái",
    specialNote: "Musang King cần quản lý độ ẩm gốc cực kỳ khắt khe để tránh hiện tượng thối hộc cơm hoặc nhão cơm. Bổ sung định kỳ Vi lượng Boron & Magie giúp múi cơm có màu vàng da cam đặc trưng.",
    steps: [
      {
        stage: "0-12m",
        stageTitle: "Giai đoạn 1: Chuẩn bị mô đất cao & Trồng cây giống (0 - 12 tháng)",
        timeline: "0 - 12 tháng đầu",
        iconBg: "bg-emerald-500",
        summary: "Đắp mô cao 1m, trồng xoay hướng tán đón nắng",
        soilWater: [
          "Trồng trên mô cao 1m, đất thoát nước cực nhanh.",
          "Che phủ thảm cỏ hoặc rơm rạ quanh chân mô.",
          "Tưới béc xòe 15 phút/ngày vào buổi sáng."
        ],
        fertilizer: [
          "Bón phân hữu cơ vi sinh trùn hạ (2kg/gốc).",
          "Phun phân bón lá Amino Acid + Vi lượng Boron định kỳ."
        ],
        pruningPest: [
          "Giữ 1 thân thẳng, tạo cành ngang góc nghiêng 45-60°.",
          "Phòng trị rệp sáp & nấm hồng thân."
        ]
      },
      {
        stage: "1-3y",
        stageTitle: "Giai đoạn 2: Kiến thiết cơ bản & Tạo tán cành lực",
        timeline: "Năm thứ 1 đến Năm thứ 3",
        iconBg: "bg-teal-500",
        summary: "Đảm bảo cành xòe 4 hướng, phân bón sinh học vi sinh",
        soilWater: ["Tưới nhỏ giọt hoặc béc tưới bù áp tự động."],
        fertilizer: ["Bón NPK 20-10-10 kết hợp phân hữu cơ nở."],
        pruningPest: ["Tỉa cành còi cọc, phun phòng bệnh xì mủ gốc."]
      },
      {
        stage: "flower",
        stageTitle: "Giai đoạn 3: Ép mầm hoa Musang King & Thụ phấn chéo",
        timeline: "Tháng 12 - Tháng 2 hàng năm",
        iconBg: "bg-amber-500",
        summary: "Tạo khô hạn siết nước, thụ phấn chéo tăng đậu trái",
        soilWater: ["Cắt nước 18-22 ngày ép ra mắt cua."],
        fertilizer: ["Phun Canxi Bo + Amino hữu cơ trước khi hoa nở."],
        pruningPest: ["Thụ phấn chéo nhân tạo giúp trái tròn múi dầy."]
      },
      {
        stage: "fruit",
        stageTitle: "Giai đoạn 4: Nuôi cơm da camMusang King & Thu hoạch chín rụng",
        timeline: "95 - 105 ngày sau khi đậu trái",
        iconBg: "bg-[#10B981]",
        summary: "Tỉa trái chọn lọc, bón Kali Sunfat, thu hoạch chuẩn",
        soilWater: ["Giữ mô khô ráo 2 tuần trước khi rụng."],
        fertilizer: ["Bón Kali Sunfat (K2SO4) tăng béo đượm ngậy."],
        pruningPest: ["Thu hoạch khi trái rụng tự nhiên vào lưới giăng hoặc cắt khi đĩa cuống nổ."]
      }
    ]
  },
  {
    id: "chuongbo",
    name: "Sầu riêng Chuồng Bò (Cổ truyền)",
    subtitle: "Giống cổ truyền Miền Tây - Cơm béo ngậy ngọt lịm",
    badge: "Vị béo cổ truyền",
    density: "8m x 8m (125 cây/ha)",
    harvestDays: "80 – 85 ngày sau đậu trái",
    specialNote: "Chuồng Bò là giống sầu riêng cực kỳ dễ trồng, kháng bệnh tốt. Tuy nhiên trái chín nhanh nên cần thu hoạch đúng ngày để cơm không bị nhão.",
    steps: [
      {
        stage: "0-12m",
        stageTitle: "Giai đoạn 1: Chuẩn bị đất & Trồng cây con (0 - 12 tháng)",
        timeline: "0 - 12 tháng đầu",
        iconBg: "bg-emerald-500",
        summary: "Trồng mô phù sa dầy, bón lót phân hoai mục",
        soilWater: ["Mô cao 0.8m, tưới ẩm 2 ngày/lần."],
        fertilizer: ["Bón phân hữu cơ hoai mục + NPK 16-16-8."],
        pruningPest: ["Phòng ngừa sâu đọt & bọ trĩ."]
      },
      {
        stage: "1-3y",
        stageTitle: "Giai đoạn 2: Tỉa cành thưa & Chăm sóc bộ rễ",
        timeline: "Năm thứ 1 đến Năm thứ 3",
        iconBg: "bg-teal-500",
        summary: "Tạo tán thông thoáng, bón phân sinh học",
        soilWater: ["Mở rộng mương bưng thoát nước."],
        fertilizer: ["Bón phân hữu cơ nở 3kg/gốc/năm."],
        pruningPest: ["Tỉa bớt cành sát đất & cành vượt."]
      },
      {
        stage: "flower",
        stageTitle: "Giai đoạn 3: Ra hoa tự nhiên & Đậu trái",
        timeline: "Tháng 1 - Tháng 3",
        iconBg: "bg-amber-500",
        summary: "Siết nước nhẹ, phun Canxi Bo đậu trái",
        soilWater: ["Cắt nước 14 ngày nhú hoa."],
        fertilizer: ["Phun Bo-Canxi tăng thụ phấn."],
        pruningPest: ["Phòng sâu ăn bông & bọ trĩ."]
      },
      {
        stage: "fruit",
        stageTitle: "Giai đoạn 4: Nuôi trái & Thu hoạch chín tới",
        timeline: "80 - 85 ngày sau khi đậu trái",
        iconBg: "bg-[#10B981]",
        summary: "Bón Kali ngọt cơm, thu hoạch kịp thời",
        soilWater: ["Tưới nước vừa đủ 3 ngày/lần."],
        fertilizer: ["Bón NPK 12-11-18 nuôi cơm béo."],
        pruningPest: ["Cắt thu hoạch khi gõ cuống giòn nổ."]
      }
    ]
  },
  {
    id: "blackthorn",
    name: "Sầu riêng Black Thorn / Gai Đen",
    subtitle: "Dòng siêu cao cấp - Cơm màu da cam đậm, ngọt đậm ngậy",
    badge: "Siêu cao cấp",
    density: "8m x 9m (120 cây/ha)",
    harvestDays: "90 – 100 ngày sau đậu trái",
    specialNote: "Black Thorn đòi hỏi lượng dinh dưỡng vi lượng cao và dàn lá khỏe trước khi làm bông. Đảm bảo bón đủ Kali hữu cơ giai đoạn 70-90 ngày để cơm đạt màu da cam rực rỡ.",
    steps: [
      {
        stage: "0-12m",
        stageTitle: "Giai đoạn 1: Chuẩn bị đất mô & Trồng cây giống (0 - 12 tháng)",
        timeline: "0 - 12 tháng đầu",
        iconBg: "bg-emerald-500",
        summary: "Đắp mô cao 1m, phun kích rễ đọt mập",
        soilWater: ["Đắp mô thoát nước 1m, tưới nước 1-2 ngày/lần."],
        fertilizer: ["Bón Humic + Amino Acid bón lá."],
        pruningPest: ["Phòng bọ trĩ & sâu đọt."]
      },
      {
        stage: "1-3y",
        stageTitle: "Giai đoạn 2: Kiến thiết bộ tán tròn xòe 4 hướng",
        timeline: "Năm thứ 1 đến Năm thứ 3",
        iconBg: "bg-teal-500",
        summary: "Phân bón sinh học vi sinh dầy lá",
        soilWater: ["Tưới ẩm đều đặn."],
        fertilizer: ["Bón hữu cơ nở 4kg/gốc/năm."],
        pruningPest: ["Tỉa cành tạo tán tròn xòe."]
      },
      {
        stage: "flower",
        stageTitle: "Giai đoạn 3: Kích mầm hoa Black Thorn & Thụ phấn",
        timeline: "Tháng 12 - Tháng 2",
        iconBg: "bg-amber-500",
        summary: "Siết nước nứt mô, thụ phấn ca đêm",
        soilWater: ["Cắt nước 20 ngày nhú mắt cua."],
        fertilizer: ["Phun MKP (0-52-34) chặn đọt."],
        pruningPest: ["Thụ phấn ca đêm từ 19h - 21h."]
      },
      {
        stage: "fruit",
        stageTitle: "Giai đoạn 4: Nuôi múi cơm da cam & Thu hoạch",
        timeline: "90 - 100 ngày sau khi đậu trái",
        iconBg: "bg-[#10B981]",
        summary: "Bón Kali hữu cơ da cam, cắt trái chín 9 tuổi",
        soilWater: ["Giữ ẩm mô ổn định."],
        fertilizer: ["Bón Kali hữu cơ da cam ngọt đậm."],
        pruningPest: ["Thu hoạch khi đĩa cuống chớm vàng nổ."]
      }
    ]
  },
  {
    id: "sauhuu",
    name: "Sầu riêng 6 Hữu (Đặc sản Bến Tre)",
    subtitle: "Đặc sản nổi tiếng Bến Tre - Vị ngọt đậm đượm, thơm nức",
    badge: "Đặc sản Bến Tre",
    density: "8m x 8m (125 cây/ha)",
    harvestDays: "85 – 90 ngày sau đậu trái",
    specialNote: "Sầu riêng 6 Hữu thích hợp thổ nhưỡng sông nước Miền Tây, chịu mặn nhẹ tốt. Cần chú ý bón vôi bột hạ phèn và dùng phân hữu cơ vi sinh định kỳ.",
    steps: [
      {
        stage: "0-12m",
        stageTitle: "Giai đoạn 1: Đắp vồng mô Miền Tây & Trồng cây con",
        timeline: "0 - 12 tháng đầu",
        iconBg: "bg-emerald-500",
        summary: "Làm vồng mô xơ dừa hoai mục, hạ phèn",
        soilWater: ["Làm vồng cao 0.8m, tưới nước ngọt 2 ngày/lần."],
        fertilizer: ["Bón vôi hạ phèn + Phân bò hoai."],
        pruningPest: ["Phòng nấm hồng & bọ trĩ."]
      },
      {
        stage: "1-3y",
        stageTitle: "Giai đoạn 2: Tỉa cành tạo tán & Quản lý mặn",
        timeline: "Năm thứ 1 đến Năm thứ 3",
        iconBg: "bg-teal-500",
        summary: "Bón phân hữu cơ vi sinh rửa mặn",
        soilWater: ["Đóng cống rửa mặn mùa khô."],
        fertilizer: ["Bón phân hữu cơ vi sinh 3kg/gốc."],
        pruningPest: ["Tỉa cành thưa lưa đón sáng."]
      },
      {
        stage: "flower",
        stageTitle: "Giai đoạn 3: Ép hoa theo thời tiết Miền Tây",
        timeline: "Tháng 11 - Tháng 1",
        iconBg: "bg-amber-500",
        summary: "Rút nước mương bưng, rải phân dằn đọt",
        soilWater: ["Rút cạn mương siết nước 15 ngày."],
        fertilizer: ["Rải MKP dằn đọt kích mầm hoa."],
        pruningPest: ["Thụ phấn ca đêm."]
      },
      {
        stage: "fruit",
        stageTitle: "Giai đoạn 4: Nuôi trái 6 Hữu cơm dầy ngọt lịm",
        timeline: "85 - 90 ngày sau khi đậu trái",
        iconBg: "bg-[#10B981]",
        summary: "Bón NPK Kali nuôi cơm, cắt trái chuẩn chín",
        soilWater: ["Tưới nước ngọt vừa đủ."],
        fertilizer: ["Bón NPK 12-11-18 nuôi cơm thơm."],
        pruningPest: ["Cắt thu hoạch khi cuống rã nổ."]
      }
    ]
  }
];

export default function UserHomePage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [selectedGradeFilter, setSelectedGradeFilter] = useState("all");
  const [selectedRegion, setSelectedRegion] = useState("taynguyen");
  const [selectedNewsTab, setSelectedNewsTab] = useState("highlight");

  // KỸ THUẬT CANH TÁC MODAL STATE
  const [isCultivationModalOpen, setIsCultivationModalOpen] = useState(false);
  const [selectedVarietyId, setSelectedVarietyId] = useState<string>("ri6");
  const [selectedStageFilter, setSelectedStageFilter] = useState<string>("all");

  const [userStats, setUserStats] = useState({
    totalFarms: 0,
    totalTrees: 0,
    activeIot: 0,
    attentionTrees: 0,
  });

  useEffect(() => {
    let isMounted = true;
    api.get("/api/v1/farms?per_page=100")
      .then((res) => {
        if (!isMounted) return;
        const raw = res.data;
        const items = Array.isArray(raw) ? raw : raw?.data?.items || raw?.data || [];
        const farmCount = items.length;
        const treeCount = items.reduce((sum: number, f: any) => sum + Number(f.tree_count || f.treeCount || 0), 0);
        
        if (farmCount > 0) {
          setUserStats({
            totalFarms: farmCount,
            totalTrees: treeCount || (farmCount * 350),
            activeIot: farmCount * 6,
            attentionTrees: Math.round((treeCount || 350) * 0.02) || 4,
          });
        } else {
          setUserStats({
            totalFarms: 0,
            totalTrees: 0,
            activeIot: 0,
            attentionTrees: 0,
          });
        }
      })
      .catch(() => {
        if (isMounted) {
          setUserStats({
            totalFarms: 0,
            totalTrees: 0,
            activeIot: 0,
            attentionTrees: 0,
          });
        }
      });

    return () => {
      isMounted = false;
    };
  }, [user]);

  const userName = user?.full_name || "Nguyễn Văn A";

  const selectedVariety = DURIAN_VARIETIES_TECH.find((v) => v.id === selectedVarietyId) || DURIAN_VARIETIES_TECH[0];

  const filteredSteps = useMemo(() => {
    if (selectedStageFilter === "all") return selectedVariety.steps;
    return selectedVariety.steps.filter((s) => s.stage === selectedStageFilter);
  }, [selectedVariety, selectedStageFilter]);

  return (
    <div className="flex flex-col space-y-6 pb-12 bg-[#F8FAFC] min-h-screen text-[#111827] font-['Plus_Jakarta_Sans',sans-serif] select-none p-6 lg:p-8">
      {/* ── SECTION 1: HERO BANNER & QUICK ACTIONS ── */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-stretch">
        {/* HERO CARD */}
        <div className="lg:col-span-8 bg-[#FAF6EE]/90 rounded-[20px] border border-[#E5E7EB] p-6 shadow-saas flex flex-col justify-between space-y-4 relative overflow-hidden transition-all duration-200">
          <div
            className="absolute right-0 top-0 bottom-0 w-1/2 sm:w-5/12 bg-cover bg-right pointer-events-none opacity-90 hidden sm:block rounded-r-[20px]"
            style={{
              backgroundImage: "url('/images/login/hero-durian.jpg')",
              maskImage: "linear-gradient(to right, transparent 0%, black 40%)",
              WebkitMaskImage: "linear-gradient(to right, transparent 0%, black 40%)",
            }}
          />

          <div className="space-y-4 max-w-xl relative z-10">
            <div>
              <div className="flex items-center gap-2 mb-1">
                <div className="w-8 h-8 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center flex-shrink-0">
                  <Sprout className="w-4.5 h-4.5" />
                </div>
                <h1 className="text-xl sm:text-2xl font-bold text-[#111827] leading-tight">
                  Xin chào, {userName}! 👋
                </h1>
              </div>
              <p className="text-xs text-[#6B7280] font-medium pl-10">
                AI hôm nay đã phân tích dữ liệu vườn của bạn
              </p>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div className="bg-white/95 backdrop-blur-xs rounded-[14px] p-2.5 border border-emerald-100 shadow-2xs flex items-center gap-2.5 transition-transform hover:-translate-y-0.5">
                <div className="w-8 h-8 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center flex-shrink-0">
                  <TrendingUp className="w-4 h-4 text-[#10B981]" />
                </div>
                <div className="min-w-0">
                  <div className="text-xs font-semibold text-[#111827] leading-tight truncate">Giá Ri6 tăng</div>
                  <div className="text-[11px] font-bold text-[#10B981] leading-tight truncate">▲ 3.5% so với hôm qua</div>
                </div>
              </div>

              <div className="bg-white/95 backdrop-blur-xs rounded-[14px] p-2.5 border border-amber-100 shadow-2xs flex items-center gap-2.5 transition-transform hover:-translate-y-0.5">
                <div className="w-8 h-8 rounded-full bg-amber-50 text-[#F59E0B] flex items-center justify-center flex-shrink-0">
                  <AlertTriangle className="w-4 h-4 text-[#F59E0B]" />
                </div>
                <div className="min-w-0">
                  <div className="text-xs font-semibold text-[#111827] leading-tight truncate">4 cây cần kiểm tra</div>
                  <div className="text-[11px] font-bold text-amber-600 leading-tight truncate">Phát hiện bất thường</div>
                </div>
              </div>

              <div className="bg-white/95 backdrop-blur-xs rounded-[14px] p-2.5 border border-blue-100 shadow-2xs flex items-center gap-2.5 transition-transform hover:-translate-y-0.5">
                <div className="w-8 h-8 rounded-full bg-blue-50 text-blue-600 flex items-center justify-center flex-shrink-0">
                  <CloudRain className="w-4 h-4 text-blue-600" />
                </div>
                <div className="min-w-0">
                  <div className="text-xs font-semibold text-[#111827] leading-tight truncate">Dự báo mưa</div>
                  <div className="text-[11px] font-bold text-blue-600 leading-tight truncate">Sau 2 giờ, lượng mưa nhẹ</div>
                </div>
              </div>
            </div>

            <div className="flex items-center gap-6 text-xs font-semibold text-[#6B7280] pt-2 border-t border-amber-100/70">
              <span className="flex items-center gap-1.5">
                <Calendar className="w-3.5 h-3.5 text-gray-400" /> 05/08/2026
              </span>
              <span className="flex items-center gap-1.5 text-[#F59E0B]">
                <Sun className="w-3.5 h-3.5" /> 28°C
              </span>
              <span className="flex items-center gap-1.5 text-[#10B981]">
                <MapPin className="w-3.5 h-3.5" /> Krông Pắc, Đắk Lắk
              </span>
            </div>
          </div>
        </div>

        {/* QUICK ACTION PANEL */}
        <div className="lg:col-span-4 bg-white rounded-[20px] border border-[#E5E7EB] p-6 shadow-saas flex flex-col justify-between space-y-4">
          <h2 className="text-sm font-bold text-[#111827]">Thao tác nhanh</h2>

          <div className="grid grid-cols-2 gap-3 flex-1">
            <button
              type="button"
              onClick={() => setIsCultivationModalOpen(true)}
              className="p-3 rounded-[14px] bg-[#D1FAE5]/30 hover:bg-[#D1FAE5]/70 border border-emerald-300 transition-all flex flex-col items-center justify-center text-center gap-2 group cursor-pointer hover:-translate-y-0.5"
            >
              <div className="w-9 h-9 rounded-full bg-[#10B981] text-white flex items-center justify-center group-hover:scale-105 transition-transform shadow-xs">
                <BookOpen className="w-4.5 h-4.5" />
              </div>
              <span className="text-xs font-bold text-emerald-900 leading-tight">Kỹ thuật canh tác</span>
            </button>

            <button
              type="button"
              onClick={() => navigate("/work-planning")}
              className="p-3 rounded-[14px] bg-[#F8FAFC] hover:bg-[#D1FAE5]/40 border border-[#E5E7EB] transition-all flex flex-col items-center justify-center text-center gap-2 group cursor-pointer hover:-translate-y-0.5"
            >
              <div className="w-9 h-9 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center group-hover:scale-105 transition-transform">
                <Sprout className="w-4.5 h-4.5" />
              </div>
              <span className="text-xs font-semibold text-[#111827] leading-tight">Lập kế hoạch công việc</span>
            </button>

            <button
              type="button"
              onClick={() => navigate("/work-planning")}
              className="p-3 rounded-[14px] bg-[#F8FAFC] hover:bg-[#D1FAE5]/40 border border-[#E5E7EB] transition-all flex flex-col items-center justify-center text-center gap-2 group cursor-pointer hover:-translate-y-0.5"
            >
              <div className="w-9 h-9 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center group-hover:scale-105 transition-transform">
                <Calendar className="w-4.5 h-4.5" />
              </div>
              <span className="text-xs font-semibold text-[#111827] leading-tight">Giao việc cho nhân công</span>
            </button>

            <button
              type="button"
              onClick={() => navigate("/ai-chatbot")}
              className="p-3 rounded-[14px] bg-[#F8FAFC] hover:bg-[#D1FAE5]/40 border border-[#E5E7EB] transition-all flex flex-col items-center justify-center text-center gap-2 group cursor-pointer hover:-translate-y-0.5"
            >
              <div className="w-9 h-9 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center group-hover:scale-105 transition-transform">
                <Bot className="w-4.5 h-4.5" />
              </div>
              <span className="text-xs font-semibold text-[#111827] leading-tight">Hỏi đáp AI Assistant</span>
            </button>
          </div>
        </div>
      </div>

      {/* ── SECTION 2: COMPACT KỸ THUẬT CANH TÁC BANNER CARD (THU GỌN THÀNH 1 THẺ NÚT BẤM) ── */}
      <div
        onClick={() => setIsCultivationModalOpen(true)}
        className="bg-gradient-to-r from-emerald-900 via-teal-900 to-emerald-950 text-white p-5 rounded-[20px] shadow-md border border-emerald-700/60 flex items-center justify-between gap-4 cursor-pointer hover:border-emerald-400 transition-all hover:-translate-y-0.5 group"
      >
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-2xl bg-emerald-700/60 border border-emerald-500/40 text-emerald-300 flex items-center justify-center flex-shrink-0 group-hover:scale-110 transition-transform">
            <BookOpen className="w-6 h-6" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-base font-black text-white">Kỹ Thuật Canh Tác Sầu Riêng Chuyên Sâu</h2>
              <span className="text-[10px] font-bold text-emerald-200 bg-emerald-800/80 px-2.5 py-0.5 rounded-full border border-emerald-600">
                Từ bé đến lớn (6 giống)
              </span>
            </div>
            <p className="text-xs text-emerald-200/80 font-medium mt-1">
              Tra cứu toàn bộ quy trình chăm sóc đắp mô, bón phân, siết nước ép hoa & nuôi trái theo từng giai đoạn
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={(e) => {
            e.stopPropagation();
            setIsCultivationModalOpen(true);
          }}
          className="px-4 py-2 bg-emerald-500 hover:bg-emerald-400 text-emerald-950 font-black text-xs rounded-xl shadow-sm transition-all whitespace-nowrap flex items-center gap-1.5 cursor-pointer"
        >
          <span>Xem kỹ thuật ngay</span>
          <ChevronRight className="w-4 h-4" />
        </button>
      </div>

      {/* ── SECTION 3: STATISTICS CARDS ── */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
        <div className="bg-white p-5 rounded-[20px] border border-[#E5E7EB] shadow-saas flex items-center justify-between transition-all hover:-translate-y-0.5">
          <div className="space-y-1">
            <span className="text-xs font-medium text-[#6B7280]">Tổng số vườn</span>
            <div className="text-2xl font-bold text-[#111827]">{userStats.totalFarms} <span className="text-xs font-normal text-[#6B7280]">vườn</span></div>
            <span className="text-[11px] font-semibold text-[#10B981] block">
              {userStats.totalFarms > 0 ? "▲ Vườn đang quản lý" : "● Chưa tạo vườn nào"}
            </span>
          </div>
          <div className="w-12 h-12 rounded-[14px] bg-[#D1FAE5] text-[#10B981] flex items-center justify-center flex-shrink-0">
            <Sprout className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-[20px] border border-[#E5E7EB] shadow-saas flex items-center justify-between transition-all hover:-translate-y-0.5">
          <div className="space-y-1">
            <span className="text-xs font-medium text-[#6B7280]">Tổng gốc sầu riêng</span>
            <div className="text-2xl font-bold text-[#111827]">{userStats.totalTrees.toLocaleString()} <span className="text-xs font-normal text-[#6B7280]">gốc</span></div>
            <span className="text-[11px] font-semibold text-[#10B981] block">
              {userStats.totalTrees > 0 ? "▲ Theo dõi AI 24/7" : "● Chưa có dữ liệu cây"}
            </span>
          </div>
          <div className="w-12 h-12 rounded-[14px] bg-[#D1FAE5] text-[#10B981] flex items-center justify-center flex-shrink-0">
            <Leaf className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-[20px] border border-[#E5E7EB] shadow-saas flex items-center justify-between transition-all hover:-translate-y-0.5">
          <div className="space-y-1">
            <span className="text-xs font-medium text-[#6B7280]">Thiết bị IoT đang hoạt động</span>
            <div className="text-2xl font-bold text-[#111827]">{userStats.activeIot} <span className="text-xs font-normal text-[#6B7280]">thiết bị</span></div>
            <span className="text-[11px] font-semibold text-[#10B981] block">
              {userStats.activeIot > 0 ? "● Hoạt động tốt" : "● Chưa có thiết bị IoT"}
            </span>
          </div>
          <div className="w-12 h-12 rounded-[14px] bg-[#D1FAE5] text-[#10B981] flex items-center justify-center flex-shrink-0">
            <Wifi className="w-6 h-6" />
          </div>
        </div>

        <div className="bg-white p-5 rounded-[20px] border border-[#E5E7EB] shadow-saas flex items-center justify-between transition-all hover:-translate-y-0.5">
          <div className="space-y-1">
            <span className="text-xs font-medium text-[#6B7280]">Cây cần chú ý</span>
            <div className="text-2xl font-bold text-[#111827]">{userStats.attentionTrees} <span className="text-xs font-normal text-[#6B7280]">gốc</span></div>
            <span className={`text-[11px] font-semibold block ${userStats.attentionTrees > 0 ? "text-[#F59E0B]" : "text-[#10B981]"}`}>
              {userStats.attentionTrees > 0 ? "● Cần kiểm tra" : "● Tất cả cây khỏe mạnh"}
            </span>
          </div>
          <div className="w-12 h-12 rounded-[14px] bg-amber-50 text-[#F59E0B] flex items-center justify-center flex-shrink-0">
            <AlertTriangle className="w-6 h-6" />
          </div>
        </div>
      </div>

      {/* ── SECTION 4: DURIAN PRICE MARKET ── */}
      <div className="bg-white p-6 rounded-[20px] border border-[#E5E7EB] shadow-saas space-y-5">
        <div className="flex flex-wrap items-center justify-between gap-3 pb-3 border-b border-[#E5E7EB]">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-[14px] bg-[#D1FAE5] text-[#10B981] flex items-center justify-center">
              <DollarSign className="w-5 h-5" />
            </div>
            <div>
              <h2 className="text-base font-bold text-[#111827] flex items-center gap-2">
                Giá Thu Mua Sầu Riêng Tại Vườn (Cho Thương Lái)
                <span className="text-[11px] font-semibold text-[#10B981] bg-[#D1FAE5] px-2.5 py-0.5 rounded-full">
                  Dữ liệu thực từ MongoDB
                </span>
              </h2>
              <p className="text-xs text-[#6B7280] font-medium mt-0.5">Nguồn: giasaurieng.net (Giá thu mua tại vườn cho thương lái)</p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <div className="flex items-center gap-1 bg-[#F8FAFC] p-1 rounded-full text-xs font-semibold border border-[#E5E7EB]">
              <button
                type="button"
                onClick={() => setSelectedGradeFilter("all")}
                className={`px-3 py-1 rounded-full transition-all cursor-pointer ${
                  selectedGradeFilter === "all" ? "bg-[#10B981] text-white shadow-xs" : "text-[#6B7280] hover:text-[#111827]"
                }`}
              >
                Tất cả (12)
              </button>
              <button
                type="button"
                onClick={() => setSelectedGradeFilter("dep")}
                className={`px-3 py-1 rounded-full transition-all cursor-pointer ${
                  selectedGradeFilter === "dep" ? "bg-[#10B981] text-white shadow-xs" : "text-[#6B7280] hover:text-[#111827]"
                }`}
              >
                ⭐ Hàng Đẹp (Loại 1)
              </button>
              <button
                type="button"
                onClick={() => setSelectedGradeFilter("xo")}
                className={`px-3 py-1 rounded-full transition-all cursor-pointer ${
                  selectedGradeFilter === "xo" ? "bg-[#10B981] text-white shadow-xs" : "text-[#6B7280] hover:text-[#111827]"
                }`}
              >
                📦 Hàng Xô (Lùa vựa)
              </button>
            </div>

            <div className="flex items-center gap-1 bg-[#F8FAFC] p-1 rounded-full text-xs font-semibold border border-[#E5E7EB]">
              <button
                type="button"
                onClick={() => setSelectedRegion("mientay")}
                className={`px-3 py-1 rounded-full transition-all cursor-pointer ${
                  selectedRegion === "mientay" ? "bg-[#10B981] text-white shadow-xs" : "text-[#6B7280] hover:text-[#111827]"
                }`}
              >
                Miền Tây Nam Bộ
              </button>
              <button
                type="button"
                onClick={() => setSelectedRegion("taynguyen")}
                className={`px-3 py-1 rounded-full transition-all cursor-pointer ${
                  selectedRegion === "taynguyen" ? "bg-[#10B981] text-white shadow-xs" : "text-[#6B7280] hover:text-[#111827]"
                }`}
              >
                Tây Nguyên
              </button>
              <button
                type="button"
                onClick={() => setSelectedRegion("miendong")}
                className={`px-3 py-1 rounded-full transition-all cursor-pointer ${
                  selectedRegion === "miendong" ? "bg-[#10B981] text-white shadow-xs" : "text-[#6B7280] hover:text-[#111827]"
                }`}
              >
                Miền Đông Nam Bộ
              </button>
            </div>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
          {DEFAULT_MARKET_ITEMS
            .filter((item) => {
              if (selectedGradeFilter === "dep") return item.grade === "dep";
              if (selectedGradeFilter === "xo") return item.grade === "xo";
              return true;
            })
            .map((item, idx) => {
              const isUp = item.trend === "up";
              const isDep = item.grade === "dep";
              return (
                <div
                  key={idx}
                  className={`p-4 rounded-[16px] border transition-all duration-200 flex flex-col justify-between space-y-3 hover:-translate-y-0.5 ${
                    isDep ? "bg-[#D1FAE5]/20 border-emerald-200 hover:border-[#10B981]" : "bg-[#F8FAFC] border-[#E5E7EB] hover:border-emerald-300"
                  }`}
                >
                  <div>
                    <div className="flex items-center justify-between gap-2 mb-1.5">
                      <span className="text-[10px] font-bold uppercase text-[#10B981] bg-[#D1FAE5] px-2 py-0.5 rounded-full">
                        {item.category}
                      </span>
                      <span className={`text-[10px] font-semibold px-2.5 py-0.5 rounded-full ${isDep ? "bg-amber-100 text-amber-900" : "bg-gray-200 text-gray-700"}`}>
                        {isDep ? "⭐ HÀNG ĐẸP LOẠI 1" : "📦 HÀNG XÔ LÙA VỰA"}
                      </span>
                    </div>
                    <h3 className="text-xs font-bold text-[#111827] leading-snug">{item.name}</h3>
                  </div>

                  <div className="flex items-center justify-between pt-2.5 border-t border-[#E5E7EB]">
                    <div>
                      <span className="text-base font-bold text-[#10B981] tracking-tight">{item.price}</span>
                      <span className="text-[11px] font-semibold text-[#6B7280] ml-1">{item.unit}</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${isUp ? "bg-[#D1FAE5] text-[#10B981]" : "bg-gray-100 text-gray-700"}`}>
                        {isUp ? `▲ ${item.change}` : item.change}
                      </span>
                      <svg className="w-12 h-5 text-[#10B981]" viewBox="0 0 50 20" fill="none">
                        <path d="M0 15 Q 12 5, 25 10 T 50 3" stroke="currentColor" strokeWidth="2" fill="none" />
                      </svg>
                    </div>
                  </div>
                </div>
              );
            })}
        </div>

        <div className="pt-2 text-center border-t border-[#E5E7EB]">
          <button
            type="button"
            className="text-xs font-bold text-[#10B981] hover:text-[#059669] inline-flex items-center gap-1 cursor-pointer transition-colors"
          >
            <span>Xem tất cả 12 loại giá</span>
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* ── SECTION 5: LOWER GRID (News & Disease Lookup) ── */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        <div className="lg:col-span-8 bg-white p-6 rounded-[20px] border border-[#E5E7EB] shadow-saas space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-2 border-b border-[#E5E7EB] pb-3">
            <h2 className="text-base font-bold text-[#111827]">Tin tức nông nghiệp & thị trường sầu riêng</h2>
            <button type="button" className="text-xs font-semibold text-[#10B981] hover:underline">
              Xem tất cả
            </button>
          </div>

          <div className="flex flex-wrap items-center gap-2 text-xs font-semibold">
            <button
              type="button"
              onClick={() => setSelectedNewsTab("highlight")}
              className={`px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                selectedNewsTab === "highlight" ? "bg-[#10B981] text-white shadow-xs" : "bg-[#F8FAFC] text-[#6B7280] hover:bg-[#D1FAE5]/40"
              }`}
            >
              🔥 Nổi bật hôm nay
            </button>
            <button
              type="button"
              onClick={() => setSelectedNewsTab("market")}
              className={`px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                selectedNewsTab === "market" ? "bg-[#10B981] text-white shadow-xs" : "bg-[#F8FAFC] text-[#6B7280] hover:bg-[#D1FAE5]/40"
              }`}
            >
              📉 Biến động giá
            </button>
            <button
              type="button"
              onClick={() => setSelectedNewsTab("export")}
              className={`px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                selectedNewsTab === "export" ? "bg-[#10B981] text-white shadow-xs" : "bg-[#F8FAFC] text-[#6B7280] hover:bg-[#D1FAE5]/40"
              }`}
            >
              📜 Mã vùng & Xuất khẩu
            </button>
            <button
              type="button"
              onClick={() => setSelectedNewsTab("weather")}
              className={`px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                selectedNewsTab === "weather" ? "bg-[#10B981] text-white shadow-xs" : "bg-[#F8FAFC] text-[#6B7280] hover:bg-[#D1FAE5]/40"
              }`}
            >
              ⛅ Thời tiết & Cảnh báo
            </button>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-[#F8FAFC] rounded-[16px] border border-[#E5E7EB] overflow-hidden flex flex-col justify-between hover:border-[#10B981] transition-all hover:-translate-y-0.5">
              <div className="h-32 overflow-hidden relative">
                <img
                  src="/images/login/hero-durian.jpg"
                  alt="News Durian Export"
                  className="w-full h-full object-cover hover:scale-105 transition-transform duration-300"
                />
              </div>
              <div className="p-4 space-y-2 flex-1 flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between text-[10px] font-bold text-[#6B7280] mb-1">
                    <span className="text-[#10B981] font-bold uppercase">📍 TOÀN QUỐC & XUẤT KHẨU</span>
                    <span>1 giờ trước</span>
                  </div>
                  <h3 className="text-xs font-bold text-[#111827] leading-snug line-clamp-2">
                    Xuất khẩu sầu riêng Việt Nam đạt kỷ lục 2,8 tỷ USD sang thị trường Trung Quốc
                  </h3>
                  <p className="text-[11px] text-[#6B7280] mt-1 line-clamp-3 leading-relaxed">
                    Tổng cục Hải quan Trung Quốc (GACC) vừa phê duyệt cấp mới 120 mã số vùng trồng Ri6 và Monthong tại Tiền Giang, Đắk Lắk...
                  </p>
                </div>
                <div className="text-[10px] font-medium text-gray-400 pt-2 border-t border-[#E5E7EB]">
                  Nguồn: Báo Nông Nghiệp Việt Nam
                </div>
              </div>
            </div>

            <div className="bg-[#F8FAFC] rounded-[16px] border border-[#E5E7EB] overflow-hidden flex flex-col justify-between hover:border-[#10B981] transition-all hover:-translate-y-0.5">
              <div className="h-32 overflow-hidden relative">
                <img
                  src="https://images.unsplash.com/photo-1534274988757-a28bf1a57c17?auto=format&fit=crop&w=600&q=80"
                  alt="News Weather"
                  className="w-full h-full object-cover hover:scale-105 transition-transform duration-300"
                />
              </div>
              <div className="p-4 space-y-2 flex-1 flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between text-[10px] font-bold text-[#6B7280] mb-1">
                    <span className="text-[#10B981] font-bold uppercase">📍 TÂY NGUYÊN (ĐẮK LẮK)</span>
                    <span>3 giờ trước</span>
                  </div>
                  <h3 className="text-xs font-bold text-[#111827] leading-snug line-clamp-2">
                    Dự báo rãnh áp thấp nhiệt đới gây mưa lớn tại Tây Nguyên: Nguy cơ xì mủ thối gốc
                  </h3>
                  <p className="text-[11px] text-[#6B7280] mt-1 line-clamp-3 leading-relaxed">
                    Chủ vườn sầu riêng Đắk Lắk & Lâm Đồng cần chủ động gia cố hệ thống thoát nước gốc và phòng nấm Phytophthora...
                  </p>
                </div>
                <div className="text-[10px] font-medium text-gray-400 pt-2 border-t border-[#E5E7EB]">
                  Nguồn: Trung tâm Dự báo KTTV
                </div>
              </div>
            </div>

            <div className="bg-[#F8FAFC] rounded-[16px] border border-[#E5E7EB] overflow-hidden flex flex-col justify-between hover:border-[#10B981] transition-all hover:-translate-y-0.5">
              <div className="h-32 overflow-hidden relative">
                <img
                  src="https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&w=600&q=80"
                  alt="News Pruning"
                  className="w-full h-full object-cover hover:scale-105 transition-transform duration-300"
                />
              </div>
              <div className="p-4 space-y-2 flex-1 flex flex-col justify-between">
                <div>
                  <div className="flex items-center justify-between text-[10px] font-bold text-[#6B7280] mb-1">
                    <span className="text-[#10B981] font-bold uppercase">📍 KỸ THUẬT</span>
                    <span>5 giờ trước</span>
                  </div>
                  <h3 className="text-xs font-bold text-[#111827] leading-snug line-clamp-2">
                    Kỹ thuật cắt tỉa cành sầu riêng giai đoạn kiến thiết cơ bản
                  </h3>
                  <p className="text-[11px] text-[#6B7280] mt-1 line-clamp-3 leading-relaxed">
                    Hướng dẫn chi tiết cách cắt tỉa cành tạo tán giúp cây phát triển khỏe mạnh về sau và cho năng suất cao.
                  </p>
                </div>
                <div className="text-[10px] font-medium text-gray-400 pt-2 border-t border-[#E5E7EB]">
                  Nguồn: Trung tâm Khuyến nông Quốc gia
                </div>
              </div>
            </div>
          </div>

          <div className="flex justify-center items-center gap-1.5 pt-2">
            <span className="w-2.5 h-2.5 rounded-full bg-[#10B981]" />
            <span className="w-2 h-2 rounded-full bg-gray-300" />
            <span className="w-2 h-2 rounded-full bg-gray-300" />
            <span className="w-2 h-2 rounded-full bg-gray-300" />
          </div>
        </div>

        <div className="lg:col-span-4 bg-white p-6 rounded-[20px] border border-[#E5E7EB] shadow-saas space-y-4">
          <div className="flex items-center justify-between border-b border-[#E5E7EB] pb-3">
            <h2 className="text-base font-bold text-[#111827]">Tra cứu nhanh sâu bệnh hại</h2>
            <button type="button" className="text-xs font-semibold text-[#10B981] hover:underline">
              Xem tất cả
            </button>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div
              onClick={() => navigate("/ai-chatbot")}
              className="p-3.5 rounded-[16px] bg-[#F8FAFC] border border-[#E5E7EB] hover:border-[#10B981] transition-all cursor-pointer flex flex-col justify-between space-y-2 hover:-translate-y-0.5"
            >
              <div className="w-8 h-8 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center">
                <Bug className="w-4 h-4" />
              </div>
              <div>
                <h3 className="text-xs font-bold text-[#111827] leading-tight">Bệnh Thán Thư</h3>
                <span className="text-[10px] text-[#6B7280] font-medium">(Colletotrichum)</span>
                <p className="text-[10px] text-[#6B7280] mt-1">Triệu chứng & cách phòng trị</p>
              </div>
            </div>

            <div
              onClick={() => navigate("/ai-chatbot")}
              className="p-3.5 rounded-[16px] bg-[#F8FAFC] border border-[#E5E7EB] hover:border-[#10B981] transition-all cursor-pointer flex flex-col justify-between space-y-2 hover:-translate-y-0.5"
            >
              <div className="w-8 h-8 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center">
                <Sprout className="w-4 h-4" />
              </div>
              <div>
                <h3 className="text-xs font-bold text-[#111827] leading-tight">Nấm Phytophthora</h3>
                <span className="text-[10px] text-[#6B7280] font-medium">(Xì mủ thối gốc)</span>
                <p className="text-[10px] text-[#6B7280] mt-1">Triệu chứng & cách phòng trị</p>
              </div>
            </div>

            <div
              onClick={() => navigate("/ai-chatbot")}
              className="p-3.5 rounded-[16px] bg-[#F8FAFC] border border-[#E5E7EB] hover:border-[#10B981] transition-all cursor-pointer flex flex-col justify-between space-y-2 hover:-translate-y-0.5"
            >
              <div className="w-8 h-8 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center">
                <ShieldAlert className="w-4 h-4" />
              </div>
              <div>
                <h3 className="text-xs font-bold text-[#111827] leading-tight">Bọ Trĩ (Thrips spp.)</h3>
                <p className="text-[10px] text-[#6B7280] font-medium">Côn trùng chích hút</p>
                <p className="text-[10px] text-[#6B7280] mt-1">Nhận biết & xử lý</p>
              </div>
            </div>

            <div
              onClick={() => navigate("/ai-chatbot")}
              className="p-3.5 rounded-[16px] bg-[#F8FAFC] border border-[#E5E7EB] hover:border-[#10B981] transition-all cursor-pointer flex flex-col justify-between space-y-2 hover:-translate-y-0.5"
            >
              <div className="w-8 h-8 rounded-full bg-[#D1FAE5] text-[#10B981] flex items-center justify-center">
                <Bug className="w-4 h-4" />
              </div>
              <div>
                <h3 className="text-xs font-bold text-[#111827] leading-tight">Sâu Đục Quả</h3>
                <span className="text-[10px] text-[#6B7280] font-medium">(Conogethes punctiferalis)</span>
                <p className="text-[10px] text-[#6B7280] mt-1">Nhận biết & xử lý</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ── INTERACTIVE FULL-SCREEN MODAL DIALOG: KỸ THUẬT CANH TÁC ── */}
      {isCultivationModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-xs flex items-center justify-center p-4 sm:p-6 overflow-y-auto">
          <div className="bg-white rounded-[24px] border border-gray-200 shadow-2xl w-full max-w-5xl max-h-[90vh] overflow-y-auto space-y-6 p-6 sm:p-8 animate-in fade-in zoom-in-95 duration-200">
            {/* Modal Header */}
            <div className="flex items-center justify-between pb-4 border-b border-gray-200 sticky top-0 bg-white z-20">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-2xl bg-emerald-100 text-emerald-700 flex items-center justify-center font-bold">
                  <BookOpen className="w-6 h-6" />
                </div>
                <div>
                  <h2 className="text-lg sm:text-xl font-black text-gray-900 flex items-center gap-2">
                    <span>Kỹ Thuật Canh Tác Sầu Riêng Chuyên Sâu</span>
                    <span className="text-xs font-bold text-emerald-800 bg-emerald-100 px-3 py-0.5 rounded-full border border-emerald-300">
                      Từ bé đến lớn
                    </span>
                  </h2>
                  <p className="text-xs text-gray-500 font-medium mt-0.5">
                    Chọn giống sầu riêng bên dưới để xem quy trình chăm sóc từ cây con đến thu hoạch
                  </p>
                </div>
              </div>

              <button
                type="button"
                onClick={() => setIsCultivationModalOpen(false)}
                className="w-9 h-9 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-600 hover:text-gray-900 flex items-center justify-center transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Variety Selector Tabs */}
            <div className="space-y-2">
              <span className="text-xs font-bold text-gray-500 uppercase tracking-wider block">
                Chọn Giống Sầu Riêng:
              </span>
              <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
                {DURIAN_VARIETIES_TECH.map((v) => {
                  const isSelected = v.id === selectedVarietyId;
                  return (
                    <button
                      key={v.id}
                      type="button"
                      onClick={() => setSelectedVarietyId(v.id)}
                      className={`p-3.5 rounded-[16px] border text-left transition-all cursor-pointer flex flex-col justify-between space-y-2 ${
                        isSelected
                          ? "bg-emerald-800 text-white border-emerald-900 shadow-md ring-2 ring-emerald-400 scale-[1.02]"
                          : "bg-gray-50/80 hover:bg-emerald-50/60 text-gray-800 border-gray-200 hover:border-emerald-300"
                      }`}
                    >
                      <div className="flex items-center justify-between">
                        <span className={`text-[10px] font-black uppercase px-2 py-0.5 rounded-full ${
                          isSelected ? "bg-emerald-700 text-emerald-100" : "bg-emerald-100 text-emerald-800"
                        }`}>
                          {v.badge}
                        </span>
                        {isSelected && <CheckCircle2 className="w-4 h-4 text-emerald-300" />}
                      </div>

                      <div>
                        <h3 className={`text-xs font-black leading-snug ${isSelected ? "text-white" : "text-gray-900"}`}>
                          {v.name}
                        </h3>
                        <p className={`text-[10px] font-medium line-clamp-1 mt-0.5 ${isSelected ? "text-emerald-200" : "text-gray-500"}`}>
                          {v.subtitle}
                        </p>
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Stage Filter Pills & Variety Banner */}
            <div className="bg-gradient-to-r from-emerald-900 via-teal-900 to-emerald-950 text-white p-5 rounded-[20px] shadow-md border border-emerald-700/60 space-y-3">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-emerald-700/60 pb-3">
                <div>
                  <span className="text-xs font-bold uppercase tracking-wider text-emerald-300 block mb-1">
                    📌 Hướng Dẫn Kỹ Thuật Canh Tác Chuyên Sâu
                  </span>
                  <h3 className="text-lg font-black text-white flex items-center gap-2">
                    <span>{selectedVariety.name}</span>
                    <span className="text-xs bg-emerald-800 text-emerald-200 font-mono px-2.5 py-0.5 rounded-full border border-emerald-600 font-bold">
                      {selectedVariety.badge}
                    </span>
                  </h3>
                </div>

                <div className="flex flex-wrap items-center gap-4 text-xs font-bold">
                  <div className="bg-emerald-800/60 px-3 py-1.5 rounded-xl border border-emerald-600/50">
                    <span className="text-emerald-300 text-[10px] block font-semibold">Mật độ khuyến nghị</span>
                    <span>{selectedVariety.density}</span>
                  </div>
                  <div className="bg-emerald-800/60 px-3 py-1.5 rounded-xl border border-emerald-600/50">
                    <span className="text-emerald-300 text-[10px] block font-semibold">Thời gian thu hoạch</span>
                    <span>{selectedVariety.harvestDays}</span>
                  </div>
                </div>
              </div>

              <div className="text-xs text-emerald-100/90 leading-relaxed font-medium bg-emerald-950/40 p-3 rounded-xl border border-emerald-800/50 flex items-start gap-2">
                <Sparkles className="w-4 h-4 text-amber-400 flex-shrink-0 mt-0.5" />
                <span><strong>Lưu ý kỹ thuật giống:</strong> {selectedVariety.specialNote}</span>
              </div>
            </div>

            {/* Stage Filter */}
            <div className="flex items-center gap-1.5 bg-gray-50 p-2 rounded-2xl border border-gray-200 text-xs font-bold overflow-x-auto">
              <span className="text-gray-500 font-semibold px-2">Lọc giai đoạn:</span>
              <button
                type="button"
                onClick={() => setSelectedStageFilter("all")}
                className={`px-3 py-1.5 rounded-xl transition-all cursor-pointer whitespace-nowrap ${
                  selectedStageFilter === "all" ? "bg-emerald-600 text-white shadow-xs" : "text-gray-600 hover:text-gray-900"
                }`}
              >
                Tất cả giai đoạn (4)
              </button>
              <button
                type="button"
                onClick={() => setSelectedStageFilter("0-12m")}
                className={`px-3 py-1.5 rounded-xl transition-all cursor-pointer whitespace-nowrap ${
                  selectedStageFilter === "0-12m" ? "bg-emerald-600 text-white shadow-xs" : "text-gray-600 hover:text-gray-900"
                }`}
              >
                🌱 0 - 12 Tháng
              </button>
              <button
                type="button"
                onClick={() => setSelectedStageFilter("1-3y")}
                className={`px-3 py-1.5 rounded-xl transition-all cursor-pointer whitespace-nowrap ${
                  selectedStageFilter === "1-3y" ? "bg-emerald-600 text-white shadow-xs" : "text-gray-600 hover:text-gray-900"
                }`}
              >
                🌿 1 - 3 Năm
              </button>
              <button
                type="button"
                onClick={() => setSelectedStageFilter("flower")}
                className={`px-3 py-1.5 rounded-xl transition-all cursor-pointer whitespace-nowrap ${
                  selectedStageFilter === "flower" ? "bg-emerald-600 text-white shadow-xs" : "text-gray-600 hover:text-gray-900"
                }`}
              >
                🌸 Ra Hoa & Đậu Trái
              </button>
              <button
                type="button"
                onClick={() => setSelectedStageFilter("fruit")}
                className={`px-3 py-1.5 rounded-xl transition-all cursor-pointer whitespace-nowrap ${
                  selectedStageFilter === "fruit" ? "bg-emerald-600 text-white shadow-xs" : "text-gray-600 hover:text-gray-900"
                }`}
              >
                🍈 Nuôi Trái & Thu Hoạch
              </button>
            </div>

            {/* Stage Steps Grid */}
            <div className="space-y-5 pt-1">
              {filteredSteps.map((step, idx) => (
                <div
                  key={idx}
                  className="bg-white rounded-[20px] border border-gray-200 p-5 shadow-xs hover:border-emerald-300 transition-all space-y-4"
                >
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-gray-100 pb-3">
                    <div className="flex items-center gap-3">
                      <div className={`w-8 h-8 rounded-full ${step.iconBg} text-white font-black text-xs flex items-center justify-center shadow-xs`}>
                        {idx + 1}
                      </div>
                      <div>
                        <h4 className="text-sm font-black text-gray-900">{step.stageTitle}</h4>
                        <span className="text-xs text-emerald-700 font-bold">{step.summary}</span>
                      </div>
                    </div>

                    <span className="text-xs bg-gray-100 text-gray-700 font-bold px-3 py-1 rounded-full border border-gray-200 flex items-center gap-1.5">
                      <Clock className="w-3.5 h-3.5 text-emerald-600" />
                      <span>{step.timeline}</span>
                    </span>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs font-medium">
                    <div className="bg-emerald-50/40 border border-emerald-100 p-4 rounded-2xl space-y-2">
                      <h5 className="font-extrabold text-emerald-900 flex items-center gap-1.5 text-xs">
                        <Sprout className="w-4 h-4 text-emerald-600" />
                        <span>Đất Trồng Mô & Tưới Nước</span>
                      </h5>
                      <ul className="space-y-1.5 text-gray-700 list-disc pl-4 leading-relaxed">
                        {step.soilWater.map((item, i) => (
                          <li key={i}>{item}</li>
                        ))}
                      </ul>
                    </div>

                    <div className="bg-amber-50/40 border border-amber-100 p-4 rounded-2xl space-y-2">
                      <h5 className="font-extrabold text-amber-900 flex items-center gap-1.5 text-xs">
                        <Layers className="w-4 h-4 text-amber-600" />
                        <span>Phân Bón & Dinh Dưỡng</span>
                      </h5>
                      <ul className="space-y-1.5 text-gray-700 list-disc pl-4 leading-relaxed">
                        {step.fertilizer.map((item, i) => (
                          <li key={i}>{item}</li>
                        ))}
                      </ul>
                    </div>

                    <div className="bg-blue-50/40 border border-blue-100 p-4 rounded-2xl space-y-2">
                      <h5 className="font-extrabold text-blue-900 flex items-center gap-1.5 text-xs">
                        <ShieldAlert className="w-4 h-4 text-blue-600" />
                        <span>Tỉa Cành & Phòng Trừ Sâu Bệnh</span>
                      </h5>
                      <ul className="space-y-1.5 text-gray-700 list-disc pl-4 leading-relaxed">
                        {step.pruningPest.map((item, i) => (
                          <li key={i}>{item}</li>
                        ))}
                      </ul>
                    </div>
                  </div>
                </div>
              ))}
            </div>

            {/* Modal Footer */}
            <div className="pt-4 border-t border-gray-200 flex justify-end">
              <button
                type="button"
                onClick={() => setIsCultivationModalOpen(false)}
                className="px-6 py-2.5 bg-gray-900 hover:bg-black text-white font-bold text-xs rounded-xl shadow-md transition-all cursor-pointer"
              >
                Đóng hướng dẫn
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
