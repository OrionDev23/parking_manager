import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:parc_oto/serializables/document_vehicle.dart';

import '../../providers/client_database.dart';
import 'document_datasource.dart';

class DocumentWebServiceResponse {
  DocumentWebServiceResponse(this.totalRecords, this.data);

  /// THe total ammount of records on the server, e.g. 100
  final int totalRecords;

  /// One page, e.g. 10 reocrds
  final List<MapEntry<String,DocumentVehicle>> data;
}

class DocumentWebService {
  int Function(MapEntry<String,DocumentVehicle>, MapEntry<String,DocumentVehicle>)? _getComparisonFunction(
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
            coef * d1.value.dateModif!.compareTo(d2.value.dateModif!);
    }

    return null;
  }

  Future<DocumentWebServiceResponse> getData(int startingAt, int count,
      int sortedBy, bool sortedAsc, {String? searchKey,Map<String,String>?filters}) async {
    if (startingAt == 0) {
      documents.clear();
    }
    return getSearchResult(searchKey,filters??{},count,startingAt,sortedBy,sortedAsc).then((value) {

      for (var element in value.documents) {
        if(!testIfContained(element.$id)){
          documents.add(MapEntry(element.$id, element.convertTo<DocumentVehicle>((p0) {
            return DocumentVehicle.fromJson(p0 as Map<String, dynamic>);
          })));

        }

      }
      var result = documents;

      result.sort(_getComparisonFunction(sortedBy, sortedAsc));
      return DocumentWebServiceResponse(
          value.total, result.skip(startingAt).take(count).toList());
    }).onError((AppwriteException error, stackTrace) {
      return Future.value(DocumentWebServiceResponse(0, documents));
    });
  }



  Future<DocumentList> getSearchResult(String? searchKey,Map<String,String>filters,
      int count,int startingAt,int sortedBy,bool sortedAsc) async{

    if(searchKey!=null && searchKey.isNotEmpty){


      return  await ClientDatabase.database!.listDocuments(
          databaseId: databaseId,
          collectionId: vehicDoc,
          queries: [
            getQuery(sortedBy, sortedAsc),
            Query.search('nom', searchKey),
            if(filters.containsKey('datemin'))
              Query.greaterThanEqual('date_expiration', int.tryParse(filters['datemin']!)),
            if(filters.containsKey('datemax'))
              Query.lessThanEqual('date_expiration', int.tryParse(filters['datemax']!)),
            if(filters.containsKey('createdBy'))
              Query.equal('createdBy', filters['createdBy']),
            if(filters.containsKey('vehicle'))
              Query.equal('vehicle', filters['vehicle']),
            Query.limit(count),
            Query.offset(startingAt),
          ]);
    }
    else{
      return await ClientDatabase.database!.listDocuments(
          databaseId: databaseId,
          collectionId: vehicDoc,
          queries: [
            getQuery(sortedBy, sortedAsc),
            if(filters.containsKey('datemin'))
              Query.greaterThanEqual('date_expiration', int.tryParse(filters['datemin']!)),
            if(filters.containsKey('datemax'))
              Query.lessThanEqual('date_expiration', int.tryParse(filters['datemax']!)),
            if(filters.containsKey('createdBy'))
              Query.equal('createdBy', filters['createdBy']),
            if(filters.containsKey('vehicle'))
              Query.equal('vehicle', filters['vehicle']),
            Query.limit(count),
            Query.offset(startingAt),
          ]).onError((AppwriteException error, stackTrace) {
            return Future.value(DocumentList.fromMap({}));      });
    }
  }



  bool testIfContained(String id){
    for(int i=0;i<documents.length;i++){
      if(documents[i].key==id){
        return true;
      }
    }
    return false;
  }

  String getQuery(int sortedBy, bool sortedAsc) {
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
}
