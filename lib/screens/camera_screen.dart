import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  final _gemini = GeminiService();

  bool   _analyzing = false;
  String _status    = '';

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildBg(),
          SafeArea(child: _buildBody()),
          if (_analyzing) _buildOverlay(),
        ],
      ),
    );
  }

  Widget _buildBg() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.4,
          colors: [AppTheme.accent.withOpacity(0.18), Colors.black],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // ── Top bar ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'Nhận diện thức ăn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),

        // ── Scan frame ──
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Transform.scale(scale: _pulse.value, child: child),
                  child: _ScanFrame(),
                ),
                const SizedBox(height: 36),
                const Text(
                  'Chụp ảnh hoặc chọn từ thư viện',
                  style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Gemini AI sẽ nhận diện và tính calo miễn phí',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        // ── Buttons ──
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _sideBtn(Icons.photo_library_rounded, 'Thư viện',
                  () => _pick(ImageSource.gallery)),
              _captureBtn(),
              _sideBtn(Icons.lightbulb_outline_rounded, 'Mẹo', _showTips),
            ],
          ),
        ),
      ],
    );
  }

  Widget _captureBtn() {
    return GestureDetector(
      onTap: () => _pick(ImageSource.camera),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [AppTheme.accent, Color(0xFF5B3FD8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: AppTheme.accent.withOpacity(0.5), blurRadius: 28, spreadRadius: 2),
          ],
        ),
        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 34),
      ),
    );
  }

  Widget _sideBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54, height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.09),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Icon(icon, color: Colors.white70, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.88),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60, height: 60,
            child: CircularProgressIndicator(
              color: AppTheme.accent,
              backgroundColor: AppTheme.accent.withOpacity(0.2),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Đang phân tích...',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            _status,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Logic ──────────────────────────────────────────────────────
  Future<void> _pick(ImageSource source) async {
    HapticFeedback.mediumImpact();
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
    } catch (e) {
      _showError('Không thể truy cập ${source == ImageSource.camera ? "camera" : "thư viện ảnh"}.\nKiểm tra quyền truy cập trong cài đặt.');
      return;
    }

    if (picked == null || !mounted) return;

    setState(() {
      _analyzing = true;
      _status    = 'Đang nhận diện món ăn...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _status = 'Đang tính calo và dinh dưỡng...');

      final result = await _gemini.analyzeFood(File(picked.path));

      if (!mounted) return;
      setState(() => _analyzing = false);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            result: result,
            imageFile: File(picked!.path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _analyzing = false);
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppTheme.errorColor),
            SizedBox(width: 10),
            Text('Lỗi', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(message, style: const TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  void _showTips() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('💡 Mẹo để đạt kết quả tốt nhất', style: TextStyle(
              color: AppTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 16),
            for (final tip in _tips) _tipRow(tip),
          ],
        ),
      ),
    );
  }

  Widget _tipRow(String tip) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle_rounded, color: AppTheme.green, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(tip, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
        ),
      ],
    ),
  );

  static const _tips = [
    'Chụp từ góc trên xuống để thấy toàn bộ món ăn',
    'Đảm bảo ánh sáng đủ sáng, tránh chụp ngược sáng',
    'Đặt một vật tham chiếu (nắp chai, bàn tay) để AI ước lượng khẩu phần',
    'Mỗi ảnh nên tập trung vào một món chính',
    'Tránh chụp qua kính hoặc bao bì che khuất thức ăn',
    'Chụp gần hơn nếu món nhỏ để AI nhận diện rõ hơn',
  ];
}

// ── Scan Frame Widget ─────────────────────────────────────────────
class _ScanFrame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 250,
      child: Stack(
        children: [
          // Faint inner glow
          Center(
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accent.withOpacity(0.06),
              ),
            ),
          ),
          // Food icon
          const Center(
            child: Icon(Icons.restaurant_rounded, size: 90, color: Color(0x30FFFFFF)),
          ),
          // Corners
          Positioned(top: 0, left: 0, child: _Corner(top: true, left: true)),
          Positioned(top: 0, right: 0, child: _Corner(top: true, left: false)),
          Positioned(bottom: 0, left: 0, child: _Corner(top: false, left: true)),
          Positioned(bottom: 0, right: 0, child: _Corner(top: false, left: false)),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final bool top;
  final bool left;
  const _Corner({required this.top, required this.left});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(28, 28),
      painter: _CornerPainter(top: top, left: left),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final bool top;
  final bool left;
  _CornerPainter({required this.top, required this.left});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color     = AppTheme.accent
      ..strokeWidth = 3.5
      ..style     = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;

    if (top  && left)  { canvas.drawLine(Offset(0, h), Offset(0, 0), paint); canvas.drawLine(Offset(0, 0), Offset(w, 0), paint); }
    if (top  && !left) { canvas.drawLine(Offset(0, 0), Offset(w, 0), paint); canvas.drawLine(Offset(w, 0), Offset(w, h), paint); }
    if (!top && left)  { canvas.drawLine(Offset(0, 0), Offset(0, h), paint); canvas.drawLine(Offset(0, h), Offset(w, h), paint); }
    if (!top && !left) { canvas.drawLine(Offset(w, 0), Offset(w, h), paint); canvas.drawLine(Offset(w, h), Offset(0, h), paint); }
  }

  @override
  bool shouldRepaint(_) => false;
}
