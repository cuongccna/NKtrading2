import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import 'image_viewer_screen.dart'; // Import màn hình xem ảnh mới
import 'package:intl/intl.dart';
import '../../../../../main.dart';
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart

class TradeDetailScreen extends StatefulWidget {
  final Map<String, dynamic> trade;
  const TradeDetailScreen({super.key, required this.trade});

  @override
  State<TradeDetailScreen> createState() => _TradeDetailScreenState();
}

class _TradeDetailScreenState extends State<TradeDetailScreen> {
  Future<Map<String, dynamic>?>? _marketContextFuture;

  @override
  void initState() {
    super.initState();
    _marketContextFuture = _fetchMarketContext();
  }

  Future<Map<String, dynamic>?> _fetchMarketContext() async {
    try {
      final result = await supabase.functions.invoke(
        'get-market-correlation',
        body: {'trade_id': widget.trade['id']},
      );
      return result.data as Map<String, dynamic>?;
    } catch (e) {
      print('Error fetching market context: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final beforeImageUrl = widget.trade['before_image_url'];

    return Scaffold(
      appBar: AppBar(title: Text('${l10n.details}: ${widget.trade['symbol']}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              context,
              l10n.symbolLabel,
              widget.trade['symbol'] ?? 'N/A',
            ),
            _buildDetailRow(
              context,
              l10n.directionLabel,
              widget.trade['direction'] ?? 'N/A',
            ),
            _buildDetailRow(
              context,
              l10n.entryPriceLabel,
              widget.trade['entry_price']?.toString() ?? 'N/A',
            ),
            _buildDetailRow(
              context,
              l10n.exitPriceLabel,
              widget.trade['exit_price']?.toString() ?? l10n.notClosed,
            ),
            _buildDetailRow(
              context,
              l10n.quantityLabel,
              widget.trade['quantity']?.toString() ?? 'N/A',
            ),
            const Divider(height: 32),
            _buildDetailRow(
              context,
              l10n.strategyLabel,
              widget.trade['strategy'] ?? '',
            ),
            _buildDetailRow(
              context,
              l10n.notesLabel,
              widget.trade['notes'] ?? '',
            ),
            const Divider(height: 32),
            _buildDetailRow(
              context,
              l10n.mindsetRatingLabel,
              widget.trade['mindset_rating']?.toString() ?? 'N/A',
            ),
            _buildDetailRow(
              context,
              l10n.emotionTagsLabel,
              (widget.trade['emotion_tags'] as List<dynamic>?)?.join(', ') ??
                  '',
            ),

            const Divider(height: 32),
            Text(
              l10n.marketContext,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildMarketContextSection(),

            if (beforeImageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
                child: Text(
                  l10n.chart,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),

            if (beforeImageUrl != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${l10n.chartScreenshot}:",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.network(
                      beforeImageUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                          ? child
                          : const Center(child: CircularProgressIndicator()),
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        color: Colors.grey.shade800,
                        child: const Center(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.fullscreen),
                      label: Text(l10n.viewImage),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ImageViewerScreen(imageUrl: beforeImageUrl),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade400),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? l10n.noValue : value,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildMarketContextSection() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _marketContextFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data?['marketContext'] == null) {
          return Text(AppLocalizations.of(context)!.noMarketData);
        }

        final marketContext = snapshot.data!['marketContext'];
        final santimentData = marketContext['santiment'];
        final duneData = (marketContext['dune'] as List<dynamic>?)?.reversed
            .toList();

        return Column(
          children: [
            if (santimentData != null) _buildSantimentChecklist(santimentData),
            if (duneData != null && duneData.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildWhaleFlowChart(duneData),
            ],
          ],
        );
      },
    );
  }

  Widget _buildSantimentChecklist(Map<String, dynamic> contextData) {
    final l10n = AppLocalizations.of(context)!;
    final numberFormatter = NumberFormat.compact(locale: 'en_US');
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildChecklistItem(
              l10n.socialVolume,
              numberFormatter.format(contextData['social_volume'] ?? 0),
              (contextData['sentiment_balance'] ?? 0) > 0
                  ? l10n.positive
                  : l10n.negative,
              (contextData['sentiment_balance'] ?? 0) > 0
                  ? Colors.greenAccent
                  : Colors.redAccent,
            ),
            const Divider(color: Colors.white10),
            _buildChecklistItem(
              l10n.exchangeFlow,
              'In: ${numberFormatter.format(contextData['exchange_inflow'] ?? 0)} / Out: ${numberFormatter.format(contextData['exchange_outflow'] ?? 0)}',
              (contextData['exchange_outflow'] ?? 0) >
                      (contextData['exchange_inflow'] ?? 0)
                  ? l10n.outflow
                  : l10n.inflow,
              (contextData['exchange_outflow'] ?? 0) >
                      (contextData['exchange_inflow'] ?? 0)
                  ? Colors.greenAccent
                  : Colors.redAccent,
            ),
            const Divider(color: Colors.white10),
            _buildChecklistItem(
              l10n.topHolders,
              '${(contextData['top_holders_percent_of_total_supply'] ?? 0.0).toStringAsFixed(2)}%',
              (contextData['top_holders_percent_of_total_supply'] ?? 0) > 50
                  ? 'Tập trung'
                  : 'Phân tán',
              null,
            ),
            const Divider(color: Colors.white10),
            _buildChecklistItem(
              l10n.activeAddresses,
              numberFormatter.format(contextData['active_addresses_24h'] ?? 0),
              (contextData['active_addresses_24h'] ?? 0) > 100000
                  ? 'Sôi động'
                  : 'Bình thường',
              (contextData['active_addresses_24h'] ?? 0) > 100000
                  ? Colors.cyanAccent
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistItem(
    String title,
    String value,
    String tag,
    Color? tagColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (tag.isNotEmpty)
            Chip(
              label: Text(
                tag,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              backgroundColor: tagColor ?? Colors.grey.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildWhaleFlowChart(List<dynamic> duneData) {
    final l10n = AppLocalizations.of(context)!;
    final currencyFormatter = NumberFormat.compact(locale: 'en_US');

    final barGroups = duneData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final toExchange = (data['whale_to_exchange'] as num?)?.toDouble() ?? 0.0;
      final fromExchange =
          (data['exchange_to_whale'] as num?)?.toDouble() ?? 0.0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: toExchange,
            color: Colors.redAccent,
            width: 15,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: fromExchange,
            color: Colors.greenAccent,
            width: 15,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Card(
      child: Container(
        height: 300,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.whaleNetflow,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              "Trong 7 ngày qua",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: barGroups,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final title = rodIndex == 0
                            ? l10n.whaleToExchange
                            : l10n.exchangeToWhale;
                        return BarTooltipItem(
                          '$title\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: currencyFormatter.format(rod.toY),
                              style: TextStyle(
                                color: rod.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value % 5000000 != 0 && value != 0)
                            return const SizedBox.shrink();
                          return Text(
                            '${(value / 1000000).toStringAsFixed(0)}M',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 10,
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < duneData.length) {
                            final date = DateTime.parse(
                              duneData[index]['date'],
                            );
                            return Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                DateFormat('dd/MM').format(date),
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 32,
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 5000000,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
