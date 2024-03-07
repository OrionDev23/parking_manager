import 'package:appwrite/appwrite.dart';
import 'package:fluent_ui/fluent_ui.dart';

import '../serializables/vehicle/vehicle.dart';
import '../serializables/conducteur/conducteur.dart';
import 'client_database.dart';

class VehicleProvider extends ChangeNotifier {
  static Map<String,Vehicle> vehicles={};
  static Map<String,Conducteur> conducteurs={};
  static bool downloadedVehicles=false;
  static bool downloadingVehicles=false;
  static bool downloadedConducteurs=false;
  static bool downloadingConducteurs=false;
  VehicleProvider(){
    if(!downloadedVehicles){
      refreshVehicles();
    }
  }

  Future<void> refreshVehicles() async{
    if(downloadingVehicles){
      return;
    }
    downloadingVehicles=true;
    vehicles.clear();
   await ClientDatabase.database!.listDocuments(
        databaseId: databaseId,
        collectionId: vehiculeid,queries: [
      Query.limit(ClientDatabase.limits['vehicles']??500)
    ]).then((value) {
      for(int i=0;i<value.documents.length;i++){
        vehicles[value.documents[i].$id]=value.documents[i].convertTo(
                (p0) => Vehicle.fromJson(p0 as Map<String,dynamic>));
      }
      downloadedVehicles=true;

   }).onError((error, stackTrace) {
      downloadedVehicles=false;

    });
    downloadingVehicles=false;
    notifyListeners();

  }

  void addVehicle(Vehicle v){
    vehicles[v.id]=v;
    notifyListeners();
  }

  void removeVehicle(Vehicle v){
    vehicles.remove(v.id);
    notifyListeners();
  }

  Future<void> refreshConducteurs() async{
    if(downloadingConducteurs){
      return;
    }
    downloadingConducteurs=true;
    conducteurs.clear();
    await ClientDatabase.database!.listDocuments(
        databaseId: databaseId,
        collectionId: chauffeurid,queries: [
      Query.limit(ClientDatabase.limits['vehicles']??500)
    ]).then((value) {
      for(int i=0;i<value.documents.length;i++){
        conducteurs[value.documents[i].$id]=value.documents[i].convertTo(
                (p0) => Conducteur.fromJson(p0 as Map<String,dynamic>));
      }
      downloadedConducteurs=true;

    }).onError((error, stackTrace) {
      downloadedConducteurs=false;

    });
    downloadingConducteurs=false;
    notifyListeners();

  }
  void addConducteur(Conducteur c){
    conducteurs[c.id]=c;
    notifyListeners();
  }

  void removeConducteur(Conducteur c){
    conducteurs.remove(c.id);
    notifyListeners();
  }

}