import { useState } from "react";
import {
  Users,
  MessageSquare,
  UserCheck,
  Sparkles,
  Heart,
  MessageCircle,
  Share2,
  Send,
  PlusCircle,
  Image as ImageIcon,
  CheckCircle2,
  Star,
  Award,
  Calendar,
  Clock,
  Filter,
  ShieldCheck,
  Search,
  X,
} from "lucide-react";

interface PostItem {
  id: string;
  author: string;
  avatarBg: string;
  region: string;
  time: string;
  category: string;
  title: string;
  content: string;
  img?: string;
  likes: number;
  comments: number;
  userLiked?: boolean;
}

interface ExpertItem {
  id: string;
  name: string;
  title: string;
  workplace: string;
  experience: string;
  rating: number;
  consultations: number;
  status: "online" | "busy";
  avatar: string;
  specialties: string[];
}

interface QAItem {
  id: string;
  farmerName: string;
  farmerRegion: string;
  expertName: string;
  expertTitle: string;
  question: string;
  answer: string;
  time: string;
  likes: number;
}

export default function UserCommunityPage() {
  const [activeTab, setActiveTab] = useState<"discussion" | "experts">("discussion");
  const [selectedCategory, setSelectedCategory] = useState("all");

  // Post Discussion States
  const [showCreatePostModal, setShowCreatePostModal] = useState(false);
  const [newPostTitle, setNewPostTitle] = useState("");
  const [newPostCategory, setNewPostCategory] = useState("Kỹ thuật canh tác");
  const [newPostContent, setNewPostContent] = useState("");

  // Expert Consultation Modal States
  const [selectedExpert, setSelectedExpert] = useState<ExpertItem | null>(null);
  const [questionText, setQuestionText] = useState("");
  const [questionSuccessMsg, setQuestionSuccessMsg] = useState("");
  const [isSubmittingQ, setIsSubmittingQ] = useState(false);

  // Sample Posts Feed
  const [posts, setPosts] = useState<PostItem[]>([
    {
      id: "post-1",
      author: "Anh Ba Đức (Chủ vườn 3.5 ha)",
      avatarBg: "bg-emerald-600 text-white",
      region: "Cai Lậy, Tiền Giang",
      time: "45 phút trước",
      category: "Kỹ thuật canh tác",
      title: "Kinh nghiệm phun phòng thán thư lá sầu riêng Ri6 giai đoạn nhú đọt gấm cực kỳ hiệu quả",
      content:
        "Chào bà con! Vụ này mưa sương nhiều, đọt non sầu riêng Ri6 nhà tôi vừa nhú gấm là tôi phun ngay luân phiên Nấm đối kháng Trichoderma + Anvil 5SC. Nhờ vậy lá ra đều rực rỡ, không hề bị cháy chóp hay còi cọc.",
      img: "https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&w=800&q=80",
      likes: 42,
      comments: 18,
      userLiked: false,
    },
    {
      id: "post-2",
      author: "Chú Bảy Nam (Nông hộ 500 cây)",
      avatarBg: "bg-amber-600 text-white",
      region: "Krông Pắc, Đắk Lắk",
      time: "2 giờ trước",
      category: "Bón phân & Dinh dưỡng",
      title: "Bí quyết khắc phục hiện tượng nứt gai & cháy múi sầu riêng Thái (Monthong) mùa mưa",
      content:
        "Năm ngoái sầu riêng nhà tôi bị nứt gai nhiều do mưa dầm. Năm nay làm theo tư vấn của TS. Nguyễn Văn Hùng bón bổ sung Canxi-Bo chelate định kỳ 15 ngày/lần kết hợp NPK 12-11-18 kali cao, trái lên cơm vàng đẹp tuyệt đối!",
      img: "https://images.unsplash.com/photo-1601004890684-d8cbf643f5f2?auto=format&fit=crop&w=800&q=80",
      likes: 68,
      comments: 29,
      userLiked: true,
    },
    {
      id: "post-3",
      author: "Kỹ sư Hoàng Hải",
      avatarBg: "bg-blue-600 text-white",
      region: "Bảo Lộc, Lâm Đồng",
      time: "5 giờ trước",
      category: "Kỹ thuật canh tác",
      title: "Hướng dẫn kỹ thuật đậy bạt siết nước dội mầm hoa sầu riêng vụ nghịch vụ 2026",
      content:
        "Bà con lưu ý giai đoạn siết nước tạo mầm hoa sầu riêng vụ nghịch: Cần đậy bạt ni-lông xẻ rãnh thoát nước kỹ ở mương vườn, kết hợp phun MKP 0-52-34 ức chế đọt non trong 15-20 ngày liên tục.",
      img: "https://images.unsplash.com/photo-1625246333195-78d9c38ad449?auto=format&fit=crop&w=800&q=80",
      likes: 95,
      comments: 34,
      userLiked: false,
    },
  ]);

  // Agronomist Experts Catalog (Real Humans)
  const expertsList: ExpertItem[] = [
    {
      id: "exp-1",
      name: "TS. Nguyễn Văn Hùng",
      title: "Chuyên gia Nông học Cây Ăn Quả",
      workplace: "Viện Cây Ăn Quả Miền Nam (SOFRI)",
      experience: "15 năm kinh nghiệm",
      rating: 5.0,
      consultations: 480,
      status: "online",
      avatar: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=300&q=80",
      specialties: ["Xử lý Phytophthora xì mủ gốc", "Tạo mầm hoa sầu riêng nghịch vụ", "Quy trình VietGAP"],
    },
    {
      id: "exp-2",
      name: "ThS. Lê Thiện Nhân",
      title: "Kỹ sư Trồng trọt & Dinh dưỡng Đất",
      workplace: "Học viện Nông nghiệp Việt Nam",
      experience: "12 năm kinh nghiệm",
      rating: 4.9,
      consultations: 350,
      status: "online",
      avatar: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=300&q=80",
      specialties: ["Khắc phục nứt trái & cháy múi", "Phối trộn NPK & Canxi-Bo", "Cải tạo đất chua ngập mặn"],
    },
    {
      id: "exp-3",
      name: "Kỹ sư Trần Thị Mai",
      title: "Chuyên gia Bảo vệ Thực vật & Sâu bệnh",
      workplace: "Chi cục Trồng trọt & BVTV Lâm Đồng",
      experience: "10 năm kinh nghiệm",
      rating: 4.9,
      consultations: 290,
      status: "busy",
      avatar: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?auto=format&fit=crop&w=300&q=80",
      specialties: ["Phòng trừ bọ trĩ & nhện đỏ", "Trị nấm thán thư rụng lá", "Chế phẩm sinh học BT & Neem"],
    },
    {
      id: "exp-4",
      name: "Chuyên gia Võ Hoàng Nam",
      title: "Cố vấn Kỹ thuật IoT & Nông nghiệp AI",
      workplace: "Đội ngũ Cố vấn Kỹ thuật DGA",
      experience: "8 năm kinh nghiệm",
      rating: 5.0,
      consultations: 520,
      status: "online",
      avatar: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=300&q=80",
      specialties: ["Cảm biến đất pH/EC/Độ ẩm", "Hệ thống tưới tự động AI", "Phân tích mã vùng trồng GACC"],
    },
  ];

  // Answered Public Q&A Catalog
  const publicQAList: QAItem[] = [
    {
      id: "qa-1",
      farmerName: "Bác Năm Nông (Chủ vườn Đắk Lắk)",
      farmerRegion: "Krông Pắc, Đắk Lắk",
      expertName: "TS. Nguyễn Văn Hùng",
      expertTitle: "Chuyên gia SOFRI",
      question: "Cây sầu riêng Monthong 6 năm tuổi bị xì mủ thân chảy nhựa nâu đỏ thì cạo vỏ bôi thuốc gì hiệu quả nhất?",
      answer:
        "Bà con dùng dao sạch cạo hết phần vỏ thâm đen rỉ nhựa cho tới phần gỗ trắng. Sau đó bôi dung dịch Ridomil Gold 68WG hoặc Aliette 800WG pha đặc, để khô 2 ngày rồi quét keo liền sẹo. Kết hợp tưới gốc Phosphonate 30ml/20L nước phòng ngừa nấm tái phát.",
      time: "Hôm qua",
      likes: 54,
    },
    {
      id: "qa-2",
      farmerName: "Anh Hai Nghĩa (Chủ vườn Tiền Giang)",
      farmerRegion: "Châu Thành, Tiền Giang",
      expertName: "ThS. Lê Thiện Nhân",
      expertTitle: "Học viện Nông nghiệp",
      question: "Sầu riêng Ri6 giai đoạn trái 60 ngày bị rụng cơm và gai bị xám thì bổ sung vi lượng gì?",
      answer:
        "Giai đoạn này trái lớn rất nhanh, bà con cần phun bổ sung Canxi-Bo chelate kết hợp Bo-Kẽm qua lá để chống nứt gai. Bón gốc NPK 15-15-15 + Humic vi sinh giúp cơm vàng dẻo và ngọt lịm.",
      time: "2 ngày trước",
      likes: 39,
    },
  ];

  // Create New Post Handler
  const handleCreatePost = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPostTitle.trim() || !newPostContent.trim()) return;

    const created: PostItem = {
      id: `post-${Date.now()}`,
      author: "Tôi (Chủ trang trại)",
      avatarBg: "bg-emerald-700 text-white font-black",
      region: "Phong Điền, Cần Thơ",
      time: "Vừa xong",
      category: newPostCategory,
      title: newPostTitle,
      content: newPostContent,
      likes: 1,
      comments: 0,
      userLiked: true,
    };

    setPosts([created, ...posts]);
    setNewPostTitle("");
    setNewPostContent("");
    setShowCreatePostModal(false);
  };

  // Toggle Like Handler
  const handleToggleLike = (id: string) => {
    setPosts(
      posts.map((p) => {
        if (p.id === id) {
          const liked = !p.userLiked;
          return {
            ...p,
            userLiked: liked,
            likes: liked ? p.likes + 1 : p.likes - 1,
          };
        }
        return p;
      })
    );
  };

  // Submit Expert Question Handler
  const handleSubmitQuestion = (e: React.FormEvent) => {
    e.preventDefault();
    if (!questionText.trim()) return;
    setIsSubmittingQ(true);

    setTimeout(() => {
      setIsSubmittingQ(false);
      setQuestionSuccessMsg(`Đã gửi câu hỏi tới ${selectedExpert?.name}! Chuyên gia sẽ phản hồi trong vòng 2 giờ.`);
      setQuestionText("");
    }, 1200);
  };

  return (
    <div className="flex flex-col space-y-6 pb-12">
      {/* 1. HERO HEADER & COMMUNITY STATS */}
      <div className="relative overflow-hidden rounded-[24px] bg-gradient-to-r from-emerald-900 via-emerald-800 to-teal-950 p-6 sm:p-8 text-white shadow-xl">
        <div className="absolute right-0 top-0 translate-x-12 -translate-y-12 w-96 h-96 bg-emerald-500/10 rounded-full blur-3xl pointer-events-none" />

        <div className="relative z-10 space-y-4">
          <div className="flex items-center gap-2">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-black bg-emerald-500/20 text-emerald-300 border border-emerald-400/30">
              <Users className="w-3.5 h-3.5" /> CỘNG ĐỒNG NÔNG DÂN & CHUYÊN GIA DGA
            </span>
          </div>

          <h1 className="text-2xl sm:text-3xl font-black tracking-tight leading-tight">
            Diễn Đàn Chia Sẻ Kinh Nghiệm Canh Tác & Hỏi Đáp Chuyên Gia Sầu Riêng
          </h1>
          <p className="text-xs sm:text-sm text-emerald-100/90 max-w-2xl font-medium leading-relaxed">
            Nơi kết nối hàng ngàn chủ vườn sầu riêng trên toàn quốc. Trao đổi kỹ thuật làm bông, trị sâu bệnh và tư vấn trực tiếp 1-1 với đội ngũ Chuyên gia Nông học hàng đầu.
          </p>

          {/* Stats Bar */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 pt-2">
            <div className="bg-white/10 backdrop-blur-md border border-white/15 p-3 rounded-[16px]">
              <span className="text-xl font-black text-emerald-300">12.450+</span>
              <p className="text-[11px] text-gray-300 font-bold">Thành viên Nông hộ</p>
            </div>
            <div className="bg-white/10 backdrop-blur-md border border-white/15 p-3 rounded-[16px]">
              <span className="text-xl font-black text-emerald-300">3.820+</span>
              <p className="text-[11px] text-gray-300 font-bold">Bài thảo luận kinh nghiệm</p>
            </div>
            <div className="bg-white/10 backdrop-blur-md border border-white/15 p-3 rounded-[16px]">
              <span className="text-xl font-black text-amber-300">15+</span>
              <p className="text-[11px] text-gray-300 font-bold">Chuyên gia SOFRI & Học viện</p>
            </div>
            <div className="bg-white/10 backdrop-blur-md border border-white/15 p-3 rounded-[16px]">
              <span className="text-xl font-black text-emerald-300">99.2%</span>
              <p className="text-[11px] text-gray-300 font-bold">Phản hồi trong 2 giờ</p>
            </div>
          </div>
        </div>
      </div>

      {/* 2. MAIN 2 TABS CONTROL BAR */}
      <div className="bg-white p-2 rounded-[20px] border border-gray-200/80 shadow-xs flex flex-col sm:flex-row items-center justify-between gap-3">
        <div className="flex items-center gap-2 w-full sm:w-auto">
          <button
            onClick={() => setActiveTab("discussion")}
            className={`flex-1 sm:flex-initial flex items-center justify-center gap-2 px-5 py-3 rounded-[14px] text-xs font-black transition-all cursor-pointer ${
              activeTab === "discussion"
                ? "bg-emerald-600 text-white shadow-md shadow-emerald-900/20"
                : "text-gray-600 hover:text-gray-900 hover:bg-gray-100"
            }`}
          >
            <MessageSquare className="w-4 h-4" />
            <span>TAB 1: Thảo Luận & Chia Sẻ Kinh Nghiệm</span>
          </button>

          <button
            onClick={() => setActiveTab("experts")}
            className={`flex-1 sm:flex-initial flex items-center justify-center gap-2 px-5 py-3 rounded-[14px] text-xs font-black transition-all cursor-pointer ${
              activeTab === "experts"
                ? "bg-emerald-600 text-white shadow-md shadow-emerald-900/20"
                : "text-gray-600 hover:text-gray-900 hover:bg-gray-100"
            }`}
          >
            <UserCheck className="w-4 h-4" />
            <span>TAB 2: Hỏi Đáp & Tư Vấn Chuyên Gia (1-1)</span>
          </button>
        </div>

        {activeTab === "discussion" && (
          <button
            onClick={() => setShowCreatePostModal(true)}
            className="w-full sm:w-auto bg-amber-500 hover:bg-amber-600 text-gray-950 font-black text-xs px-5 py-3 rounded-[14px] transition-all cursor-pointer flex items-center justify-center gap-2 shadow-sm"
          >
            <PlusCircle className="w-4 h-4" />
            <span>Đăng Bài Chia Sẻ Kinh Nghiệm</span>
          </button>
        )}
      </div>

      {/* 3. TAB 1: THẢO LUẬN & CHIA SẺ KINHI NGHIỆM */}
      {activeTab === "discussion" && (
        <div className="space-y-4">
          {/* Filter Bar */}
          <div className="flex items-center gap-2 overflow-x-auto pb-1 text-xs font-bold">
            {[
              { id: "all", label: "Tất cả bài viết" },
              { id: "tech", label: "🌱 Kỹ thuật canh tác" },
              { id: "pest", label: "🐛 Xử lý sâu bệnh & xì mủ" },
              { id: "fertilizer", label: "🧪 Bón phân & Dinh dưỡng" },
              { id: "market", label: "📈 Giá sầu riêng & Thị trường" },
            ].map((cat) => (
              <button
                key={cat.id}
                onClick={() => setSelectedCategory(cat.id)}
                className={`px-4 py-2 rounded-[12px] transition-all cursor-pointer whitespace-nowrap ${
                  selectedCategory === cat.id
                    ? "bg-emerald-100 text-emerald-900 border border-emerald-300 font-black shadow-2xs"
                    : "bg-white text-gray-600 hover:bg-gray-100 border border-gray-200"
                }`}
              >
                {cat.label}
              </button>
            ))}
          </div>

          {/* Posts Feed Grid */}
          <div className="space-y-4">
            {posts.map((post) => (
              <div
                key={post.id}
                className="bg-white p-5 sm:p-6 rounded-[22px] border border-gray-200/80 shadow-xs hover:border-emerald-300 transition-all space-y-3.5"
              >
                {/* Author Info Header */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3">
                    <div className={`w-10 h-10 rounded-full flex items-center justify-center font-black text-xs ${post.avatarBg}`}>
                      {post.author.charAt(0)}
                    </div>
                    <div>
                      <h4 className="text-xs font-black text-gray-900">{post.author}</h4>
                      <div className="flex items-center gap-2 text-[10px] text-gray-500 font-semibold">
                        <span>📍 {post.region}</span>
                        <span>•</span>
                        <span>{post.time}</span>
                      </div>
                    </div>
                  </div>

                  <span className="text-[10px] font-black text-emerald-800 bg-emerald-100 px-2.5 py-1 rounded-full border border-emerald-200">
                    {post.category}
                  </span>
                </div>

                {/* Content */}
                <div className="space-y-2">
                  <h3 className="text-sm sm:text-base font-black text-gray-900 leading-snug">{post.title}</h3>
                  <p className="text-xs sm:text-sm text-gray-700 font-medium leading-relaxed whitespace-pre-line">{post.content}</p>
                </div>

                {/* Image if available */}
                {post.img && (
                  <div className="overflow-hidden rounded-[16px] border border-gray-200/80 max-h-72">
                    <img src={post.img} alt={post.title} className="w-full h-full object-cover hover:scale-102 transition-transform duration-300" />
                  </div>
                )}

                {/* Action Buttons (Like, Comment, Share) */}
                <div className="pt-3 border-t border-gray-100 flex items-center justify-between text-xs font-bold">
                  <div className="flex items-center gap-4">
                    <button
                      onClick={() => handleToggleLike(post.id)}
                      className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                        post.userLiked ? "bg-red-50 text-red-600 font-black" : "text-gray-600 hover:bg-gray-100"
                      }`}
                    >
                      <Heart className={`w-4 h-4 ${post.userLiked ? "fill-red-500 text-red-500" : ""}`} />
                      <span>{post.likes} Thích</span>
                    </button>

                    <button className="flex items-center gap-1.5 px-3 py-1.5 rounded-full text-gray-600 hover:bg-gray-100 transition-all cursor-pointer">
                      <MessageCircle className="w-4 h-4 text-emerald-600" />
                      <span>{post.comments} Bình luận</span>
                    </button>
                  </div>

                  <button className="flex items-center gap-1.5 text-gray-500 hover:text-gray-900 transition-all cursor-pointer">
                    <Share2 className="w-4 h-4" />
                    <span className="hidden sm:inline">Chia sẻ</span>
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* 4. TAB 2: HỎI ĐÁP & TƯ VẤN CHUYÊN GIA (1-1) */}
      {activeTab === "experts" && (
        <div className="space-y-6">
          {/* Experts Directory Header */}
          <div className="bg-white p-5 rounded-[20px] border border-gray-200/80 shadow-xs space-y-4">
            <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
              <div className="flex items-center gap-2">
                <div className="w-9 h-9 rounded-[12px] bg-amber-100 text-amber-800 flex items-center justify-center font-black">
                  <UserCheck className="w-5 h-5" />
                </div>
                <div>
                  <h2 className="text-base font-black text-gray-900 tracking-tight">Danh Sách Chuyên Gia Nông Nghiệp Thực Tế</h2>
                  <p className="text-xs text-gray-500 font-medium">Chọn Chuyên gia Nông học giàu kinh nghiệm để gửi câu hỏi hoặc tư vấn 1-1</p>
                </div>
              </div>
            </div>

            {/* Experts Cards Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {expertsList.map((exp) => (
                <div
                  key={exp.id}
                  className="bg-gray-50/90 border border-gray-200/80 rounded-[20px] p-5 flex flex-col justify-between space-y-4 hover:border-emerald-400 hover:shadow-xs transition-all"
                >
                  <div className="flex items-start gap-4">
                    <div className="relative flex-shrink-0">
                      <img src={exp.avatar} alt={exp.name} className="w-16 h-16 rounded-[18px] object-cover border-2 border-emerald-500 shadow-sm" />
                      <span
                        className={`absolute -bottom-1 -right-1 w-4 h-4 rounded-full border-2 border-white ${
                          exp.status === "online" ? "bg-emerald-500" : "bg-amber-500"
                        }`}
                        title={exp.status === "online" ? "Online sẵn sàng tư vấn" : "Hẹn lịch trước"}
                      />
                    </div>

                    <div className="space-y-1 flex-1">
                      <div className="flex items-center justify-between gap-2">
                        <h3 className="text-sm font-black text-gray-900 leading-tight">{exp.name}</h3>
                        <span className="flex items-center gap-1 text-[11px] font-black text-amber-600 bg-amber-100 px-2 py-0.5 rounded-full">
                          <Star className="w-3 h-3 fill-amber-500 text-amber-500" />
                          {exp.rating} ({exp.consultations})
                        </span>
                      </div>

                      <p className="text-xs font-bold text-emerald-800">{exp.title}</p>
                      <p className="text-[11px] text-gray-600 font-medium">{exp.workplace}</p>
                      <p className="text-[10px] text-gray-500 font-bold italic">🎖️ {exp.experience}</p>
                    </div>
                  </div>

                  {/* Specialties Pills */}
                  <div className="flex flex-wrap gap-1.5">
                    {exp.specialties.map((spec, sIdx) => (
                      <span key={sIdx} className="text-[10px] font-bold text-gray-700 bg-white border border-gray-200 px-2 py-0.5 rounded-md">
                        ✓ {spec}
                      </span>
                    ))}
                  </div>

                  {/* Action Buttons */}
                  <div className="grid grid-cols-2 gap-2 pt-2 border-t border-gray-200/60">
                    <button
                      onClick={() => {
                        setSelectedExpert(exp);
                        setQuestionSuccessMsg("");
                      }}
                      className="bg-emerald-600 hover:bg-emerald-700 text-white font-black text-xs py-2.5 rounded-[12px] transition-all cursor-pointer shadow-xs flex items-center justify-center gap-1.5"
                    >
                      <MessageSquare className="w-3.5 h-3.5" />
                      <span>Hỏi Chuyên gia</span>
                    </button>

                    <button
                      onClick={() => {
                        setSelectedExpert(exp);
                        setQuestionSuccessMsg("");
                      }}
                      className="bg-white hover:bg-gray-100 text-gray-900 border border-gray-300 font-black text-xs py-2.5 rounded-[12px] transition-all cursor-pointer flex items-center justify-center gap-1.5"
                    >
                      <Calendar className="w-3.5 h-3.5 text-emerald-700" />
                      <span>Đặt Lịch 1-1</span>
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Public Answered Q&A List */}
          <div className="bg-white p-5 rounded-[20px] border border-gray-200/80 shadow-xs space-y-4">
            <div className="flex items-center gap-2">
              <div className="w-9 h-9 rounded-[12px] bg-purple-100 text-purple-700 flex items-center justify-center font-black">
                <ShieldCheck className="w-5 h-5" />
              </div>
              <div>
                <h2 className="text-base font-black text-gray-900 tracking-tight">Câu Hỏi Nông Dân Đã Được Chuyên Gia Trả Lời Công Khai</h2>
                <p className="text-xs text-gray-500 font-medium">Học hỏi từ kinh nghiệm xử lý thực tế của các chủ vườn khác</p>
              </div>
            </div>

            <div className="space-y-4">
              {publicQAList.map((qa) => (
                <div key={qa.id} className="bg-gray-50/80 border border-gray-200/80 rounded-[20px] p-5 space-y-3">
                  {/* Question Box */}
                  <div className="space-y-1">
                    <div className="flex items-center justify-between text-[11px] font-bold text-gray-500">
                      <span className="text-emerald-800 font-black">🙋 {qa.farmerName} ({qa.farmerRegion})</span>
                      <span>{qa.time}</span>
                    </div>
                    <h3 className="text-xs sm:text-sm font-black text-gray-900">❓ {qa.question}</h3>
                  </div>

                  {/* Expert Answer Box */}
                  <div className="bg-emerald-50/70 border border-emerald-200/80 p-4 rounded-[16px] space-y-1.5">
                    <div className="flex items-center gap-2 text-xs font-black text-emerald-900">
                      <Award className="w-4 h-4 text-emerald-700" />
                      <span>Trả lời bởi {qa.expertName} ({qa.expertTitle})</span>
                    </div>
                    <p className="text-xs text-gray-800 font-medium leading-relaxed whitespace-pre-line">{qa.answer}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* 5. MODAL CREATE NEW POST (TAB 1) */}
      {showCreatePostModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-md animate-fade-in">
          <div className="bg-white rounded-[24px] max-w-lg w-full p-6 shadow-2xl border border-gray-100 space-y-4">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <h3 className="text-base font-black text-gray-900">Đăng Bài Chia Sẻ Kinh Nghiệm Nông Nghiệp</h3>
              <button onClick={() => setShowCreatePostModal(false)} className="text-gray-400 hover:text-gray-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreatePost} className="space-y-3">
              <div>
                <label className="text-xs font-black text-gray-700 block mb-1">Chọn Danh Mục</label>
                <select
                  value={newPostCategory}
                  onChange={(e) => setNewPostCategory(e.target.value)}
                  className="w-full text-xs font-bold p-2.5 bg-gray-50 border border-gray-200 rounded-[12px]"
                >
                  <option value="Kỹ thuật canh tác">🌱 Kỹ thuật canh tác</option>
                  <option value="Xử lý nấm bệnh">🐛 Xử lý sâu bệnh & xì mủ</option>
                  <option value="Bón phân & Dinh dưỡng">🧪 Bón phân & Dinh dưỡng</option>
                  <option value="Giá sầu riêng & Thị trường">📈 Giá sầu riêng & Thị trường</option>
                </select>
              </div>

              <div>
                <label className="text-xs font-black text-gray-700 block mb-1">Tiêu Đề Bài Viết</label>
                <input
                  type="text"
                  placeholder="Ví dụ: Kinh nghiệm khắc phục xì mủ gốc mùa mưa..."
                  value={newPostTitle}
                  onChange={(e) => setNewPostTitle(e.target.value)}
                  className="w-full text-xs font-bold p-2.5 bg-gray-50 border border-gray-200 rounded-[12px]"
                  required
                />
              </div>

              <div>
                <label className="text-xs font-black text-gray-700 block mb-1">Nội Dung Thảo Luận</label>
                <textarea
                  rows={4}
                  placeholder="Chia sẻ bí quyết canh tác, quy trình phun thuốc hoặc câu hỏi kinh nghiệm..."
                  value={newPostContent}
                  onChange={(e) => setNewPostContent(e.target.value)}
                  className="w-full text-xs font-medium p-2.5 bg-gray-50 border border-gray-200 rounded-[12px]"
                  required
                />
              </div>

              <div className="pt-2 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowCreatePostModal(false)}
                  className="px-4 py-2 text-xs font-bold text-gray-600 hover:bg-gray-100 rounded-[12px]"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 text-xs font-black bg-emerald-600 hover:bg-emerald-700 text-white rounded-[12px] shadow-sm"
                >
                  Đăng bài ngay
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* 6. MODAL CONSULT EXPERT QUESTION (TAB 2) */}
      {selectedExpert && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-md animate-fade-in">
          <div className="bg-white rounded-[24px] max-w-lg w-full p-6 shadow-2xl border border-gray-100 space-y-4">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <div className="flex items-center gap-3">
                <img src={selectedExpert.avatar} alt={selectedExpert.name} className="w-10 h-10 rounded-[12px] object-cover border border-emerald-500" />
                <div>
                  <h3 className="text-sm font-black text-gray-900">Gửi Câu Hỏi Cho {selectedExpert.name}</h3>
                  <p className="text-[11px] text-gray-500 font-semibold">{selectedExpert.title}</p>
                </div>
              </div>
              <button onClick={() => setSelectedExpert(null)} className="text-gray-400 hover:text-gray-600">
                <X className="w-5 h-5" />
              </button>
            </div>

            {questionSuccessMsg ? (
              <div className="py-6 text-center space-y-3">
                <CheckCircle2 className="w-12 h-12 text-emerald-600 mx-auto animate-bounce" />
                <p className="text-xs font-black text-gray-900">{questionSuccessMsg}</p>
                <button
                  onClick={() => setSelectedExpert(null)}
                  className="bg-emerald-600 text-white font-black text-xs px-6 py-2.5 rounded-[12px]"
                >
                  Đóng
                </button>
              </div>
            ) : (
              <form onSubmit={handleSubmitQuestion} className="space-y-3">
                <div>
                  <label className="text-xs font-black text-gray-700 block mb-1">Mô Tả Chi Tiết Vấn Đề Của Vườn Sầu Riêng</label>
                  <textarea
                    rows={4}
                    placeholder="Mô tả tuổi cây, triệu chứng nấm bệnh, rụng lá, màu nhựa xì mủ hoặc nhu cầu tư vấn dinh dưỡng..."
                    value={questionText}
                    onChange={(e) => setQuestionText(e.target.value)}
                    className="w-full text-xs font-medium p-3 bg-gray-50 border border-gray-200 rounded-[12px]"
                    required
                  />
                </div>

                <div className="p-3 bg-emerald-50 border border-emerald-200/80 rounded-[14px] text-[11px] text-emerald-900 font-bold space-y-1">
                  <p>✓ Tư vấn 1-1 trực tiếp với Chuyên gia thực tế</p>
                  <p>✓ Thời gian phản hồi dự kiến: Dưới 2 giờ</p>
                </div>

                <div className="pt-2 flex justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => setSelectedExpert(null)}
                    className="px-4 py-2 text-xs font-bold text-gray-600 hover:bg-gray-100 rounded-[12px]"
                  >
                    Hủy
                  </button>
                  <button
                    type="submit"
                    disabled={isSubmittingQ}
                    className="px-5 py-2 text-xs font-black bg-emerald-600 hover:bg-emerald-700 text-white rounded-[12px] shadow-sm flex items-center gap-1.5"
                  >
                    <Send className="w-3.5 h-3.5" />
                    <span>{isSubmittingQ ? "Đang gửi..." : "Gửi tới Chuyên gia"}</span>
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
