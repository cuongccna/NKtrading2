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
  late Future<List<Map<String, dynamic>>> _tradesFuture;

  @override
  void initState() {
    super.initState();
    _tradesFuture = _fetchTrades();
  }

  Future<List<Map<String, dynamic>>> _fetchTrades() async {
    final userId = supabase.auth.currentUser!.id;

    // *** FIX: Bắt đầu câu truy vấn và áp dụng các bộ lọc trước ***
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
      // Thêm 1 ngày để bao gồm cả ngày kết thúc
      final inclusiveEndDate = widget.filter.endDate!.add(
        const Duration(days: 1),
      );
      query = query.lt('created_at', inclusiveEndDate.toIso8601String());
    }

    // *** FIX: Gọi hàm order() ở cuối cùng ***
    final data = await query.order('created_at', ascending: false);

    return data;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _tradesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        final trades = snapshot.data ?? [];
        if (trades.isEmpty) {
          return const Center(child: Text('Không tìm thấy giao dịch nào.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: trades.length,
          itemBuilder: (context, index) {
            final trade = trades[index];
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
      },
    );
  }
}
