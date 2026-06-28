import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MacroBar extends StatefulWidget {
  final String label;
  final double value;
  final double goal;
  final String unit;
  final Color color;

  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.unit,
    required this.color,
  });

  @override
  State<MacroBar> createState() => _MacroBarState();
}

class _MacroBarState extends State<MacroBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = Tween<double>(
      begin: 0,
      end: (widget.value / widget.goal).clamp(0.0, 1.0),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(MacroBar old) {
    super.didUpdateWidget(old);
    final newVal = (widget.value / widget.goal).clamp(0.0, 1.0);
    final oldVal = (old.value / old.goal).clamp(0.0, 1.0);
    if (newVal != oldVal) {
      _anim = Tween<double>(begin: oldVal, end: newVal).animate(
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
    return Row(
      children: [
        // Dot
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        // Label
        SizedBox(
          width: 76,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Bar
        Expanded(
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: _anim.value,
                minHeight: 7,
                backgroundColor: widget.color.withOpacity(0.15),
                valueColor: AlwaysStoppedAnimation(widget.color),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Value
        SizedBox(
          width: 58,
          child: Text(
            '${widget.value.toStringAsFixed(1)}${widget.unit}',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: widget.color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
