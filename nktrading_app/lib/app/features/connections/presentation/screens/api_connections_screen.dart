import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../widgets/api_key_list_view.dart';
import '../widgets/wallet_list_view.dart';

class ApiConnectionsScreen extends StatefulWidget {
  const ApiConnectionsScreen({super.key});

  @override
  State<ApiConnectionsScreen> createState() => _ApiConnectionsScreenState();
}

class _ApiConnectionsScreenState extends State<ApiConnectionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.connections),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.apiKeys),
            Tab(text: l10n.wallets),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [ApiKeyListView(), WalletListView()],
      ),
    );
  }
}
