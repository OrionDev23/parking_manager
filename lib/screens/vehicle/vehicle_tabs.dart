import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:parc_oto/screens/vehicle/vehicle_form.dart';
import 'package:parc_oto/screens/vehicle/vehicle_management.dart';

class VehicleTabs extends StatefulWidget {
  const VehicleTabs({super.key});

  @override
  State<VehicleTabs> createState() => _VehicleTabsState();
}

class _VehicleTabsState extends State<VehicleTabs> {


  static ValueNotifier<int> currentIndex=ValueNotifier(0);
  List<Tab> tabs = [];

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      text: Text('${'nouvvehicule'.tr()} ${index-1}'),
      semanticLabel: '${'nouvvehicule'.tr()} ${index-1}',
      icon: const Icon(Bootstrap.car_front),
      body: const VehicleForm(),
      onClosed: () {
          tabs.remove(tab);

          if (currentIndex.value > 0) currentIndex.value--;
      },
    );
    return tab;
  }

  @override
  void initState() {
    currentIndex.value=0;
    tabs.add(Tab(
      text: Text('gestionvehicles'.tr()),
      closeIcon: null,
      icon: const Icon(IonIcons.settings),
      body: const VehicleManagement(),
      onClosed: null,
    ));
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    return ValueListenableBuilder(
      valueListenable: currentIndex,
      builder: (context,value,_) {
        return TabView(
          tabs: tabs,
          currentIndex: value,
          onChanged: (index) =>  currentIndex.value = index,
          tabWidthBehavior: TabWidthBehavior.equal,
          closeButtonVisibility: CloseButtonVisibilityMode.always,
          showScrollButtons: true,
          onNewPressed: () {
            setState(() {
              final index = tabs.length + 1;
              final tab = generateTab(index);
              tabs.add(tab);
              currentIndex.value=index;
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
      }
    );
  }
}
