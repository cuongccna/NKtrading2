import 'package:flutter/material.dart';
import 'package:nktrading_app/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../../../main.dart';
import '../../data/models/trade_filter_model.dart';

class FilterDialog extends StatefulWidget {
  final TradeFilterModel initialFilter;
  const FilterDialog({super.key, required this.initialFilter});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  String? _selectedSymbol;
  String? _selectedStrategy;

  List<String> _symbolOptions = [];
  List<String> _strategyOptions = [];

  // *** FIX: Thêm trạng thái loading ***
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
    _selectedSymbol = widget.initialFilter.symbol;
    _selectedStrategy = widget.initialFilter.strategy;
    _fetchOptions();
  }

  Future<void> _fetchOptions() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final data = await supabase
          .from('trades')
          .select('symbol, strategy')
          .eq('user_id', userId);

      final symbols = data
          .where((e) => e['symbol'] != null)
          .map((e) => e['symbol'] as String)
          .toSet()
          .toList();
      final strategies = data
          .where((e) => e['strategy'] != null)
          .map((e) => e['strategy'] as String)
          .toSet()
          .toList();

      if (mounted) {
        setState(() {
          _symbolOptions = symbols;
          _strategyOptions = strategies;
          _isLoading = false; // Tải xong, tắt loading
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false; // Tắt loading ngay cả khi có lỗi
        });
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStartDate ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return AlertDialog(
      title: Text(l10n.filterTrades),
      // *** FIX: Hiển thị nội dung dựa trên trạng thái loading ***
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.dateRange,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => _selectDate(context, true),
                          child: Text(
                            _startDate == null
                                ? l10n.selectDate
                                : dateFormat.format(_startDate!),
                          ),
                        ),
                      ),
                      const Text("-"),
                      Expanded(
                        child: TextButton(
                          onPressed: () => _selectDate(context, false),
                          child: Text(
                            _endDate == null
                                ? l10n.selectDate
                                : dateFormat.format(_endDate!),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    l10n.symbol,
                    _selectedSymbol,
                    _symbolOptions,
                    (val) => setState(() => _selectedSymbol = val),
                  ),
                  const SizedBox(height: 16),
                  _buildDropdown(
                    l10n.strategy,
                    _selectedStrategy,
                    _strategyOptions,
                    (val) => setState(() => _selectedStrategy = val),
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(const TradeFilterModel()); // Reset
          },
          child: Text(l10n.reset),
        ),
        FilledButton(
          onPressed: () {
            final filter = TradeFilterModel(
              startDate: _startDate,
              endDate: _endDate,
              symbol: _selectedSymbol,
              strategy: _selectedStrategy,
            );
            Navigator.of(context).pop(filter);
          },
          child: Text(l10n.apply),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    String title,
    String? value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    // Đảm bảo giá trị hiện tại có trong danh sách, nếu không thì đặt là null
    final currentValue = items.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: title,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(AppLocalizations.of(context)!.all),
        ),
        ...items.map(
          (item) => DropdownMenuItem<String>(value: item, child: Text(item)),
        ),
      ],
      onChanged: onChanged,
    );
  }
}
