import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/serializables/planning.dart';

import '../main.dart';
import '../utilities/profil_beautifier.dart';
import 'client_database.dart';

class PlanningProvider extends ChangeNotifier {


  static Map<String,Planning> plannings={};
  static bool downloadedPlanning=false;
  static bool downloadingPlanning=false;
  PlanningProvider(){
    if(!downloadedPlanning && !downloadingPlanning){
      refreshPlannings();
    }
  }

  Future<void> refreshPlannings() async{
    if(downloadingPlanning){
      return;
    }
    downloadingPlanning=true;
    plannings.clear();
    await ClientDatabase.database!.listDocuments(
        databaseId: databaseId,
        collectionId: planningID,queries: [Query.limit(5000)]).then((value) {
      for(int i=0;i<value.documents.length;i++){
        plannings[value.documents[i].$id]=value.documents[i].convertTo(
                (p0) => Planning.fromJson(p0 as Map<String,dynamic>));
      }
      downloadedPlanning=true;

    }).onError((error, stackTrace) {
      downloadedPlanning=false;

    });
    downloadingPlanning=false;
    notifyListeners();

  }
  static List<String> removedPlanDocs = [];
  Future<List<Planning>> getPlanningBeforeTime(DateTime expiration) async {
    List<Planning> result = [];

    removedPlanDocs = prefs.getStringList('removedPlanning') ?? [];
    while(downloadingPlanning){
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if(downloadedPlanning){
      for(var element in plannings.values){
        if(element.startTime.isBefore
          (expiration) && !removedPlanDocs.contains(element.id)){
          result.add(element);
        }
      }
    }
    else{
    await ClientDatabase.database!.listDocuments(
        databaseId: databaseId,
        collectionId: planningID,
        queries: [
          Query.lessThanEqual('startTime', dateToIntJson(expiration)),
          if (removedPlanDocs.isNotEmpty)
            ...removedPlanDocs.map((e) => Query.notEqual(r'$id', e))
        ]).then((value) {
      for (int i = 0; i < value.documents.length; i++) {
        result.add(value.documents[i]
            .convertTo((p0) => Planning.fromJson(p0 as Map<String, dynamic>)));
      }
    }).onError((error, stackTrace) {
      if (kDebugMode) {
        print(stackTrace);
      }
    });}

    return result;
  }



}