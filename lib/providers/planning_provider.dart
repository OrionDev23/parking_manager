import 'package:appwrite/appwrite.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/serializables/planning.dart';

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



}