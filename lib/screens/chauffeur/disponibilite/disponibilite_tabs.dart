import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/chauffeur/disponibilite/disponibilite_gestion.dart';

class DisponbiliteTabs extends StatefulWidget {
  const DisponbiliteTabs({super.key});

  @override
  DisponbiliteTabsState createState() => DisponbiliteTabsState();
}

class DisponbiliteTabsState extends State<DisponbiliteTabs> {
  static ValueNotifier<int> currentIndex = ValueNotifier(0);
  static List<Tab> tabs = [];

  @override
  void initState() {
    currentIndex.value = 0;
    if (tabs.isEmpty) {
      tabs.add(Tab(
        text: Text('disponibilite'.tr()),
        closeIcon: null,
        icon: const Icon(FluentIcons.settings),
        body: const DisponibiliteGestion(),
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
