import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Ikon Google 'G' 4-warna berstandar Material Design.
/// Di-render menggunakan CustomPainter murni tanpa aset gambar eksternal
/// sehingga andal saat offline dan tajam pada seluruh resolusi layar.
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double strokeWidth = w * 0.22;
    final Rect rect = Rect.fromCenter(
      center: Offset(w / 2, h / 2),
      width: w - strokeWidth,
      height: h - strokeWidth,
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // Merah (Atas)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -math.pi / 4, -math.pi / 2, false, paint);

    // Kuning (Kiri)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, -3 * math.pi / 4, -math.pi / 2, false, paint);

    // Hijau (Bawah)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(rect, -5 * math.pi / 4, -math.pi / 2, false, paint);

    // Biru (Kanan arc + garis horizontal menuju tengah)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -7 * math.pi / 4, -math.pi / 4, false, paint);

    final barPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0xFF4285F4);

    canvas.drawLine(
      Offset(w / 2, h / 2),
      Offset(w - strokeWidth / 2, h / 2),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
