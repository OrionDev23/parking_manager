import 'package:appwrite/appwrite.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/serializables/reparation/reparation.dart';

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


  static Map<String,List<Reparation>> repPerVeh={};

  static Future<Map<String,List<Reparation>>> downloadReparations()async {


    await ClientDatabase.database!.listDocuments(
        databaseId: databaseId,
        collectionId: reparationId,
    ).then((value) {
      for(var doc in value.documents){
        Reparation rep=doc.convertTo((p0) => Reparation.fromJson(p0 as
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
  List<Reparation>> repPerVeh){
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

  static double getCost(List<Reparation> reps){
    double result=0;
    for(var r in reps){
      result+=r.getPrixTTC();
    }
    return result;
  }
  static DateTime? getLast(List<Reparation>reps){
    DateTime? d;
    for(var r in reps){
      if(d==null){
        d=r.date;
      }
      else{
        if(d.compareTo(r.date)<0){
          d=r.date;
        }
      }
    }
    return d;
  }

  static String? getModel(List<Reparation> reps){
    String? result;
    for(var r in reps){
      if(r.modele!=null){
        result=r.modele;
        break;
      }
    }
    return result;
  }

  static String? getMatConducteur(List<Reparation> reps){
    String? result;
    for(var r in reps){
      if(r.matriculeConducteur!=null){
        result=r.matriculeConducteur;
        break;
      }
    }
    return result;
  }

  static String? getConducteur(List<Reparation> reps){
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
}