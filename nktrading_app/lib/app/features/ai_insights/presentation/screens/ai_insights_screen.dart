import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import '../../../../../main.dart';

class AiInsightsScreen extends StatefulWidget {
  const AiInsightsScreen({super.key});

  @override
  State<AiInsightsScreen> createState() => _AiInsightsScreenState();
}

class _AiInsightsScreenState extends State<AiInsightsScreen> {
  Future<Map<String, dynamic>>? _insightsFuture;

  @override
  void initState() {
    super.initState();
    _insightsFuture = _fetchInsights();
  }

  Future<Map<String, dynamic>> _fetchInsights() async {
    try {
      final results = await Future.wait([
        supabase.functions.invoke('get-winning-patterns'),
        supabase.functions.invoke('get-psychological-impact'),
      ]);

      final patternsData = results[0].data as Map<String, dynamic>? ?? {};
      final psychologyData = results[1].data as Map<String, dynamic>? ?? {};

      return {...patternsData, ...psychologyData};
    } catch (e) {
      throw 'Không thể tải dữ liệu phân tích: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, dynamic>>(
      future: _insightsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Không có đủ dữ liệu để phân tích.'));
        }

        final insights = snapshot.data!;
        final bestStrategy = insights['bestStrategy'];
        final bestDay = insights['bestDay'];
        final bestSession = insights['bestSession'];
        final byMindset = (insights['byMindset'] as List<dynamic>?) ?? [];
        final byEmotionTag = (insights['byEmotionTag'] as List<dynamic>?) ?? [];

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _insightsFuture = _fetchInsights();
            });
          },
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              if (bestStrategy != null)
                _buildInsightCard(
                  context,
                  icon: Icons.star_outline,
                  title: l10n.bestPerformingStrategy,
                  content: bestStrategy['key'],
                  pnl: (bestStrategy['pnl'] as num).toDouble(),
                  winrate: (bestStrategy['winrate'] as num).toDouble(),
                  tradeCount: bestStrategy['tradeCount'] as int,
                ),
              if (bestDay != null)
                _buildInsightCard(
                  context,
                  icon: Icons.calendar_today_outlined,
                  title: l10n.bestPerformingDay,
                  content: bestDay['key'],
                  pnl: (bestDay['pnl'] as num).toDouble(),
                  winrate: (bestDay['winrate'] as num).toDouble(),
                  tradeCount: bestDay['tradeCount'] as int,
                ),
              if (bestSession != null)
                _buildInsightCard(
                  context,
                  icon: Icons.access_time_outlined,
                  title: l10n.bestPerformingSession,
                  content: bestSession['key'],
                  pnl: (bestSession['pnl'] as num).toDouble(),
                  winrate: (bestSession['winrate'] as num).toDouble(),
                  tradeCount: bestSession['tradeCount'] as int,
                ),
              const SizedBox(height: 16),
              if (byMindset.isNotEmpty || byEmotionTag.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    l10n.psychologicalAnalysis,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (byMindset.isNotEmpty)
                _buildPsychologyTable(
                  context,
                  title: l10n.performanceByMindset,
                  data: byMindset,
                  header1: l10n.rating,
                ),
              const SizedBox(height: 24),
              if (byEmotionTag.isNotEmpty)
                _buildPsychologyTable(
                  context,
                  title: l10n.performanceByEmotion,
                  data: byEmotionTag,
                  header1: l10n.tag,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInsightCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required double pnl,
    required double winrate,
    required int tradeCount,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
    );
    final isProfit = pnl >= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.amber.shade300, size: 28),
                const SizedBox(width: 12),
                Text(title, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 12),
            // *** FIX: Thêm điểm nhấn màu sắc cho nội dung chính ***
            Text(
              content,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade200,
                shadows: [
                  Shadow(
                    blurRadius: 10.0,
                    color: Colors.amber.withOpacity(0.3),
                    offset: const Offset(2.0, 2.0),
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  l10n.pnl,
                  currencyFormatter.format(pnl),
                  isProfit ? Colors.greenAccent : Colors.redAccent,
                ),
                _buildStatColumn(
                  l10n.winrate,
                  '${winrate.toStringAsFixed(1)}%',
                ),
                _buildStatColumn(l10n.tradeCount, tradeCount.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, [Color? valueColor]) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPsychologyTable(
    BuildContext context, {
    required String title,
    required List<dynamic> data,
    required String header1,
  }) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            // *** FIX: Dùng ListView thay vì DataTable để linh hoạt hơn ***
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Colors.white12),
              itemBuilder: (context, index) {
                final item = data[index];
                final pnl = (item['averagePnl'] as num).toDouble();
                final isProfit = pnl >= 0;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                  title: Text(
                    item['key'].toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currencyFormatter.format(pnl),
                        style: TextStyle(
                          color: isProfit
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Text('${item['tradeCount']} lệnh'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
