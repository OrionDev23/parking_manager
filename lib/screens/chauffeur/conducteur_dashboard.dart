import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../admin_parameters.dart';
import '../../providers/counters.dart';
import '../../widgets/module_dashboard_action.dart';
import '../../widgets/module_dashboard_header.dart';
import '../../widgets/module_dashboard_panel.dart';
import '../../widgets/module_dashboard_section_header.dart';
import '../dashboard/charts/pie_chart.dart';
import '../logs/logging/log_table.dart';
import '../sidemenu/pane_items.dart';
import 'document/chauf_document_form.dart';
import 'document/chauf_document_tabs.dart';
import 'manager/chauffeur_form.dart';
import 'manager/chauffeur_tabs.dart';

class ConducteurDashboard extends StatelessWidget {
  const ConducteurDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const panelHeight = 380.0;
    final actions = <Widget>[
      ModuleDashboardAction(
        label: 'gchauffeurs'.tr(),
        detail: 'Consulter les conducteurs',
        icon: FluentIcons.people,
        onPressed: () => PaneItemsAndFooters.selectPane('driver-manager'),
      ),
      ModuleDashboardAction(
        label: 'nouvchauf'.tr(),
        detail: 'Ajouter un conducteur',
        icon: FluentIcons.add_friend,
        onPressed: () {
          if (!PaneItemsAndFooters.selectPane('driver-manager')) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
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
            ChauffeurTabsState.tabs.add(tab);
            ChauffeurTabsState.currentIndex.value =
                ChauffeurTabsState.tabs.length;
          });
        },
      ),
      ModuleDashboardAction(
        label: 'disponibilite'.tr(),
        detail: 'Voir les disponibilités',
        icon: FluentIcons.health,
        onPressed: () =>
            PaneItemsAndFooters.selectPane('driver-availability'),
      ),
      ModuleDashboardAction(
        label: 'documents'.tr(),
        detail: 'Consulter les dossiers conducteurs',
        icon: FluentIcons.document_set,
        onPressed: () =>
            PaneItemsAndFooters.selectPane('driver-documents'),
      ),
      ModuleDashboardAction(
        label: 'nouvdocument'.tr(),
        detail: 'Ajouter un document',
        icon: FluentIcons.document,
        onPressed: () {
          if (!PaneItemsAndFooters.selectPane('driver-documents')) return;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            late Tab tab;
            tab = Tab(
              key: UniqueKey(),
              text: Text('nouvdocument'.tr()),
              semanticLabel: 'nouvdocument'.tr(),
              icon: const Icon(FluentIcons.new_folder),
              body: const ScaffoldPage(content: CDocumentForm()),
              onClosed: () {
                CDocumentTabsState.tabs.remove(tab);
                if (CDocumentTabsState.currentIndex.value > 0) {
                  CDocumentTabsState.currentIndex.value--;
                }
              },
            );
            CDocumentTabsState.tabs.add(tab);
            CDocumentTabsState.currentIndex.value =
                CDocumentTabsState.tabs.length;
          });
        },
      ),
      ModuleDashboardAction(
        label: 'archive'.tr(),
        detail: 'Consulter les conducteurs archivés',
        icon: FluentIcons.archive,
        onPressed: () => PaneItemsAndFooters.selectPane('driver-archive'),
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
                title: 'chauffeurs'.tr(),
                subtitle:
                    'Gérez les conducteurs, leurs disponibilités et leurs documents.',
                eyebrow: 'Fleet / People',
                heroTitle: 'Centre de gestion des conducteurs',
                heroDescription:
                    'Consultez les équipes, planifiez les disponibilités et gardez les dossiers conducteurs à jour.',
                icon: FluentIcons.people,
              ),
              const SizedBox(height: 24),
              ModuleDashboardSectionHeader(
                title: 'Gestion de votre équipe',
                subtitle:
                    'Accédez aux conducteurs, aux disponibilités et aux dossiers administratifs.',
              ),
              Wrap(spacing: 12, runSpacing: 12, children: actions),
              const SizedBox(height: 30),
              ModuleDashboardSectionHeader(
                title: 'Activité et disponibilité',
                subtitle:
                    'Suivez les derniers mouvements et la répartition des conducteurs.',
              ),
              StaggeredGrid.count(
                crossAxisCount: compact ? 1 : 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                children: [
                  StaggeredGridTile.fit(
                    crossAxisCellCount: 1,
                    child: ModuleDashboardPanel(
                      title: 'Derniers mouvements',
                      height: panelHeight,
                      child: const LogTable(
                        statTable: true,
                        pages: false,
                        numberOfRows: 3,
                        filters: {'typemin': '16', 'typemax': '25'},
                        fieldsToShow: ['act', 'date'],
                      ),
                    ),
                  ),
                  StaggeredGridTile.fit(
                    crossAxisCellCount: 1,
                    child: ModuleDashboardPanel(
                      title: 'Répartition des disponibilités',
                      height: panelHeight,
                      child: ParcOtoPie(
                        labels: [
                          MapEntry(
                            'disponible',
                            DatabaseCounters().countChauffeur(etat: 0),
                          ),
                          MapEntry(
                            'absent',
                            DatabaseCounters().countChauffeur(etat: 1),
                          ),
                          MapEntry(
                            'mission',
                            DatabaseCounters().countChauffeur(etat: 2),
                          ),
                          MapEntry(
                            'quitteentre',
                            DatabaseCounters().countChauffeur(etat: 3),
                          ),
                        ],
                      ),
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
