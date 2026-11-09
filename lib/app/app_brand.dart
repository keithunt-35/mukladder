import 'package:flutter/material.dart';

class AppBrandMark extends StatelessWidget {
  const AppBrandMark({this.size = 44, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'MUKLadder tennis logo',
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _BrandMarkPainter()),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final scale = size.width / 48;
    final background = Paint()..color = const Color(0xFF0B5D3B);
    final ball = Paint()..color = const Color(0xFFD8F06A);
    final seam = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * scale;
    final rung = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 2.4 * scale
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(bounds, Radius.circular(14 * scale)),
      background,
    );
    canvas.drawCircle(Offset(24 * scale, 18 * scale), 11 * scale, ball);

    final leftSeam = Path()
      ..moveTo(19 * scale, 9 * scale)
      ..cubicTo(
        12 * scale,
        15 * scale,
        13 * scale,
        22 * scale,
        20 * scale,
        27 * scale,
      );
    final rightSeam = Path()
      ..moveTo(29 * scale, 9 * scale)
      ..cubicTo(
        36 * scale,
        15 * scale,
        35 * scale,
        22 * scale,
        28 * scale,
        27 * scale,
      );
    canvas.drawPath(leftSeam, seam);
    canvas.drawPath(rightSeam, seam);

    for (final y in [33.0, 38.0, 43.0]) {
      canvas.drawLine(
        Offset(15 * scale, y * scale),
        Offset(33 * scale, y * scale),
        rung,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AppBrandLockup extends StatelessWidget {
  const AppBrandLockup({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBrandMark(size: compact ? 34 : 52),
        const SizedBox(width: 12),
        Text('MUKLadder', style: textStyle),
      ],
    );
  }
}
