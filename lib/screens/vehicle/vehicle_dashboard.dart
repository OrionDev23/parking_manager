import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../../providers/client_database.dart';
import '../dashboard/pie_chart/pie_chart.dart';
import '../logs/logging/log_table.dart';
import 'documents/document_form.dart';
import 'documents/document_tabs.dart';
import 'states/state_form.dart';
import 'states/state_manager.dart';
import '../../widgets/button_container.dart';
import '../../widgets/page_header.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../theme.dart';
import '../sidemenu/pane_items.dart';
import '../sidemenu/sidemenu.dart';
import 'manager/vehicle_form.dart';
import 'manager/vehicle_tabs.dart';

class VehicleDashboard extends StatelessWidget {
  const VehicleDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
      padding: const EdgeInsets.all(10),
      header: PageTitle(
        text: 'vehicules'.tr(),
      ),
      content: Column(
        children: [
          Flexible(
            child: GridView.count(
              padding: const EdgeInsets.all(10),
              childAspectRatio: 8.5,
              crossAxisCount: 2,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              children: [
                ButtonContainer(
                  color:appTheme.color.darkest,
                  action: (){
                    PanesListState.index.value=PaneItemsAndFooters.originalItems.indexOf(PaneItemsAndFooters.vehicles)+1;
                  },
                  icon: FluentIcons.task_manager,
                  text: 'gestionvehicles'.tr(),
                  showBothLN: false,
                  showBottom: false,
                  showCounter: false,),
                ButtonContainer(
                  action: () {
                    PanesListState.index.value=PaneItemsAndFooters.originalItems.indexOf(PaneItemsAndFooters.vehicles)+1;
                    Future.delayed(const Duration(milliseconds: 300)).whenComplete(() {
                      late Tab tab;
                      tab = Tab(
                        key: UniqueKey(),
                        text: Text('nouvvehicule'.tr()),
                        semanticLabel: 'nouvvehicule'.tr(),
                        icon: const Icon(FluentIcons.new_folder),
                        body: const VehicleForm(),
                        onClosed: () {
                          VehicleTabsState.tabs.remove(tab);

                          if (VehicleTabsState.currentIndex.value > 0) {
                            VehicleTabsState.currentIndex.value--;
                          }
                        },
                      );
                      final index = VehicleTabsState.tabs.length + 1;
                      VehicleTabsState.tabs.add(tab);
                      VehicleTabsState.currentIndex.value = index - 1;
                    });
                  },
                  color:appTheme.color.darker,icon: FluentIcons.car, text: 'nouvvehicule'.tr(),showBothLN: false,showBottom: false,showCounter: false,),
                ButtonContainer(
                  action: (){
                    PanesListState.index.value=PaneItemsAndFooters.originalItems.indexOf(PaneItemsAndFooters.vehicles)+2;
                  },
                  color:appTheme.color.dark,icon: FluentIcons.verified_brand, text: 'brands'.tr(),showBothLN: false,showBottom: false,showCounter: false,),
                ButtonContainer(
                  action: (){
                    PanesListState.index.value=PaneItemsAndFooters.originalItems.indexOf(PaneItemsAndFooters.vehicles)+3;
                  },
                  color:appTheme.color,icon: FluentIcons.sync_status, text: 'vstates'.tr(),showBothLN: false,showBottom: false,showCounter: false,),
                ButtonContainer(
                  action: () {
                    PanesListState.index.value=PaneItemsAndFooters.originalItems.indexOf(PaneItemsAndFooters.vehicles)+3;
                    Future.delayed(const Duration(milliseconds: 300)).whenComplete(() {
                      showDialog(
                            context: EtatManagerState.current!,
                          barrierDismissible: true,
                          builder: (c){
                            return ContentDialog(
                              title: const Text("nouvetat").tr(),
                              constraints: BoxConstraints.loose(Size(
                                  800.px,500.px
                              )),
                              content: const StateForm(),
                            );
                          });
                  },);
                    },
                  color:appTheme.color.light,icon: FluentIcons.update_restore, text: 'nouvetat'.tr(),showBothLN: false,showBottom: false,showCounter: false,),
                ButtonContainer(
                  action: (){
                    PanesListState.index.value=PaneItemsAndFooters.originalItems.indexOf(PaneItemsAndFooters.vehicles)+4;
                  },
                  color:appTheme.color.lighter,icon: FluentIcons.document_set, text: 'documents'.tr(),showBothLN: false,showBottom: false,showCounter: false,),
                ButtonContainer(
                  action: () {
                    PanesListState.index.value=PaneItemsAndFooters.originalItems.indexOf(PaneItemsAndFooters.vehicles)+4;
                    Future.delayed(const Duration(milliseconds: 300)).whenComplete(() {
                      late Tab tab;
                      tab = Tab(
                        key: UniqueKey(),
                        text: Text('nouvdocument'.tr()),
                        semanticLabel: 'nouvdocument'.tr(),
                        icon: const Icon(FluentIcons.new_folder),
                        body: const DocumentForm(),
                        onClosed: () {
                          DocumentTabsState.tabs.remove(tab);

                          if (DocumentTabsState.currentIndex.value > 0) {
                            DocumentTabsState.currentIndex.value--;
                          }
                        },
                      );
                      final index = DocumentTabsState.tabs.length + 1;
                      DocumentTabsState.tabs.add(tab);
                      DocumentTabsState.currentIndex.value = index - 1;
                    });
                  },
                  color:appTheme.color.lightest,icon: FluentIcons.document, text: 'nouvdocument'.tr(),showBothLN: false,showBottom: false,showCounter: false,),
              ],
            ),
          ),
          smallSpace,
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Column(
                      children: [
                        Text('lactivities',style:  TextStyle(fontSize: 16,fontWeight: FontWeight.bold,color: appTheme.writingStyle.color),).tr(),
                        smallSpace,
                        const Flexible(
                          child: LogTable(
                            statTable: true,
                            numberOfRows: 3,
                            filters: {
                              'typemin':'0',
                              'typemax':'9'
                            },

                            fieldsToShow: [
                              'act','id','date'
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  smallSpace,
                  ParcOtoPie(
                    title: 'vstates'.tr(),
                    labels: [
                      MapEntry('gstate', ClientDatabase().countVehicles(etat: 0)),
                      MapEntry('bstate', ClientDatabase().countVehicles(etat: 1)),
                      MapEntry('rstate', ClientDatabase().countVehicles(etat: 2))
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
