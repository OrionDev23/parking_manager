import 'package:adv_log_fact/screens/chauffeur/chauffeur_form.dart';
import 'package:adv_log_fact/screens/chauffeur/chauffeur_list.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../../main.dart';

class ChauffeurTabs extends StatefulWidget {
  const ChauffeurTabs({Key? key}) : super(key: key);

  @override
  State<ChauffeurTabs> createState() => ChauffeurTabsState();
}

class ChauffeurTabsState extends State<ChauffeurTabs> {
  static List<Tab> tabs = [
    Tab(
      text: const Text('Liste des Chauffeurs'),
      body: const ChauffeurList(),
      icon: const Icon(FluentIcons.delivery_truck),
      semanticLabel: 'Chauffeur list',
      onClosed: null,
      closeIcon: null,
    ),
  ];
  static int currentIndex = 0;
  static ValueNotifier<int> changing = ValueNotifier(0);
  Tab generateTab(int index) {
    Tab? tab;
    tab = Tab(
      text: const Text('Nouveau chauffeur'),
      body: ChauffeurForm(),
      icon: const Icon(FluentIcons.switch_user),
      semanticLabel: 'Nouveau chauffeur',
      onClosed: () {
        setState(() {
          tabs.remove(tab);
          if (currentIndex > 0) currentIndex--;
        });
      },
    );
    return tab;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: changing,
      builder: (c, v, w) {
        return ScaffoldPage(
          content: Card(
            child: TabView(
              currentIndex: currentIndex,
              tabs: tabs,
              onChanged: (index) => setState(() => currentIndex = index),
              tabWidthBehavior: TabWidthBehavior.equal,
              closeButtonVisibility: CloseButtonVisibilityMode.always,
              onNewPressed: MyAppState.userType.value == 0 ||
                      MyAppState.userType.value == 3
                  ? () {
                      tabs.add(generateTab(tabs.length));
                      setState(() {
                        currentIndex = tabs.length - 1;
                      });
                    }
                  : null,
            ),
          ),
        );
      },
    );
  }
}
