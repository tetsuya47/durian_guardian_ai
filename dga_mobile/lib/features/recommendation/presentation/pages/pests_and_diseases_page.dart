import 'package:flutter/material.dart';

class DiseaseRecord {
  final String id;
  final String name;
  final String scientificName;
  final String riskLevel; // 'Cao', 'Trung bình', 'Thấp'
  final Color riskColor;
  final String recentYears;
  final String affectedRegions;
  final String symptoms;
  final String culturalPrevention;
  final String biologicalPrevention;
  final String chemicalTreatment;
  final String activeIngredients;
  final String spraySchedule;

  const DiseaseRecord({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.riskLevel,
    required this.riskColor,
    required this.recentYears,
    required this.affectedRegions,
    required this.symptoms,
    required this.culturalPrevention,
    required this.biologicalPrevention,
    required this.chemicalTreatment,
    required this.activeIngredients,
    required this.spraySchedule,
  });
}

class PestsAndDiseasesPage extends StatefulWidget {
  final String varietyId;
  final String varietyName;

  const PestsAndDiseasesPage({
    super.key,
    this.varietyId = 'ri6',
    this.varietyName = 'Sầu riêng Ri6',
  });

  @override
  State<PestsAndDiseasesPage> createState() => _PestsAndDiseasesPageState();
}

class _PestsAndDiseasesPageState extends State<PestsAndDiseasesPage> {
  String _searchQuery = '';
  String _selectedYearFilter = 'all';

  final List<DiseaseRecord> _diseases = const [
    DiseaseRecord(
      id: 'dis_1',
      name: 'Nấm Nứt Thân Xì Mủ & Thối Rễ',
      scientificName: 'Phytophthora palmivora',
      riskLevel: 'Nguy cơ rất cao',
      riskColor: Colors.red,
      recentYears: '2024 - 2026',
      affectedRegions: 'Tây Nguyên (Đắk Lắk, Lâm Đồng: tỷ lệ 35%), ĐBSCL (Tiền Giang, Bến Tre: 28%)',
      symptoms: 'Thân cây nứt rãnh rỉ mủ màu nâu đen, vỏ thân thối mục. Rễ tơ chuyển đen, lá vàng úa và rụng đồng loạt từ dưới lên.',
      culturalPrevention: 'Đào rãnh thoát nước sâu 50-70cm trong mùa mưa. Tỉa cành thông thoáng cách mặt đất 0.8-1m. Quét vôi bột + đồng đỏ quanh gốc 2 lần/năm.',
      biologicalPrevention: 'Tưới nấm đối kháng Trichoderma hazianum + Bacillus subtilis định kỳ 2 tháng/lần vào gốc.',
      chemicalTreatment: 'Cạo sạch vết xì mủ đến phần gỗ lành, quét trực tiếp thuốc đặc trị. Kết hợp tưới sục gốc.',
      activeIngredients: 'Fosetyl-Aluminium (Aliette), Metalaxyl-M, Dimethomorph, Propamocarb.',
      spraySchedule: 'Phun 2-3 lần cách nhau 7 ngày khi chớm có dấu hiệu; quét gốc định kỳ đầu mùa mưa.',
    ),
    DiseaseRecord(
      id: 'dis_2',
      name: 'Rầy Phấn / Rầy Nhảy Sầu Riêng',
      scientificName: 'Allocaridara malayensis',
      riskLevel: 'Nguy cơ cao',
      riskColor: Colors.deepOrange,
      recentYears: '2025 - 2026',
      affectedRegions: 'Đông Nam Bộ (Bình Phước, Đồng Nai), Tây Nguyên (Đắk Nông, Gia Lai)',
      symptoms: 'Rầy non và rầy trưởng thành chích hút nhựa đọt non làm lá biến dạng, teo tóp, cháy rìa lá và rụng trơ cành non (cháy đọt). Tiết mật tạo nấm bồ hóng.',
      culturalPrevention: 'Tưới phun sương áp lực cao lên tán lá khi đọt mới nhú để rửa trôi rầy non. Vệ sinh cỏ dại ký chủ quanh vườn.',
      biologicalPrevention: 'Phun chế phẩm Nấm xanh (Metarhizium anisopliae) + Nấm trắng (Beauveria bassiana). Bảo vệ bọ rùa và kiến vàng.',
      chemicalTreatment: 'Phun kép 2 lần: lần 1 khi đọt vừa nhú hình mũi giáo (mầm hạt gạo), lần 2 sau 5-7 ngày khi lá mở hé.',
      activeIngredients: 'Imidacloprid, Thiamethoxam, Acetamiprid, Dinotefuran, Buprofezin (thuốc ức chế lột xác).',
      spraySchedule: 'Phun vào sáng sớm hoặc chiều mát ướt đều 2 mặt lá.',
    ),
    DiseaseRecord(
      id: 'dis_3',
      name: 'Bệnh Thán Thư Lá & Thối Hoa',
      scientificName: 'Colletotrichum gloeosporioides',
      riskLevel: 'Trung bình - Cao',
      riskColor: Colors.orange,
      recentYears: '2024 - 2026',
      affectedRegions: 'ĐBSCL (Tiền Giang, Hậu Giang, Cần Thơ), Tây Nguyên (vùng sương mù ẩm ướt)',
      symptoms: 'Vết bệnh ban đầu là đốm vàng nhỏ trên chóp hoặc mép lá, sau lan rộng thành vệt màu nâu xám có vân đồng tâm. Làm thối rụng hoa và rụng cuống trái non.',
      culturalPrevention: 'Cắt tỉa cành khô, cành sâu bệnh sau thu hoạch tiêu hủy. Bón cân đối N-P-K, tăng cường Kali và Silic giúp vách tế bào lá dày cứng.',
      biologicalPrevention: 'Phun dịch chiết xuất tỏi ớt kết hợp vi sinh vật đối kháng Chaetomium spp.',
      chemicalTreatment: 'Phun phòng khi cơi đọt bắt đầu mở lá và trước giai đoạn bung hoa 10 ngày.',
      activeIngredients: 'Azoxystrobin + Difenoconazole (Amistar Top), Mancozeb, Difenoconazole, Hexaconazole.',
      spraySchedule: 'Phun định kỳ 10-14 ngày/lần trong mùa mưa ẩm ướt.',
    ),
    DiseaseRecord(
      id: 'dis_4',
      name: 'Sâu Đục Trái & Bọ Xít Muỗi',
      scientificName: 'Conogethes punctiferalis',
      riskLevel: 'Nguy cơ cao giai đoạn trái',
      riskColor: Colors.redAccent,
      recentYears: '2025 - 2026',
      affectedRegions: 'Tất cả các vùng trồng sầu riêng trọng điểm (Đắk Lắk, Bình Phước, Tiền Giang)',
      symptoms: 'Sâu non đục vào vỏ và cơm trái, đùn phân màu nâu ra ngoài lỗ đục. Vết đục tạo điều kiện cho nấm khuẩn xâm nhập gây thối nguyên trái và rụng non.',
      culturalPrevention: 'Tỉa bỏ trái chùm dày sát nhau, chèn xốp hoặc cành ngăn gai trái cọ xát. Bao trái sầu riêng chuyên dụng khi trái được 40-50 ngày tuổi.',
      biologicalPrevention: 'Treo bẫy Pheromone dẫn dụ sâu đực. Phun vi khuẩn Bacillus thuringiensis (Bt).',
      chemicalTreatment: 'Phun thuốc trừ sâu sinh học khi trái bắt đầu hình thành hộc cơm (sau xổ nhụy 30 ngày).',
      activeIngredients: 'Emamectin benzoate, Abamectin, Spinetoram (Radiant), Chlorantraniliprole.',
      spraySchedule: 'Phun tập trung vào các chùm trái vào lúc chiều mát.',
    ),
    DiseaseRecord(
      id: 'dis_5',
      name: 'Bệnh Cháy Lá Chết Đọt (Đốm Rong)',
      scientificName: 'Rhizoctonia solani / Cephaleuros virescens',
      riskLevel: 'Trung bình',
      riskColor: Colors.amber,
      recentYears: '2024 - 2025',
      affectedRegions: 'Vùng đất phèn ĐBSCL và vườn thiếu ánh sáng tán rậm rạp',
      symptoms: 'Lá bị dính lại thành từng chùm bởi các sợi tơ nấm màu nâu xám, sau đó lá bị luộc chín khô cháy và rụng cành trơ trụi.',
      culturalPrevention: 'Tỉa cành tạo tán đón nắng thông thoáng, tránh để vườn quá rậm rạp ẩm thấp.',
      biologicalPrevention: 'Tưới Trichoderma bảo vệ vùng rễ và thân.',
      chemicalTreatment: 'Phun hoạt chất trừ nấm dạng tiếp xúc và nội hấp.',
      activeIngredients: 'Validamycin, Hexaconazole, Copper Oxychloride.',
      spraySchedule: 'Phun khi thấy xuất hiện màng tơ nấm đầu tiên.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredList = _diseases.where((d) {
      final matchesSearch = _searchQuery.isEmpty ||
          d.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.scientificName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.symptoms.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          d.activeIngredients.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesYear = _selectedYearFilter == 'all' ||
          d.recentYears.contains(_selectedYearFilter) ||
          (_selectedYearFilter == 'high_risk' && (d.riskLevel.contains('Cao') || d.riskLevel.contains('rất cao')));

      return matchesSearch && matchesYear;
    }).toList();

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
          'Sâu Bệnh Hại: ${widget.varietyName}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header Container
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Column(
              children: [
                // Search Input Field
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
                      hintText: 'Tìm tên sâu bệnh, triệu chứng, hoạt chất...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF2E7D32), size: 22),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Tabs (Năm gần nhất & Mức độ)
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('all', 'Tất cả sâu bệnh'),
                      const SizedBox(width: 8),
                      _buildFilterChip('2026', 'Năm 2026 (Mới nhất)'),
                      const SizedBox(width: 8),
                      _buildFilterChip('2025', 'Năm 2025'),
                      const SizedBox(width: 8),
                      _buildFilterChip('high_risk', '⚠️ Nguy cơ cao'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Pests & Diseases Cards List
          Expanded(
            child: filteredList.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _buildDiseaseCard(item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String id, String label) {
    final isSelected = _selectedYearFilter == id;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedYearFilter = id),
      selectedColor: const Color(0xFF4CAF50),
      backgroundColor: Colors.grey.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF555555),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: isSelected ? const Color(0xFF4CAF50) : Colors.grey.shade300),
      ),
    );
  }

  Widget _buildDiseaseCard(DiseaseRecord item) {
    return Container(
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name + Risk Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.scientificName,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.riskColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.riskLevel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: item.riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Chi tiết khu vực bị ảnh hưởng trong các năm gần nhất
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFECB3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFFF57C00), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Khu vực bị ảnh hưởng (${item.recentYears}):',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.affectedRegions,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF4E342E), height: 1.25),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Triệu chứng nhận biết
          _buildDetailSection(
            icon: Icons.visibility_outlined,
            iconColor: Colors.deepOrange,
            title: 'Triệu chứng nhận biết:',
            content: item.symptoms,
          ),
          const Divider(height: 20, thickness: 0.8),

          // Biện pháp phòng ngừa (Canh tác & Sinh học)
          _buildDetailSection(
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF2E7D32),
            title: 'Biện pháp phòng ngừa canh tác & sinh học:',
            content: '${item.culturalPrevention}\n• Sinh học: ${item.biologicalPrevention}',
          ),
          const SizedBox(height: 12),

          // Hoạt chất thuốc BVTV đặc trị & Lịch phun
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.medication_liquid_outlined, color: Color(0xFF2E7D32), size: 18),
                    SizedBox(width: 6),
                    Text(
                      'Hoạt chất đặc trị & Lịch phun thuốc:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '• Hoạt chất: ${item.activeIngredients}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1B5E20)),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Cách xử lý: ${item.chemicalTreatment}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Lịch phun: ${item.spraySchedule}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF555555)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF333333),
            height: 1.35,
          ),
        ),
      ],
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
              'Không tìm thấy sâu bệnh phù hợp',
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
