import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/chauffeur/chauffeur_form.dart';
import 'package:parc_oto/screens/chauffeur/chauffeur_table.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../theme.dart';
import '../../../widgets/button_container.dart';
import '../../../widgets/page_header.dart';
import 'chauffeur_tabs.dart';

class ChauffeurGestion extends StatefulWidget {
  const ChauffeurGestion({super.key});

  @override
  ChauffeurGestionsState createState() => ChauffeurGestionsState();
}

class ChauffeurGestionsState extends State<ChauffeurGestion> {
  final tstyle=TextStyle(
    fontSize: 10.sp,
  );



  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return ScaffoldPage(
      header: PageTitle(
        text: 'gestionchauf'.tr(),
        trailing: SizedBox(
            width: 15.w,
            height: 10.h,
            child: ButtonContainer(
              icon: FluentIcons.add,
              text: 'add'.tr(),
              showBottom: false,
              showCounter: false,
              action: () {
                final index = ChauffeurTabsState.tabs.length + 1;
                final tab = generateTab(index);
                ChauffeurTabsState.tabs.add(tab);
                ChauffeurTabsState.currentIndex.value = index - 1;
              },
            )),
      ),
      content: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5.0,horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(icon: const Icon(FluentIcons.filter), onPressed: (){}),
                const SizedBox(width: 10,),

                SizedBox(
                  width: 30.w,
                  height: 7.h,
                  child: TextBox(
                    placeholder: 'search'.tr(),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Row(
              children: [
                SizedBox(
                    width:60.w,
                    child: const ChauffeurTable()),
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
          ),
        ],
      ),
    );
  }

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvchauf'.tr()),
      semanticLabel: 'nouvchauf'.tr(),
      icon: const Icon(FluentIcons.document),
      body: ChauffeurForm(),
      onClosed: () {
        ChauffeurTabsState.tabs.remove(tab);

        if (ChauffeurTabsState.currentIndex.value > 0) {
          ChauffeurTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }
}
