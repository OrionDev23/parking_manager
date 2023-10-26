
import 'package:appwrite/appwrite.dart';

class ClientDatabase{
  static Client? client;
  static Account? account;
  ClientDatabase(){
    client ??= Client()
        ..setEndpoint('https://cloud.appwrite.io/v1')
        ..setProject('6531ace99382e496a904');
    account??=Account(client!);
  }
}