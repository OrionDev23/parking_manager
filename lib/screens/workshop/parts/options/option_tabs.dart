import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'option_manager.dart';

import 'option_form.dart';

class OptionTabs extends StatefulWidget {
  final bool archive;

  const OptionTabs({super.key, this.archive = false});

  @override
  OptionTabsState createState() => OptionTabsState();
}

class OptionTabsState extends State<OptionTabs> {
  static ValueNotifier<int> currentIndex = ValueNotifier(0);
  static List<Tab> tabs = [];
  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvoption'.tr()),
      semanticLabel: 'nouvoption'.tr(),
      icon: const Icon(FluentIcons.shop),
      body: const OptionForm(),
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

  String getTitle() {
    return 'options';
  }

  Widget getGestionnaire() {
    return const OptionManager(
    );
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

  void initValues() {
      addTab1();
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
            onNewPressed: widget.archive
                ? null
                : () {
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
