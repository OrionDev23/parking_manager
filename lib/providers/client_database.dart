
import 'package:appwrite/appwrite.dart';

class ClientDatabase{
  static Client? client;

  ClientDatabase(){
    client ??= Client()
        ..setEndpoint('https://cloud.appwrite.io/v1')
        ..setProject('6531ace99382e496a904');
  }
}