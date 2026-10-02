import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import '../main.dart';
import '../serializables/conducteur/disponibilite_chauffeur.dart';
import '../serializables/conducteur/document_chauffeur.dart';
import '../serializables/conducteur/conducteur.dart';
import '../domain/entities/driver.dart';
import '../utilities/profil_beautifier.dart';
import 'client_database.dart';

class DriverProvider extends ChangeNotifier {
  static Map<String,Conducteur> conducteurs={};
  static Map<String,DisponibiliteChauffeur> disponibiliteConducteurs={};
  static Map<String,DocumentChauffeur> documentConducteurs={};
  static bool downloadedConducteurs=false;
  static bool downloadingConducteurs=false;
  static bool downloadedDocuments=false;
  static bool downloadingDocuments=false;
  static bool downloadedDisp=false;
  static bool downloadingDisp=false;
  DriverProvider(){
    if(!downloadedConducteurs && !downloadingConducteurs){
      refreshConducteurs();
    }
  }
  Future<void> refreshConducteurs() async{
    if(downloadingConducteurs){
      return;
    }
    downloadingConducteurs=true;
    try {
      final drivers = await driverServices.repository.getDrivers();
      conducteurs
        ..clear()
        ..addEntries(
          drivers.map(
            (driver) => MapEntry(driver.id, _toLegacyConducteur(driver)),
          ),
        );
      downloadedConducteurs = true;
    } catch (_) {
      downloadedConducteurs = false;
    }
    downloadingConducteurs=false;
    notifyListeners();

  }
  static Conducteur _toLegacyConducteur(Driver driver) {
    return Conducteur(
      id: driver.id,
      name: driver.lastName,
      prenom: driver.firstName,
      matricule: driver.registration,
      vehicules: driver.vehicleIds,
      filliale: driver.subsidiary,
      direction: driver.direction,
      departement: driver.department,
      profession: driver.profession,
      etat: driver.state,
      etatactuel: driver.currentStateId,
      createdBy: driver.createdBy,
      adresse: driver.address,
      email: driver.email,
      dateNaissance: driver.birthDate,
      service: driver.service,
      telephone: driver.phone,
      createdAt: driver.createdAt,
      updatedAt: driver.updatedAt,
    );
  }

  Future<void> refreshDocuments() async{
    if(downloadingDocuments){
      return;
    }
    downloadingDocuments=true;
    documentConducteurs.clear();
    await DatabaseGetter.database!.listRows(
        databaseId: databaseId,
        tableId: chaufDoc,queries: [Query.limit(5000)]).then((value) {
      for(int i=0;i<value.rows.length;i++){
        documentConducteurs[value.rows[i].$id]=value.rows[i].convertTo(
                (p0) => DocumentChauffeur.fromJson(p0));
      }
      downloadedDocuments=true;

    }).onError((error, stackTrace) {
      downloadedDocuments=false;

    });
    downloadingDocuments=false;
    notifyListeners();

  }
  Future<void> refreshDisp() async{
    if(downloadingDisp){
      return;
    }
    downloadingDisp=true;
    disponibiliteConducteurs.clear();
    await DatabaseGetter.database!.listRows(
        databaseId: databaseId,
        tableId: chaufDispID,queries: [Query.limit(5000)]).then((value) {
      for(int i=0;i<value.rows.length;i++){
        disponibiliteConducteurs[value.rows[i].$id]=value.rows[i].convertTo(
                (p0) => DisponibiliteChauffeur.fromJson(p0));
      }
      downloadedDisp=true;

    }).onError((error, stackTrace) {
      downloadedDisp=false;

    });
    downloadingDisp=false;
    notifyListeners();

  }

  Future<int> getDriversCount() async{
    if(!downloadedConducteurs && !downloadingConducteurs){
      await refreshConducteurs();

    }
    else{
      while(downloadingConducteurs){
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
    return conducteurs.length;

  }
  Future<int> getDriversDocsCount() async{
    if(!downloadedDocuments && !downloadingDocuments){
      await refreshDocuments();

    }
    else{
      while(downloadingDocuments){
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
    return documentConducteurs.length;

  }
  Future<int> getDriversStatesCount() async{
    if(!downloadedDisp && !downloadingDisp ){
      await refreshDocuments();

    }
    else{
      while(downloadingDisp){
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
    return disponibiliteConducteurs.length;

  }
  void addConducteur(Conducteur c){
    conducteurs[c.id]=c;
    notifyListeners();
  }

  void removeConducteur(Conducteur c){
    conducteurs.remove(c.id);
    notifyListeners();
  }
  static List<String> removedCondDocs = [];

  Future<List<DocumentChauffeur>> getConduDocumentsBeforeTime(
      DateTime expiration) async {
    List<DocumentChauffeur> result = [];
    removedCondDocs = prefs.getStringList('removedCondDocs') ?? [];
    while(downloadingDocuments){
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if(downloadedDocuments){
      for(var element in documentConducteurs.values){
        if(element.dateExpiration!=null && element.dateExpiration!.isBefore
          (expiration) && !removedCondDocs.contains(element.id)){
          result.add(element);
        }
      }
    }
    else{
      await DatabaseGetter.database!.listRows(
          databaseId: databaseId,
          tableId: chaufDoc,
          queries: [
            Query.lessThanEqual('date_expiration', dateToIntJson(expiration)),
            if (removedCondDocs.isNotEmpty)
              ...removedCondDocs.map((e) => Query.notEqual(r'$id', e))
          ]).then((value) {
        for (int i = 0; i < value.rows.length; i++) {
          result.add(value.rows[i].convertTo(
                  (p0) => DocumentChauffeur.fromJson(p0)));
        }
      }).onError((AppwriteException error, stackTrace) {
        if (kDebugMode) {
          print(error.message);
          print(error.response);
        }
      });
    }


    return result;
  }

  static String getEtat(int? etat) {
    switch (etat) {
      case 0:
        return 'disponible';
      case 1:
        return 'mission';
      case 2:
        return 'absent';
      case 3:
        return 'quitteentre';
      default:
        return 'disponible';
    }
  }


}