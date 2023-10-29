import 'package:fl_chart/fl_chart.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
class TransactionChart extends StatefulWidget {
  const TransactionChart({super.key});

  @override
  State<StatefulWidget> createState() => TransactionChartState();
}

class TransactionChartState extends State<TransactionChart> {
  final double width = 7;
  List<BarChartGroupData>? rawBarGroups;
  late List<BarChartGroupData> showingBarGroups;

  int touchedGroupIndex = -1;


  void makeGroups(AppTheme appTheme){
    final barGroup1 = makeGroupData(appTheme,0, 5, 12);
    final barGroup2 = makeGroupData(appTheme,1, 16, 12);
    final barGroup3 = makeGroupData(appTheme,2, 18, 5);
    final barGroup4 = makeGroupData(appTheme,3, 20, 16);
    final barGroup5 = makeGroupData(appTheme,4, 17, 6);
    final barGroup6 = makeGroupData(appTheme,5, 19, 1.5);
    final barGroup7 = makeGroupData(appTheme,6, 10, 1.5);

    final items = [
      barGroup1,
      barGroup2,
      barGroup3,
      barGroup4,
      barGroup5,
      barGroup6,
      barGroup7,
    ];

    rawBarGroups = items;

    showingBarGroups = rawBarGroups!;
  }

  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    if(rawBarGroups==null){
      makeGroups(appTheme);
    }
    return AspectRatio(
      aspectRatio: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                makeTransactionsIcon(appTheme),
                const SizedBox(
                  width: 38,
                ),
                const Text(
                  'Transactions',
                  style: TextStyle(fontSize: 22),
                ),
              ],
            ),
            const SizedBox(
              height: 38,
            ),
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: 20,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.grey,
                      getTooltipItem: (a, b, c, d) => null,
                    ),
                    touchCallback: (FlTouchEvent event, response) {
                      if (response == null || response.spot == null) {
                        setState(() {
                          touchedGroupIndex = -1;
                          showingBarGroups = List.of(rawBarGroups!);
                        });
                        return;
                      }

                      touchedGroupIndex = response.spot!.touchedBarGroupIndex;

                      setState(() {
                        if (!event.isInterestedForInteractions) {
                          touchedGroupIndex = -1;
                          showingBarGroups = List.of(rawBarGroups!);
                          return;
                        }
                        showingBarGroups = List.of(rawBarGroups!);
                        if (touchedGroupIndex != -1) {
                          var sum = 0.0;
                          for (final rod
                          in showingBarGroups[touchedGroupIndex].barRods) {
                            sum += rod.toY;
                          }
                          final avg = sum /
                              showingBarGroups[touchedGroupIndex]
                                  .barRods
                                  .length;

                          showingBarGroups[touchedGroupIndex] =
                              showingBarGroups[touchedGroupIndex].copyWith(
                                barRods: showingBarGroups[touchedGroupIndex]
                                    .barRods
                                    .map((rod) {
                                  return rod.copyWith(
                                      toY: avg, color: appTheme.color);
                                }).toList(),
                              );
                        }
                      });
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
                        getTitlesWidget: bottomTitles,
                        reservedSize: 42,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: leftTitles,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  barGroups: showingBarGroups,
                  gridData: const FlGridData(show: false),
                ),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
          ],
        ),
      ),
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff7589a2),
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    if (value == 0) {
      text = '1K';
    } else if (value == 10) {
      text = '5K';
    } else if (value == 19) {
      text = '10K';
    } else {
      return Container();
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 0,
      child: Text(text, style: style),
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    final titles = <String>['Mn', 'Te', 'Wd', 'Tu', 'Fr', 'St', 'Su'];

    final Widget text = Text(
      titles[value.toInt()],
      style: const TextStyle(
        color: Color(0xff7589a2),
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16, //margin top
      child: text,
    );
  }

  BarChartGroupData makeGroupData(AppTheme appTheme,int x, double y1, double y2) {
    return BarChartGroupData(
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: appTheme.color.darkest,
          width: width,
        ),
        BarChartRodData(
          toY: y2,
          color: appTheme.color.lightest,
          width: width,
        ),
      ],
    );
  }

  Widget makeTransactionsIcon(AppTheme appTheme) {
    const width = 4.5;
    const space = 3.5;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: width,
          height: 10,
          color: appTheme.color.lightest,
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 28,
          color: appTheme.color.lighter,
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 42,
          color:appTheme.color,
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 28,
          color: appTheme.color.lighter,
        ),
        const SizedBox(
          width: space,
        ),
        Container(
          width: width,
          height: 10,
          color:appTheme.color.lightest,
        ),
      ],
    );
  }
}