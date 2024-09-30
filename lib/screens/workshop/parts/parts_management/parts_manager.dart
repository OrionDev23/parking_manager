import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'parts_form.dart';

import '../../../../widgets/button_container.dart';
import '../../../../widgets/page_header.dart';
import 'parts_table.dart';
import 'parts_tabs.dart';
class PartsManager extends StatelessWidget {
  const PartsManager({super.key,});

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
        header: PageTitle(
          text: getTitle().tr(),
          trailing: ButtonContainer(
            icon: FluentIcons.add,
            text: 'add'.tr(),
            showBottom: false,
            showCounter: false,
            action: () {
              addOption();
            },
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: getTable(),
        ));
  }

  String getTitle() {
    return 'gpieces';
  }

  void addOption() {
    final index = PartTabsState.tabs.length + 1;
    final tab = generateTab(index);
    PartTabsState.tabs.add(tab);
    PartTabsState.currentIndex.value = index - 1;
  }

  Widget getTable() {
    return const PartsTable();
  }

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvpart'.tr()),
      semanticLabel: 'nouvpart'.tr(),
      icon: const Icon(FluentIcons.document),
      body: const PartsForm(),
      onClosed: () {
        PartTabsState.tabs.remove(tab);

        if (PartTabsState.currentIndex.value > 0) {
          PartTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }
}
