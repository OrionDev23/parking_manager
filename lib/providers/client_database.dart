import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../serializables/parc_user.dart';

const databaseId = "6531ad112080ae3b14a7";
const userid = "users";
const chauffeurid = "6537d87b492c80f255e8";
const genreid = "6537960246d5b0e1ab77";
const vehiculeid = "6531ad22153b2a49ca2c";

class ClientDatabase {
  static Client? client;
  static Account? account;
  static User? user;
  final DateTime ref=DateTime(2023,11,01,12,13,15);

  static Databases? database;

  static ValueNotifier<ParcUser?> me=ValueNotifier(null);

  ClientDatabase() {
    client ??= Client()
      ..setEndpoint('https://cloud.appwrite.io/v1')
      ..setProject('6531ace99382e496a904');
    account ??= Account(client!);
    database ??= Databases(client!);
  }

  Future<void> getUser() async {
    if (user == null) {
      await account?.get().then((value) async {
        user = value;
        database!
            .getDocument(
                databaseId: databaseId,
                collectionId: userid,
                documentId: user!.$id)
            .then((result) {
          me.value = ParcUser.fromJson(result.data);
        }).catchError((error) {
          me.value = ParcUser(
            email: user!.email,
            id: user!.$id,
            name: user!.name,
            tel: user!.phone,
            datea: DateTime.parse(user!.accessedAt.isEmpty?DateTime.now().toIso8601String():user!.accessedAt).difference(ref).inMilliseconds.abs(),
            datec: DateTime.parse(user!.$createdAt).difference(ref).inMilliseconds.abs(),
            datel: DateTime.parse(user!.$updatedAt.isEmpty?DateTime.now().toIso8601String():user!.$updatedAt).difference(ref).inMilliseconds.abs(),
          );
          uploadUser(me.value!);
        });
      }).catchError((error) {
        user = null;
      });
    }
  }

  void uploadUser(ParcUser u) {
    database!.createDocument(
        databaseId: databaseId,
        collectionId: userid,
        documentId: me.value!.id,
        data: me.value!.toJson(),
        permissions: [
          Permission.read(Role.users()),
          Permission.write(Role.user(me.value!.id)),
          Permission.update(Role.user(me.value!.id)),
          Permission.delete(Role.user(me.value!.id)),
        ]);
  }
}
