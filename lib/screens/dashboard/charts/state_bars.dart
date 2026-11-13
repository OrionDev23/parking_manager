import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../theme.dart';
import 'common.dart';

class StateBars extends StatefulWidget {
  final String? title;
  final bool vertical;
  final bool hideEmpty;

  final List<MapEntry<String, Future<int>>> labels;
  const StateBars({
    super.key,
    this.hideEmpty = false,
    required this.labels,
    this.vertical = false,
    this.title,
  });

  @override
  State<StateBars> createState() => _StateBarsState();
}

class _StateBarsState extends State<StateBars> {
  bool loading = false;

  List<ChartData> values = [];
  List<Color> colors = [];
  String? error;
  int _loadGeneration = 0;
  @override
  void initState() {
    super.initState();
    initValues();
  }

  bool _sameInputs(StateBars other) {
    if (widget.labels.length != other.labels.length ||
        widget.hideEmpty != other.hideEmpty ||
        widget.vertical != other.vertical) {
      return false;
    }
    for (var i = 0; i < widget.labels.length; i++) {
      if (widget.labels[i].key != other.labels[i].key ||
          !identical(widget.labels[i].value, other.labels[i].value)) {
        return false;
      }
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant StateBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameInputs(oldWidget)) initValues();
  }

  Future<void> initValues() async {
    final generation = ++_loadGeneration;
    final labels = widget.labels;
    setState(() {
      loading = true;
      error = null;
      // Do not mutate the list currently held by Syncfusion's chart.
      values = [];
      gotenColors = false;
      colors.clear();
    });

    try {
      final loaded = await Future.wait<ChartData>([
        for (var i = 0; i < labels.length; i++)
          labels[i].value.then(
            (value) => ChartData(i, value, labels[i].key),
          ),
      ]).timeout(const Duration(seconds: 25));
      if (!mounted || generation != _loadGeneration) return;
      values = _sortAsIntended(loaded, labels);
      gotenColors = false;
      colors = [];
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

  List<ChartData> _sortAsIntended(
    List<ChartData> source,
    List<MapEntry<String, Future<int>>> labels,
  ) {
    final byLabel = {for (final item in source) item.label: item};
    final sorted = <ChartData>[];
    for (var i = 0; i < labels.length; i++) {
      final item = byLabel[labels[i].key];

      // Map lookup is nullable: skip missing entries instead of force-unwrapping.
      if (item == null) continue;
      if (item.y == 0 && widget.hideEmpty) continue;

      sorted.add(ChartData(i, item.y, item.label));
    }
    return sorted;
  }


  bool hideEmptyFil = true;

  bool gotenColors = false;

  void getColors(AppTheme appTheme) {
    if (!gotenColors) {
      colors = appTheme.getRandomColors(values.length);
      gotenColors = true;
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
            isTransposed: widget.vertical,
            plotAreaBorderWidth: 0,
            margin: const EdgeInsets.all(5),
            primaryYAxis: const NumericAxis(
              interval: 10,
              axisLine: AxisLine(width: 0),
              majorTickLines: MajorTickLines(size: 0),
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              color: appTheme.backGroundColor,
              textStyle: appTheme.writingStyle,
            ),
            primaryXAxis: const CategoryAxis(
              labelIntersectAction: AxisLabelIntersectAction.multipleRows,
              majorGridLines: MajorGridLines(width: 0),
              arrangeByIndex: false,
            ),
            series: <CartesianSeries<ChartData, String>>[
              ColumnSeries(
                width: widget.vertical ? 0.5 : 0.7,
                name: '',
                pointColorMapper: (s, o) {
                  return colors[o];
                },
                borderRadius: widget.vertical
                    ? const BorderRadius.horizontal(right: Radius.circular(5))
                    : const BorderRadius.vertical(top: Radius.circular(5)),
                dataSource: values,
                xValueMapper: (s, r) {
                  return s.label.tr();
                },
                dataLabelSettings: DataLabelSettings(
                  isVisible: true,
                  useSeriesColor: false,
                  showZeroValue: false,
                  textStyle: TextStyle(color: appTheme.writingStyle.color),
                  labelAlignment: ChartDataLabelAlignment.bottom,
                ),
                dataLabelMapper: (s, t) {
                  return s.y.toString();
                },
                yValueMapper: (s, r) {
                  return s.y;
                },
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
    super.dispose();
  }
}
