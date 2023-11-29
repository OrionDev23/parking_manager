import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../../theme.dart';
import '../../../../widgets/page_header.dart';
import 'disponibilite_table.dart';

class DisponibiliteGestion extends StatefulWidget {
  const DisponibiliteGestion({super.key,});

  @override
  DisponibiliteGestionState createState() => DisponibiliteGestionState();
}

class DisponibiliteGestionState extends State<DisponibiliteGestion> {
  final tstyle=TextStyle(
    fontSize: 10.sp,
  );



  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return ScaffoldPage(
      header: PageTitle(
        text: 'disponibilite'.tr(),
      ),
      content: Row(
        children: [
          SizedBox(
              width:60.w,
              child: const DisponibliteTable()),
          const SizedBox(width: 10,),
          Flexible(
            child: Column(
              children: [
                SizedBox(
                  height:20.h,
                  child: PieChart(
                      PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: 120,
                              color: appTheme.color.darkest,
                            ),
                            PieChartSectionData(
                              value: 60,
                              color: appTheme.color,
                            ),
                            PieChartSectionData(
                              value: 180,
                              color: appTheme.color.lightest,
                            ),
                          ]
                      )
                  ),
                ),
                const SizedBox(height: 10,),

              ],

            ),
          ),
          const SizedBox(width: 10,),
          Flexible(child: Column(
            children: [
              SizedBox(height: 10.h,),
              Row(children: [
                Container(color: appTheme.color.darkest,width: 2.w,height: 1.w,),
                const SizedBox(width: 5,),
                Text('Bon état',style: tstyle,),
              ],),
              const SizedBox(height: 5,),
              Row(children: [
                Container(color: appTheme.color,width: 2.w,height: 1.w,),
                const SizedBox(width: 5,),
                Text('En panne',style: tstyle,),
              ],),
              const SizedBox(height: 5,),
              Row(children: [
                Container(color: appTheme.color,width: 2.w,height: 1.w,),
                const SizedBox(width: 5,),
                Text('En réparation',style: tstyle,),
              ],),
            ],
          )),
          const SizedBox(width: 10,),
        ],
      ),
    );
  }
}
