import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../providers/counters.dart';
import '../../widgets/module_dashboard_action.dart';
import '../../widgets/module_dashboard_header.dart';
import '../../widgets/module_dashboard_metric.dart';
import '../../widgets/module_dashboard_section_header.dart';
import '../../widgets/module_dashboard_panel.dart';
import '../dashboard/charts/pie_chart.dart';
import '../logs/logging/log_table.dart';
import '../sidemenu/pane_items.dart';
import 'documents/document_form.dart';
import 'documents/document_tabs.dart';
import 'manager/vehicle_form.dart';
import 'manager/vehicle_tabs.dart';
import 'states/state_form.dart';
import 'states/state_manager.dart';

class VehicleDashboard extends StatelessWidget {
  const VehicleDashboard({super.key});

  void _openNewVehicle() {
    if (!PaneItemsAndFooters.selectPane('vehicle-manager')) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      final index = VehicleTabsState.tabs.length;
      VehicleTabsState.tabs.add(tab);
      VehicleTabsState.currentIndex.value = index;
    });
  }

  void _openNewDocument() {
    if (!PaneItemsAndFooters.selectPane('vehicle-documents')) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      late Tab tab;
      tab = Tab(
        key: UniqueKey(),
        text: Text('nouvdocument'.tr()),
        semanticLabel: 'nouvdocument'.tr(),
        icon: const Icon(FluentIcons.new_folder),
        body: const ScaffoldPage(content: DocumentForm()),
        onClosed: () {
          DocumentTabsState.tabs.remove(tab);
          if (DocumentTabsState.currentIndex.value > 0) {
            DocumentTabsState.currentIndex.value--;
          }
        },
      );
      final index = DocumentTabsState.tabs.length;
      DocumentTabsState.tabs.add(tab);
      DocumentTabsState.currentIndex.value = index;
    });
  }

  void _openStateDialog(BuildContext context) {
    if (!PaneItemsAndFooters.selectPane('vehicle-states')) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dialogContext = EtatManagerState.current;
      if (dialogContext == null || !dialogContext.mounted) return;
      showDialog(
        context: dialogContext,
        barrierDismissible: true,
        builder: (context) => ContentDialog(
          title: const Text('nouvetat').tr(),
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 500),
          content: const StateForm(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final moduleActions = <Widget>[
            ModuleDashboardAction(
              label: 'gestionvehicles'.tr(),
              detail: 'Parc et fiches véhicules',
              icon: FluentIcons.task_manager,
              onPressed: () => PaneItemsAndFooters.selectPane('vehicle-manager'),
            ),
            ModuleDashboardAction(
              label: 'nouvvehicule'.tr(),
              detail: 'Ajouter un véhicule',
              icon: FluentIcons.car,
              onPressed: _openNewVehicle,
            ),
            ModuleDashboardAction(
              label: 'brands'.tr(),
              detail: 'Référentiels fabricants',
              icon: FluentIcons.verified_brand,
              onPressed: () => PaneItemsAndFooters.selectPane('vehicle-brands'),
            ),
            ModuleDashboardAction(
              label: 'vstates'.tr(),
              detail: 'États et statuts du parc',
              icon: FluentIcons.health,
              onPressed: () => PaneItemsAndFooters.selectPane('vehicle-states'),
            ),
            ModuleDashboardAction(
              label: 'nouvetat'.tr(),
              detail: 'Créer un état',
              icon: FluentIcons.health_refresh,
              onPressed: () => _openStateDialog(context),
            ),
            ModuleDashboardAction(
              label: 'documents'.tr(),
              detail: 'Documents administratifs',
              icon: FluentIcons.document_set,
              onPressed: () => PaneItemsAndFooters.selectPane('vehicle-documents'),
            ),
            ModuleDashboardAction(
              label: 'nouvdocument'.tr(),
              detail: 'Ajouter un document',
              icon: FluentIcons.document,
              onPressed: _openNewDocument,
            ),
          ];

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 28,
              vertical: 22,
            ),
            children: [
              ModuleDashboardHeader(
                title: 'vehicules'.tr(),
                subtitle:
                    'Gérez votre parc, ses documents et ses états depuis un seul espace.',
                eyebrow: 'Gestion de flotte',
                heroTitle: 'Votre parc automobile, en un coup d’œil',
                heroDescription:
                    'Accédez aux véhicules, aux états et aux documents administratifs.',
                icon: FluentIcons.car,
              ),
              ModuleDashboardSectionHeader(
                title: 'Indicateurs du parc',
                subtitle:
                    'Consultez les volumes du parc et la répartition des principaux états.',
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ModuleDashboardMetric(
                    label: 'Véhicules',
                    detail: 'Parc total',
                    icon: FluentIcons.car,
                    loadValue: () => DatabaseCounters().countVehicles(),
                  ),
                  ModuleDashboardMetric(
                    label: 'Libres',
                    detail: 'État libre',
                    icon: FluentIcons.check_mark,
                    loadValue: () => DatabaseCounters().countVehiclesByDashboardStatus(etat: 0),
                  ),
                  ModuleDashboardMetric(
                    label: 'En panne',
                    detail: 'État panne',
                    icon: FluentIcons.repair,
                    loadValue: () => DatabaseCounters().countVehiclesByDashboardStatus(etat: 1),
                  ),
                  ModuleDashboardMetric(
                    label: 'Au garage',
                    detail: 'État garage',
                    icon: FluentIcons.repair,
                    loadValue: () => DatabaseCounters().countVehiclesByDashboardStatus(etat: 2),
                  ),
                  ModuleDashboardMetric(
                    label: 'En marche',
                    detail: 'État en marche',
                    icon: FluentIcons.car,
                    loadValue: () => DatabaseCounters().countVehiclesByDashboardStatus(etat: 3),
                  ),
                  ModuleDashboardMetric(
                    label: 'En réforme',
                    detail: 'Véhicules réformés',
                    icon: FluentIcons.document,
                    loadValue: () => DatabaseCounters().countVehiclesByDashboardStatus(etat: 4),
                  ),
                  ModuleDashboardMetric(
                    label: 'Documents',
                    detail: 'Documents véhicules',
                    icon: FluentIcons.document_set,
                    loadValue: () => DatabaseCounters().countVdocs(),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              ModuleDashboardSectionHeader(
                title: 'Gérer le parc automobile',
                subtitle:
                    'Ouvrez directement la gestion des véhicules, documents et référentiels.',
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: moduleActions,
              ),
              const SizedBox(height: 28),
              ModuleDashboardSectionHeader(
                title: 'État et activité du parc',
                subtitle:
                    'Suivez la répartition des véhicules et les dernières opérations enregistrées.',
              ),
              StaggeredGrid.count(
                crossAxisCount: compact ? 1 : 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                children: [
                  ModuleDashboardPanel(
                    title: 'Activité récente',
                    child: const LogTable(
                      statTable: true,
                      numberOfRows: 4,
                      pages: false,
                      filters: {'typemin': '0', 'typemax': '9'},
                      fieldsToShow: ['act', 'id', 'date'],
                    ),
                  ),
                  ModuleDashboardPanel(
                    title: 'Répartition des véhicules',
                    child: ParcOtoPie(
                      labels: [
                        MapEntry('gstate', DatabaseCounters().countVehiclesByDashboardStatus(etat: 0)),
                        MapEntry('bstate', DatabaseCounters().countVehiclesByDashboardStatus(etat: 1)),
                        MapEntry('rstate', DatabaseCounters().countVehiclesByDashboardStatus(etat: 2)),
                        MapEntry('ostate', DatabaseCounters().countVehiclesByDashboardStatus(etat: 3)),
                        MapEntry('restate', DatabaseCounters().countVehiclesByDashboardStatus(etat: 4)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

