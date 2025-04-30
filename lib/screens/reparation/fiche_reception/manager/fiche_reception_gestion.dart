import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../../widgets/button_container.dart';
import '../../../../../widgets/page_header.dart';
import '../form/fiche_reception_form.dart';
import 'fiche_reception_table.dart';
import 'fiche_reception_tabs.dart';

class FicheReceptionGestion extends StatefulWidget {
  final bool archive;

  const FicheReceptionGestion({super.key, this.archive = false});

  @override
  FicheReceptionGestionState createState() => FicheReceptionGestionState();
}

class FicheReceptionGestionState extends State<FicheReceptionGestion> {
  final tstyle = TextStyle(
    fontSize: 10.sp,
  );

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
        header: PageTitle(
          text: 'fichesreception'.tr(),
          trailing: widget.archive
              ? null
              : ButtonContainer(
            icon: FluentIcons.add,
            text: 'add'.tr(),
            showBottom: false,
            showCounter: false,
            action: () {
              final index = FicheReceptionTabsState.tabs.length + 1;
              final tab = generateTab(index);
              FicheReceptionTabsState.tabs.add(tab);
              FicheReceptionTabsState.currentIndex.value = index - 1;
            },
          ),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: FicheReceptionTable(
            archive: widget.archive,
          ),
        ));
  }

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvfiche'.tr()),
      semanticLabel: 'nouvfiche'.tr(),
      icon: const Icon(FluentIcons.document),
      body: FicheReceptionForm(
        key: UniqueKey(),
      ),
      onClosed: () {
        FicheReceptionTabsState.tabs.remove(tab);

        if (FicheReceptionTabsState.currentIndex.value > 0) {
          FicheReceptionTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }
}
