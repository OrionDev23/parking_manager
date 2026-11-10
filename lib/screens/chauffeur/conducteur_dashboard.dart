import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../admin_parameters.dart';
import '../../providers/counters.dart';
import '../../theme.dart';
import '../../widgets/module_dashboard_action.dart';
import '../../widgets/module_dashboard_header.dart';
import '../../widgets/module_dashboard_section_header.dart';
import '../../widgets/module_dashboard_panel.dart';
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
    var appTheme = context.watch<AppTheme>();
    bool portrait = Device.orientation == Orientation.portrait;
    double height = 380.px;
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
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
          const SizedBox(height: 26),
          ModuleDashboardSectionHeader(
            title: 'Actions courantes',
            subtitle: 'Gérez les conducteurs, leurs dossiers et les actions administratives courantes.',
          ),
          Text(
            'Accès rapides',
            style: TextStyle(
              color: appTheme.writingStyle.color,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ModuleDashboardAction(
            label: 'gchauffeurs'.tr(),
            detail: 'Accès et gestion',
            icon: FluentIcons.list,
            onPressed: () {
                  PaneItemsAndFooters.selectPane('driver-manager');
                },
          ),
              ModuleDashboardAction(
            label: 'nouvchauf'.tr(),
            detail: 'Créer un nouvel élément',
            icon: FluentIcons.car,
            onPressed: () {
                  PaneItemsAndFooters.selectPane('driver-manager');
                  Future.delayed(const Duration(milliseconds: 300))
                      .whenComplete(() {
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
          ),
              ModuleDashboardAction(
            label: 'disponibilite'.tr(),
            detail: 'Disponibilités et planning',
            icon: FluentIcons.health,
            onPressed: () {
                  PaneItemsAndFooters.selectPane('driver-availability');
                },
          ),
              ModuleDashboardAction(
            label: 'documents'.tr(),
            detail: 'Documents et dossiers',
            icon: FluentIcons.document_set,
            onPressed: () {
                  PaneItemsAndFooters.selectPane('driver-documents');
                },
          ),
              ModuleDashboardAction(
            label: 'nouvdocument'.tr(),
            detail: 'Créer un nouvel élément',
            icon: FluentIcons.document,
            onPressed: () {
                  PaneItemsAndFooters.selectPane('driver-documents');
                  Future.delayed(const Duration(milliseconds: 400))
                      .whenComplete(() {
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
                        final index = CDocumentTabsState.tabs.length + 1;
                        CDocumentTabsState.tabs.add(tab);
                        CDocumentTabsState.currentIndex.value = index - 1;
                      });
                },
          ),
              ModuleDashboardAction(
            label: 'archive'.tr(),
            detail: 'Éléments archivés',
            icon: FluentIcons.list,
            onPressed: () {
                  PaneItemsAndFooters.selectPane('driver-archive');
                },
          ),
            ]
          const SizedBox(height: 28),
          ModuleDashboardSectionHeader(
            title: 'Équipe et disponibilité',
            subtitle: 'Consultez les mouvements récents et la répartition des disponibilités.',
          ),

          StaggeredGrid.count(
            crossAxisCount: portrait ? 1 : 2,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            children: [
              StaggeredGridTile.fit(
                crossAxisCellCount: 1,
                child: ModuleDashboardPanel(
                  title: 'Activité récente',
                  height: height,
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
                  title: 'Disponibilité',
                  height: height,
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
          const SizedBox(height: 28),
,
          ),
        ],
      ),
    );
  }
}
