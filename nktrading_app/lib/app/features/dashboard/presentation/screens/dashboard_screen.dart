// Giao diện giữ chỗ cho Bảng điều khiển

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../../main.dart';
import 'package:fl_chart/fl_chart.dart'; // Import thư viện biểu đồ
import '../../../../../l10n/app_localizations.dart';
import '../../../../core/providers/currency_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<List<dynamic>>? _dataFutures;
  String _selectedTimeRange = 'all';
  String _preferredCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refetch data when locale changes
    _fetchData();
  }

  void _fetchData() async {
    final currencyProvider = Provider.of<CurrencyProvider>(
      context,
      listen: false,
    );
    final currency = currencyProvider.currency;

    try {
      final userId = supabase.auth.currentUser!.id;

      if (mounted) {
        setState(() {
          _dataFutures =
              Future.wait([
                _fetchUserStats(_selectedTimeRange, currency),
                _fetchPerformanceCharts(_selectedTimeRange, currency),
                _fetchPerformancePatterns(),
                _fetchTopTrades(currency),
              ]).catchError((error) {
                // If any single request fails, still show partial data
                return Future.wait([
                  _fetchUserStats(
                    _selectedTimeRange,
                    currency,
                  ).catchError((_) => <String, dynamic>{}),
                  _fetchPerformanceCharts(
                    _selectedTimeRange,
                    currency,
                  ).catchError((_) => <dynamic>[]),
                  _fetchPerformancePatterns().catchError(
                    (_) => <String, dynamic>{},
                  ),
                  _fetchTopTrades(
                    currency,
                  ).catchError((_) => <String, dynamic>{}),
                ]);
              });
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _dataFutures = Future.error('Error loading data: $e');
        });
      }
    }
  }

  Future<Map<String, dynamic>> _fetchUserStats(
    String timeRange,
    String targetCurrency,
  ) async {
    final result = await supabase.functions.invoke(
      'get-user-stats',
      body: {'timeRange': timeRange, 'targetCurrency': targetCurrency},
    );
    if (result.data == null) throw 'Error loading statistics';
    return result.data;
  }

  Future<List<dynamic>> _fetchPerformanceCharts(
    String timeRange,
    String targetCurrency,
  ) async {
    final result = await supabase.functions.invoke(
      'get-performance-charts',
      body: {'timeRange': timeRange, 'targetCurrency': targetCurrency},
    );
    if (result.data == null) throw 'Error loading charts';
    return result.data;
  }

  Future<Map<String, dynamic>> _fetchPerformancePatterns() async {
    final result = await supabase.functions.invoke('get-performance-patterns');
    if (result.data == null) throw 'Error loading patterns';
    return result.data;
  }

  Future<Map<String, dynamic>> _fetchTopTrades(String targetCurrency) async {
    final result = await supabase.functions.invoke(
      'get-top-trades',
      body: {'targetCurrency': targetCurrency},
    );
    if (result.data == null) throw 'Error loading top trades';
    return result.data;
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, size: 28, color: valueColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: valueColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showTopTradesDialog(Map<String, dynamic> topTradesData) {
    final l10n = AppLocalizations.of(context)!;
    final currencyProvider = Provider.of<CurrencyProvider>(
      context,
      listen: false,
    );
    final topWinners = (topTradesData['topWinners'] as List<dynamic>?) ?? [];
    final topLosers = (topTradesData['topLosers'] as List<dynamic>?) ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.pnl),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.top10WinningTrades,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (topWinners.isEmpty)
                  ListTile(title: Text(l10n.noValue))
                else
                  ...topWinners.map(
                    (trade) => ListTile(
                      title: Text(trade['symbol']),
                      trailing: Text(
                        '+${currencyProvider.formatCurrency(trade['pnl'])}',
                        style: const TextStyle(color: Colors.greenAccent),
                      ),
                    ),
                  ),
                const Divider(height: 32),
                Text(
                  l10n.top10LosingTrades,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (topLosers.isEmpty)
                  ListTile(title: Text(l10n.noValue))
                else
                  ...topLosers.map(
                    (trade) => ListTile(
                      title: Text(trade['symbol']),
                      trailing: Text(
                        currencyProvider.formatCurrency(trade['pnl']),
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );
  }

  Widget _buildEquityCurveChart(
    List<dynamic> equityData,
    AppLocalizations l10n,
  ) {
    final List<FlSpot> spots = equityData.asMap().entries.map((entry) {
      final index = entry.key;
      final dataPoint = entry.value;
      return FlSpot(index.toDouble(), (dataPoint['pnl'] as num).toDouble());
    }).toList();

    if (spots.isNotEmpty) {
      spots.insert(0, const FlSpot(-1, 0));
    }

    Widget leftTitleWidgets(double value, TitleMeta meta) {
      final style = TextStyle(
        color: Colors.grey.shade400,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      );
      String text;
      if (value.abs() >= 1000000) {
        text = '${(value / 1000000).toStringAsFixed(1)}M';
      } else if (value.abs() >= 1000) {
        text = '${(value / 1000).toStringAsFixed(1)}K';
      } else {
        text = value.toStringAsFixed(0);
      }
      return Text(text, style: style, textAlign: TextAlign.center);
    }

    Widget bottomTitleWidgets(double value, TitleMeta meta) {
      final style = TextStyle(
        color: Colors.grey.shade400,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      );
      Widget text;
      final index = value.toInt();
      if (index < 0 || index >= equityData.length) {
        text = Text('', style: style);
      } else {
        final dateString = equityData[index]['date'];
        final date = DateTime.parse(dateString);
        text = Text(DateFormat('dd/MM').format(date), style: style);
      }
      return Padding(padding: const EdgeInsets.only(top: 8.0), child: text);
    }

    return Card(
      child: Container(
        height: 250,
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.growthChart,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LineChart(
                LineChartData(
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: (spots.length / 5).ceilToDouble().toDouble(),
                        getTitlesWidget: bottomTitleWidgets,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: leftTitleWidgets,
                        reservedSize: 42,
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.cyan,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            Colors.cyan.withOpacity(0.4),
                            Colors.cyan.withOpacity(0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyPerformanceList(
    List<dynamic> performanceData,
    AppLocalizations l10n,
  ) {
    final currencyProvider = Provider.of<CurrencyProvider>(
      context,
      listen: false,
    );

    double maxPnl = 0;
    for (var item in performanceData) {
      final pnl = (item['pnl'] as num).abs();
      if (pnl > maxPnl) {
        maxPnl = pnl.toDouble();
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.performanceByStrategy,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: performanceData.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 24, color: Colors.white12),
              itemBuilder: (context, index) {
                final data = performanceData[index];
                final strategy = data['strategy'] as String;
                final pnl = (data['pnl'] as num).toDouble();
                final winrate = (data['winrate'] as num);
                final tradeCount = data['tradeCount'] as int;
                final isProfit = pnl >= 0;
                final barRatio = maxPnl > 0 ? (pnl.abs() / maxPnl) : 0.0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strategy,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${winrate.toStringAsFixed(1)}% WR ($tradeCount ${l10n.trades})',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: barRatio,
                            backgroundColor: Colors.grey.shade800,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isProfit ? Colors.greenAccent : Colors.redAccent,
                            ),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          currencyProvider.formatCurrency(pnl),
                          style: TextStyle(
                            color: isProfit
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayOfWeekPerformanceChart(
    List<dynamic> performanceData,
    AppLocalizations l10n,
  ) {
    final currencyProvider = Provider.of<CurrencyProvider>(
      context,
      listen: false,
    );

    // Get localized day names
    final days = _getLocalizedDayNames(l10n);

    final barGroups = performanceData.map((data) {
      final day = (data['day'] as num).toInt();
      final pnl = (data['pnl'] as num).toDouble();
      return BarChartGroupData(
        x: day,
        barRods: [
          BarChartRodData(
            toY: pnl,
            color: pnl >= 0
                ? Colors.greenAccent.withOpacity(0.7)
                : Colors.redAccent.withOpacity(0.7),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();

    return Card(
      child: Container(
        height: 250,
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.performanceByDay,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Colors.blueGrey,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
                        return BarTooltipItem(
                          '${days[group.x.toInt()]}\n',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: currencyProvider.formatCurrency(rod.toY),
                              style: TextStyle(
                                color: rod.toY >= 0
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final text = Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: text,
                          );
                        },
                        reservedSize: 32,
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getLocalizedDayNames(AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).languageCode;
    if (locale == 'vi') {
      return ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    } else {
      return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    }
  }

  String _getLocalizedTimeRangeName(String key, AppLocalizations l10n) {
    switch (key) {
      case 'daily':
        return l10n.daily;
      case 'weekly':
        return l10n.weekly;
      case 'monthly':
        return l10n.monthly;
      case 'yearly':
        return l10n.yearly;
      case 'all':
        return l10n.all;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<List<dynamic>>(
      future: _dataFutures,
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        Widget buildTimeFilter() {
          final Map<String, String> timeRanges = {
            'daily': _getLocalizedTimeRangeName('daily', l10n),
            'weekly': _getLocalizedTimeRangeName('weekly', l10n),
            'monthly': _getLocalizedTimeRangeName('monthly', l10n),
            'yearly': _getLocalizedTimeRangeName('yearly', l10n),
            'all': l10n.all,
          };

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: timeRanges.entries.map((entry) {
                final key = entry.key;
                final value = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(value),
                    selected: _selectedTimeRange == key,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTimeRange = key;
                          _fetchData();
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.errorLoading),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text(l10n.noData));
        }

        final stats = snapshot.data![0] as Map<String, dynamic>;
        final performanceData = snapshot.data![1] as List<dynamic>;
        final patternsData = snapshot.data![2] as Map<String, dynamic>;
        final topTradesData = snapshot.data![3] as Map<String, dynamic>;

        final byDayOfWeekData =
            patternsData['byDayOfWeek'] as List<dynamic>? ?? [];
        final totalPnl = (stats['totalPnl'] ?? 0.0).toDouble();
        final winrate = (stats['winrate'] ?? 0.0).toDouble();
        final averageWin = (stats['averageWin'] ?? 0.0).toDouble();
        final averageLoss = (stats['averageLoss'] ?? 0.0).toDouble();
        final totalTrades = stats['totalTrades'] ?? 0;
        final equityCurveData = stats['equityCurve'] as List<dynamic>? ?? [];

        return RefreshIndicator(
          onRefresh: () async => _fetchData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                buildTimeFilter(),
                const SizedBox(height: 24),

                if (totalTrades == 0)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48.0),
                      child: Text(l10n.noDataInTimeRange),
                    ),
                  )
                else ...[
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.8,
                    children: [
                      InkWell(
                        onTap: () => _showTopTradesDialog(topTradesData),
                        child: _buildStatCard(
                          context,
                          title: l10n.pnl,
                          value: currencyProvider.formatCurrency(totalPnl),
                          icon: Icons.show_chart,
                          valueColor: totalPnl >= 0
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                      _buildStatCard(
                        context,
                        title: l10n.winrate,
                        value: '${winrate.toStringAsFixed(1)}%',
                        icon: Icons.pie_chart,
                      ),
                      _buildStatCard(
                        context,
                        title: l10n.averageProfit,
                        value: currencyProvider.formatCurrency(averageWin),
                        icon: Icons.trending_up,
                        valueColor: Colors.greenAccent,
                      ),
                      _buildStatCard(
                        context,
                        title: l10n.averageLoss,
                        value: currencyProvider.formatCurrency(averageLoss),
                        icon: Icons.trending_down,
                        valueColor: Colors.redAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (equityCurveData.isNotEmpty)
                    _buildEquityCurveChart(equityCurveData, l10n),

                  const SizedBox(height: 16),

                  if (performanceData.isNotEmpty)
                    _buildStrategyPerformanceList(performanceData, l10n),

                  const SizedBox(height: 16),

                  if (byDayOfWeekData.isNotEmpty)
                    _buildDayOfWeekPerformanceChart(byDayOfWeekData, l10n),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
