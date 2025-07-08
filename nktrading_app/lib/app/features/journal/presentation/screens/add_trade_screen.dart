import 'dart:typed_data'; // Import để dùng Uint8List

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../main.dart';

import 'package:image_picker/image_picker.dart';

class AddTradeScreen extends StatefulWidget {
  final Map<String, dynamic>? initialTrade;
  const AddTradeScreen({super.key, this.initialTrade});

  @override
  State<AddTradeScreen> createState() => _AddTradeScreenState();
}

class _AddTradeScreenState extends State<AddTradeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _entryPriceController = TextEditingController();
  final _exitPriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _strategyController = TextEditingController();
  final _notesController = TextEditingController();
  final _emotionTagsController = TextEditingController();

  String _direction = 'Long';
  double _mindsetRating = 3.0;

  XFile? _beforeImageFile;
  String? _existingImageUrl;
  bool _isLoading = false;

  List<String> _strategyOptions = [];
  List<String> _emotionTagOptions = [];

  bool get _isEditMode => widget.initialTrade != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final trade = widget.initialTrade!;
      _symbolController.text = trade['symbol'] ?? '';
      _entryPriceController.text = trade['entry_price']?.toString() ?? '';
      _exitPriceController.text = trade['exit_price']?.toString() ?? '';
      _quantityController.text = trade['quantity']?.toString() ?? '';
      _strategyController.text = trade['strategy'] ?? '';
      _notesController.text = trade['notes'] ?? '';
      _emotionTagsController.text =
          (trade['emotion_tags'] as List<dynamic>?)?.join(', ') ?? '';
      _direction = trade['direction'] ?? 'Long';
      _mindsetRating = (trade['mindset_rating'] as int?)?.toDouble() ?? 3.0;
      _existingImageUrl = trade['before_image_url'];
    }
    _fetchAutocompleteOptions();
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _entryPriceController.dispose();
    _exitPriceController.dispose();
    _quantityController.dispose();
    _strategyController.dispose();
    _notesController.dispose();
    _emotionTagsController.dispose();
    super.dispose();
  }

  Future<void> _fetchAutocompleteOptions() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('trades')
          .select('strategy, emotion_tags')
          .eq('user_id', userId);

      final strategies = data
          .where(
            (e) =>
                e['strategy'] != null && (e['strategy'] as String).isNotEmpty,
          )
          .map((e) => e['strategy'] as String)
          .toSet()
          .toList();
      final tags = data
          .where((e) => e['emotion_tags'] != null)
          .expand(
            (row) => (row['emotion_tags'] as List<dynamic>).map(
              (tag) => tag.toString(),
            ),
          )
          .toSet()
          .toList();

      if (mounted) {
        setState(() {
          _strategyOptions = strategies;
          _emotionTagOptions = tags;
        });
      }
    } catch (e) {
      print('Error fetching autocomplete options: $e');
    }
  }

  Future<void> _pickImage(
    ImageSource source,
    Function(XFile) onImagePicked,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 480,
      maxHeight: 320,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        onImagePicked(pickedFile);
      });
    }
  }

  Future<String?> _uploadImage(XFile? imageFile) async {
    if (imageFile == null) return null;
    try {
      final imageBytes = await imageFile.readAsBytes();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.${imageFile.name.split('.').last}';

      await supabase.storage
          .from('trade_images')
          .uploadBinary(
            fileName,
            imageBytes,
            fileOptions: FileOptions(contentType: imageFile.mimeType),
          );
      return supabase.storage.from('trade_images').getPublicUrl(fileName);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      return null;
    }
  }

  Future<void> _saveTrade() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userId = supabase.auth.currentUser!.id;
      final emotionTags = _emotionTagsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final imageUrl = _beforeImageFile != null
          ? await _uploadImage(_beforeImageFile)
          : _existingImageUrl;

      final payload = {
        'user_id': userId,
        'symbol': _symbolController.text.trim(),
        'direction': _direction,
        'entry_price': double.parse(_entryPriceController.text),
        'exit_price': _exitPriceController.text.trim().isEmpty
            ? null
            : double.parse(_exitPriceController.text.trim()),
        'quantity': double.parse(_quantityController.text),
        'strategy': _strategyController.text.trim().isEmpty
            ? null
            : _strategyController.text.trim(),
        'notes': _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        'mindset_rating': _mindsetRating.toInt(),
        'emotion_tags': emotionTags,
        'before_image_url': imageUrl,
      };

      if (_isEditMode) {
        await supabase.from('trades').update(payload).match({
          'id': widget.initialTrade!['id'],
        });
      } else {
        await supabase.from('trades').insert(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã lưu giao dịch thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi lưu giao dịch: $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(_isEditMode ? l10n.editTrade : l10n.addTrade)),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _symbolController,
                decoration: InputDecoration(labelText: l10n.symbol),
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _direction,
                decoration: InputDecoration(labelText: l10n.direction),
                items: [l10n.long, l10n.short]
                    .map(
                      (String value) => DropdownMenuItem<String>(
                        value: value == l10n.long ? 'Long' : 'Short',
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: (String? newValue) =>
                    setState(() => _direction = newValue!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _entryPriceController,
                decoration: InputDecoration(labelText: l10n.entryPrice),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _exitPriceController,
                decoration: InputDecoration(labelText: l10n.exitPrice),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(labelText: l10n.quantity),
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 16),
              // *** FIX: Sửa lại Autocomplete để hoạt động đúng ***
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _strategyController.text),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return _strategyOptions.where((String option) {
                    return option.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    );
                  });
                },
                onSelected: (String selection) {
                  // Cập nhật controller khi người dùng chọn một mục
                  _strategyController.text = selection;
                },
                fieldViewBuilder:
                    (
                      context,
                      fieldTextEditingController,
                      focusNode,
                      onFieldSubmitted,
                    ) {
                      // Dùng một listener để cập nhật controller khi người dùng gõ
                      // Điều này đảm bảo cả giá trị gõ tay và giá trị chọn đều được lưu
                      fieldTextEditingController.addListener(() {
                        _strategyController.text =
                            fieldTextEditingController.text;
                      });
                      return TextFormField(
                        controller: fieldTextEditingController,
                        focusNode: focusNode,
                        decoration: InputDecoration(labelText: l10n.strategy),
                      );
                    },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(labelText: l10n.notes),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.psychology,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(l10n.mindsetRating),
              Slider(
                value: _mindsetRating,
                min: 1,
                max: 5,
                divisions: 4,
                label: _mindsetRating.round().toString(),
                onChanged: (v) => setState(() => _mindsetRating = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emotionTagsController,
                decoration: InputDecoration(
                  labelText: l10n.emotionTags,
                  hintText: "FOMO, Kiên nhẫn, Trả thù,...",
                ),
              ),
              Wrap(
                spacing: 8.0,
                children: _emotionTagOptions
                    .map(
                      (tag) => ActionChip(
                        label: Text(tag),
                        onPressed: () {
                          final currentTags = _emotionTagsController.text
                              .split(',')
                              .map((t) => t.trim())
                              .where((t) => t.isNotEmpty)
                              .toList();
                          if (!currentTags.contains(tag)) {
                            currentTags.add(tag);
                            _emotionTagsController.text = currentTags.join(
                              ', ',
                            );
                          }
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              Text("Hình ảnh", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              _buildImagePicker(
                "Ảnh chụp biểu đồ",
                _beforeImageFile,
                (file) => setState(() => _beforeImageFile = file),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : FilledButton(onPressed: _saveTrade, child: Text(l10n.save)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(
    String title,
    XFile? imageFile,
    Function(XFile) onImagePicked,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 8),
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade700),
            borderRadius: BorderRadius.circular(12),
          ),
          child: imageFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: FutureBuilder<Uint8List>(
                    future: imageFile.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          snapshot.data != null) {
                        return Image.memory(snapshot.data!, fit: BoxFit.cover);
                      }
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                )
              : Center(
                  child: TextButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Chọn ảnh'),
                    onPressed: () =>
                        _pickImage(ImageSource.gallery, onImagePicked),
                  ),
                ),
        ),
      ],
    );
  }
}
