import 'package:flutter/material.dart';

class PostItem {
  final String id;
  final String authorName;
  final String authorRole;
  final String avatarUrl;
  final String timeAgo;
  final String title;
  final String content;
  final String? imageUrl;
  final List<String>? galleryImages;
  final String category; // 'pests', 'techniques', 'expert'
  final bool isExpertAnswered;
  final String? expertAnswer;
  final String? expertName;
  final bool isFeatured;
  int likes;
  bool isLiked;
  final List<Map<String, String>> comments;

  PostItem({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.avatarUrl,
    required this.timeAgo,
    required this.title,
    required this.content,
    this.imageUrl,
    this.galleryImages,
    required this.category,
    this.isExpertAnswered = false,
    this.expertAnswer,
    this.expertName,
    this.isFeatured = false,
    required this.likes,
    this.isLiked = false,
    required this.comments,
  });
}

class ExpertModel {
  final String id;
  final String name;
  final String title;
  final String workplace;
  final String experience;
  final int consultationsCount;
  final double rating;
  final String avatarUrl;
  final bool isOnline;
  final String specialty;

  ExpertModel({
    required this.id,
    required this.name,
    required this.title,
    required this.workplace,
    required this.experience,
    required this.consultationsCount,
    required this.rating,
    required this.avatarUrl,
    required this.isOnline,
    required this.specialty,
  });
}

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'all'; // 'all', 'pests', 'techniques', 'expert'
  final Map<String, TextEditingController> _commentControllers = {};

  final List<ExpertModel> _experts = [
    ExpertModel(
      id: 'exp-1',
      name: 'ThS. Nguyễn Văn Đức',
      title: 'Chuyên gia Dinh dưỡng & Thổ nhưỡng Sầu Riêng',
      workplace: 'Viện Nông Nghiệp Tây Nguyên (WASI)',
      experience: '20 năm kinh nghiệm',
      consultationsCount: 1420,
      rating: 4.9,
      avatarUrl: 'assets/images/expert_nguyen_van_duc.png',
      isOnline: true,
      specialty: 'Cân bằng NPK, pH đất & Phục hồi rễ tơ',
    ),
    ExpertModel(
      id: 'exp-2',
      name: 'Kỹ sư Lê Minh',
      title: 'Chuyên gia Bệnh hại & Nấm Phytophthora',
      workplace: 'Trung tâm BVTV Vùng Miền Tây',
      experience: '14 năm kinh nghiệm',
      consultationsCount: 980,
      rating: 4.9,
      avatarUrl: 'assets/images/expert_le_minh.png',
      isOnline: true,
      specialty: 'Đặc trị Xì mủ gốc, Thối rễ & Nấm hồng',
    ),
    ExpertModel(
      id: 'exp-3',
      name: 'TS. Trần Thị Thanh',
      title: 'Chuyên gia Sinh học & Phân bón Vi sinh',
      workplace: 'Khoa Nông Nghiệp - Đại học Cần Thơ',
      experience: '18 năm kinh nghiệm',
      consultationsCount: 1150,
      rating: 5.0,
      avatarUrl: 'assets/images/expert_tran_thi_thanh.png',
      isOnline: true,
      specialty: 'Trichoderma đối kháng, Phosphonate & Hữu cơ',
    ),
    ExpertModel(
      id: 'exp-4',
      name: 'GS. TS. Hoàng Trọng Nam',
      title: 'Chuyên gia Sinh lý Cây trồng & Xử lý Ra hoa',
      workplace: 'Học viện Nông nghiệp Việt Nam',
      experience: '25 năm kinh nghiệm',
      consultationsCount: 2100,
      rating: 5.0,
      avatarUrl: 'assets/images/expert_hoang_trong_nam.png',
      isOnline: true,
      specialty: 'Kích ra hoa nghịch vụ, Hạn chế rụng bông',
    ),
    ExpertModel(
      id: 'exp-5',
      name: 'Kỹ sư Phạm Văn Hùng',
      title: 'Chuyên gia Nuôi trái & Tăng chất lượng Cơm',
      workplace: 'Hiệp hội Sầu riêng Đắk Lắk',
      experience: '16 năm kinh nghiệm',
      consultationsCount: 1340,
      rating: 4.8,
      avatarUrl: 'assets/images/expert_pham_van_hung.png',
      isOnline: false,
      specialty: 'Kali Sunfat, Chống sượng cơm, Lên màu trái',
    ),
    ExpertModel(
      id: 'exp-6',
      name: 'ThS. Vũ Thị Ngọc',
      title: 'Chuyên gia Quản lý Sâu bệnh VietGAP / Export',
      workplace: 'Chi cục Trồng trọt & BVTV Lâm Đồng',
      experience: '12 năm kinh nghiệm',
      consultationsCount: 890,
      rating: 4.9,
      avatarUrl: 'assets/images/expert_vu_thi_ngoc.png',
      isOnline: true,
      specialty: 'Thuốc BVTV sinh học & Quản lý tồn dư PHI',
    ),
  ];

  final List<PostItem> _posts = [
    PostItem(
      id: 'post-featured-1',
      authorName: 'Nguyễn Văn Hùng',
      authorRole: 'Nông dân Đắk Lắk',
      avatarUrl: '',
      timeAgo: '2 giờ trước',
      title: 'Hỏi kinh nghiệm xử lý xì mủ gốc mùa mưa Tây Nguyên',
      content:
          'Chào mọi người! Vườn sầu riêng Ri6 5 năm tuổi của mình mấy hôm nay mưa nhiều phát hiện 2 cây bị xì mủ thâm đen ở gốc. Mình đã cạo sạch và quét Ridomil Gold, cho hỏi có nên rải thêm vôi bột xung quanh gốc không ạ?',
      imageUrl: 'assets/images/post_nguyen_van_hung.jpg',
      category: 'pests',
      isFeatured: true,
      isExpertAnswered: true,
      expertName: 'Kỹ sư Lê Minh (Vie-farm Verified)',
      expertAnswer:
          'Chào anh Hùng! Anh rải vôi bột 500g/gốc rất tốt để nâng pH đất > 6.0 hạn chế nấm Phytophthora bào hòa. Nhớ siết thoát nước mương rãnh nhé!',
      likes: 24,
      isLiked: false,
      comments: [
        {
          'author': 'Nguyễn Văn Chinh',
          'text': 'Kinh nghiệm nhà mình là pha thêm Phosphonate tưới rễ tơ 2 lần cách nhau 7 ngày.',
          'time': '30 phút trước'
        },
      ],
    ),
    PostItem(
      id: 'post-normal-2',
      authorName: 'Trần Thị Thu Hà',
      authorRole: 'Chủ vườn Tiền Giang',
      avatarUrl: '',
      timeAgo: '5 giờ trước',
      title: 'Kinh nghiệm bón phân NPK kết hợp Kali Sunfat nuôi cơm Monthong',
      content:
          'Chia sẻ với bà con: Giai đoạn quả 70 ngày mình bón NPK 15-15-15 kết hợp K2SO4 tỉ lệ 2:1 cơm sầu riêng lên màu vàng rất đẹp, ngọt đậm và hạt lép rõ rệt. Ảnh chụp thực tế tại vườn.',
      galleryImages: [
        'assets/images/post_tran_thi_thu_ha.jpg',
        'assets/images/post_phan_hai.jpg',
        'assets/images/post_nguyen_thi_mai.jpg',
      ],
      category: 'techniques',
      likes: 42,
      isLiked: true,
      comments: [
        {
          'author': 'Võ Văn Nam',
          'text': 'Trái Monthong nhìn mê quá chị ơi! Tỷ lệ bón mỗi gốc bao nhiêu vậy chị?',
          'time': '3 giờ trước'
        },
      ],
    ),
    PostItem(
      id: 'post-question-3',
      authorName: 'Nguyễn Văn Chinh',
      authorRole: 'Nông dân Lâm Đồng',
      avatarUrl: '',
      timeAgo: '10 phút trước',
      title: 'Hỏi Chuyên Gia: Cây sầu riêng Monthong rụng búp hoa mùa mưa có phải do thiếu Canxi Bột?',
      content:
          'Kính gửi Kỹ sư Vie-farm! Vườn Monthong nhà tôi 6 năm tuổi đang giai đoạn ra búp hoa bằng ngón tay trỏ. Mấy hôm nay mưa dầm búp hoa rụng rải rác dưới gốc. Cho tôi hỏi cách xử lý xịt Canxi Boron phòng rụng búp?',
      category: 'expert',
      likes: 18,
      isLiked: false,
      comments: [],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (final controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // Interactive Expert Consultation Dialog
  void _openConsultationDialog(ExpertModel expert) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Image.asset(expert.avatarUrl, fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hỏi Ý Kiến Chuyên Gia',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              expert.name,
                              style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Tiêu đề thắc mắc', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: titleController,
                  decoration: InputDecoration(
                    hintText: 'Ví dụ: Cây bị xì mủ gốc, rụng búp hoa...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Chi tiết tình trạng vườn sầu riêng', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: contentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Mô tả hiện tượng, tuổi cây, triệu chứng trên lá/thân/trái...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Đính kèm ảnh chụp thực tế tại vườn'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (titleController.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ Đã gửi câu hỏi tới ${expert.name}. Phản hồi trong 30 phút!'),
                          backgroundColor: Colors.green.shade700,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('GỬI CÂU HỎI CHO CHUYÊN GIA', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E8E4A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Open Create Post Modal
  void _openCreatePostModal() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'pests';
    final List<String> attachedPhotos = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tạo Bài Thảo Luận Mới',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Chủ đề bài viết', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Sâu bệnh & Nấm'),
                          selected: category == 'pests',
                          onSelected: (_) => setModalState(() => category = 'pests'),
                        ),
                        ChoiceChip(
                          label: const Text('Kỹ thuật canh tác'),
                          selected: category == 'techniques',
                          onSelected: (_) => setModalState(() => category = 'techniques'),
                        ),
                        ChoiceChip(
                          label: const Text('Hỏi chuyên gia'),
                          selected: category == 'expert',
                          onSelected: (_) => setModalState(() => category = 'expert'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Tiêu đề bài viết...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Chia sẻ kinh nghiệm hoặc đặt câu hỏi cho cộng đồng...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Gallery Image Upload Section
                    StatefulBuilder(
                      builder: (ctx, setPhotoState) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  final samplePhotos = [
                                    'assets/images/post_tran_thi_thu_ha.jpg',
                                    'assets/images/post_phan_hai.jpg',
                                    'assets/images/post_nguyen_thi_mai.jpg',
                                  ];
                                  final nextPhoto = samplePhotos[attachedPhotos.length % samplePhotos.length];
                                  attachedPhotos.add(nextPhoto);
                                });
                              },
                              icon: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF1E8E4A)),
                              label: Text(
                                attachedPhotos.isEmpty
                                    ? 'Tải ảnh từ thư viện / Chụp ảnh'
                                    : 'Đã đính kèm ${attachedPhotos.length} ảnh (Chạm thêm)',
                                style: const TextStyle(color: Color(0xFF1E8E4A), fontWeight: FontWeight.bold),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFF1E8E4A)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            if (attachedPhotos.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                height: 75,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: attachedPhotos.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (context, idx) {
                                    return Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: SizedBox(
                                            width: 75,
                                            height: 75,
                                            child: Image.asset(
                                              attachedPhotos[idx],
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: InkWell(
                                            onTap: () {
                                              setModalState(() {
                                                attachedPhotos.removeAt(idx);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(3),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.7),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (titleController.text.trim().isEmpty) return;
                          setState(() {
                            _posts.insert(
                              0,
                              PostItem(
                                id: 'post-${DateTime.now().millisecondsSinceEpoch}',
                                authorName: 'Nguyễn Văn A (Bạn)',
                                authorRole: 'Nông dân Vie-farm',
                                avatarUrl: '',
                                timeAgo: 'Vừa xong',
                                title: titleController.text.trim(),
                                content: contentController.text.trim(),
                                galleryImages: attachedPhotos.isNotEmpty ? List.from(attachedPhotos) : null,
                                category: category,
                                likes: 0,
                                comments: [],
                              ),
                            );
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Đã đăng bài viết thảo luận lên Cộng đồng!'),
                              backgroundColor: Color(0xFF1E8E4A),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.send),
                        label: const Text('ĐĂNG BÀI THẢO LUẬN', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E8E4A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(112 + MediaQuery.of(context).padding.top),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Header Top Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F5ED),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: Color(0xFF1E8E4A),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Cộng Đồng Sầu Riêng Vie-farm',
                              style: TextStyle(
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF111827),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Kết nối nông dân - Chia sẻ kinh nghiệm - Cùng nhau phát triển',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF6B7280),
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                            ),
                            child: const Icon(
                              Icons.notifications_none_rounded,
                              color: Color(0xFF111827),
                              size: 22,
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFFEF4444),
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: const Text(
                                '2',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Tab Bar Row
                Expanded(
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF1E8E4A),
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelColor: const Color(0xFF1E8E4A),
                    unselectedLabelColor: const Color(0xFF6B7280),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 15),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Thảo luận',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.psychology_outlined, size: 15),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Chuyên gia',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscussionTab(),
          _buildExpertsTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              onPressed: _openCreatePostModal,
              backgroundColor: const Color(0xFF1E8E4A),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.edit_note),
              label: const Text('Đăng bài thảo luận', style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  // 1. DISCUSSION TAB VIEW (RICH CARDS & FILTERS RESTORED)
  Widget _buildDiscussionTab() {
    final filteredPosts = _selectedCategory == 'all'
        ? _posts
        : _posts.where((p) => p.category == _selectedCategory).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Post Prompt Box
          InkWell(
            onTap: _openCreatePostModal,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.green.shade50,
                    child: Icon(Icons.person, color: Colors.green.shade800, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hôm nay vườn bạn thế nào? Đăng bài...',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.image_outlined, color: Colors.green.shade700, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: _selectedCategory == 'all',
                  onSelected: (_) => setState(() => _selectedCategory = 'all'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Sâu bệnh & Nấm'),
                  selected: _selectedCategory == 'pests',
                  onSelected: (_) => setState(() => _selectedCategory = 'pests'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Kỹ thuật canh tác'),
                  selected: _selectedCategory == 'techniques',
                  onSelected: (_) => setState(() => _selectedCategory = 'techniques'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Hỏi chuyên gia'),
                  selected: _selectedCategory == 'expert',
                  onSelected: (_) => setState(() => _selectedCategory = 'expert'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Render Post Cards
          ...filteredPosts.map((post) {
            if (post.isFeatured) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildFeaturedPostCard(post),
              );
            } else if (post.galleryImages != null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildNormalPostCard(post),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildQuestionPostCard(post),
              );
            }
          }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // CARD 1: FEATURED POST CARD WITH VERIFIED EXPERT ANSWER
  Widget _buildFeaturedPostCard(PostItem post) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1E8E4A).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE8F5ED),
                child: Text(
                  post.authorName[0],
                  style: const TextStyle(
                    color: Color(0xFF1E8E4A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${post.authorRole} • ${post.timeAgo}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 12, color: Colors.amber.shade900),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Đã trả lời',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            post.content,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 12),

          // Expert Answer Highlight Box
          if (post.isExpertAnswered)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF7F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1E8E4A).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFF1E8E4A), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        post.expertName ?? 'Chuyên gia Vie-farm',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E8E4A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.expertAnswer ?? '',
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF1F2937), height: 1.35),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      post.isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                      color: post.isLiked ? Colors.green.shade700 : Colors.grey.shade600,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        post.isLiked = !post.isLiked;
                        post.likes += post.isLiked ? 1 : -1;
                      });
                    },
                  ),
                  Text('${post.likes}', style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 16),
                  const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${post.comments.length}', style: const TextStyle(fontSize: 13)),
                ],
              ),
              const Icon(Icons.share_outlined, size: 18, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  // CARD 2: GALLERY POST CARD
  Widget _buildNormalPostCard(PostItem post) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFE8F5ED),
                child: Text(
                  post.authorName[0],
                  style: const TextStyle(
                    color: Color(0xFF1E8E4A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${post.authorRole} • ${post.timeAgo}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            post.content,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 12),

          // 3 Images Gallery
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 100,
                    child: Image.asset(
                      'assets/images/post_tran_thi_thu_ha.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 100,
                    child: Image.asset(
                      'assets/images/post_phan_hai.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 100,
                    child: Image.asset(
                      'assets/images/post_nguyen_thi_mai.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      post.isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                      color: post.isLiked ? Colors.green.shade700 : Colors.grey.shade600,
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        post.isLiked = !post.isLiked;
                        post.likes += post.isLiked ? 1 : -1;
                      });
                    },
                  ),
                  Text('${post.likes}', style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 16),
                  const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${post.comments.length}', style: const TextStyle(fontSize: 13)),
                ],
              ),
              const Icon(Icons.share_outlined, size: 18, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  // CARD 3: QUESTION POST CARD
  Widget _buildQuestionPostCard(PostItem post) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blue.shade50,
                child: Text(post.authorName[0], style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${post.authorRole} • ${post.timeAgo}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Hỏi chuyên gia', style: TextStyle(color: Colors.blue.shade900, fontSize: 10.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            post.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 6),
          Text(
            post.content,
            style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
        ],
      ),
    );
  }

  // 2. EXPERTS TAB VIEW (FIXED: 6 Distinct Vietnamese Avatars & Interactive Consultation)
  Widget _buildExpertsTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _experts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final exp = _experts[index];

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Expert Avatar with Online Indicator
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: exp.avatarUrl.startsWith('assets/')
                          ? Image.asset(
                              exp.avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return CircleAvatar(
                                  radius: 30,
                                  backgroundColor: const Color(0xFFE8F5ED),
                                  child: Text(
                                    exp.name[0],
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E8E4A),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Image.network(
                              exp.avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return CircleAvatar(
                                  radius: 30,
                                  backgroundColor: const Color(0xFFE8F5ED),
                                  child: Text(
                                    exp.name[0],
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E8E4A),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  if (exp.isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Expert Info Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            exp.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFD97706), size: 14),
                              const SizedBox(width: 3),
                              Text(
                                '${exp.rating}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exp.title,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF4B5563),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '🏢 ${exp.workplace}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5ED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '💡 Chuyên môn: ${exp.specialty}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E8E4A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '💬 ${exp.consultationsCount} lượt tư vấn',
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280)),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openConsultationDialog(exp),
                          icon: const Icon(Icons.chat, size: 14),
                          label: const Text('Hỏi ý kiến', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E8E4A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }


}
