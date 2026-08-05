import 'package:flutter/material.dart';

class EmptyStateIllustration extends StatelessWidget {
  const EmptyStateIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 160,
      decoration: const BoxDecoration(
        color: Color(0xFFEBF5EF),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SizedBox(
          width: 110,
          height: 120,
          child: CustomPaint(
            painter: ClipboardIllustrationPainter(),
          ),
        ),
      ),
    );
  }
}

class ClipboardIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw leaves on the left
    final leafPaint = Paint()..color = const Color(0xFF4CAF6E)..style = PaintingStyle.fill;
    final leafDarkPaint = Paint()..color = const Color(0xFF2E7D4E)..style = PaintingStyle.fill;

    // Leaf 1
    final leafPath1 = Path()
      ..moveTo(25, 60)
      ..quadraticBezierTo(5, 45, 10, 30)
      ..quadraticBezierTo(25, 40, 25, 60);
    canvas.drawPath(leafPath1, leafPaint);

    // Leaf 2
    final leafPath2 = Path()
      ..moveTo(25, 75)
      ..quadraticBezierTo(0, 70, 5, 50)
      ..quadraticBezierTo(22, 60, 25, 75);
    canvas.drawPath(leafPath2, leafDarkPaint);

    // 2. Draw Clipboard Board (Green)
    final boardRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(30, 20, 70, 95),
      const Radius.circular(16),
    );
    final boardPaint = Paint()..color = const Color(0xFF0F8A4C)..style = PaintingStyle.fill;
    canvas.drawRRect(boardRect, boardPaint);

    // 3. Draw Paper Sheet (White)
    final paperRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(35, 28, 60, 80),
      const Radius.circular(10),
    );
    final paperPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    canvas.drawRRect(paperRect, paperPaint);

    // 4. Draw Clip Handle at top
    final clipPath = Path()
      ..moveTo(52, 14)
      ..lineTo(78, 14)
      ..lineTo(80, 24)
      ..lineTo(50, 24)
      ..close();
    final clipPaint = Paint()..color = const Color(0xFF096336)..style = PaintingStyle.fill;
    canvas.drawPath(clipPath, clipPaint);

    final clipHolePaint = Paint()..color = const Color(0xFFEBF5EF)..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(65, 18), 3, clipHolePaint);

    // 5. Draw Prohibited/No-image icon on paper
    const circleCenter = Offset(65, 68);
    const radius = 18.0;

    final greenCirclePaint = Paint()
      ..color = const Color(0xFF0F8A4C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(circleCenter, radius, greenCirclePaint);

    // Diagonal slash
    final slashPaint = Paint()
      ..color = const Color(0xFF0F8A4C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      const Offset(52, 81),
      const Offset(78, 55),
      slashPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
