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
  String _selectedCategory = 'all'; // 'all', 'pests', 'techniques', 'weather'
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
      avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200',
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
      avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
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
      avatarUrl: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=200',
      isOnline: true,
      specialty: 'Trichoderma đối kháng, Phosphonate & Hữu cơ',
    ),
  ];

  final List<PostItem> _posts = [
    // 1. Featured Post (Card 1)
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
          'author': 'Phan Hải',
          'text': 'Kinh nghiệm nhà mình là pha thêm Phosphonate tưới rễ tơ 2 lần cách nhau 7 ngày.',
          'time': '30 phút trước'
        },
      ],
    ),

    // 2. Normal Post (Card 2)
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

    // 3. Question Card (Card 3)
    PostItem(
      id: 'post-question-3',
      authorName: 'Phan Hải (Nông dân Lâm Đồng)',
      authorRole: 'Thành viên Vie-farm',
      avatarUrl: '',
      timeAgo: '10 phút trước',
      title: 'Hỏi Chuyên Gia: Cây sầu riêng Monthong rụng búp hoa mùa mưa có phải do thiếu Canxi Bột?',
      content:
          'Kính gửi Kỹ sư Vie-farm! Vườn Monthong nhà tôi 6 năm tuổi đang giai đoạn ra búp hoa bằng ngón tay trỏ. Mấy hôm nay mưa dầm búp hoa rụng rải rác dưới gốc...',
      category: 'expert',
      likes: 18,
      isLiked: false,
      comments: [],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _openCreateDiscussionModal(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'pests';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Color(0xFF1E8E4A), size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    'Đăng Bài Thảo Luận Mới',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tiêu đề bài viết (*)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'Nhập tiêu đề ngắn gọn...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Nội dung chi tiết (*)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: contentController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Mô tả chi tiết tình trạng vườn cây...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty || contentController.text.trim().isEmpty) return;
                    setState(() {
                      _posts.insert(
                        0,
                        PostItem(
                          id: 'post-${DateTime.now().millisecondsSinceEpoch}',
                          authorName: 'HH (Bạn)',
                          authorRole: 'Nông dân Vie-farm',
                          avatarUrl: '',
                          timeAgo: 'Vừa xong',
                          title: titleController.text.trim(),
                          content: contentController.text.trim(),
                          category: category,
                          likes: 0,
                          comments: [],
                        ),
                      );
                    });
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Đăng Bài Thảo Luận'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E8E4A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                      // Community Icon Avatar
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

                      // Title & Subtitle Column
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

                      // Notification Bell Button
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
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
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
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.storefront_outlined, size: 15),
                            SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Vựa vật tư',
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
          _buildSuppliesTab(),
        ],
      ),
    );
  }

  // 1. DISCUSSION TAB VIEW
  Widget _buildDiscussionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Create Post Card ("Bạn muốn trao đổi kỹ thuật gì?")
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
              children: [
                // Avatar "HH"
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0B7C3E),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      'HH',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Fake Input button
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openCreateDiscussionModal(context),
                    child: Container(
                      height: 44,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Bạn muốn trao đổi kỹ thuật gì?',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Action Button (Image icon)
                GestureDetector(
                  onTap: () => _openCreateDiscussionModal(context),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E8E4A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.edit_square,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Category Chips Row (Horizontal Scroll)
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildChip('all', 'Tất cả bài viết'),
                      const SizedBox(width: 8),
                      _buildChip('pests', 'Hỏi đáp Sâu bệnh'),
                      const SizedBox(width: 8),
                      _buildChip('techniques', 'Kỹ thuật canh tác'),
                      const SizedBox(width: 8),
                      _buildChip('weather', 'Thời tiết nông vụ'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Filter Icon Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.filter_alt_outlined,
                  color: Color(0xFF1E8E4A),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Posts Feed
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final post = _posts[index];
              if (post.isFeatured) {
                return _buildFeaturedPostCard(post);
              } else if (post.category == 'expert') {
                return _buildQuestionPostCard(post);
              } else {
                return _buildNormalPostCard(post);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E8E4A) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? const Color(0xFF1E8E4A) : const Color(0xFFD1D5DB),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_rounded, color: Colors.white, size: 15),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF374151),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CARD 1: FEATURED POST CARD
  Widget _buildFeaturedPostCard(PostItem post) {
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
          // Featured Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, color: Color(0xFF1E8E4A), size: 14),
                SizedBox(width: 4),
                Text(
                  'Bài viết nổi bật',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E8E4A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal 2-Column Split
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Image Column
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: 110,
                      height: 170,
                      child: Image.asset(
                        'assets/images/post_nguyen_van_hung.jpg',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFE5E7EB),
                          child: const Icon(Icons.park_rounded, color: Color(0xFF1E8E4A), size: 48),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '3 ảnh',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Right Response Column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Author Row
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFF0F8A4C),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Kỹ sư Lê Minh (Vie-farm Verified)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F8A4C),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.more_vert_rounded, color: Color(0xFF9CA3AF), size: 20),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Light Mint Box
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF7F2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        post.expertAnswer ??
                            'Chào anh Hùng! Anh rải vôi bột 500g/gốc rất tốt để nâng pH đất > 6.0 hạn chế nấm Phytophthora bào hòa. Nhớ siết thoát nước mương rãnh nhé!',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF1F2937),
                          height: 1.35,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Footer Stats Row
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        const Text(
                          '2 giờ trước',
                          style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.thumb_up_alt_outlined, size: 13, color: Color(0xFF6B7280)),
                            const SizedBox(width: 2),
                            Text('${post.likes}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                            const SizedBox(width: 6),
                            const Icon(Icons.chat_bubble_outline_rounded, size: 13, color: Color(0xFF6B7280)),
                            const SizedBox(width: 2),
                            Text('${post.comments.length}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                            const SizedBox(width: 6),
                            const Icon(Icons.share_outlined, size: 13, color: Color(0xFF6B7280)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // CARD 2: NORMAL POST CARD
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
          // Header Row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5ED),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    post.authorName.isNotEmpty ? post.authorName[0] : 'T',
                    style: const TextStyle(
                      color: Color(0xFF1E8E4A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert_rounded, color: Color(0xFF9CA3AF), size: 20),
            ],
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          // Content
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF374151),
              height: 1.4,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Gallery (3 horizontal images)
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 105,
                    child: Image.asset(
                      'assets/images/post_tran_thi_thu_ha.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 105,
                    child: Image.asset(
                      'assets/images/post_phan_hai.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 105,
                    child: Image.asset(
                      'assets/images/post_nguyen_thi_mai.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Footer Row (Tag + Likes/Comments)
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5ED),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Kỹ thuật canh tác',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E8E4A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.thumb_up_alt_outlined, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text('${post.likes}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
              const SizedBox(width: 14),
              const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Text('${post.comments.isNotEmpty ? post.comments.length : 8}', style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            ],
          ),
        ],
      ),
    );
  }

  // CARD 3: QUESTION CARD
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
          // Header Row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5ED),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'P',
                    style: TextStyle(
                      color: Color(0xFF1E8E4A),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          '${post.authorRole} • ${post.timeAgo}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5ED),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Hỏi chuyên gia',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E8E4A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.more_vert_rounded, color: Color(0xFF9CA3AF), size: 20),
            ],
          ),
          const SizedBox(height: 12),

          // Large Title
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          // Content snippet
          Text(
            post.content,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF374151),
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 2. EXPERTS TAB VIEW
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
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFE8F5ED),
                child: Text(
                  exp.name[0],
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E8E4A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exp.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exp.title,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '⭐ ${exp.rating} • ${exp.consultationsCount} tư vấn',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E8E4A),
                      ),
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

  // 3. SUPPLIES TAB VIEW
  Widget _buildSuppliesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: const Row(
            children: [
              Icon(Icons.storefront_outlined, color: Color(0xFF1E8E4A), size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vựa Vật Tư Nông Nghiệp Đắk Lắk',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Chuyên NPK, Trichoderma & Phân bón vi sinh',
                      style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
