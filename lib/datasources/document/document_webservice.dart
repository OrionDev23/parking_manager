import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';
import 'package:parc_oto/serializables/document_vehicle.dart';

import 'document_datasource.dart';


class DocumentWebService extends ParcOtoWebService{
  DocumentWebService(super.data, super.collectionID, super.columnForSearch);

  @override
  num Function(MapEntry<String,dynamic>, MapEntry<String,dynamic>)? getComparisonFunction(
      int column, bool ascending) {
    int coef = ascending ? 1 : -1;
    switch (column) {
      //id
      case 0:
        return ( d1,  d2) => coef * d1.key.compareTo(d2.key);
      //nom
      case 1:
        return ( d1, d2) =>
            coef * d1.value.nom.compareTo(d2.value.nom);
      //vehicle
      case 2:
        return ( d1, d2) {
          if (d1.value.vehicle == null && d2.value.vehicle == null) {
            return -1;
          } else if (d2.value.vehicle == d1.value.vehicle) {
            return 0;
          } else {
            return coef * d1.value.vehicle!.id!.compareTo(d2.value.vehicle!.id!);
          }
        };
      //date d'expiration
      case 3:
        return ( d1,  d2) =>
            coef * d1.value.dateExpiration!.compareTo(d2.value.dateExpiration!);
      //date modif
      case 4:
        return ( d1,  d2) =>
            coef * d1.value.updatedAt!.compareTo(d2.value.updatedAt!);
    }

    return null;
  }






  bool testIfContained(String id){
    for(int i=0;i<documents.length;i++){
      if(documents[i].key==id){
        return true;
      }
    }
    return false;
  }

  @override
  String getSortingQuery(int sortedBy, bool sortedAsc) {
    switch (sortedBy) {
      case 0:
        if (sortedAsc) {
          return Query.orderAsc('nom');
        } else {
          return Query.orderDesc('nom');
        }
      case 1:
        if (sortedAsc) {
          return Query.orderAsc('date_expiration');
        } else {
          return Query.orderDesc('date_expiration');
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

  @override
  fromJsonFunction(Map<String, dynamic> json) {
    return DocumentVehicle.fromJson(json);
  }

  @override
  String getAttributeForSearch(int att) {
    return 'nom';
  }

  @override
  List<String> getFilterQueries(Map<String, String> filters, int count, int startingAt, int sortedBy, bool sortedAsc, {int? index}) {
    return [
      if(filters.containsKey('datemin'))
        Query.greaterThanEqual('date_expiration', int.tryParse(filters['datemin']!)),
      if(filters.containsKey('datemax'))
        Query.lessThanEqual('date_expiration', int.tryParse(filters['datemax']!)),
      if(filters.containsKey('createdBy'))
        Query.equal('createdBy', filters['createdBy']),
      if(filters.containsKey('vehicle'))
        Query.equal('vehicle', filters['vehicle']),
    ];
  }


}
