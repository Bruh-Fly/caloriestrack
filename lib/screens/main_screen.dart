import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/app_text.dart';
import 'profile_screen.dart';
import 'pro_screen.dart';
import 'recipes_screen.dart';
import 'today_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;
  static const _screens = [
    TodayScreen(),
    RecipesScreen(),
    ProfileScreen(),
    ProScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
        backgroundColor: p.background,
        body: IndexedStack(index: _index, children: _screens),
        bottomNavigationBar: Container(
            decoration: BoxDecoration(color: p.surface, boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(.05),
                  blurRadius: 18,
                  offset: const Offset(0, -4))
            ]),
            child: SafeArea(
                top: false,
                child: SizedBox(
                    height: 62,
                    child: Row(children: [
                      _item(0, Icons.bookmark_border, Icons.bookmark,
                          context.tr('Diary', 'Nhật ký')),
                      _item(
                          1,
                          Icons.restaurant_menu_outlined,
                          Icons.restaurant_menu,
                          context.tr('Recipes', 'Công thức')),
                      _item(2, Icons.person_outline, Icons.person,
                          context.tr('Profile', 'Hồ sơ')),
                      _item(3, Icons.workspace_premium_outlined,
                          Icons.workspace_premium, context.tr('Pro', 'Pro'))
                    ])))));
  }

  Widget _item(int i, IconData icon, IconData active, String label) {
    final selected = _index == i;
    final p = context.palette;
    return Expanded(
        child: InkWell(
            onTap: () => setState(() => _index = i),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(selected ? active : icon,
                  color: selected ? p.brand : p.textSecondary, size: 21),
              const SizedBox(height: 3),
              Text(label,
                  style: TextStyle(
                      color: selected ? p.brand : p.textSecondary,
                      fontSize: 9,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500))
            ])));
  }
}
