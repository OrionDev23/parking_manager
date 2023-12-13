import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/reparation/reparation_form.dart';
import 'package:parc_oto/screens/reparation/reparation_table.dart';
import 'package:parc_oto/screens/reparation/reparation_tabs.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../../../widgets/button_container.dart';
import '../../../../widgets/page_header.dart';

class ReparationGestion extends StatefulWidget {
  final bool archive;
  const ReparationGestion({super.key,this.archive=false});

  @override
  ReparationGestionState createState() => ReparationGestionState();
}

class ReparationGestionState extends State<ReparationGestion> {
  final tstyle=TextStyle(
    fontSize: 10.sp,
  );



  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
        header: PageTitle(
          text: 'reparations'.tr(),
          trailing: widget.archive?null:SizedBox(
              width: 15.w,
              height: 10.h,
              child: ButtonContainer(
                icon: FluentIcons.add,
                text: 'add'.tr(),
                showBottom: false,
                showCounter: false,
                action: () {
                  final index = ReparationTabsState.tabs.length + 1;
                  final tab = generateTab(index);
                  ReparationTabsState.tabs.add(tab);
                  ReparationTabsState.currentIndex.value = index - 1;
                },
              )),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: ReparationTable(archive: widget.archive,),
        )
    );
  }

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvrepar'.tr()),
      semanticLabel: 'nouvrepar'.tr(),
      icon: const Icon(FluentIcons.document),
      body: ReparationForm(key: UniqueKey(),),
      onClosed: () {
        ReparationTabsState.tabs.remove(tab);

        if (ReparationTabsState.currentIndex.value > 0) {
          ReparationTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }
}
