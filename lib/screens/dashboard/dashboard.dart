import 'package:appwrite/appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:parc_oto/admin_parameters.dart';
import 'package:parc_oto/providers/driver_provider.dart';
import 'package:parc_oto/providers/log_provider.dart';
import 'package:parc_oto/providers/planning_provider.dart';
import 'package:parc_oto/providers/repair_provider.dart';
import 'package:parc_oto/providers/vehicle_provider.dart';
import 'package:parc_oto/screens/dashboard/charts/state_category_bar.dart';
import 'package:parc_oto/screens/entreprise/entreprise.dart';
import 'package:parc_oto/screens/logs/logging/log_table.dart';
import 'package:parc_oto/utilities/vehicle_util.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'charts/pie_chart.dart';

import '../../providers/counters.dart';
import '../../theme.dart';
import '../../widgets/module_dashboard_action.dart';
import '../../widgets/module_dashboard_header.dart';
import '../../widgets/module_dashboard_section_header.dart';
import '../sidemenu/pane_items.dart';
import 'charts/state_bars.dart';
import 'charts/costs_graph.dart';
import 'table_stats.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    var appTheme = context.watch<AppTheme>();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<VehicleProvider>(
          create: (c) => VehicleProvider(),
        ),
        ChangeNotifierProvider<DriverProvider>(create: (c) => DriverProvider()),
        ChangeNotifierProvider<LogProvider>(create: (c) => LogProvider()),
        ChangeNotifierProvider<PlanningProvider>(
          create: (c) => PlanningProvider(),
        ),
        ChangeNotifierProvider<RepairProvider>(create: (c) => RepairProvider()),
      ],
      builder: (con, w) {
        var vehicles = Provider.of<VehicleProvider>(con);
        var drivers = Provider.of<DriverProvider>(con);
        var logs = Provider.of<LogProvider>(con);
        var plannings = Provider.of<PlanningProvider>(con);
        var repairs = Provider.of<RepairProvider>(con);
        return ScaffoldPage(
          padding: EdgeInsets.zero,
          content: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 760;
              return ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 14 : 28,
                  vertical: 22,
                ),
                children: [
                  ModuleDashboardHeader(
                    title: 'home'.tr(),
                    subtitle: 'Vue d’ensemble de votre activité',
                    eyebrow: 'ParcOto / Overview',
                    heroTitle: 'Pilotage de votre parc automobile',
                    heroDescription:
                        'Retrouvez vos véhicules, interventions et équipes au même endroit.',
                    icon: FluentIcons.car,
                    trailing: Tooltip(
                      message: 'Actualiser les données',
                      child: IconButton(
                        icon: const Icon(FluentIcons.refresh),
                        onPressed: () => onRefresh(
                          vehicles,
                          drivers,
                          logs,
                          plannings,
                          repairs,
                        ),
                      ),
                    ),
                  ),
                  ModuleDashboardSectionHeader(
                    title: 'Actions courantes',
                    subtitle:
                        'Accédez directement aux fonctions les plus utilisées.',
                  ),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: buttonList(),
                  ),
                  const SizedBox(height: 28),
                  ModuleDashboardSectionHeader(
                    title: 'Indicateurs de votre activité',
                    subtitle:
                        'Une vue synthétique de la flotte, des opérations et des mouvements récents.',
                  ),
                  StaggeredGrid.count(
                    crossAxisCount: compact ? 1 : 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    children: widgetList(appTheme),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void onRefresh(
    VehicleProvider vehicles,
    DriverProvider drivers,
    LogProvider logs,
    PlanningProvider plannings,
    RepairProvider repairs,
  ) async {
    await Future.wait([
      vehicles.refreshVehicles(),
      vehicles.refreshDocuments(),
      drivers.refreshConducteurs(),
      drivers.refreshDocuments(),
      logs.refreshLogs(),
      plannings.refreshPlannings(),
      repairs.refreshReparations(),
    ]);
    setState(() {});
  }

  List<Widget> buttonList() {
    final vehicleCount = VehicleProvider.downloadedVehicles
        ? VehicleProvider.vehicles.length
        : null;
    final vehicleDocumentCount = VehicleProvider.downloadedDocuments
        ? VehicleProvider.documentsVehicules.length
        : null;
    final repairCount = RepairProvider.downloadedReparations
        ? RepairProvider.reparations.length
        : null;
    final providerCount = RepairProvider.downloadedPrestataires
        ? RepairProvider.prestataires.length
        : null;
    final driverCount = DriverProvider.downloadedConducteurs
        ? DriverProvider.conducteurs.length
        : null;
    final driverDocumentCount = DriverProvider.downloadedDocuments
        ? DriverProvider.documentConducteurs.length
        : null;
    final planningCount = PlanningProvider.downloadedPlanning
        ? PlanningProvider.plannings.length
        : null;
    final activityCount = LogProvider.downloadedActivities
        ? LogProvider.activities.length
        : null;

    String countDetail(int? count, String singular, String plural) =>
        count == null ? 'Synchronisation des données' : '$count ${count == 1 ? singular : plural}';

    return [
      ModuleDashboardAction(
        label: 'vehicules'.tr(),
        detail: countDetail(vehicleCount, 'véhicule', 'véhicules'),
        icon: FluentIcons.car,
        onPressed: () => PaneItemsAndFooters.selectPane('vehicles'),
      ),
      ModuleDashboardAction(
        label: 'vehicledocuments'.tr(),
        detail: countDetail(vehicleDocumentCount, 'document', 'documents'),
        icon: FluentIcons.document_set,
        onPressed: () => PaneItemsAndFooters.selectPane('vehicle-documents'),
      ),
      ModuleDashboardAction(
        label: 'reparations'.tr(),
        detail: countDetail(repairCount, 'intervention', 'interventions'),
        icon: FluentIcons.repair,
        onPressed: () => PaneItemsAndFooters.selectPane('repairs'),
      ),
      ModuleDashboardAction(
        label: 'prestataires'.tr(),
        detail: countDetail(providerCount, 'prestataire', 'prestataires'),
        icon: FluentIcons.service_activity,
        onPressed: () => PaneItemsAndFooters.selectPane('repair-providers'),
      ),
      ModuleDashboardAction(
        label: 'chauffeurs'.tr(),
        detail: countDetail(driverCount, 'conducteur', 'conducteurs'),
        icon: FluentIcons.people,
        onPressed: () => PaneItemsAndFooters.selectPane('chauffeurs'),
      ),
      ModuleDashboardAction(
        label: 'chaufdocuments'.tr(),
        detail: countDetail(driverDocumentCount, 'document', 'documents'),
        icon: FluentIcons.document_set,
        onPressed: () => PaneItemsAndFooters.selectPane('driver-documents'),
      ),
      ModuleDashboardAction(
        label: 'reservation'.tr(),
        detail: countDetail(planningCount, 'réservation', 'réservations'),
        icon: FluentIcons.edit_event,
        onPressed: () => PaneItemsAndFooters.selectPane('planner'),
      ),
      ModuleDashboardAction(
        label: 'activities'.tr(),
        detail: countDetail(activityCount, 'activité', 'activités'),
        icon: FluentIcons.database_activity,
        onPressed: () => PaneItemsAndFooters.selectPane('events'),
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
          icon: Icon(FluentIcons.health, color: appTheme.color.darker),
          content: StateBars(
            labels: conducteurEmploye
                ? [
                    MapEntry(
                      'gstate',
                      DatabaseCounters().countVehicles(etat: 0),
                    ),
                    MapEntry(
                      'bstate',
                      DatabaseCounters().countVehicles(etat: 1),
                    ),
                    MapEntry(
                      'rstate',
                      DatabaseCounters().countVehicles(etat: 2),
                    ),
                    MapEntry(
                      'ostate',
                      DatabaseCounters().countVehicles(etat: 3),
                    ),
                    MapEntry(
                      'restate',
                      DatabaseCounters().countVehicles(etat: 4),
                    ),
                  ]
                : [
                    MapEntry(
                      'dispo',
                      DatabaseCounters().countVehicles(etat: 5),
                    ),
                    MapEntry(
                      'panne',
                      DatabaseCounters().countVehicles(etat: 6),
                    ),
                    MapEntry(
                      'enreparation',
                      DatabaseCounters().countVehicles(etat: 7),
                    ),
                    MapEntry(
                      'enmission',
                      DatabaseCounters().countVehicles(etat: 8),
                    ),
                  ],
          ),
          onTap: () {
            PaneItemsAndFooters.selectPane('vehicle-manager');
          },
        ),
      ),
      if (MyEntrepriseState.p != null)
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
              labels: List.generate(
                MyEntrepriseState.p?.filiales?.length ?? 0,
                (index) => MapEntry(
                  MyEntrepriseState.p!.filiales![index],
                  DatabaseCounters().countVehiclesWithCondition([
                    Query.equal(
                      'appartenance',
                      MyEntrepriseState.p!.filiales![index]
                          .replaceAll(' ', '')
                          .trim()
                          .toUpperCase(),
                    ),
                  ]),
                ),
              ),
            ),
            onTap: () {
              PaneItemsAndFooters.selectPane('vehicle-manager');
            },
          ),
        ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: TableStats(
          height: height,
          title: 'perimetre'.tr(),
          icon: Icon(FluentIcons.map_directions, color: appTheme.color.darker),
          content: StateCategoryBars(
            labels: List.generate(
              conducteurEmploye ? 5 : 4,
              (index) => MapEntry(
                VehiclesUtilities.getEtatName(
                  conducteurEmploye ? index : index + 5,
                ),
                [
                  if (conducteurEmploye)
                    MapEntry(
                      VehiclesUtilities.getPerimetre(0),
                      DatabaseCounters().countVehiclesWithCondition([
                        Query.equal('etatactuel', index),
                        Query.equal('perimetre', 0),
                      ]),
                    ),
                  if (conducteurEmploye)
                    MapEntry(
                      VehiclesUtilities.getPerimetre(1),
                      DatabaseCounters().countVehiclesWithCondition([
                        Query.equal('etatactuel', index),
                        Query.equal('perimetre', 1),
                      ]),
                    ),
                  if (conducteurEmploye)
                    MapEntry(
                      VehiclesUtilities.getPerimetre(2),
                      DatabaseCounters().countVehiclesWithCondition([
                        Query.equal('etatactuel', index),
                        Query.equal('perimetre', 2),
                      ]),
                    ),
                  if (!conducteurEmploye)
                    MapEntry(
                      VehiclesUtilities.getPerimetre(3),
                      DatabaseCounters().countVehiclesWithCondition([
                        Query.equal('etatactuel', index),
                        Query.equal('perimetre', 3),
                      ]),
                    ),
                  if (!conducteurEmploye)
                    MapEntry(
                      VehiclesUtilities.getPerimetre(4),
                      DatabaseCounters().countVehiclesWithCondition([
                        Query.equal('etatactuel', index),
                        Query.equal('perimetre', 4),
                      ]),
                    ),
                ],
              ),
            ),
          ),
          onTap: () {
            PaneItemsAndFooters.selectPane('vehicle-manager');
          },
        ),
      ),
      if (MyEntrepriseState.p != null)
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: TableStats(
            height: height * 2,
            title: 'exploitationvehicule'.tr(),
            icon: Icon(Icons.hub, color: appTheme.color.darker),
            content: StateBars(
              hideEmpty: true,
              vertical: true,
              labels: List.generate(
                MyEntrepriseState.p!.filiales?.length ?? 0,
                (index) => MapEntry(
                  MyEntrepriseState.p!.filiales![index],
                  DatabaseCounters().countVehiclesWithCondition([
                    Query.equal(
                      'filliale',
                      MyEntrepriseState.p!.filiales![index]
                          .replaceAll(' ', '')
                          .trim()
                          .toUpperCase(),
                    ),
                  ]),
                ),
              ),
            ),
            onTap: () {
              PaneItemsAndFooters.selectPane('vehicle-manager');
            },
          ),
        ),
      if (MyEntrepriseState.p != null)
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: TableStats(
            height: height * 2,
            title: 'directions'.tr(),
            icon: Icon(Icons.apartment, color: appTheme.color.darker),
            content: StateBars(
              hideEmpty: true,
              vertical: true,
              labels: List.generate(
                MyEntrepriseState.p!.directions?.length ?? 0,
                (index) => MapEntry(
                  MyEntrepriseState.p!.directions![index],
                  DatabaseCounters().countVehiclesWithCondition([
                    Query.equal(
                      'direction',
                      MyEntrepriseState.p!.directions![index]
                          .replaceAll(' ', '')
                          .trim()
                          .toUpperCase(),
                    ),
                  ]),
                ),
              ),
            ),
            onTap: () {
              PaneItemsAndFooters.selectPane('vehicle-manager');
            },
          ),
        ),
      if (MyEntrepriseState.p != null)
        StaggeredGridTile.fit(
          crossAxisCellCount: 1,
          child: TableStats(
            height: height,
            title: 'appartenanceconducteur'.tr(),
            icon: Icon(Icons.home_work_outlined, color: appTheme.color.darker),
            content: ParcOtoPie(
              labels: List.generate(
                MyEntrepriseState.p!.filiales?.length ?? 0,
                (index) => MapEntry(
                  MyEntrepriseState.p!.filiales![index],
                  DatabaseCounters().countChauffeurWithCondition([
                    Query.equal(
                      'filliale',
                      MyEntrepriseState.p!.filiales![index]
                          .replaceAll(' ', '')
                          .trim()
                          .toUpperCase(),
                    ),
                  ]),
                ),
              ),
            ),
            onTap: () {
              PaneItemsAndFooters.selectPane('vehicle-manager');
            },
          ),
        ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 1,
        child: TableStats(
          height: height,
          title: 'majvehicules'.tr(),
          icon: Icon(FluentIcons.car, color: appTheme.color.darker),
          content: const LogTable(
            pages: false,
            fieldsToShow: ['act', 'id', 'date'],
            filters: {'typemin': '0', 'typemax': '9'},
            statTable: true,
            numberOfRows: 5,
          ),
          onTap: () {
            PaneItemsAndFooters.selectPane('vehicle-manager');
          },
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 2,
        child: TableStats(
          height: height,
          title: 'depenses'.tr(),
          icon: Icon(FluentIcons.cost_control, color: appTheme.color.darker),
          content: CostGraph(start: start, end: end, appTheme: appTheme),
          onTap: () {
            PaneItemsAndFooters.selectPane('vehicle-manager');
          },
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 1,
        child: TableStats(
          height: height,
          title: 'majreparation'.tr(),
          icon: Icon(FluentIcons.repair, color: appTheme.color.darker),
          content: const LogTable(
            pages: false,
            fieldsToShow: ['act', 'id', 'date'],
            filters: {'typemin': '10', 'typemax': '15'},
            statTable: true,
            numberOfRows: 5,
          ),
          onTap: () {
            PaneItemsAndFooters.selectPane('vehicle-manager');
          },
        ),
      ),
      StaggeredGridTile.fit(
        crossAxisCellCount: 1,
        child: TableStats(
          height: height,
          title: 'majconducteurs'.tr(),
          icon: Icon(FluentIcons.people, color: appTheme.color.darker),
          content: const LogTable(
            pages: false,
            fieldsToShow: ['act', 'id', 'date'],
            filters: {'typemin': '16', 'typemax': '25'},
            statTable: true,
            numberOfRows: 5,
          ),
          onTap: () {
            PaneItemsAndFooters.selectPane('vehicle-manager');
          },
        ),
      ),
    ];
  }

  @override
  bool get wantKeepAlive => true;
}
