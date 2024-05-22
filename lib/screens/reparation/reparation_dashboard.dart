import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../theme.dart';
import '../../widgets/button_container.dart';
import '../../widgets/page_header.dart';
import '../logs/logging/log_table.dart';
import '../prestataire/prestataire_form.dart';
import '../prestataire/prestataire_tabs.dart';
import '../sidemenu/pane_items.dart';
import '../sidemenu/sidemenu.dart';
import 'manager/reparation_tabs.dart';
import 'reparation_form/reparation_form.dart';

class ReparationDashboard extends StatelessWidget {
  const ReparationDashboard({super.key});

  final int indexAdition = 4;

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    bool portrait=Device.orientation==Orientation.portrait;
    return ScaffoldPage(
      padding: const EdgeInsets.all(10),
      header: PageTitle(
        text: 'reparations'.tr(),
      ),
      content: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          StaggeredGrid.count(
            crossAxisCount:
            portrait?2 : 4,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            children: [
              ButtonContainer(
                color: appTheme.color,
                action: () {
                  PanesListState.index.value = PaneItemsAndFooters
                          .originalItems
                          .indexOf(PaneItemsAndFooters.reparations) +
                      1 +
                      indexAdition;
                },
                icon: FluentIcons.list,
                text: 'greparations'.tr(),
                showBothLN: false,
                showBottom: false,
                showCounter: false,
              ),
              ButtonContainer(
                action: () {
                  PanesListState.index.value = PaneItemsAndFooters
                          .originalItems
                          .indexOf(PaneItemsAndFooters.reparations) +
                      1 +
                      indexAdition;
                  Future.delayed(const Duration(milliseconds: 300))
                      .whenComplete(() {
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
                color: appTheme.color,
                icon: FluentIcons.repair,
                text: 'nouvrepar'.tr(),
                showBothLN: false,
                showBottom: false,
                showCounter: false,
              ),
              ButtonContainer(
                color: appTheme.color,
                action: () {
                  PanesListState.index.value = PaneItemsAndFooters
                          .originalItems
                          .indexOf(PaneItemsAndFooters.reparations) +
                      2 +
                      indexAdition;
                },
                icon: FluentIcons.list,
                text: 'prestataires'.tr(),
                showBothLN: false,
                showBottom: false,
                showCounter: false,
              ),
              ButtonContainer(
                action: () {
                  PanesListState.index.value = PaneItemsAndFooters
                          .originalItems
                          .indexOf(PaneItemsAndFooters.reparations) +
                      2 +
                      indexAdition;
                  Future.delayed(const Duration(milliseconds: 300))
                      .whenComplete(() {
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
                color: appTheme.color,
                icon: FluentIcons.service_activity,
                text: 'nouvprest'.tr(),
                showBothLN: false,
                showBottom: false,
                showCounter: false,
              ),
            ],
          ),
          bigSpace,
          SizedBox(
            height: 380.px,
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
                    filters: {'typemin': '10', 'typemax': '15'},
                    fieldsToShow: ['act', 'date'],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
