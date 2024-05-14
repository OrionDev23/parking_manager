import 'dart:async';
import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:encrypt/encrypt.dart' as en;

import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:gzip/gzip.dart';
import 'package:parc_oto/serializables/backup.dart';
import 'package:parc_oto/theme.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../providers/client_database.dart';
import '../../utilities/file_manipulation.dart';

class BackupUploader extends StatefulWidget {
  final String data;
  final int vehicCount;
  final int vehicDocCount;
  final int vehicStatesCount;
  final int condCount;
  final int condDocCount;
  final int condStateCount;
  final int repairCount;
  final int prestCount;
  final int planCount;
  final int logCount;
  final DateTime date;
  const BackupUploader(
      {super.key,
      required this.data,
      required this.date,
      required this.vehicCount,
      required this.vehicDocCount,
      required this.vehicStatesCount,
      required this.condCount,
      required this.condDocCount,
      required this.condStateCount,
      required this.repairCount,
      required this.prestCount,
      required this.planCount,
      required this.logCount});

  @override
  BackupUploaderState createState() => BackupUploaderState();
}

class BackupUploaderState extends State<BackupUploader> {
  double progress = 0;

  String? cryptedString;
  Uint8List? file;

  @override
  void initState() {
    cryptString();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ContentDialog(
      constraints: BoxConstraints(
        minWidth: 300.px,
        maxWidth: 500.px
      ),
      title: const Text('backupnow').tr(),
      content: ListView(
        shrinkWrap: true,
        children: [
          ProgressBar(
            value: progress,
          ),
          bigSpace,
          if (progress >= 35 && progress < 100) const Text('uploading').tr(),
          if (progress < 10) const Text('crypting').tr(),
          if (progress >= 10 && progress < 35) const Text('compressing').tr(),
          if (progress == 100) const Text('savedone').tr(),
        ],
      ),
      actions: [
        Button(
            onPressed: progress == 100 ? () => context.pop() : null,
            child: const Text('fermer').tr()),
        FilledButton(
            onPressed: progress == 100 ? saveCopy : null,
            child:  Row(
                    children: [
                      const Icon(FluentIcons.save),
                      smallSpace,
                      const Text('regcopie').tr(),
                    ],
                  ))
      ],
    );
  }

  void cryptString() {
    String s;

    if (secretKey.length < 32) {
      s = secretKey;
      for (int i = 0; i < (32 - secretKey.length); i++) {
        s = '${s}p';
      }
    } else {
      s = secretKey.substring(0, 32);
    }
    final key = en.Key.fromUtf8(s);
    final iv = en.IV.fromLength(16);
    final encrypter = en.Encrypter(en.AES(key));

    cryptedString = encrypter.encrypt(widget.data, iv: iv).base64;
    setState(() {
      progress = 10;
    });
    compressFile();
  }

  void compressFile() async {
    if (cryptedString != null) {
      final zipper = GZip();
      final input = utf8.encode(cryptedString!);
      final compress = await zipper.compress(input);
      file = Uint8List.fromList(compress);
      setState(() {
        progress = 35;
      });
      uploadFile();
    }
  }

  String? id;
  void uploadFile() async {
    if (file != null) {
      id ??=
          widget.date.difference(ClientDatabase.ref).inMilliseconds.toString();
      await ClientDatabase.storage!
          .createFile(
              bucketId: backupId,
              fileId: id!,
              file: InputFile.fromBytes(
                bytes: file!,
                filename: 'BACKUP '
                    '${widget.date.day}-${widget.date.month}-${widget.date.year}-${widget.date.hour}-${widget.date.minute}-${widget.date.second}.gz',
              ),
              onProgress: (p) {
                setState(() {
                  progress += 0.45 * p.progress + 35;
                });
              })
          .onError((AppwriteException error, stackTrace) {
        if (kDebugMode) {
          print(error.message);
          print(error.response);
        }
        return Future.value(File(
            $id: '',
            bucketId: '',
            $createdAt: '',
            $updatedAt: '',
            $permissions: [],
            name: '',
            signature: '',
            mimeType: '',
            sizeOriginal: 10,
            chunksTotal: 10,
            chunksUploaded: 10));
      }).then((value) {
        setState(() {
          progress = 80;
        });
        updateDb();
      });
    } else {
      if (kDebugMode) {
        print('erreur fichier');
      }
    }
  }

  void updateDb() async {
    await ClientDatabase.database!.createDocument(
        databaseId: databaseId,
        collectionId: backupId,
        documentId: id!,
        data: Backup(
          id: id!,
          vehicles: widget.vehicCount,
          vehicledocs: widget.vehicDocCount,
          vehiclesstates: widget.vehicStatesCount,
          drivers: widget.condCount,
          driversdocs: widget.condDocCount,
          driversstates: widget.condStateCount,
          repairs: widget.repairCount,
          providers: widget.prestCount,
          plannings: widget.planCount,
          logs: widget.logCount,
          createdBy: ClientDatabase.me.value?.id,
        ).toJson());
    setState(() {
      progress = 100;
    });
  }

  void saveCopy() {
    if (file != null) {
      saveThisFile(
          file!,
          "BACKUP ${widget.date.day}-${widget.date.month}-${widget.date.year}-${widget.date.hour}-${widget.date.minute}-${widget.date.second}",
          'gz',
          "application/gzip");
    }
  }
}
