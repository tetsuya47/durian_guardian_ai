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
  final String category; // 'pests', 'techniques', 'expert'
  final bool isExpertAnswered;
  final String? expertAnswer;
  final String? expertName;
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
    required this.category,
    this.isExpertAnswered = false,
    this.expertAnswer,
    this.expertName,
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
  String _selectedCategory = 'all'; // 'all', 'pests', 'techniques'
  final Map<String, TextEditingController> _commentControllers = {};
  final Map<String, bool> _expandedComments = {};

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
    ExpertModel(
      id: 'exp-4',
      name: 'Kỹ sư Võ Văn Nam',
      title: 'Chuyên gia Kỹ thuật Làm Bông & Tạo Tán',
      workplace: 'Hiệp hội Sầu Riêng Việt Nam',
      experience: '15 năm kinh nghiệm',
      consultationsCount: 860,
      rating: 4.8,
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
      isOnline: false,
      specialty: 'Xử lý ra hoa đồng loạt, Tỉa cành & Nuôi cơm',
    ),
  ];

  final List<PostItem> _posts = [
    PostItem(
      id: 'post-expert-1',
      authorName: 'Phan Hải (Nông dân Lâm Đồng)',
      authorRole: 'Thành viên Vườn Sầu Riêng',
      avatarUrl: '',
      timeAgo: '10 phút trước',
      title: 'Hỏi Chuyên Gia: Cây sầu riêng Monthong rụng búp hoa mùa mưa có phải do thiếu Canxi Bột?',
      content:
          'Kính gửi Kỹ sư Vie-farm! Vườn Monthong nhà tôi 6 năm tuổi đang giai đoạn ra búp hoa bằng ngón tay trỏ. Mấy hôm nay mưa dầm búp hoa rụng rải rác dưới gốc. Cho tôi hỏi đây là do tháo nước kém hay thiếu Canxi-Bo ạ?',
      imageUrl: 'https://images.unsplash.com/photo-1595855759920-86582396756a?w=600',
      category: 'expert',
      isExpertAnswered: true,
      expertName: 'ThS. Nguyễn Văn Đức (Chuyên Gia Vie-farm)',
      expertAnswer:
          '🌱 **CỐ VẤN TỪ CHUYÊN GIA VIE-FARM:**\nChào anh Hải! Hiện tượng rụng búp hoa mùa mưa có 2 nguyên nhân chính:\n1. Tình trạng sốc nước do mưa dầm đột ngột làm dư Đạm tự nhiên trong nước mưa.\n2. Thiếu hụt Canxi-Bo làm cuống hoa yếu dễ gãy.\n👉 **Khắc phục ngay:** Phun Canxi-Bo dạng Chelate kết hợp Siêu Bo Dạng Sữa 5-7 ngày/lần. Khai thông rãnh thoát nước không để đọng nước quanh hình chiếu tán!',
      likes: 42,
      isLiked: true,
      comments: [
        {
          'author': 'Lê Văn Tám (Đắk Lắk)',
          'text': 'Cảm ơn Kỹ sư Đức đã tư vấn rất chi tiết! Vườn em cũng vừa làm theo công thức này đứng rụng hoa ngay.',
          'time': '5 phút trước'
        },
      ],
    ),
    PostItem(
      id: 'post-1',
      authorName: 'Nguyễn Văn Hùng',
      authorRole: 'Nông dân Đắk Lắk (500 gốc sầu)',
      avatarUrl: '',
      timeAgo: '2 giờ trước',
      title: 'Hỏi kinh nghiệm xử lý xì mủ gốc mùa mưa Tây Nguyên',
      content:
          'Chào mọi người! Vườn sầu riêng Ri6 5 năm tuổi của mình mấy hôm nay mưa nhiều phát hiện 2 cây bị xì mủ thâm đen ở gốc. Mình đã cạo sạch và quét Ridomil Gold, cho hỏi có nên rải thêm vôi bột xung quanh gốc không ạ?',
      imageUrl: 'https://images.unsplash.com/photo-1595855759920-86582396756a?w=600',
      category: 'pests',
      isExpertAnswered: true,
      expertName: 'Kỹ sư Lê Minh (Vie-farm Verified)',
      expertAnswer:
          'Chào anh Hùng! Anh rải vôi bột 500g/gốc rất tốt để nâng pH đất > 6.0 hạn chế nấm Phytophthora bão hòa. Nhớ siết thoát nước mương rãnh nhé!',
      likes: 24,
      isLiked: false,
      comments: [
        {
          'author': 'Phan Hải (Chủ vườn Lâm Đồng)',
          'text':
              'Kinh nghiệm nhà mình là pha thêm Phosphonate tưới rễ tơ 2 lần cách nhau 7 ngày là đứng vết bệnh ngay.',
          'time': '30 phút trước'
        },
      ],
    ),
    PostItem(
      id: 'post-2',
      authorName: 'Trần Thị Thu Hà',
      authorRole: 'Chủ vườn Tiền Giang',
      avatarUrl: '',
      timeAgo: '5 giờ trước',
      title: 'Kinh nghiệm bón phân NPK kết hợp Kali Sunfat nuôi cơm Monthong',
      content:
          'Chia sẻ với bà con: Giai đoạn quả 70 ngày mình bón NPK 15-15-15 kết hợp K2SO4 tỉ lệ 2:1 cơm sầu riêng lên màu vàng rất đẹp, ngọt đậm và hạt lép rõ rệt. Ảnh chụp thực tế cơm quả vườn nhà mình đây ạ!',
      imageUrl: 'https://images.unsplash.com/photo-1546548970-71785318a17b?w=600',
      category: 'techniques',
      likes: 56,
      isLiked: true,
      comments: [
        {
          'author': 'Võ Văn Nam',
          'text': 'Trái Monthong nhìn mê quá chị ơi! Cho em hỏi tỷ lệ bón cho mỗi gốc bao nhiêu gam vậy ạ?',
          'time': '3 giờ trước'
        },
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var controller in _commentControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _openAskExpertModal(BuildContext context, {ExpertModel? targetExpert}) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String? selectedImage = 'https://images.unsplash.com/photo-1595855759920-86582396756a?w=600';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.88,
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
              // Handle bar
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

              // Title Header
              Row(
                children: [
                  const Icon(Icons.verified, color: Color(0xFF2E7D32), size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      targetExpert != null
                          ? 'Gửi Câu Hỏi Cho ${targetExpert.name}'
                          : 'Đặt Câu Hỏi Cho Chuyên Gia Vie-farm',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
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
                      if (targetExpert != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFC8E6C9)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(targetExpert.avatarUrl),
                                radius: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      targetExpert.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B4D3E),
                                      ),
                                    ),
                                    Text(
                                      targetExpert.title,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Title Input
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'Tiêu đề câu hỏi (Ví dụ: Hỏi chẩn đoán nấm lá sầu riêng...)',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFF7FAF8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFD0E1D4)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Content Input
                      TextField(
                        controller: contentController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Mô tả chi tiết triệu chứng bệnh, tuổi vườn sầu riêng và phân bón đã sử dụng để Chuyên gia chẩn đoán...',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFF7FAF8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFD0E1D4)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Image attachment preview
                      if (selectedImage != null) ...[
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                selectedImage!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: InkWell(
                                onTap: () => setModalState(() => selectedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Add Photo Button
                      OutlinedButton.icon(
                        onPressed: () {
                          setModalState(() {
                            selectedImage =
                                'https://images.unsplash.com/photo-1595855759920-86582396756a?w=600';
                          });
                        },
                        icon: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF2E7D32)),
                        label: const Text(
                          'Đính kèm ảnh thực tế lá / thân cây bị bệnh',
                          style: TextStyle(color: Color(0xFF2E7D32)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2E7D32)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty ||
                        contentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung!'),
                        ),
                      );
                      return;
                    }

                    final expertNameStr = targetExpert?.name ?? 'ThS. Nguyễn Văn Đức (Chuyên Gia Vie-farm)';

                    setState(() {
                      _posts.insert(
                        0,
                        PostItem(
                          id: 'post-${DateTime.now().millisecondsSinceEpoch}',
                          authorName: 'Phan Hải (Bạn)',
                          authorRole: 'Nông dân Vie-farm',
                          avatarUrl: '',
                          timeAgo: 'Vừa xong',
                          title: titleController.text.trim(),
                          content: contentController.text.trim(),
                          imageUrl: selectedImage,
                          category: 'expert',
                          isExpertAnswered: true,
                          expertName: expertNameStr,
                          expertAnswer:
                              '🌱 **CỐ VẤN TỪ CHUYÊN GIA VIE-FARM:**\nChào anh Hải! $expertNameStr đã tiếp nhận câu hỏi của anh. Kỹ sư đang phân tích hình ảnh đính kèm & thông số môi trường vườn nhà anh. Phác đồ điều trị sẽ được gửi cho anh trong ít phút!',
                          likes: 1,
                          isLiked: true,
                          comments: [],
                        ),
                      );
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('👨‍🌾 Đã gửi câu hỏi trực tiếp cho $expertNameStr thành công!'),
                        backgroundColor: const Color(0xFF2E7D32),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Gửi Câu Hỏi Cho Chuyên Gia'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openCreateDiscussionModal(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'pests';
    String? selectedImage = 'https://images.unsplash.com/photo-1546548970-71785318a17b?w=600';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.88,
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
                  const Icon(Icons.chat_bubble_outline, color: Color(0xFF2E7D32), size: 28),
                  const SizedBox(width: 10),
                  const Text(
                    'Đăng Bài Thảo Luận Mới',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B4D3E),
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
                        'Chọn chủ đề bài viết (*)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E35),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Hỏi đáp Sâu bệnh'),
                            selected: category == 'pests',
                            onSelected: (val) {
                              if (val) setModalState(() => category = 'pests');
                            },
                            selectedColor: const Color(0xFF2E7D32),
                            labelStyle: TextStyle(
                              color: category == 'pests' ? Colors.white : const Color(0xFF2E7D32),
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Kỹ thuật Canh tác'),
                            selected: category == 'techniques',
                            onSelected: (val) {
                              if (val) setModalState(() => category = 'techniques');
                            },
                            selectedColor: const Color(0xFF2E7D32),
                            labelStyle: TextStyle(
                              color: category == 'techniques' ? Colors.white : const Color(0xFF2E7D32),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: 'Tiêu đề bài thảo luận (Ví dụ: Kinh nghiệm bón phân...)',
                          hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFF7FAF8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFD0E1D4)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextField(
                        controller: contentController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Chia sẻ kinh nghiệm hoặc thảo luận cùng bà con nông dân...',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          filled: true,
                          fillColor: const Color(0xFFF7FAF8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFD0E1D4)),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (selectedImage != null) ...[
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(
                                selectedImage!,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: InkWell(
                                onTap: () => setModalState(() => selectedImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      OutlinedButton.icon(
                        onPressed: () {
                          setModalState(() {
                            selectedImage =
                                'https://images.unsplash.com/photo-1546548970-71785318a17b?w=600';
                          });
                        },
                        icon: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF2E7D32)),
                        label: const Text(
                          'Đính kèm hình ảnh vườn sầu riêng',
                          style: TextStyle(color: Color(0xFF2E7D32)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF2E7D32)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty ||
                        contentController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung!'),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      _posts.insert(
                        0,
                        PostItem(
                          id: 'post-${DateTime.now().millisecondsSinceEpoch}',
                          authorName: 'Phan Hải (Bạn)',
                          authorRole: 'Nông dân Vie-farm',
                          avatarUrl: '',
                          timeAgo: 'Vừa xong',
                          title: titleController.text.trim(),
                          content: contentController.text.trim(),
                          imageUrl: selectedImage,
                          category: category,
                          likes: 1,
                          isLiked: true,
                          comments: [],
                        ),
                      );
                    });

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Đã đăng bài viết thảo luận thành công!'),
                        backgroundColor: Color(0xFF2E7D32),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Đăng Bài Thảo Luận'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addComment(PostItem post, String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      post.comments.add({
        'author': 'Phan Hải (Bạn)',
        'text': text.trim(),
        'time': 'Vừa xong',
      });
      _commentControllers[post.id]?.clear();
    });
  }

  // 1. Tab Thảo Luận Cộng Đồng View
  Widget _buildCommunityDiscussionView() {
    final filteredPosts = _posts.where((p) {
      if (_selectedCategory == 'all') return true;
      return p.category == _selectedCategory;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Creator Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0EFE7)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withAlpha(10),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE8F5E9),
                  child: Icon(Icons.person, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _openCreateDiscussionModal(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAF8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFD0E1D4)),
                      ),
                      child: const Text(
                        'Bạn muốn trao đổi kỹ thuật hoặc hỏi bệnh gì hôm nay?',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF2E7D32)),
                  onPressed: () => _openCreateDiscussionModal(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('all', 'Tất cả bài viết'),
                const SizedBox(width: 8),
                _buildCategoryChip('pests', 'Hỏi đáp Sâu bệnh'),
                const SizedBox(width: 8),
                _buildCategoryChip('techniques', 'Kỹ thuật Canh tác'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Feed Posts List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredPosts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final post = filteredPosts[index];
              _commentControllers.putIfAbsent(post.id, () => TextEditingController());
              final isExpanded = _expandedComments[post.id] ?? false;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post Header
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: const Color(0xFFE8F5E9),
                          child: Text(
                            post.authorName.isNotEmpty ? post.authorName[0] : 'U',
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1B4D3E),
                                ),
                              ),
                              Text(
                                '${post.authorRole} • ${post.timeAgo}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Title & Content
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E35),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        height: 1.4,
                      ),
                    ),

                    // Attached Image
                    if (post.imageUrl != null) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          post.imageUrl!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ],

                    // Verified Expert Answer Box if present
                    if (post.isExpertAnswered && post.expertAnswer != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified, color: Color(0xFF2E7D32), size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    post.expertName ?? 'Chuyên Gia Vie-farm (Verified)',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B4D3E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              post.expertAnswer!,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey.shade900,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 8),

                    // Action Bar (Like, Comment, Share)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        InkWell(
                          onTap: () {
                            setState(() {
                              post.isLiked = !post.isLiked;
                              post.isLiked ? post.likes++ : post.likes--;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  post.isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: post.isLiked ? Colors.red : Colors.grey,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${post.likes}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: post.isLiked ? Colors.red : Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _expandedComments[post.id] = !isExpanded;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.chat_bubble_outline,
                                    color: Colors.grey, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  '${post.comments.length} Bình luận',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Đã sao chép liên kết bài thảo luận!')),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: Row(
                              children: [
                                Icon(Icons.share_outlined, color: Colors.grey, size: 20),
                                SizedBox(width: 6),
                                Text('Chia sẻ',
                                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Expanded Comments Section
                    if (isExpanded) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),

                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: post.comments.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, cIdx) {
                          final comment = post.comments[cIdx];
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7FAF8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      comment['author']!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1B4D3E),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      comment['time']!,
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  comment['text']!,
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 10),

                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentControllers[post.id],
                              decoration: InputDecoration(
                                hintText: 'Viết bình luận...',
                                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                filled: true,
                                fillColor: const Color(0xFFF7FAF8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(color: Color(0xFFD0E1D4)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.send, color: Color(0xFF2E7D32)),
                            onPressed: () {
                              final text = _commentControllers[post.id]?.text ?? '';
                              _addComment(post, text);
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // 2. Tab Hỏi Đáp Chuyên Gia View (Expert Directory & Direct Consultation)
  Widget _buildAskExpertView() {
    final expertPosts = _posts.where((p) => p.category == 'expert').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1B4D3E), Color(0xFF2E7D32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withAlpha(40),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent, color: Colors.amber, size: 36),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đội Ngũ Chuyên Gia Nông Nghiệp Vie-farm',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Chọn Chuyên gia để đặt câu hỏi trực tiếp & nhận phác đồ chẩn đoán bệnh 24/7',
                        style: TextStyle(fontSize: 11.5, color: Colors.white70, height: 1.3),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _openAskExpertModal(context),
                        icon: const Icon(Icons.help_center_outlined, size: 16),
                        label: const Text('Đặt câu hỏi cho Chuyên gia'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          foregroundColor: Colors.black87,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section Title: Expert Directory
          const Row(
            children: [
              Icon(Icons.badge_outlined, color: Color(0xFF2E7D32), size: 22),
              SizedBox(width: 8),
              Text(
                'Danh Sách Chuyên Gia Sẵn Sàng Tư Vấn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Expert Directory Cards List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _experts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final expert = _experts[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE0EFE7)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(6),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 26,
                              backgroundImage: NetworkImage(expert.avatarUrl),
                            ),
                            if (expert.isOnline)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    expert.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B4D3E),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified, color: Colors.blue, size: 16),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                expert.title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF2E7D32),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                expert.workplace,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7FAF8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${expert.rating}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.chat, color: Color(0xFF2E7D32), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${expert.consultationsCount} ca tư vấn',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const Spacer(),
                          Text(
                            expert.experience,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF33691E),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      '🎯 Chuyên môn: ${expert.specialty}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _openAskExpertModal(context, targetExpert: expert),
                        icon: const Icon(Icons.contact_support_outlined, size: 16),
                        label: Text('Hỏi ý kiến ${expert.name}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Section Title: Answered Expert Q&A History
          const Row(
            children: [
              Icon(Icons.question_answer_outlined, color: Color(0xFF2E7D32), size: 22),
              SizedBox(width: 8),
              Text(
                'Các Câu Hỏi Đã Được Chuyên Gia Giải Đáp',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B4D3E),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: expertPosts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final post = expertPosts[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.help_outline, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            post.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bởi: ${post.authorName} • ${post.timeAgo}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      post.content,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade800),
                    ),
                    if (post.isExpertAnswered && post.expertAnswer != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFC8E6C9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified, color: Color(0xFF2E7D32), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  post.expertName ?? 'Chuyên Gia Vie-farm (Verified)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B4D3E),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              post.expertAnswer!,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade900),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String key, String label) {
    final isSelected = _selectedCategory == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategory = key;
          });
        }
      },
      selectedColor: const Color(0xFF2E7D32),
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : const Color(0xFF2E7D32),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      side: const BorderSide(color: Color(0xFFC8E6C9)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4D3E),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.groups, color: Color(0xFFA5D6A7)),
            SizedBox(width: 10),
            Text(
              'Cộng Đồng Sầu Riêng Vie-farm',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          indicatorWeight: 3,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              icon: Icon(Icons.chat_bubble_outline),
              text: '💬 Thảo Luận Cộng Đồng',
            ),
            Tab(
              icon: Icon(Icons.support_agent),
              text: '👨‍⚕️ Hỏi Đáp Chuyên Gia',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCommunityDiscussionView(),
          _buildAskExpertView(),
        ],
      ),
    );
  }
}
