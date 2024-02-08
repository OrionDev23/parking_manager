import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/counters.dart';
import '../../theme.dart';
import '../../widgets/button_container.dart';
import '../../widgets/page_header.dart';
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
      padding: const EdgeInsets.all(10),
      header: PageTitle(
        text: 'chauffeurs'.tr(),
      ),
      content: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          StaggeredGrid.count(
            crossAxisCount: portrait ? 2 : 4,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            children: [
              ButtonContainer(
                color: appTheme.color,
                action: () {
                  PanesListState.index.value = PaneItemsAndFooters.originalItems
                          .indexOf(PaneItemsAndFooters.chauffeurs) +
                      1 +
                      indexAdition;
                },
                icon: FluentIcons.list,
                text: 'gchauffeurs'.tr(),
                showBothLN: false,
                showBottom: false,
                showCounter: false,
              ),
              ButtonContainer(
                action: () {
                  PanesListState.index.value = PaneItemsAndFooters.originalItems
                          .indexOf(PaneItemsAndFooters.chauffeurs) +
                      1 +
                      indexAdition;
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
                color: appTheme.color,
                icon: FluentIcons.car,
                text: 'nouvchauf'.tr(),
                showBothLN: false,
                showBottom: false,
                showCounter: false,
              ),
              ButtonContainer(
                action: () {
                  PanesListState.index.value = PaneItemsAndFooters.originalItems
                          .indexOf(PaneItemsAndFooters.chauffeurs) +
                      2 +
                      indexAdition;
                },
                color: appTheme.color,
                icon: FluentIcons.health,
                text: 'disponibilite'.tr(),
                showBothLN: false,
                showBottom: false,
                showCounter: false,
              ),
              ButtonContainer(
                action: () {
                  PanesListState.index.value = PaneItemsAndFooters.originalItems
                          .indexOf(PaneItemsAndFooters.chauffeurs) +
                      3 +
                      indexAdition;
                },
                color: appTheme.color,
                icon: FluentIcons.document_set,
                text: 'documents'.tr(),
                showBothLN: false,
                showBottom: false,
                showCounter: false,
              ),
              ButtonContainer(
                action: () {
                  PanesListState.index.value = PaneItemsAndFooters.originalItems
                          .indexOf(PaneItemsAndFooters.chauffeurs) +
                      3 +
                      indexAdition;
                  Future.delayed(const Duration(milliseconds: 400))
                      .whenComplete(() {
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
                color: appTheme.color,
                icon: FluentIcons.document,
                text: 'nouvdocument'.tr(),
                showBothLN: false,
                showBottom: false,
                showCounter: false,
              ),
              ButtonContainer(
                color: appTheme.color,
                action: () {
                  PanesListState.index.value = PaneItemsAndFooters.originalItems
                          .indexOf(PaneItemsAndFooters.chauffeurs) +
                      4 +
                      indexAdition;
                },
                icon: FluentIcons.list,
                text: 'archive'.tr(),
                showBothLN: false,
                showBottom: false,
                showCounter: false,
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
                            color: appTheme.writingStyle.color),
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
                      MapEntry('disponible',
                          DatabaseCounters().countChauffeur(etat: 0)),
                      MapEntry(
                          'absent', DatabaseCounters().countChauffeur(etat: 1)),
                      MapEntry('mission',
                          DatabaseCounters().countChauffeur(etat: 2)),
                      MapEntry('quitteentre',
                          DatabaseCounters().countChauffeur(etat: 3))
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
