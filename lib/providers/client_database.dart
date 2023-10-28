
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
class ClientDatabase{
  static Client? client;
  static Account? account;

  static User? user;

  ClientDatabase(){
    client ??= Client()
        ..setEndpoint('https://cloud.appwrite.io/v1')
        ..setProject('6531ace99382e496a904');
    account??=Account(client!);
  }

  Future<void> getUser() async{
    await account?.get().then((value) {
      user=value;
    }).catchError((error){

    });
  }
}