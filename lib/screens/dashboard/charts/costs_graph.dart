import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:parc_oto/providers/repair_provider.dart';
import 'package:parc_oto/screens/dashboard/charts/common.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../serializables/reparation/reparation.dart';

class CostGraph extends StatefulWidget {
  final DateTime start;
  final DateTime end;
  final AppTheme appTheme;
  final int refreshVersion;

  const CostGraph({
    super.key,
    required this.start,
    required this.end,
    required this.appTheme,
    this.refreshVersion = 0,
  });

  @override
  State<CostGraph> createState() => _CostGraphState();
}

class _CostGraphState extends State<CostGraph> {
  List<Reparation> reparations = [];
  List<ChartDataTimeSpan> values = [];
  bool loading = true;
  String? error;
  double chartTotal = 0;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    initValues();
  }

  @override
  void didUpdateWidget(covariant CostGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshVersion != widget.refreshVersion || oldWidget.start != widget.start || oldWidget.end != widget.end) {
      initValues();
    }
  }

  Future<void> initValues() async {
    final generation = ++_loadGeneration;
    final start = widget.start;
    final end = widget.end;
    setState(() {
      loading = true;
      error = null;
      reparations = [];
      values = [];
      chartTotal = 0;
    });

    try {
      final loaded = await context.read<RepairProvider>().getReparationInMarge(
        start,
        end,
      ).timeout(const Duration(seconds: 30));
      if (!mounted || generation != _loadGeneration) return;

      final inRange = loaded
          .where(
            (repair) =>
                !repair.date.isBefore(start) &&
                !repair.date.isAfter(end),
          )
          .toList();

      final monthlyTotals = <DateTime, double>{};
      for (final repair in inRange) {
        final month = DateTime(repair.date.year, repair.date.month);
        monthlyTotals.update(
          month,
          (total) => total + repair.getPrixTTC(),
          ifAbsent: () => repair.getPrixTTC(),
        );
      }

      final chartValues = monthlyTotals.entries
          .map((entry) => ChartDataTimeSpan(entry.key, entry.value))
          .toList()
        ..sort((a, b) => a.x.compareTo(b.x));

      final calculatedSourceTotal = inRange.fold<double>(
        0,
        (total, repair) => total + repair.getPrixTTC(),
      );
      final calculatedChartTotal = chartValues.fold<double>(
        0,
        (total, point) => total + point.y,
      );

      // The chart must reconcile exactly (within floating-point tolerance)
      // with the sum of the repair records returned by the provider.
      if ((calculatedSourceTotal - calculatedChartTotal).abs() > 0.01) {
        throw StateError(
          'Le total du graphique ne correspond pas au total des réparations.',
        );
      }

      reparations = inRange;
      values = chartValues;
      chartTotal = calculatedChartTotal;

      if (kDebugMode) {
        debugPrint(
          '[ParcOto Dashboard] repair cost chart: '
          '${reparations.length} repairs, '
          'source=$calculatedSourceTotal DA, chart=$chartTotal DA',
        );
      }
    } catch (exception) {
      if (generation == _loadGeneration) error = exception.toString();
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 64,
          height: 16,
          child: LinearProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 24),
            const SizedBox(height: 8),
            const Text('Impossible de vérifier les dépenses.'),
            Text(error!, maxLines: 2, overflow: TextOverflow.ellipsis),
            TextButton(
              onPressed: initValues,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (values.isEmpty) {
      return const Center(child: Text('Aucune réparation sur cette période.'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total vérifié : ${chartTotal.toStringAsFixed(2)} DA'),
              Text('${reparations.length} réparations'),
            ],
          ),
        ),
        Expanded(
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            trackballBehavior: TrackballBehavior(
              enable: true,
              activationMode: ActivationMode.singleTap,
              tooltipSettings: InteractiveTooltip(
                format: 'point.x : point.y DA',
                color: appTheme.backGroundColor,
                textStyle: appTheme.writingStyle,
              ),
            ),
            primaryXAxis: DateTimeAxis(
              intervalType: DateTimeIntervalType.months,
              dateFormat: DateFormat.MMM(),
              majorGridLines: const MajorGridLines(width: 0),
              title: AxisTitle(text: 'months'.tr()),
            ),
            primaryYAxis: NumericAxis(
              title: AxisTitle(text: 'costs'.tr()),
              interval: 20000,
              axisLine: const AxisLine(width: 0),
              labelFormat: '{value} DA',
              majorTickLines: const MajorTickLines(size: 0),
            ),
            series: <LineSeries<ChartDataTimeSpan, DateTime>>[
              LineSeries(
                markerSettings: const MarkerSettings(isVisible: true),
                color: appTheme.color.lightest,
                dataSource: values,
                xValueMapper: (data, _) => data.x,
                yValueMapper: (data, _) => data.y,
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    values.clear();
    reparations.clear();
    super.dispose();
  }
}
