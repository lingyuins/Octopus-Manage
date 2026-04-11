import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:octopusmanage/l10n/app_localizations.dart';
import 'package:octopusmanage/models/stats.dart';
import 'package:octopusmanage/widgets/stats_card.dart';
import 'package:provider/provider.dart';
import 'package:octopusmanage/providers/app_provider.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  StatsMetrics? _today;
  StatsMetrics? _total;
  List<StatsDaily> _daily = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final api = context.read<AppProvider>().api;
      final results = await Future.wait([
        api.getStatsToday(),
        api.getStatsTotal(),
        api.getStatsDaily(),
      ]);
      if (mounted) {
        setState(() {
          _today = results[0] as StatsMetrics;
          _total = results[1] as StatsMetrics;
          _daily = results[2] as List<StatsDaily>;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = context.watch<AppProvider>().loc;
    return RefreshIndicator(
      onRefresh: _loadStats,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text(loc.t('dashboard')),
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => context.read<AppProvider>().logout(),
              ),
            ],
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  loc.t('today'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildStatsGrid(_today ?? StatsMetrics(), loc),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  loc.t('total'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildStatsGrid(_total ?? StatsMetrics(), loc),
            ),
            if (_daily.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    loc.t('daily_requests'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildDailyChart(loc)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                  child: Text(
                    loc.t('daily_cost'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _buildDailyCostChart(loc)),
            ],
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(StatsMetrics stats, AppLocalizations loc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.6,
        children: [
          StatsCard(
            title: loc.t('requests'),
            value: '${stats.requestSuccess}',
            subtitle: '${loc.t("failed")}: ${stats.requestFailed}',
            icon: Icons.send,
            color: Colors.blue,
          ),
          StatsCard(
            title: loc.t('cost'),
            value: '\$${stats.totalCost.toStringAsFixed(4)}',
            subtitle: 'In: \$${stats.inputCost.toStringAsFixed(4)}',
            icon: Icons.attach_money,
            color: Colors.green,
          ),
          StatsCard(
            title: loc.t('tokens'),
            value: _formatNum(stats.totalTokens),
            subtitle: 'In: ${_formatNum(stats.inputToken)}',
            icon: Icons.data_usage,
            color: Colors.orange,
          ),
          StatsCard(
            title: loc.t('success_rate'),
            value: '${(stats.successRate * 100).toStringAsFixed(1)}%',
            subtitle: '${loc.t("avg_wait")}: ${stats.waitTime}ms',
            icon: Icons.trending_up,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChart(AppLocalizations loc) {
    final data = _daily.reversed.toList();
    if (data.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _formatNum(v.toInt()),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= data.length) return const SizedBox();
                    final d = data[i].date;
                    return Text(
                      d.length >= 5 ? d.substring(5) : d,
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                  interval: data.length > 7
                      ? (data.length / 7).ceilToDouble()
                      : 1,
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: data
                    .asMap()
                    .entries
                    .map(
                      (e) => FlSpot(
                        e.key.toDouble(),
                        e.value.metrics.requestSuccess.toDouble(),
                      ),
                    )
                    .toList(),
                isCurved: true,
                color: Colors.blue,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.withValues(alpha: 0.1),
                ),
              ),
              LineChartBarData(
                spots: data
                    .asMap()
                    .entries
                    .map(
                      (e) => FlSpot(
                        e.key.toDouble(),
                        e.value.metrics.requestFailed.toDouble(),
                      ),
                    )
                    .toList(),
                isCurved: true,
                color: Colors.red,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.red.withValues(alpha: 0.1),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots
                    .map(
                      (s) => LineTooltipItem(
                        '${s.barIndex == 0 ? loc.t("success") : loc.t("failed")}: ${s.y.toInt()}',
                        TextStyle(
                          color: s.barIndex == 0 ? Colors.blue : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyCostChart(AppLocalizations loc) {
    final data = _daily.reversed.toList();
    if (data.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: true, drawVerticalLine: false),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (v, _) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      '\$${v.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) {
                    final i = v.toInt();
                    if (i < 0 || i >= data.length) return const SizedBox();
                    final d = data[i].date;
                    return Text(
                      d.length >= 5 ? d.substring(5) : d,
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                  interval: data.length > 7
                      ? (data.length / 7).ceilToDouble()
                      : 1,
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: data
                    .asMap()
                    .entries
                    .map(
                      (e) =>
                          FlSpot(e.key.toDouble(), e.value.metrics.totalCost),
                    )
                    .toList(),
                isCurved: true,
                color: Colors.green,
                barWidth: 2,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.green.withValues(alpha: 0.1),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (spots) => spots
                    .map(
                      (s) => LineTooltipItem(
                        '\$${s.y.toStringAsFixed(4)}',
                        const TextStyle(color: Colors.green, fontSize: 12),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
