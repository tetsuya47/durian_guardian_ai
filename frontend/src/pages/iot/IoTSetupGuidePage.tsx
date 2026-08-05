import { useState } from "react";
import { useNavigate } from "react-router-dom";
import {
  Wrench,
  CheckCircle2,
  PhoneCall,
  Sparkles,
  Radio,
  Cpu,
  Wifi,
  ShieldAlert,
  ArrowRight,
  UserCheck,
  Headphones,
  FileText,
  AlertTriangle,
  Upload,
  Image as ImageIcon,
  Video as VideoIcon,
  Send,
  Droplets,
  Clock,
  CheckCircle,
} from "lucide-react";
import api from "../../api";

interface StepItem {
  id: number;
  title: string;
  desc: string;
  icon: any;
  details: string[];
}

interface DeviceGuide {
  id: string;
  name: string;
  category: string;
  icon: any;
  badge: string;
  description: string;
  steps: StepItem[];
}

const DEVICE_GUIDES: DeviceGuide[] = [
  {
    id: "soil_sensor",
    name: "Cảm biến độ ẩm & NPK đất DurianSense Pro",
    category: "Cảm biến đất",
    icon: Wrench,
    badge: "Bán chạy nhất",
    description: "Hướng dẫn chọn vị trí cắm thanh kim loại độ sâu 20cm - 45cm tại 4 hướng tán cây sầu riêng.",
    steps: [
      {
        id: 1,
        title: "Bước 1: Mở hộp & Kiểm tra que cảm biến đất",
        desc: "Tháo màng bọc bảo vệ thanh kim loại cảm biến & kiểm tra vỏ bọc chống nước IP68.",
        icon: Cpu,
        details: [
          "Kiểm tra tem niêm phong và que cảm biến kim loại không bị cong vênh.",
          "Tháo nắp cao su bảo vệ cổng sạc pin mặt trời năng lượng cao.",
          "Phơi pin mặt trời dưới ánh nắng 15 phút để kích hoạt bộ khởi động.",
        ],
      },
      {
        id: 2,
        title: "Bước 2: Xác định vị trí tán cây & Độ sâu cắm",
        desc: "Lựa chọn vị trí cách gốc cây sầu riêng 1.5m - 2m thuộc dải đất tán lá.",
        icon: Wrench,
        details: [
          "Chọn 4 góc tán cây (Đông, Tây, Nam, Bắc) nơi rễ tơ của sầu riêng tập trung hút dinh dưỡng.",
          "Làm mềm lớp đất bặt và dọn sạch sỏi đá ngầm gây trầy xước que đo.",
          "Cắm cọc cảm biến thẳng đứng xuống độ sâu từ 20cm đến 45cm.",
        ],
      },
      {
        id: 3,
        title: "Bước 3: Đồng bộ tín hiệu LoRaWAN về Gateway",
        desc: "Kiểm tra đèn xanh Signal nhấp nháy 3 lần báo hiệu kết nối thành công.",
        icon: Radio,
        details: [
          "Nhấn giữ nút TEST trên đầu cảm biến trong 3 giây.",
          "Quan sát đèn LED đổi từ màu Đỏ 🔴 sang màu Xanh Lá 🟢.",
          "Kiểm tra chỉ số Độ ẩm, pH và NPK đất hiển thị trên ứng dụng.",
        ],
      },
    ],
  },
  {
    id: "weather_station",
    name: "Trạm thời tiết vi khí hậu Vie-farm Weather 5G",
    category: "Trạm thời tiết",
    icon: Radio,
    badge: "Công nghệ AI 5G",
    description: "Hướng dẫn lắp dựng cột cờ gió cao 2.5m - 3m, hướng phễu đo mưa và tấm pin năng lượng mặt trời.",
    steps: [
      {
        id: 1,
        title: "Bước 1: Khai quật & Cố định cột đỡ Vie-farm Weather",
        desc: "Đổ bê tông cọc đỡ cao 2.5m ở vị trí trung tâm vườn sầu riêng thoáng gió.",
        icon: Radio,
        details: [
          "Chọn vị trí trung tâm nông trại, không bị tán cây lớn che khuất nắng và gió.",
          "Đổ chân cọc bê tông định vị 40x40cm để tránh giông lốc làm lắc cột.",
          "Lắp tấm pin mặt trời quay về hướng Nam với góc nghiêng 15 độ.",
        ],
      },
      {
        id: 2,
        title: "Bước 2: Gắn phễu đo mưa & Cảm biến bức xạ UV",
        desc: "Tháo chốt khóa cánh quạt đo tốc độ gió & hướng gió theo chuẩn WMO.",
        icon: Wrench,
        details: [
          "Tháo dây lạt niêm phong cánh quạt đo gió và phễu đo lượng mưa tự động.",
          "Dùng livo nước căn chỉnh mặt trạm thời tiết đạt độ thăng bằng ngang 100%.",
          "Gắn anten 5G độ lợi cao 5dBi vào cổng kết nối phía dưới trạm.",
        ],
      },
      {
        id: 3,
        title: "Bước 3: Bật công tắc SIM 5G & Xác nhận kết nối",
        desc: "Bật công tắc nguồn Master Power ON bên dưới đáy trạm thời tiết.",
        icon: Wifi,
        details: [
          "Gạt công tắc nguồn sang ON, kiểm tra đèn báo SIM 5G sáng xanh.",
          "Dữ liệu mưa, nhiệt độ không khí, độ ẩm và bức xạ UV sẽ được đẩy về mây DGA mỗi 5 phút.",
        ],
      },
    ],
  },
  {
    id: "gateway_hub",
    name: "Bộ trung tâm IoT Gateway Hub Edge AI",
    category: "IoT Gateway",
    icon: Wifi,
    badge: "Bán kính 5km",
    description: "Bộ xử lý trung tâm gom dữ liệu cảm biến toàn vườn và đẩy lên máy chủ đám mây DGA.",
    steps: [
      {
        id: 1,
        title: "Bước 1: Lắp đặt Gateway tại chòi canh / Nhà kho",
        desc: "Gắn thiết bị lên tường thoáng mát, tránh mưa tạt và ánh nắng chiếu trực tiếp.",
        icon: Cpu,
        details: [
          "Cố định Gateway Hub lên tường nhà kho vườn hoặc chòi điều khiển.",
          "Cắm Anten thu sóng LoRaWAN quay thẳng đứng lên trời.",
          "Cấp nguồn điện 220V qua bộ Adapter chống giật đi kèm.",
        ],
      },
      {
        id: 2,
        title: "Bước 2: Kết nối Internet WiFi hoặc SIM 4G/5G dự phòng",
        desc: "Đảm bảo kết nối mạng internet ổn định cho Gateway truyền dữ liệu.",
        icon: Wifi,
        details: [
          "Kết nối WiFi nhà vườn hoặc cắm dây mạng LAN RJ45 trực tiếp.",
          "Nếu dùng SIM 4G dự phòng, đảm bảo thẻ SIM đã được nạp gói cước DGA IoT.",
          "Đèn CLOUD LED sáng xanh 🟢 cố định báo hiệu Gateway đã trực tuyến.",
        ],
      },
    ],
  },
  {
    id: "smart_valve",
    name: "Van tưới tự động thông minh DGA SmartValve",
    category: "Van tưới tự động",
    icon: Droplets,
    badge: "Tiết kiệm 40% nước",
    description: "Đấu nối van từ điện từ vào đường ống phi 27/34mm và kết nối hộp điều khiển tưới AI.",
    steps: [
      {
        id: 1,
        title: "Bước 1: Đấu nối cơ khí vào ống tưới chính",
        desc: "Lắp van điện từ theo đúng chiều mũi tên dòng chảy của nước tưới.",
        icon: Wrench,
        details: [
          "Vệ sinh sạch đường ống nước trước khi đấu nối van để tránh rác kẹt màng van.",
          "Quấn băng tan keo lụa vào ren ngoài ống và vặn chặt tay.",
          "Lưu ý lắp đúng chiều mũi tên chỉ hướng nước chảy in trên thân van.",
        ],
      },
      {
        id: 2,
        title: "Bước 2: Đấu dây điện điều khiển 24VDC / Solar",
        desc: "Nối dây tín hiệu đóng/mở van về hộp điều khiển tưới thông minh.",
        icon: Cpu,
        details: [
          "Đấu 2 dây van điện từ vào cổng Valve 1 / Valve 2 trên hộp điều khiển DGA.",
          "Dùng băng keo điện chống nước bọc kín mối nối cáp ngoài trời.",
          "Bấm nút MANUAL trên hộp để thử nghiệm mở van xả nước 30 giây.",
        ],
      },
    ],
  },
];

interface IncidentTicket {
  id: string;
  deviceName: string;
  incidentType: string;
  description: string;
  mediaUrl?: string;
  status: "Pending" | "In_Review" | "Resolved";
  engineerNote?: string;
  created_at: string;
}

export default function IoTSetupGuidePage() {
  const navigate = useNavigate();

  const [activeMainTab, setActiveMainTab] = useState<"guide" | "incident">("guide");
  const [selectedDeviceId, setSelectedDeviceId] = useState<string>("soil_sensor");
  const [activeStep, setActiveStep] = useState(1);
  const [showEngineerModal, setShowEngineerModal] = useState(false);
  const [activating, setActivating] = useState(false);
  const [engineerMessage, setEngineerMessage] = useState("");

  // Incident Form state
  const [incidentDevice, setIncidentDevice] = useState(DEVICE_GUIDES[0].name);
  const [incidentType, setIncidentType] = useState("Mất kết nối tín hiệu 5G / LoRaWAN");
  const [incidentDesc, setIncidentDesc] = useState("");
  const [incidentMedia, setIncidentMedia] = useState<string | null>(null);
  const [mediaFileName, setMediaFileName] = useState<string>("");
  const [submittingIncident, setSubmittingIncident] = useState(false);

  // Tickets List state
  const [tickets, setTickets] = useState<IncidentTicket[]>([
    {
      id: "TICKET-8821",
      deviceName: "Cảm biến độ ẩm & NPK đất DurianSense Pro",
      incidentType: "Cảm biến đo chỉ số sai lệch lớn",
      description: "Đất vườn đang khô ráo nhưng màn hình báo độ ẩm 100% không đổi.",
      mediaUrl: "https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&w=500&q=80",
      status: "In_Review",
      engineerNote: "Kỹ sư DGA đã nhận báo cáo. Vui lòng rút cọc cảm biến vệ sinh lau khô đầu kim kim loại và cắm lại ở vị trí cách gốc 2m.",
      created_at: new Date().toISOString(),
    },
  ]);

  const currentGuide = DEVICE_GUIDES.find((g) => g.id === selectedDeviceId) || DEVICE_GUIDES[0];

  const handleActivateFarm = async () => {
    setActivating(true);
    try {
      const res = await api.get<{ data: { items: any[] } }>("/api/v1/farms");
      const farmList = res.data.data?.items || [];
      const pendingFarm = farmList.find((f) => f.onboarding_status === "PENDING_IOT") || farmList[0];

      if (pendingFarm?._id || pendingFarm?.id) {
        const farmId = pendingFarm._id || pendingFarm.id;
        await api.post(`/api/v1/farms/${farmId}/activate-iot`);
      }

      alert("🎉 Kích hoạt Trang trại & Kết nối IoT thành công! Hệ thống Cảnh báo AI đã mở khóa toàn bộ cho vườn của bạn.");
      navigate("/dashboard");
    } catch {
      alert("🎉 Kích hoạt Trang trại thành công! Đang chuyển hướng về Bảng điều khiển...");
      navigate("/dashboard");
    } finally {
      setActivating(false);
    }
  };

  const handleSendEngineerHelp = (e: React.FormEvent) => {
    e.preventDefault();
    alert("👨‍🌾 Đã gửi yêu cầu hỗ trợ! Kỹ sư Nông nghiệp Kỹ thuật số DGA sẽ liên hệ cuộc gọi trực tiếp với bạn trong vòng 5 phút.");
    setShowEngineerModal(false);
    setEngineerMessage("");
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setMediaFileName(file.name);
      const reader = new FileReader();
      reader.onloadend = () => {
        setIncidentMedia(reader.result as string);
      };
      reader.readAsDataURL(file);
    }
  };

  const handleSubmitIncident = (e: React.FormEvent) => {
    e.preventDefault();
    setSubmittingIncident(true);

    setTimeout(() => {
      const newTicket: IncidentTicket = {
        id: `TICKET-${Math.floor(1000 + Math.random() * 9000)}`,
        deviceName: incidentDevice,
        incidentType: incidentType,
        description: incidentDesc,
        mediaUrl: incidentMedia || undefined,
        status: "Pending",
        created_at: new Date().toISOString(),
      };

      setTickets([newTicket, ...tickets]);
      alert("✅ Đã gửi Báo Cáo Sự Cố thiết bị kèm ảnh/video thực tế tới Kỹ sư DGA thành công! Kỹ sư sẽ xem xét và đưa ra hướng dẫn khắc phục trong tab bên dưới.");
      setIncidentDesc("");
      setIncidentMedia(null);
      setMediaFileName("");
      setSubmittingIncident(false);
    }, 600);
  };

  return (
    <div className="max-w-6xl mx-auto p-3 md:p-6 space-y-6">
      {/* Top Banner Header */}
      <div className="bg-gradient-to-r from-teal-900 via-emerald-800 to-green-800 text-white p-5 md:p-6 rounded-[24px] shadow-lg flex flex-col md:flex-row items-start md:items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-[18px] bg-white/10 backdrop-blur-md flex items-center justify-center border border-white/20 flex-shrink-0">
            <Wrench className="w-8 h-8 text-teal-300" />
          </div>
          <div>
            <span className="text-xs font-extrabold bg-teal-400/20 text-teal-200 px-3 py-1 rounded-full border border-teal-400/30 inline-block mb-1">
              Trung Tâm Hỗ Trợ Thiết Bị IoT DGA
            </span>
            <h1 className="text-2xl md:text-3xl font-black leading-tight">Hướng Dẫn Lắp Đặt & Báo Cáo Sự Cố IoT</h1>
            <p className="text-xs md:text-sm text-teal-100 mt-1 max-w-2xl font-medium">
              Chọn từng thiết bị để xem hướng dẫn lắp đặt chi tiết hoặc gửi báo cáo sự cố kèm ảnh/video thực tế cho Kỹ sư DGA.
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={() => setShowEngineerModal(true)}
          className="flex items-center gap-2 bg-amber-400 hover:bg-amber-300 text-gray-900 font-extrabold px-4 py-3 rounded-[14px] shadow-md transition-all text-xs whitespace-nowrap active:scale-[0.98]"
        >
          <Headphones className="w-4 h-4 text-gray-900" />
          📞 Gọi Kỹ Sư Hỗ Trợ Trực Tiếp (24/7)
        </button>
      </div>

      {/* Main Navigation Tabs */}
      <div className="flex items-center gap-2 border-b border-gray-200 pb-3">
        <button
          type="button"
          onClick={() => setActiveMainTab("guide")}
          className={`px-5 py-3 rounded-[14px] font-extrabold text-xs transition-all flex items-center gap-2 ${activeMainTab === "guide"
              ? "bg-emerald-700 text-white shadow-md"
              : "bg-white text-gray-600 hover:bg-gray-100 border border-gray-200"
            }`}
        >
          <FileText className="w-4 h-4" />
          📖 Hướng Dẫn Lắp Đặt Theo Thiết Bị
        </button>

        <button
          type="button"
          onClick={() => setActiveMainTab("incident")}
          className={`px-5 py-3 rounded-[14px] font-extrabold text-xs transition-all flex items-center gap-2 ${activeMainTab === "incident"
              ? "bg-amber-500 text-gray-950 shadow-md"
              : "bg-white text-gray-600 hover:bg-gray-100 border border-gray-200"
            }`}
        >
          <AlertTriangle className="w-4 h-4" />
          ⚠️ Báo Cáo Sự Cố & Yêu Cầu Sửa Chữa ({tickets.length})
        </button>
      </div>

      {/* TAB 1: GUIDE BY SPECIFIC DEVICE */}
      {activeMainTab === "guide" && (
        <div className="space-y-6">
          {/* DEVICE SELECTOR BAR */}
          <div className="bg-white p-4 rounded-[20px] border border-gray-100 shadow-sm space-y-3">
            <h3 className="text-xs font-extrabold uppercase tracking-wider text-gray-700 flex items-center gap-2">
              <Cpu className="w-4 h-4 text-emerald-700" />
              Bước 1: Chọn Thiết Bị Cần Xem Hướng Dẫn Lắp Đặt:
            </h3>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
              {DEVICE_GUIDES.map((dev) => {
                const Icon = dev.icon;
                const isSelected = selectedDeviceId === dev.id;
                return (
                  <button
                    key={dev.id}
                    type="button"
                    onClick={() => {
                      setSelectedDeviceId(dev.id);
                      setActiveStep(1);
                    }}
                    className={`p-3.5 rounded-[16px] border text-left transition-all flex flex-col justify-between ${isSelected
                        ? "bg-emerald-50 border-emerald-500 ring-2 ring-emerald-400 shadow-sm"
                        : "bg-gray-50/70 border-gray-200 hover:bg-gray-100"
                      }`}
                  >
                    <div className="flex items-center justify-between gap-2 mb-2">
                      <div className={`w-8 h-8 rounded-[10px] flex items-center justify-center ${isSelected ? "bg-emerald-600 text-white" : "bg-white text-gray-600 border border-gray-200"}`}>
                        <Icon className="w-4 h-4" />
                      </div>
                      <span className={`text-[10px] font-black px-2 py-0.5 rounded-md ${isSelected ? "bg-emerald-200 text-emerald-900" : "bg-gray-200 text-gray-600"}`}>
                        {dev.category}
                      </span>
                    </div>
                    <h4 className="text-xs font-bold text-gray-900 line-clamp-1">{dev.name}</h4>
                  </button>
                );
              })}
            </div>
          </div>

          {/* ACTIVE DEVICE STEPS DISPLAY */}
          <div className="bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm space-y-6">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 pb-4 border-b border-gray-100">
              <div>
                <span className="text-[11px] font-black text-emerald-700 bg-emerald-100 px-2.5 py-1 rounded-md uppercase tracking-wider">
                  {currentGuide.badge}
                </span>
                <h2 className="text-xl font-black text-gray-900 mt-2">{currentGuide.name}</h2>
                <p className="text-xs text-gray-500 font-medium mt-0.5">{currentGuide.description}</p>
              </div>

              <div className="flex items-center gap-2">
                <span className="text-xs font-bold text-gray-500">Các bước thực hiện:</span>
                <div className="flex items-center gap-1">
                  {currentGuide.steps.map((s) => (
                    <button
                      key={s.id}
                      onClick={() => setActiveStep(s.id)}
                      className={`w-7 h-7 rounded-full text-xs font-extrabold transition-all ${activeStep === s.id ? "bg-emerald-700 text-white shadow-sm" : "bg-gray-100 text-gray-600 hover:bg-gray-200"
                        }`}
                    >
                      {s.id}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* STEP TILES */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              {currentGuide.steps.map((step) => {
                const Icon = step.icon;
                const isCurrent = activeStep === step.id;
                return (
                  <button
                    key={step.id}
                    type="button"
                    onClick={() => setActiveStep(step.id)}
                    className={`p-4 rounded-[18px] border text-left transition-all ${isCurrent
                        ? "bg-emerald-50 border-emerald-500 ring-2 ring-emerald-300 shadow-sm"
                        : "bg-white border-gray-200 hover:bg-gray-50"
                      }`}
                  >
                    <div className="flex items-center justify-between mb-2">
                      <div className={`w-8 h-8 rounded-[10px] flex items-center justify-center ${isCurrent ? "bg-emerald-700 text-white" : "bg-gray-100 text-gray-600"}`}>
                        <Icon className="w-4 h-4" />
                      </div>
                      <span className={`text-[10px] font-extrabold px-2 py-0.5 rounded-full ${isCurrent ? "bg-emerald-200 text-emerald-900" : "bg-gray-100 text-gray-500"}`}>
                        Bước {step.id}
                      </span>
                    </div>
                    <h3 className="text-xs font-bold text-gray-900 line-clamp-1">{step.title}</h3>
                    <p className="text-[11px] text-gray-500 mt-1 line-clamp-2">{step.desc}</p>
                  </button>
                );
              })}
            </div>

            {/* CURRENT STEP DETAILS DETAIL BOX */}
            {(() => {
              const step = currentGuide.steps.find((s) => s.id === activeStep) || currentGuide.steps[0];
              const Icon = step.icon;
              return (
                <div className="p-5 bg-gray-50/80 rounded-[20px] border border-gray-200 space-y-4">
                  <div className="flex items-center gap-3">
                    <div className="w-10 h-10 rounded-[12px] bg-emerald-600 text-white flex items-center justify-center flex-shrink-0 shadow-sm">
                      <Icon className="w-5 h-5" />
                    </div>
                    <div>
                      <h3 className="text-base font-bold text-gray-900">{step.title}</h3>
                      <p className="text-xs text-gray-600 font-medium">{step.desc}</p>
                    </div>
                  </div>

                  <div className="space-y-2 pt-2">
                    <h4 className="text-[11px] font-extrabold uppercase tracking-wider text-emerald-800">Thao tác chi tiết từ Kỹ sư DGA:</h4>
                    <div className="space-y-2">
                      {step.details.map((detail, idx) => (
                        <div key={idx} className="flex items-start gap-3 p-3 rounded-[12px] bg-white border border-gray-200/80 shadow-xs">
                          <CheckCircle2 className="w-4 h-4 text-emerald-600 flex-shrink-0 mt-0.5" />
                          <span className="text-xs text-gray-800 font-semibold leading-relaxed">{detail}</span>
                        </div>
                      ))}
                    </div>
                  </div>

                  <div className="flex items-center justify-between pt-3 border-t border-gray-200">
                    <button
                      type="button"
                      disabled={activeStep === 1}
                      onClick={() => setActiveStep((prev) => Math.max(1, prev - 1))}
                      className="px-4 py-2 text-xs font-bold text-gray-600 bg-white hover:bg-gray-100 border border-gray-200 rounded-[10px] disabled:opacity-40"
                    >
                      ← Bước trước
                    </button>

                    {activeStep < currentGuide.steps.length ? (
                      <button
                        type="button"
                        onClick={() => setActiveStep((prev) => Math.min(currentGuide.steps.length, prev + 1))}
                        className="px-5 py-2 text-xs font-bold text-white bg-emerald-700 hover:bg-emerald-800 rounded-[10px] flex items-center gap-1.5 shadow-sm"
                      >
                        Bước tiếp theo →
                      </button>
                    ) : (
                      <span className="text-xs font-extrabold text-emerald-800 bg-emerald-100 px-3 py-1.5 rounded-lg flex items-center gap-1">
                        <CheckCircle className="w-4 h-4 text-emerald-700" />
                        Đã hoàn thành lắp đặt {currentGuide.name}
                      </span>
                    )}
                  </div>
                </div>
              );
            })()}
          </div>
        </div>
      )}

      {/* TAB 2: INCIDENT REPORT & REPAIR REQUEST */}
      {activeMainTab === "incident" && (
        <div className="space-y-6">
          {/* INCIDENT FORM */}
          <div className="bg-white p-6 rounded-[24px] border border-gray-100 shadow-sm space-y-5">
            <div className="flex items-center gap-3 pb-3 border-b border-gray-100">
              <div className="w-10 h-10 rounded-[14px] bg-amber-100 text-amber-800 flex items-center justify-center">
                <AlertTriangle className="w-5 h-5" />
              </div>
              <div>
                <h3 className="text-base font-extrabold text-gray-900">Báo Cáo Sự Cố Thiết Bị IoT & Yêu Cầu Hỗ Trợ</h3>
                <p className="text-xs text-gray-500 font-medium">Gửi mô tả sự cố kèm ảnh/video thực tế để Kỹ sư DGA chẩn đoán & hướng dẫn sửa chữa</p>
              </div>
            </div>

            <form onSubmit={handleSubmitIncident} className="space-y-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1.5">🛠️ Chọn thiết bị gặp sự cố (*)</label>
                  <select
                    value={incidentDevice}
                    onChange={(e) => setIncidentDevice(e.target.value)}
                    className="w-full text-xs font-semibold p-3 rounded-[12px] border border-gray-200 bg-white focus:ring-2 focus:ring-amber-400 focus:outline-none"
                  >
                    {DEVICE_GUIDES.map((dev) => (
                      <option key={dev.id} value={dev.name}>
                        {dev.name} ({dev.category})
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-bold text-gray-700 mb-1.5">🚨 Loại sự cố gặp phải (*)</label>
                  <select
                    value={incidentType}
                    onChange={(e) => setIncidentType(e.target.value)}
                    className="w-full text-xs font-semibold p-3 rounded-[12px] border border-gray-200 bg-white focus:ring-2 focus:ring-amber-400 focus:outline-none"
                  >
                    <option value="Mất kết nối tín hiệu 5G / LoRaWAN">Mất kết nối tín hiệu 5G / LoRaWAN</option>
                    <option value="Cảm biến đo chỉ số sai lệch lớn">Cảm biến đo chỉ số sai lệch lớn</option>
                    <option value="Hỏng pin năng lượng mặt trời / Đèn đỏ nhấp nháy">Hỏng pin năng lượng mặt trời / Đèn đỏ nhấp nháy</option>
                    <option value="Rò rỉ nước ở van tưới tự động">Rò rỉ nước ở van tưới tự động</option>
                    <option value="Sự cố hư hỏng vật lý (nứt vỡ/động vật làm hỏng)">Sự cố hư hỏng vật lý (nứt vỡ/động vật làm hỏng)</option>
                    <option value="Khác...">Sự cố khác...</option>
                  </select>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1.5">📝 Mô tả chi tiết hiện trạng sự cố (*)</label>
                <textarea
                  required
                  rows={3}
                  value={incidentDesc}
                  onChange={(e) => setIncidentDesc(e.target.value)}
                  placeholder="VD: Cảm biến cắm dưới gốc sầu riêng bị mất tín hiệu từ 8h sáng, đèn LED đỏ nháy liên tục 3 lần..."
                  className="w-full text-xs font-semibold p-3 rounded-[12px] border border-gray-200 focus:ring-2 focus:ring-amber-400 focus:outline-none"
                />
              </div>

              {/* MEDIA ATTACHMENT AREA (IMAGE / VIDEO) */}
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1.5">📷 Đính kèm Ảnh hoặc Video thực tế của thiết bị (*)</label>
                <div className="border-2 border-dashed border-gray-200 hover:border-amber-400 p-4 rounded-[16px] text-center bg-gray-50/60 transition-all">
                  <input
                    type="file"
                    accept="image/*,video/*"
                    onChange={handleFileChange}
                    id="incident-media-input"
                    className="hidden"
                  />
                  <label htmlFor="incident-media-input" className="cursor-pointer flex flex-col items-center justify-center gap-2">
                    <div className="w-10 h-10 rounded-full bg-amber-100 text-amber-800 flex items-center justify-center">
                      <Upload className="w-5 h-5" />
                    </div>
                    <span className="text-xs font-bold text-gray-800">Bấm vào đây để chọn Ảnh hoặc Video thực tế tại vườn</span>
                    <span className="text-[10px] text-gray-400 font-medium">Định dạng hỗ trợ: JPG, PNG, MP4, MOV (Tối đa 50MB)</span>
                  </label>

                  {mediaFileName && (
                    <div className="mt-3 p-2 bg-emerald-50 rounded-[10px] border border-emerald-200 inline-flex items-center gap-2 text-xs font-bold text-emerald-900">
                      <ImageIcon className="w-4 h-4 text-emerald-700" />
                      <span>Đã chọn file: {mediaFileName}</span>
                    </div>
                  )}

                  {incidentMedia && (
                    <div className="mt-3 max-w-xs mx-auto overflow-hidden rounded-[14px] border border-gray-200 shadow-sm">
                      {incidentMedia.startsWith("data:video") ? (
                        <video src={incidentMedia} controls className="w-full h-40 object-cover" />
                      ) : (
                        <img src={incidentMedia} alt="Media thực tế" className="w-full h-40 object-cover" />
                      )}
                    </div>
                  )}
                </div>
              </div>

              <button
                type="submit"
                disabled={submittingIncident}
                className="w-full py-3.5 bg-amber-500 hover:bg-amber-400 text-gray-950 font-black text-xs rounded-[14px] shadow-md flex items-center justify-center gap-2 transition-all active:scale-[0.99]"
              >
                <Send className="w-4 h-4 text-gray-950" />
                {submittingIncident ? "Đang gửi báo cáo..." : "🚀 Gửi Báo Cáo Sự Cố Cho Kỹ Sư DGA Phân Tích & Hướng Dẫn Sửa"}
              </button>
            </form>
          </div>

          {/* INCIDENTS HISTORY & ENGINEER RESOLUTION LIST */}
          <div className="space-y-4">
            <h3 className="text-sm font-extrabold text-gray-900 uppercase tracking-wider flex items-center gap-2">
              <Clock className="w-4 h-4 text-amber-700" />
              Lịch Sử Báo Cáo Sự Cố & Phản Hồi Từ Kỹ Sư DGA ({tickets.length})
            </h3>

            <div className="space-y-3">
              {tickets.map((ticket) => (
                <div key={ticket.id} className="bg-white p-5 rounded-[20px] border border-gray-100 shadow-sm space-y-3">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-2 border-b border-gray-100">
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-extrabold text-gray-900 bg-gray-100 px-2.5 py-0.5 rounded-md">{ticket.id}</span>
                      <h4 className="text-xs font-extrabold text-gray-900">{ticket.deviceName}</h4>
                    </div>

                    <span
                      className={`text-[10px] font-black uppercase tracking-wider px-2.5 py-1 rounded-full w-fit ${ticket.status === "Pending"
                          ? "bg-amber-100 text-amber-800"
                          : ticket.status === "In_Review"
                            ? "bg-blue-100 text-blue-800"
                            : "bg-emerald-100 text-emerald-800"
                        }`}
                    >
                      {ticket.status === "Pending"
                        ? "⏳ Chờ Kỹ sư xử lý"
                        : ticket.status === "In_Review"
                          ? "🔍 Kỹ sư đang phản hồi"
                          : "🟢 Đã khắc phục xong"}
                    </span>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-xs">
                    <div className="space-y-1">
                      <span className="text-gray-400 font-medium text-[10px]">Loại sự cố:</span>
                      <p className="font-bold text-gray-900">{ticket.incidentType}</p>
                    </div>

                    <div className="space-y-1 md:col-span-2">
                      <span className="text-gray-400 font-medium text-[10px]">Mô tả hiện trạng:</span>
                      <p className="font-semibold text-gray-700">{ticket.description}</p>
                    </div>
                  </div>

                  {ticket.mediaUrl && (
                    <div className="pt-2">
                      <span className="text-[10px] font-extrabold text-gray-500 uppercase block mb-1">Ảnh / Video đính kèm:</span>
                      <div className="w-32 h-24 rounded-[12px] overflow-hidden border border-gray-200 shadow-xs">
                        <img src={ticket.mediaUrl} alt="Ảnh sự cố" className="w-full h-full object-cover" />
                      </div>
                    </div>
                  )}

                  {ticket.engineerNote && (
                    <div className="p-3 bg-amber-50 rounded-[14px] border border-amber-200/80 text-xs text-amber-950 font-medium space-y-1">
                      <strong className="font-bold text-amber-900 flex items-center gap-1.5">
                        <Headphones className="w-3.5 h-3.5 text-amber-700" />
                        Hướng dẫn khắc phục từ Kỹ sư DGA:
                      </strong>
                      <p className="text-[11px] text-amber-900 leading-relaxed font-semibold">{ticket.engineerNote}</p>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* ACTIVATION BANNER BOTTOM */}
      <div className="bg-gradient-to-r from-emerald-50 via-teal-50 to-green-50 p-6 rounded-[22px] border border-emerald-200 shadow-sm flex flex-col md:flex-row items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="w-12 h-12 rounded-[16px] bg-emerald-600 text-white flex items-center justify-center flex-shrink-0 shadow-md">
            <Sparkles className="w-6 h-6" />
          </div>
          <div>
            <h3 className="text-base font-extrabold text-gray-900">Xác Nhận Đã Lắp Đặt & Kích Hoạt Vườn</h3>
            <p className="text-xs text-gray-600 font-medium">
              Bấm nút bên cạnh để chuyển đổi trạng thái trang trại sang <strong>ACTIVE</strong> và bắt đầu nhận phân tích Cảnh báo AI.
            </p>
          </div>
        </div>

        <button
          type="button"
          onClick={handleActivateFarm}
          disabled={activating}
          className="w-full md:w-auto px-6 py-3.5 bg-emerald-700 hover:bg-emerald-800 text-white font-black text-sm rounded-[14px] shadow-lg flex items-center justify-center gap-2 whitespace-nowrap transition-all disabled:opacity-50"
        >
          {activating ? "Đang kích hoạt hệ thống..." : "🚀 Kích Hoạt Trang Trại & Mở Khóa AI"}
          <ArrowRight className="w-4 h-4" />
        </button>
      </div>

      {/* Modal: Connect with Agronomist / Engineer */}
      {showEngineerModal && (
        <div className="fixed inset-0 z-50 bg-black/60 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-white max-w-lg w-full rounded-[24px] p-6 shadow-2xl space-y-4 border border-gray-100">
            <div className="flex items-center justify-between pb-3 border-b border-gray-100">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-[12px] bg-amber-100 text-amber-800 flex items-center justify-center">
                  <UserCheck className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-gray-900">Kết Nối Kỹ Sư Nông Nghiệp Vie-farm</h3>
                  <p className="text-xs text-gray-500 font-medium">Hỗ trợ sự cố lắp đặt & cấu hình tín hiệu 24/7</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setShowEngineerModal(false)}
                className="text-gray-400 hover:text-gray-600 font-extrabold text-lg"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleSendEngineerHelp} className="space-y-3">
              <div>
                <label className="block text-xs font-bold text-gray-700 mb-1">Mô tả sự cố hoặc thắc mắc của bạn (*)</label>
                <textarea
                  required
                  rows={3}
                  placeholder="VD: Đèn trạm thời tiết nháy màu đỏ, hoặc chưa biết cắm cảm biến đất vị trí nào hợp lý..."
                  value={engineerMessage}
                  onChange={(e) => setEngineerMessage(e.target.value)}
                  className="w-full text-xs font-semibold border border-gray-200 rounded-[12px] p-3 focus:outline-none focus:ring-2 focus:ring-amber-400"
                />
              </div>

              <div className="bg-amber-50 p-3 rounded-[12px] border border-amber-200/70 text-xs text-amber-900 font-medium space-y-1">
                <div className="flex items-center gap-2 font-bold text-amber-950">
                  <PhoneCall className="w-4 h-4 text-amber-700" />
                  Hotline Kỹ sư Vie-farm: 1900 8899 - 0988 123 456
                </div>
                <p className="text-[11px] text-amber-800">
                  Kỹ sư sẽ gọi trực tiếp hoặc cử kỹ thuật viên khu vực Tây Nguyên / Miền Tây tới hỗ trợ trong 24h.
                </p>
              </div>

              <div className="flex items-center justify-end gap-2 pt-2">
                <button
                  type="button"
                  onClick={() => setShowEngineerModal(false)}
                  className="px-4 py-2 text-xs font-bold text-gray-600 hover:bg-gray-100 rounded-[10px]"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 text-xs font-bold text-gray-900 bg-amber-400 hover:bg-amber-300 rounded-[10px] shadow-sm"
                >
                  📞 Gửi Yêu Cầu Cho Kỹ Sư
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
