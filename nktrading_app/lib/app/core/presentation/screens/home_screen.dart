// File: lib/app/core/presentation/screens/home_screen.dart (MỚI)
// Nội dung: Màn hình chính sau khi đăng nhập thành công

import 'package:flutter/material.dart';
import '../../../../main.dart'; // Để truy cập supabase client
import '../../../features/auth/presentation/screens/splash_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhật Ký Giao Dịch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Xử lý đăng xuất
              await supabase.auth.signOut();

              if (context.mounted) {
                // Điều hướng về màn hình chờ để kiểm tra lại
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: const Center(child: Text('Chào mừng! Đây là màn hình chính.')),
    );
  }
}
