import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProScreen extends StatelessWidget {
  const ProScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return CustomScrollView(slivers: [
      SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 120),
          sliver: SliverList.list(children: [
            Text('CaloAI Pro',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text('Cá nhân hóa hành trình dinh dưỡng của bạn',
                style: TextStyle(color: p.textSecondary)),
            const SizedBox(height: 22),
            Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      p.brand,
                      Color.lerp(p.brand, Colors.black, 0.2)!
                    ]),
                    borderRadius: BorderRadius.circular(28)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 30),
                      const SizedBox(height: 18),
                      const Text('Tiến gần hơn\nđến mục tiêu',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 10),
                      Text(
                          'Kế hoạch bữa ăn và theo dõi dinh dưỡng thuận tiện trong một nơi.',
                          style: TextStyle(
                              color: Colors.white.withOpacity(.82),
                              height: 1.4)),
                      const SizedBox(height: 22),
                      for (final t in [
                        'Gợi ý bữa ăn theo mục tiêu',
                        'Theo dõi lượng ăn và dinh dưỡng',
                        'Lưu công thức yêu thích'
                      ])
                        Padding(
                            padding: const EdgeInsets.only(bottom: 11),
                            child: Row(children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 9),
                              Text(t,
                                  style: const TextStyle(color: Colors.white))
                            ]))
                    ])),
            const SizedBox(height: 22),
            Text('Chọn kế hoạch',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            for (final plan in [
              ('Kế hoạch 1 tháng', 'Linh hoạt theo tháng'),
              ('Kế hoạch 12 tháng', 'Tiết kiệm hơn')
            ])
              Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(17),
                  decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: p.outline)),
                  child: Row(children: [
                    Icon(Icons.workspace_premium_outlined, color: p.brand),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(plan.$1,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Text(plan.$2,
                              style: TextStyle(
                                  color: p.textSecondary, fontSize: 12))
                        ])),
                    Text('Sắp có',
                        style: TextStyle(
                            color: p.brand, fontWeight: FontWeight.w700))
                  ])),
            const SizedBox(height: 12),
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: p.surface, borderRadius: BorderRadius.circular(18)),
                child: Text(
                    'Thanh toán và đăng ký gói chưa được kết nối trong phiên bản này.',
                    style: TextStyle(color: p.textSecondary, height: 1.4))),
            const SizedBox(height: 18),
            Text('Chia sẻ trải nghiệm',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                    color: p.surface, borderRadius: BorderRadius.circular(18)),
                child: Text(
                    '“Ứng dụng giúp tôi nhìn rõ hơn thói quen ăn uống mỗi ngày.”\n\n— Người dùng CaloAI',
                    style: TextStyle(color: p.textSecondary, height: 1.5)))
          ]))
    ]);
  }
}
