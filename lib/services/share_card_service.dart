import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/meal_entry.dart';

class ShareCardService {
  static Future<void> shareMeal({
    required String title,
    required List<MealEntry> meals,
    String? imagePath,
  }) async {
    final calories = meals.fold<int>(0, (sum, meal) => sum + meal.calories);
    final protein = meals.fold<double>(0, (sum, meal) => sum + meal.protein);
    final carbs = meals.fold<double>(0, (sum, meal) => sum + meal.carbs);
    final fat = meals.fold<double>(0, (sum, meal) => sum + meal.fat);
    final file = await _render(
      heading: title,
      subheading: meals.isEmpty
          ? 'A fresh start, one meal at a time.'
          : meals.map((m) => m.name).join(' · '),
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      imagePath: imagePath,
      footer: 'Tracked with CaloAI',
    );
    await Share.shareXFiles([XFile(file.path)],
        text: '$title · $calories kcal');
  }

  static Future<void> shareSuccess({
    required DateTime date,
    required int calories,
    required int goal,
    required int meals,
    required int activeDays,
    required int greenDays,
    required double weightChange,
  }) async {
    final file = await _render(
      heading: 'A day worth celebrating',
      subheading:
          '${date.day}/${date.month}/${date.year}  ·  $activeDays active days',
      calories: calories,
      protein: 0,
      carbs: 0,
      fat: 0,
      footer:
          '$meals meals logged  ·  $greenDays green days  ·  ${weightChange >= 0 ? '+' : ''}${weightChange.toStringAsFixed(1)} kg  ·  CaloAI',
      imagePath: null,
      goal: goal,
    );
    await Share.shareXFiles([XFile(file.path)], text: 'My CaloAI progress');
  }

  static Future<File> _render({
    required String heading,
    required String subheading,
    required int calories,
    required double protein,
    required double carbs,
    required double fat,
    required String footer,
    required String? imagePath,
    int? goal,
  }) async {
    const size = Size(1080, 1350);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE3FFF7), Color(0xFFF8F7FF), Color(0xFFE6F6EE)],
        ).createShader(bounds),
    );
    final card = RRect.fromRectAndRadius(
      const Rect.fromLTWH(54, 76, 972, 1198),
      const Radius.circular(56),
    );
    canvas.drawRRect(card, Paint()..color = Colors.white.withOpacity(.94));

    if (imagePath != null) {
      final imageFile = File(imagePath);
      if (await imageFile.exists()) {
        try {
          final codec =
              await ui.instantiateImageCodec(await imageFile.readAsBytes());
          final frame = await codec.getNextFrame();
          codec.dispose();
          final image = frame.image;
          final target = RRect.fromRectAndRadius(
            const Rect.fromLTWH(92, 116, 896, 470),
            const Radius.circular(38),
          );
          canvas.save();
          canvas.clipRRect(target);
          final src = _coverRect(image.width.toDouble(),
              image.height.toDouble(), target.outerRect);
          canvas.drawImageRect(image, src, target.outerRect,
              Paint()..filterQuality = FilterQuality.high);
          canvas.restore();
          image.dispose();
        } catch (_) {
          // Keep the designed background when an old image file is unavailable.
        }
      }
    } else {
      _text(canvas, '🥗', const Offset(465, 170), 130);
      _text(canvas, 'A delicious day begins with small choices',
          const Offset(130, 375), 32,
          color: const Color(0xFF64746F),
          maxWidth: 820,
          align: TextAlign.center);
    }

    final titleY = imagePath == null ? 535.0 : 635.0;
    _text(canvas, heading, Offset(100, titleY), 54,
        weight: FontWeight.w800, maxWidth: 880);
    _text(canvas, subheading, Offset(100, titleY + 78), 27,
        color: const Color(0xFF65716E), maxWidth: 880);
    final kcalY = titleY + 175;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(94, kcalY, 892, 185), const Radius.circular(34)),
      Paint()..color = const Color(0xFF123D32),
    );
    _text(canvas, '$calories', Offset(135, kcalY + 30), 72,
        color: Colors.white, weight: FontWeight.w800);
    _text(canvas, goal == null ? 'kcal' : 'kcal  /  $goal kcal goal',
        Offset(140, kcalY + 118), 28,
        color: const Color(0xFFC7E5DC));

    if (goal != null) {
      _text(
          canvas,
          '${(calories - goal).abs()} kcal ${calories >= goal ? 'above' : 'to goal'}',
          Offset(140, kcalY + 150),
          22,
          color: const Color(0xFFC7E5DC));
    } else {
      final macroY = kcalY + 220;
      _macro(canvas, 'PROTEIN', '${protein.toStringAsFixed(1)} g',
          Offset(110, macroY));
      _macro(canvas, 'CARBS', '${carbs.toStringAsFixed(1)} g',
          Offset(408, macroY));
      _macro(canvas, 'FAT', '${fat.toStringAsFixed(1)} g', Offset(706, macroY));
      final names = subheading.split(' · ');
      _text(canvas, 'TODAY\'S PLATE', const Offset(110, 1040), 22,
          color: const Color(0xFF138E72), weight: FontWeight.w700);
      for (var i = 0; i < names.length && i < 3; i++) {
        _text(canvas, '•  ${names[i]}', Offset(112, 1080 + i * 46), 27,
            color: const Color(0xFF263A35), maxWidth: 820);
      }
    }
    _text(canvas, footer, const Offset(110, 1190), 23,
        color: const Color(0xFF72817D), maxWidth: 850);

    final picture = recorder.endRecording();
    final image =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    if (bytes == null) throw StateError('Could not render share card.');
    final directory = await getTemporaryDirectory();
    final file = File(
        '${directory.path}/caloai_share_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return file;
  }

  static Rect _coverRect(double sourceWidth, double sourceHeight, Rect target) {
    final sourceRatio = sourceWidth / sourceHeight;
    final targetRatio = target.width / target.height;
    if (sourceRatio > targetRatio) {
      final width = sourceHeight * targetRatio;
      return Rect.fromLTWH((sourceWidth - width) / 2, 0, width, sourceHeight);
    }
    final height = sourceWidth / targetRatio;
    return Rect.fromLTWH(0, (sourceHeight - height) / 2, sourceWidth, height);
  }

  static void _macro(Canvas canvas, String label, String value, Offset origin) {
    _text(canvas, value, origin, 35,
        color: const Color(0xFF123D32), weight: FontWeight.w700);
    _text(canvas, label, origin.translate(0, 47), 18,
        color: const Color(0xFF72817D), weight: FontWeight.w600);
  }

  static void _text(Canvas canvas, String text, Offset offset, double fontSize,
      {Color color = const Color(0xFF17221F),
      FontWeight weight = FontWeight.w500,
      double? maxWidth,
      TextAlign align = TextAlign.left}) {
    final painter = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: fontSize,
              color: color,
              fontWeight: weight,
              height: 1.2)),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 3,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? 850);
    painter.paint(canvas, offset);
  }
}
