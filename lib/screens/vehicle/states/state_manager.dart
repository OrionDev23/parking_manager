import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../widgets/button_container.dart';
import '../../../widgets/page_header.dart';
import 'state_form.dart';
import 'state_table.dart';

class EtatManager extends StatefulWidget {
  const EtatManager({super.key});

  @override
  EtatManagerState createState() => EtatManagerState();
}

class EtatManagerState extends State<EtatManager> {
  final tstyle = TextStyle(
    fontSize: 10.sp,
  );

  static BuildContext? current;

  @override
  void initState() {
    current = context;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: PageTitle(
        text: 'vstates'.tr(),
        trailing: ButtonContainer(
            icon: FluentIcons.add,
            text: 'add'.tr(),
            showBottom: false,
            showCounter: false,
            action: showStateForm),
      ),
      content: const StateTable(),
    );
  }

  void showStateForm() {
    showDialog(
        context: context,
        barrierDismissible: true,
        builder: (c) {
          return ContentDialog(
            title: const Text("nouvetat").tr(),
            constraints: BoxConstraints.loose(Size(800.px, 500.px)),
            content: const StateForm(),
          );
        });
  }
}
