// File: lib/main.dart
// Nội dung: Khởi tạo Supabase và thiết lập màn hình chờ (Splash Screen)

import 'package:flutter/material.dart';
import 'package:nktrading_app/l10n/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/features/auth/presentation/screens/splash_screen.dart';

// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Import file được tạo tự động

// *** THAY THẾ VỚI THÔNG TIN SUPABASE CỦA BẠN ***
const String supabaseUrl =
    'https://yzeuoubfqtpnsqyvrukc.supabase.co'; // Dán URL của bạn vào đây
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl6ZXVvdWJmcXRwbnNxeXZydWtjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEzODQwMjAsImV4cCI6MjA2Njk2MDAyMH0.58zzghJ0P4Vd_HxmudorLx-W8gHFUR5hsdNUs-OQeh0'; // Dán anon key của bạn vào đây

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  runApp(const NKTradingApp());
}

final supabase = Supabase.instance.client;

class NKTradingApp extends StatefulWidget {
  const NKTradingApp({super.key});

  @override
  State<NKTradingApp> createState() => _NKTradingAppState();

  // Hàm static để các widget con có thể thay đổi ngôn ngữ
  static void setLocale(BuildContext context, Locale newLocale) {
    _NKTradingAppState? state = context
        .findAncestorStateOfType<_NKTradingAppState>();
    state?.setLocale(newLocale);
  }
}

class _NKTradingAppState extends State<NKTradingApp> {
  // *** FIX: Đặt locale mặc định là 'vi' ***
  Locale? _locale = const Locale('vi');

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NKTRADING',
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: _locale, // Sử dụng locale từ state
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueGrey,
          brightness: Brightness.dark,
        ),
        // ... (các theme khác giữ nguyên)
      ),
      home: const SplashScreen(),
    );
  }
}
