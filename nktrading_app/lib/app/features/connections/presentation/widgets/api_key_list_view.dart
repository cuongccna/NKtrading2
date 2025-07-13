import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../main.dart';
import 'add_api_key_dialog.dart';

class ApiKeyListView extends StatefulWidget {
  const ApiKeyListView({super.key});

  @override
  State<ApiKeyListView> createState() => _ApiKeyListViewState();
}

class _ApiKeyListViewState extends State<ApiKeyListView> {
  late Future<List<Map<String, dynamic>>> _keysFuture;
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

  Future<void> _syncTrades(String keyId, String exchange) async {
    if (_syncingStatus[keyId] == true) return;

    setState(() => _syncingStatus[keyId] = true);

    final l10n = AppLocalizations.of(context)!;

    try {
      if (exchange.toLowerCase() != 'binance') {
        throw 'Chức năng đồng bộ cho sàn $exchange chưa được hỗ trợ.';
      }

      final result = await supabase.functions.invoke('sync-binance-trades');

      if (mounted) {
        final data = result.data as Map<String, dynamic>?;
        final message = data?['message'] ?? 'Hoàn tất!';
        final errors = data?['errors'] as List<dynamic>?;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message),
                if (errors != null && errors.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Một số lỗi: ${errors.first}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            backgroundColor: errors?.isNotEmpty == true
                ? Colors.orange
                : Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        // Refresh danh sách nếu có dữ liệu được đồng bộ
        final syncedCount = data?['syncedCount'] as int?;
        if (syncedCount != null && syncedCount > 0) {
          _refreshKeys();
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Lỗi đồng bộ: ';
        if (e.toString().contains('Rate limit')) {
          errorMessage += 'Vượt giới hạn yêu cầu. Vui lòng thử lại sau.';
        } else if (e.toString().contains('Invalid API key')) {
          errorMessage += 'API key không hợp lệ. Vui lòng kiểm tra lại.';
        } else if (e.toString().contains('No trading symbols')) {
          errorMessage += 'Không tìm thấy cặp giao dịch nào để đồng bộ.';
        } else {
          errorMessage += e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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
