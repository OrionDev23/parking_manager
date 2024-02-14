import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/prestataire/prestataire_form.dart';
import 'package:parc_oto/screens/prestataire/prestataire_table.dart';
import 'package:parc_oto/screens/prestataire/prestataire_tabs.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../widgets/button_container.dart';
import '../../../../widgets/page_header.dart';

class PrestataireGestion extends StatefulWidget {
  final bool archive;

  const PrestataireGestion({super.key, this.archive = false});

  @override
  PrestataireGestionState createState() => PrestataireGestionState();
}

class PrestataireGestionState extends State<PrestataireGestion> {
  final tstyle = TextStyle(
    fontSize: 10.sp,
  );

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
        header: PageTitle(
          text: 'prestataires'.tr(),
          trailing: widget.archive
              ? null
              : ButtonContainer(
                icon: FluentIcons.add,
                text: 'add'.tr(),
                showBottom: false,
                showCounter: false,
                action: () {
                  final index = PrestataireTabsState.tabs.length + 1;
                  final tab = generateTab(index);
                  PrestataireTabsState.tabs.add(tab);
                  PrestataireTabsState.currentIndex.value = index - 1;
                },
              ),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: PrestataireTable(
            archive: widget.archive,
          ),
        ));
  }

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvprest'.tr()),
      semanticLabel: 'nouvprest'.tr(),
      icon: const Icon(FluentIcons.document),
      body: const PrestataireForm(),
      onClosed: () {
        PrestataireTabsState.tabs.remove(tab);

        if (PrestataireTabsState.currentIndex.value > 0) {
          PrestataireTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }
}
