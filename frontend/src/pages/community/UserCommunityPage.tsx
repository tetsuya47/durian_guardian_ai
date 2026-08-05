import { useState } from "react";
import {
  MessageSquare,
  UserCheck,
  Heart,
  MessageCircle,
  Share2,
  Bookmark,
  PlusCircle,
  CheckCircle2,
  Star,
  Award,
  Calendar,
  ShieldCheck,
  MoreVertical,
  X,
  Send,
  Sprout,
  Filter,
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
  userBookmarked?: boolean;
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
      avatarBg: "bg-[#0E7A53] text-white",
      region: "Cai Lậy, Tiền Giang",
      time: "45 phút trước",
      category: "Kỹ thuật canh tác",
      title: "Kinh nghiệm phun phòng thán thư lá sầu riêng Ri6 giai đoạn nhú đọt gấm cực kỳ hiệu quả",
      content:
        "Chào bà con! Vụ này mưa sương nhiều, đọt non sầu riêng Ri6 nhà tôi vừa nhú gấm là tôi phun ngay luân phiên Nấm đối kháng Trichoderma + Anvil 5SC. Nhờ vậy lá ra đều rực rỡ, không hề bị cháy chóp hay còi cọc.",
      img: "https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?auto=format&fit=crop&w=1200&q=80",
      likes: 42,
      comments: 18,
      userLiked: false,
      userBookmarked: false,
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
      img: "https://images.unsplash.com/photo-1601004890684-d8cbf643f5f2?auto=format&fit=crop&w=1200&q=80",
      likes: 68,
      comments: 29,
      userLiked: true,
      userBookmarked: true,
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
      img: "https://images.unsplash.com/photo-1625246333195-78d9c38ad449?auto=format&fit=crop&w=1200&q=80",
      likes: 95,
      comments: 34,
      userLiked: false,
      userBookmarked: false,
    },
  ]);

  // Agronomist Experts Catalog
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
      avatarBg: "bg-[#0E7A53] text-white font-bold",
      region: "Phong Điền, Cần Thơ",
      time: "Vừa xong",
      category: newPostCategory,
      title: newPostTitle,
      content: newPostContent,
      likes: 1,
      comments: 0,
      userLiked: true,
      userBookmarked: false,
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

  // Toggle Bookmark Handler
  const handleToggleBookmark = (id: string) => {
    setPosts(
      posts.map((p) => {
        if (p.id === id) {
          return { ...p, userBookmarked: !p.userBookmarked };
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
    <div className="flex flex-col space-y-6 pb-12 bg-[#F7F9FC] min-h-screen text-[#1F2937] font-['Plus_Jakarta_Sans',sans-serif] select-none p-6 lg:p-8">
      {/* ── 1. MAIN NAVIGATION TAB BAR & CREATE POST BUTTON (HERO REMOVED) ── */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4">
        {/* Navigation Tabs */}
        <div className="flex items-center gap-3 bg-white p-1.5 rounded-[16px] border border-[#E9EEF3] shadow-xs">
          <button
            type="button"
            onClick={() => setActiveTab("discussion")}
            className={`h-[52px] px-6 rounded-[14px] text-xs sm:text-sm font-bold transition-all cursor-pointer flex items-center gap-2 ${
              activeTab === "discussion"
                ? "bg-[#0E7A53] text-white shadow-sm"
                : "text-[#6B7280] hover:text-[#1F2937] hover:bg-[#F7F9FC]"
            }`}
          >
            <MessageSquare className="w-4 h-4" />
            <span>Thảo luận & Chia sẻ Kinh Nghiệm</span>
          </button>

          <button
            type="button"
            onClick={() => setActiveTab("experts")}
            className={`h-[52px] px-6 rounded-[14px] text-xs sm:text-sm font-bold transition-all cursor-pointer flex items-center gap-2 ${
              activeTab === "experts"
                ? "bg-[#0E7A53] text-white shadow-sm"
                : "text-[#6B7280] hover:text-[#1F2937] hover:bg-[#F7F9FC]"
            }`}
          >
            <UserCheck className="w-4 h-4" />
            <span>Hỏi Đáp & Tư Vấn Chuyên Gia</span>
          </button>
        </div>

        {/* Create Post Button */}
        {activeTab === "discussion" && (
          <button
            type="button"
            onClick={() => setShowCreatePostModal(true)}
            className="h-[52px] px-6 bg-amber-500 hover:bg-amber-600 text-white font-bold text-xs sm:text-sm rounded-[16px] transition-all cursor-pointer flex items-center justify-center gap-2 shadow-xs hover:-translate-y-0.5"
          >
            <PlusCircle className="w-5 h-5" />
            <span>Đăng bài chia sẻ</span>
          </button>
        )}
      </div>

      {/* ── 2. TAB 1: THẢO LUẬN & CHIA SẺ KINH NGHIỆM ── */}
      {activeTab === "discussion" && (
        <div className="space-y-6">
          {/* Category Filter Chips */}
          <div className="flex items-center gap-2 overflow-x-auto pb-1 text-xs font-semibold no-scrollbar">
            {[
              { id: "all", label: "Tất cả bài viết" },
              { id: "tech", label: "Kỹ thuật canh tác" },
              { id: "pest", label: "Xử lý sâu bệnh" },
              { id: "fertilizer", label: "Bón phân" },
              { id: "market", label: "Giá thị trường" },
            ].map((cat) => (
              <button
                key={cat.id}
                type="button"
                onClick={() => setSelectedCategory(cat.id)}
                className={`px-5 py-2.5 rounded-full transition-all cursor-pointer whitespace-nowrap border ${
                  selectedCategory === cat.id
                    ? "bg-[#0E7A53] text-white border-[#0E7A53] shadow-xs font-bold"
                    : "bg-white text-[#6B7280] hover:text-[#1F2937] border-[#E9EEF3] hover:bg-[#F7F9FC]"
                }`}
              >
                {cat.label}
              </button>
            ))}
          </div>

          {/* Posts Feed Grid */}
          <div className="space-y-6">
            {posts.map((post) => (
              <div
                key={post.id}
                className="bg-white p-6 rounded-[22px] border border-[#E9EEF3] shadow-xs transition-all duration-200 hover:-translate-y-0.5 space-y-5 relative"
              >
                {/* Category Badge (Top Right) */}
                <div className="absolute top-6 right-14">
                  <span className="text-xs font-semibold text-[#0E7A53] bg-emerald-50 px-3 py-1 rounded-full border border-emerald-100">
                    {post.category}
                  </span>
                </div>

                {/* Header: Author Avatar, Info & Options */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-3.5">
                    <div className={`w-12 h-12 rounded-full flex items-center justify-center font-bold text-sm shadow-xs ${post.avatarBg}`}>
                      {post.author.charAt(0)}
                    </div>
                    <div>
                      <h4 className="text-base font-bold text-[#1F2937] leading-tight">{post.author}</h4>
                      <div className="flex items-center gap-2 text-xs text-[#6B7280] font-medium mt-0.5">
                        <span>{post.region}</span>
                        <span>•</span>
                        <span>{post.time}</span>
                      </div>
                    </div>
                  </div>

                  <button type="button" className="text-gray-400 hover:text-gray-600 p-1 cursor-pointer">
                    <MoreVertical className="w-5 h-5" />
                  </button>
                </div>

                {/* Title & Body */}
                <div className="space-y-2">
                  <h3 className="text-xl sm:text-2xl font-bold text-[#1F2937] leading-snug">
                    {post.title}
                  </h3>
                  <p className="text-base text-[#1F2937] leading-[1.7] whitespace-pre-line font-medium">
                    {post.content}
                  </p>
                </div>

                {/* Large Featured Image (Nearly 100% Width) */}
                {post.img && (
                  <div className="w-full aspect-[16/9] sm:aspect-[21/9] overflow-hidden rounded-[20px] border border-[#E9EEF3] bg-gray-100">
                    <img
                      src={post.img}
                      alt={post.title}
                      className="w-full h-full object-cover hover:scale-102 transition-transform duration-300"
                    />
                  </div>
                )}

                {/* Footer Action Icons */}
                <div className="pt-4 border-t border-[#E9EEF3] flex items-center justify-between text-sm font-semibold">
                  <div className="flex items-center gap-6">
                    <button
                      type="button"
                      onClick={() => handleToggleLike(post.id)}
                      className={`flex items-center gap-2 px-3 py-1.5 rounded-full transition-all cursor-pointer ${
                        post.userLiked ? "text-rose-600 bg-rose-50 font-bold" : "text-[#6B7280] hover:text-[#1F2937] hover:bg-[#F7F9FC]"
                      }`}
                    >
                      <Heart className={`w-5 h-5 ${post.userLiked ? "fill-rose-500 text-rose-500" : ""}`} />
                      <span>{post.likes}</span>
                    </button>

                    <button
                      type="button"
                      className="flex items-center gap-2 px-3 py-1.5 rounded-full text-[#6B7280] hover:text-[#1F2937] hover:bg-[#F7F9FC] transition-all cursor-pointer"
                    >
                      <MessageCircle className="w-5 h-5 text-[#0E7A53]" />
                      <span>{post.comments}</span>
                    </button>

                    <button
                      type="button"
                      className="flex items-center gap-2 px-3 py-1.5 rounded-full text-[#6B7280] hover:text-[#1F2937] hover:bg-[#F7F9FC] transition-all cursor-pointer"
                    >
                      <Share2 className="w-5 h-5" />
                      <span className="hidden sm:inline">Chia sẻ</span>
                    </button>
                  </div>

                  <button
                    type="button"
                    onClick={() => handleToggleBookmark(post.id)}
                    className={`p-2 rounded-full transition-all cursor-pointer ${
                      post.userBookmarked ? "text-[#0E7A53] bg-emerald-50" : "text-[#6B7280] hover:text-[#1F2937] hover:bg-[#F7F9FC]"
                    }`}
                  >
                    <Bookmark className={`w-5 h-5 ${post.userBookmarked ? "fill-[#0E7A53]" : ""}`} />
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* ── 3. TAB 2: HỎI ĐÁP & TƯ VẤN CHUYÊN GIA ── */}
      {activeTab === "experts" && (
        <div className="space-y-6">
          {/* Experts Directory */}
          <div className="bg-white p-6 rounded-[22px] border border-[#E9EEF3] shadow-xs space-y-5">
            <div className="flex items-center justify-between border-b border-[#E9EEF3] pb-3">
              <div>
                <h2 className="text-lg font-bold text-[#1F2937]">Danh Sách Chuyên Gia Nông Nghiệp</h2>
                <p className="text-xs text-[#6B7280] font-medium">Chọn Chuyên gia Nông học để gửi câu hỏi hoặc tư vấn 1-1</p>
              </div>
            </div>

            {/* Experts Cards Grid */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
              {expertsList.map((exp) => (
                <div
                  key={exp.id}
                  className="bg-[#F7F9FC] border border-[#E9EEF3] rounded-[20px] p-5 flex flex-col justify-between space-y-4 hover:border-[#0E7A53] transition-all"
                >
                  <div className="flex items-start gap-4">
                    <div className="relative flex-shrink-0">
                      <img src={exp.avatar} alt={exp.name} className="w-16 h-16 rounded-[18px] object-cover border-2 border-[#0E7A53] shadow-xs" />
                      <span
                        className={`absolute -bottom-1 -right-1 w-4 h-4 rounded-full border-2 border-white ${
                          exp.status === "online" ? "bg-emerald-500" : "bg-amber-500"
                        }`}
                      />
                    </div>

                    <div className="space-y-1 flex-1">
                      <div className="flex items-center justify-between gap-2">
                        <h3 className="text-sm font-bold text-[#1F2937] leading-tight">{exp.name}</h3>
                        <span className="flex items-center gap-1 text-[11px] font-semibold text-amber-700 bg-amber-100 px-2.5 py-0.5 rounded-full">
                          <Star className="w-3 h-3 fill-amber-500 text-amber-500" />
                          {exp.rating} ({exp.consultations})
                        </span>
                      </div>

                      <p className="text-xs font-semibold text-[#0E7A53]">{exp.title}</p>
                      <p className="text-[11px] text-[#6B7280] font-medium">{exp.workplace}</p>
                      <p className="text-[10px] text-[#6B7280] font-bold italic">🎖️ {exp.experience}</p>
                    </div>
                  </div>

                  {/* Specialties */}
                  <div className="flex flex-wrap gap-1.5">
                    {exp.specialties.map((spec, sIdx) => (
                      <span key={sIdx} className="text-[10px] font-semibold text-[#1F2937] bg-white border border-[#E9EEF3] px-2.5 py-0.5 rounded-md">
                        ✓ {spec}
                      </span>
                    ))}
                  </div>

                  {/* Action Buttons */}
                  <div className="grid grid-cols-2 gap-2 pt-2 border-t border-[#E9EEF3]">
                    <button
                      type="button"
                      onClick={() => {
                        setSelectedExpert(exp);
                        setQuestionSuccessMsg("");
                      }}
                      className="bg-[#0E7A53] hover:bg-emerald-800 text-white font-bold text-xs py-2.5 rounded-[12px] transition-all cursor-pointer flex items-center justify-center gap-1.5 shadow-xs"
                    >
                      <MessageSquare className="w-3.5 h-3.5" />
                      <span>Hỏi Chuyên gia</span>
                    </button>

                    <button
                      type="button"
                      onClick={() => {
                        setSelectedExpert(exp);
                        setQuestionSuccessMsg("");
                      }}
                      className="bg-white hover:bg-gray-100 text-[#1F2937] border border-[#E9EEF3] font-bold text-xs py-2.5 rounded-[12px] transition-all cursor-pointer flex items-center justify-center gap-1.5"
                    >
                      <Calendar className="w-3.5 h-3.5 text-[#0E7A53]" />
                      <span>Đặt Lịch 1-1</span>
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Public Answered Q&A List */}
          <div className="bg-white p-6 rounded-[22px] border border-[#E9EEF3] shadow-xs space-y-5">
            <div className="flex items-center gap-2 pb-3 border-b border-[#E9EEF3]">
              <div className="w-8 h-8 rounded-[12px] bg-purple-100 text-purple-700 flex items-center justify-center font-bold">
                <ShieldCheck className="w-4.5 h-4.5" />
              </div>
              <div>
                <h2 className="text-base font-bold text-[#1F2937]">Câu Hỏi Nông Dân Đã Được Chuyên Gia Trả Lời</h2>
                <p className="text-xs text-[#6B7280] font-medium">Học hỏi từ kinh nghiệm xử lý thực tế của các chủ vườn khác</p>
              </div>
            </div>

            <div className="space-y-4">
              {publicQAList.map((qa) => (
                <div key={qa.id} className="bg-[#F7F9FC] border border-[#E9EEF3] rounded-[20px] p-5 space-y-3">
                  <div className="space-y-1">
                    <div className="flex items-center justify-between text-[11px] font-semibold text-[#6B7280]">
                      <span className="text-[#0E7A53] font-bold">🙋 {qa.farmerName} ({qa.farmerRegion})</span>
                      <span>{qa.time}</span>
                    </div>
                    <h3 className="text-sm font-bold text-[#1F2937]">❓ {qa.question}</h3>
                  </div>

                  <div className="bg-emerald-50/70 border border-emerald-200/80 p-4 rounded-[16px] space-y-1.5">
                    <div className="flex items-center gap-2 text-xs font-bold text-[#0E7A53]">
                      <Award className="w-4 h-4 text-[#0E7A53]" />
                      <span>Trả lời bởi {qa.expertName} ({qa.expertTitle})</span>
                    </div>
                    <p className="text-xs text-[#1F2937] font-medium leading-relaxed whitespace-pre-line">{qa.answer}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* ── 4. MODAL CREATE NEW POST (TAB 1) ── */}
      {showCreatePostModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-md animate-fade-in">
          <div className="bg-white rounded-[24px] max-w-lg w-full p-6 shadow-2xl border border-gray-100 space-y-4">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <h3 className="text-base font-bold text-[#1F2937]">Đăng Bài Chia Sẻ Kinh Nghiệm Nông Nghiệp</h3>
              <button type="button" onClick={() => setShowCreatePostModal(false)} className="text-gray-400 hover:text-gray-600 cursor-pointer">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreatePost} className="space-y-3">
              <div>
                <label className="text-xs font-bold text-[#1F2937] block mb-1">Chọn Danh Mục</label>
                <select
                  value={newPostCategory}
                  onChange={(e) => setNewPostCategory(e.target.value)}
                  className="w-full text-xs font-semibold p-3 bg-[#F7F9FC] border border-[#E9EEF3] rounded-[14px]"
                >
                  <option value="Kỹ thuật canh tác">Kỹ thuật canh tác</option>
                  <option value="Xử lý sâu bệnh">Xử lý sâu bệnh & xì mủ</option>
                  <option value="Bón phân & Dinh dưỡng">Bón phân & Dinh dưỡng</option>
                  <option value="Giá sầu riêng & Thị trường">Giá sầu riêng & Thị trường</option>
                </select>
              </div>

              <div>
                <label className="text-xs font-bold text-[#1F2937] block mb-1">Tiêu Đề Bài Viết</label>
                <input
                  type="text"
                  placeholder="Ví dụ: Kinh nghiệm khắc phục xì mủ gốc mùa mưa..."
                  value={newPostTitle}
                  onChange={(e) => setNewPostTitle(e.target.value)}
                  className="w-full text-xs font-bold p-3 bg-[#F7F9FC] border border-[#E9EEF3] rounded-[14px]"
                  required
                />
              </div>

              <div>
                <label className="text-xs font-bold text-[#1F2937] block mb-1">Nội Dung Thảo Luận</label>
                <textarea
                  rows={4}
                  placeholder="Chia sẻ bí quyết canh tác, quy trình phun thuốc hoặc câu hỏi kinh nghiệm..."
                  value={newPostContent}
                  onChange={(e) => setNewPostContent(e.target.value)}
                  className="w-full text-xs font-medium p-3 bg-[#F7F9FC] border border-[#E9EEF3] rounded-[14px]"
                  required
                />
              </div>

              <div className="pt-2 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowCreatePostModal(false)}
                  className="px-4 py-2 text-xs font-semibold text-[#6B7280] hover:bg-gray-100 rounded-[12px] cursor-pointer"
                >
                  Hủy
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 text-xs font-bold bg-[#0E7A53] hover:bg-emerald-800 text-white rounded-[12px] shadow-sm cursor-pointer"
                >
                  Đăng bài ngay
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* ── 5. MODAL CONSULT EXPERT QUESTION (TAB 2) ── */}
      {selectedExpert && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-md animate-fade-in">
          <div className="bg-white rounded-[24px] max-w-lg w-full p-6 shadow-2xl border border-gray-100 space-y-4">
            <div className="flex items-center justify-between border-b border-gray-100 pb-3">
              <div className="flex items-center gap-3">
                <img src={selectedExpert.avatar} alt={selectedExpert.name} className="w-10 h-10 rounded-[12px] object-cover border border-[#0E7A53]" />
                <div>
                  <h3 className="text-sm font-bold text-[#1F2937]">Gửi Câu Hỏi Cho {selectedExpert.name}</h3>
                  <p className="text-[11px] text-[#6B7280] font-semibold">{selectedExpert.title}</p>
                </div>
              </div>
              <button type="button" onClick={() => setSelectedExpert(null)} className="text-gray-400 hover:text-gray-600 cursor-pointer">
                <X className="w-5 h-5" />
              </button>
            </div>

            {questionSuccessMsg ? (
              <div className="py-6 text-center space-y-3">
                <CheckCircle2 className="w-12 h-12 text-[#0E7A53] mx-auto animate-bounce" />
                <p className="text-xs font-bold text-[#1F2937]">{questionSuccessMsg}</p>
                <button
                  type="button"
                  onClick={() => setSelectedExpert(null)}
                  className="bg-[#0E7A53] text-white font-bold text-xs px-6 py-2.5 rounded-[12px] cursor-pointer"
                >
                  Đóng
                </button>
              </div>
            ) : (
              <form onSubmit={handleSubmitQuestion} className="space-y-3">
                <div>
                  <label className="text-xs font-bold text-[#1F2937] block mb-1">Mô Tả Chi Tiết Vấn Đề Của Vườn Sầu Riêng</label>
                  <textarea
                    rows={4}
                    placeholder="Mô tả tuổi cây, triệu chứng nấm bệnh, rụng lá, màu nhựa xì mủ hoặc nhu cầu tư vấn dinh dưỡng..."
                    value={questionText}
                    onChange={(e) => setQuestionText(e.target.value)}
                    className="w-full text-xs font-medium p-3 bg-[#F7F9FC] border border-[#E9EEF3] rounded-[14px]"
                    required
                  />
                </div>

                <div className="p-3 bg-emerald-50 border border-emerald-200/80 rounded-[14px] text-[11px] text-[#0E7A53] font-semibold space-y-1">
                  <p>✓ Tư vấn 1-1 trực tiếp với Chuyên gia thực tế</p>
                  <p>✓ Thời gian phản hồi dự kiến: Dưới 2 giờ</p>
                </div>

                <div className="pt-2 flex justify-end gap-2">
                  <button
                    type="button"
                    onClick={() => setSelectedExpert(null)}
                    className="px-4 py-2 text-xs font-semibold text-[#6B7280] hover:bg-gray-100 rounded-[12px] cursor-pointer"
                  >
                    Hủy
                  </button>
                  <button
                    type="submit"
                    disabled={isSubmittingQ}
                    className="px-5 py-2 text-xs font-bold bg-[#0E7A53] hover:bg-emerald-800 text-white rounded-[12px] shadow-sm flex items-center gap-1.5 cursor-pointer"
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
