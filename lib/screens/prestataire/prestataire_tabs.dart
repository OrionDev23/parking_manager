
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/prestataire/prestataire_form.dart';
import 'package:parc_oto/screens/prestataire/prestataire_gestion.dart';



class PrestataireTabs extends StatefulWidget {
  final bool archive;
  const PrestataireTabs({super.key,this.archive=false});

  @override
  PrestataireTabsState createState() => PrestataireTabsState();
}

class PrestataireTabsState extends State<PrestataireTabs> {
  static ValueNotifier<int> currentIndex=ValueNotifier(0);
  static ValueNotifier<int> currentIndex2=ValueNotifier(0);
  static List<Tab> tabs = [];
  static List<Tab> tabs2 = [];

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvprest'.tr()),
      semanticLabel: 'nouvprest'.tr(),
        icon: const Icon(FluentIcons.shop),
      body: const PrestataireForm(),
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
    if(widget.archive){
      currentIndex2.value=0;
      if(tabs2.isEmpty){
        tabs2.add(Tab(
          text: Text('prestataires'.tr()),
          closeIcon: null,
          icon: const Icon(FluentIcons.settings),
          body:  PrestataireGestion(archive: widget.archive,),
          onClosed: null,
        ));
      }
    }
    else{
      currentIndex.value=0;
      if(tabs.isEmpty){
        tabs.add(Tab(
          text: Text('prestataires'.tr()),
          closeIcon: null,
          icon: const Icon(FluentIcons.settings),
          body:  PrestataireGestion(archive: widget.archive,),
          onClosed: null,
        ));
      }
    }
    super.initState();
  }
  @override
  Widget build(BuildContext context) {

    return ValueListenableBuilder(
        valueListenable: widget.archive?currentIndex2:currentIndex,
        builder: (context,value,_) {
          return TabView(
            tabs:  widget.archive?tabs2:tabs,
            currentIndex: value,
            onChanged: (index) =>   widget.archive?currentIndex2.value=index:currentIndex.value = index,
            tabWidthBehavior: TabWidthBehavior.equal,
            closeButtonVisibility: CloseButtonVisibilityMode.always,
            showScrollButtons: true,
            onNewPressed:widget.archive?null: () {
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
                if(widget.archive){
                  final item = tabs2.removeAt(oldIndex);
                  tabs2.insert(newIndex, item);

                  if (currentIndex2.value == newIndex) {
                    currentIndex2.value = oldIndex;
                  } else if (currentIndex2.value == oldIndex) {
                    currentIndex2.value = newIndex;
                  }
                }
                else{
                  final item = tabs.removeAt(oldIndex);
                  tabs.insert(newIndex, item);

                  if (currentIndex.value == newIndex) {
                    currentIndex.value = oldIndex;
                  } else if (currentIndex.value == oldIndex) {
                    currentIndex.value = newIndex;
                  }
                }

              });
            },
          );
        }
    );
  }
}
