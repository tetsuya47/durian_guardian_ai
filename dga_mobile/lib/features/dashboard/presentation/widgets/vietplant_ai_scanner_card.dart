import 'package:flutter/material.dart';

class VietplantAIScannerCard extends StatelessWidget {
  final VoidCallback onCameraTap;
  final List<Map<String, dynamic>> scanHistory;

  const VietplantAIScannerCard({
    super.key,
    required this.onCameraTap,
    required this.scanHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Card Container (Matching Screenshot 5)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF1F8E9), Color(0xFFE8F5E9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFC8E6C9), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Plant Scanner Frame Illustration
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.park, size: 70, color: Color(0xFF2E7D32)),
                      // Scanner Viewfinder Overlay Corners
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(width: 14, height: 14, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF2E7D32), width: 3), left: BorderSide(color: Color(0xFF2E7D32), width: 3)))),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(width: 14, height: 14, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF2E7D32), width: 3), right: BorderSide(color: Color(0xFF2E7D32), width: 3)))),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(width: 14, height: 14, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF2E7D32), width: 3), left: BorderSide(color: Color(0xFF2E7D32), width: 3)))),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(width: 14, height: 14, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF2E7D32), width: 3), right: BorderSide(color: Color(0xFF2E7D32), width: 3)))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Card Title & Sub-text
                const Text(
                  'Chụp ảnh để nhận diện cây trồng',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tự động nhận diện cây trồng và chẩn đoán sâu bệnh bằng hình ảnh',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF555555),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 18),

                // Green Action Button [📷 Chụp ảnh]
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onCameraTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.crop_free, size: 24),
                    label: const Text(
                      'Chụp ảnh',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Lịch sử nhận diện (Scan History from MongoDB)
          const Text(
            'Lịch sử nhận diện',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 12),
          scanHistory.isEmpty
              ? _buildEmptyHistory()
              : Column(
                  children: scanHistory.take(5).map((item) => _buildHistoryTile(item)).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(Map<String, dynamic> item) {
    final diseaseName = item['disease_name'] ?? item['condition'] ?? 'Khỏe mạnh';
    final treeCode = item['tree_code'] ?? item['tree_id'] ?? 'Cây trồng';
    final confidence = item['confidence'] != null ? '${((item['confidence'] as num) * 100).toStringAsFixed(0)}%' : '95%';
    final date = item['created_at']?.toString().split('T').first ?? '12/08/2026';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: diseaseName.contains('Healthy') || diseaseName.contains('Khỏe')
              ? const Color(0xFFE8F5E9)
              : const Color(0xFFFFEBEE),
          child: Icon(
            diseaseName.contains('Healthy') || diseaseName.contains('Khỏe') ? Icons.check_circle_outline : Icons.warning_amber_outlined,
            color: diseaseName.contains('Healthy') || diseaseName.contains('Khỏe') ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          diseaseName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text('$treeCode • $date', style: const TextStyle(fontSize: 13, color: Colors.grey)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            confidence,
            style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Text(
        'Chưa có lịch sử nhận diện. Hãy bấm "Chụp ảnh" để bắt đầu chẩn đoán cây trồng!',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey, fontSize: 14),
      ),
    );
  }
}
