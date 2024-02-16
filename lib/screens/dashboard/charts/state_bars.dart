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
  const StateBars(
      {super.key,
      this.hideEmpty = false,
      required this.labels,
      this.vertical = false,
      this.title});

  @override
  State<StateBars> createState() => _StateBarsState();
}

class _StateBarsState extends State<StateBars> {
  bool loading = false;

  List<ChartData> values = [];
  List<Color> colors=[];
  late TooltipBehavior tooltip;
  @override
  void initState() {
    tooltip = TooltipBehavior(enable: true);

    initValues();
    super.initState();
  }

  void initValues() async {
    loading = true;
    List<Future> tasks = [];
    for (int i = 0; i < widget.labels.length; i++) {
      tasks.add(getValue(i));
    }
    await Future.wait(tasks);
    sortAsIntended();
    loading = false;
    if(mounted){
      setState(() {
      });
    }

  }

  void sortAsIntended() {
    loading = true;
    List<ChartData> result = [];
    for (int i = 0; i < widget.labels.length; i++) {
      for (int j = 0; j < values.length; j++) {
        if (widget.labels[i].key == values[j].label) {
          if (values[j].y != 0 || !widget.hideEmpty) {
            result.add(ChartData(values[j].x, values[j].y, values[j].label));
          }
          values.removeAt(j);
          break;
        }
      }
    }
    values.clear();
    values.addAll(result);
  }

  Future<void> getValue(int index) async {
    values.add(ChartData(
        index, await widget.labels[index].value, widget.labels[index].key));
  }

  bool hideEmptyFil = true;

  bool gotenColors=false;

  void getColors(AppTheme appTheme){
    if(!gotenColors){
      colors=appTheme.getRandomColors(values.length);
      gotenColors=true;
    }
  }
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    if (loading) {
      return const Center(child: ProgressRing());
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
                color: appTheme.writingStyle.color),
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
                majorTickLines: MajorTickLines(size: 0)),
            tooltipBehavior: tooltip,
            primaryXAxis: const CategoryAxis(
              labelIntersectAction: AxisLabelIntersectAction.multipleRows,
              majorGridLines: MajorGridLines(width: 0),
              arrangeByIndex: false,
            ),
            series: <CartesianSeries<ChartData, String>>[
              ColumnSeries(
                  width: widget.vertical ? 0.5 : 0.7,
                  name: '',
                  pointColorMapper: (s,o){
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
                      textStyle: TextStyle(
                        color: appTheme.writingStyle.color,
                      ),
                      labelAlignment: ChartDataLabelAlignment.bottom),
                  dataLabelMapper: (s, t) {
                    return s.y.toString();
                  },
                  yValueMapper: (s, r) {
                    return s.y;
                  })
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
