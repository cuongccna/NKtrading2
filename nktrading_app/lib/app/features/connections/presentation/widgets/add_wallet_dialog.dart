import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../main.dart';

class AddWalletDialog extends StatefulWidget {
  const AddWalletDialog({super.key});

  @override
  State<AddWalletDialog> createState() => _AddWalletDialogState();
}

class _AddWalletDialogState extends State<AddWalletDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _addressController = TextEditingController();
  String _selectedBlockchain = 'BSC';
  bool _isLoading = false;

  Future<void> _saveWallet() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // *** FIX: Lấy ID của người dùng hiện tại ***
      final userId = supabase.auth.currentUser!.id;

      await supabase.from('user_wallets').insert({
        'user_id': userId, // Thêm user_id vào dữ liệu gửi đi
        'label': _labelController.text,
        'address': _addressController.text.trim(),
        'blockchain': _selectedBlockchain,
      });

      if (mounted) {
        Navigator.of(context).pop(true); // Trả về true để báo thành công
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.addWallet),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedBlockchain,
                decoration: InputDecoration(labelText: l10n.blockchain),
                items: ['BSC', 'Ethereum']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedBlockchain = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _labelController,
                decoration: InputDecoration(labelText: l10n.label),
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: l10n.walletAddress),
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveWallet,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }
}
