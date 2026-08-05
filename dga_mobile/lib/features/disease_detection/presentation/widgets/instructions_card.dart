import 'package:flutter/material.dart';

class InstructionsCard extends StatelessWidget {
  const InstructionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEEF7F2),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Right leaf decoration
            Positioned(
              right: -5,
              top: 0,
              bottom: 0,
              width: 110,
              child: CustomPaint(
                painter: InstructionLeafPainter(),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD6EDE0),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.saved_search_rounded,
                      color: Color(0xFF0F8A4C),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hướng dẫn chẩn đoán',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F8A4C),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Bấm Chụp ảnh hoặc Thư viện ảnh để bắt đầu chẩn đoán bệnh lá sầu riêng.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4B5563),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 60), // Spacing for leaf graphic
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InstructionLeafPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final darkGreen = Paint()..color = const Color(0xFF2E7D4E)..style = PaintingStyle.fill;
    final medGreen = Paint()..color = const Color(0xFF4CAF6E)..style = PaintingStyle.fill;
    final lightGreen = Paint()..color = const Color(0xFF81C798)..style = PaintingStyle.fill;

    // Leaf 1
    final path1 = Path()
      ..moveTo(size.width * 0.5, 0)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.1, size.width, size.height * 0.6)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.5, size.width * 0.5, 0);
    canvas.drawPath(path1, medGreen);

    // Leaf 2
    final path2 = Path()
      ..moveTo(size.width * 0.7, 0)
      ..quadraticBezierTo(size.width, size.height * 0.3, size.width * 0.95, size.height * 0.95)
      ..quadraticBezierTo(size.width * 0.65, size.height * 0.7, size.width * 0.7, 0);
    canvas.drawPath(path2, darkGreen);

    // Leaf 3
    final path3 = Path()
      ..moveTo(size.width * 0.6, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.95, size.height * 0.55, size.width * 0.85, size.height)
      ..quadraticBezierTo(size.width * 0.55, size.height * 0.75, size.width * 0.6, size.height * 0.3);
    canvas.drawPath(path3, lightGreen);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
