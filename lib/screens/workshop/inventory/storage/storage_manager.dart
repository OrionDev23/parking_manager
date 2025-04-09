import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'storage_form.dart';
import 'storage_tabs.dart';

import '../../../../widgets/button_container.dart';
import '../../../../widgets/page_header.dart';
import 'storage_table.dart';

class StorageManager extends StatelessWidget{
  const StorageManager({super.key});

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
    return 'stock';
  }

  void addOption() {
    final index = StorageTabsState.tabs.length + 1;
    final tab = generateTab(index);
    StorageTabsState.tabs.add(tab);
    StorageTabsState.currentIndex.value = index - 1;
  }

  Widget getTable() {
    return const StorageTable();
  }

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvstock'.tr()),
      semanticLabel: 'nouvstock'.tr(),
      icon: const Icon(FluentIcons.document),
      body: const StorageForm(),
      onClosed: () {
        StorageTabsState.tabs.remove(tab);

        if (StorageTabsState.currentIndex.value > 0) {
          StorageTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }

}