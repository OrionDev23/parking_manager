import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:encrypt/encrypt.dart' as en;

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:gzip/gzip.dart';
import 'package:parc_oto/theme.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/client_database.dart';
import '../../utilities/file_manipulation.dart';

class BackupUploader extends StatefulWidget {
  final String data;
  final DateTime date;
  const BackupUploader({super.key, required this.data, required this.date});

  @override
  BackupUploaderState createState() => BackupUploaderState();
}

class BackupUploaderState extends State<BackupUploader> {

  double progress=0;

  String? cryptedString;
  Uint8List? file;

  @override
  void initState() {
    cryptString();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400.px,
      height: 200.px,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ProgressBar(
            value: progress,
          ),
          bigSpace,
          if(progress>=35 && progress<100)
            const Text('uploading').tr(),
          if(progress<10)
            const Text('crypting').tr(),
          if(progress>=10 && progress<35)
            const Text('compressing').tr(),
          if(progress==100)
            const Text('savedone').tr(),
          if(progress==100)
            FilledButton(
                onPressed: saveCopy,
                child: Row(
              children: [
                const Icon(FluentIcons.save),
                smallSpace,
                const Text('regcopie').tr(),
              ],
            ))
        ],
      ),
    );
  }



  void cryptString(){
    String s;

    if(secretKey.length<32){
      s=secretKey;
      for(int i=0;i<(32-secretKey.length);i++){
        s='${s}p';
      }
    }
    else{
      s=secretKey.substring(0,32);
    }
    final key=en.Key.fromUtf8(s);
    final iv=en.IV.fromLength(16);
    final encrypter=en.Encrypter(en.AES(key));
    
    cryptedString=encrypter.encrypt(widget.data,iv: iv).base64;
    setState(() {
      progress=10;
    });
    compressFile();
  }

  void compressFile() async{
    if(cryptedString!=null){
      final zipper = GZip();
    final input=utf8.encode(cryptedString!);
      final compress = await zipper.compress(input);
      file=Uint8List.fromList(compress);
      print('here');
      setState(() {
        progress=35;
      });
    }

  }

  String? id;
  void uploadingFile() async {
    if (file != null) {
      id ??= widget.date
          .difference(ClientDatabase.ref)
          .inMilliseconds
          .toString();
      await ClientDatabase.storage!.createFile(bucketId: buckedId, fileId: id!,
          file:
          InputFile.fromBytes(bytes: file!, filename: '$id.gz'),onProgress:
          (p){
            //0==35
            //100==80
          }).onError(
              (AppwriteException error,
              stackTrace) {
            print(error.message);
            print(error.response);
            return Future.value(File.fromMap({}));
          });
      setState(() {
        progress = 80;
      });
      updateDb();
    }
    else {
      print('erreur fichier');
    }
  }


  void updateDb() async{
    await ClientDatabase.database!.createDocument(
        databaseId: databaseId, collectionId: backupId, documentId: id!, data:
    {"fileid":id!});
    setState(() {
      progress=100;
    });
  }
  void saveCopy(){
    if(file!=null){
      saveThisFile(file!, "BACKUP ${widget.date.
    day}-${widget.date.month}-${widget.date.year}-${widget.date.hour}-${widget.date.minute}-${widget.date.second}",'gz',"application/gzip");
    }

  }
}
