import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'providers/lifestyle_provider.dart';
import 'providers/language_provider.dart';
import 'screens/welcome_screen.dart';
import 'screens/main_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final appProvider = AppProvider();
  await appProvider.init();
  final lifestyleProvider = LifestyleProvider();
  await lifestyleProvider.init();
  final languageProvider = LanguageProvider();
  await languageProvider.init();

  // Load saved user profile (update calorie goals if exists)
  final authService = AuthService();
  final profile = await authService.loadCachedProfileForSession();
  if (profile != null) {
    await lifestyleProvider.configureMeasurements(
      weight: profile.weight,
      targetWeight: profile.targetWeight,
      height: profile.height,
      age: profile.age,
      sex: profile.sex,
      activity: profile.activity,
      goal: profile.goal,
      rate: profile.rate,
    );
    await appProvider.updateCalorieGoal(profile.dailyCalories);
    await appProvider.updateMacroGoals(
      protein: profile.proteinGoal,
      carbs: profile.carbsGoal,
      fat: profile.fatGoal,
    );
  }

  final onboarded = profile != null;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
        ChangeNotifierProvider.value(value: lifestyleProvider),
        ChangeNotifierProvider.value(value: languageProvider),
      ],
      child: CaloAIApp(skipOnboarding: onboarded),
    ),
  );
}

class CaloAIApp extends StatelessWidget {
  final bool skipOnboarding;
  const CaloAIApp({super.key, required this.skipOnboarding});

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageProvider>();
    return MaterialApp(
      title: 'CaloAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      locale: language.locale,
      supportedLocales: LanguageProvider.options
          .map((option) => Locale(option.code))
          .toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: skipOnboarding ? const MainScreen() : const WelcomeScreen(),
      builder: (context, child) {
        final brightness = Theme.of(context).brightness;
        final dark = brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
          statusBarBrightness: dark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
          systemNavigationBarIconBrightness:
              dark ? Brightness.light : Brightness.dark,
        ));
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.85, 1.15),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
