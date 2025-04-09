import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'storage_form.dart';

import 'storage_manager.dart';

class StorageTabs extends StatefulWidget{
  const StorageTabs({super.key});
  @override
  State<StorageTabs> createState() => StorageTabsState();

}
class StorageTabsState extends State<StorageTabs> {
  static final List<Tab> tabs = [];
  static final ValueNotifier<int> currentIndex = ValueNotifier(0);

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvstock'.tr()),
      semanticLabel: 'nouvstock'.tr(),
      icon: const Icon(FluentIcons.shop),
      body: const StorageForm(),
      onClosed: () {
        tabs.remove(tab);
        if (currentIndex.value > 0) currentIndex.value--;
      },
    );
    return tab;
  }

  @override
  void initState() {
    initValues();
    super.initState();
  }

  void initValues() {
    addTab1();
  }


  String getTitle() {
    return 'stock';
  }

  Widget getGestionnaire() {
    return const StorageManager();
  }


  void addTab1() {
    currentIndex.value = 0;
    if (tabs.isEmpty) {
      tabs.add(Tab(
        text: Text(getTitle().tr()),
        closeIcon: null,
        icon: const Icon(FluentIcons.settings),
        body: getGestionnaire(),
        onClosed: null,
      ));
    }
  }
  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) {
      initValues();
    }
    return ValueListenableBuilder(
        valueListenable:  currentIndex,
        builder: (context, value, _) {
          return TabView(
            tabs:tabs,
            currentIndex: value,
            onChanged: (index) =>currentIndex.value = index,
            tabWidthBehavior: TabWidthBehavior.equal,
            closeButtonVisibility: CloseButtonVisibilityMode.always,
            showScrollButtons: true,
            onNewPressed: () {
              setState(() {
                final index = tabs.length + 1;
                final tab = generateTab(index);
                tabs.add(tab);
                currentIndex.value = index - 1;
              });
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = tabs.removeAt(oldIndex);
                tabs.insert(newIndex, item);

                if (currentIndex.value == newIndex) {
                  currentIndex.value = oldIndex;
                } else if (currentIndex.value == oldIndex) {
                  currentIndex.value = newIndex;
                }

              });
            },
          );
        });
  }



}