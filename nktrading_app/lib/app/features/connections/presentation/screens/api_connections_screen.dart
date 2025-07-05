import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../main.dart';
import '../widgets/add_api_key_dialog.dart';

class ApiConnectionsScreen extends StatefulWidget {
  const ApiConnectionsScreen({super.key});

  @override
  State<ApiConnectionsScreen> createState() => _ApiConnectionsScreenState();
}

class _ApiConnectionsScreenState extends State<ApiConnectionsScreen> {
  late Future<List<Map<String, dynamic>>> _keysFuture;
  // State để quản lý trạng thái đang đồng bộ cho từng key
  final Map<String, bool> _syncingStatus = {};

  @override
  void initState() {
    super.initState();
    _keysFuture = _fetchApiKeys();
  }

  Future<List<Map<String, dynamic>>> _fetchApiKeys() {
    return supabase.from('user_api_keys').select();
  }

  void _refreshKeys() {
    setState(() {
      _keysFuture = _fetchApiKeys();
    });
  }

  Future<void> _deleteKey(String id) async {
    try {
      await supabase.from('user_api_keys').delete().match({'id': id});
      _refreshKeys();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xóa key: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // *** NEW: Hàm để kích hoạt đồng bộ hóa ***
  Future<void> _syncTrades(String keyId, String exchange) async {
    if (_syncingStatus[keyId] == true) return; // Tránh nhấn nhiều lần

    setState(() => _syncingStatus[keyId] = true);

    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${l10n.syncing} ${exchange}...')));

    try {
      // Hiện tại chúng ta chỉ có function cho Binance
      if (exchange.toLowerCase() != 'binance') {
        throw 'Chức năng đồng bộ cho sàn $exchange chưa được hỗ trợ.';
      }

      final result = await supabase.functions.invoke('sync-binance-trades');

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
        setState(() => _syncingStatus[keyId] = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageApiKeys)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _keysFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          final keys = snapshot.data!;
          if (keys.isEmpty) {
            return Center(child: Text(l10n.noConnections));
          }
          return ListView.builder(
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final keyId = key['id'] as String;
              final isSyncing = _syncingStatus[keyId] ?? false;

              return ListTile(
                leading: const Icon(Icons.vpn_key_outlined),
                title: Text(key['label'] ?? 'Unnamed Key'),
                subtitle: Text(key['exchange']),
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
                            onPressed: () =>
                                _syncTrades(keyId, key['exchange']),
                            tooltip: l10n.sync,
                          ),
                    // Nút xóa
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                      onPressed: () => _deleteKey(keyId),
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
            builder: (_) => const AddApiKeyDialog(),
          );
          if (success == true) {
            _refreshKeys();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.addConnection),
      ),
    );
  }
}
