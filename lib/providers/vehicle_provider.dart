import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';
import '../serializables/vehicle/document_vehicle.dart';
import '../serializables/vehicle/state.dart';
import '../serializables/vehicle/vehicle.dart';
import '../utilities/profil_beautifier.dart';
import 'client_database.dart';

class VehicleProvider extends ChangeNotifier {
  static Map<String,Vehicle> vehicles={};
  static Map<String,Etat> etats={};
  static Map<String,DocumentVehicle> documentsVehicules={};


  static bool downloadedVehicles=false;
  static bool downloadingVehicles=false;
  static bool downloadedDocuments=false;
  static bool downloadingDocuments=false;
  static bool downloadedStates=false;
  static bool downloadingStates=false;
  VehicleProvider(){
    if(!downloadedVehicles && !downloadingVehicles){
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
  Future<void> refreshDocuments() async{
    if(downloadingDocuments){
      return;
    }
    downloadingDocuments=true;
    documentsVehicules.clear();
   await ClientDatabase.database!.listDocuments(
        databaseId: databaseId,
        collectionId: vehicDoc,queries: [Query.limit(5000)]).then((value) {
      for(int i=0;i<value.documents.length;i++){
        documentsVehicules[value.documents[i].$id]=value.documents[i].convertTo(
                (p0) => DocumentVehicle.fromJson(p0 as Map<String,dynamic>));
      }
      downloadedDocuments=true;

   }).onError((error, stackTrace) {
     downloadedDocuments=false;

    });
    downloadingDocuments=false;
    notifyListeners();

  }
  Future<void> refreshStates() async{
    if(downloadingStates){
      return;
    }
    downloadingStates=true;
    etats.clear();
   await ClientDatabase.database!.listDocuments(
        databaseId: databaseId,
        collectionId: etatId,queries: [Query.limit(5000)]).then((value) {
      for(int i=0;i<value.documents.length;i++){
        etats[value.documents[i].$id]=value.documents[i].convertTo(
                (p0) => Etat.fromJson(p0 as Map<String,dynamic>));
      }
      downloadedStates=true;

   }).onError((error, stackTrace) {
     downloadedStates=false;

    });
    downloadingStates=false;
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


  static List<String> removedVehiDocs = [];
  Future<List<DocumentVehicle>> getDocumentsBeforeTime(
      DateTime expiration) async {
    removedVehiDocs = prefs.getStringList('removedDocs') ?? [];

    List<DocumentVehicle> result = [];
    while(downloadingDocuments){
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if(downloadedDocuments){
      for(var element in documentsVehicules.values){
        if(element.dateExpiration!=null && element.dateExpiration!.isBefore
          (expiration) && !removedVehiDocs.contains(element.id)){
          result.add(element);
        }
      }
    }
    else{
    await ClientDatabase.database!.listDocuments(
        databaseId: databaseId,
        collectionId: vehicDoc,
        queries: [
          Query.lessThanEqual('date_expiration', dateToIntJson(expiration)),
          if (removedVehiDocs.isNotEmpty)
            ...removedVehiDocs.map((e) => Query.notEqual(r'$id', e))
        ]).then((value) {
      for (int i = 0; i < value.documents.length; i++) {
        result.add(value.documents[i].convertTo(
                (p0) => DocumentVehicle.fromJson(p0 as Map<String, dynamic>)));
      }
    }).onError((error, stackTrace) {
      if (kDebugMode) {
        print(stackTrace);
      }
    });}
    return result;
  }


  Future<Vehicle?> getVehicle(String docID) async {
    if(vehicles.containsKey(docID)){
      return vehicles[docID];
    }
    else{
      return await ClientDatabase.database!
          .getDocument(
          databaseId: databaseId, collectionId: vehiculeid, documentId: docID)
          .then((value) {
        return value
            .convertTo((p0) => Vehicle.fromJson(p0 as Map<String, dynamic>));
      }).onError((error, stackTrace) {
        return Future.value(
            Vehicle(id: docID, matricule: '', matriculeEtrang: false));
      });
    }

  }

}