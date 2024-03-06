import 'package:appwrite/appwrite.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../serializables/vehicle/vehicle.dart';
import 'client_database.dart';

class VehicleProvider extends ChangeNotifier {
  static Map<String,Vehicle> vehicles={};
  static bool downloaded=false;
  static bool downloading=false;
  VehicleProvider(){
    if(!downloaded){
      refreshDatabase();
    }
  }

  Future<void> refreshDatabase() async{
    if(downloading){
      return;
    }
    downloading=true;
    vehicles.clear();
   await ClientDatabase.database!.listDocuments(
        databaseId: databaseId,
        collectionId: vehiculeid,queries: [
      Query.limit(ClientDatabase.limits['vehicles']??500)
    ]).then((value) {
      for(int i=0;i<value.documents.length;i++){
        vehicles[value.documents[i].$id]=value.documents[i].convertTo(
                (p0) => Vehicle.fromJson(p0 as Map<String,dynamic>));
      downloaded=true;
      }
    }).onError((error, stackTrace) {
      downloaded=false;

    });
    downloading=false;
    notifyListeners();

  }

  void addVehicle(Vehicle v){
    vehicles[v.id]=v;
    notifyListeners();
  }
}