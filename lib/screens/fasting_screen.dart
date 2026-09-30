import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lifestyle_provider.dart';
import '../theme/app_theme.dart';

class FastingScreen extends StatefulWidget {
  const FastingScreen({super.key});
  @override
  State<FastingScreen> createState() => _FastingScreenState();
}

class _FastingScreenState extends State<FastingScreen> {
  Timer? _ticker;
  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Consumer<LifestyleProvider>(builder: (context, life, _) {
      final active = life.fastStartedAt != null;
      final elapsed = life.currentFastDuration;
      final progress =
          (elapsed.inMinutes / (life.fastGoalHours * 60)).clamp(0.0, 1.0);
      return CustomScrollView(physics: const BouncingScrollPhysics(), slivers: [
        SliverPadding(
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 120),
            sliver: SliverList.list(children: [
              Text('Nhịn ăn',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 5),
              Text('Theo dõi khung giờ ăn và nhịn ăn của bạn',
                  style: TextStyle(color: p.textSecondary)),
              const SizedBox(height: 24),
              Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(28)),
                  child: Column(children: [
                    Row(children: [
                      const Icon(Icons.nights_stay_outlined),
                      const SizedBox(width: 9),
                      Text(active ? 'ĐANG NHỊN ĂN' : 'KẾ HOẠCH HÔM NAY',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, letterSpacing: 1))
                    ]),
                    const SizedBox(height: 22),
                    SizedBox(
                        width: 210,
                        height: 210,
                        child: Stack(alignment: Alignment.center, children: [
                          SizedBox.expand(
                              child: CircularProgressIndicator(
                                  value: active ? progress : 0,
                                  strokeWidth: 13,
                                  backgroundColor: p.surfaceRaised,
                                  color: p.brand,
                                  strokeCap: StrokeCap.round)),
                          Column(mainAxisSize: MainAxisSize.min, children: [
                            Text(
                                active
                                    ? _duration(elapsed)
                                    : '${life.fastGoalHours}:00',
                                style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w700,
                                    color: p.textPrimary)),
                            Text(active ? 'đã nhịn' : 'giờ nhịn',
                                style: TextStyle(color: p.textSecondary))
                          ])
                        ])),
                    const SizedBox(height: 18),
                    Text(
                        active
                            ? 'Bắt đầu ${_time(life.fastStartedAt!)}  ·  Mục tiêu ${life.fastGoalHours} giờ'
                            : 'Khung ăn dự kiến 12:00 – 20:00',
                        style: TextStyle(color: p.textSecondary)),
                    const SizedBox(height: 20),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                            onPressed: () async {
                              if (active) {
                                final result = await life.endFast();
                                if (context.mounted && result != null)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              'Đã lưu phiên ${_duration(result.duration)}')));
                              } else {
                                await life.startFast();
                              }
                            },
                            child: Text(active
                                ? 'Kết thúc nhịn ăn'
                                : 'Bắt đầu nhịn ăn'))),
                  ])),
              const SizedBox(height: 20),
              _card(context,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chọn lịch nhịn ăn',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 14),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          for (final h in [12, 14, 16, 18, 20])
                            ChoiceChip(
                                label: Text('$h:${24 - h}'),
                                selected: life.fastGoalHours == h,
                                onSelected: active
                                    ? null
                                    : (_) => life.startFast(hours: h))
                        ]),
                        const SizedBox(height: 8),
                        Text(
                            'Ví dụ 16:8 nghĩa là nhịn 16 giờ và ăn trong khung 8 giờ.',
                            style:
                                TextStyle(color: p.textSecondary, fontSize: 12))
                      ])),
              const SizedBox(height: 18),
              _card(context,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lịch sử',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        if (life.fastHistory.isEmpty)
                          Text('Các phiên đã hoàn thành sẽ hiện ở đây.',
                              style: TextStyle(color: p.textSecondary))
                        else
                          for (final entry in life.fastHistory.take(5))
                            ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: Icon(Icons.check_circle_outline,
                                    color: p.brand),
                                title: Text(_duration(entry.duration)),
                                subtitle: Text(
                                    '${entry.startedAt.day}/${entry.startedAt.month} · ${_time(entry.startedAt)}'),
                                trailing: const Icon(Icons.chevron_right))
                      ])),
              const SizedBox(height: 18),
              _card(context,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bắt đầu nhẹ nhàng',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                            'Chọn khung giờ phù hợp với lịch sinh hoạt của bạn. Có thể dừng bất cứ lúc nào nếu thấy không khỏe.',
                            style:
                                TextStyle(color: p.textSecondary, height: 1.45))
                      ]))
            ]))
      ]);
    });
  }

  Widget _card(BuildContext c, {required Widget child}) => Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: c.palette.surface, borderRadius: BorderRadius.circular(22)),
      child: child);
  String _duration(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}';
  String _time(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
