import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/call_provider.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final callProvider = CallProvider();
  await callProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: callProvider),
      ],
      child: const WebRTCApp(),
    ),
  );
}

class WebRTCApp extends StatelessWidget {
  const WebRTCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'مكالمات WebRTC المحلية',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF10B981),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF10B981),
          secondary: Color(0xFF064E3B),
          surface: Color(0xFF1E293B),
        ),
        fontFamily: 'Tajawal',
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
