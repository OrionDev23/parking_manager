import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/serializables/parc_user.dart';

import '../../utilities/profil_beautifier.dart';

class FutureImage extends StatelessWidget {
  final String fileID;
  final ParcUser? user;
  const FutureImage(this.fileID, {super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(future: ClientDatabase.storage!.getFileView(
      bucketId: buckedId,
      fileId: fileID,
    ),
        builder: (context,snapshot){
          return snapshot.hasData && snapshot.data != null
              ? Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
          ):
              !snapshot.hasData
                  ?user==null?Image.asset('assets/images/defaultUser.webp',fit: BoxFit.cover,)
                  :Text(ProfilUtilitis.getFirstLetters(user!))
                  : const ProgressRing();
    });
  }

}
