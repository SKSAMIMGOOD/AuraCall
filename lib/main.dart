import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/services/local_db.dart';
import 'core/providers/app_providers.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Local Hive Database Cache
  final db = LocalDbService();
  await db.init();

  runApp(
    const ProviderScope(
      child: AuraCallApp(),
    ),
  );
}

class AuraCallApp extends ConsumerWidget {
  const AuraCallApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'AuraCall',
      debugShowCheckedModeBanner: false,
      
      // Theme toggles
      themeMode: settings.darkTheme ? ThemeMode.dark : ThemeMode.light,
      darkTheme: AppTheme.amoledDarkTheme,
      theme: AppTheme.lightGlassTheme,
      
      home: const SplashScreen(),
    );
  }
}
