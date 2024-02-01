import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/logs/logging/log_table.dart';
import 'package:parc_oto/widgets/page_header.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class LogActivityManagement extends StatefulWidget {
  const LogActivityManagement({super.key});

  @override
  State<LogActivityManagement> createState() => _LogActivityManagementState();
}

class _LogActivityManagementState extends State<LogActivityManagement>
    with AutomaticKeepAliveClientMixin<LogActivityManagement> {
  final tstyle = TextStyle(
    fontSize: 10.sp,
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ScaffoldPage(
      header: PageTitle(
        text: 'journal'.tr(),
      ),
      content: const LogTable(),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
