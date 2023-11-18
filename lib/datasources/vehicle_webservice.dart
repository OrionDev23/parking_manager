import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/datasources/vehicules_datasource.dart';

import '../providers/client_database.dart';
import '../serializables/vehicle.dart';
import '../utilities/vehicle_util.dart';

class VehiculesWebServiceResponse {
  VehiculesWebServiceResponse(this.totalRecords, this.data);

  /// THe total ammount of records on the server, e.g. 100
  final int totalRecords;

  /// One page, e.g. 10 reocrds
  final List<Vehicle> data;
}

class VehiculesWebService {
  int Function(Vehicle, Vehicle)? _getComparisonFunction(
      int column, bool ascending) {
    int coef = ascending ? 1 : -1;
    switch (column) {
    //id
      case 0:
        return (Vehicle d1, Vehicle d2) => coef * d1.id!.compareTo(d2.id!);
    //matricule
      case 1:
        return (Vehicle d1, Vehicle d2) =>
        coef * d1.matricule.compareTo(d2.matricule);
    //marque
      case 2:
        return (Vehicle d1, Vehicle d2) {
          if (d1.marque == null && d1.type==null) {
            return -1;
          } else if (d2.marque == null && d2.type==null) {
            return 1;
          }
          else if(d2.marque==d1.marque) {
            return coef * d1.type!.compareTo(d2.type!);
          }
          else {
            return coef * d1.marque!.id.compareTo(d2.marque!.id);
          }
        };
    //type
      case 3:
        return (Vehicle d1, Vehicle d2) {
          if (d1.type == null) {
            return -1;
          } else if (d2.type == null) {
            return 1;
          } else {
            return coef * d1.type!.compareTo(d2.type!);
          }
        };
    //annee
      case 4:
        return (Vehicle d1, Vehicle d2) {
          int annee1 = d1.anneeUtil ??
              VehiclesUtilities.getAnneeFromMatricule(d1.matricule);
          int annee2 = d2.anneeUtil ??
              VehiclesUtilities.getAnneeFromMatricule(d2.matricule);

          return coef * annee1.compareTo(annee2);
        };
    //dateAjout
      case 5:
        return (Vehicle d1, Vehicle d2) =>
        coef * d1.dateCreation!.compareTo(d2.dateCreation!);
    //date modif
      case 6:
        return (Vehicle d1, Vehicle d2) =>
        coef * d1.dateModification!.compareTo(d2.dateModification!);
    }

    return null;
  }

  Future<VehiculesWebServiceResponse> getData(
      int startingAt, int count, int sortedBy, bool sortedAsc) async {
    if(startingAt==0){
      vehicles.clear();
    }
    return ClientDatabase.database!.listDocuments(
        databaseId: databaseId,
        collectionId: vehiculeid,
        queries: [
          Query.limit(count),
          Query.offset(startingAt),
          getQuery(sortedBy,sortedAsc),
        ]).then((value) {
      for (var element in value.documents) {


        vehicles.add( element.convertTo<Vehicle>((p0) {

          return Vehicle.fromJson(p0 as Map<String,dynamic>);
        }));
      }


      var result = vehicles;

      result.sort(_getComparisonFunction(sortedBy, sortedAsc));
      return VehiculesWebServiceResponse(
          value.total, result.skip(startingAt).take(count).toList());
    }).onError((error, stackTrace) {
      return Future.value(VehiculesWebServiceResponse(0,vehicles));
    });
  }


  String getQuery(int sortedBy,bool sortedAsc){

    switch (sortedBy){
      case 1: if(sortedAsc){
        return Query.orderAsc('matricule');
      }
      else{
        return Query.orderDesc('matricule');
      }
      case 2: if(sortedAsc){
        return Query.orderAsc('type');
      }
      else{
        return Query.orderDesc('type');
      }
      case 4:
        if(sortedAsc){
          return Query.orderAsc('annee_util');
        }
        else{
          return Query.orderDesc('annee_util');
        }
      case 6:
        if(sortedAsc){
          return Query.orderAsc('\$updatedAt');
        }
        else{
          return Query.orderDesc('\$updatedAt');
        }
    }
    return Query.orderAsc('\$id');
  }
}