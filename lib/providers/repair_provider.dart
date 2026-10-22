import 'package:appwrite/appwrite.dart' hide Client;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/pdf_generation/pdf_theming.dart';
import 'package:parc_oto/serializables/client.dart';
import 'package:parc_oto/serializables/reparation/reparation.dart';
import 'package:parc_oto/utilities/vehicle_util.dart';

import '../main.dart';
import '../serializables/reparation/fiche_reception.dart';
import '../serializables/vehicle/vehicle.dart';
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

  List<Map<String, dynamic>> _readCached(String entity) {
    return vehicleServices.localDatabase.readLegacyCache(
      companyId: vehicleServices.companyId,
      entity: entity,
    );
  }

  Map<String, dynamic> _rowPayload(dynamic row) => <String, dynamic>{
    ...Map<String, dynamic>.from(row.data),
    r'$id': row.$id,
    r'$createdAt': row.$createdAt,
    r'$updatedAt': row.$updatedAt,
  };

  Future<void> refreshReparations() async {
    if (downloadingReparations) return;
    downloadingReparations = true;
    try {
      final cached = _readCached('repair');
      for (final payload in cached) {
        try {
          final item = Reparation.fromJson(payload);
          reparations[item.id] = item;
        } catch (error) {
          debugPrint('[ParcOto Repairs] invalid cached repair ignored: $error');
        }
      }
      if (reparations.isNotEmpty) {
        downloadedReparations = true;
        notifyListeners();
      }

      final database = DatabaseGetter.database;
      if (database == null) throw StateError('Appwrite database unavailable');
      final value = await database.listRows(
        databaseId: databaseId,
        tableId: reparationId,
        queries: [Query.limit(5000)],
      );
      final refreshed = <String, Reparation>{};
      for (final row in value.rows) {
        final payload = _rowPayload(row);
        try {
          final item = Reparation.fromJson(payload);
          refreshed[item.id] = item;
          vehicleServices.localDatabase.cacheLegacyRow(
            companyId: vehicleServices.companyId,
            entity: 'repair',
            entityId: row.$id,
            payload: payload,
          );
        } catch (error) {
          debugPrint('[ParcOto Repairs] remote row ignored: $error');
        }
      }
      reparations = refreshed;
      downloadedReparations = true;
    } catch (error) {
      downloadedReparations = reparations.isNotEmpty;
      debugPrint('[ParcOto Repairs] refresh failed: $error');
    } finally {
      downloadingReparations = false;
      notifyListeners();
    }
  }

  Future<void> refreshPrestataires() async {
    if (downloadingPrestataires) return;
    downloadingPrestataires = true;
    try {
      for (final payload in _readCached('provider')) {
        try {
          final item = Client.fromJson(payload);
          prestataires[item.id] = item;
        } catch (error) {
          debugPrint('[ParcOto Providers] invalid cached provider ignored: $error');
        }
      }
      if (prestataires.isNotEmpty) {
        downloadedPrestataires = true;
        notifyListeners();
      }

      final database = DatabaseGetter.database;
      if (database == null) throw StateError('Appwrite database unavailable');
      // Providers live in prestataire, not in the reparation table.
      final value = await database.listRows(
        databaseId: databaseId,
        tableId: prestataireId,
        queries: [Query.limit(5000)],
      );
      final refreshed = <String, Client>{};
      for (final row in value.rows) {
        final payload = _rowPayload(row);
        try {
          final item = Client.fromJson(payload);
          refreshed[item.id] = item;
          vehicleServices.localDatabase.cacheLegacyRow(
            companyId: vehicleServices.companyId,
            entity: 'provider',
            entityId: row.$id,
            payload: payload,
          );
        } catch (error) {
          debugPrint('[ParcOto Providers] remote row ignored: $error');
        }
      }
      prestataires = refreshed;
      downloadedPrestataires = true;
    } catch (error) {
      downloadedPrestataires = prestataires.isNotEmpty;
      debugPrint('[ParcOto Providers] refresh failed: $error');
    } finally {
      downloadingPrestataires = false;
      notifyListeners();
    }
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
  static Future<Map<String, List<FicheReception>>> downloadFicheReparations() async {
    repPerVeh = {};
    final database = DatabaseGetter.database;

    // Local cache provides an offline fallback and is refreshed when online.
    try {
      final cached = vehicleServices.localDatabase.readLegacyCache(
        companyId: vehicleServices.companyId,
        entity: 'reception_sheet',
      );
      for (final payload in cached) {
        try {
          final fiche = FicheReception.fromJson(payload);
          final key = fiche.vehiculemat ?? fiche.vehicule ?? 'nonind';
          repPerVeh.putIfAbsent(key, () => <FicheReception>[]).add(fiche);
        } catch (error) {
          debugPrint('[ParcOto Reception] invalid cached sheet ignored: $error');
        }
      }
    } catch (error) {
      debugPrint('[ParcOto Reception] local cache read failed: $error');
    }

    if (database == null) return repPerVeh;
    try {
      final value = await database.listRows(
        databaseId: databaseId,
        tableId: fichesreceptionId,
        queries: [Query.limit(5000)],
      );
      final refreshed = <String, List<FicheReception>>{};
      for (final row in value.rows) {
        final payload = <String, dynamic>{
          ...row.data,
          r'$id': row.$id,
          r'$createdAt': row.$createdAt,
          r'$updatedAt': row.$updatedAt,
        };
        try {
          final fiche = FicheReception.fromJson(payload);
          final key = fiche.vehiculemat ?? fiche.vehicule ?? 'nonind';
          refreshed.putIfAbsent(key, () => <FicheReception>[]).add(fiche);
          vehicleServices.localDatabase.cacheLegacyRow(
            companyId: vehicleServices.companyId,
            entity: 'reception_sheet',
            entityId: row.$id,
            payload: payload,
          );
        } catch (error) {
          debugPrint('[ParcOto Reception] remote row ignored: $error');
        }
      }
      repPerVeh = refreshed;
    } catch (error) {
      debugPrint('[ParcOto Reception] remote refresh failed; using cache: $error');
    }
    return repPerVeh;
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

  static List<Map<String,dynamic>> prepareListVehicleImmob(Map<String,
      List<FicheReception>> repPerVeh,List<Vehicle> vehicles){

    List<Map<String,dynamic>> result=[];

    for(int i=0;i<vehicles.length;i++){
      DateTime? d=repPerVeh.containsKey(vehicles[i].matricule)?getLast(repPerVeh[vehicles[i].matricule]!):null;

      double immobil=repPerVeh.containsKey(vehicles[i].matricule)?getImmobilisation(repPerVeh[vehicles[i].matricule]!):0;
      result.add({
        'vehicule':vehicles[i].matricule,
        'modele':"${VehiclesUtilities.getMarqueName(vehicles[i].marque)} ${vehicles[i].type=="nonind"?"":vehicles[i].type ?? ""}",
        'nbr. rep':repPerVeh.containsKey(vehicles[i].matricule)?repPerVeh[vehicles[i].matricule]!.length:0,
        'immob':immobil==0?"0 jours (0 heures)":"${numberFormat2.format(immobil/24)} jours ($immobil heures",
        'dern. rep':d==null?'':DateFormat('EEE, d/M/y').format(d)
      });
    }
    result.sort((a,b){
      return -a['immob'].compareTo(b['immob']);
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

  static double getImmobilisation(List<FicheReception> reps,){
    double result=0;
    for(var r in reps){
      result+=(r.dateSortie??DateTime.now()).difference(r.dateEntre).inHours;
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
      await DatabaseGetter.database!.listRows(
          databaseId: databaseId,
          tableId: reparationId,
          queries: [
            Query.greaterThanEqual('date', dateToIntJson(start)),
            Query.lessThanEqual('date', dateToIntJson(end)),
          ]).then((value) {
        for (int i = 0; i < value.rows.length; i++) {
          result.add(value.rows[i].convertTo(
                  (p0) => Reparation.fromJson(p0)));
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
        .getRow(
        databaseId: databaseId,
        tableId: prestataireId,
        rowId: docID)
        .then((value) {
      return value
          .convertTo((p0) => Client.fromJson(p0));
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
        .getRow(
        databaseId: databaseId,
        tableId: fichesreceptionId,
        rowId: docID)
        .then((value) {
      return value
          .convertTo((p0) => FicheReception.fromJson(p0));
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
        .getRow(
        databaseId: databaseId,
        tableId: reparationId,
        rowId: docID)
        .then((value) {
      return value
          .convertTo((p0) => Reparation.fromJson(p0));
    }).onError((error, stackTrace) {
      return Future.value(Reparation(
        id: docID, numero: 0, date: DateTime.now(),
      ));
    });
  }

}