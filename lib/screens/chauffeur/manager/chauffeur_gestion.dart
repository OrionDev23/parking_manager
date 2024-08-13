import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/batch_import/import_conducteurs.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../theme.dart';
import '../../../../widgets/button_container.dart';
import '../../../../widgets/page_header.dart';
import '../../../admin_parameters.dart';
import '../../../providers/client_database.dart';
import 'chauffeur_form.dart';
import 'chauffeur_table.dart';
import 'chauffeur_tabs.dart';

class ChauffeurGestion extends StatefulWidget {
  final bool archive;

  const ChauffeurGestion({super.key, this.archive = false});

  @override
  ChauffeurGestionsState createState() => ChauffeurGestionsState();
}

class ChauffeurGestionsState extends State<ChauffeurGestion> {
  final tstyle = TextStyle(
    fontSize: 10.sp,
  );
  static ValueNotifier<int> stateChanges = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    return ScaffoldPage(
      header: PageTitle(
        text: widget.archive ? 'archive'.tr() : 'gchauffeurs'.tr(),
        trailing: widget.archive
            ? null
            : Row(
              children: [
                if (showImportConducteur && DatabaseGetter().isAdmin())
                  ButtonContainer(
                    color: appTheme.color.darkest,
                    icon: FluentIcons.add,
                    text: 'importlist'.tr(),
                    showBottom: false,
                    showCounter: false,
                    action: importList,
                  ),
                if (showImportConducteur && DatabaseGetter().isAdmin()) smallSpace,
                ButtonContainer(
                  icon: FluentIcons.add,
                  text: 'add'.tr(),
                  showBottom: false,
                  showCounter: false,
                  action: () {
                    final index = ChauffeurTabsState.tabs.length + 1;
                    final tab = generateTab(index);
                    ChauffeurTabsState.tabs.add(tab);
                    ChauffeurTabsState.currentIndex.value = index - 1;
                  },
                ),
              ],
            ),
      ),
      content: ChauffeurTable(
        archive: widget.archive,
      )
    );
  }


  void importList() async {
    FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      allowMultiple: false,
    );
    if (pickedFile != null) {
      Future.delayed(const Duration(milliseconds: 50))
          .then((value) => showDialog(
          context: context,
          barrierDismissible: true,
          builder: (c) {
            return ImportConducteurs(
              file: pickedFile,
            );
          }));
    }
  }
  Tab generateTab(int index) {
    late Tab tab;
    tab = Tab(
      key: UniqueKey(),
      text: Text('nouvchauf'.tr()),
      semanticLabel: 'nouvchauf'.tr(),
      icon: const Icon(FluentIcons.document),
      body: const ChauffeurForm(),
      onClosed: () {
        ChauffeurTabsState.tabs.remove(tab);

        if (ChauffeurTabsState.currentIndex.value > 0) {
          ChauffeurTabsState.currentIndex.value--;
        }
      },
    );
    return tab;
  }
}
