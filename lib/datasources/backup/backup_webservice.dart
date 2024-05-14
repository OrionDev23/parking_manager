import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';
import 'package:parc_oto/serializables/backup.dart';

class BackupWebService extends ParcOtoWebService<Backup> {
  BackupWebService(super.data, super.collectionID, super.columnForSearch);

  @override
  String getAttributeForSearch(int att) {
    return 'search';
  }

  @override
  String getSearchQueryPerIndex(int index, String searchKey) {
    switch (index) {
      case 2:
        return Query.equal('annee_util', int.tryParse(searchKey) ?? 9999);
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
        Query.greaterThanEqual('\$createdAt', filters['datemin']!),
      if (filters.containsKey('datemax'))
        Query.lessThanEqual('\$createdAt', filters['datemax']!),
    ];
  }

  @override
  String getSortingQuery(int sortedBy, bool sortedAsc) {
    switch (sortedBy) {
      case 0:
        if (sortedAsc) {
          return Query.orderAsc('\$id');
        } else {
          return Query.orderDesc('\$id');
        }
      case 1:
        if (sortedAsc) {
          return Query.orderAsc('vehicles');
        } else {
          return Query.orderDesc('vehicles');
        }
      case 2:
        if (sortedAsc) {
          return Query.orderAsc('createdBy');
        } else {
          return Query.orderDesc('createdBy');
        }
        default:
          if (sortedAsc) {
            return Query.orderAsc('\$id');
          } else {
            return Query.orderDesc('\$id');
          }
    }
  }


  @override
  Backup fromJsonFunction(Map<String, dynamic> json) {
    return Backup.fromJson(json);
  }

  @override
  int Function(MapEntry<String, Backup> p1, MapEntry<String, Backup> p2)? getComparisonFunction(int column, bool ascending) {
    int coef = ascending ? 1 : -1;
    switch(column){
      case 0:
        return (d1, d2) =>
        coef * d1.value.id.compareTo(d2.value.id);
      case 1:
        return (d1,d2)=>
        coef * d1.value.vehicles.compareTo(d2.value.vehicles);
      case 2:
        return (d1,d2)=>
        coef * (d1.value.createdBy??'').compareTo(d2.value.createdBy??'');
      default:
        return (d1, d2) =>
        coef * d1.value.id.compareTo(d2.value.id);
    }
  }
}
