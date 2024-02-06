import 'package:easy_localization/easy_localization.dart';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../theme.dart';
import 'common.dart';

class StateCategoryBars extends StatefulWidget {
  final String? title;

  final List<MapEntry<String,List<MapEntry<String,Future<int>>>>>labels;

  const StateCategoryBars({super.key, required this.labels, this.title});

  @override
  State<StateCategoryBars> createState() => _StateBarsState();
}

class _StateBarsState extends State<StateCategoryBars> {
  bool loading = false;

  List<MapEntry<String,List<ChartData>>> values = [];
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
    List<MapEntry<String,List<ChartData>>> result = [];

    List<ChartData> res2=[];
    for(int i=0;i<widget.labels.length;i++){
      res2.clear();
      for(int k=0;k<values.length;k++){
          if(values[k].key==widget.labels[i].key){
            for(int j=0;j<values[k].value.length;j++){
                res2.add(ChartData(values[k].value[j].x, values[k].value[j].y, values[k].value[j].label));
            }
            break;
          }
      }
      result.add(MapEntry(widget.labels[i].key, res2));
    }
    values.clear();
    values.addAll(result);


  }

  Future<void> getValue(int index) async {

    List<ChartData> s=[];
    for(int j=0;j<widget.labels[index].value.length;j++){
      s.add(ChartData(j, await widget.labels[index].value[j].value, widget
          .labels[index].value[j].key));
    }
    values.add(
        MapEntry(widget.labels[index].key,
            s)
    );

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
            series: List.generate(values.length, (index) => ColumnSeries(
                name: values[index].key.tr(),
                dataSource: values[index].value,
                xValueMapper: ( s,r){
                  return s.label.tr();
                },
                dataLabelSettings: const DataLabelSettings(
                  isVisible: true,
                  useSeriesColor: true,
                ),
                dataLabelMapper: (s,t){
                  return s.y.toString();
                },
                pointColorMapper: (s,t){
                  return getRandomColor(t, appTheme);
                },
                yValueMapper: ( s,r){
                  return s.y;
                })),
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
