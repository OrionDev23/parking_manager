import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';
import '../../serializables/conducteur/document_chauffeur.dart';


class ChaufDocumentWebService extends ParcOtoWebService<DocumentChauffeur>{
  ChaufDocumentWebService(super.data, super.collectionID, super.columnForSearch);

  @override
  int Function(MapEntry<String,DocumentChauffeur>, MapEntry<String,DocumentChauffeur>)? getComparisonFunction(
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
          if (d1.value.chauffeurNom == null || d2.value.chauffeurNom == null) {
            return 0;
          } else if (d2.value.chauffeurNom == d1.value.chauffeurNom) {
            return 0;
          } else {
            return coef * d1.value.chauffeurNom!.compareTo(d2.value.chauffeurNom!);
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
          return Query.orderAsc('chauffeurNom');
        } else {
          return Query.orderDesc('chauffeurNom');
        }
      case 2:
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
  DocumentChauffeur fromJsonFunction(Map<String, dynamic> json) {
    return DocumentChauffeur.fromJson(json);
  }

  @override
  String getAttributeForSearch(int att) {
    switch(att){
      case 0:return 'nom';
      case 1:return 'chaffeurNom';
      default:return 'nom';
    }
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
      if(filters.containsKey('chauffeur'))
        Query.equal('chauffeurNom', filters['chauffeur']),
    ];
  }


}
