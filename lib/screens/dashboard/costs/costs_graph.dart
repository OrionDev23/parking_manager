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

  List<MapEntry<int,double>>values=[];

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
    gradiantColors = [
      widget.appTheme.color.darkest,
      widget.appTheme.color.light,
    ];

    setState(() {
      loading = false;
    });
  }

  void fillValues(){
    int date=0;
    for(var r in reparations){
      date=getDate(r.date);
      if(datePresent(date)){
        addToValue(date,r.getPrixTTC());
      }
      else{
        values.add(MapEntry(date,r.getPrixTTC()));
      }
    }

    values.sort((a,b)=>a.key.compareTo(b.key));
  }

  void addToValue(int date,double value){
    for(int j=0;j<values.length;j++){
      if(values[j].key==date){
        values[j]=MapEntry(values[j].key, values[j].value+value);
        return;
      }
    }
  }

  bool datePresent(int date){
    for(int j=0;j<values.length;j++){
      if(values[j].key==date){
        return true;
      }
    }
    return false;
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

    double result=(a*current+b);

    return result.round();
  }



  List<Color> gradiantColors = [];
  bool showAvg = false;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: ProgressRing());
    }
    return Stack(
      alignment: Alignment.topRight,
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
          width: 100,
          height: 34,
          child: HyperlinkButton(
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
                    ? widget.appTheme.color.withOpacity(0.5)
                    : widget.appTheme.color,
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

    String text=NumberFormat.currency(locale: 'fr',symbol:'DA',decimalDigits:0).format(value);
    return  Text(text,style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 8));
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
              interval: 20000,
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
        maxY: getMaxValue()+20000,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(values.length, (index) => FlSpot(
      values[index].key.toDouble(),
      values[index].value,),),
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
            strokeWidth: 0.1,
          );
        },
        getDrawingHorizontalLine: (value){
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
            interval: 20000,
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
      maxY: getMaxValue()+20000,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(values.length, (index) => FlSpot(
              values[index].key.toDouble(),
              avg,),),
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
        ]
    );
  }

  double getMinValue() {
    double min = 0;
    for(int i=0;i<values.length;i++){
      if(values[i].value<min){
        min=values[i].value;
      }
    }
    return min;
  }

  double getMaxValue() {
    double max = 0;
    for(int i=0;i<values.length;i++){
      if(values[i].value>max){
        max=values[i].value;
      }
    }
    max=((max/20000).ceil())*20000;
    return max;
  }

  double getAverage(){
    double avg = 0;
    for(int i=0;i<values.length;i++){
      avg+=values[i].value;
    }
    return avg/values.length;
  }
}
