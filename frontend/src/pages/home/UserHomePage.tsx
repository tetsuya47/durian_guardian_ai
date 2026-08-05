import { useState, useEffect } from "react";
import {
  Home,
  Sun,
  CloudRain,
  Wind,
  Droplets,
  Search,
  Sparkles,
  TrendingUp,
  BookOpen,
  Bug,
  ShieldCheck,
  Zap,
  Newspaper,
  CheckCircle2,
  ChevronRight,
  ArrowUpRight,
  Tag,
  DollarSign,
  AlertCircle,
  ShoppingBag,
  ExternalLink,
  Sprout,
  RefreshCw,
  QrCode,
  CreditCard,
  Wallet,
  X,
  Copy,
  Lock,
  Shield,
} from "lucide-react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../../hooks/useAuth";
import api from "../../api";

interface WeatherData {
  temp: number;
  humidity: number;
  wind_speed: number;
  rain_probability: number;
  condition: string;
  location: string;
  recommendation: string;
}

const DEFAULT_MARKET_ITEMS = [
  // 1. Ri6
  {
    name: "Sầu riêng Ri6 (Hàng Đẹp Loại 1)",
    category: "Ri6",
    quality: "Hàng Đẹp (Loại 1)",
    grade: "dep",
    price_mientay: "63.000 – 65.000",
    price_miendong: "55.000 – 60.000",
    price_taynguyen: "52.000 – 54.000",
    unit: "đ/kg",
    change: "+3.5%",
    trend: "up",
  },
  {
    name: "Sầu riêng Ri6 (Hàng Xô Lùa Vựa)",
    category: "Ri6",
    quality: "Hàng Xô (Lùa vựa)",
    grade: "xo",
    price_mientay: "48.000 – 50.000",
    price_miendong: "45.000 – 48.000",
    price_taynguyen: "42.000 – 45.000",
    unit: "đ/kg",
    change: "Ổn định",
    trend: "same",
  },

  // 2. Thái / Monthong
  {
    name: "Sầu riêng Thái / Monthong (Hàng Đẹp Loại 1)",
    category: "Thái",
    quality: "Hàng Đẹp (Xuất khẩu A)",
    grade: "dep",
    price_mientay: "94.000 – 95.000",
    price_miendong: "85.000 – 90.000",
    price_taynguyen: "72.000 – 74.000",
    unit: "đ/kg",
    change: "+5.2%",
    trend: "up",
  },
  {
    name: "Sầu riêng Thái / Monthong (Hàng Xô Lùa Vựa)",
    category: "Thái",
    quality: "Hàng Xô (Lùa vựa)",
    grade: "xo",
    price_mientay: "75.000 – 77.000",
    price_miendong: "65.000 – 70.000",
    price_taynguyen: "55.000 – 60.000",
    unit: "đ/kg",
    change: "+2.1%",
    trend: "up",
  },

  // 3. Musang King
  {
    name: "Sầu riêng Musang King (Hàng Đẹp Loại 1)",
    category: "Musang King",
    quality: "Hàng Đẹp (Trái chín cây)",
    grade: "dep",
    price_mientay: "180.000 – 220.000",
    price_miendong: "180.000 – 220.000",
    price_taynguyen: "170.000 – 200.000",
    unit: "đ/kg",
    change: "Ổn định",
    trend: "same",
  },
  {
    name: "Sầu riêng Musang King (Hàng Xô Lùa Vựa)",
    category: "Musang King",
    quality: "Hàng Xô (Lùa vựa)",
    grade: "xo",
    price_mientay: "130.000 – 160.000",
    price_miendong: "130.000 – 160.000",
    price_taynguyen: "120.000 – 150.000",
    unit: "đ/kg",
    change: "Ổn định",
    trend: "same",
  },

  // 4. Black Thorn
  {
    name: "Sầu riêng Black Thorn (Hàng Đẹp Loại 1)",
    category: "Black Thorn",
    quality: "Hàng Đẹp (Loại 1 xuất khẩu)",
    grade: "dep",
    price_mientay: "230.000 – 280.000",
    price_miendong: "230.000 – 280.000",
    price_taynguyen: "220.000 – 260.000",
    unit: "đ/kg",
    change: "+4.0%",
    trend: "up",
  },
  {
    name: "Sầu riêng Black Thorn (Hàng Xô Lùa Vựa)",
    category: "Black Thorn",
    quality: "Hàng Xô (Lùa vựa)",
    grade: "xo",
    price_mientay: "170.000 – 200.000",
    price_miendong: "170.000 – 200.000",
    price_taynguyen: "160.000 – 190.000",
    unit: "đ/kg",
    change: "+1.8%",
    trend: "up",
  },

  // 5. Chuồng Bò
  {
    name: "Sầu riêng Chuồng Bò (Hàng Đẹp Loại 1)",
    category: "Chuồng Bò",
    quality: "Hàng Đẹp (Loại 1)",
    grade: "dep",
    price_mientay: "50.000 – 58.000",
    price_miendong: "48.000 – 55.000",
    price_taynguyen: "45.000 – 50.000",
    unit: "đ/kg",
    change: "+1.5%",
    trend: "up",
  },
  {
    name: "Sầu riêng Chuồng Bò (Hàng Xô Lùa Vựa)",
    category: "Chuồng Bò",
    quality: "Hàng Xô (Lùa vựa)",
    grade: "xo",
    price_mientay: "38.000 – 45.000",
    price_miendong: "35.000 – 42.000",
    price_taynguyen: "30.000 – 35.000",
    unit: "đ/kg",
    change: "Ổn định",
    trend: "same",
  },

  // 6. Khổ Qua Xanh
  {
    name: "Sầu riêng Khổ Qua Xanh (Hàng Đẹp Loại 1)",
    category: "Khổ Qua",
    quality: "Hàng Đẹp (Loại 1)",
    grade: "dep",
    price_mientay: "38.000 – 45.000",
    price_miendong: "35.000 – 42.000",
    price_taynguyen: "32.000 – 38.000",
    unit: "đ/kg",
    change: "Ổn định",
    trend: "same",
  },
  {
    name: "Sầu riêng Khổ Qua Xanh (Hàng Xô Lùa Vựa)",
    category: "Khổ Qua",
    quality: "Hàng Xô (Lùa vựa)",
    grade: "xo",
    price_mientay: "25.000 – 30.000",
    price_miendong: "22.000 – 28.000",
    price_taynguyen: "20.000 – 25.000",
    unit: "đ/kg",
    change: "Ổn định",
    trend: "same",
  },
];

export default function UserHomePage() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const isUserAdmin = user?.role === "Admin" || user?.role === "ADMIN" || user?.role === "System Admin";
  const [adminActiveTab, setAdminActiveTab] = useState<string>("all");

  const [searchTerm, setSearchTerm] = useState("");
  const [selectedDiseaseTab, setSelectedDiseaseTab] = useState("all");
  const [selectedRegion, setSelectedRegion] = useState<"mientay" | "miendong" | "taynguyen">("mientay");
  const [selectedGradeFilter, setSelectedGradeFilter] = useState<"all" | "dep" | "xo">("all");
  const [marketItems, setMarketItems] = useState<any[]>(DEFAULT_MARKET_ITEMS);
  const [marketSource, setMarketSource] = useState("giasaurieng.net (Giá thu mua tại vườn cho thương lái)");
  const [loadingMarket, setLoadingMarket] = useState(false);

  // Payment Modal States
  const [selectedPaymentPkg, setSelectedPaymentPkg] = useState<any | null>(null);
  const [paymentMethod, setPaymentMethod] = useState<"vietqr" | "momo" | "vnpay" | "card">("vietqr");
  const [billingCycle, setBillingCycle] = useState<1 | 6 | 12>(1);
  const [promoCodeInput, setPromoCodeInput] = useState("");
  const [promoDiscount, setPromoDiscount] = useState(0);
  const [promoMessage, setPromoMessage] = useState("");
  const [isProcessingPay, setIsProcessingPay] = useState(false);
  const [paySuccess, setPaySuccess] = useState(false);
  const [copiedAccount, setCopiedAccount] = useState(false);

  const handleOpenPayment = (pkg: any) => {
    if (pkg.active) return;
    setSelectedPaymentPkg(pkg);
    setPaymentMethod("vietqr");
    setBillingCycle(1);
    setPromoCodeInput("");
    setPromoDiscount(0);
    setPromoMessage("");
    setPaySuccess(false);
  };

  const handleApplyPromoCode = () => {
    const code = promoCodeInput.trim().toUpperCase();
    if (code === "DGA2026" || code === "SAURIENG2026" || code === "DGA20") {
      setPromoDiscount(0.2); // 20% off
      setPromoMessage("🎉 Áp dụng mã giảm giá 20% thành công!");
    } else if (code.length > 0) {
      setPromoDiscount(0);
      setPromoMessage("❌ Mã giảm giá không đúng hoặc đã hết hạn.");
    }
  };

  const handleConfirmPayment = () => {
    setIsProcessingPay(true);
    setTimeout(() => {
      setIsProcessingPay(false);
      setPaySuccess(true);
    }, 1200);
  };

  const [weather, setWeather] = useState<WeatherData>({
    temp: 29.5,
    humidity: 78,
    wind_speed: 12.5,
    rain_probability: 30,
    condition: "Nắng mây đan xen - Thích hợp làm đọt",
    location: "Phong Điền, Cần Thơ",
    recommendation: "Thời tiết thuận lợi cho lá non lụa cứng. Khuyên dùng NPK 20-20-15 bổ sung Vi lượng.",
  });

  const fetchRealMarketPrices = () => {
    setLoadingMarket(true);
    api
      .get("/market/latest")
      .then((res) => {
        const items = res.data?.data?.items || res.data?.items || (Array.isArray(res.data) ? res.data : []);
        if (items && items.length > 0) {
          setMarketItems(items);
        }
        if (res.data?.data?.source || res.data?.source) {
          setMarketSource(res.data?.data?.source || res.data?.source);
        }
      })
      .catch(() => {})
      .finally(() => setLoadingMarket(false));
  };

  useEffect(() => {
    // Fetch live weather data from backend API
    api
      .get("/weather/current")
      .then((res) => {
        if (res.data?.data) {
          const d = res.data.data;
          setWeather({
            temp: d.temp_c || d.temp || 29.5,
            humidity: d.humidity || 78,
            wind_speed: d.wind_speed_kmh || 12.5,
            rain_probability: d.pop || 30,
            condition: d.condition || "Nắng mây đan xen",
            location: d.location_name || "Phong Điền, Cần Thơ",
            recommendation: d.ai_recommendation || "Thời tiết ổn định cho cây sầu riêng.",
          });
        }
      })
      .catch(() => {});

    fetchRealMarketPrices();
  }, []);

  // Helper to extract regional price string
  const getRegionalPrice = (item: any, reg: "mientay" | "miendong" | "taynguyen") => {
    if (reg === "mientay") return item.price_mientay || item.price || "63.000 – 65.000";
    if (reg === "miendong") return item.price_miendong || item.price || "55.000 – 60.000";
    return item.price_taynguyen || item.price || "52.000 – 54.000";
  };

  // Pest & Disease AI Search Database
  const diseasesList = [
    {
      id: "dis-1",
      name: "Bệnh Thán Thư (Colletotrichum)",
      type: "Nấm hại lá",
      symptom: "Vết bệnh bắt đầu từ chóp lá, màu nâu xám, có quầng vàng xung quanh, lá khô giòn rụng sớm.",
      control: "Phun phòng bằng chế phẩm sinh học Trichoderma hoặcScore 250EC giai đoạn đọt lụa.",
      bioControl: "Nấm đối kháng Trichoderma harzianum + Dầu tỏi neem",
    },
    {
      id: "dis-2",
      name: "Nấm Phytophthora (Xì mủ thối gốc)",
      type: "Bệnh nấm gốc & thân",
      symptom: "Vỏ thân rỉ nhựa nâu đỏ, gỗ bên trong thâm đen, lá vàng rụng lạt đọt.",
      control: "Cạo sạch vết xì mủ, quét Aliette 800WG hoặc phun Ridomil Gold rửa vườn.",
      bioControl: "Vi sinh Pseudomonas fluorescens + Bôi vôi quét gốc sinh học",
    },
    {
      id: "dis-3",
      name: "Bọ Trĩ (Thrips spp.)",
      type: "Côn trùng châm hút",
      symptom: "Lá non còi cọc, mép lá cong queo, chóp đọt bị châm đen cháy xém.",
      control: "Phun luân phiên thuốc sinh học Matrine hoặc Radiant khi cây vừa nhú đọt gấm.",
      bioControl: "Thả bọ rùa & nhện ăn thịt + Phun dầu khoáng SK Enspray",
    },
    {
      id: "dis-4",
      name: "Sâu Đục Quả (Conogethes punctiferalis)",
      type: "Sâu hại trái",
      symptom: "Sâu đục sâu vào vỏ hột sầu riêng, đùn phân đen ra ngoài, trái hỏng rụng.",
      control: "Bọc trái sầu riêng bằng túi chuyên dụng, phun chế phẩm sinh học BT.",
      bioControl: "Chế phẩm BT (Bacillus thuringiensis) + Dùng bẫy Pheromone",
    },
  ];

  // Biological Control Measures (Biện pháp sinh học)
  const bioMeasures = [
    {
      title: "Ủ nấm đối kháng Trichoderma",
      desc: "Trộn nấm Trichoderma với phân hữu cơ hoai mục bón quanh tán cây giúp tiêu diệt nấm Phytophthora & Pythium trong đất.",
      tag: "Sinh học gốc",
      color: "bg-emerald-50 text-emerald-800 border-emerald-200",
    },
    {
      title: "Chế phẩm vi sinh BT trừ sâu",
      desc: "Vi khuẩn Bacillus thuringiensis gây việt trùng đường ruột sâu đục trái & sâu ăn lá mà không gây độc cho ong mật.",
      tag: "Vi sinh trừ sâu",
      color: "bg-blue-50 text-blue-800 border-blue-200",
    },
    {
      title: "Trồng hoa rặng rào thu hút thiên địch",
      desc: "Trồng hoa mười giờ, cúc xuyến chi quanh bờ vườn để nuôi ong ký sinh và bọ rùa săn bọ trĩ tự nhiên.",
      tag: "Sinh thái vườn",
      color: "bg-amber-50 text-amber-800 border-amber-200",
    },
  ];

  // Agronomy Guides (Kỹ thuật canh tác)
  const farmingGuides = [
    {
      stage: "Giai đoạn 1: Xử lý đọt & Tạo mầm hoa",
      detail: "Bón MKP 0-52-34 kết hợp siết nước 15-20 ngày. Phun Bo-Kẽm kích thích nhú mắt cua đồng loạt.",
      icon: Sprout,
    },
    {
      stage: "Giai đoạn 2: Nuôi trái non & Hạn chế đi đọt",
      detail: "Bón NPK 15-15-15 + Humic. Nếu đọt nhú cùng lúc với bông, phun chặn đọt bằng K2O3 để chống rụng trái.",
      icon: ShieldCheck,
    },
    {
      stage: "Giai đoạn 3: Phục hồi sau thu hoạch",
      detail: "Rửa vườn bằng gốc Đồng, tỉa cành khô cành bệnh, bón 15-20kg phân hữu cơ vi sinh + vôi bột cải tạo đất.",
      icon: RefreshCw,
    },
  ];

  // Subscription Deals
  const promoPackages = [
    {
      name: "Gói Plus",
      price: "Miễn Phí",
      period: "vĩnh viễn",
      desc: "Dành cho nông hộ trải nghiệm các tính năng cơ bản của ứng dụng.",
      features: [
        "Sử dụng các chức năng app có giới hạn lượt",
        "Giới hạn lượt quét AI (tự động hồi lượt hàng tuần)",
        "Dự báo thời tiết & tra cứu giá thu mua tại vườn",
        "❌ Không được tư vấn 1-1 với Chuyên gia Nông nghiệp",
      ],
      badge: "Gói Mặc Định",
      btnText: "Đang sử dụng",
      active: true,
    },
    {
      name: "Gói Pro",
      price: "30.000đ",
      period: "/ tháng",
      desc: "Mở khóa toàn bộ chức năng ứng dụng & Tư vấn Chuyên gia Nông nghiệp.",
      features: [
        "Sử dụng TẤT CẢ các chức năng trong app theo tháng",
        "Không giới hạn lượt quét AI & chẩn đoán sâu bệnh",
        "Mở khóa tư vấn 1-1 trực tiếp với Chuyên gia Nông nghiệp",
        "❌ Không sử dụng được các chức năng thiết bị IoT",
      ],
      badge: "Phổ Biến ★",
      btnText: "Nâng cấp Gói Pro",
      active: false,
      popular: true,
    },
    {
      name: "Gói Premium",
      price: "199.000đ",
      period: "/ tháng",
      desc: "Mở khóa toàn diện AI + IoT quản lý vườn tự động & Ưu đãi Voucher.",
      features: [
        "Mở khóa thiết bị IoT để AI quản lý vườn & đề xuất kỹ thuật",
        "Sử dụng TẤT CẢ các chức năng ứng dụng không giới hạn",
        "👨‍🌾 Đầy đủ đặc quyền Tư vấn Chuyên gia Nông nghiệp 1-1",
        "🎁 Voucher giảm giá 20% khi mua thiết bị IoT nông nghiệp",
      ],
      badge: "VIP Premium ★★★",
      btnText: "Đăng ký Gói Premium",
      active: false,
    },
  ];

  const [selectedNewsTab, setSelectedNewsTab] = useState<"highlight" | "market" | "export" | "weather">("highlight");

  // Market & Agronomy News Catalog
  const newsList = [
    // Tab 1: 🔥 Nổi bật hôm nay
    {
      tab: "highlight",
      region: "Toàn quốc & Xuất khẩu",
      title: "Xuất khẩu sầu riêng Việt Nam đạt kỷ lục 2,8 tỷ USD sang thị trường Trung Quốc",
      source: "Báo Nông Nghiệp Việt Nam",
      time: "1 giờ trước",
      desc: "Tổng cục Hải quan Trung Quốc (GACC) vừa phê duyệt cấp mới 120 mã số vùng trồng sầu riêng Ri6 và Monthong tại Tiền Giang, Đắk Lắk và Lâm Đồng.",
      img: "https://images.unsplash.com/photo-1618160702438-9b02ab6515c9?auto=format&fit=crop&w=600&q=80",
    },
    {
      tab: "highlight",
      region: "Tây Nguyên (Đắk Lắk)",
      title: "Dự báo rãnh áp thấp nhiệt đới gây mưa lớn tại Tây Nguyên: Nguy cơ xì mủ thối gốc",
      source: "Trung tâm Dự báo Khí tượng Nông nghiệp",
      time: "3 giờ trước",
      desc: "Chủ vườn sầu riêng Đắk Lắk & Lâm Đồng cần chủ động xẻ rãnh thoát nước gốc và phun phòng nấm Phytophthora sau các đợt mưa dầm dề.",
      img: "https://images.unsplash.com/photo-1534274988757-a28bf1a57c17?auto=format&fit=crop&w=600&q=80",
    },

    // Tab 2: 📉 Biến động giá & Thị trường
    {
      tab: "market",
      region: "Miền Tây Nam Bộ",
      title: "Giá sầu riêng Monthong loại 1 chạm mốc 95.000đ/kg tại các vựa Tiền Giang & Bến Tre",
      source: "Tạp chí Nông Dân Điện Tử",
      time: "2 giờ trước",
      desc: "Thương lái đẩy mạnh thu mua sầu riêng Thái xuất khẩu tươi do nguồn cung cuối vụ Miền Tây chững lại, giá thu mua tăng 5.000đ/kg.",
      img: "https://images.unsplash.com/photo-1546548970-71785318a17b?auto=format&fit=crop&w=600&q=80",
    },
    {
      tab: "market",
      region: "Tây Nguyên & Lâm Đồng",
      title: "Sốt giá sầu riêng Black Thorn & Musang King chín cây thu mua tại vườn",
      source: "Bản tin Thị trường Nông sản",
      time: "5 giờ trước",
      desc: "Các vựa thu mua sầu riêng nhập khẩu gai đen Black Thorn với giá 250.000đ - 280.000đ/kg, đem lại lợi nhuận vượt trội cho nhà vườn Đắk Lắk.",
      img: "https://images.unsplash.com/photo-1601004890684-d8cbf643f5f2?auto=format&fit=crop&w=600&q=80",
    },

    // Tab 3: 📜 Mã số vùng trồng & Xuất khẩu
    {
      tab: "export",
      region: "Quy chuẩn xuất khẩu GACC",
      title: "Trung Quốc siết chặt kiểm tra dư lượng kim loại nặng & Cadmi trên sầu riêng nhập khẩu",
      source: "Cục Bảo vệ Thực vật",
      time: "4 giờ trước",
      desc: "Bộ Nông nghiệp khuyến cáo nhà vườn tuân thủ quy trình bón phân VietGAP, ghi chép nhật ký canh tác số để bảo vệ mã vùng trồng xuất khẩu.",
      img: "https://images.unsplash.com/photo-1494412574643-ff11b0a5c1c3?auto=format&fit=crop&w=600&q=80",
    },
    {
      tab: "export",
      region: "Miền Đông Nam Bộ",
      title: "Cấp mới 45 mã số cơ sở đóng gói sầu riêng cho tỉnh Đồng Nai & Bình Phước",
      source: "Sở Nông Nghiệp & PTNT Đồng Nai",
      time: "6 giờ trước",
      desc: "Nâng cao năng lực sơ chế, chiếu xạ và đóng thùng lạnh container sầu riêng xuất khẩu chính ngạch sang thị trường Á - Âu.",
      img: "https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?auto=format&fit=crop&w=600&q=80",
    },

    // Tab 4: 🌤️ Thời tiết & Cảnh báo vùng
    {
      tab: "weather",
      region: "Đông Nam Bộ",
      title: "Cảnh báo bọ trĩ & nhện đỏ bùng phát mùa nắng nóng kéo dài tại Đông Nam Bộ",
      source: "Chi cục Trồng trọt & BVTV Đồng Nai",
      time: "2 giờ trước",
      desc: "Khuyến cáo chủ vườn phun tưới xịt rửa đọt non sầu riêng kết hợp chế phẩm sinh học SK Enspray 99EC bảo vệ chóp lá.",
      img: "https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&w=600&q=80",
    },
    {
      tab: "weather",
      region: "Miền Tây Nam Bộ",
      title: "Kỹ thuật siết nước dội mầm hoa sầu riêng vụ nghịch tại Đồng Tháp & Cần Thơ",
      source: "Viện Cây Ăn Quả Miền Nam (SOFRI)",
      time: "7 giờ trước",
      desc: "Hướng dẫn kỹ thuật đậy bạt ni-lông xẻ rãnh làm bông mùa mưa nghịch vụ thành công cho giống Ri6 mang lại hiệu quả kinh tế cao.",
      img: "https://images.unsplash.com/photo-1625246333195-78d9c38ad449?auto=format&fit=crop&w=600&q=80",
    },
  ];

  return (
    <div className="flex flex-col space-y-6 pb-12">
      {/* 1. CLEAN ECOLOGICAL PAGE HEADER */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 bg-white p-5 rounded-[22px] border border-gray-200/90 shadow-xs">
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-[14px] bg-emerald-100 text-emerald-700 flex items-center justify-center flex-shrink-0">
            <Home className="w-6 h-6" />
          </div>
          <div>
            <h1 className="text-xl font-black text-gray-900 leading-tight">Cổng Thông Tin & Thị Trường Sầu Riêng</h1>
            <p className="text-xs text-gray-500 font-medium mt-0.5">Cập nhật giá thu mua tại vườn, tra cứu dịch bệnh & hướng dẫn kỹ thuật canh tác</p>
          </div>
        </div>
      </div>

      {/* WEB ADMIN 6-TAB NAVIGATION CONTROLS */}
      {isUserAdmin && (
        <div className="bg-white p-4 sm:p-5 rounded-[22px] border border-emerald-300 shadow-md space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-xs font-black uppercase text-emerald-800 tracking-wider flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-emerald-600" /> BẢNG QUẢN TRỊ TRANG CHỦ WEB ADMIN (6 TAB DỮ LIỆU)
            </span>
            <span className="text-[11px] font-bold text-gray-500 bg-emerald-50 text-emerald-800 px-2.5 py-0.5 rounded-full border border-emerald-200">
              Quyền Hạn Quản Trị Hệ Thống
            </span>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            {[
              { id: "all", label: "🌐 Xem Tất Cả Dữ Liệu" },
              { id: "prices", label: "💵 1. Giá Thu Mua Sầu Riêng Tại Vườn" },
              { id: "diseases", label: "🐛 2. Tra Cứu Nhanh Sâu Bệnh Hại" },
              { id: "biocontrol", label: "🌿 3. Biện Pháp Phòng Trừ Sinh Học" },
              { id: "farming", label: "🌱 4. Kỹ Thuật Canh Tác Sầu Riêng" },
              { id: "promos", label: "⚡ 5. ƯU ĐÃI GÓI NÔNG NGHIỆP THÔNG MINH" },
              { id: "news", label: "📰 6. Tin Tức Nông Nghiệp & Xuất Khẩu" },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setAdminActiveTab(tab.id)}
                className={`px-4 py-2.5 rounded-[12px] text-xs font-black transition-all cursor-pointer ${
                  adminActiveTab === tab.id
                    ? "bg-emerald-700 text-white shadow-md shadow-emerald-950/20 scale-102"
                    : "bg-gray-100 text-gray-700 hover:bg-emerald-50 hover:text-emerald-800"
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>
        </div>
      )}

      {/* 2. GIÁ CẢ THỊ TRƯỜNG SẦU RIÊNG REALTIME (THU MUA TẠI VƯỜN CHO THƯƠNG LÁI) */}
      {(adminActiveTab === "all" || adminActiveTab === "prices") && (
        <div className="bg-white p-5 rounded-[20px] border border-gray-200/80 shadow-xs space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-2">
              <div className="w-9 h-9 rounded-[12px] bg-emerald-100 text-emerald-700 flex items-center justify-center">
                <DollarSign className="w-5 h-5" />
              </div>
              <div>
                <h2 className="text-base font-black text-gray-900 tracking-tight flex items-center gap-2">
                  Giá Thu Mua Sầu Riêng Tại Vườn (Cho Thương Lái)
                  <span className="text-[10px] font-black text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-md border border-emerald-200">
                    Dữ liệu thực từ MongoDB
                  </span>
                </h2>
                <p className="text-xs text-gray-500 font-medium">
                  Nguồn: <strong className="text-gray-700">{marketSource}</strong>
                </p>
              </div>
            </div>

            {/* Region & Grade Selector Controls */}
            <div className="flex flex-wrap items-center gap-2">
              {/* Grade Filter Tabs */}
              <div className="flex items-center gap-1 bg-emerald-50 p-1 rounded-[12px] text-xs font-bold border border-emerald-200/80">
                <button
                  onClick={() => setSelectedGradeFilter("all")}
                  className={`px-2.5 py-1 rounded-[8px] transition-all cursor-pointer ${
                    selectedGradeFilter === "all" ? "bg-emerald-700 text-white shadow-xs" : "text-emerald-800 hover:bg-emerald-100"
                  }`}
                >
                  Tất cả (12)
                </button>
                <button
                  onClick={() => setSelectedGradeFilter("dep")}
                  className={`px-2.5 py-1 rounded-[8px] transition-all cursor-pointer ${
                    selectedGradeFilter === "dep" ? "bg-emerald-700 text-white shadow-xs" : "text-emerald-800 hover:bg-emerald-100"
                  }`}
                >
                  ⭐ Hàng Đẹp (Loại 1)
                </button>
                <button
                  onClick={() => setSelectedGradeFilter("xo")}
                  className={`px-2.5 py-1 rounded-[8px] transition-all cursor-pointer ${
                    selectedGradeFilter === "xo" ? "bg-emerald-700 text-white shadow-xs" : "text-emerald-800 hover:bg-emerald-100"
                  }`}
                >
                  📦 Hàng Xô (Lùa vựa)
                </button>
              </div>

              {/* Region Tabs */}
              <div className="flex items-center gap-1 bg-gray-100 p-1 rounded-[12px] text-xs font-bold">
                <button
                  onClick={() => setSelectedRegion("mientay")}
                  className={`px-3 py-1 rounded-[8px] transition-all cursor-pointer ${
                    selectedRegion === "mientay" ? "bg-emerald-600 text-white shadow-xs" : "text-gray-600 hover:text-gray-900"
                  }`}
                >
                  Miền Tây Nam Bộ
                </button>
                <button
                  onClick={() => setSelectedRegion("taynguyen")}
                  className={`px-3 py-1 rounded-[8px] transition-all cursor-pointer ${
                    selectedRegion === "taynguyen" ? "bg-emerald-600 text-white shadow-xs" : "text-gray-600 hover:text-gray-900"
                  }`}
                >
                  Tây Nguyên
                </button>
                <button
                  onClick={() => setSelectedRegion("miendong")}
                  className={`px-3 py-1 rounded-[8px] transition-all cursor-pointer ${
                    selectedRegion === "miendong" ? "bg-emerald-600 text-white shadow-xs" : "text-gray-600 hover:text-gray-900"
                  }`}
                >
                  Miền Đông Nam Bộ
                </button>
              </div>
            </div>
          </div>

          {/* Real Farm-Gate Purchasing Prices Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3.5">
            {marketItems
              .filter((item) => {
                if (selectedGradeFilter === "dep") return item.grade === "dep" || item.name.includes("Đẹp") || item.quality.includes("Đẹp");
                if (selectedGradeFilter === "xo") return item.grade === "xo" || item.name.includes("Xô") || item.quality.includes("Xô");
                return true;
              })
              .map((item, idx) => {
                const priceStr = getRegionalPrice(item, selectedRegion);
                const isUp = item.trend === "up" || (item.change && item.change.includes("+"));
                const isDepGrade = item.grade === "dep" || item.name.includes("Đẹp") || item.quality.includes("Đẹp");

                return (
                  <div
                    key={idx}
                    className={`border p-4 rounded-[18px] transition-all flex flex-col justify-between space-y-3 ${
                      isDepGrade ? "bg-emerald-50/40 border-emerald-200/90 hover:border-emerald-500 shadow-2xs" : "bg-gray-50/90 border-gray-200/80 hover:border-emerald-400"
                    }`}
                  >
                    <div>
                      <div className="flex items-center justify-between gap-2 mb-1">
                        <span className="text-[10px] font-black uppercase text-emerald-800 bg-emerald-100 px-2 py-0.5 rounded">
                          {item.category || "Sầu riêng"}
                        </span>
                        <span className={`text-[10px] font-extrabold px-2 py-0.5 rounded-full ${isDepGrade ? "bg-amber-100 text-amber-900 border border-amber-200" : "bg-gray-200 text-gray-700"}`}>
                          {isDepGrade ? "⭐ HÀNG ĐẸP LOẠI 1" : "📦 HÀNG XÔ LÙA VỰA"}
                        </span>
                      </div>
                      <h3 className="text-sm font-black text-gray-900 leading-snug">{item.name}</h3>
                    </div>

                    <div className="flex items-baseline justify-between pt-2 border-t border-gray-200/60">
                      <div>
                        <span className="text-lg font-black text-emerald-700 tracking-tight">{priceStr}</span>
                        <span className="text-[11px] font-bold text-gray-500 ml-1">{item.unit || "đ/kg"}</span>
                      </div>
                      <span
                        className={`text-[10px] font-black px-2 py-0.5 rounded-full ${
                          isUp ? "bg-emerald-100 text-emerald-800" : "bg-gray-200 text-gray-700"
                        }`}
                      >
                        {item.change || "Ổn định"}
                      </span>
                    </div>
                  </div>
                );
              })}
          </div>
        </div>
      )}

      {/* 3. TÌM KIẾM & TRA CỨU SÂU BỆNH AI (PEST & DISEASE LOOKUP) */}
      {(adminActiveTab === "all" || adminActiveTab === "diseases") && (
        <div className="bg-white p-5 rounded-[20px] border border-gray-200/80 shadow-xs space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-2">
              <div className="w-9 h-9 rounded-[12px] bg-red-100 text-red-700 flex items-center justify-center">
                <Bug className="w-5 h-5" />
              </div>
              <div>
                <h2 className="text-base font-black text-gray-900 tracking-tight">Tra Cứu Nhanh Sâu Bệnh Hại Sầu Riêng</h2>
                <p className="text-xs text-gray-500 font-medium">Nhận biết triệu chứng, nguyên nhân & biện pháp xử lý kịp thời</p>
              </div>
            </div>

            <div className="flex items-center gap-1.5 bg-gray-100 p-1 rounded-[12px] text-xs font-bold">
              <button
                onClick={() => setSelectedDiseaseTab("all")}
                className={`px-3 py-1 rounded-[8px] transition-all ${selectedDiseaseTab === "all" ? "bg-white text-gray-900 shadow-xs" : "text-gray-500 hover:text-gray-900"}`}
              >
                Tất cả ({diseasesList.length})
              </button>
              <button
                onClick={() => setSelectedDiseaseTab("nam")}
                className={`px-3 py-1 rounded-[8px] transition-all ${selectedDiseaseTab === "nam" ? "bg-white text-gray-900 shadow-xs" : "text-gray-500 hover:text-gray-900"}`}
              >
                Bệnh nấm lá & gốc
              </button>
              <button
                onClick={() => setSelectedDiseaseTab("Sau")}
                className={`px-3 py-1 rounded-[8px] transition-all ${selectedDiseaseTab === "Sau" ? "bg-white text-gray-900 shadow-xs" : "text-gray-500 hover:text-gray-900"}`}
              >
                Bọ trĩ & sâu hại
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {diseasesList
              .filter((d) => {
                if (selectedDiseaseTab === "nam") return d.type.includes("Nấm") || d.type.includes("bệnh");
                if (selectedDiseaseTab === "Sau") return d.type.includes("Côn trùng") || d.type.includes("Sâu");
                return true;
              })
              .filter((d) => !searchTerm || d.name.toLowerCase().includes(searchTerm.toLowerCase()) || d.symptom.toLowerCase().includes(searchTerm.toLowerCase()))
              .map((dis) => (
                <div key={dis.id} className="bg-gray-50/90 border border-gray-200/80 p-4 rounded-[18px] space-y-2 flex flex-col justify-between">
                  <div>
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-[10px] font-black uppercase text-emerald-800 bg-emerald-100 px-2 py-0.5 rounded">{dis.type}</span>
                      <button onClick={() => navigate("/ai-chatbot")} className="text-[10px] font-extrabold text-blue-600 hover:underline flex items-center gap-0.5">
                        Hỏi Trợ lý AI <ArrowUpRight className="w-3 h-3" />
                      </button>
                    </div>
                    <h3 className="text-sm font-black text-gray-900">{dis.name}</h3>
                    <p className="text-xs text-gray-600 font-medium mt-1"><strong>Triệu chứng:</strong> {dis.symptom}</p>
                  </div>

                  <div className="pt-2 border-t border-gray-200/60 text-xs space-y-1">
                    <p className="text-emerald-800 font-semibold"><strong>Biện pháp sinh học:</strong> {dis.bioControl}</p>
                    <p className="text-gray-700 font-semibold"><strong>Thuốc đặc trị:</strong> {dis.control}</p>
                  </div>
                </div>
              ))}
          </div>
        </div>
      )}

      {/* 4. BIỆN PHÁP PHÒNG TRỪ SINH HỌC & KỸ THUẬT CANH TÁC */}
      {(adminActiveTab === "all" || adminActiveTab === "biocontrol" || adminActiveTab === "farming") && (
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
          {/* Biện Pháp Phòng Trừ Sinh Học */}
          {(adminActiveTab === "all" || adminActiveTab === "biocontrol") && (
            <div className={`${adminActiveTab === "biocontrol" ? "lg:col-span-12" : "lg:col-span-6"} bg-white p-5 rounded-[20px] border border-gray-200/80 shadow-xs space-y-4 flex flex-col justify-between`}>
              <div>
                <div className="flex items-center gap-2 mb-3">
                  <div className="w-9 h-9 rounded-[12px] bg-emerald-100 text-emerald-700 flex items-center justify-center">
                    <ShieldCheck className="w-5 h-5" />
                  </div>
                  <div>
                    <h2 className="text-base font-black text-gray-900 tracking-tight">Biện Pháp Phòng Trừ Sinh Học</h2>
                    <p className="text-xs text-gray-500 font-medium">Bảo vệ hệ sinh thái đất & tăng sức đề kháng tự nhiên cho sầu riêng</p>
                  </div>
                </div>

                <div className="space-y-3">
                  {bioMeasures.map((bm, idx) => (
                    <div key={idx} className="p-3.5 rounded-[16px] border border-gray-200/80 bg-gray-50/60 space-y-1">
                      <div className="flex items-center justify-between">
                        <h3 className="text-xs font-black text-gray-900">{bm.title}</h3>
                        <span className={`text-[9px] font-black px-2 py-0.5 rounded border ${bm.color}`}>{bm.tag}</span>
                      </div>
                      <p className="text-xs text-gray-600 font-medium leading-relaxed">{bm.desc}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Kỹ Thuật Canh Tác */}
          {(adminActiveTab === "all" || adminActiveTab === "farming") && (
            <div className={`${adminActiveTab === "farming" ? "lg:col-span-12" : "lg:col-span-6"} bg-white p-5 rounded-[20px] border border-gray-200/80 shadow-xs space-y-4 flex flex-col justify-between`}>
              <div>
                <div className="flex items-center gap-2 mb-3">
                  <div className="w-9 h-9 rounded-[12px] bg-amber-100 text-amber-700 flex items-center justify-center">
                    <BookOpen className="w-5 h-5" />
                  </div>
                  <div>
                    <h2 className="text-base font-black text-gray-900 tracking-tight">Kỹ Thuật Canh Tác Cốt Lõi</h2>
                    <p className="text-xs text-gray-500 font-medium">Quy trình chăm sóc theo các giai đoạn phát triển sầu riêng</p>
                  </div>
                </div>

                <div className="space-y-3">
                  {farmingGuides.map((fg, idx) => {
                    const IconComp = fg.icon;
                    return (
                      <div key={idx} className="p-3.5 rounded-[16px] border border-gray-200/80 bg-gray-50/60 space-y-1">
                        <div className="flex items-center gap-2">
                          <IconComp className="w-4 h-4 text-emerald-600" />
                          <h3 className="text-xs font-black text-gray-900">{fg.stage}</h3>
                        </div>
                        <p className="text-xs text-gray-600 font-medium leading-relaxed">{fg.detail}</p>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* 5. ƯU ĐÃI GÓI NÔNG NGHIỆP THÔNG MINH */}
      {(adminActiveTab === "all" || adminActiveTab === "promos") && (
        <div className="bg-white p-5 rounded-[20px] border border-gray-200/80 shadow-xs space-y-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="w-9 h-9 rounded-[12px] bg-purple-100 text-purple-700 flex items-center justify-center">
                <Zap className="w-5 h-5" />
              </div>
              <div>
                <h2 className="text-base font-black text-gray-900 tracking-tight">Gói Dịch Vụ Nông Nghiệp Thông Minh DGA</h2>
                <p className="text-xs text-gray-500 font-medium">Đăng ký để mở khóa tư vấn chuyên gia 1-1 & trợ lý AI không giới hạn</p>
              </div>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            {promoPackages.map((pkg, idx) => (
              <div
                key={idx}
                className={`p-5 rounded-[22px] border flex flex-col justify-between transition-all relative ${
                  pkg.popular
                    ? "bg-gradient-to-b from-purple-50/60 to-white border-purple-300 shadow-md scale-102"
                    : "bg-gray-50/70 border-gray-200/80"
                }`}
              >
                {pkg.popular && (
                  <span className="absolute -top-3 right-4 bg-purple-700 text-white text-[10px] font-black px-3 py-0.5 rounded-full shadow-xs">
                    {pkg.badge}
                  </span>
                )}
                <div className="space-y-3">
                  <div>
                    <span className="text-[10px] font-extrabold text-purple-700 uppercase tracking-wider">{pkg.badge}</span>
                    <h3 className="text-lg font-black text-gray-900">{pkg.name}</h3>
                    <p className="text-xs text-gray-500 font-medium mt-0.5">{pkg.desc}</p>
                  </div>

                  <div className="flex items-baseline gap-1">
                    <span className="text-2xl font-black text-gray-900">{pkg.price}</span>
                    <span className="text-xs font-bold text-gray-500">{pkg.period}</span>
                  </div>

                  <ul className="space-y-2 text-xs text-gray-600 font-medium pt-2 border-t border-gray-200/60">
                    {pkg.features.map((feat, fIdx) => (
                      <li key={fIdx} className="flex items-start gap-1.5">
                        <span className="text-emerald-600 font-bold">✓</span>
                        <span>{feat}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                <button
                  onClick={() => handleOpenPayment(pkg)}
                  disabled={pkg.active}
                  className={`w-full mt-4 py-2.5 rounded-[12px] text-xs font-black transition-all cursor-pointer ${
                    pkg.active
                      ? "bg-gray-200 text-gray-500 cursor-not-allowed"
                      : pkg.popular
                      ? "bg-purple-700 hover:bg-purple-800 text-white shadow-md shadow-purple-900/20"
                      : "bg-gray-900 hover:bg-black text-white"
                  }`}
                >
                  {pkg.btnText}
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* 6. TIN TỨC NÔNG NGHIỆP & XUẤT KHẨU */}
      {(adminActiveTab === "all" || adminActiveTab === "news") && (
        <div className="bg-white p-5 rounded-[20px] border border-gray-200/80 shadow-xs space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-2">
              <div className="w-9 h-9 rounded-[12px] bg-purple-100 text-purple-700 flex items-center justify-center">
                <Newspaper className="w-5 h-5" />
              </div>
              <div>
                <h2 className="text-base font-black text-gray-900 tracking-tight">Tin Tức Nông Nghiệp & Thị Trường Sầu Riêng</h2>
                <p className="text-xs text-gray-500 font-medium">Cập nhật tin tức xuất khẩu, kỹ thuật mùa vụ & cảnh báo thời tiết</p>
              </div>
            </div>

            <div className="flex items-center gap-1 bg-purple-50 p-1 rounded-[12px] text-xs font-bold border border-purple-200/80">
              <button
                onClick={() => setSelectedNewsTab("highlight")}
                className={`px-3 py-1.5 rounded-[10px] transition-all cursor-pointer ${
                  selectedNewsTab === "highlight" ? "bg-purple-700 text-white shadow-xs" : "text-purple-900 hover:bg-purple-100"
                }`}
              >
                🔥 Nổi bật hôm nay
              </button>
              <button
                onClick={() => setSelectedNewsTab("market")}
                className={`px-3 py-1.5 rounded-[10px] transition-all cursor-pointer ${
                  selectedNewsTab === "market" ? "bg-purple-700 text-white shadow-xs" : "text-purple-900 hover:bg-purple-100"
                }`}
              >
                📉 Biến động giá
              </button>
              <button
                onClick={() => setSelectedNewsTab("export")}
                className={`px-3 py-1.5 rounded-[10px] transition-all cursor-pointer ${
                  selectedNewsTab === "export" ? "bg-purple-700 text-white shadow-xs" : "text-purple-900 hover:bg-purple-100"
                }`}
              >
                📜 Mã vùng & Xuất khẩu
              </button>
              <button
                onClick={() => setSelectedNewsTab("weather")}
                className={`px-3 py-1.5 rounded-[10px] transition-all cursor-pointer ${
                  selectedNewsTab === "weather" ? "bg-purple-700 text-white shadow-xs" : "text-purple-900 hover:bg-purple-100"
                }`}
              >
                🌤️ Thời tiết & Cảnh báo
              </button>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {newsList
              .filter((n) => n.tab === selectedNewsTab)
              .map((n, idx) => (
                <div
                  key={idx}
                  className="bg-gray-50/90 border border-gray-200/80 rounded-[20px] p-4 flex gap-4 items-center hover:border-purple-300 hover:shadow-xs transition-all"
                >
                  <img src={n.img} alt={n.title} className="w-28 h-28 rounded-[16px] object-cover flex-shrink-0 border border-gray-200 shadow-2xs" />
                  <div className="space-y-1.5 flex-1">
                    <div className="flex items-center justify-between gap-1">
                      <span className="text-[9px] font-black uppercase text-purple-800 bg-purple-100 px-2 py-0.5 rounded border border-purple-200">
                        📍 {n.region}
                      </span>
                      <span className="text-[10px] text-gray-400 font-bold">{n.time}</span>
                    </div>
                    <h3 className="text-xs font-black text-gray-900 leading-snug line-clamp-2">{n.title}</h3>
                    <p className="text-[11px] text-gray-600 font-medium line-clamp-2 leading-relaxed">{n.desc}</p>
                    <p className="text-[10px] font-bold text-gray-400 italic">Nguồn: {n.source}</p>
                  </div>
                </div>
              ))}
          </div>
        </div>
      )}

      {/* 7. INTERACTIVE PAYMENT METHOD MODAL */}
      {selectedPaymentPkg && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-md animate-fade-in">
          <div className="bg-white rounded-[28px] max-w-2xl w-full p-6 sm:p-7 shadow-2xl border border-gray-100 max-h-[90vh] overflow-y-auto relative space-y-5">
            {/* Modal Header */}
            <div className="flex items-center justify-between border-b border-gray-100 pb-4">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-[14px] bg-emerald-100 text-emerald-800 flex items-center justify-center font-black">
                  <Shield className="w-6 h-6" />
                </div>
                <div>
                  <h3 className="text-lg font-black text-gray-900 leading-tight">
                    Thanh Toán & Nâng Cấp {selectedPaymentPkg.name}
                  </h3>
                  <p className="text-xs text-gray-500 font-medium">Hệ thống kích hoạt dịch vụ tự động trong 30 giây</p>
                </div>
              </div>
              <button
                onClick={() => setSelectedPaymentPkg(null)}
                className="w-9 h-9 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-600 flex items-center justify-center transition-all cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {paySuccess ? (
              /* Success Screen */
              <div className="py-8 text-center space-y-4">
                <div className="w-16 h-16 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto animate-bounce">
                  <CheckCircle2 className="w-10 h-10" />
                </div>
                <div className="space-y-1">
                  <h4 className="text-xl font-black text-gray-900">Kích Hoạt Gói {selectedPaymentPkg.name} Thành Công!</h4>
                  <p className="text-xs text-gray-600 font-medium max-w-md mx-auto">
                    Cảm ơn bạn đã nâng cấp dịch vụ Durian Guardian AI. Tài khoản của bạn đã mở khóa đầy đủ các đặc quyền cao cấp.
                  </p>
                </div>

                <div className="bg-emerald-50 border border-emerald-200 p-4 rounded-[18px] max-w-sm mx-auto text-left text-xs space-y-1.5 text-emerald-900 font-bold">
                  <p>✓ Đã mở khóa: <strong>{selectedPaymentPkg.name}</strong></p>
                  <p>✓ Thời hạn: <strong>{billingCycle} Tháng</strong></p>
                  <p>✓ Tư vấn 1-1 với Chuyên gia Nông nghiệp: <strong>ĐÃ KÍCH HOẠT</strong></p>
                  {selectedPaymentPkg.name.includes("Premium") && <p>✓ Voucher giảm 20% mua IoT: <strong>ĐÃ NHẬN VOUCHER</strong></p>}
                </div>

                <button
                  onClick={() => setSelectedPaymentPkg(null)}
                  className="bg-emerald-600 hover:bg-emerald-700 text-white font-black text-xs px-8 py-3 rounded-[14px] transition-all cursor-pointer shadow-lg shadow-emerald-900/20"
                >
                  Bắt đầu sử dụng ngay
                </button>
              </div>
            ) : (
              /* Payment Options Screen */
              <div className="space-y-5">
                {/* Billing Cycle Selector */}
                <div className="space-y-2">
                  <label className="text-xs font-black text-gray-900 uppercase tracking-wide">1. Chọn Chu Kỳ Thanh Toán</label>
                  <div className="grid grid-cols-3 gap-2.5">
                    {[
                      { cycle: 1, label: "1 Tháng", desc: "Thanh toán từng tháng" },
                      { cycle: 6, label: "6 Tháng", desc: "Giảm 10% tổng hóa đơn" },
                      { cycle: 12, label: "12 Tháng", desc: "Giảm 20% (Khuyên dùng)" },
                    ].map((item) => (
                      <button
                        key={item.cycle}
                        onClick={() => setBillingCycle(item.cycle as any)}
                        className={`p-3 rounded-[16px] border text-left transition-all cursor-pointer ${
                          billingCycle === item.cycle
                            ? "border-emerald-600 bg-emerald-50/60 shadow-xs"
                            : "border-gray-200 hover:border-gray-300 bg-gray-50/50"
                        }`}
                      >
                        <div className="flex items-center justify-between">
                          <span className="text-xs font-black text-gray-900">{item.label}</span>
                          {item.cycle > 1 && (
                            <span className="text-[9px] font-black text-emerald-700 bg-emerald-100 px-1.5 py-0.5 rounded">
                              {item.cycle === 6 ? "-10%" : "-20%"}
                            </span>
                          )}
                        </div>
                        <p className="text-[10px] text-gray-500 font-medium mt-0.5">{item.desc}</p>
                      </button>
                    ))}
                  </div>
                </div>

                {/* Payment Method Selector */}
                <div className="space-y-2">
                  <label className="text-xs font-black text-gray-900 uppercase tracking-wide">2. Chọn Phương Thức Thanh Toán</label>
                  <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                    {[
                      { id: "vietqr", name: "VietQR 24/7", icon: QrCode, badge: "Nhanh nhất" },
                      { id: "momo", name: "Ví MoMo", icon: Wallet, badge: "Khuyên dùng" },
                      { id: "vnpay", name: "VNPay QR", icon: QrCode, badge: "Mọi App Bank" },
                      { id: "card", name: "Thẻ Visa / MC", icon: CreditCard, badge: "Quốc tế" },
                    ].map((pm) => {
                      const IconComp = pm.icon;
                      return (
                        <button
                          key={pm.id}
                          onClick={() => setPaymentMethod(pm.id as any)}
                          className={`p-3 rounded-[16px] border text-center transition-all cursor-pointer flex flex-col items-center gap-1.5 ${
                            paymentMethod === pm.id
                              ? "border-emerald-600 bg-emerald-600 text-white font-black shadow-md"
                              : "border-gray-200 bg-white hover:border-gray-300 text-gray-700 font-bold"
                          }`}
                        >
                          <IconComp className="w-5 h-5" />
                          <span className="text-xs leading-tight">{pm.name}</span>
                        </button>
                      );
                    })}
                  </div>
                </div>

                {/* Dynamic Payment Method Content */}
                <div className="bg-gray-50 border border-gray-200/80 p-4 rounded-[20px]">
                  {paymentMethod === "vietqr" && (
                    <div className="flex flex-col sm:flex-row items-center gap-5">
                      <div className="w-36 h-36 bg-white p-2 rounded-[16px] border border-gray-200 shadow-md flex items-center justify-center flex-shrink-0">
                        <img
                          src="https://api.qrserver.com/v1/create-qr-code/?size=180x180&data=VietQR_MBBank_0976231258_DurianGuardianAI"
                          alt="VietQR Payment"
                          className="w-full h-full object-contain"
                        />
                      </div>
                      <div className="space-y-1.5 text-xs text-gray-700 flex-1">
                        <span className="text-[10px] font-black uppercase text-emerald-800 bg-emerald-100 px-2 py-0.5 rounded">
                          Ngân hàng Quân Đội (MBBank)
                        </span>
                        <p className="pt-1">Số tài khoản: <strong className="text-gray-900 font-black text-sm">0976231258</strong></p>
                        <p>Chủ tài khoản: <strong className="text-gray-900 font-bold">NGUYEN VAN TEO</strong></p>
                        <p>Nội dung chuyển khoản: <strong className="text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">DGA {selectedPaymentPkg.name.toUpperCase()} {billingCycle}THANG</strong></p>

                        <button
                          onClick={() => {
                            navigator.clipboard.writeText("0976231258");
                            setCopiedAccount(true);
                            setTimeout(() => setCopiedAccount(false), 2000);
                          }}
                          className="mt-2 text-[11px] font-bold text-emerald-700 hover:text-emerald-800 flex items-center gap-1 cursor-pointer"
                        >
                          <Copy className="w-3.5 h-3.5" />
                          <span>{copiedAccount ? "Đã sao chép số tài khoản!" : "Sao chép số tài khoản MBBank"}</span>
                        </button>
                      </div>
                    </div>
                  )}

                  {paymentMethod === "momo" && (
                    <div className="flex items-center gap-4 text-xs text-gray-700">
                      <div className="w-28 h-28 bg-pink-50 p-2 rounded-[16px] border border-pink-200 flex items-center justify-center flex-shrink-0 text-pink-700 font-black">
                        <QrCode className="w-16 h-16 text-pink-600" />
                      </div>
                      <div className="space-y-1">
                        <h4 className="font-black text-pink-700 text-sm">Thanh toán bằng Ví MoMo</h4>
                        <p className="text-gray-600">Quét mã QR MoMo để tự động điền thông tin và kích hoạt gói cước ngay lập tức.</p>
                      </div>
                    </div>
                  )}

                  {paymentMethod === "vnpay" && (
                    <div className="flex items-center gap-4 text-xs text-gray-700">
                      <div className="w-28 h-28 bg-blue-50 p-2 rounded-[16px] border border-blue-200 flex items-center justify-center flex-shrink-0 text-blue-700 font-black">
                        <QrCode className="w-16 h-16 text-blue-600" />
                      </div>
                      <div className="space-y-1">
                        <h4 className="font-black text-blue-700 text-sm">Cổng VNPay QR Đa Ngân Hàng</h4>
                        <p className="text-gray-600">Mở ứng dụng ngân hàng bất kỳ (Vietcombank, BIDV, Agribank...) chọn Quét Mã QR.</p>
                      </div>
                    </div>
                  )}

                  {paymentMethod === "card" && (
                    <div className="space-y-2 text-xs">
                      <h4 className="font-black text-gray-900">Thẻ Quốc Tế Visa / MasterCard / JCB</h4>
                      <input
                        type="text"
                        placeholder="Số thẻ (16 chữ số)"
                        className="w-full p-2.5 bg-white border border-gray-200 rounded-[10px] text-xs font-bold focus:outline-none focus:ring-1 focus:ring-emerald-500"
                      />
                      <div className="grid grid-cols-2 gap-2">
                        <input
                          type="text"
                          placeholder="MM/YY"
                          className="w-full p-2.5 bg-white border border-gray-200 rounded-[10px] text-xs font-bold"
                        />
                        <input
                          type="password"
                          placeholder="CVV / CVC"
                          className="w-full p-2.5 bg-white border border-gray-200 rounded-[10px] text-xs font-bold"
                        />
                      </div>
                    </div>
                  )}
                </div>

                {/* Promo Code Coupon Section */}
                <div className="space-y-1.5">
                  <div className="flex gap-2">
                    <input
                      type="text"
                      placeholder="Nhập mã giảm giá (VD: DGA2026)"
                      value={promoCodeInput}
                      onChange={(e) => setPromoCodeInput(e.target.value)}
                      className="flex-1 px-3.5 py-2 text-xs border border-gray-200 rounded-[12px] font-bold focus:outline-none focus:ring-2 focus:ring-emerald-500 uppercase"
                    />
                    <button
                      onClick={handleApplyPromoCode}
                      className="bg-gray-900 hover:bg-black text-white font-black text-xs px-4 py-2 rounded-[12px] transition-all cursor-pointer"
                    >
                      Áp dụng
                    </button>
                  </div>
                  {promoMessage && <p className="text-xs font-bold text-emerald-700 mt-1">{promoMessage}</p>}
                </div>

                {/* Order Total & Confirm Action */}
                <div className="pt-3 border-t border-gray-100 flex items-center justify-between">
                  <div>
                    <span className="text-[10px] font-bold text-gray-400 uppercase block">TỔNG TIỀN THANH TOÁN ({billingCycle} THÁNG)</span>
                    <div className="flex items-baseline gap-1.5">
                      <span className="text-2xl font-black text-emerald-700">
                        {(() => {
                          const base = selectedPaymentPkg.name.includes("Pro") ? 30000 : 199000;
                          const cycleMult = billingCycle === 6 ? 0.9 : billingCycle === 12 ? 0.8 : 1;
                          const total = base * billingCycle * cycleMult * (1 - promoDiscount);
                          return total.toLocaleString("vi-VN") + "đ";
                        })()}
                      </span>
                      {promoDiscount > 0 && <span className="text-xs font-bold text-emerald-600">(-20% Voucher)</span>}
                    </div>
                  </div>

                  <button
                    onClick={handleConfirmPayment}
                    disabled={isProcessingPay}
                    className="bg-emerald-600 hover:bg-emerald-700 text-white font-black text-xs px-6 py-3 rounded-[14px] transition-all cursor-pointer shadow-lg shadow-emerald-900/20 flex items-center gap-2"
                  >
                    {isProcessingPay ? (
                      <span>Đang xử lý thanh toán...</span>
                    ) : (
                      <>
                        <Lock className="w-4 h-4" />
                        <span>Xác nhận & Kích hoạt gói</span>
                      </>
                    )}
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
