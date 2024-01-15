import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/screens/chauffeur/manager/chauffeur_tabs.dart';
import 'package:parc_oto/screens/chauffeur/manager/chauffeur_form.dart';
import 'package:parc_oto/screens/sidemenu/sidemenu.dart';
import '../../theme.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../widgets/button_container.dart';
import '../../widgets/page_header.dart';
import '../prestataire/prestataire_form.dart';
import '../prestataire/prestataire_tabs.dart';
import '../reparation/manager/reparation_tabs.dart';
import '../reparation/reparation_form/reparation_form.dart';
import '../sidemenu/pane_items.dart';
import '../vehicle/documents/document_form.dart';
import '../vehicle/documents/document_tabs.dart';
import '../vehicle/manager/vehicle_form.dart';
import '../vehicle/manager/vehicle_tabs.dart';
import 'transaction_chart.dart';
import 'table_stats.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();

    return ScaffoldPage(
      header: const PageTitle(text: 'home'),
      content: ListView(
        padding: const EdgeInsets.all(5),
        children: [
          SizedBox(
            height: 400.px,
            child: GridView.count(
              primary: false,
              shrinkWrap: true,
              padding: const EdgeInsets.all(10),
              childAspectRatio: 3,
              crossAxisCount: 4,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              children: [
                ButtonContainer(
                  icon: FluentIcons.car,
                  text: 'vehicules'.tr(),
                  getCount: ClientDatabase().countVehicles,
                  action: () {
                    PanesListState.index.value = PaneItemsAndFooters
                            .originalItems
                            .indexOf(PaneItemsAndFooters.vehicles);
                  },
                  actionList: () {
                    PanesListState.index.value = PaneItemsAndFooters
                            .originalItems
                            .indexOf(PaneItemsAndFooters.vehicles) +
                        1;
                  },
                  actionNouveau: () {
                    PanesListState.index.value = PaneItemsAndFooters
                            .originalItems
                            .indexOf(PaneItemsAndFooters.vehicles) +
                        1;
                    Future.delayed(const Duration(milliseconds: 300))
                        .whenComplete(() {
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
                ),
                ButtonContainer(
                  icon: FluentIcons.document_set,
                  text: 'vehicledocuments'.tr(),
                  getCount: ClientDatabase().countVdocs,
                  action: () {
                    PanesListState.index.value = PaneItemsAndFooters
                            .originalItems
                            .indexOf(PaneItemsAndFooters.vehicles)+4;
                  },
                  actionList: () {
                    PanesListState.index.value = PaneItemsAndFooters
                            .originalItems
                            .indexOf(PaneItemsAndFooters.vehicles) +
                        4;
                  },
                  actionNouveau: () {
                    PanesListState.index.value = PaneItemsAndFooters
                            .originalItems
                            .indexOf(PaneItemsAndFooters.vehicles) +
                        4;
                    Future.delayed(const Duration(milliseconds: 300))
                        .whenComplete(() {
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
                ),
                ButtonContainer(
                  icon: FluentIcons.repair,
                  text: 'reparations'.tr(),
                  getCount: ClientDatabase().countReparation,
                  action: () {
                    PanesListState.index.value = PaneItemsAndFooters
                        .originalItems
                        .indexOf(PaneItemsAndFooters.reparations) +
                        5;
                  },
                  actionList: () {
                    PanesListState.index.value = PaneItemsAndFooters
                        .originalItems
                        .indexOf(PaneItemsAndFooters.vehicles) +
                        6;
                  },
                  actionNouveau: () {
                    PanesListState.index.value = PaneItemsAndFooters
                        .originalItems
                        .indexOf(PaneItemsAndFooters.vehicles) +
                        6;
                    Future.delayed(const Duration(milliseconds: 300))
                        .whenComplete(() {
                      late Tab tab;
                      tab = Tab(
                        key: UniqueKey(),
                        text: Text('nouvrepar'.tr()),
                        semanticLabel: 'nouvrepar'.tr(),
                        icon: const Icon(FluentIcons.document),
                        body: ReparationForm(key: UniqueKey(),),
                        onClosed: () {
                          ReparationTabsState.tabs.remove(tab);

                          if (ReparationTabsState.currentIndex.value > 0) {
                            ReparationTabsState.currentIndex.value--;
                          }
                        },
                      );
                      final index = ReparationTabsState.tabs.length + 1;
                      ReparationTabsState.tabs.add(tab);
                      ReparationTabsState.currentIndex.value = index - 1;
                    });
                  },
                ),
                ButtonContainer(
                  icon: FluentIcons.service_activity,
                  text: 'Prestataires'.tr(),
                  getCount: ClientDatabase().countPrestataire,
                  action: () {
                    PanesListState.index.value = PaneItemsAndFooters
                        .originalItems
                        .indexOf(PaneItemsAndFooters.reparations) +
                        7;
                  },
                  actionList: () {
                    PanesListState.index.value = PaneItemsAndFooters
                        .originalItems
                        .indexOf(PaneItemsAndFooters.vehicles) +
                        7;
                  },
                  actionNouveau: () {
                    PanesListState.index.value = PaneItemsAndFooters
                        .originalItems
                        .indexOf(PaneItemsAndFooters.vehicles) +
                        7;
                    Future.delayed(const Duration(milliseconds: 300))
                        .whenComplete(() {
                      late Tab tab;
                      tab = Tab(
                        key: UniqueKey(),
                        text: Text('nouvprest'.tr()),
                        semanticLabel: 'nouvprest'.tr(),
                        icon: const Icon(FluentIcons.document),
                        body: const PrestataireForm(),
                        onClosed: () {
                          PrestataireTabsState.tabs.remove(tab);

                          if (PrestataireTabsState.currentIndex.value > 0) {
                            PrestataireTabsState.currentIndex.value--;
                          }
                        },
                      );
                      final index = PrestataireTabsState.tabs.length + 1;
                      PrestataireTabsState.tabs.add(tab);
                      PrestataireTabsState.currentIndex.value = index - 1;
                    });
                  },
                ),
                ButtonContainer(
                  icon: FluentIcons.people,
                  text: 'chauffeurs'.tr(),
                  getCount: ClientDatabase().countChauffeur,
                  action: () {
                    PanesListState.index.value = PaneItemsAndFooters
                            .originalItems
                            .indexOf(PaneItemsAndFooters.chauffeurs) +
                        1;
                  },
                  actionList: () {
                    PanesListState.index.value = PaneItemsAndFooters
                            .originalItems
                            .indexOf(PaneItemsAndFooters.chauffeurs) +
                        1;
                  },
                  actionNouveau: () {
                    PanesListState.index.value = PaneItemsAndFooters
                            .originalItems
                            .indexOf(PaneItemsAndFooters.chauffeurs) +
                        1;
                    Future.delayed(const Duration(milliseconds: 300))
                        .whenComplete(() {
                      late Tab tab;
                      tab = Tab(
                        key: UniqueKey(),
                        text: Text('nouvchauf'.tr()),
                        semanticLabel: 'nouvchauf'.tr(),
                        icon: const Icon(FluentIcons.people_add),
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
                ),
                ButtonContainer(
                  icon: FluentIcons.people,
                  text: 'chaufdocuments'.tr(),
                  getCount: ClientDatabase().countCDocs,
                  action: () {
                    PanesListState.index.value = PaneItemsAndFooters
                            .originalItems
                            .indexOf(PaneItemsAndFooters.chauffeurs) +
                        1;
                  },
                  actionList: () {
                    PanesListState.index.value = PaneItemsAndFooters
                            .originalItems
                            .indexOf(PaneItemsAndFooters.chauffeurs) +
                        1;
                  },
                  actionNouveau: () {
                    PanesListState.index.value = PaneItemsAndFooters
                            .originalItems
                            .indexOf(PaneItemsAndFooters.chauffeurs) +
                        1;
                    Future.delayed(const Duration(milliseconds: 300))
                        .whenComplete(() {
                      late Tab tab;
                      tab = Tab(
                        key: UniqueKey(),
                        text: Text('nouvchauf'.tr()),
                        semanticLabel: 'nouvchauf'.tr(),
                        icon: const Icon(FluentIcons.people_add),
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
                ),
                ButtonContainer(
                  icon: FluentIcons.edit_event,
                  text: 'reservation'.tr(),
                  getCount: ClientDatabase().countReservation,
                  action: () {
                    PanesListState.index.value = PaneItemsAndFooters
                        .originalItems
                        .indexOf(PaneItemsAndFooters.planner) +10;
                  },
                  showBothLN: false,
                  actionList: () {
                    PanesListState.index.value = PaneItemsAndFooters
                        .originalItems
                        .indexOf(PaneItemsAndFooters.planner) +10;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: TableStats(),
                ),
                const SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                          boxShadow: kElevationToShadow[2],
                          borderRadius: BorderRadius.circular(5),
                          color: appTheme.mode == ThemeMode.dark
                              ? Colors.grey
                              : appTheme.mode == ThemeMode.light
                                  ? Colors.white
                                  : ThemeMode.system == ThemeMode.light
                                      ? Colors.white
                                      : Colors.grey),
                      height: 50.h,
                      child: const TransactionChart()),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TableStats(),
                ),
                SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: TableStats(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
