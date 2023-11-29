
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:parc_oto/screens/chauffeur/manager/chauffeur_form.dart';

import 'chauffeur_gestion.dart';


class ChauffeurTabs extends StatefulWidget {
  final bool archive;
  const ChauffeurTabs({super.key,this.archive=false});

  @override
  ChauffeurTabsState createState() => ChauffeurTabsState();
}

class ChauffeurTabsState extends State<ChauffeurTabs> {
  static ValueNotifier<int> currentIndex=ValueNotifier(0);
  static ValueNotifier<int> currentIndex2=ValueNotifier(0);
  static List<Tab> tabs = [];
  static List<Tab> tabs2 = [];

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvchauf'.tr()),
      semanticLabel: 'nouvchauf'.tr(),
      icon: const Icon(Bootstrap.car_front),
      body: const ChauffeurForm(),
      onClosed: () {
        if(widget.archive){
          tabs2.remove(tab);
          if (currentIndex2.value > 0) currentIndex2.value--;
        }
        else{
          tabs.remove(tab);

          if (currentIndex.value > 0) currentIndex.value--;
        }

      },
    );
    return tab;
  }

  @override
  void initState() {
    if(archive){
      currentIndex2.value=0;
    }
    else{
      currentIndex.value=0;
    }
    currentIndex.value=0;
    if(tabs.isEmpty){
      tabs.add(Tab(
        text: Text('gchauffeurs'.tr()),
        closeIcon: null,
        icon: const Icon(IonIcons.settings),
        body:  ChauffeurGestion(archive: widget.archive,),
        onClosed: null,
      ));
    }
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
                currentIndex.value=index-1;
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
