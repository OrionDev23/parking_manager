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
        if(!testIfVehiculesContained(element.$id)){
          documents.add(MapEntry(element.$id, element.convertTo<DocumentVehicle>((p0) {
            return DocumentVehicle.fromJson(p0 as Map<String, dynamic>);
          })));

        }

      }
      var result = documents;

      result.sort(_getComparisonFunction(sortedBy, sortedAsc));
      return DocumentWebServiceResponse(
          value.total, result.skip(startingAt).take(count).toList());
    }).onError((error, stackTrace) {
      return Future.value(DocumentWebServiceResponse(0, documents));
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
    for(int i=0;i<documents.length;i++){
      if(documents[i].key==id){
        return true;
      }
    }
    return false;
  }

  String getQuery(int sortedBy, bool sortedAsc) {
    switch (sortedBy) {
      case 1:
        if (sortedAsc) {
          return Query.orderAsc('matricule');
        } else {
          return Query.orderDesc('matricule');
        }
      case 2:
        if (sortedAsc) {
          return Query.orderAsc('type');
        } else {
          return Query.orderDesc('type');
        }
      case 4:
        if (sortedAsc) {
          return Query.orderAsc('annee_util');
        } else {
          return Query.orderDesc('annee_util');
        }
      case 6:
        if (sortedAsc) {
          return Query.orderAsc('\$updatedAt');
        } else {
          return Query.orderDesc('\$updatedAt');
        }
    }
    return Query.orderAsc('\$id');
  }
}
