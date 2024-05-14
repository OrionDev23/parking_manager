import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:go_router/go_router.dart';

import '../../serializables/backup.dart';

class BackupRestore extends StatefulWidget {

  final Backup backup;
  const BackupRestore({super.key, required this.backup});

  @override
  State<BackupRestore> createState() => _BackupRestoreState();
}

class _BackupRestoreState extends State<BackupRestore> {
  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      actions: [
        Button(child: const Text('fermer').tr(),onPressed: ()=>context.pop(),),
        FilledButton(onPressed: confirmSelection, child: const Text('confirmer').tr()),
      ],
    );
  }

  void confirmSelection(){

  }
}
