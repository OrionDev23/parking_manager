import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../../../widgets/button_container.dart';
import '../../../../widgets/page_header.dart';
import 'prestataire_form.dart';
import 'prestataire_table.dart';
import 'prestataire_tabs.dart';

class PrestataireGestion extends StatelessWidget {
  final bool archive;

  const PrestataireGestion({super.key, this.archive = false});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
        header: PageTitle(
          text: getTitle().tr(),
          trailing: archive
              ? null
              : ButtonContainer(
            icon: FluentIcons.add,
            text: 'add'.tr(),
            showBottom: false,
            showCounter: false,
            action: () {
              addPrestataire();
            },
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: getTable(),
        ));
  }

  String getTitle() {
    return 'prestataires';
  }

  void addPrestataire() {
    final index = PrestataireTabsState.tabs.length + 1;
    final tab = generateTab(index);
    PrestataireTabsState.tabs.add(tab);
    PrestataireTabsState.currentIndex.value = index - 1;
  }

  Widget getTable() {
    return PrestataireTable(
      archive: archive,
    );
  }

  Tab generateTab(int index) {
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
    return tab;
  }
}
