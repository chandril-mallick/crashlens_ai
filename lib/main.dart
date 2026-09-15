import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/crash_analysis_provider.dart';
import 'providers/history_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/app_shell.dart';
import 'screens/import_screen.dart';
import 'screens/analyzing_screen.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/model_manager_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait for Android
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling — dark background, light icons
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const CrashLensApp());
}

class CrashLensApp extends StatelessWidget {
  const CrashLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CrashAnalysisProvider()),
        ChangeNotifierProvider(create: (_) => HistoryProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final s = SettingsProvider();
            s.init();
            return s;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final m = ModelManagerService();
            m.init();
            return m;
          },
        ),
      ],
      child: MaterialApp(
        title: 'CrashLens AI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        initialRoute: '/',
        routes: {
          '/': (_) => const AppShell(),
          '/import': (_) => const ImportScreen(),
          '/analyzing': (_) => const AnalyzingScreen(),
          '/result': (_) => const ResultScreen(),
          '/history': (_) => const HistoryScreen(),
          '/settings': (_) => const SettingsScreen(),
        },
        // Edge-to-edge on Android
        builder: (context, child) {
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
            ),
            child: child!,
          );
        },
      ),
    );
  }
}
