import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  const CostGraph(
      {super.key,
      required this.start,
      required this.end,
      required this.appTheme});

  @override
  State<CostGraph> createState() => _CostGraphState();
}

class _CostGraphState extends State<CostGraph> {
  List<Reparation> reparations = [];

  List<ChartDataTimeSpan> values = [];

  bool loading = true;

  @override
  void initState() {
    initValues();
    super.initState();
  }

  void initValues() async {
    reparations =
        await RepairProvider().getReparationInMarge(widget.start, widget.end);
    if (kDebugMode) {
      print('got them lenght :${reparations.length}');
    }
    fillValues();

    loading = false;
    if(mounted){
      setState(() {
      });
    }
  }

  void fillValues() {
    for (var r in reparations) {
      if (datePresent(r.date)) {
        addToValue(DateTime(r.date.year,r.date.month), r.getPrixTTC());
      } else {
        values.add(ChartDataTimeSpan(DateTime(r.date.year,r.date.month), r
            .getPrixTTC
          ()));
      }
    }

    values.sort((a, b) => a.x.compareTo(b.x));
  }

  void addToValue(DateTime date, double value) {
    for (int j = 0; j < values.length; j++) {
      if (values[j].x == date) {
        values[j] = ChartDataTimeSpan(values[j].x, values[j].y + value);
        return;
      }
    }
  }

  bool datePresent(DateTime date) {
    for (int j = 0; j < values.length; j++) {
      if (values[j].x.month == date.month && values[j].x.year==date.year) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    if (loading) {
      return const Center(
          child: SizedBox(
              width: 64, height: 16, child: LinearProgressIndicator()));
    }
    return Column(
      children: [
        Expanded(
          child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              trackballBehavior: TrackballBehavior(
                  enable: true,
                  activationMode: ActivationMode.singleTap,
                  tooltipSettings:
                      InteractiveTooltip(
                          format: 'point.x : point.y DA',
                          color: appTheme.backGroundColor,
                          textStyle: appTheme.writingStyle

                      )),
              primaryXAxis: DateTimeAxis(

                  intervalType: DateTimeIntervalType.months,
                  dateFormat: DateFormat.MMM(),
                  majorGridLines: const MajorGridLines(width: 0),

                  title: AxisTitle(text: 'months'.tr())),
              primaryYAxis:  NumericAxis(
                  title: AxisTitle(text:'costs'.tr()),
                  interval: 20000,
                  axisLine: const AxisLine(width: 0),
                  labelFormat: '{value} DA',
                  majorTickLines: const MajorTickLines(size: 0)),
              series: <LineSeries<ChartDataTimeSpan, DateTime>>[
                LineSeries(
                  markerSettings: const MarkerSettings(
                    isVisible: true
                  ),
                    color: appTheme.color.lightest,
                    dataSource: values,
                    xValueMapper: (data, t) {
                      return data.x;
                    },
                    yValueMapper: (data, t) {
                      return data.y;
                    }),
              ]),
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
