import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../providers/counters.dart';
import '../dashboard/pie_chart/pie_chart.dart';
import '../logs/logging/log_table.dart';
import 'document/chauf_document_form.dart';
import 'document/chauf_document_tabs.dart';
import 'manager/chauffeur_form.dart';
import 'manager/chauffeur_tabs.dart';
import '../../widgets/button_container.dart';
import '../../widgets/page_header.dart';
import 'package:provider/provider.dart';
import '../../theme.dart';
import '../sidemenu/pane_items.dart';
import '../sidemenu/sidemenu.dart';

class ConducteurDashboard extends StatelessWidget {
  const ConducteurDashboard({super.key});

  final int indexAdition=6;

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
      padding: const EdgeInsets.all(10),
      header: PageTitle(
        text: 'chauffeurs'.tr(),
      ),
      content: Column(
        children: [
          Flexible(
            flex: 3,
            child: GridView.count(
              padding: const EdgeInsets.all(10),
              childAspectRatio: kIsWeb?5:4,
              crossAxisCount: Device.orientation==Orientation.portrait ?2:3,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              children: [
                ButtonContainer(
                  color:appTheme.color,
                  action: (){
                    PanesListState.index.value=PaneItemsAndFooters.originalItems.indexOf(PaneItemsAndFooters.chauffeurs)+1+indexAdition;
                  },
                  icon: FluentIcons.list,
                  text: 'gchauffeurs'.tr(),
                  showBothLN: false,
                  showBottom: false,
                  showCounter: false,),
                ButtonContainer(
                  action: () {
                    PanesListState.index.value=PaneItemsAndFooters.originalItems.indexOf(PaneItemsAndFooters.chauffeurs)+1+indexAdition;
                    Future.delayed(const Duration(milliseconds: 300)).whenComplete(() {
                      late Tab tab;
                      tab = Tab(
                        key: UniqueKey(),
                        text: Text('nouvchauf'.tr()),
                        semanticLabel: 'nouvchauf'.tr(),
                        icon: const Icon(FluentIcons.add_friend),
                        body: const ChauffeurForm(),
                        onClosed: () {
                          ChauffeurTabsState.tabs.remove(tab);

                          if (ChauffeurTabsState.currentIndex.value > 0) {
                            ChauffeurTabsState.currentIndex.value--;
                          }
                        },
                      );
                      final index = ChauffeurTabsState.tabs.length + 1;
                      ChauffeurTabsState.tabs.add(tab);
                      ChauffeurTabsState.currentIndex.value = index - 1;
                    });
                  },
                  color:appTheme.color,icon: FluentIcons.car, text: 'nouvchauf'.tr(),showBothLN: false,showBottom: false,showCounter: false,),
                ButtonContainer(
                  action: (){
                    PanesListState.index.value=PaneItemsAndFooters.originalItems.indexOf(PaneItemsAndFooters.chauffeurs)+2+indexAdition;
                  },
                  color:appTheme.color,icon: FluentIcons.health, text: 'disponibilite'.tr(),showBothLN: false,showBottom: false,showCounter: false,),
                ButtonContainer(
                  action: (){
                    PanesListState.index.value=PaneItemsAndFooters.originalItems.indexOf(PaneItemsAndFooters.chauffeurs)+3+indexAdition;
                  },
                  color:appTheme.color,icon: FluentIcons.document_set, text: 'documents'.tr(),showBothLN: false,showBottom: false,showCounter: false,),
                ButtonContainer(
                  action: () {
                    PanesListState.index.value=PaneItemsAndFooters.originalItems.indexOf(PaneItemsAndFooters.chauffeurs)+3+indexAdition;
                    Future.delayed(const Duration(milliseconds: 400)).whenComplete(() {
                      late Tab tab;
                      tab = Tab(
                        key: UniqueKey(),
                        text: Text('nouvdocument'.tr()),
                        semanticLabel: 'nouvdocument'.tr(),
                        icon: const Icon(FluentIcons.new_folder),
                        body: const CDocumentForm(),
                        onClosed: () {
                          CDocumentTabsState.tabs.remove(tab);

                          if (CDocumentTabsState.currentIndex.value > 0) {
                            CDocumentTabsState.currentIndex.value--;
                          }
                        },
                      );
                      final index = CDocumentTabsState.tabs.length + 1;
                      CDocumentTabsState.tabs.add(tab);
                      CDocumentTabsState.currentIndex.value = index - 1;
                    });
                  },
                  color:appTheme.color,icon: FluentIcons.document, text: 'nouvdocument'.tr(),showBothLN: false,showBottom: false,showCounter: false,),
                ButtonContainer(
                  color:appTheme.color,
                  action: (){
                    PanesListState.index.value=PaneItemsAndFooters.originalItems.indexOf(PaneItemsAndFooters.chauffeurs)+4+indexAdition;
                  },
                  icon: FluentIcons.list,
                  text: 'archive'.tr(),
                  showBothLN: false,
                  showBottom: false,
                  showCounter: false,),

              ],
            ),
          ),
          smallSpace,
          Flexible(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Column(
                      children: [
                        Text('lactivities',style:  TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: appTheme.writingStyle.color),).tr(),
                        smallSpace,
                        const Flexible(
                          child: LogTable(
                            statTable: true,
                            pages: false,
                            numberOfRows: 3,
                            filters: {
                              'typemin':'16',
                              'typemax':'25'
                            },
                            fieldsToShow: [
                              'act','date'
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  smallSpace,
                  ParcOtoPie(
                    radius: kIsWeb?90:120,
                    title: 'disponibilite'.tr(),
                    labels: [
                      MapEntry('disponible', DatabaseCounters().countChauffeur(etat: 0)),
                      MapEntry('absent', DatabaseCounters().countChauffeur(etat: 1)),
                      MapEntry('mission', DatabaseCounters().countChauffeur(etat: 2)),
                      MapEntry('quitteentre', DatabaseCounters().countChauffeur(etat: 3))
                    ],
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
