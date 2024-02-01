import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';
import 'package:parc_oto/serializables/conducteur/disponibilite_chauffeur.dart';

class DisponibiliteWebService
    extends ParcOtoWebService<DisponibiliteChauffeur> {
  DisponibiliteWebService(
      super.data, super.collectionID, super.columnForSearch);

  @override
  DisponibiliteChauffeur fromJsonFunction(Map<String, dynamic> json) {
    return DisponibiliteChauffeur.fromJson(json);
  }

  @override
  String getAttributeForSearch(int att) {
    return 'chauffeurNom';
  }

  @override
  int Function(MapEntry<String, DisponibiliteChauffeur> p1,
          MapEntry<String, DisponibiliteChauffeur> p2)?
      getComparisonFunction(int column, bool ascending) {
    int coef = ascending ? 1 : -1;
    switch (column) {
      //id
      case 0:
        return (d1, d2) =>
            coef * d1.value.chauffeurNom.compareTo(d2.value.chauffeurNom);
      //vehicle
      case 1:
        return (d1, d2) {
          return coef * d1.value.type.compareTo(d2.value.type);
        };
      case 2:
        return (d1, d2) =>
            coef * d1.value.createdAt!.compareTo(d2.value.createdAt!);
    }

    return null;
  }

  @override
  List<String> getFilterQueries(Map<String, String> filters, int count,
      int startingAt, int sortedBy, bool sortedAsc,
      {int? index}) {
    return [
      if (filters.containsKey('type'))
        Query.equal('type', int.parse(filters['type']!)),
      if (filters.containsKey('datemin'))
        Query.greaterThanEqual(r'$createdAt', filters['dateMin']),
      if (filters.containsKey('datemax'))
        Query.lessThanEqual(r'$createdAt', filters['dateMax']),
    ];
  }

  @override
  String getSortingQuery(int sortedBy, bool sortedAsc) {
    switch (sortedBy) {
      case 0:
        if (sortedAsc) {
          return Query.orderAsc('chauffeurNom');
        } else {
          return Query.orderDesc('chauffeurNom');
        }
      case 1:
        if (sortedAsc) {
          return Query.orderAsc('type');
        } else {
          return Query.orderDesc('type');
        }
      case 2:
        if (sortedAsc) {
          return Query.orderAsc('\$createdAt');
        } else {
          return Query.orderDesc('\$createdAt');
        }
    }
    return Query.orderAsc('\$id');
  }
}
