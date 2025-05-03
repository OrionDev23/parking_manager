

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/backup/backup_table.dart';
import 'package:parc_oto/widgets/button_container.dart';
import 'package:parc_oto/widgets/page_header.dart';

import '../../theme.dart';
import 'backup_restore.dart';
import 'backup_selection.dart';
class BackupManager extends StatefulWidget {
  const BackupManager({super.key});

  @override
  State<BackupManager> createState() => _BackupManagerState();
}

class _BackupManagerState extends State<BackupManager> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageTitle(
        text: 'backup'.tr(),
        trailing: Row(
          children: [
            ButtonContainer(
              icon: FluentIcons.import,
              text: 'importfile'.tr(),
              showBottom: false,
              showCounter: false,
              action: pickingFile?null:showImportScreen,
            ),
            smallSpace,
            ButtonContainer(
              icon: FluentIcons.save_all,
              text: 'save'.tr(),
              showBottom: false,
              showCounter: false,
              action: showSaveScreen,
            ),
          ],
        ),
      ),
      content: const BackupTable(selectD: false,),
    );
  }


  bool pickingFile=false;
  void showImportScreen() async{
    if(!pickingFile){
      setState(() {
        pickingFile=true;
      });
      await FilePicker.platform
          .pickFiles(
          dialogTitle: 'importfile'.tr(),
          type: FileType.custom,
          withData: true,
          allowedExtensions: ['gz']
      )
          .then((value) {
        if(value!=null){
          var bytes=value.files.first.bytes;
          Future.delayed(const Duration(milliseconds: 30)).then((value) {
            showDialog(context: context, builder: (con){
              return BackupRestore(backupFile: bytes);
            });
          });
        }
      });
      setState(() {
        pickingFile=false;
      });
    }


  }

  void showSaveScreen() {

    Future.delayed(const Duration(milliseconds: 30)).then((value) {
      showDialog(
          context: context,
          barrierDismissible: false,
          dismissWithEsc: false,
          builder: (c) {
            return const BackupSelection();
          });
    });
  }
}
