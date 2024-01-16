import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/theme.dart';

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

  bool loading = true;

  @override
  void initState() {
    initValues();
    super.initState();
  }

  void initValues() async {
    reparations =
        await ClientDatabase().getReparationInMarge(widget.start, widget.end);
    gradiantColors = [
      widget.appTheme.color.darkest,
      widget.appTheme.color.light,
    ];

    setState(() {
      loading = false;
    });
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
          .format(DateTime(widget.start.year, value.toInt()+1)),
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );

    return SideTitleWidget(axisSide: meta.axisSide, child: text);
  }

  Widget leftTitleWidget(double value, TitleMeta meta) {
    return Text(NumberFormat.compactCurrency(
      symbol: 'DZ',
      locale: 'fr',
    ).format(value.toInt()));
  }

  LineChartData mainData() {
    return LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: widget.appTheme.color,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
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
              interval: 1,
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
        minX: 0,
        maxX: 11,
        minY: getMinValue(),
        maxY: getMaxValue(),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(reparations.length, (index) {
              return FlSpot(
                  reparations[index].date.month +
                      (reparations[index].date.day / 30),
                  reparations[index].getPrixTTC());
            }),
            isCurved: true,
            gradient: LinearGradient(
              colors: gradiantColors,
            ),
            barWidth: 5,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
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
        horizontalInterval: 1,
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
            interval: 1,
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
      minX: 0,
      maxX: 11,
      minY: getMinValue(),
      maxY: getMaxValue(),
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
            dotData: const FlDotData(show: false),
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
