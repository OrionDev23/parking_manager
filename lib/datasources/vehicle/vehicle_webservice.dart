import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:parc_oto/datasources/vehicle/vehicules_datasource.dart';

import '../../providers/client_database.dart';
import '../../serializables/vehicle.dart';
import '../../utilities/vehicle_util.dart';

class VehiculesWebServiceResponse {
  VehiculesWebServiceResponse(this.totalRecords, this.data);

  /// THe total ammount of records on the server, e.g. 100
  final int totalRecords;

  /// One page, e.g. 10 reocrds
  final List<MapEntry<String,Vehicle>> data;
}

class VehiculesWebService {
  int Function(MapEntry<String,Vehicle>, MapEntry<String,Vehicle>)? _getComparisonFunction(
      int column, bool ascending) {
    int coef = ascending ? 1 : -1;
    switch (column) {

      //matricule
      case 0:
        return (MapEntry<String,Vehicle> d1, MapEntry<String,Vehicle> d2) =>
            coef * d1.value.matricule.compareTo(d2.value.matricule);
      //marque
      case 1:
        return (MapEntry<String,Vehicle> d1, MapEntry<String,Vehicle> d2) {
          if (d1.value.marque == null && d1.value.type == null) {
            return -1;
          } else if (d2.value.marque == null && d2.value.type == null) {
            return 1;
          } else if (d2.value.marque == d1.value.marque) {
            return coef * d1.value.type!.compareTo(d2.value.type!);
          } else {
            return coef * d1.value.marque!.id.compareTo(d2.value.marque!.id);
          }
        };
      //annee
      case 2:
        return ( d1,  d2) {
          int annee1 = d1.value.anneeUtil ??
              VehiclesUtilities.getAnneeFromMatricule(d1.value.matricule);
          int annee2 = d2.value.anneeUtil ??
              VehiclesUtilities.getAnneeFromMatricule(d2.value.matricule);

          return coef * annee1.compareTo(annee2);
        };
      //date modif
      case 3:
        return ( d1,  d2) =>
            coef * d1.value.dateModification!.compareTo(d2.value.dateModification!);
    default:
    return (MapEntry<String,Vehicle> d1, MapEntry<String,Vehicle> d2) => coef * d1.key.compareTo(d2.key);
    }

  }

  Future<VehiculesWebServiceResponse> getData(int startingAt, int count,
      int sortedBy, bool sortedAsc, {String? searchKey,Map<String,String>?filters}) async {
    if (startingAt == 0) {
      vehicles.clear();
    }
    return getSearchResult(searchKey,filters??{},count,startingAt,sortedBy,sortedAsc).then((value) {

      for (var element in value.documents) {
        if(!testIfVehiculesContained(element.$id)){
          vehicles.add(MapEntry(element.$id, element.convertTo<Vehicle>((p0) {
            return Vehicle.fromJson(p0 as Map<String, dynamic>);
          })));

        }

      }
      var result = vehicles;

      result.sort(_getComparisonFunction(sortedBy, sortedAsc));
      return VehiculesWebServiceResponse(
          value.total, result.skip(startingAt).take(count).toList());
    }).onError((error, stackTrace) {
      return Future.value(VehiculesWebServiceResponse(0, vehicles));
    });
  }



  Future<DocumentList> getSearchResult(String? searchKey,Map<String,String>filters,
      int count,int startingAt,int sortedBy,bool sortedAsc) async{

    if(searchKey!=null && searchKey.isNotEmpty){
      late DocumentList d;
      for(int i=0;i<8;i++){
         d=await ClientDatabase.database!.listDocuments(
            databaseId: databaseId,
            collectionId: vehiculeid,
            queries: [

              if(i==2)
                Query.equal('annee_util', int.tryParse(searchKey)??9999),
              if(i!=2)
              Query.search(getAttributeForSearch(i), searchKey),
              if(filters.containsKey('yearmin'))
                Query.greaterThanEqual('annee_util', int.tryParse(filters['yearmin']!)),
              if(filters.containsKey('yearmax'))
                Query.lessThanEqual('annee_util', int.tryParse(filters['yearmax']!)),
              if(filters.containsKey('genre'))
                Query.equal('genre', filters['genre']),
              if(filters.containsKey('marque'))
                Query.equal('marque', filters['marque']),
              Query.limit(count),
              Query.offset(startingAt),
              getQuery(sortedBy, sortedAsc),
            ]);
         if(d.documents.isNotEmpty){
           break;
         }
      }
      return d;
    }
    else{
      return await ClientDatabase.database!.listDocuments(
          databaseId: databaseId,
          collectionId: vehiculeid,
          queries: [
            if(filters.containsKey('yearmin'))
              Query.greaterThanEqual('annee_util', int.tryParse(filters['yearmin']!)),
            if(filters.containsKey('yearmax'))
              Query.lessThanEqual('annee_util', int.tryParse(filters['yearmax']!)),
            if(filters.containsKey('genre'))
              Query.equal('genre', filters['genre']),
            if(filters.containsKey('marque'))
              Query.equal('marque', filters['marque']),
            Query.limit(count),
            Query.offset(startingAt),
            getQuery(sortedBy, sortedAsc),

          ]);
    }
  }



  String getAttributeForSearch(int att){
    switch (att){
      case 0:return 'matricule';
      case 1:return 'type';
      case 3:return 'nom';
      case 4:return 'prenom';
      case 5:return 'numero_serie';
      case 6:return 'numero';
      case 7:return 'matricule_prec';
      default:return 'matricule';
    }
  }


  bool testIfVehiculesContained(String id){
    for(int i=0;i<vehicles.length;i++){
      if(vehicles[i].key==id){
        return true;
      }
    }
    return false;
  }

  String getQuery(int sortedBy, bool sortedAsc) {
    switch (sortedBy) {
      case 0:
        if (sortedAsc) {
          return Query.orderAsc('matricule');
        } else {
          return Query.orderDesc('matricule');
        }
      case 1:
        if (sortedAsc) {
          return Query.orderAsc('type');
        } else {
          return Query.orderDesc('type');
        }
      case 2:
        if (sortedAsc) {
          return Query.orderAsc('annee_util');
        } else {
          return Query.orderDesc('annee_util');
        }
      case 3:
        if (sortedAsc) {
          return Query.orderAsc('\$updatedAt');
        } else {
          return Query.orderDesc('\$updatedAt');
        }
    }
    return Query.orderAsc('\$id');
  }



}
