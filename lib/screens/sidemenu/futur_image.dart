import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/providers/client_database.dart';

class FutureImage extends StatelessWidget {
  final String fileID;
  const FutureImage(this.fileID, {super.key});

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
          )
              : const ProgressRing();
    });
  }

}
