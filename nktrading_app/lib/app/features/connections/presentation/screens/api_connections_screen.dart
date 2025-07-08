import 'package:flutter/material.dart';
import '../widgets/api_key_list_view.dart';
import '../widgets/wallet_list_view.dart';

class ApiConnectionsScreen extends StatelessWidget {
  const ApiConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Không cần TabController ở đây nữa
    return const Column(
      children: [
        Expanded(child: ApiKeyListView()),
        Divider(height: 1),
        Expanded(child: WalletListView()),
      ],
    );
  }
}
