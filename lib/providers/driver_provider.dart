import 'package:appwrite/appwrite.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/serializables/prestataire.dart';
import 'package:parc_oto/serializables/reparation/reparation.dart';

import '../serializables/conducteur/disponibilite_chauffeur.dart';
import '../serializables/conducteur/document_chauffeur.dart';
import '../serializables/conducteur/conducteur.dart';
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


}