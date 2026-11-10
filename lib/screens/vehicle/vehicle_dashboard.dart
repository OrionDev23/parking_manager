import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../../providers/counters.dart';
import '../../theme.dart';
import '../../widgets/button_container.dart';
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
    final appTheme = context.watch<AppTheme>();

    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 760;
          final moduleColumns = constraints.maxWidth >= 1400
              ? 4
              : constraints.maxWidth >= 1000
              ? 3
              : constraints.maxWidth >= 620
              ? 2
              : 1;

          final moduleActions = <ButtonContainer>[
            ButtonContainer(
              icon: FluentIcons.task_manager,
              text: 'gestionvehicles'.tr(),
              color: appTheme.color,
              showBothLN: false,
              showBottom: false,
              showCounter: false,
              action: () => PaneItemsAndFooters.selectPane('vehicle-manager'),
            ),
            ButtonContainer(
              icon: FluentIcons.car,
              text: 'nouvvehicule'.tr(),
              color: appTheme.color,
              showBothLN: false,
              showBottom: false,
              showCounter: false,
              action: _openNewVehicle,
            ),
            ButtonContainer(
              icon: FluentIcons.verified_brand,
              text: 'brands'.tr(),
              color: appTheme.color,
              showBothLN: false,
              showBottom: false,
              showCounter: false,
              action: () => PaneItemsAndFooters.selectPane('vehicle-brands'),
            ),
            ButtonContainer(
              icon: FluentIcons.health,
              text: 'vstates'.tr(),
              color: appTheme.color,
              showBothLN: false,
              showBottom: false,
              showCounter: false,
              action: () => PaneItemsAndFooters.selectPane('vehicle-states'),
            ),
            ButtonContainer(
              icon: FluentIcons.health_refresh,
              text: 'nouvetat'.tr(),
              color: appTheme.color,
              showBothLN: false,
              showBottom: false,
              showCounter: false,
              action: () => _openStateDialog(context),
            ),
            ButtonContainer(
              icon: FluentIcons.document_set,
              text: 'documents'.tr(),
              color: appTheme.color,
              showBothLN: false,
              showBottom: false,
              showCounter: false,
              action: () => PaneItemsAndFooters.selectPane('vehicle-documents'),
            ),
            ButtonContainer(
              icon: FluentIcons.document,
              text: 'nouvdocument'.tr(),
              color: appTheme.color,
              showBothLN: false,
              showBottom: false,
              showCounter: false,
              action: _openNewDocument,
            ),
          ];

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 28,
              vertical: 22,
            ),
            children: [
              Text(
                'vehicules'.tr(),
                style: TextStyle(
                  fontSize: compact ? 25 : 30,
                  fontWeight: FontWeight.w700,
                  color: appTheme.writingStyle.color,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Gérez votre parc, ses documents et ses états depuis un seul espace.',
                style: TextStyle(fontSize: 13, color: Colors.grey[100]),
              ),
              const SizedBox(height: 22),
              Container(
                padding: EdgeInsets.all(compact ? 16 : 22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      appTheme.color.dark,
                      appTheme.color,
                      appTheme.color.light,
                    ],
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'GESTION DE FLOTTE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .78),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Votre parc automobile, en un coup d’œil',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: compact ? 17 : 21,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Accédez aux véhicules, aux états et aux documents administratifs.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .86),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: 20),
                      Icon(
                        FluentIcons.car,
                        size: 58,
                        color: Colors.white.withValues(alpha: .9),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'Accès rapides',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: appTheme.writingStyle.color,
                ),
              ),
              const SizedBox(height: 12),
              StaggeredGrid.count(
                crossAxisCount: moduleColumns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: moduleActions,
              ),
              const SizedBox(height: 28),
              Text(
                'Suivi du parc',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: appTheme.writingStyle.color,
                ),
              ),
              const SizedBox(height: 12),
              StaggeredGrid.count(
                crossAxisCount: compact ? 1 : 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                children: [
                  _VehicleDashboardPanel(
                    title: 'Activité récente',
                    child: const LogTable(
                      statTable: true,
                      numberOfRows: 4,
                      pages: false,
                      filters: {'typemin': '0', 'typemax': '9'},
                      fieldsToShow: ['act', 'id', 'date'],
                    ),
                  ),
                  _VehicleDashboardPanel(
                    title: 'vstates'.tr(),
                    child: ParcOtoPie(
                      labels: [
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

class _VehicleDashboardPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _VehicleDashboardPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    return Container(
      height: 360,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appTheme.backGroundColor,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey[30]),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: appTheme.writingStyle.color,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: child),
        ],
      ),
    );
  }
}
