import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'providers/timer_provider.dart';
import 'services/storage_service.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  final storageService = StorageService();
  await storageService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),
        ChangeNotifierProvider(create: (_) => TimerProvider(storageService)),
      ],
      child: const RunRestApp(),
    ),
  );
}

class RunRestApp extends StatelessWidget {
  const RunRestApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();

    return MaterialApp(
      title: 'Run / Rest',
      debugShowCheckedModeBanner: false,
      themeMode: themeProv.getThemeMode(),
      theme: themeProv.getLightTheme(),
      darkTheme: themeProv.getDarkTheme(),
      home: const HomeScreen(),
      builder: (context, child) {
        // Handle AMOLED mode if selected
        if (themeProv.mode == AppThemeMode.amoled) {
          return Theme(
            data: themeProv.getAmoledTheme(),
            child: child ?? const SizedBox(),
          );
        }
        return child ?? const SizedBox();
      },
    );
  }
}
