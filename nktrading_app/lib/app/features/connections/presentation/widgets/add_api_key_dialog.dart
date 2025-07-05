import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
// Nhiệm vụ 3.3 sẽ xử lý việc mã hóa và lưu, hiện tại chỉ có giao diện
import '../../../../../main.dart'; // Import để dùng supabase client

class AddApiKeyDialog extends StatefulWidget {
  const AddApiKeyDialog({super.key});

  @override
  State<AddApiKeyDialog> createState() => _AddApiKeyDialogState();
}

class _AddApiKeyDialogState extends State<AddApiKeyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();
  String _selectedExchange = 'Binance';
  bool _hasAgreed = false;
  bool _isLoading = false;

  // *** FIX: Cập nhật hàm để gọi Edge Function ***
  Future<void> _saveApiKey() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bạn phải đồng ý với điều khoản bảo mật.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Gọi đến function 'add-api-key' đã deploy
      await supabase.functions.invoke(
        'add-api-key',
        body: {
          'exchange': _selectedExchange,
          'label': _labelController.text,
          'apiKey': _apiKeyController.text,
          'apiSecret': _apiSecretController.text,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu kết nối thành công!')),
        );
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
      title: Text(l10n.addApiKey),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedExchange,
                decoration: InputDecoration(labelText: l10n.exchange),
                items: ['Binance', 'Kucoin', 'Bybit']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedExchange = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _labelController,
                decoration: InputDecoration(labelText: l10n.label),
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(labelText: l10n.apiKey),
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _apiSecretController,
                decoration: InputDecoration(labelText: l10n.apiSecret),
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 24),
              // Cảnh báo bảo mật
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.importantNotice,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade200,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.readOnlyWarning),
                  ],
                ),
              ),
              CheckboxListTile(
                title: Text(
                  l10n.iUnderstand,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: _hasAgreed,
                onChanged: (val) => setState(() => _hasAgreed = val!),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
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
          onPressed: _isLoading ? null : _saveApiKey,
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
