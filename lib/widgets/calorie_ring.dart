import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CalorieRing extends StatefulWidget {
  final int consumed;
  final int goal;
  final double progress; // 0.0 – 1.0

  const CalorieRing({
    super.key,
    required this.consumed,
    required this.goal,
    required this.progress,
  });

  @override
  State<CalorieRing> createState() => _CalorieRingState();
}

class _CalorieRingState extends State<CalorieRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _anim = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(CalorieRing old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _anim = Tween<double>(begin: old.progress, end: widget.progress).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
      );
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final remaining = (widget.goal - widget.consumed).clamp(0, 99999);
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: 218,
        height: 218,
        child: CustomPaint(
          painter: _RingPainter(
            progress: _anim.value,
            track: p.surfaceRaised,
            brand: p.brand,
            success: p.success,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$remaining',
                  style: TextStyle(
                    color: p.textPrimary,
                    fontSize: 43,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: -1.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text('kcal còn lại',
                    style: TextStyle(
                        color: p.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 3),
                Text('trên ${widget.goal} kcal',
                    style: TextStyle(
                        color: p.textSecondary.withOpacity(.8), fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color track;
  final Color brand;
  final Color success;
  _RingPainter(
      {required this.progress,
      required this.track,
      required this.brand,
      required this.success});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 18;
    const strokeWidth = 16.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // ── Track ring ──
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0) return;

    // ── Glow under arc ──
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = brand.withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 8
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // ── Gradient arc ──
    final gradient = SweepGradient(
      startAngle: -pi / 2,
      endAngle: -pi / 2 + 2 * pi * progress,
      colors: [brand, success],
      tileMode: TileMode.clamp,
    );
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // ── Endpoint dot ──
    if (progress > 0.02) {
      final angle = -pi / 2 + 2 * pi * progress;
      final ex = center.dx + radius * cos(angle);
      final ey = center.dy + radius * sin(angle);
      canvas.drawCircle(
        Offset(ex, ey),
        strokeWidth / 2,
        Paint()..color = success,
      );
      canvas.drawCircle(
        Offset(ex, ey),
        strokeWidth / 2 + 4,
        Paint()
          ..color = success.withOpacity(0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.brand != brand ||
      old.success != success;
}
