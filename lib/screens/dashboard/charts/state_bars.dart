import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../theme.dart';
import '../pie_chart/indicator.dart';
import 'common.dart';

class StateBars extends StatefulWidget {
  final String? title;

  final List<MapEntry<String, Future<int>>> labels;
  const StateBars({super.key, required this.labels, this.title});

  @override
  State<StateBars> createState() => _StateBarsState();
}

class _StateBarsState extends State<StateBars> {
  bool loading = false;

  List<ChartData> values = [];
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
    int temp = 0;
    for (int j = 0; j < values.length; j++) {
      temp += values[j].y;
    }
    totalNumber = temp;
    setState(() {
      loading = false;
    });
  }
  late final int totalNumber;

  void sortAsIntended() {
    List<ChartData> result = [];
    for (int i = 0; i < widget.labels.length; i++) {
      for (int j = 0; j < values.length; j++) {
        if (widget.labels[i].key == values[j].label) {
          result.add(ChartData(values[j].x, values[j].y,values[j].label));
          values.removeAt(j);
          break;
        }
      }
    }
    values.addAll(result);


  }

  Future<void> getValue(int index) async {
    values.add(
        ChartData(index, await widget.labels[index].value,widget.labels[index]
            .key));
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

                enableAxisAnimation: true,
                primaryXAxis: const CategoryAxis(
                  arrangeByIndex: true,
                ),
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  animationDuration: 0,
                  duration: 1000,
                ),
                series: <CartesianSeries<ChartData, String>>[
                  ColumnSeries(
                      dataSource: values,

                      xValueMapper: ( s,r){
                        return s.label.tr();
                      },
                      dataLabelMapper: (s,t){
                        return s.label.tr();
                      },
                      pointColorMapper: (s,t){
                        return getRandomColor(t, appTheme);
                      },
                      yValueMapper: ( s,r){
                        return s.y;
                      })
                ],
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
