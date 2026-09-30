import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import 'result_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.mealType});
  final String? mealType;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  final _picker = ImagePicker();
  final _gemini = GeminiService();
  CameraController? _cameraController;
  String? _cameraError;
  bool _initializingCamera = false;

  bool _analyzing = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraController = null;
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    if (_cameraController != null || _initializingCamera || !mounted) return;
    _initializingCamera = true;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty)
        throw CameraException('NoCamera', 'Thiết bị không tìm thấy camera.');
      final camera = cameras.firstWhere(
        (value) => value.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _cameraError = null;
      });
    } on CameraException catch (error) {
      if (mounted) setState(() => _cameraError = _cameraMessage(error));
    } catch (error) {
      if (mounted)
        setState(() => _cameraError = 'Không thể khởi động camera: $error');
    } finally {
      _initializingCamera = false;
    }
  }

  String _cameraMessage(CameraException error) {
    if (error.code.toLowerCase().contains('permission') ||
        error.code.toLowerCase().contains('denied')) {
      return 'CaloAI cần quyền Camera. Hãy cấp quyền trong Cài đặt của điện thoại.';
    }
    return error.description ?? 'Không thể mở camera trên thiết bị này.';
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
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'Nhận diện thức ăn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),

        // ── Scan frame ──
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          final controller = _cameraController;
          final previewWidth = math.min(constraints.maxWidth - 36, 390.0);
          final previewHeight = math
              .max(160.0,
                  math.min(constraints.maxHeight - 90, previewWidth * 4 / 3))
              .toDouble();
          return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (controller?.value.isInitialized == true)
              SizedBox(
                width: previewWidth,
                height: previewHeight,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(fit: StackFit.expand, children: [
                    CameraPreview(controller!),
                    const IgnorePointer(child: _ScanFrame()),
                  ]),
                ),
              )
            else
              SizedBox(
                width: previewWidth,
                height: previewHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.05),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppTheme.accent.withOpacity(.5)),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_cameraError == null)
                          const CircularProgressIndicator(
                              color: AppTheme.accent)
                        else
                          const Icon(Icons.no_photography_outlined,
                              color: Colors.white54, size: 42),
                        const SizedBox(height: 14),
                        Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 22),
                            child: Text(
                              _cameraError ?? 'Đang mở camera…',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 13),
                            )),
                        if (_cameraError != null)
                          TextButton(
                              onPressed: _initializeCamera,
                              child: const Text('Thử lại')),
                      ]),
                ),
              ),
            const SizedBox(height: 16),
            const Text('Đưa món ăn vào khung rồi chạm nút chụp',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 5),
            const Text('Ảnh sẽ được gửi lên AI để ước tính dinh dưỡng',
                style: TextStyle(color: Colors.white38, fontSize: 11)),
          ]));
        })),

        // ── Buttons ──
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _sideBtn(Icons.photo_library_rounded, 'Thư viện', _pickGallery),
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
      onTap: _analyzing ? null : _capturePhoto,
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
            BoxShadow(
                color: AppTheme.accent.withOpacity(0.5),
                blurRadius: 28,
                spreadRadius: 2),
          ],
        ),
        child:
            const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 34),
      ),
    );
  }

  Widget _sideBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.09),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Icon(icon, color: Colors.white70, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
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
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: AppTheme.accent,
              backgroundColor: AppTheme.accent.withOpacity(0.2),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Đang phân tích...',
            style: TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
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
  Future<void> _pickGallery() async {
    HapticFeedback.mediumImpact();
    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );
    } catch (e) {
      _showError(
          'Không thể mở thư viện ảnh. Kiểm tra quyền truy cập trong cài đặt.\n$e');
      return;
    }
    if (picked == null || !mounted) return;
    await _analyzeImage(File(picked.path));
  }

  Future<void> _capturePhoto() async {
    HapticFeedback.mediumImpact();
    final camera = _cameraController;
    if (camera == null ||
        !camera.value.isInitialized ||
        camera.value.isTakingPicture) {
      _showError(
          _cameraError ?? 'Camera chưa sẵn sàng. Hãy thử lại sau giây lát.');
      return;
    }
    try {
      final photo = await camera.takePicture();
      if (mounted) await _analyzeImage(File(photo.path));
    } on CameraException catch (error) {
      if (mounted) _showError(_cameraMessage(error));
    } catch (error) {
      if (mounted) _showError('Không thể chụp ảnh: $error');
    }
  }

  Future<File> _jpegForUpload(File source) async {
    final directory = await getTemporaryDirectory();
    final outputPath =
        '${directory.path}${Platform.pathSeparator}caloai_food_${DateTime.now().microsecondsSinceEpoch}.jpg';
    final compressed = await FlutterImageCompress.compressAndGetFile(
      source.absolute.path,
      outputPath,
      minWidth: 1600,
      minHeight: 1600,
      quality: 88,
      format: CompressFormat.jpeg,
      keepExif: false,
    );
    if (compressed != null) {
      final jpeg = File(compressed.path);
      if (await jpeg.exists() && await jpeg.length() > 0) return jpeg;
    }

    // Some Android gallery providers expose a valid image with a misleading
    // extension or MIME type. If it is already a supported bitstream, copy it
    // under its real extension so MultipartFile sends the matching MIME type.
    final format = await _imageFormat(source);
    if (format != null) {
      final normalized = File(
          '${directory.path}${Platform.pathSeparator}caloai_food_${DateTime.now().microsecondsSinceEpoch}.$format');
      return normalized.writeAsBytes(await source.readAsBytes(), flush: true);
    }
    if (compressed != null) {
      throw Exception(
          'Ảnh sau khi chuyển đổi bị rỗng. Hãy chụp hoặc chọn lại ảnh.');
    }
    throw Exception(
        'Không thể chuẩn hóa ảnh này. Hãy chọn JPEG, PNG hoặc WebP, hoặc chụp trực tiếp trong CaloAI.');
  }

  Future<String?> _imageFormat(File file) async {
    final raf = await file.open();
    try {
      final bytes = await raf.read(12);
      if (bytes.length >= 3 &&
          bytes[0] == 0xff &&
          bytes[1] == 0xd8 &&
          bytes[2] == 0xff) {
        return 'jpg';
      }
      if (bytes.length >= 8 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4e &&
          bytes[3] == 0x47) {
        return 'png';
      }
      if (bytes.length >= 12 &&
          String.fromCharCodes(bytes.sublist(0, 4)) == 'RIFF' &&
          String.fromCharCodes(bytes.sublist(8, 12)) == 'WEBP') {
        return 'webp';
      }
      return null;
    } finally {
      await raf.close();
    }
  }

  Future<void> _analyzeImage(File source) async {
    if (!mounted) return;
    final language = context.read<LanguageProvider>().code;

    setState(() {
      _analyzing = true;
      _status = 'Đang chuẩn hóa ảnh...';
    });

    try {
      final jpeg = await _jpegForUpload(source);
      if (!mounted) return;
      setState(() => _status = 'Đang nhận diện món ăn...');
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _status = 'Đang tính calo và dinh dưỡng...');

      final result = await _gemini.analyzeFood(jpeg, language: language);

      if (!mounted) return;
      setState(() => _analyzing = false);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            result: result,
            imageFile: jpeg,
            mealType: widget.mealType,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _analyzing = false);
      final message = e.toString().replaceAll('Exception: ', '');
      _showError(message.contains('Upload a JPEG, PNG, or WebP')
          ? 'Ảnh chưa được chuyển về JPEG phù hợp. Hãy chọn lại ảnh hoặc chụp trực tiếp trong CaloAI.'
          : message);
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
        content: Text(message,
            style: const TextStyle(color: AppTheme.textSecondary)),
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
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('💡 Mẹo để đạt kết quả tốt nhất',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
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
            const Icon(Icons.check_circle_rounded,
                color: AppTheme.green, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(tip,
                  style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      height: 1.4)),
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
  const _ScanFrame();
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        children: [
          // Viewfinder corners overlay the live preview.
          Positioned(top: 0, left: 0, child: _Corner(top: true, left: true)),
          Positioned(top: 0, right: 0, child: _Corner(top: true, left: false)),
          Positioned(
              bottom: 0, left: 0, child: _Corner(top: false, left: true)),
          Positioned(
              bottom: 0, right: 0, child: _Corner(top: false, left: false)),
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
      ..color = AppTheme.accent
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;

    if (top && left) {
      canvas.drawLine(Offset(0, h), Offset(0, 0), paint);
      canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
    }
    if (top && !left) {
      canvas.drawLine(Offset(0, 0), Offset(w, 0), paint);
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
    }
    if (!top && left) {
      canvas.drawLine(Offset(0, 0), Offset(0, h), paint);
      canvas.drawLine(Offset(0, h), Offset(w, h), paint);
    }
    if (!top && !left) {
      canvas.drawLine(Offset(w, 0), Offset(w, h), paint);
      canvas.drawLine(Offset(w, h), Offset(0, h), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
