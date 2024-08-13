import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/workshop/parts/options/option_form.dart';

import '../../../../widgets/button_container.dart';
import '../../../../widgets/page_header.dart';
import 'option_table.dart';
import 'option_tabs.dart';
class OptionManager extends StatelessWidget {
  const OptionManager({super.key,});

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
    return 'options';
  }

  void addOption() {
    final index = OptionTabsState.tabs.length + 1;
    final tab = generateTab(index);
    OptionTabsState.tabs.add(tab);
    OptionTabsState.currentIndex.value = index - 1;
  }

  Widget getTable() {
    return const OptionTable();
  }

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvoption'.tr()),
      semanticLabel: 'nouvoption'.tr(),
      icon: const Icon(FluentIcons.document),
      body: const OptionForm(),
      onClosed: () {
        OptionTabsState.tabs.remove(tab);

        if (OptionTabsState.currentIndex.value > 0) {
          OptionTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }
}
