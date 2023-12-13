import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';
import 'package:parc_oto/serializables/reparation.dart';

class ReparationWebService extends ParcOtoWebService<Reparation> {
  ReparationWebService(super.data, super.collectionID, super.columnForSearch);

  @override
  fromJsonFunction(Map<String, dynamic> json) {
    return Reparation.fromJson(json);
  }

  @override
  String getAttributeForSearch(int att) {
    switch (att) {
      case 1:
        return 'vehiculemat';
      case 2:
        return 'prestatairenom';
      case 3:
        return 'nchassi';
      case 4:
        return 'modele';
      case 5:
        return 'designations';
    }
    return 'remarque';
  }

  @override
  String getSearchQueryPerIndex(int index, String searchKey) {
    switch (index) {
      case 0:
        return Query.equal('numero', int.tryParse(searchKey) ?? 0);
      default:
        return Query.search(getAttributeForSearch(index), searchKey);
    }
  }



  @override
  List<String> getFilterQueries(Map<String, String> filters, int count,
      int startingAt, int sortedBy, bool sortedAsc,
      {int? index}) {
    return [
      if (filters.containsKey('datemin'))
        Query.greaterThanEqual('date', int.tryParse(filters['datemin']!)),
      if (filters.containsKey('datemax'))
        Query.lessThanEqual('date', int.tryParse(filters['datemax']!)),
    ];
  }

  @override
  String getSortingQuery(int sortedBy, bool sortedAsc) {
    switch (sortedBy) {
      case 0:
        if (sortedAsc) {
          return Query.orderAsc('numero');
        } else {
          return Query.orderDesc('numero');
        }
      case 1:
        if (sortedAsc) {
          return Query.orderAsc('vehiculemat');
        } else {
          return Query.orderDesc('vehiculemat');
        }
      case 2:
        if (sortedAsc) {
          return Query.orderAsc('prestatairenom');
        } else {
          return Query.orderDesc('prestatairenom');
        }
      case 3:
        if (sortedAsc) {
          return Query.orderAsc('date');
        } else {
          return Query.orderDesc('date');
        }
      case 4:
        if (sortedAsc) {
          return Query.orderAsc('numero');
        } else {
          return Query.orderDesc('numero');
        }
      case 5:
        if (sortedAsc) {
          return Query.orderAsc('\$updatedAt');
        } else {
          return Query.orderDesc('\$updatedAt');
        }
    }
    return Query.orderAsc('\$id');
  }


  @override
  int Function(MapEntry<String, Reparation> p1, MapEntry<String, Reparation> p2)?
  getComparisonFunction(int column, bool ascending) {
    int coef = ascending ? 1 : -1;
    switch (column) {
    //matricule
      case 0:
        return (d1, d2) =>
        coef * d1.value.numero.compareTo(d2.value.numero);
    //marque
      case 1:
        return (d1, d2) {
          if(d1.value.vehiculemat==null && d2.value.vehiculemat==null){
            return 0;
          }
          return coef * (d1.value.vehiculemat ?? '').compareTo((d2.value.vehiculemat ?? ''));
        };
      case 2:
        return (d1, d2) {
          if(d1.value.prestatairenom==null && d2.value.prestatairenom==null){
            return 0;
          }
          return coef * (d1.value.prestatairenom ?? '').compareTo((d2.value.prestatairenom ?? ''));
        };
      case 3:
        return (d1, d2) {

          return coef * d1.value.date.compareTo(d2.value.date);
        };
      case 4:
        return (d1, d2) {

          return coef * d1.value.getPrixTotal().compareTo(d2.value.getPrixTotal());
        };
    //date modif
      case 5:
        return (d1, d2) =>
        coef * d1.value.updatedAt!.compareTo(d2.value.updatedAt!);
      default:
        return (d1, d2) => coef * d1.value.numero.compareTo(d2.value.numero);
    }
  }
}
