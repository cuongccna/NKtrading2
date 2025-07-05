import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../main.dart';
import 'add_wallet_dialog.dart';

class WalletListView extends StatefulWidget {
  const WalletListView({super.key});

  @override
  State<WalletListView> createState() => _WalletListViewState();
}

class _WalletListViewState extends State<WalletListView> {
  late Future<List<Map<String, dynamic>>> _walletsFuture;
  // State để quản lý trạng thái đang đồng bộ cho từng ví
  final Map<String, bool> _syncingStatus = {};

  @override
  void initState() {
    super.initState();
    _walletsFuture = _fetchWallets();
  }

  Future<List<Map<String, dynamic>>> _fetchWallets() {
    return supabase.from('user_wallets').select();
  }

  void _refreshWallets() {
    setState(() {
      _walletsFuture = _fetchWallets();
    });
  }

  Future<void> _deleteWallet(String id) async {
    try {
      await supabase.from('user_wallets').delete().match({'id': id});
      _refreshWallets();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa ví: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // *** NEW: Hàm để kích hoạt đồng bộ hóa on-chain ***
  Future<void> _syncOnChainTrades(
    String walletId,
    String walletAddress,
    String blockchain,
  ) async {
    if (_syncingStatus[walletId] == true) return;

    setState(() => _syncingStatus[walletId] = true);

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${l10n.syncing} ${blockchain}...')));

    try {
      final result = await supabase.functions.invoke(
        'sync-onchain-trades',
        body: {'walletAddress': walletAddress, 'blockchain': blockchain},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.data['message'] ?? 'Hoàn tất!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đồng bộ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncingStatus[walletId] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _walletsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final wallets = snapshot.data!;
          if (wallets.isEmpty) {
            return Center(child: Text(l10n.noWallets));
          }
          return ListView.builder(
            itemCount: wallets.length,
            itemBuilder: (context, index) {
              final wallet = wallets[index];
              final walletId = wallet['id'] as String;
              final address = wallet['address'] as String;
              final blockchain = wallet['blockchain'] as String;
              final isSyncing = _syncingStatus[walletId] ?? false;

              return ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: Text(wallet['label'] ?? 'Unnamed Wallet'),
                subtitle: Text(
                  '$blockchain: ${address.substring(0, 6)}...${address.substring(address.length - 4)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nút đồng bộ
                    isSyncing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.sync),
                            onPressed: () => _syncOnChainTrades(
                              walletId,
                              address,
                              blockchain,
                            ),
                            tooltip: l10n.syncWallet,
                          ),
                    // Nút xóa
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _deleteWallet(walletId),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final success = await showDialog<bool>(
            context: context,
            builder: (_) => const AddWalletDialog(),
          );
          if (success == true) {
            _refreshWallets();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.addWallet),
      ),
    );
  }
}
