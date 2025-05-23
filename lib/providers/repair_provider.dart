import 'package:appwrite/appwrite.dart' hide Client;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/serializables/client.dart';
import 'package:parc_oto/serializables/reparation/reparation.dart';

import '../serializables/reparation/fiche_reception.dart';
import '../utilities/profil_beautifier.dart';
import 'client_database.dart';

class RepairProvider extends ChangeNotifier {


  static Map<String,Reparation> reparations={};
  static Map<String,Client> prestataires={};
  static bool downloadedReparations=false;
  static bool downloadingReparations=false;
  static bool downloadedPrestataires=false;
  static bool downloadingPrestataires=false;
  RepairProvider(){
    if(!downloadedReparations && !downloadingPrestataires){
      refreshReparations();
    }
  }




  static Map<String,List<FicheReception>> repPerVeh={};

  Future<void> refreshReparations() async{
    if(downloadingReparations){
      return;
    }
    downloadingReparations=true;
    reparations.clear();
    await DatabaseGetter.database!.listDocuments(
        databaseId: databaseId,
        collectionId: reparationId,queries: [Query.limit(5000)]).then((value) {
      for(int i=0;i<value.documents.length;i++){
        reparations[value.documents[i].$id]=value.documents[i].convertTo(
                (p0) => Reparation.fromJson(p0 as Map<String,dynamic>));
      }
      downloadedReparations=true;

    }).onError((error, stackTrace) {
      downloadedReparations=false;

    });
    downloadingReparations=false;
    notifyListeners();

  }
  Future<void> refreshPrestataires() async{
    if(downloadingPrestataires){
      return;
    }
    downloadingPrestataires=true;
    prestataires.clear();
    await DatabaseGetter.database!.listDocuments(
        databaseId: databaseId,
        collectionId: reparationId,queries: [Query.limit(5000)]).then((value) {
      for(int i=0;i<value.documents.length;i++){
        prestataires[value.documents[i].$id]=value.documents[i].convertTo(
                (p0) => Client.fromJson(p0 as Map<String,dynamic>));
      }
      downloadedPrestataires=true;

    }).onError((error, stackTrace) {
      downloadedPrestataires=false;

    });
    downloadingPrestataires=false;
    notifyListeners();

  }

  Future<int> getRepairsCount() async{
    if(!downloadedReparations && !downloadingReparations){
      await refreshReparations();

    }
    else{
      while(downloadingReparations){
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
    return reparations.length;

  }
  Future<int> getProvidersCount() async{
    if(!downloadedPrestataires && !downloadingPrestataires){
      await refreshPrestataires();

    }
    else{
      while(downloadingPrestataires){
        await Future.delayed(const Duration(milliseconds: 30));
      }
    }
    return prestataires.length;

  }
  static Future<Map<String,List<FicheReception>>> downloadFicheReparations()async {


    await DatabaseGetter.database!.listDocuments(
      databaseId: databaseId,
      collectionId: fichesreceptionId,
    ).then((value) {
      for(var doc in value.documents){
        FicheReception rep=doc.convertTo((p0) => FicheReception.fromJson(p0 as
        Map<String,dynamic>));
        if(!repPerVeh.containsKey(rep.vehicule)){
          repPerVeh[rep.vehiculemat??'nonind']=[rep];
        }
        else{
          repPerVeh[rep.vehiculemat??'']!.add(rep);
        }
      }
      return repPerVeh;
    });

    return {};
  }


  static List<Map<String,dynamic>> prepareVehicRepList(Map<String,
      List<FicheReception>> repPerVeh){
    List<Map<String,dynamic>> result=[];
    for(var v in repPerVeh.entries){
      DateTime? d=getLast(v.value);
      result.add({
        'vehicule':v.key,
        'modele':getModel(v.value)??'/',
        'mat. conducteur':getMatConducteur(v.value)??'/',
        'nom conducteur':getConducteur(v.value)??'/',
        'nbr. rep':v.value.length,
        'cost':getCost(v.value),
        'dern. rep':d==null?'':DateFormat('EEE, d/M/y').format(d)
      });
    }
    result.sort((a,b){
      return -a['cost'].compareTo(b['cost']);
    });
    return result;
  }

  static double getCost(List<FicheReception> reps){
    double result=0;
    for(var r in reps){
      result+=r.reparationCost??0;
    }
    return result;
  }
  static DateTime? getLast(List<FicheReception>reps){
    DateTime? d;
    for(var r in reps){
      if(d==null){
        d=r.dateEntre;
      }
      else{
        if(d.compareTo(r.dateEntre)<0){
          d=r.dateEntre;
        }
      }
    }
    return d;
  }

  static String? getModel(List<FicheReception> reps){
    String? result;
    for(var r in reps){
      if(r.modele!=null){
        result=r.modele;
        break;
      }
    }
    return result;
  }

  static String? getMatConducteur(List<FicheReception> reps){
    String? result;
    for(var r in reps){
      if(r.matriculeConducteur!=null){
        result=r.matriculeConducteur;
        break;
      }
    }
    return result;
  }

  static String? getConducteur(List<FicheReception> reps){
    String? result;
    for(var r in reps){
      if(r.nomConducteur!=null || r.prenomConducteur!=null){
        if(r.nomConducteur!=null){
          result=r.nomConducteur;
        }
        if(r.prenomConducteur!=null){
          result='$result ${r.prenomConducteur}';
        }
        break;
      }
    }
    return result?.trim();
  }

  Future<List<Reparation>> getReparationInMarge(
      DateTime start, DateTime end) async {
    List<Reparation> result = [];
    while(downloadingReparations){
      await Future.delayed(const Duration(milliseconds: 100));
    }
    if(downloadedReparations){
      for(var element in reparations.values){
        if((element.date.isAtSameMomentAs(start) || element.date.isAfter(start)
        ) && (element.date.isAtSameMomentAs(end) || element.date.isBefore(end))){
          result.add(element);
        }
      }
    }
    else{
      await DatabaseGetter.database!.listDocuments(
          databaseId: databaseId,
          collectionId: reparationId,
          queries: [
            Query.greaterThanEqual('date', dateToIntJson(start)),
            Query.lessThanEqual('date', dateToIntJson(end)),
          ]).then((value) {
        for (int i = 0; i < value.documents.length; i++) {
          result.add(value.documents[i].convertTo(
                  (p0) => Reparation.fromJson(p0 as Map<String, dynamic>)));
        }
      }).onError((error, stackTrace) {
        if (kDebugMode) {
          print(stackTrace);
        }
      });
    }
    return result;
  }


  Future<Client?> getPrestataire(String? docID) async {
    if (docID == null) {
      return null;
    }
    return await DatabaseGetter.database!
        .getDocument(
        databaseId: databaseId,
        collectionId: prestataireId,
        documentId: docID)
        .then((value) {
      return value
          .convertTo((p0) => Client.fromJson(p0 as Map<String, dynamic>));
    }).onError((error, stackTrace) {
      return Future.value(Client(
        id: docID,
        nom: '',
        adresse: '',
      ));
    });
  }
  Future<FicheReception?> getFiche(String? docID) async {
    if (docID == null) {
      return null;
    }
    return await DatabaseGetter.database!
        .getDocument(
        databaseId: databaseId,
        collectionId: fichesreceptionId,
        documentId: docID)
        .then((value) {
      return value
          .convertTo((p0) => FicheReception.fromJson(p0 as Map<String, dynamic>));
    }).onError((error, stackTrace) {
      return Future.value(FicheReception(
        id: docID, numero: 0, dateEntre: DateTime.now(),
      ));
    });
  }
  Future<Reparation?> getReparation(String? docID) async {
    if (docID == null) {
      return null;
    }
    return await DatabaseGetter.database!
        .getDocument(
        databaseId: databaseId,
        collectionId: reparationId,
        documentId: docID)
        .then((value) {
      return value
          .convertTo((p0) => Reparation.fromJson(p0 as Map<String, dynamic>));
    }).onError((error, stackTrace) {
      return Future.value(Reparation(
        id: docID, numero: 0, date: DateTime.now(),
      ));
    });
  }

}