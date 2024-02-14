import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../widgets/button_container.dart';
import '../../../widgets/page_header.dart';
import 'document_form.dart';
import 'document_table.dart';
import 'document_tabs.dart';

class VehiculeDocuments extends StatefulWidget {
  const VehiculeDocuments({super.key});

  @override
  VehiculeDocumentsState createState() => VehiculeDocumentsState();
}

class VehiculeDocumentsState extends State<VehiculeDocuments> {
  final tstyle = TextStyle(
    fontSize: 10.sp,
  );

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageTitle(
        text: 'gestiondocument'.tr(),
        trailing: ButtonContainer(
          icon: FluentIcons.add,
          text: 'add'.tr(),
          showBottom: false,
          showCounter: false,
          action: () {
            final index = DocumentTabsState.tabs.length + 1;
            final tab = generateTab(index);
            DocumentTabsState.tabs.add(tab);
            DocumentTabsState.currentIndex.value = index - 1;
          },
        ),
      ),
      content: const DocumentTable(),
    );
  }

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvdocument'.tr()),
      semanticLabel: 'nouvdocument'.tr(),
      icon: const Icon(FluentIcons.document),
      body:  const ScaffoldPage(
        content: DocumentForm(),
      ),
      onClosed: () {
        DocumentTabsState.tabs.remove(tab);

        if (DocumentTabsState.currentIndex.value > 0) {
          DocumentTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }
}
