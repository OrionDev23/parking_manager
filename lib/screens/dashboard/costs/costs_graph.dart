import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/theme.dart';
import 'package:parc_oto/utilities/profil_beautifier.dart';

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

  Map<int,double> values={};

  bool loading = true;

  @override
  void initState() {
    initValues();
    super.initState();
  }

  void initValues() async {
    reparations =
        await ClientDatabase().getReparationInMarge(widget.start, widget.end);
    if (kDebugMode) {
      print('got them lenght :${reparations.length}');
    }
    fillValues();
    if (kDebugMode) {

      values.forEach((key, value) {
      print('$key cost : $value');
    });}
    gradiantColors = [
      widget.appTheme.color.darkest,
      widget.appTheme.color.light,
    ];

    setState(() {
      loading = false;
    });
  }

  void fillValues(){
    for(var r in reparations){
      values[getDate(r.date)]=r.getPrixTTC();
    }
  }

  int getDate(DateTime date){
    // start ===> -6
    // end ===> 0
    // a(start)+b=
    // a(end)+b=0
    // a=-b/end
    //-start*b/end+b=-6 ==> -start*b/end+end*b/end=-6 ==> (-start*b+end*b)/end=-6
    // -6*end=(-start+end)*b
    //(-6*end)/(-start+end)=b
    // a=(-6*end)/((start+end)*end)


    int start=dateToIntJson(widget.start)!;
    int end=dateToIntJson(widget.end)!;
    int current=dateToIntJson(date)!;

    double b=(-6*end)/(-start+end);
    double a=-b/end;

    return (a*current+b).toInt();
  }



  List<Color> gradiantColors = [];
  bool showAvg = false;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: ProgressRing());
    }
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1.7,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 18,
              left: 12,
              top: 24,
              bottom: 12,
            ),
            child: LineChart(
              showAvg ? avgData() : mainData(),
            ),
          ),
        ),
        SizedBox(
          width: 60,
          height: 34,
          child: Button(
            onPressed: () {
              setState(() {
                showAvg = !showAvg;
              });
            },
            child: Text(
              'avg',
              style: TextStyle(
                fontSize: 12,
                color: showAvg
                    ? widget.appTheme.writingStyle.color!.withOpacity(0.5)
                    : widget.appTheme.writingStyle.color!,
              ),
            ).tr(),
          ),
        ),
      ],
    );
  }

  Widget bottomTitleWidget(double value, TitleMeta meta) {
    Widget text = Text(
      DateFormat('MMM', 'fr')
          .format(DateTime(0, widget.end.month+value.toInt())),
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9),
    );

    return SideTitleWidget(axisSide: meta.axisSide, child: text);
  }

  Widget leftTitleWidget(double value, TitleMeta meta) {

    String text="";
    switch(value.toInt()){
      case 20000:
        text= '20.000 DA';
        break;
      case 40000:
        text= '40.000 DA';
        break;
      case 60000:
        text='60.000 DA';
        break;
      case 80000:
        text='80.000 DA';
        break;
    }
    return  Text(text,style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 9));
  }

  LineChartData mainData() {
    return LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 5000,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: widget.appTheme.color,
              strokeWidth: 0.1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: widget.appTheme.color,
              strokeWidth: 0.1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: bottomTitleWidget,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 5000,
              getTitlesWidget: leftTitleWidget,
              reservedSize: 42,
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: widget.appTheme.backGroundColor),
        ),
        minX: -6,
        maxX: 0,
        minY: 0,
        maxY: 100000,
        lineBarsData: [
          LineChartBarData(
            spots: values.entries.map((e) => FlSpot(
              e.key.toDouble(),
              e.value,)).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: gradiantColors,
            ),
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: gradiantColors
                      .map((color) => color.withOpacity(0.3))
                      .toList(),
                )),
          )
        ]);
  }

  LineChartData avgData(){
    double avg=getAverage();
    return LineChartData(
      lineTouchData: const LineTouchData(enabled: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        verticalInterval: 1,
        horizontalInterval: 10000,
        getDrawingVerticalLine: (value){
          return FlLine(
            color: widget.appTheme.color,
            strokeWidth: 1,
          );
        },
        getDrawingHorizontalLine: (value){
          return FlLine(
            color: widget.appTheme.color,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 10000,
            getTitlesWidget: bottomTitleWidget,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: leftTitleWidget,
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: widget.appTheme.backGroundColor),
      ),
      minX: 1,
      maxX: 12,
      minY: 0,
      maxY: 100000,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(reparations.length, (index) {
              return FlSpot(
                  reparations[index].date.month +
                      (reparations[index].date.day / 30),
                  avg);
            }),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                ColorTween(begin: gradiantColors[0],end: gradiantColors[1]).lerp(0.2)!,
                ColorTween(begin: gradiantColors[0],end: gradiantColors[1]).lerp(0.2)!,
              ],
            ),
            barWidth: 5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    ColorTween(begin: gradiantColors[0],end: gradiantColors[1]).lerp(0.2)!.withOpacity(0.1),
                    ColorTween(begin: gradiantColors[0],end: gradiantColors[1]).lerp(0.2)!.withOpacity(0.1),
                  ],
                ),),
          )
        ]
    );
  }

  double getMinValue() {
    double min = 0;
    for (int i = 0; i < reparations.length; i++) {
      if (min > reparations[i].getPrixTTC()) {
        min = reparations[i].getPrixTTC();
      }
    }
    return min;
  }

  double getMaxValue() {
    double max = 0;
    for (int i = 0; i < reparations.length; i++) {
      if (max < reparations[i].getPrixTTC()) {
        max = reparations[i].getPrixTTC();
      }
    }
    return max;
  }

  double getAverage(){
    double avg = 0;
    for (int i = 0; i < reparations.length; i++) {
        avg += reparations[i].getPrixTTC();
    }
    return avg/reparations.length;
  }
}
