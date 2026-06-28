import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'today_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
import 'camera_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  static const _screens = [
    TodayScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: IndexedStack(
        index: _index,
        children: _screens,
      ),
      floatingActionButton: _CameraFAB(onTap: _openCamera),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _BottomBar(
        index: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }

  void _openCamera() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CameraScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }
}

// ── Camera FAB ────────────────────────────────────────────────────
class _CameraFAB extends StatefulWidget {
  final VoidCallback onTap;
  const _CameraFAB({required this.onTap});

  @override
  State<_CameraFAB> createState() => _CameraFABState();
}

class _CameraFABState extends State<_CameraFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.9)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp:   (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF9B7DFF), AppTheme.accent, Color(0xFF5B3FD8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withOpacity(0.55),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

// ── Bottom Navigation Bar ─────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: const Color(0xFF0F0F17),
      elevation: 0,
      notchMargin: 10,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 62,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(0, Icons.home_rounded,        Icons.home_outlined,     'Hôm nay'),
            const SizedBox(width: 66), // space for FAB
            _navItem(1, Icons.history_rounded,     Icons.history_rounded,   'Lịch sử'),
            _navItem(2, Icons.person_rounded,      Icons.person_outline_rounded, 'Cài đặt'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    int i,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
  ) {
    final selected = index == i;
    return GestureDetector(
      onTap: () => onTap(i),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Column(
            key: ValueKey('$i-$selected'),
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? activeIcon : inactiveIcon,
                color: selected ? AppTheme.accent : const Color(0xFF4A4A60),
                size: 24,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: selected ? AppTheme.accent : const Color(0xFF4A4A60),
                  fontSize: 10,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
