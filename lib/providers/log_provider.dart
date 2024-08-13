import 'package:appwrite/appwrite.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../serializables/activity.dart';
import 'client_database.dart';

class LogProvider extends ChangeNotifier {


  static Map<String,Activity> activities={};
  static bool downloadedActivities=false;
  static bool downloadingActivities=false;
  LogProvider(){
    if(!downloadedActivities && !downloadingActivities){
      refreshLogs();
    }
  }

  Future<void> refreshLogs() async{
    if(downloadingActivities){
      return;
    }
    downloadingActivities=true;
    activities.clear();
    await DatabaseGetter.database!.listDocuments(
        databaseId: databaseId,
        collectionId: activityId,queries: [Query.limit(5000)]).then((value) {
      for(int i=0;i<value.documents.length;i++){
        activities[value.documents[i].$id]=value.documents[i].convertTo(
                (p0) => Activity.fromJson(p0 as Map<String,dynamic>));
      }
      downloadedActivities=true;

    }).onError((error, stackTrace) {
      downloadedActivities=false;

    });
    downloadingActivities=false;
    notifyListeners();

  }

  Future<int> getLogCount() async{
    if(!downloadedActivities && !downloadingActivities){
      await refreshLogs();

    }
    else{
      while(downloadingActivities){
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
    return activities.length;

  }


}