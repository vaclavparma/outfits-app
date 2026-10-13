import 'package:flutter/material.dart';

/// Simple drawn garments for the welcome screen — the app ships no photos
/// of its own, so these stand in for the user's clothes.
enum GarmentArt { shirt, stripedTee, trousers }

/// [art] in [color], drawn to fit a square of [size] on a white card.
class GarmentArtCard extends StatelessWidget {
  final GarmentArt art;
  final Color color;
  final double width;
  final double height;
  final double rotationDeg;

  const GarmentArtCard({
    super.key,
    required this.art,
    required this.color,
    required this.width,
    required this.height,
    this.rotationDeg = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotationDeg * 3.1415926535 / 180,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 10))],
        ),
        padding: EdgeInsets.all(width * 0.12),
        child: CustomPaint(painter: _GarmentPainter(art, color)),
      ),
    );
  }
}

class _GarmentPainter extends CustomPainter {
  final GarmentArt art;
  final Color color;
  _GarmentPainter(this.art, this.color);

  /// The outline in a 100 × 100 box.
  Path get _outline => switch (art) {
    GarmentArt.shirt => Path()
      ..moveTo(36, 8)
      ..lineTo(44, 5)
      ..lineTo(50, 12)
      ..lineTo(56, 5)
      ..lineTo(64, 8)
      ..lineTo(80, 16)
      ..quadraticBezierTo(86, 20, 87, 30)
      ..lineTo(92, 86)
      ..lineTo(81, 88)
      ..lineTo(73, 38)
      ..lineTo(74, 95)
      ..lineTo(26, 95)
      ..lineTo(27, 38)
      ..lineTo(19, 88)
      ..lineTo(8, 86)
      ..lineTo(13, 30)
      ..quadraticBezierTo(14, 20, 20, 16)
      ..close(),
    GarmentArt.stripedTee => Path()
      ..moveTo(34, 12)
      ..quadraticBezierTo(50, 22, 66, 12)
      ..lineTo(84, 20)
      ..lineTo(95, 40)
      ..lineTo(80, 48)
      ..lineTo(74, 40)
      ..lineTo(75, 92)
      ..lineTo(25, 92)
      ..lineTo(26, 40)
      ..lineTo(20, 48)
      ..lineTo(5, 40)
      ..lineTo(16, 20)
      ..close(),
    GarmentArt.trousers => Path()
      ..moveTo(28, 6)
      ..lineTo(72, 6)
      ..lineTo(80, 96)
      ..lineTo(58, 96)
      ..lineTo(50, 34)
      ..lineTo(42, 96)
      ..lineTo(20, 96)
      ..close(),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 100;
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);
    final outline = _outline;
    final darker = Color.lerp(color, Colors.black, 0.22)!;
    canvas.drawPath(outline, Paint()..color = color);
    final line = Paint()
      ..color = darker
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    switch (art) {
      case GarmentArt.shirt:
        canvas.drawLine(const Offset(50, 12), const Offset(50, 95), line);
        for (var y = 24.0; y < 92; y += 13) {
          canvas.drawCircle(Offset(52.5, y), 1.1, Paint()..color = darker);
        }
        canvas.drawPath(
          Path()
            ..moveTo(44, 5)
            ..lineTo(42, 16)
            ..lineTo(50, 12)
            ..lineTo(58, 16)
            ..lineTo(56, 5),
          line,
        );
      case GarmentArt.stripedTee:
        canvas.save();
        canvas.clipPath(outline);
        final stripe = Paint()
          ..color = darker
          ..strokeWidth = 1.6;
        for (var y = 18.0; y < 96; y += 6) {
          canvas.drawLine(Offset(0, y), Offset(100, y), stripe);
        }
        canvas.restore();
      case GarmentArt.trousers:
        canvas.drawLine(const Offset(28, 13), const Offset(72, 13), line);
        canvas.drawLine(const Offset(50, 13), const Offset(50, 34), line);
    }
    canvas.drawPath(outline, line..color = darker.withValues(alpha: 0.5));
  }

  @override
  bool shouldRepaint(_GarmentPainter old) => old.art != art || old.color != color;
}
