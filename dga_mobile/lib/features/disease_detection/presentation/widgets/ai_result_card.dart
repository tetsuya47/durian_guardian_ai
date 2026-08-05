import 'package:flutter/material.dart';
import '../../domain/entities/disease_detection_entities.dart';

class AIResultCard extends StatelessWidget {
  final DetectionResultEntity result;

  const AIResultCard({
    super.key,
    required this.result,
  });

  Color _getSeverityColor() {
    switch (result.severity) {
      case 'Nhẹ':
        return const Color(0xFF2E7D32);
      case 'Trung bình':
        return Colors.orange;
      case 'Nặng':
        return Colors.red;
      default:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor();
    final confidencePercent = (result.confidence * 100).toStringAsFixed(1);
    final isHealthy = result.diseaseName.toLowerCase().contains('khỏe mạnh') ||
        result.diseaseName.toLowerCase().contains('healthy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CARD 1: AI PHÂN TÍCH CHẨN ĐOÁN
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFC8E6C9)),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.analytics_outlined, color: Color(0xFF2E7D32), size: 20),
                      SizedBox(width: 8),
                      Text(
                        '📊 AI PHÂN TÍCH CHẨN ĐOÁN',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: severityColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Mức độ: ${result.severity}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: severityColor),
                    ),
                  ),
                ],
              ),
              const Divider(height: 20),
              _buildAnalysisRow('✓ Bệnh chẩn đoán:', result.diseaseName, isBold: true, color: severityColor),
              _buildAnalysisRow('✓ Độ tin cậy (Model 1):', '$confidencePercent%'),
              _buildAnalysisRow('✓ Mức độ nghiêm trọng:', result.severity),
              _buildAnalysisRow(
                '✓ Nguy cơ bùng phát (Model 3):',
                result.severity == 'Nặng' ? 'Rất Cao (90%)' : result.severity == 'Trung bình' ? 'Cao (70%)' : 'Thấp (20%)',
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isHealthy
                      ? '💡 Đánh giá AI: Cây khỏe mạnh, tán lá phát triển tốt. Duy trì bón phân hữu cơ vi sinh.'
                      : '💡 Đánh giá AI: Phát hiện tổn thương lá. Cần xử lý trong 24-48 giờ tới để tránh bùng phát rộng.',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF1B4D3E), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // CARD 2: VÌ SAO AI ĐƯA RA KẾT LUẬN (XAI Transparency)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBF9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFD0E1D4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology_outlined, color: Color(0xFF2E7D32), size: 20),
                  SizedBox(width: 8),
                  Text(
                    '🔍 VÌ SAO AI ĐƯA RA KẾT LUẬN?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text('AI suy luận dựa trên sự kết hợp 7 yếu tố:', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildCheckFactor('Hình ảnh lá chụp trực tiếp từ camera'),
              _buildCheckFactor('Kết quả mô hình Deep Learning Model 1 (EfficientNet-B0)'),
              _buildCheckFactor('Chỉ số tin cậy Confidence ($confidencePercent%)'),
              _buildCheckFactor('Tập quy tắc kiểm định Rule Engine từ MongoDB'),
              _buildCheckFactor('Trích xuất dữ liệu từ Cơ sở tri thức Knowledge Base'),
              _buildCheckFactor('Dữ liệu vi khí hậu & thời tiết thực tế 24h'),
              _buildCheckFactor('Nhật ký tác động canh tác Farm Activity'),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // CARD 3: LÝ DO CHỌN THUỐC & PHÁC ĐỒ (Hide if Healthy)
        if (!isHealthy) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF81C784)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.medication_liquid_outlined, color: Color(0xFF2E7D32), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '💊 LÝ DO AI KHUYÊN DÙNG PHÁC ĐỒ NÀY',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1B4D3E)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildCheckFactor('Đúng hoạt chất đặc trị kiểm chứng khoa học'),
                _buildCheckFactor('Đạt hiệu quả cao nhất với bệnh ${result.diseaseName}'),
                _buildCheckFactor('Liều lượng pha chuẩn 200L phù hợp mức bệnh ${result.severity}'),
                _buildCheckFactor('Đã kiểm tra an toàn trong Knowledge Base MongoDB'),
                const Divider(height: 20),
                Text(
                  _getProtocolText(result.diseaseName, result.severity) ?? '',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1B4D3E), height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // CARD 4: CẢNH BÁO MÔI TRƯỜNG & QUY TẮC
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E1),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    '⚠️ CẢNH BÁO VÀ HƯỚNG DẪN QUẢN LÝ',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (!isHealthy) ...[
                const Text('• Thời tiết: Nếu dự báo có mưa trong 24h, tạm hoãn phun để tránh trôi thuốc.', style: TextStyle(fontSize: 11.5, color: Color(0xFF5D4037))),
                const SizedBox(height: 4),
                const Text('• Giãn cách: Không phun lặp lại cùng loại thuốc hóa học dưới 7 ngày.', style: TextStyle(fontSize: 11.5, color: Color(0xFF5D4037))),
                const SizedBox(height: 4),
                const Text('• Cách ly PHI: Tuân thủ thời gian cách ly PHI trước khi thu hoạch.', style: TextStyle(fontSize: 11.5, color: Color(0xFF5D4037))),
              ] else ...[
                const Text('• Duy trì theo dõi lá và độ ẩm đất định kỳ hàng tuần.', style: TextStyle(fontSize: 11.5, color: Color(0xFF5D4037))),
              ],
            ],
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('📅 Đã đặt lịch nhắc AI tự động tái khám sau 7 ngày!'),
                  backgroundColor: Color(0xFF2E7D32),
                  duration: Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.alarm_add, size: 18),
            label: const Text('⏰ Đặt Lịch Nhắc Tái Khám Sau 7 Ngày', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckFactor(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 14, color: Color(0xFF2E7D32)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF1B4D3E), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  String? _getProtocolText(String disease, String severity) {
    final d = disease.toLowerCase();
    if (d.contains('khỏe mạnh') || d.contains('healthy')) {
      return null;
    }

    if (d.contains('thán thư') || d.contains('anthracnose')) {
      return 'Phác đồ khuyên dùng: Phun Ridomil Gold 68WG (Metalaxyl M 40g/kg + Mancozeb 640g/kg) pha 500g / 200L nước vào sáng sớm. Tỉa bỏ cành rậm rạp & đặt lịch tái khám sau 7 ngày.';
    } else if (d.contains('sẹo thân') || d.contains('canker')) {
      return 'Phác đồ khuyên dùng: Dùng dao cạo sạch sẹo nứt trên thân, quét đậm đặc Aliette 800WG (Fosetyl-Aluminium) hoặc Phytocide 50WP lên vết sẹo. Tái khám sau 7 ngày.';
    } else if (d.contains('thối quả') || d.contains('fruit_rot') || d.contains('rot')) {
      return 'Phác đồ khuyên dùng: Phun phòng trị bằng Agri-Fos 400 (Phosphonate) pha 500ml / 200L nước phun đều chùm quả. Tiêu hủy quả thối & tái khám sau 7 ngày.';
    } else if (d.contains('rệp sáp') || d.contains('mealybug')) {
      return 'Phác đồ khuyên dùng: Phun Movento 150OD (Spirotetramat) 160ml/200L nước + Dầu khoáng SK Enspray 99EC 400ml/200L nước rửa trôi lớp sáp rệp. Tái khám sau 7 ngày.';
    } else if (d.contains('nấm hồng') || d.contains('pink')) {
      return 'Phác đồ khuyên dùng: Phun Coc85 (Copper Hydroxide) 500g/200L nước hoặc Anvil 5SC (Hexaconazole) 300ml/200L nước quét trực tiếp vị trí nấm hồng chạc ba cành & hẹn tái khám sau 7 ngày.';
    } else if (d.contains('bồ hóng') || d.contains('sooty_mold') || d.contains('mold')) {
      return 'Phác đồ khuyên dùng: Phun Antracol 70WP (Propineb + Zinc++) 500g/200L nước kết hợp diệt rầy mật rệp sáp tạo mật ngọt. Tái khám sau 7 ngày.';
    } else if (d.contains('cháy thân') || d.contains('cháy lá') || d.contains('stem_blight') || d.contains('blight')) {
      return 'Phác đồ khuyên dùng: Phun Validacin 5SL (Validamycin) 300ml/200L nước hoặc Amistar Top 325SC 150ml/200L nước ướt đều 2 mặt lá & thân cành. Tái khám sau 7 ngày.';
    } else if (d.contains('nứt thân') || d.contains('chảy nhựa') || d.contains('gummosis')) {
      return 'Phác đồ khuyên dùng: Cạo vết nhựa đen, quét đậm đặc Metalaxyl + Mancozeb (Ridomil Gold) hoặc Fosetyl-Aluminium. Rải 500g Vôi bột/gốc hạ chua & hẹn tái khám sau 7 ngày.';
    } else if (d.contains('bọ trĩ') || d.contains('thrips')) {
      return 'Phác đồ khuyên dùng: Phun Radiant 60SC (Spinetoram) 150ml/200L nước hoặc Confidor 100SL vào thời điểm cơi đọt nhú hình đuôi tôm. Tái khám sau 7 ngày.';
    } else if (d.contains('vàng lá') || d.contains('yellow_leaf') || d.contains('yellow')) {
      return 'Phác đồ khuyên dùng: Tưới gốc Phos-Acid + Phân hữu cơ Humic K-Humate 1kg/200L nước để kích rễ tơ phục hồi. Rải 500g Vôi bột nâng pH đất & tái khám sau 7 ngày.';
    }

    return 'Phác đồ khuyên dùng: Phun thuốc BVTV đặc trị theo hướng dẫn kỹ thuật, bổ sung phân bón lá giàu Kẽm & đặt lịch hẹn tái khám sau 7 ngày.';
  }
}
