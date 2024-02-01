import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../widgets/button_container.dart';
import '../../../widgets/page_header.dart';
import 'chauf_document_form.dart';
import 'chauf_document_table.dart';
import 'chauf_document_tabs.dart';

class ChauffeurDocuments extends StatefulWidget {
  const ChauffeurDocuments({super.key});

  @override
  ChauffeurDocumentsState createState() => ChauffeurDocumentsState();
}

class ChauffeurDocumentsState extends State<ChauffeurDocuments> {
  final tstyle = TextStyle(
    fontSize: 10.sp,
  );

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageTitle(
        text: 'gestiondocument'.tr(),
        trailing: SizedBox(
            width: 15.w,
            height: 10.h,
            child: ButtonContainer(
              icon: FluentIcons.add,
              text: 'add'.tr(),
              showBottom: false,
              showCounter: false,
              action: () {
                final index = CDocumentTabsState.tabs.length + 1;
                final tab = generateTab(index);
                CDocumentTabsState.tabs.add(tab);
                CDocumentTabsState.currentIndex.value = index - 1;
              },
            )),
      ),
      content: const CDocumentTable(),
    );
  }

  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvdocument'.tr()),
      semanticLabel: 'nouvdocument'.tr(),
      icon: const Icon(FluentIcons.document),
      body: const ScaffoldPage(content: CDocumentForm()),
      onClosed: () {
        CDocumentTabsState.tabs.remove(tab);

        if (CDocumentTabsState.currentIndex.value > 0) {
          CDocumentTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }
}
