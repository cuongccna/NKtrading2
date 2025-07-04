import 'package:flutter/material.dart';
import '../../../../../main.dart';
import 'trade_detail_screen.dart'; // Import màn hình chi tiết

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});
  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  late Stream<List<Map<String, dynamic>>> _tradesStream;

  @override
  void initState() {
    super.initState();
    _tradesStream = supabase
        .from('trades')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    // File này chỉ trả về nội dung bên trong, không có Scaffold
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _tradesStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        final trades = snapshot.data ?? [];
        if (trades.isEmpty) {
          return const Center(
            child: Text('Chưa có giao dịch nào. Hãy thêm một giao dịch mới!'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(
            bottom: 80,
          ), // Thêm padding để FAB không che mất item cuối
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
