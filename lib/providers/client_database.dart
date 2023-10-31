import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

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

  static Databases? database;

  static ParcUser? me;

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
          me = ParcUser.fromJson(result.data);
        }).catchError((error) {
          me = ParcUser(
            email: user!.email,
            id: user!.$id,
            name: user!.name,
            tel: user!.phone,

          );
          uploadUser(me!);
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
        documentId: me!.id,
        data: me!.toJson(),
        permissions: [
          Permission.read(Role.users()),
          Permission.write(Role.user(me!.id)),
          Permission.update(Role.user(me!.id)),
          Permission.delete(Role.user(me!.id)),
        ]);
  }
}
