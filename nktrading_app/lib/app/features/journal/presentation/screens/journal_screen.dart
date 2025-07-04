import 'package:flutter/material.dart';
import '../../../../../main.dart';
import 'trade_detail_screen.dart'; // Import màn hình chi tiết
import '../../data/models/trade_filter_model.dart'; // Import

class JournalScreen extends StatefulWidget {
  final TradeFilterModel filter;
  const JournalScreen({super.key, this.filter = const TradeFilterModel()});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final List<Map<String, dynamic>> _trades = [];
  final _scrollController = ScrollController();

  bool _isLoading = true; // Loading cho lần tải đầu tiên
  bool _isLoadingMore = false; // Loading cho các lần tải thêm
  bool _hasMore = true; // Cờ để kiểm tra xem còn dữ liệu để tải không
  int _currentPage = 0;
  static const _pageSize = 20; // Số lượng item tải mỗi lần

  @override
  void initState() {
    super.initState();
    _fetchInitialTrades();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Hàm lắng nghe sự kiện cuộn
  void _onScroll() {
    // Nếu người dùng cuộn đến gần cuối danh sách, và không đang tải, và vẫn còn dữ liệu
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _fetchMoreTrades();
    }
  }

  // Hàm tải dữ liệu lần đầu hoặc khi áp dụng bộ lọc mới
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

  // Hàm tải thêm dữ liệu cho các trang tiếp theo
  Future<void> _fetchMoreTrades() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });
    await _fetchTrades();
    if (mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  // Hàm lấy dữ liệu chính, sử dụng .range() để phân trang
  Future<void> _fetchTrades() async {
    try {
      final from = _currentPage * _pageSize;
      final to = from + _pageSize - 1;
      final userId = supabase.auth.currentUser!.id;

      var query = supabase.from('trades').select().eq('user_id', userId);

      // Áp dụng các bộ lọc
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_trades.isEmpty) {
      return const Center(child: Text('Không tìm thấy giao dịch nào.'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80),
      // Thêm 1 item ở cuối để hiển thị vòng xoay "tải thêm"
      itemCount: _trades.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Nếu là item cuối cùng và còn dữ liệu để tải
        if (index == _trades.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final trade = _trades[index];
        final isLong = trade['direction'] == 'Long';
        final entryPrice = (trade['entry_price'] ?? 0.0).toDouble();
        final exitPrice = trade['exit_price'] != null
            ? (trade['exit_price']).toDouble()
            : null;
        final quantity = (trade['quantity'] ?? 0.0).toDouble();
        final pnl = exitPrice != null
            ? (exitPrice - entryPrice) * quantity * (isLong ? 1 : -1)
            : null;

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
            subtitle: Text('Giá vào: $entryPrice - SL: $quantity'),
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
