import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';

import '../../serializables/vehicle/vehicle.dart';
import '../../utilities/vehicle_util.dart';

class VehiculesWebService extends ParcOtoWebService<Vehicle> {
  VehiculesWebService(super.data, super.collectionID, super.columnForSearch);

  @override
  String getAttributeForSearch(int att) {
    return 'search';
  }

  @override
  String getSearchQueryPerIndex(int index, String searchKey) {
    return Query.search(getAttributeForSearch(index), searchKey);
  }

  @override
  List<String> getFilterQueries(Map<String, String> filters, int count,
      int startingAt, int sortedBy, bool sortedAsc,
      {int? index}) {
    return [
      if (filters.containsKey('yearmin'))
        Query.greaterThanEqual('annee_util', int.tryParse(filters['yearmin']!)),
      if (filters.containsKey('yearmax'))
        Query.lessThanEqual('annee_util', int.tryParse(filters['yearmax']!)),
      if (filters.containsKey('genre')) Query.equal('genre', filters['genre']),
      if (filters.containsKey('marque'))
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
          return Query.orderAsc('etatactuel');
        } else {
          return Query.orderDesc('etatactuel');
        }
      case 4:
        if (sortedAsc) {
          return Query.orderAsc('\$updatedAt');
        } else {
          return Query.orderDesc('\$updatedAt');
        }
      case 5:
        if (sortedAsc) {
          return Query.orderAsc('perimetre');
        } else {
          return Query.orderDesc('perimetre');
        }
      case 6:
        if (sortedAsc) {
          return Query.orderAsc('appartenance');
        } else {
          return Query.orderDesc('appartenance');
        }
      case 7:
        if (sortedAsc) {
          return Query.orderAsc('\$id');
        } else {
          return Query.orderDesc('\$id');
        }
      case 8:
        if (sortedAsc) {
          return Query.orderAsc('direction');
        } else {
          return Query.orderDesc('direction');
        }
      case 9:
        if (sortedAsc) {
          return Query.orderAsc('matriculeConducteur');
        } else {
          return Query.orderDesc('matriculeConducteur');
        }
      case 10:
        if (sortedAsc) {
          return Query.orderAsc('nom');
        } else {
          return Query.orderDesc('nom');
        }
      case 11:
        if (sortedAsc) {
          return Query.orderAsc('prenom');
        } else {
          return Query.orderDesc('prenom');
        }
      case 12:
        if (sortedAsc) {
          return Query.orderAsc('profession');
        } else {
          return Query.orderDesc('profession');
        }
    }
    return Query.orderAsc('\$id');
  }

  @override
  int Function(MapEntry<String, Vehicle> p1, MapEntry<String, Vehicle> p2)?
      getComparisonFunction(int column, bool ascending) {
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
      case 3:
        return (d1, d2) =>
            coef *
            (d1.value.etatactuel ?? 0).compareTo(d2.value.etatactuel ?? 0);
      //date modif
      case 4:
        return (d1, d2) =>
            coef * d1.value.updatedAt!.compareTo(d2.value.updatedAt!);
      case 5:
        return (d1, d2) =>
        coef *
            d1.value.perimetre .compareTo(d2.value.perimetre );
      case 6:
        return (d1, d2) {
          return coef * (d1.value.appartenance ?? '').compareTo((d2.value.appartenance ?? ''));
        };

      case 7:return (d1, d2) {
        return coef * (int.tryParse(d1.value.id)??0).compareTo(int.tryParse(d2.value
            .id)??0);
      };
      case 8:return (d1, d2) {
        return coef * (d1.value.direction??'').compareTo((d2.value
            .direction??''));
      };
      case 9:return (d1, d2) {
        return coef * (d1.value.matriculeConducteur??'').compareTo((d2.value
            .matriculeConducteur??''));
      };
      case 10:return (d1, d2) {
        return coef * (d1.value.nom??'').compareTo((d2.value
            .nom??''));
      };
      case 11:return (d1, d2) {
        return coef * (d1.value.prenom??'').compareTo((d2.value
            .prenom??''));
      };
      case 12:return (d1, d2) {
        return coef * (d1.value.profession??'').compareTo((d2.value
            .profession??''));
      };
      default:
        return (d1, d2) => coef * d1.key.compareTo(d2.key);
    }
  }

  @override
  Vehicle fromJsonFunction(Map<String, dynamic> json) {
    return Vehicle.fromJson(json);
  }
}
