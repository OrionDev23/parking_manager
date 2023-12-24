import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/widgets/page_header.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:dart_appwrite/models.dart';
import 'package:dart_appwrite/dart_appwrite.dart';

import '../../widgets/button_container.dart';


class UserManagement extends StatefulWidget {
  const UserManagement({super.key});

  @override
  State<UserManagement> createState() => _UserManagementState();
}

class _UserManagementState extends State<UserManagement> {
  bool loading = false;





  @override
  void initState() {
    initClient();
    super.initState();
    loadUsers();
  }



  String? searchKey;

  void loadUsers() async {
    setState(() {
      loading=true;
    });



    await Users(client).list(search: searchKey).then((value) async{

      List<Future<void>> tasks=List.empty(growable: true);
      users=value;
      for(var element in value.users){
        tasks.add(loadTeam(element));
      }
      await Future.wait(tasks);

    }).onError((AppwriteException error, stackTrace) {

    });
    setState(() {
      loading=false;
    });
  }


  Future<void> loadTeam(User user) async {

    await Teams(client).list().then((t) {
      userTeams[user.$id]=t.teams;
    });

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
              action: () {},
            )),
      ),
    );
  }
}
