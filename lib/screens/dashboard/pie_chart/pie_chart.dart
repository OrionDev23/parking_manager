import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class ParcOtoPie extends StatefulWidget {
  final String? title;

  final List<MapEntry<String,Future<int>>> labels;
  const ParcOtoPie({super.key,required this.labels,this.title});

  @override
  State<ParcOtoPie> createState() => _ParcOtoPieState();
}

class _ParcOtoPieState extends State<ParcOtoPie> {



  List<MapEntry<String,int>> values=[];

  @override
  void initState() {
    initValues();
    super.initState();
  }

  bool loading=false;
  void initValues() async{
    loading=true;
    List<Future>tasks=[];
    for(int i=0;i<widget.labels.length;i++){
        tasks.add(getValue(i));
    }
    await Future.wait(tasks);
    sortAsIntended();
    setState(() {
      loading=false;
    });
  }

  Future<void> getValue(int index) async{
    values.add(MapEntry(widget.labels[index].key, await widget.labels[index].value));
  }


  void sortAsIntended(){
    List<MapEntry<String,int>> result=[];
    for(int i=0;i<widget.labels.length;i++){
        for(int j=0;j<values.length;j++){
          if(widget.labels[i].key==values[j].key){
            result.add(MapEntry(values[j].key, values[j].value));
            values.removeAt(j);
            break;
          }
        }
    }
    values.addAll(result);
  }
  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    if(loading){
      return const Center(child: ProgressRing());
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(widget.title!=null)
        Text(widget.title!,style:  TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: appTheme.writingStyle.color),),
        smallSpace,
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 140.px,
              height: 140.px,
              child: PieChart(
                  PieChartData(
                    sections: List.generate(values.length, (index) {
                      return PieChartSectionData(
                        value: double.parse(values[index].value.toDouble().toStringAsFixed(0)),
                        color: getRandomColor(index,appTheme),
                        title: values[index].value.toString(),
                        showTitle: true,
                      );
                    }),
                  ),
              ),
            ),
            smallSpace,
            SizedBox(
              width: 110.px,
              height: 25.px*values.length,
              child: Column(
                  children: List.generate(values.length, (index) {
                    return Padding(padding: const EdgeInsets.all(5),
                      child:Row(
                        children: [
                        Container(color: getRandomColor(index, appTheme),width: 20.px,height: 10.px,),
                        const SizedBox(width: 2,),
                        Text(values[index].key,style: tstyle.copyWith(fontSize: 8),).tr(),
                      ],),
                    );
                  })
              ),
            ),
          ],
        ),

      ],
    );
  }
  Color getRandomColor(int index,AppTheme appTheme){
    switch(index){
      case 0:return appTheme.color.lightest;
      case 1:return appTheme.color;
      case 2:return appTheme.color.darker;
      case 3:return appTheme.color.light;
      case 4:return appTheme.color.darkest;
      case 5:return appTheme.color.lighter;
      case 6:return appTheme.color.dark;
      default:return appTheme.color;
    }
  }
}
