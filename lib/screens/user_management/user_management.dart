import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/screens/user_management/user_creation.dart';
import 'package:parc_oto/screens/user_management/user_table.dart';
import 'package:parc_oto/widgets/page_header.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../widgets/button_container.dart';

class UserManagement extends StatefulWidget {
  final bool archive;
  const UserManagement({super.key, this.archive = false});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  bool loading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
        header: PageTitle(
          text: 'usermanagement'.tr(),
          trailing: SizedBox(
              width: 15.w,
              height: 10.h,
              child: ButtonContainer(
                icon: FluentIcons.add,
                text: 'add'.tr(),
                showBottom: false,
                showCounter: false,
                action: showUserForm,
              )),
        ),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: UsersTable(
            archive: widget.archive,
          ),
        ));
  }


  void showUserForm(){
    showDialog(context: context, builder: (c){
      return const UserForm();
    });
  }
}
