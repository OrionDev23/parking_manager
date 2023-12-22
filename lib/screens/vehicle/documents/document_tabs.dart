
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/vehicle/documents/vehicule_documents.dart';

import 'document_form.dart';

class DocumentTabs extends StatefulWidget {
  const DocumentTabs({super.key});

  @override
  DocumentTabsState createState() => DocumentTabsState();
}

class DocumentTabsState extends State<DocumentTabs> {
  static ValueNotifier<int> currentIndex=ValueNotifier(0);
  static List<Tab> tabs = [];

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvdocument'.tr()),
      semanticLabel: 'nouvdocument'.tr(),
      icon: const Icon(FluentIcons.new_folder),
      body: const DocumentForm(),
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
    if(tabs.isEmpty){
      tabs.add(Tab(
        text: Text('gestiondocument'.tr()),
        closeIcon: null,
        icon: const Icon(FluentIcons.settings),
        body: const VehiculeDocuments(),
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
