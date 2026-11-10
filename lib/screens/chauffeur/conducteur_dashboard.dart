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
import '../dashboard/charts/pie_chart.dart';
import '../logs/logging/log_table.dart';
import '../sidemenu/pane_items.dart';
import '../sidemenu/sidemenu.dart';
import 'document/chauf_document_form.dart';
import 'document/chauf_document_tabs.dart';
import 'manager/chauffeur_form.dart';
import 'manager/chauffeur_tabs.dart';

class ConducteurDashboard extends StatelessWidget {
  const ConducteurDashboard({super.key});

  final int indexAdition = 6;

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    bool portrait = Device.orientation == Orientation.portrait;
    double height = 380.px;
    return ScaffoldPage(
      padding: EdgeInsets.zero,
      content: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
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
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ModuleDashboardAction(
            label: 'gchauffeurs'.tr(),
            detail: 'Accès et gestion',
            icon: FluentIcons.list,
            onPressed: () {
                  PanesListState.index.value =
                      PaneItemsAndFooters.originalItems.indexOf(
                        PaneItemsAndFooters.chauffeurs,
                      ) +
                      PaneItemsAndFooters.vehicles.items.length +
                      PaneItemsAndFooters.reparations.items.length +
                      (showAtelier
                          ? PaneItemsAndFooters.atelier.items.length
                          : 0) -
                      1;
                },
          ),
              ModuleDashboardAction(
            label: 'nouvchauf'.tr(),
            detail: 'Créer un nouvel élément',
            icon: FluentIcons.car,
            onPressed: () {
                  PanesListState.index.value =
                      PaneItemsAndFooters.originalItems.indexOf(
                        PaneItemsAndFooters.chauffeurs,
                      ) +
                      PaneItemsAndFooters.vehicles.items.length +
                      PaneItemsAndFooters.reparations.items.length +
                      (showAtelier
                          ? PaneItemsAndFooters.atelier.items.length
                          : 0) -
                      1;
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
                  PanesListState.index.value =
                      PaneItemsAndFooters.originalItems.indexOf(
                        PaneItemsAndFooters.chauffeurs,
                      ) +
                      PaneItemsAndFooters.vehicles.items.length +
                      PaneItemsAndFooters.reparations.items.length +
                      (showAtelier
                          ? PaneItemsAndFooters.atelier.items.length
                          : 0);
                },
          ),
              ModuleDashboardAction(
            label: 'documents'.tr(),
            detail: 'Documents et dossiers',
            icon: FluentIcons.document_set,
            onPressed: () {
                  PanesListState.index.value =
                      PaneItemsAndFooters.originalItems.indexOf(
                        PaneItemsAndFooters.chauffeurs,
                      ) +
                      PaneItemsAndFooters.vehicles.items.length +
                      PaneItemsAndFooters.reparations.items.length +
                      (showAtelier
                          ? PaneItemsAndFooters.atelier.items.length
                          : 0) +
                      1;
                },
          ),
              ModuleDashboardAction(
            label: 'nouvdocument'.tr(),
            detail: 'Créer un nouvel élément',
            icon: FluentIcons.document,
            onPressed: () {
                  PanesListState.index.value =
                      PaneItemsAndFooters.originalItems.indexOf(
                        PaneItemsAndFooters.chauffeurs,
                      ) +
                      PaneItemsAndFooters.vehicles.items.length +
                      PaneItemsAndFooters.reparations.items.length +
                      (showAtelier
                          ? PaneItemsAndFooters.atelier.items.length
                          : 0) +
                      1;
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
                  PanesListState.index.value =
                      PaneItemsAndFooters.originalItems.indexOf(
                        PaneItemsAndFooters.chauffeurs,
                      ) +
                      PaneItemsAndFooters.vehicles.items.length +
                      PaneItemsAndFooters.reparations.items.length +
                      (showAtelier
                          ? PaneItemsAndFooters.atelier.items.length
                          : 0) +
                      2;
                },
          ),
            ],
          ),
          bigSpace,
          StaggeredGrid.count(
            crossAxisCount: portrait ? 1 : 2,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            children: [
              StaggeredGridTile.fit(
                crossAxisCellCount: 1,
                child: SizedBox(
                  height: height,
                  child: Column(
                    children: [
                      Text(
                        'lactivities',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: appTheme.writingStyle.color,
                        ),
                      ).tr(),
                      smallSpace,
                      const Flexible(
                        child: LogTable(
                          statTable: true,
                          pages: false,
                          numberOfRows: 3,
                          filters: {'typemin': '16', 'typemax': '25'},
                          fieldsToShow: ['act', 'date'],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              smallSpace,
              StaggeredGridTile.fit(
                crossAxisCellCount: 1,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  height: height,
                  child: ParcOtoPie(
                    title: 'disponibilite'.tr(),
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
      ),
    );
  }
}
