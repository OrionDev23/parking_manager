import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../../../widgets/button_container.dart';
import '../../../../widgets/page_header.dart';
import 'category_form.dart';
import 'category_table.dart';
import 'category_tabs.dart';
class CategoryManager extends StatelessWidget {
  const CategoryManager({super.key,});

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
              addCategory();
            },
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: getTable(),
        ));
  }

  String getTitle() {
    return 'categories';
  }

  void addCategory() {
    final index = CategoryTabsState.tabs.length + 1;
    final tab = generateTab(index);
    CategoryTabsState.tabs.add(tab);
    CategoryTabsState.currentIndex.value = index - 1;
  }

  Widget getTable() {
    return const CategoryTable();
  }

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvcategory'.tr()),
      semanticLabel: 'nouvcategory'.tr(),
      icon: const Icon(FluentIcons.document),
      body: const CategoryForm(),
      onClosed: () {
        CategoryTabsState.tabs.remove(tab);

        if (CategoryTabsState.currentIndex.value > 0) {
          CategoryTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }
}
