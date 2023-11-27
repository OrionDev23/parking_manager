import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';

import '../../serializables/vehicle.dart';
import '../../utilities/vehicle_util.dart';


class VehiculesWebService extends ParcOtoWebService {
  VehiculesWebService(super.data, super.collectionID, super.columnForSearch);



  @override
  String getAttributeForSearch(int att) {
    switch (att) {
      case 0:
        return 'matricule';
      case 1:
        return 'type';
      case 3:
        return 'nom';
      case 4:
        return 'prenom';
      case 5:
        return 'numero_serie';
      case 6:
        return 'numero';
      case 7:
        return 'matricule_prec';
      default:
        return 'matricule';
    }
  }

  @override
  String getSearchQueryPerIndex(int index,String searchKey){
    switch(index){
      case 2: return Query.equal('annee_util', int.tryParse(searchKey)??9999);
      default: return Query.search(getAttributeForSearch(index), searchKey);
    }
  }

  @override
  List<String> getFilterQueries(Map<String,String>filters,
      int count,int startingAt,int sortedBy,bool sortedAsc,{int? index}){
    return [
      if(filters.containsKey('yearmin'))
        Query.greaterThanEqual(
            'annee_util', int.tryParse(filters['yearmin']!)),
      if(filters.containsKey('yearmax'))
        Query.lessThanEqual(
            'annee_util', int.tryParse(filters['yearmax']!)),
      if(filters.containsKey('genre'))
        Query.equal('genre', filters['genre']),
      if(filters.containsKey('marque'))
        Query.equal('marque', filters['marque']),
    ];
  }

  @override
  String getSortingQuery(int sortedBy, bool sortedAsc) {
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

  @override
  fromJsonFunction(Map<String, dynamic> json) {
    return Vehicle.fromJson(json);
  }

  @override
  num Function(MapEntry<String, dynamic> p1, MapEntry<String,
      dynamic> p2)? getComparisonFunction(int column, bool ascending) {
    int coef = ascending ? 1 : -1;
    switch (column) {
    //matricule
      case 0:
        return (d1, d2) =>
        coef * d1.value.matricule.compareTo(d2.value.matricule);
    //marque
      case 1:
        return (d1, d2) {
          return coef * (d1.value.type ?? '').compareTo((d2.value.type ?? ''));
        };
    //annee
      case 2:
        return (d1, d2) {
          int annee1 = d1.value.anneeUtil ??
              VehiclesUtilities.getAnneeFromMatricule(d1.value.matricule);
          int annee2 = d2.value.anneeUtil ??
              VehiclesUtilities.getAnneeFromMatricule(d2.value.matricule);

          return coef * annee1.compareTo(annee2);
        };
    //date modif
      case 3:
        return (d1, d2) =>
        coef * d1.value.dateModification!.compareTo(d2.value.dateModification!);
      default:
        return (d1, d2) => coef * d1.key.compareTo(d2.key);
    }
  }
}