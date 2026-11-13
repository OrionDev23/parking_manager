import 'package:easy_localization/easy_localization.dart';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../theme.dart';
import 'common.dart';

class StateCategoryBars extends StatefulWidget {
  final String? title;

  final List<MapEntry<String, List<MapEntry<String, Future<int>>>>> labels;

  const StateCategoryBars({super.key, required this.labels, this.title});

  @override
  State<StateCategoryBars> createState() => _StateBarsState();
}

class _StateBarsState extends State<StateCategoryBars> {
  bool loading = false;
  List<ChartDataCategory> values = [];

  List<Color> colors = [];
  String? error;
  int _loadGeneration = 0;
  @override
  void initState() {
    super.initState();
    initValues();
  }

  bool gotenColors = false;

  void getColors(AppTheme appTheme) {
    if (!gotenColors) {
      colors = appTheme.getRandomColors(values.length);
      gotenColors = true;
    }
  }

  bool _sameInputs(StateCategoryBars other) {
    if (widget.labels.length != other.labels.length) return false;
    for (var i = 0; i < widget.labels.length; i++) {
      final current = widget.labels[i];
      final previous = other.labels[i];
      if (current.key != previous.key ||
          current.value.length != previous.value.length) {
        return false;
      }
      for (var j = 0; j < current.value.length; j++) {
        if (current.value[j].key != previous.value[j].key ||
            !identical(current.value[j].value, previous.value[j].value)) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant StateCategoryBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameInputs(oldWidget)) initValues();
  }

  Future<void> initValues() async {
    final generation = ++_loadGeneration;
    final labels = widget.labels;
    setState(() {
      loading = true;
      error = null;
      // Keep the previous chart data immutable while a refresh is pending.
      values = [];
      gotenColors = false;
      colors.clear();
    });

    try {
      final loaded = await Future.wait([
        for (final category in labels)
          () async {
            final categoryValues = await Future.wait([
              for (var i = 0; i < category.value.length; i++)
                category.value[i].value.then(
                  (value) => ChartData(i, value, category.value[i].key),
                ),
            ]);
            return ChartDataCategory(category.key, categoryValues);
          }(),
      ]);
      if (!mounted || generation != _loadGeneration) return;
      values = loaded;
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
    var appTheme = context.watch<AppTheme>();
    if (loading) {
      return const Center(child: ProgressRing());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(FluentIcons.warning, size: 24),
            const SizedBox(height: 8),
            const Text('Impossible de vérifier ces statistiques.'),
            Text(error!, maxLines: 2, overflow: TextOverflow.ellipsis),
            Button(onPressed: initValues, child: const Text('Réessayer')),
          ],
        ),
      );
    }
    if (values.isEmpty) {
      return const Center(child: Text('Aucune donnée à afficher.'));
    }
    getColors(appTheme);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Text(
            widget.title!,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: appTheme.writingStyle.color,
            ),
          ),
        smallSpace,
        Expanded(
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            legend: const Legend(isVisible: true),
            margin: const EdgeInsets.all(5),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              color: appTheme.backGroundColor,
              textStyle: appTheme.writingStyle,
            ),
            primaryYAxis: const NumericAxis(
              interval: 10,
              axisLine: AxisLine(width: 0),
              majorTickLines: MajorTickLines(size: 0),
            ),
            primaryXAxis: const CategoryAxis(
              labelIntersectAction: AxisLabelIntersectAction.multipleRows,
              majorGridLines: MajorGridLines(width: 0),
            ),
            series: List<ColumnSeries<ChartData, String>>.generate(
              values.length,
              (index) {
                return ColumnSeries(
                  name: values[index].category.tr(),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(5),
                  ),
                  color: colors[index],
                  dataSource: values[index].values,
                  width: 1,
                  spacing: 0.1,
                  xValueMapper: (s, r) {
                    return s.label.tr();
                  },
                  dataLabelMapper: (s, t) {
                    return '${s.y.toString()} \n ${s.label.tr()}';
                  },
                  yValueMapper: (s, r) {
                    return s.y;
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    values.clear();
    super.dispose();
  }
}
