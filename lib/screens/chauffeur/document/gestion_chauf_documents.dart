import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../theme.dart';
import '../../../widgets/button_container.dart';
import '../../../widgets/page_header.dart';
import 'chauf_document_form.dart';
import 'chauf_document_table.dart';
import 'chauf_document_tabs.dart';

class ChauffeurDocuments extends StatefulWidget {
  const ChauffeurDocuments({super.key});

  @override
  ChauffeurDocumentsState createState() => ChauffeurDocumentsState();
}

class ChauffeurDocumentsState extends State<ChauffeurDocuments> {
  final tstyle=TextStyle(
    fontSize: 10.sp,
  );



  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return ScaffoldPage(
      header: PageTitle(
        text: 'gestiondocument'.tr(),
        trailing: SizedBox(
            width: 15.w,
            height: 10.h,
            child: ButtonContainer(
              icon: FluentIcons.add,
              text: 'add'.tr(),
              showBottom: false,
              showCounter: false,
              action: () {
                final index = CDocumentTabsState.tabs.length + 1;
                final tab = generateTab(index);
                CDocumentTabsState.tabs.add(tab);
                CDocumentTabsState.currentIndex.value = index - 1;
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
                    child: const CDocumentTable()),
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
      text: Text('nouvdocument'.tr()),
      semanticLabel: 'nouvdocument'.tr(),
      icon: const Icon(FluentIcons.document),
      body: const CDocumentForm(),
      onClosed: () {
        CDocumentTabsState.tabs.remove(tab);

        if (CDocumentTabsState.currentIndex.value > 0) {
          CDocumentTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }
}
