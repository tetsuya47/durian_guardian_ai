import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_api_client.dart';

class NewsArticleItem {
  final String id;
  final String title;
  final String summary;
  final String content;
  final String imageUrl;
  final String category;
  final String region;
  final String source;
  final bool isFeatured;
  final String? createdAt;

  const NewsArticleItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.content,
    required this.imageUrl,
    required this.category,
    required this.region,
    required this.source,
    required this.isFeatured,
    this.createdAt,
  });

  factory NewsArticleItem.fromJson(Map<String, dynamic> json) {
    return NewsArticleItem(
      id: json['_id']?.toString() ?? '',
      title: json['title'] ?? 'Tin tức sầu riêng',
      summary: json['summary'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image_url'] ??
          'https://images.unsplash.com/photo-1592417817098-8f3d6eb19655?auto=format&fit=crop&w=600&q=80',
      category: json['category'] ?? 'Tin mới',
      region: json['region'] ?? 'Toàn quốc',
      source: json['source'] ?? 'Ban biên tập Durian Guardian',
      isFeatured: json['is_featured'] == true,
      createdAt: json['created_at']?.toString(),
    );
  }
}

final durianNewsListProvider = FutureProvider<List<NewsArticleItem>>((ref) async {
  final client = ref.watch(dioApiClientProvider);
  final response = await client.request<List<NewsArticleItem>>(
    path: '/news',
    method: 'GET',
    decoder: (json) {
      if (json is List) {
        return json.map((e) => NewsArticleItem.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    },
  );
  return response.data ?? [];
});

class DurianNewsPage extends ConsumerStatefulWidget {
  const DurianNewsPage({super.key});

  @override
  ConsumerState<DurianNewsPage> createState() => _DurianNewsPageState();
}

class _DurianNewsPageState extends ConsumerState<DurianNewsPage> {
  String _searchQuery = '';
  String _selectedFilter = 'all';

  final List<_FilterTab> _filterTabs = const [
    _FilterTab(id: 'all', label: 'Tất cả tin tức'),
    _FilterTab(id: 'xuat_khau', label: '🌍 Xuất khẩu & Thị trường'),
    _FilterTab(id: 'tay_nguyen', label: '📍 Tây Nguyên (Đắk Lắk, Lâm Đồng)'),
    _FilterTab(id: 'dbscl', label: '📍 ĐBSCL (Tiền Giang, Bến Tre)'),
    _FilterTab(id: 'dong_nam_bo', label: '📍 Đông Nam Bộ (Bình Phước)'),
    _FilterTab(id: 'ky_thuat', label: '🌱 Kỹ thuật canh tác'),
    _FilterTab(id: 'kiem_dich', label: '🛡️ Kiểm dịch & Mã số vùng trồng'),
  ];

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(durianNewsListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Tin Tức & Thị Trường Sầu Riêng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2E7D32),
        onRefresh: () async => ref.refresh(durianNewsListProvider),
        child: Column(
          children: [
            // Search & Filter Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  // Search Input Box
                  Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: const InputDecoration(
                        hintText: 'Tìm kiếm tin tức, vùng trồng, xuất khẩu...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 13.5),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF2E7D32), size: 22),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Horizontal Filter Chips
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filterTabs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final tab = _filterTabs[index];
                        final isSelected = _selectedFilter == tab.id;
                        return FilterChip(
                          label: Text(tab.label),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _selectedFilter = tab.id),
                          selectedColor: const Color(0xFF2E7D32),
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF444444),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 12.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade300,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // News List View
            Expanded(
              child: newsAsync.when(
                data: (articles) {
                  final filtered = articles.where((a) {
                    final query = _searchQuery.toLowerCase();
                    final matchesSearch = query.isEmpty ||
                        a.title.toLowerCase().contains(query) ||
                        a.summary.toLowerCase().contains(query) ||
                        a.content.toLowerCase().contains(query) ||
                        a.region.toLowerCase().contains(query) ||
                        a.category.toLowerCase().contains(query) ||
                        a.source.toLowerCase().contains(query);

                    bool matchesCategory = true;
                    if (_selectedFilter == 'xuat_khau') {
                      matchesCategory = a.category.toLowerCase().contains('xuất') ||
                          a.title.toLowerCase().contains('xuất khẩu') ||
                          a.region.toLowerCase().contains('xuất khẩu');
                    } else if (_selectedFilter == 'tay_nguyen') {
                      matchesCategory = a.region.toLowerCase().contains('tây nguyên') ||
                          a.region.toLowerCase().contains('đắk lắk') ||
                          a.region.toLowerCase().contains('lâm đồng') ||
                          a.region.toLowerCase().contains('gia lai');
                    } else if (_selectedFilter == 'dbscl') {
                      matchesCategory = a.region.toLowerCase().contains('đbscl') ||
                          a.region.toLowerCase().contains('tiền giang') ||
                          a.region.toLowerCase().contains('bến tre') ||
                          a.region.toLowerCase().contains('cần thơ');
                    } else if (_selectedFilter == 'dong_nam_bo') {
                      matchesCategory = a.region.toLowerCase().contains('đông nam bộ') ||
                          a.region.toLowerCase().contains('bình phước') ||
                          a.region.toLowerCase().contains('đồng nai');
                    } else if (_selectedFilter == 'ky_thuat') {
                      matchesCategory = a.category.toLowerCase().contains('kỹ thuật') ||
                          a.title.toLowerCase().contains('kỹ thuật') ||
                          a.summary.toLowerCase().contains('tưới');
                    } else if (_selectedFilter == 'kiem_dich') {
                      matchesCategory = a.category.toLowerCase().contains('kiểm dịch') ||
                          a.title.toLowerCase().contains('mã số vùng trồng') ||
                          a.title.toLowerCase().contains('gacc');
                    }

                    return matchesSearch && matchesCategory;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildArticleCard(context, item);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        const Text('Không thể tải tin tức lúc này', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => ref.refresh(durianNewsListProvider),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                          child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticleCard(BuildContext context, NewsArticleItem item) {
    return InkWell(
      onTap: () => _showArticleDetail(context, item),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image with Badges
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    item.imageUrl,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: const Color(0xFFE8F5E9),
                      child: const Center(
                        child: Icon(Icons.article, size: 48, color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.amberAccent, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          item.region,
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B2E25),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 6),

            // Summary
            Text(
              item.summary,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 8),

            // Source & Read More Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF2E7D32), size: 15),
                    const SizedBox(width: 4),
                    Text(
                      item.source,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const Row(
                  children: [
                    Text(
                      'Đọc chi tiết',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 18, color: Color(0xFF2E7D32)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showArticleDetail(BuildContext context, NewsArticleItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.88,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              children: [
                // Top drag handle
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),

                // Article Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category & Region Tag
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.category,
                                style: const TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '📍 ${item.region}',
                                style: TextStyle(
                                  color: Colors.orange.shade900,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2E25),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Source & Date
                        Row(
                          children: [
                            const Icon(Icons.newspaper, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              'Nguồn: ${item.source}',
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Article Cover Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            item.imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Highlighted Summary Box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F8E9),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFC5E1A5)),
                          ),
                          child: Text(
                            item.summary,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32),
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Full Article Content
                        Text(
                          item.content,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF333333),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 54, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'Không tìm thấy tin tức phù hợp',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'Vui lòng thử tìm kiếm với từ khóa khác',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterTab {
  final String id;
  final String label;

  const _FilterTab({required this.id, required this.label});
}
