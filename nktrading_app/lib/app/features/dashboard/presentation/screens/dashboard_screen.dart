// Giao diện giữ chỗ cho Bảng điều khiển

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../main.dart';
import 'package:fl_chart/fl_chart.dart'; // Import thư viện biểu đồ

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<Map<String, dynamic>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchUserStats();
  }

  Future<Map<String, dynamic>> _fetchUserStats() async {
    try {
      final result = await supabase.functions.invoke('get-user-stats');
      if (result.data == null) {
        throw 'Không nhận được dữ liệu từ server.';
      }
      return result.data as Map<String, dynamic>;
    } catch (e) {
      throw 'Không thể tải dữ liệu thống kê: $e';
    }
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

  // Widget để xây dựng biểu đồ Equity Curve
  Widget _buildEquityCurveChart(List<dynamic> equityData) {
    final List<FlSpot> spots = equityData.asMap().entries.map((entry) {
      final index = entry.key;
      final dataPoint = entry.value;
      return FlSpot(index.toDouble(), (dataPoint['pnl'] as num).toDouble());
    }).toList();

    // Thêm điểm bắt đầu (0, 0) vào biểu đồ
    spots.insert(0, const FlSpot(-1, 0));

    // Hàm để định dạng giá trị tiền tệ trên trục Y
    Widget leftTitleWidgets(double value, TitleMeta meta) {
      final style = TextStyle(
        color: Colors.grey.shade400,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      );
      String text;
      if (value >= 1000000) {
        text = '${(value / 1000000).toStringAsFixed(1)}M';
      } else if (value >= 1000) {
        text = '${(value / 1000).toStringAsFixed(1)}K';
      } else {
        text = value.toStringAsFixed(0);
      }
      return Text(text, style: style, textAlign: TextAlign.center);
    }

    // Hàm để định dạng ngày tháng trên trục X
    Widget bottomTitleWidgets(double value, TitleMeta meta) {
      final style = TextStyle(
        color: Colors.grey.shade400,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      );
      Widget text;
      // Trừ 1 vì chúng ta đã thêm điểm bắt đầu ở index -1
      final index = value.toInt();
      if (index < 0 || index >= equityData.length) {
        text = Text('', style: style);
      } else {
        final dateString = equityData[index]['date'];
        final date = DateTime.parse(dateString);
        text = Text(DateFormat('dd/MM').format(date), style: style);
      }
      return SideTitleWidget(axisSide: meta.axisSide, space: 8.0, child: text);
    }

    return Card(
      child: Container(
        height: 250,
        padding: const EdgeInsets.fromLTRB(16, 24, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Biểu đồ tăng trưởng",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: LineChart(
                LineChartData(
                  // *** FIX: Thêm TitlesData để hiển thị chỉ dẫn trục ***
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
                        interval: (spots.length / 4)
                            .ceilToDouble(), // Hiển thị khoảng 4-5 nhãn
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
                  // *** FIX: Thêm GridData để có đường kẻ ngang ***
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
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

  Widget _buildChartPlaceholder(BuildContext context, {required String title}) {
    return Card(
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Expanded(
              child: Center(
                child: Icon(Icons.bar_chart, size: 60, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Lỗi tải dữ liệu: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Không có dữ liệu thống kê.'));
        }

        final stats = snapshot.data!;
        final totalPnl = (stats['totalPnl'] ?? 0.0).toDouble();
        final winrate = (stats['winrate'] ?? 0.0).toDouble();
        final averageWin = (stats['averageWin'] ?? 0.0).toDouble();
        final averageLoss = (stats['averageLoss'] ?? 0.0).toDouble();
        final totalTrades = stats['totalTrades'] ?? 0;
        final equityCurveData = stats['equityCurve'] as List<dynamic>? ?? [];

        final currencyFormatter = NumberFormat.currency(
          locale: 'vi_VN',
          symbol: '',
        );

        if (totalTrades == 0) {
          return const Center(
            child: Text('Bạn chưa có giao dịch nào được đóng.'),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _statsFuture = _fetchUserStats();
            });
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.8,
                  children: [
                    _buildStatCard(
                      context,
                      title: 'Tổng Lãi/Lỗ',
                      value: currencyFormatter.format(totalPnl),
                      icon: Icons.show_chart,
                      valueColor: totalPnl >= 0
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Tỷ lệ thắng',
                      value: '${winrate.toStringAsFixed(1)}%',
                      icon: Icons.pie_chart,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Lợi nhuận TB',
                      value: currencyFormatter.format(averageWin),
                      icon: Icons.trending_up,
                      valueColor: Colors.greenAccent,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Thua lỗ TB',
                      value: currencyFormatter.format(averageLoss),
                      icon: Icons.trending_down,
                      valueColor: Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Thay thế placeholder bằng biểu đồ thật
                if (equityCurveData.isNotEmpty)
                  _buildEquityCurveChart(equityCurveData)
                else
                  _buildChartPlaceholder(context, title: 'Biểu đồ tăng trưởng'),

                const SizedBox(height: 16),
                _buildChartPlaceholder(
                  context,
                  title: 'Hiệu suất theo chiến lược',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
