import 'dart:typed_data'; // Import để dùng Uint8List

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../main.dart';

import 'package:image_picker/image_picker.dart';

class AddTradeScreen extends StatefulWidget {
  const AddTradeScreen({super.key});
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
  bool _isLoading = false;

  List<String> _strategyOptions = [];
  List<String> _emotionTagOptions = [];

  @override
  void initState() {
    super.initState();
    _fetchAutocompleteOptions();
  }

  Future<void> _fetchAutocompleteOptions() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('trades')
          .select('strategy, emotion_tags')
          .eq('user_id', userId);

      final strategies = data
          .where((e) => e['strategy'] != null)
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

  // *** FIX: Thêm giới hạn kích thước ảnh ***
  Future<void> _pickImage(
    ImageSource source,
    Function(XFile) onImagePicked,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 480, // Giới hạn chiều rộng
      maxHeight: 320, // Giới hạn chiều cao
      imageQuality: 85, // Chất lượng nén
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
      final userId = supabase.auth.currentUser!.id;
      final imageBytes = await imageFile.readAsBytes();
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.${imageFile.name.split('.').last}';
      final filePath = '$userId/$fileName';

      await supabase.storage
          .from('tradeimages')
          .uploadBinary(
            filePath,
            imageBytes,
            fileOptions: FileOptions(contentType: imageFile.mimeType),
          );
      return supabase.storage.from('tradeimages').getPublicUrl(filePath);
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
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final beforeImageUrl = await _uploadImage(_beforeImageFile);
        final userId = supabase.auth.currentUser!.id;
        final emotionTags = _emotionTagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        await supabase.from('trades').insert({
          'user_id': userId,
          'symbol': _symbolController.text,
          'direction': _direction,
          'entry_price': double.parse(_entryPriceController.text),
          'exit_price': _exitPriceController.text.isEmpty
              ? null
              : double.parse(_exitPriceController.text),
          'quantity': double.parse(_quantityController.text),
          'strategy': _strategyController.text.isEmpty
              ? null
              : _strategyController.text,
          'notes': _notesController.text.isEmpty ? null : _notesController.text,
          'mindset_rating': _mindsetRating.toInt(),
          'emotion_tags': emotionTags,
          'before_image_url': beforeImageUrl,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu giao dịch thành công!')),
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
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addTrade)),
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
                onChanged: (String? newValue) {
                  setState(() {
                    _direction = newValue!;
                  });
                },
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
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '')
                    return const Iterable<String>.empty();
                  return _strategyOptions.where(
                    (o) => o.toLowerCase().contains(
                      textEditingValue.text.toLowerCase(),
                    ),
                  );
                },
                onSelected: (String selection) =>
                    _strategyController.text = selection,
                fieldViewBuilder: (context, ctl, fn, _) {
                  _strategyController.text = ctl.text;
                  return TextFormField(
                    controller: ctl,
                    focusNode: fn,
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
                  : FilledButton(
                      onPressed: _saveTrade,
                      child: Text(l10n.saveTrade),
                    ),
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
