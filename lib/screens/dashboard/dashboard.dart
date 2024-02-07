import 'package:appwrite/appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:parc_oto/screens/chauffeur/manager/chauffeur_form.dart';
import 'package:parc_oto/screens/chauffeur/manager/chauffeur_tabs.dart';
import 'package:parc_oto/screens/dashboard/charts/state_bars_vertical.dart';
import 'package:parc_oto/screens/dashboard/charts/state_category_bar.dart';
import 'package:parc_oto/screens/entreprise/entreprise.dart';
import 'package:parc_oto/screens/logs/logging/log_table.dart';
import 'package:parc_oto/screens/sidemenu/sidemenu.dart';
import 'package:parc_oto/utilities/vehicle_util.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'pie_chart/pie_chart.dart';

import '../../providers/counters.dart';
import '../../theme.dart';
import '../../widgets/button_container.dart';
import '../../widgets/page_header.dart';
import '../chauffeur/document/chauf_document_form.dart';
import '../chauffeur/document/chauf_document_tabs.dart';
import '../prestataire/prestataire_form.dart';
import '../prestataire/prestataire_tabs.dart';
import '../reparation/manager/reparation_tabs.dart';
import '../reparation/reparation_form/reparation_form.dart';
import '../sidemenu/pane_items.dart';
import '../vehicle/documents/document_form.dart';
import '../vehicle/documents/document_tabs.dart';
import '../vehicle/manager/vehicle_form.dart';
import '../vehicle/manager/vehicle_tabs.dart';
import 'charts/state_bars.dart';
import 'costs/costs_graph.dart';
import 'table_stats.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    bool portrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return ScaffoldPage(
      header: const PageTitle(text: 'home'),
      content: ListView(
        padding: const EdgeInsets.all(5),
        children: [
          StaggeredGrid.count(
            crossAxisCount:
                MediaQuery.of(context).orientation == Orientation.portrait
                    ? 2
                    : 4,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            children: buttonList(appTheme),
          ),
          StaggeredGrid.count(
            crossAxisCount:
                MediaQuery.of(context).orientation == Orientation.portrait
                    ? 1
                    : 2,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            children: widgetList(appTheme),
          ),
        ],
      ),
    );
  }

  List<Widget> buttonList(AppTheme appTheme) {
    return [
      ButtonContainer(
        icon: FluentIcons.car,
        text: 'vehicules'.tr(),
        getCount: DatabaseCounters().countVehicles,
        action: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
              .indexOf(PaneItemsAndFooters.vehicles);
        },
        actionList: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.vehicles) +
              1;
        },
        actionNouveau: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.vehicles) +
              1;
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
      ),
      ButtonContainer(
        icon: FluentIcons.document_set,
        text: 'vehicledocuments'.tr(),
        getCount: DatabaseCounters().countVdocs,
        action: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.vehicles) +
              4;
        },
        actionList: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.vehicles) +
              4;
        },
        actionNouveau: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.vehicles) +
              4;
          Future.delayed(const Duration(milliseconds: 300)).whenComplete(() {
            late Tab tab;
            tab = Tab(
              key: UniqueKey(),
              text: Text('nouvdocument'.tr()),
              semanticLabel: 'nouvdocument'.tr(),
              icon: const Icon(FluentIcons.new_folder),
              body: const ScaffoldPage(
                content: DocumentForm(),
              ),
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
        getCount: DatabaseCounters().countReparation,
        action: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.reparations) +
              4;
        },
        actionList: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.reparations) +
              5;
        },
        actionNouveau: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.reparations) +
              5;
          Future.delayed(const Duration(milliseconds: 300)).whenComplete(() {
            late Tab tab;
            tab = Tab(
              key: UniqueKey(),
              text: Text('nouvrepar'.tr()),
              semanticLabel: 'nouvrepar'.tr(),
              icon: const Icon(FluentIcons.document),
              body: ReparationForm(
                key: UniqueKey(),
              ),
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
        text: 'prestataires'.tr(),
        getCount: DatabaseCounters().countPrestataire,
        action: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.reparations) +
              6;
        },
        actionList: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.reparations) +
              6;
        },
        actionNouveau: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.reparations) +
              6;
          Future.delayed(const Duration(milliseconds: 300)).whenComplete(() {
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
        getCount: DatabaseCounters().countChauffeur,
        action: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.chauffeurs) +
              6;
        },
        actionList: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.chauffeurs) +
              7;
        },
        actionNouveau: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.chauffeurs) +
              7;
          Future.delayed(const Duration(milliseconds: 300)).whenComplete(() {
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
        icon: FluentIcons.document_set,
        text: 'chaufdocuments'.tr(),
        getCount: DatabaseCounters().countCDocs,
        action: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.chauffeurs) +
              9;
        },
        actionList: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.chauffeurs) +
              9;
        },
        actionNouveau: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.chauffeurs) +
              9;
          Future.delayed(const Duration(milliseconds: 300)).whenComplete(() {
            late Tab tab;
            tab = Tab(
              key: UniqueKey(),
              text: Text('nouvdocument'.tr()),
              semanticLabel: 'nouvdocument'.tr(),
              icon: const Icon(FluentIcons.new_folder),
              body: const ScaffoldPage(
                content: CDocumentForm(),
              ),
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
      ),
      ButtonContainer(
        icon: FluentIcons.edit_event,
        text: 'reservation'.tr(),
        getCount: DatabaseCounters().countReservation,
        action: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.planner) +
              10;
        },
        showBothLN: false,
        actionList: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.planner) +
              10;
        },
      ),
      ButtonContainer(
        icon: FluentIcons.database_activity,
        text: 'activities'.tr(),
        getCount: DatabaseCounters().countLog,
        action: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.evenements) +
              10;
        },
        showBothLN: false,
        actionList: () {
          PanesListState.index.value = PaneItemsAndFooters.originalItems
                  .indexOf(PaneItemsAndFooters.evenements) +
              10;
        },
      ),
    ];
  }

  List<Widget> widgetList(AppTheme appTheme) {
    DateTime start = DateTime.now().subtract(const Duration(days: 30 * 6));
    DateTime end = DateTime.now();

    double height = 400.px;

    return [
      StaggeredGridTile.fit(
        crossAxisCellCount: 1,
        child: TableStats(
          height: height,
          title: 'vstates'.tr(),
          icon: Icon(
            FluentIcons.car,
            color: appTheme.color.darker,
          ),
          content: StateBars(
            labels: [
              MapEntry('gstate', DatabaseCounters().countVehicles(etat: 0)),
              MapEntry('bstate', DatabaseCounters().countVehicles(etat: 1)),
              MapEntry('rstate', DatabaseCounters().countVehicles(etat: 2)),
              MapEntry('ostate', DatabaseCounters().countVehicles(etat: 3)),
              MapEntry('restate', DatabaseCounters().countVehicles(etat: 4)),
            ],
          ),
          onTap: () {
            PanesListState.index.value = PaneItemsAndFooters.originalItems
                    .indexOf(PaneItemsAndFooters.vehicles) +
                1;
          },
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 1,
        child: TableStats(
          height: height,
          title: 'appartenance'.tr(),
          icon: Icon(
            FluentIcons.car,
            color: appTheme.color.darker,
          ),
          content: ParcOtoPie(
            labels: List.generate(MyEntrepriseState.p!.filiales?.length??0,
                    (index) => MapEntry(MyEntrepriseState.p!
                    .filiales![index], DatabaseCounters().countVehiclesWithCondition([
                  Query.search('appartenance', '"${MyEntrepriseState.p!
                      .filiales![index].trim()}"')
                ]))),
            radius: 100,
          ),
          onTap: () {
            PanesListState.index.value = PaneItemsAndFooters.originalItems
                .indexOf(PaneItemsAndFooters.vehicles) +
                1;
          },
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: TableStats(
          height: height,
          title: 'vstates'.tr(),
          icon: Icon(
            FluentIcons.car,
            color: appTheme.color.darker,
          ),
          content: StateCategoryBars(
            labels: List.generate(3, (index) => MapEntry(VehiclesUtilities.getPerimetre(index),[
              MapEntry('gstate', DatabaseCounters().countVehiclesWithCondition([
                Query.equal('etatactuel', 0),
                Query.equal('perimetre', index)
              ])),
              MapEntry('bstate', DatabaseCounters().countVehiclesWithCondition([
                Query.equal('etatactuel', 1),
                Query.equal('perimetre', index)
              ])),
              MapEntry('rstate', DatabaseCounters().countVehiclesWithCondition([
                Query.equal('etatactuel', 2),
                Query.equal('perimetre', index)
              ])),
              MapEntry('ostate', DatabaseCounters().countVehiclesWithCondition([
                Query.equal('etatactuel', 3),
                Query.equal('perimetre', index)
              ])),
              MapEntry('restate', DatabaseCounters().countVehiclesWithCondition([
                Query.equal('etatactuel', 4),
                Query.equal('perimetre', index)
              ])),
            ],)),
          ),
          onTap: () {
            PanesListState.index.value = PaneItemsAndFooters.originalItems
                .indexOf(PaneItemsAndFooters.vehicles) +
                1;
          },
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 1,
        child: TableStats(
          height: height*2,
          title: 'appartenance'.tr(),
          icon: Icon(
            FluentIcons.car,
            color: appTheme.color.darker,
          ),
          content: StateBarsVertical(
            labels: List.generate(MyEntrepriseState.p!.filiales?.length??0,
                    (index) => MapEntry(MyEntrepriseState.p!
                        .filiales![index], DatabaseCounters().countVehiclesWithCondition([
                      Query.search('appartenance', MyEntrepriseState.p!
                          .filiales![index])
                    ]))),
          ),
          onTap: () {
            PanesListState.index.value = PaneItemsAndFooters.originalItems
                .indexOf(PaneItemsAndFooters.vehicles) +
                1;
          },
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 1,
        child: TableStats(
          height: height,
          title: 'vehicules'.tr(),
          icon: Icon(
            FluentIcons.car,
            color: appTheme.color.darker,
          ),
          content: const LogTable(
            pages: false,
            fieldsToShow: [
              'act',
              'id',
              'date',
            ],
            filters: {'typemin': '0', 'typemax': '9'},
            statTable: true,
            numberOfRows: 5,
          ),
          onTap: () {
            PanesListState.index.value = PaneItemsAndFooters.originalItems
                    .indexOf(PaneItemsAndFooters.vehicles) +
                1;
          },
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 1,
        child: TableStats(
          height: height,
          title: 'depenses'.tr(),
          icon: Icon(
            FluentIcons.cost_control,
            color: appTheme.color.darker,
          ),
          content: CostGraph(
            start: start,
            end: end,
            appTheme: appTheme,
          ),
          onTap: () {
            PanesListState.index.value = PaneItemsAndFooters.originalItems
                    .indexOf(PaneItemsAndFooters.reparations) +
                5;
          },
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 1,
        child: TableStats(
          height: height,
          title: 'reparations'.tr(),
          icon: Icon(
            FluentIcons.repair,
            color: appTheme.color.darker,
          ),
          content: const LogTable(
            pages: false,
            fieldsToShow: [
              'act',
              'id',
              'date',
            ],
            filters: {'typemin': '10', 'typemax': '15'},
            statTable: true,
            numberOfRows: 5,
          ),
          onTap: () {
            PanesListState.index.value = PaneItemsAndFooters.originalItems
                    .indexOf(PaneItemsAndFooters.reparations) +
                5;
          },
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 1,
        child: TableStats(
          height: height,
          title: 'chauffeurs'.tr(),
          icon: Icon(
            FluentIcons.people,
            color: appTheme.color.darker,
          ),
          content: const LogTable(
            pages: false,
            fieldsToShow: [
              'act',
              'id',
              'date',
            ],
            filters: {'typemin': '16', 'typemax': '25'},
            statTable: true,
            numberOfRows: 5,
          ),
          onTap: () {
            PanesListState.index.value = PaneItemsAndFooters.originalItems
                    .indexOf(PaneItemsAndFooters.chauffeurs) +
                7;
          },
        ),
      ),
    ];
  }
}
