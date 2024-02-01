import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'indicator.dart';

class ParcOtoPie extends StatefulWidget {
  final String? title;

  final List<MapEntry<String, Future<int>>> labels;

  final double radius;

  const ParcOtoPie(
      {super.key, required this.labels, this.title, required this.radius});

  @override
  State<ParcOtoPie> createState() => _ParcOtoPieState();
}

class _ParcOtoPieState extends State<ParcOtoPie> {
  List<MapEntry<String, int>> values = [];

  @override
  void initState() {
    initValues();
    super.initState();
  }

  bool loading = false;

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
      temp += values[j].value;
    }
    totalNumber = temp;
    setState(() {
      loading = false;
    });
  }

  Future<void> getValue(int index) async {
    values.add(
        MapEntry(widget.labels[index].key, await widget.labels[index].value));
  }

  void sortAsIntended() {
    List<MapEntry<String, int>> result = [];
    for (int i = 0; i < widget.labels.length; i++) {
      for (int j = 0; j < values.length; j++) {
        if (widget.labels[i].key == values[j].key) {
          result.add(MapEntry(values[j].key, values[j].value));
          values.removeAt(j);
          break;
        }
      }
    }
    values.addAll(result);
  }

  late final int totalNumber;

  int touchedIndex = -1;

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
          child: AspectRatio(
            aspectRatio: 1.3,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(touchCallback:
                          (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection == null) {
                            touchedIndex = -1;
                            return;
                          }
                          touchedIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      }),
                      sectionsSpace: 0,
                      centerSpaceRadius: 0,
                      borderData: FlBorderData(show: false),
                      sections: List.generate(values.length, (index) {
                        return PieChartSectionData(
                          radius: touchedIndex == index
                              ? widget.radius + 10
                              : widget.radius,
                          value: values[index].value.toDouble(),
                          color: getRandomColor(index, appTheme),
                          title: touchedIndex == index
                              ? '${values[index].key.tr()} : ${values[index].value} / $totalNumber'
                              : '${((values[index].value / totalNumber) * 100).toStringAsFixed(0)} %',
                          titleStyle: TextStyle(
                              fontSize: touchedIndex == index ? 16 : 14,
                              color: Colors.white,
                              shadows: const [
                                Shadow(color: Colors.black, blurRadius: 2)
                              ]),
                          showTitle: true,
                        );
                      }),
                    ),
                  ),
                ),
                bigSpace,
                Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(values.length, (index) {
                      return Indicator(
                        text: values[index].key.tr(),
                        color: getRandomColor(index, appTheme),
                        size: 10.px,
                        isSquare: true,
                      );
                    })),
              ],
            ),
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
