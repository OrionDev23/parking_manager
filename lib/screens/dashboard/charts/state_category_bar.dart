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
  @override
  void initState() {
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
    setState(() {
      loading = false;
    });
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
            margin: const EdgeInsets.all(5),
            primaryXAxis: const CategoryAxis(
                //arrangeByIndex: true,
                ),
            series: List<ColumnSeries<ChartDataCategory, String>>.generate(
                values.first.values.length, (index) {
              return ColumnSeries(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(5)),
                  dataSource: values,
                  width: 1,
                  spacing: 0.1,
                  xValueMapper: (s, r) {
                    return s.category.tr();
                  },
                  dataLabelSettings: DataLabelSettings(
                    isVisible: true,
                    builder: (data, point, series, pointIndex, seriesIndex) {
                      ChartDataCategory d = data;
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            d.values[seriesIndex].y.toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                          smallSpace,

                          SizedBox(
                            height: (point.y??0).toDouble()*0.65,
                          ),
                          Text(
                            d.values[seriesIndex].label.tr(),
                            style: const TextStyle(fontSize: 10),
                          ),
                          smallSpace,
                        ],
                      );
                    },
                    labelPosition: ChartDataLabelPosition.inside,
                    labelAlignment: ChartDataLabelAlignment.auto,
                    margin: EdgeInsets.zero,
                  ),
                  dataLabelMapper: (s, t) {
                    return '${s.values[index].y.toString()} \n ${s.values[index].label.tr()}';
                  },
                  pointColorMapper: (s, t) {
                    return getRandomColor(t, appTheme);
                  },
                  yValueMapper: (s, r) {
                    return s.values[index].y;
                  });
            }),
          ),
        ),
      ],
    );
  }

  Color getRandomColor(int index, AppTheme appTheme) {
    switch (index) {
      case 0:
        return appTheme.color.lightest;
      case 1:
        return appTheme.color;
      case 2:
        return appTheme.color.darker;
      case 3:
        return appTheme.color.light;
      case 4:
        return appTheme.color.darkest;
      case 5:
        return appTheme.color.lighter;
      case 6:
        return appTheme.color.dark;
      default:
        return appTheme.color;
    }
  }
}
