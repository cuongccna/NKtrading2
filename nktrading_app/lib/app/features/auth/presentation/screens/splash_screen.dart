import 'package:flutter/material.dart';
import 'package:nktrading_app/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import '../../../../core/presentation/screens/main_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sử dụng StreamBuilder để lắng nghe và tự động cập nhật giao diện
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Trong khi chờ dữ liệu đầu tiên, hiển thị màn hình chờ
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Khi có dữ liệu, kiểm tra xem người dùng đã đăng nhập hay chưa
        final session = snapshot.data?.session;
        if (session != null) {
          // Nếu đã đăng nhập, hiển thị màn hình chính
          return const MainScreen();
        } else {
          // Nếu chưa đăng nhập, hiển thị màn hình đăng nhập
          return const LoginScreen();
        }
      },
    );
  }
}
