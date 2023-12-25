import 'package:appwrite/appwrite.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../widgets/empty_table_widget.dart';

class AcceptInvitation extends StatefulWidget {
  const AcceptInvitation({super.key});

  @override
  State<AcceptInvitation> createState() => _AcceptInvitationState();
}

class _AcceptInvitationState extends State<AcceptInvitation> {


  String get userId => Uri.base.queryParameters['userId'] ?? '';
  String get projectId => Uri.base.queryParameters['projectid'] ?? '';
  String get endpointU => Uri.base.queryParameters['endpoint'] ?? '';
  String get membershipId => Uri.base.queryParameters['membershipId'] ?? '';
  String get teamId => Uri.base.queryParameters['teamId'] ?? '';

  String get secret => Uri.base.queryParameters['secret'] ?? '';

  bool done=false;
  bool linknotvalid=false;

  @override
  void initState() {
    if(secret.isEmpty || teamId.isEmpty || membershipId.isEmpty || endpointU.isEmpty || projectId.isEmpty ||userId.isEmpty){
      done=true;
      linknotvalid=true;
    }
    else{
      confirmMembership();
    }
    super.initState();
  }


  void confirmMembership()async{
    Client client=Client()
      ..setProject(projectId)
      ..setEndpoint(endpointU);
    await Teams(client).updateMembershipStatus(
        teamId: teamId,
        membershipId: membershipId,
        userId: userId,
        secret: secret).then((value) {
          setState(() {
            done=true;
            linknotvalid=false;
          });
    }).onError((error, stackTrace) {
      done=true;
      linknotvalid=true;
    });
  }
  @override
  Widget build(BuildContext context) {
    if(done){
      return NoDataWidget(
        icon:linknotvalid?FluentIcons.error:FluentIcons.check_mark,
        text:linknotvalid?'linknotvalid':'donepassword',);
    }
    else{
      return const Center(child: ProgressBar());
    }
  }


}
