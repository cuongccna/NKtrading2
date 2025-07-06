import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../main.dart';
import 'trade_detail_screen.dart'; // Import màn hình chi tiết
import '../../data/models/trade_filter_model.dart'; // Import
import '../../../../../l10n/app_localizations.dart';
import 'add_trade_screen.dart'; // Import

class JournalScreen extends StatefulWidget {
  final TradeFilterModel filter;
  const JournalScreen({super.key, this.filter = const TradeFilterModel()});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final List<Map<String, dynamic>> _trades = [];
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  static const _pageSize = 20;
  String _searchTerm = '';

  @override
  void initState() {
    super.initState();
    _fetchInitialTrades();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      if (_searchTerm != _searchController.text) {
        _searchTerm = _searchController.text;
        _fetchInitialTrades();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchMoreTrades();
    }
  }

  Future<void> _fetchInitialTrades() async {
    setState(() {
      _isLoading = true;
      _trades.clear();
      _currentPage = 0;
      _hasMore = true;
    });
    await _fetchTrades();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMoreTrades() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    await _fetchTrades();
    if (mounted) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _fetchTrades() async {
    try {
      final from = _currentPage * _pageSize;
      final to = from + _pageSize - 1;
      final userId = supabase.auth.currentUser!.id;

      var query = supabase.from('trades').select().eq('user_id', userId);

      if (widget.filter.symbol != null) {
        query = query.eq('symbol', widget.filter.symbol!);
      }
      if (widget.filter.strategy != null) {
        query = query.eq('strategy', widget.filter.strategy!);
      }
      if (widget.filter.startDate != null) {
        query = query.gte(
          'created_at',
          widget.filter.startDate!.toIso8601String(),
        );
      }
      if (widget.filter.endDate != null) {
        final inclusiveEndDate = widget.filter.endDate!.add(
          const Duration(days: 1),
        );
        query = query.lt('created_at', inclusiveEndDate.toIso8601String());
      }
      if (_searchTerm.isNotEmpty) {
        query = query.ilike('symbol', '%$_searchTerm%');
      }

      final data = await query
          .order('created_at', ascending: false)
          .range(from, to);

      if (mounted) {
        setState(() {
          _trades.addAll(data);
          _currentPage++;
          if (data.length < _pageSize) {
            _hasMore = false;
          }
        });
      }
    } catch (e) {
      // ...
    }
  }

  Color _getColorForStrategy(String? strategy) {
    if (strategy == null || strategy.isEmpty) return Colors.grey;
    final index = strategy.hashCode % Colors.primaries.length;
    return Colors.primaries[index];
  }

  // *** NEW: Hàm điều hướng đến màn hình Sửa ***
  void _navigateToEditScreen(Map<String, dynamic> trade) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => AddTradeScreen(initialTrade: trade),
          ),
        )
        .then((result) {
          if (result == true) {
            _fetchInitialTrades(); // Tải lại toàn bộ danh sách khi có thay đổi
          }
        });
  }

  // *** NEW: Hàm hiển thị hộp thoại xác nhận và xóa ***
  Future<void> _deleteTrade(String tradeId, int index) async {
    final l10n = AppLocalizations.of(context)!;
    final bool? confirmed = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeletion),
        content: Text(l10n.deleteConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await supabase.from('trades').delete().match({'id': tradeId});
        if (mounted) {
          setState(() {
            _trades.removeAt(index);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa giao dịch thành công.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi xóa giao dịch: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchBySymbol,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
            ),
          ),
        ),
        Expanded(child: _buildTradeList()),
      ],
    );
  }

  Widget _buildTradeList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_trades.isEmpty) {
      return const Center(child: Text('Không tìm thấy giao dịch nào.'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 80),
      itemCount: _trades.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _trades.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final trade = _trades[index];
        final pnl = trade['exit_price'] != null
            ? ((trade['exit_price'] - (trade['entry_price'] ?? 0.0)) *
                      (trade['quantity'] ?? 0.0) *
                      (trade['direction'] == 'Long' ? 1 : -1))
                  .toDouble()
            : null;

        final createdAt = DateTime.parse(trade['created_at']);
        final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
        final strategy = trade['strategy'] as String?;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: InkWell(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TradeDetailScreen(trade: trade),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        trade['direction'] == 'Long'
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: trade['direction'] == 'Long'
                            ? Colors.green
                            : Colors.red,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              trade['symbol'] ?? 'N/A',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              'Giá vào: ${trade['entry_price']} - SL: ${trade['quantity']}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      if (pnl != null)
                        Text(
                          '${pnl > 0 ? '+' : ''}${NumberFormat.currency(locale: 'vi_VN', symbol: '').format(pnl)}',
                          style: TextStyle(
                            color: pnl > 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      if (pnl == null) const Text('Đang mở'),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (strategy != null && strategy.isNotEmpty)
                              Chip(
                                label: Text(
                                  strategy,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: _getColorForStrategy(strategy),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 0,
                                ),
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 4.0,
                                ),
                                visualDensity: VisualDensity.compact,
                              ),
                            if (strategy != null && strategy.isNotEmpty)
                              const SizedBox(width: 8),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // *** NEW: Hàng chứa các nút Sửa/Xóa ***
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _navigateToEditScreen(trade),
                            tooltip: 'Sửa',
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _deleteTrade(trade['id'], index),
                            tooltip: 'Xóa',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
