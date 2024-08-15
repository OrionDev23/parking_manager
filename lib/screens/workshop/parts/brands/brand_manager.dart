import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../../../widgets/button_container.dart';
import '../../../../widgets/page_header.dart';
import 'brand_form.dart';
import 'brand_table.dart';
import 'brand_tabs.dart';
class BrandManager extends StatelessWidget {
  const BrandManager({super.key,});

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
              addBrand();
            },
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: getTable(),
        ));
  }

  String getTitle() {
    return 'brands';
  }

  void addBrand() {
    final index = BrandTabsState.tabs.length + 1;
    final tab = generateTab(index);
    BrandTabsState.tabs.add(tab);
    BrandTabsState.currentIndex.value = index - 1;
  }

  Widget getTable() {
    return const BrandTable();
  }

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvbrand'.tr()),
      semanticLabel: 'nouvbrand'.tr(),
      icon: const Icon(FluentIcons.document),
      body: const BrandForm(),
      onClosed: () {
        BrandTabsState.tabs.remove(tab);

        if (BrandTabsState.currentIndex.value > 0) {
          BrandTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }
}
