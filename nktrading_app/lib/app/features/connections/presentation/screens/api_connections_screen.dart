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
              return ListTile(
                leading: const Icon(Icons.vpn_key_outlined),
                title: Text(key['label'] ?? 'Unnamed Key'),
                subtitle: Text(key['exchange']),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => _deleteKey(key['id']),
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
