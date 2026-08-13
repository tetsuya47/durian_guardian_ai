import 'package:flutter/material.dart';

class TechniqueItem {
  final String id;
  final String stageId;
  final String stageName;
  final String title;
  final String summary;
  final String fertilizerAdvice;
  final String wateringAdvice;
  final String pestAdvice;
  final List<String> steps;
  final String difficulty;

  const TechniqueItem({
    required this.id,
    required this.stageId,
    required this.stageName,
    required this.title,
    required this.summary,
    required this.fertilizerAdvice,
    required this.wateringAdvice,
    required this.pestAdvice,
    required this.steps,
    required this.difficulty,
  });
}

class FarmingTechniquesPage extends StatefulWidget {
  final String varietyId;
  final String varietyName;

  const FarmingTechniquesPage({
    super.key,
    this.varietyId = 'ri6',
    this.varietyName = 'Sầu riêng Ri6',
  });

  @override
  State<FarmingTechniquesPage> createState() => _FarmingTechniquesPageState();
}

class _FarmingTechniquesPageState extends State<FarmingTechniquesPage> {
  String _selectedStage = 'all';

  static const List<Map<String, String>> growthStages = [
    {'id': 'all', 'label': 'Tất cả giai đoạn'},
    {'id': 'stage_1', 'label': '🌱 Cây con (1 - 3 năm)'},
    {'id': 'stage_2', 'label': '🌿 Cây kiến thiết (3 - 5 năm)'},
    {'id': 'stage_3', 'label': '🌸 Xử lý ra hoa (Kinh doanh)'},
    {'id': 'stage_4', 'label': '🍈 Nuôi trái & Đậu trái'},
    {'id': 'stage_5', 'label': '🍂 Phục hồi sau thu hoạch'},
  ];

  final List<TechniqueItem> _techniques = const [
    // Stage 1: Cây con 1-3 năm
    TechniqueItem(
      id: 'tech_1',
      stageId: 'stage_1',
      stageName: 'Cây con (1 - 3 năm)',
      title: 'Kỹ thuật định hình tỉa cành tạo tán giai đoạn cây con',
      summary: 'Tạo khung cành lực cho sầu riêng ngay từ 1-3 năm đầu, giúp cành mọc ngang 90 độ mang trái tốt.',
      fertilizerAdvice: 'Bón NPK 20-10-10 hoặc 16-16-8 kết hợp phân hữu cơ nở (2-3kg/gốc/năm).',
      wateringAdvice: 'Tưới giữ ẩm 2 ngày/lần. Mùa khô tưới 30-50 lít/cây/lần.',
      pestAdvice: 'Phòng rầy nhảy, sâu ăn lá, nấm thối rễ Phytophthora bằng Trichoderma.',
      steps: [
        'Giữ lại cành chính vuông góc với thân chính.',
        'Cắt bỏ cành vượt, cành mọc ngược vào trong thân.',
        'Cố định cành xòe đều 4 hướng bằng dây chằng nhẹ.'
      ],
      difficulty: 'Cơ bản',
    ),
    TechniqueItem(
      id: 'tech_2',
      stageId: 'stage_1',
      stageName: 'Cây con (1 - 3 năm)',
      title: 'Bón phân hữu cơ vi sinh & Chăm sóc bộ rễ',
      summary: 'Phát triển hệ rễ tơ khỏe mạnh, tăng sức đề kháng cho cây sầu riêng con.',
      fertilizerAdvice: 'Bón phân chuồng hoai mục + Trichoderma 5kg/gốc/lần (2 lần/năm).',
      wateringAdvice: 'Duy trì độ ẩm đất 60-70%, tránh úng nước gốc.',
      pestAdvice: 'Tưới Humic + Ridomil Gold định kỳ 3 tháng/lần.',
      steps: [
        'Xới nhẹ đất quanh tán lá, tránh đứt rễ chính.',
        'Rải đều phân hữu cơ nở xung quanh hình chiếu tán lá.',
        'Tưới đẫm nước sau khi bón phân 1-2 giờ.'
      ],
      difficulty: 'Cơ bản',
    ),

    // Stage 2: Cây kiến thiết 3-5 năm
    TechniqueItem(
      id: 'tech_3',
      stageId: 'stage_2',
      stageName: 'Cây kiến thiết (3 - 5 năm)',
      title: 'Quản lý cơi đọt & Làm thuần thục cơi lá',
      summary: 'Giúp lá xanh dày, cơi đọt mập mạp chuẩn bị cho lứa trái đầu tiên.',
      fertilizerAdvice: 'Bón NPK 15-15-15 kết hợp xịt Amino Acid + Vi lượng qua lá.',
      wateringAdvice: 'Tưới định kỳ 3 ngày/lần tùy thuộc vào độ ẩm thời tiết.',
      pestAdvice: 'Phun thuốc ngừa rầy bông, rệp sáp khi đọt mới nhú hình mầm hạt gạo.',
      steps: [
        'Theo dõi khi cơi đọt mới nhú 1-2cm.',
        'Phun xịt phân bón lá vi lượng + Amino dưỡng đọt.',
        'Khi lá chuyển sang bánh tẻ, chuẩn bị cho cơi đọt tiếp theo.'
      ],
      difficulty: 'Trung bình',
    ),

    // Stage 3: Xử lý ra hoa
    TechniqueItem(
      id: 'tech_4',
      stageId: 'stage_3',
      stageName: 'Xử lý ra hoa (Kinh doanh)',
      title: 'Kỹ thuật xiết nước & Tạo mầm hoa sầu riêng',
      summary: 'Kích thích tạo mầm hoa (mắt cua) đồng loạt, đạt tỷ lệ đậu hoa cao.',
      fertilizerAdvice: 'Phun MKP (0-52-34) + 10-60-10 kích mầm hoa 2 lần cách nhau 7 ngày.',
      wateringAdvice: 'Cắt nước hoàn toàn 15-20 ngày cho đến khi nhú mắt cua 2-3cm.',
      pestAdvice: 'Phun phòng thán thư hoa, rầy nhện đỏ.',
      steps: [
        'Dọn sạch cỏ dại quanh mô gốc cây.',
        'Xiết nước tạo khô hạn cho đất.',
        'Khi mắt cua sáng 2-3cm, nhấp nước nhẹ 1/3 lượng bình thường.'
      ],
      difficulty: 'Nâng cao',
    ),

    // Stage 4: Nuôi trái & Đậu trái
    TechniqueItem(
      id: 'tech_5',
      stageId: 'stage_4',
      stageName: 'Nuôi trái & Đậu trái',
      title: 'Tỉa bớt trái lứa & Bổ sung Canxi-Bo chống rụng trái',
      summary: 'Giúp trái phát triển tròn đều, không bị méo trái, hạn chế tối đa rụng trái non.',
      fertilizerAdvice: 'Bón NPK 12-12-17 hoặc 15-5-20 + Kali Sunfat nuôi cơm trái.',
      wateringAdvice: 'Tưới nước đều đặn mỗi ngày, tránh để đất quá khô rồi tưới dồn đột ngột.',
      pestAdvice: 'Phòng sâu đục trái, bọ xít muỗi và rệp sáp bám gai trái.',
      steps: [
        'Tỉa bỏ trái chùm méo chột, trái đít nhọn.',
        'Chỉ giữ lại 80-120 trái/cây tùy sức cây.',
        'Phun Canxi-Bo định kỳ 10 ngày/lần.'
      ],
      difficulty: 'Nâng cao',
    ),

    // Stage 5: Phục hồi sau thu hoạch
    TechniqueItem(
      id: 'tech_6',
      stageId: 'stage_5',
      stageName: 'Phục hồi sau thu hoạch',
      title: 'Rửa vườn & Phục hồi bộ rễ sau cắt trái',
      summary: 'Rửa sạch nấm bệnh trong vườn, giúp cây lấy lại sức cho vụ mùa tiếp theo.',
      fertilizerAdvice: 'Bón vôi nông nghiệp 2-3kg/gốc + Phân hữu cơ hoai mục 15-20kg/gốc.',
      wateringAdvice: 'Tưới đẫm nước giúp xả độc tồn dư phân bón cũ.',
      pestAdvice: 'Phun Copper Hydroxide hoặc Ridomil Gold rửa tán cây.',
      steps: [
        'Cắt tỉa cành khô, cành sâu bệnh, cành mang trái cũ.',
        'Rải vôi bột hạ phèn quanh gốc.',
        'Tưới Trichoderma + Humic kích rễ mới.'
      ],
      difficulty: 'Trung bình',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredTechniques = _selectedStage == 'all'
        ? _techniques
        : _techniques.where((t) => t.stageId == _selectedStage).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Kỹ Thuật Canh Tác: ${widget.varietyName}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Growth Stage Filter Chips Header ("từ nhỏ đến lớn")
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Bộ lọc giai đoạn phát triển (từ nhỏ đến lớn):',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: growthStages.length,
                    itemBuilder: (context, index) {
                      final stage = growthStages[index];
                      final isSelected = _selectedStage == stage['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(stage['label']!),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _selectedStage = stage['id']!;
                            });
                          },
                          selectedColor: const Color(0xFF4CAF50),
                          backgroundColor: Colors.grey.shade100,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF555555),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Filtered Techniques List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: filteredTechniques.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final item = filteredTechniques[index];
                return _buildTechniqueCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniqueCard(TechniqueItem item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Badge Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.stageName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Độ khó: ${item.difficulty}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),

          // Summary
          Text(
            item.summary,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              height: 1.3,
            ),
          ),
          const Divider(height: 24, thickness: 0.8),

          // Advice Cards Grid (Bón phân, Tưới nước, Sâu bệnh)
          _buildInfoRow(Icons.science_outlined, 'Bón phân', item.fertilizerAdvice, Colors.green),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.water_drop_outlined, 'Tưới nước', item.wateringAdvice, Colors.blue),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.bug_report_outlined, 'Phòng sâu bệnh', item.pestAdvice, Colors.orange),
          const SizedBox(height: 14),

          // Steps list
          const Text(
            'Các bước thực hiện chuẩn:',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF333333)),
          ),
          const SizedBox(height: 6),
          Column(
            children: item.steps.map((step) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        step,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF444444)),
          ),
        ),
      ],
    );
  }
}
