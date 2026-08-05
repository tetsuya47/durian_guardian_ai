import 'package:flutter/material.dart';

class PhotoTipsCard extends StatelessWidget {
  const PhotoTipsCard({super.key});

  @override
  Widget build(BuildContext context) {
    const tips = [
      'Chụp rõ nét, đủ sáng',
      'Lấy nét vào vùng lá bị bệnh',
      'Tránh chụp khi lá còn nước mưa hoặc sương',
      'Nên chụp cả mặt trên và mặt dưới lá',
    ];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F9F5),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFDDF0E4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFF0F8A4C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Mẹo chụp ảnh chuẩn',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F8A4C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF0F8A4C),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
