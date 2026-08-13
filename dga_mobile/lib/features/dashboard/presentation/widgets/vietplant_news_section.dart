import 'package:flutter/material.dart';

class VietplantNewsSection extends StatelessWidget {
  final List<Map<String, dynamic>> articles;
  final VoidCallback? onViewAll;

  const VietplantNewsSection({
    super.key,
    required this.articles,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.newspaper_rounded, color: Color(0xFF2E7D32), size: 20),
                  SizedBox(width: 6),
                  Text(
                    'Điểm tin sầu riêng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B2E25),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onViewAll,
                child: const Row(
                  children: [
                    Text(
                      'Tất cả',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: Color(0xFF2E7D32)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Horizontal News Cards List
        SizedBox(
          height: 255,
          child: articles.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: articles.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final item = articles[index];
                    return _buildNewsCard(context, item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildNewsCard(BuildContext context, Map<String, dynamic> item) {
    final title = item['title'] ?? 'Tin sầu riêng';
    final summary = item['summary'] ?? '';
    final imageUrl = item['image_url'] ?? item['image_path'] ?? 'assets/images/durian_news_daklak.png';
    final category = item['category'] ?? 'Sầu riêng';

    final isAsset = imageUrl.startsWith('assets/');

    return Container(
      width: 230,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Header with Category Tag Overlay
          Stack(
            children: [
              isAsset
                  ? Image.asset(
                      imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 120,
                        color: Colors.green.shade50,
                        child: const Center(
                          child: Icon(Icons.eco, color: Color(0xFF2E7D32), size: 36),
                        ),
                      ),
                    )
                  : Image.network(
                      imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/durian_news_daklak.png',
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Text Content Area (Protected from overflow)
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B2E25),
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text('Đang tải điểm tin sầu riêng...'),
    );
  }
}
