import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/purchase_history_repository.dart';

class ManagementAnalyticsSection extends StatefulWidget {
  const ManagementAnalyticsSection({super.key});

  @override
  State<ManagementAnalyticsSection> createState() =>
      _ManagementAnalyticsSectionState();
}

class _ManagementAnalyticsSectionState
    extends State<ManagementAnalyticsSection> {
  final PurchaseHistoryRepository _historyRepository =
      PurchaseHistoryRepository();

  Map<String, int> _consumptionByDay = {};
  List<Map<String, dynamic>> _storeSummaries = [];
  Map<String, dynamic> _consumptionOutcomes = {};
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final dates = _periodDates();
      final results = await Future.wait<Object>([
        _historyRepository.getConsumptionByDay(
          startDate: dates.start,
          endDateExclusive: dates.end,
        ),
        _historyRepository.getStorePurchaseSummaries(),
        _historyRepository.getConsumptionOutcomeSummary(),
      ]);
      final consumptionRows = results[0] as List<Map<String, dynamic>>;
      final storeRows = results[1] as List<Map<String, dynamic>>;
      final outcomeRow = results[2] as Map<String, dynamic>;
      final consumptionByDay = {
        for (final row in consumptionRows)
          row['fecha'] as String: (row['unidades'] as num).toInt(),
      };

      if (!mounted) return;
      setState(() {
        _consumptionByDay = consumptionByDay;
        _storeSummaries = storeRows;
        _consumptionOutcomes = outcomeRow;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('Error cargando estadísticas: $error\n$stackTrace');
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  ({DateTime start, DateTime end}) _periodDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return (
      start: today.subtract(const Duration(days: 6)),
      end: today.add(const Duration(days: 1)),
    );
  }

  List<DateTime> _periodDays() {
    final dates = _periodDates();
    return [
      for (
        var day = dates.start;
        day.isBefore(dates.end);
        day = day.add(const Duration(days: 1))
      )
        day,
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Card(
        color: AppTheme.surfaceCard,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text(
                'No se pudieron cargar las estadísticas.',
                style: TextStyle(color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loadAnalytics,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildConsumptionCard(),
        const SizedBox(height: 12),
        _buildStoresCard(),
        const SizedBox(height: 12),
        _buildConsumptionOutcomesCard(),
        const SizedBox(height: 120),
      ],
    );
  }

  Widget _buildConsumptionCard() {
    final days = _periodDays();
    final values = [
      for (final day in days) _consumptionByDay[_dateOnly(day)] ?? 0,
    ];
    final total = values.fold<int>(0, (sum, quantity) => sum + quantity);
    final maxValue = values.fold<int>(
      0,
      (maximum, value) => value > maximum ? value : maximum,
    );
    final chartMax = maxValue > 0 ? maxValue.toDouble() : 1.0;
    final calculatedYInterval = (chartMax / 3).ceilToDouble();
    final yInterval = calculatedYInterval > 1 ? calculatedYInterval : 1.0;

    return _analyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Consumo',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '$total UN',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _periodLabel(days),
            style: const TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          if (total == 0)
            const _EmptyAnalyticsMessage(
              message: 'Sin consumos en este periodo.',
            )
          else
            SizedBox(
              height: 170,
              child: BarChart(
                BarChartData(
                  maxY: chartMax,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppTheme.borderSeparator,
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    for (var index = 0; index < days.length; index++)
                      BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: values[index].toDouble(),
                            width: 20,
                            color: AppTheme.accentBlue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) => SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= days.length) {
                            return const SizedBox.shrink();
                          }
                          final date = days[index];
                          final label = const [
                            'L',
                            'M',
                            'X',
                            'J',
                            'V',
                            'S',
                            'D',
                          ][date.weekday - 1];
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoresCard() {
    final totalUnits = _storeSummaries.fold<int>(
      0,
      (total, store) => total + (store['unidades'] as num).toInt(),
    );

    return _analyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiendas habituales',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (_storeSummaries.isEmpty)
            const _EmptyAnalyticsMessage(
              message: 'Aún no hay compras registradas.',
            )
          else ...[
            for (final store in _storeSummaries)
              _buildStoreSummary(store, totalUnits),
            const SizedBox(height: 4),
            const Text(
              'El gasto suma solo compras con precio registrado.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStoreSummary(Map<String, dynamic> store, int totalUnits) {
    final units = (store['unidades'] as num).toInt();
    final share = totalUnits == 0 ? 0.0 : units / totalUnits;
    final percentage = (share * 100).round();
    final spend = store['gasto_total'] as num?;
    final spendLabel = spend == null
        ? 'Sin precios registrados'
        : 'Importe: \$${spend.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  store['tienda_nombre'] as String? ?? 'Tienda desconocida',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppTheme.textPrimary),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$units UN · $percentage%',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            spendLabel,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 5,
              backgroundColor: AppTheme.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.accentBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionOutcomesCard() {
    final depleted = (_consumptionOutcomes['agotados'] as num?)?.toInt() ?? 0;
    final partial = (_consumptionOutcomes['parciales'] as num?)?.toInt() ?? 0;
    final total = depleted + partial;

    return _analyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Agotamiento de stock',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (total == 0)
            const _EmptyAnalyticsMessage(
              message: 'Aún no hay consumos registrados.',
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          centerSpaceRadius: 34,
                          sectionsSpace: 3,
                          sections: [
                            if (depleted > 0)
                              PieChartSectionData(
                                value: depleted.toDouble(),
                                color: AppTheme.statusExpired,
                                radius: 24,
                                showTitle: false,
                              ),
                            if (partial > 0)
                              PieChartSectionData(
                                value: partial.toDouble(),
                                color: AppTheme.statusGood,
                                radius: 24,
                                showTitle: false,
                              ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$total',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'consumos',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOutcomeLegend(
                        label: 'Agotado',
                        count: depleted,
                        total: total,
                        color: AppTheme.statusExpired,
                      ),
                      const SizedBox(height: 12),
                      _buildOutcomeLegend(
                        label: 'Consumo parcial',
                        count: partial,
                        total: total,
                        color: AppTheme.statusGood,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOutcomeLegend({
    required String label,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = (count / total * 100).round();
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 12),
          ),
        ),
        Text(
          '$count · $percentage%',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _analyticsCard({required Widget child}) {
    return Card(
      color: AppTheme.surfaceCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  String _periodLabel(List<DateTime> days) {
    if (days.isEmpty) return '';
    final start = days.first;
    final end = days.last;
    if (start.month != end.month) {
      return '${start.day} ${_monthName(start.month)} – '
          '${end.day} ${_monthName(end.month)} ${end.year}';
    }
    return '${start.day}–${end.day} ${_monthName(end.month)} ${end.year}';
  }

  String _monthName(int month) => const [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ][month - 1];

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class _EmptyAnalyticsMessage extends StatelessWidget {
  const _EmptyAnalyticsMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: AppTheme.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
