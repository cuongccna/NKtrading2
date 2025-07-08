import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../main.dart';
import 'api_connections_screen.dart'; // Import màn hình con

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _preferredCurrency;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('user_profiles')
          .select('preferred_currency')
          .eq('id', userId)
          .single();
      if (mounted) {
        setState(() {
          _preferredCurrency = data['preferred_currency'] ?? 'USD';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _preferredCurrency = 'USD'; // Fallback
        });
      }
    }
  }

  Future<void> _updateCurrency(String? newCurrency) async {
    if (newCurrency == null) return;
    final userId = supabase.auth.currentUser!.id;
    try {
      await supabase
          .from('user_profiles')
          .update({'preferred_currency': newCurrency})
          .eq('id', userId);
      if (mounted) {
        setState(() {
          _preferredCurrency = newCurrency;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật đơn vị tiền tệ!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.settings),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.general),
              Tab(text: l10n.connections),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab Cài đặt chung
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_preferredCurrency == null)
                  const Center(child: CircularProgressIndicator())
                else
                  ListTile(
                    title: Text(l10n.currency),
                    trailing: DropdownButton<String>(
                      value: _preferredCurrency,
                      items: [
                        DropdownMenuItem(
                          value: 'USD',
                          child: Text(l10n.usDollar),
                        ),
                        DropdownMenuItem(
                          value: 'VND',
                          child: Text(l10n.vietnameseDong),
                        ),
                      ],
                      onChanged: _updateCurrency,
                    ),
                  ),
              ],
            ),
            // Tab Kết nối
            const ApiConnectionsScreen(),
          ],
        ),
      ),
    );
  }
}
