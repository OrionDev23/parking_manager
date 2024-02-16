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
  late TooltipBehavior tooltip;
  List<ChartDataCategory> values = [];

  List<Color> colors=[];
  @override
  void initState() {
    tooltip = TooltipBehavior(enable: true);
    initValues();
    super.initState();
  }


  bool gotenColors=false;

  void getColors(AppTheme appTheme){
    if(!gotenColors){
      colors=appTheme.getRandomColors(values.length);
      gotenColors=true;
    }
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
    List<ChartDataCategory> result = [];
    for (int i = 0; i < widget.labels.length; i++) {
      for (int j = 0; j < values.length; j++) {
        if (widget.labels[i].key == values[j].category) {
          result.add(ChartDataCategory(widget.labels[i].key, values[j].values));
          values.removeAt(j);
          break;
        }
      }
    }
    values.addAll(result);
  }

  Future<void> getValue(int index) async {
    List<ChartData> s = [];
    for (int j = 0; j < widget.labels[index].value.length; j++) {
      s.add(ChartData(j, await widget.labels[index].value[j].value,
          widget.labels[index].value[j].key));
    }
    values.add(ChartDataCategory(widget.labels[index].key, s));
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
            plotAreaBorderWidth: 0,
            legend: const Legend(
              isVisible: true,
            ),
            margin: const EdgeInsets.all(5),
            tooltipBehavior: tooltip,
            primaryYAxis: const NumericAxis(
                interval: 10,
                axisLine: AxisLine(width: 0),
                majorTickLines: MajorTickLines(size: 0)),
            primaryXAxis: const CategoryAxis(
                labelIntersectAction: AxisLabelIntersectAction.multipleRows,
                majorGridLines: MajorGridLines(width: 0)
                ),
            series: List<ColumnSeries<ChartData, String>>.generate(
                values.length, (index) {
              return ColumnSeries(
                  name: values[index].category.tr(),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(5)),
                  color: colors[index],
                  dataSource: values[index].values,
                  width: 1,
                  spacing: 0.1,
                  xValueMapper: (s, r) {
                    return s.label.tr();
                  },
                  dataLabelMapper: (s, t) {
                    return '${s.y.toString()} \n ${s
                        .label.tr()}';
                  },
                  yValueMapper: (s, r) {
                    return s.y;
                  });
            }),
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
