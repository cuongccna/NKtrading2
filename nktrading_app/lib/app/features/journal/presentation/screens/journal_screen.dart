import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../main.dart';
import 'trade_detail_screen.dart'; // Import màn hình chi tiết
import '../../data/models/trade_filter_model.dart'; // Import
import '../../../../../l10n/app_localizations.dart';

class JournalScreen extends StatefulWidget {
  final TradeFilterModel filter;
  const JournalScreen({super.key, this.filter = const TradeFilterModel()});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final List<Map<String, dynamic>> _trades = [];
  final _scrollController = ScrollController();
  // *** NEW: Controller cho thanh tìm kiếm ***
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
    // Lắng nghe thay đổi trong ô tìm kiếm
    _searchController.addListener(() {
      if (_searchTerm != _searchController.text) {
        _searchTerm = _searchController.text;
        _fetchInitialTrades(); // Tải lại dữ liệu từ đầu với từ khóa mới
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

      // Áp dụng bộ lọc
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
      // *** NEW: Áp dụng tìm kiếm nhanh ***
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải dữ liệu: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _hasMore = false;
        });
      }
    }
  }

  // *** NEW: Hàm tạo màu sắc ngẫu nhiên nhưng nhất quán cho chiến lược ***
  Color _getColorForStrategy(String? strategy) {
    if (strategy == null || strategy.isEmpty) {
      return Colors.grey;
    }
    // Dùng hashCode để tạo ra một chỉ số màu nhất quán
    final index = strategy.hashCode % Colors.primaries.length;
    return Colors.primaries[index];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        // *** NEW: Thanh tìm kiếm ***
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
        final isLong = trade['direction'] == 'Long';
        final entryPrice = (trade['entry_price'] ?? 0.0).toDouble();
        final pnl = trade['exit_price'] != null
            ? ((trade['exit_price'] - entryPrice) *
                      (trade['quantity'] ?? 0.0) *
                      (isLong ? 1 : -1))
                  .toDouble()
            : null;

        // *** NEW: Định dạng ngày giờ và lấy thông tin chiến lược ***
        final createdAt = DateTime.parse(trade['created_at']);
        final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
        final strategy = trade['strategy'] as String?;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(
              isLong ? Icons.arrow_upward : Icons.arrow_downward,
              color: isLong ? Colors.green : Colors.red,
            ),
            title: Text(
              trade['symbol'] ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // *** NEW: Cập nhật subtitle để hiển thị nhiều thông tin hơn ***
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Giá vào: $entryPrice - SL: ${trade['quantity']}'),
                const SizedBox(height: 4),
                Row(
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
              ],
            ),
            trailing: pnl != null
                ? Text(
                    '${pnl > 0 ? '+' : ''}${pnl.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: pnl > 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const Text('Đang mở'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TradeDetailScreen(trade: trade),
              ),
            ),
          ),
        );
      },
    );
  }
}
