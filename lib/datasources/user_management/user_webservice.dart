import 'package:dart_appwrite/dart_appwrite.dart';
import 'package:dart_appwrite/models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';

import '../../providers/client_database.dart';
const secretKey =
    "50715faccd768576e726c7f51394b1d092b4d492cb307a0b7b63a8ba3ff5c4c94b57560dff8b85133d355bb760cf3276db26c8cee3351e35cb33fec7ea5efc7d023a9a2ca4910fae20d112ee4898c292ec705f0e2a6eb8427675e374123a5cd51ef3e5ebf7836cd001c4829cbef2caf4d3dc35cf51958f88c88d14252276e494";

class UsersWebservice extends ParcOtoWebServiceUsers <String,MapEntry<User,List<Membership>?>>{



  Client client = Client();
  UsersWebservice(super.data,){
    initClient();
  }

  
  void initClient() {
    client.setProject(project)
      ..setKey(secretKey)
      ..setEndpoint(endpoint);
  }


  Map<String,MapEntry<User,List<Membership>?>> users={};
  Future<void> loadTeam(User user) async {
    if(kDebugMode){
      print('loading teams for user ${user.name}');

    }

    await Users(client).listMemberships(userId: user.$id).then((value) {
      users[user.$id]=MapEntry(user,value.memberships);
    }).onError((error, stackTrace) {
      users[user.$id]=MapEntry(user,null);
    });

    if(kDebugMode){
    String roles='';
    users[user.$id]?.value?.forEach((element) {
    if(roles.isNotEmpty){
    roles+=', ';
    }
    roles+=element.teamName.tr();
    });
    print('his teams are : $roles');
    }

  }


  @override
  Future<Map<String,MapEntry<User, List<Membership>?>>> getSearchResult(String? searchKey)  async{
    await Users(client).list(search: searchKey).then((value) async{

      List<Future<void>> tasks=List.empty(growable: true);
      for(var element in value.users){
        tasks.add(loadTeam(element));
      }
      await Future.wait(tasks);

    }).onError((AppwriteException error, stackTrace) {

    });

    return users;
  }

  @override
  int Function(MapEntry<String,MapEntry<User, List<Membership>?>> p1, MapEntry<String,MapEntry<User, List<Membership>?>> p2)? getComparisonFunction(int column, bool ascending) {
    int coef = ascending ? 1 : -1;
    switch (column) {
    //name
      case 0:
        return (d1, d2) =>
        coef * d1.value.key.name.compareTo(d2.value.key.name);
    //email
      case 1:
        return (d1, d2) =>
        coef * d1.value.key.email.compareTo(d2.value.key.email);
      case 2:
        return (d1, d2) =>
        coef * d1.value.key.$id.compareTo(d2.value.key.$id);
      case 3:
        return (d1, d2) =>
        coef * (d1.value.value?[0].teamName??'').compareTo(d2.value.value?[0].teamName??'');
      case 4:
        return (d1, d2) =>
        coef * (d1.value.key.$createdAt).compareTo(d2.value.key.$createdAt);

      default:
        return (d1, d2) =>
        coef * (d1.value.key.$createdAt).compareTo(d2.value.key.$createdAt);
    }
  }



}