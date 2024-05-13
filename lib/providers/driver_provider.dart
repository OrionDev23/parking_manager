import 'package:appwrite/appwrite.dart';
import 'package:flutter/foundation.dart';

import '../main.dart';
import '../serializables/conducteur/disponibilite_chauffeur.dart';
import '../serializables/conducteur/document_chauffeur.dart';
import '../serializables/conducteur/conducteur.dart';
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
  Future<void> refreshDocuments() async{
    if(downloadingDocuments){
      return;
    }
    downloadingDocuments=true;
    documentConducteurs.clear();
    await ClientDatabase.database!.listDocuments(
        databaseId: databaseId,
        collectionId: chaufDoc,queries: [Query.limit(5000)]).then((value) {
      for(int i=0;i<value.documents.length;i++){
        documentConducteurs[value.documents[i].$id]=value.documents[i].convertTo(
                (p0) => DocumentChauffeur.fromJson(p0 as Map<String,dynamic>));
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
    await ClientDatabase.database!.listDocuments(
        databaseId: databaseId,
        collectionId: chaufDispID,queries: [Query.limit(5000)]).then((value) {
      for(int i=0;i<value.documents.length;i++){
        disponibiliteConducteurs[value.documents[i].$id]=value.documents[i].convertTo(
                (p0) => DisponibiliteChauffeur.fromJson(p0 as Map<String,dynamic>));
      }
      downloadedDisp=true;

    }).onError((error, stackTrace) {
      downloadedDisp=false;

    });
    downloadingDisp=false;
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
      await ClientDatabase.database!.listDocuments(
          databaseId: databaseId,
          collectionId: chaufDoc,
          queries: [
            Query.lessThanEqual('date_expiration', dateToIntJson(expiration)),
            if (removedCondDocs.isNotEmpty)
              ...removedCondDocs.map((e) => Query.notEqual(r'$id', e))
          ]).then((value) {
        for (int i = 0; i < value.documents.length; i++) {
          result.add(value.documents[i].convertTo(
                  (p0) => DocumentChauffeur.fromJson(p0 as Map<String, dynamic>)));
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