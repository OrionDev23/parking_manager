import 'package:appwrite/appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/providers/driver_provider.dart';
import 'package:parc_oto/providers/log_provider.dart';
import 'package:parc_oto/providers/planning_provider.dart';
import 'package:parc_oto/providers/repair_provider.dart';
import 'package:parc_oto/providers/vehicle_provider.dart';
import 'package:parc_oto/screens/chauffeur/manager/chauffeur_form.dart';
import 'package:parc_oto/screens/chauffeur/manager/chauffeur_tabs.dart';
import 'package:parc_oto/screens/dashboard/charts/state_category_bar.dart';
import 'package:parc_oto/screens/entreprise/entreprise.dart';
import 'package:parc_oto/screens/logs/logging/log_table.dart';
import 'package:parc_oto/screens/sidemenu/sidemenu.dart';
import 'package:parc_oto/utilities/vehicle_util.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'charts/pie_chart.dart';

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
import 'charts/costs_graph.dart';
import 'table_stats.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    var appTheme = context.watch<AppTheme>();
    bool portrait = MediaQuery.of(context).orientation == Orientation.portrait;
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<VehicleProvider>(create:(c)=> VehicleProvider()),
        ChangeNotifierProvider<DriverProvider>(create:(c)=> DriverProvider()),
        ChangeNotifierProvider<LogProvider>(create:(c)=> LogProvider()),
        ChangeNotifierProvider<PlanningProvider>(create:(c)=> PlanningProvider()),
        ChangeNotifierProvider<RepairProvider>(create:(c)=> RepairProvider()),
      ],
      builder: (con,w){
        var vehicles=Provider.of<VehicleProvider>(con);
        var drivers=Provider.of<DriverProvider>(con);
        var logs=Provider.of<LogProvider>(con);
        var plannings=Provider.of<PlanningProvider>(con);
        var repairs=Provider.of<RepairProvider>(con);
        return ScaffoldPage(
            header:  PageTitle(text: 'home',trailing: Button(
              onPressed: ()=>onRefresh(vehicles,drivers,logs,
                  plannings,repairs),
              child: const Text('refresh').tr(),),),
            content: ListView(
              padding: const EdgeInsets.all(10),
              children: [
                StaggeredGrid.count(
                  crossAxisCount:
                  portrait
                      ? 2
                      : 4,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  children: buttonList(appTheme,vehicles,drivers,logs,
                    plannings,repairs),
                ),
                smallSpace,
                StaggeredGrid.count(
                  crossAxisCount:
                  portrait
                      ? 1
                      : 2,
                  mainAxisSpacing: 5,
                  crossAxisSpacing: 5,
                  children: widgetList(appTheme),
                ),
              ],
            ));
      },
    );
  }


  void onRefresh(VehicleProvider vehicles,
      DriverProvider drivers,LogProvider logs,PlanningProvider plannings,
      RepairProvider repairs)async{
    await Future.wait([
      vehicles.refreshVehicles(),
      vehicles.refreshDocuments(),
      drivers.refreshConducteurs(),
      drivers.refreshDocuments(),
      logs.refreshLogs(),
      plannings.refreshPlannings(),
      repairs.refreshReparations()
    ]);
    setState(() {

    });
  }

  List<ButtonContainer> buttonList(AppTheme appTheme,VehicleProvider vehicles,
      DriverProvider drivers,LogProvider logs,PlanningProvider plannings,
      RepairProvider repairs) {
    return [
      ButtonContainer(
        icon: FluentIcons.car,
        text: 'vehicules'.tr(),
        getCount:!VehicleProvider.downloadedVehicles?vehicles
            .getVehicleCount:null,
        counter: VehicleProvider.downloadedVehicles?VehicleProvider
            .vehicles.length:null,
        maxCounter: ClientDatabase.gotLimit && ClientDatabase.limits
            .containsKey('vehicles')?ClientDatabase.limits['vehicles']:null,
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
        getCount:!VehicleProvider.downloadedDocuments?vehicles
            .getVehicleDocsCount:null,
        counter: VehicleProvider.downloadedDocuments?VehicleProvider
        .documentsVehicules.length:null,
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
        getCount:!RepairProvider.downloadedReparations?repairs
            .getRepairsCount:null,
        counter: RepairProvider.downloadedReparations?RepairProvider
            .reparations.length:null,
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
        getCount:!RepairProvider.downloadedPrestataires?repairs
            .getProvidersCount:null,
        counter: RepairProvider.downloadedPrestataires?RepairProvider
            .prestataires.length:null,
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
        getCount:!DriverProvider.downloadedConducteurs?drivers
        .getDriversCount:null,
        counter:DriverProvider.downloadedConducteurs?DriverProvider
        .conducteurs.length:null,
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
        getCount:!DriverProvider.downloadedDocuments?drivers
            .getDriversDocsCount:null,
        counter:DriverProvider.downloadedDocuments?DriverProvider
            .documentConducteurs.length:null,
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
        getCount:!PlanningProvider.downloadedPlanning?plannings
            .getPlanningCount:null,
        counter:PlanningProvider.downloadedPlanning?PlanningProvider
            .plannings.length:null,
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
        getCount:!LogProvider.downloadedActivities?logs
            .getLogCount:null,
        counter:LogProvider.downloadedActivities?LogProvider
            .activities.length:null,
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
            FluentIcons.health,
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
      if(MyEntrepriseState.p!=null)
      StaggeredGridTile.fit(
        crossAxisCellCount: 1,
        child: TableStats(
          height: height,
          title: 'appartenancevehicule'.tr(),
          icon: Icon(
            Icons.emoji_transportation,
            color: appTheme.color.darker,
          ),
          content: ParcOtoPie(
            labels: List.generate(MyEntrepriseState.p?.filiales?.length??0,
                    (index) => MapEntry(MyEntrepriseState.p!
                    .filiales![index], DatabaseCounters().countVehiclesWithCondition([
                  Query.equal('appartenance', MyEntrepriseState.p!
                      .filiales![index]
                      .replaceAll(' ', '').trim().toUpperCase())
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
        crossAxisCellCount: 2,
        child: TableStats(
          height: height,
          title: 'perimetre'.tr(),
          icon: Icon(
            FluentIcons.map_directions,
            color: appTheme.color.darker,
          ),
          content: StateCategoryBars(
            labels: List.generate(5, (index) => MapEntry(VehiclesUtilities
                .getEtatName(index),[
              MapEntry(VehiclesUtilities
                  .getPerimetre(0), DatabaseCounters()
                  .countVehiclesWithCondition([
                Query.equal('etatactuel', index),
                Query.equal('perimetre', 0)
              ])),
              MapEntry(VehiclesUtilities
                  .getPerimetre(1), DatabaseCounters()
                  .countVehiclesWithCondition([
                Query.equal('etatactuel', index),
                Query.equal('perimetre', 1)
              ])),
              MapEntry(VehiclesUtilities
                  .getPerimetre(2), DatabaseCounters()
                  .countVehiclesWithCondition([
                Query.equal('etatactuel', index),
                Query.equal('perimetre', 2)
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
      if(MyEntrepriseState.p!=null)
        StaggeredGridTile.fit(
        crossAxisCellCount: 1,
        child: TableStats(
          height: height*2,
          title: 'exploitationvehicule'.tr(),
          icon: Icon(
            Icons.hub,
            color: appTheme.color.darker,
          ),
          content: StateBars(
            hideEmpty: true,
            vertical: true,
            labels: List.generate(MyEntrepriseState.p!.filiales?.length??0,
                    (index) => MapEntry(MyEntrepriseState.p!
                    .filiales![index], DatabaseCounters().countVehiclesWithCondition([
                  Query.equal('filliale', MyEntrepriseState.p!
                      .filiales![index]
                      .replaceAll(' ', '').trim().toUpperCase())
                ]))),
          ),
          onTap: () {
            PanesListState.index.value = PaneItemsAndFooters.originalItems
                .indexOf(PaneItemsAndFooters.vehicles) +
                1;
          },
        ),
      ),
      if(MyEntrepriseState.p!=null)
        StaggeredGridTile.fit(
        crossAxisCellCount: 1,
        child: TableStats(
          height: height*2,
          title: 'directions'.tr(),
          icon: Icon(
            Icons.apartment,
            color: appTheme.color.darker,
          ),
          content: StateBars(
            hideEmpty: true,
            vertical: true,
            labels: List.generate(MyEntrepriseState.p!.directions?.length??0,
                    (index) => MapEntry(MyEntrepriseState.p!
                    .directions![index], DatabaseCounters().countVehiclesWithCondition([
                  Query.equal('direction', MyEntrepriseState.p!
                      .directions![index]
                      .replaceAll(' ', '').trim().toUpperCase())
                ]))),
          ),
          onTap: () {
            PanesListState.index.value = PaneItemsAndFooters.originalItems
                .indexOf(PaneItemsAndFooters.vehicles) +
                1;
          },
        ),
      ),
      if(MyEntrepriseState.p!=null)
        StaggeredGridTile.fit(
        crossAxisCellCount: 1,
        child: TableStats(
          height: height,
          title: 'appartenanceconducteur'.tr(),
          icon: Icon(
            Icons.home_work_outlined,
            color: appTheme.color.darker,
          ),
          content: ParcOtoPie(
            labels: List.generate(MyEntrepriseState.p!.filiales?.length??0,
                    (index) => MapEntry(MyEntrepriseState.p!
                    .filiales![index], DatabaseCounters().countChauffeurWithCondition([
                  Query.equal('filliale', MyEntrepriseState.p!
                      .filiales![index]
                      .replaceAll(' ', '').trim().toUpperCase())
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
          title: 'majvehicules'.tr(),
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
        crossAxisCellCount: 2,
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
          title: 'majreparation'.tr(),
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
          title: 'majconducteurs'.tr(),
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

  @override
  bool get wantKeepAlive => true;
}
