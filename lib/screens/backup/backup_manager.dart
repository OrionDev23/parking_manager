

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/backup/backup_table.dart';
import 'package:parc_oto/widgets/button_container.dart';
import 'package:parc_oto/widgets/page_header.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../theme.dart';
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
            SizedBox(
              width: 200.px,
              child: ButtonContainer(
                icon: FluentIcons.import,
                text: 'import'.tr(),
                showBottom: false,
                showCounter: false,
              ),
            ),
            smallSpace,
            SizedBox(
              width: 200.px,
              child: ButtonContainer(
                icon: FluentIcons.save_all,
                text: 'save'.tr(),
                showBottom: false,
                showCounter: false,
                action: showSaveScreen,
              ),
            ),
          ],
        ),
      ),
      content: const BackupTable(selectD: false,),
    );
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
