import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../../widgets/empty_widget/src/widget.dart';


class ParcOtoPie extends StatefulWidget {
  final String? title;

  final List<MapEntry<String, Future<int>>> labels;

  const ParcOtoPie(
      {super.key, required this.labels, this.title,});

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

  bool group = true;

  int indexOfBiggest = 0;
  int valueOfBiggest = 0;
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
    loading = false;
    if(mounted){
      setState(() {
      });
    }
  }

  Future<void> getValue(int index) async {
    values.add(
        MapEntry(widget.labels[index].key, await widget.labels[index].value));
  }

  bool notOnlyOne=false;
  void sortAsIntended() {
    int noo=0;
    List<MapEntry<String, int>> result = [];
    for (int i = 0; i < widget.labels.length; i++) {
      for (int j = 0; j < values.length; j++) {
        if (widget.labels[i].key == values[j].key) {
          if (values[j].value > valueOfBiggest) {
            valueOfBiggest = values[j].value;
            indexOfBiggest = i;
          }
          if(values[j].value>0){
              noo++;
          }
          result.add(MapEntry(values[j].key, values[j].value));

          values.removeAt(j);
          break;
        }
      }
    }
    if(noo>1){
      notOnlyOne=true;
    }
    else{
      notOnlyOne=false;
    }
    values.addAll(result);

  }

  late final int totalNumber;

  int minValue = 10;
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    if (loading) {
      return const Center(child: ProgressRing());
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
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
          valueOfBiggest == 0
              ? Flexible(
                  child: SizedBox(
                    width: 250.px,
                    child: EmptyWidget(
                      title: 'nodatayet'.tr(),
                      titleTextStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      image: PackageImage.Image_3.encode(),
                    ),
                  ),
                )
              : Expanded(
                  child: SfCircularChart(
                    legend: const Legend(
                      isVisible: true,
                    ),
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      format: 'point.x : point.y'
                    ),
                    series: [
                      PieSeries<MapEntry<String, int>, String>(
                        radius: '85%',
                        legendIconType: LegendIconType.circle,
                        explode: true,
                        explodeIndex: indexOfBiggest,
                        groupMode: notOnlyOne&&group?CircularChartGroupMode
                            .value:null,
                        groupTo: minValue.toDouble(),
                        dataSource: values,
                        xValueMapper: (s, t) {
                          return s.key.tr();
                        },
                        yValueMapper: (s, t) {
                          return s.value;
                        },
                        dataLabelMapper: (s, t) {
                          return s.key.tr();
                        },
                        dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            textStyle: TextStyle(fontSize: 10),
                            showZeroValue: false,
                            connectorLineSettings:
                                ConnectorLineSettings(type: ConnectorType.line)),
                      )
                    ],
                  ),
                ),
          if (valueOfBiggest != 0 && notOnlyOne)
            SizedBox(
              height: 30.px,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text('groupvalues').tr(),
                  smallSpace,
                  SizedBox(
                    width: 70.px,
                    child: NumberBox(
                        clearButton: false,
                        mode: SpinButtonPlacementMode.none,
                        value: minValue,
                        onChanged: (s) {
                          setState(() {
                            minValue = s ?? 0;
                          });

                        }),
                  ),
                  smallSpace,
                  Checkbox(
                      checked: group,
                      onChanged: (s) => setState(() {
                            group = s ?? false;
                          })),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    values.clear();
    super.dispose();
  }
}
