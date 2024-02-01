import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'state_manager.dart';

class StateTabs extends StatefulWidget {
  const StateTabs({super.key});

  @override
  StateTabsState createState() => StateTabsState();
}

class StateTabsState extends State<StateTabs> {
  static ValueNotifier<int> currentIndex = ValueNotifier(0);
  static List<Tab> tabs = [];

  @override
  void initState() {
    currentIndex.value = 0;
    if (tabs.isEmpty) {
      tabs.add(Tab(
        text: Text('vstates'.tr()),
        closeIcon: null,
        icon: const Icon(FluentIcons.settings),
        body: const EtatManager(),
        onClosed: null,
      ));
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: currentIndex,
        builder: (context, value, _) {
          return TabView(
            tabs: tabs,
            currentIndex: value,
            onChanged: (index) => currentIndex.value = index,
            tabWidthBehavior: TabWidthBehavior.equal,
            closeButtonVisibility: CloseButtonVisibilityMode.always,
            showScrollButtons: true,
            onNewPressed: null,
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
