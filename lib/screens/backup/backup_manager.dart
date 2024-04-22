import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/widgets/button_container.dart';
import 'package:parc_oto/widgets/page_header.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

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
        trailing: SizedBox(
          width: 250.px,
          child: ButtonContainer(
            icon: FluentIcons.save_all,
            text: 'backupnow'.tr(),
            showBottom: false,
            showCounter: false,
          ),
        ),

      ),
    );
  }
}
