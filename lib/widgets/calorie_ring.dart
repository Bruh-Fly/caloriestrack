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
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => SizedBox(
        width: 200,
        height: 200,
        child: CustomPaint(
          painter: _RingPainter(progress: _anim.value),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Percentage
                Text(
                  '${(widget.progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'đã đạt',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center      = Offset(size.width / 2, size.height / 2);
    final radius      = size.width / 2 - 18;
    const strokeWidth = 16.0;
    final rect        = Rect.fromCircle(center: center, radius: radius);

    // ── Track ring ──
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color      = AppTheme.surface
        ..style      = PaintingStyle.stroke
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
        ..color       = AppTheme.accent.withOpacity(0.25)
        ..style       = PaintingStyle.stroke
        ..strokeWidth  = strokeWidth + 8
        ..strokeCap    = StrokeCap.round
        ..maskFilter   = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // ── Gradient arc ──
    final gradient = SweepGradient(
      startAngle: -pi / 2,
      endAngle:   -pi / 2 + 2 * pi * progress,
      colors: const [AppTheme.accent, AppTheme.green],
      tileMode: TileMode.clamp,
    );
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..shader      = gradient.createShader(rect)
        ..style       = PaintingStyle.stroke
        ..strokeWidth  = strokeWidth
        ..strokeCap    = StrokeCap.round,
    );

    // ── Endpoint dot ──
    if (progress > 0.02) {
      final angle = -pi / 2 + 2 * pi * progress;
      final ex    = center.dx + radius * cos(angle);
      final ey    = center.dy + radius * sin(angle);
      canvas.drawCircle(
        Offset(ex, ey),
        strokeWidth / 2,
        Paint()..color = AppTheme.green,
      );
      canvas.drawCircle(
        Offset(ex, ey),
        strokeWidth / 2 + 4,
        Paint()
          ..color      = AppTheme.green.withOpacity(0.35)
          ..maskFilter  = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
