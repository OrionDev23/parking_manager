import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/module_dashboard_action.dart';
import '../../widgets/module_dashboard_header.dart';
import '../../widgets/module_dashboard_panel.dart';
import '../../widgets/module_dashboard_section_header.dart';
import '../logs/logging/log_table.dart';
import '../prestataire/prestataire_form.dart';
import '../prestataire/prestataire_tabs.dart';
import '../sidemenu/pane_items.dart';
import 'reparation/manager/reparation_tabs.dart';
import 'reparation/reparation_order_form/reparation_form.dart';

class ReparationDashboard extends StatelessWidget {
  const ReparationDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = <Widget>[
      ModuleDashboardAction(
        label: 'greparations'.tr(),
        detail: 'Consulter les ordres de réparation',
        icon: FluentIcons.list,
        onPressed: () => PaneItemsAndFooters.selectPane('repair-orders'),
      ),
      ModuleDashboardAction(
        label: 'nouvrepar'.tr(),
        detail: 'Créer un ordre de réparation',
        icon: FluentIcons.repair,
        onPressed: () {
          if (!PaneItemsAndFooters.selectPane('repair-orders')) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            late Tab tab;
            tab = Tab(
              key: UniqueKey(),
              text: Text('nouvrepar'.tr()),
              semanticLabel: 'nouvrepar'.tr(),
              icon: const Icon(FluentIcons.document),
              body: ReparationForm(key: UniqueKey()),
              onClosed: () {
                ReparationTabsState.tabs.remove(tab);
                if (ReparationTabsState.currentIndex.value > 0) {
                  ReparationTabsState.currentIndex.value--;
                }
              },
            );
            ReparationTabsState.tabs.add(tab);
            ReparationTabsState.currentIndex.value =
                ReparationTabsState.tabs.length;
          });
        },
      ),
      ModuleDashboardAction(
        label: 'prestataires'.tr(),
        detail: 'Consulter les prestataires',
        icon: FluentIcons.service_activity,
        onPressed: () => PaneItemsAndFooters.selectPane('repair-providers'),
      ),
      ModuleDashboardAction(
        label: 'nouvprest'.tr(),
        detail: 'Ajouter un prestataire',
        icon: FluentIcons.add_friend,
        onPressed: () {
          if (!PaneItemsAndFooters.selectPane('repair-providers')) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
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
            PrestataireTabsState.tabs.add(tab);
            PrestataireTabsState.currentIndex.value =
                PrestataireTabsState.tabs.length;
          });
        },
      ),
    ];

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
                title: 'reparations'.tr(),
                subtitle:
                    'Suivez les interventions, les réceptions et les prestataires.',
                eyebrow: 'Maintenance / Operations',
                heroTitle: 'Pilotage des réparations',
                heroDescription:
                    'Centralisez les ordres de réparation, les fiches de réception et le suivi des intervenants.',
                icon: FluentIcons.repair,
              ),
              const SizedBox(height: 24),
              ModuleDashboardSectionHeader(
                title: 'Actions de maintenance',
                subtitle:
                    'Créez une intervention ou accédez aux ordres et aux prestataires.',
              ),
              Wrap(spacing: 12, runSpacing: 12, children: actions),
              const SizedBox(height: 30),
              ModuleDashboardSectionHeader(
                title: 'Activité de maintenance',
                subtitle:
                    'Retrouvez les dernières opérations enregistrées dans le module.',
              ),
              ModuleDashboardPanel(
                title: 'Historique récent',
                height: 380.px,
                child: const LogTable(
                  statTable: true,
                  pages: false,
                  numberOfRows: 3,
                  filters: {'typemin': '10', 'typemax': '15'},
                  fieldsToShow: ['act', 'date'],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
