import 'package:appwrite/appwrite.dart';
import '../parcoto_webservice.dart';
import '../../serializables/reparation/fiche_reception.dart';
class FicheReceptionWebService extends ParcOtoWebService<FicheReception> {
  FicheReceptionWebService(super.data, super.collectionID, super.columnForSearch);

  @override
  fromJsonFunction(Map<String, dynamic> json) {
    return FicheReception.fromJson(json);
  }

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
      if (filters.containsKey('datemin'))
        Query.greaterThanEqual('dateEntre', int.tryParse(filters['datemin']!)),
      if (filters.containsKey('datemax'))
        Query.lessThanEqual('dateEntre', int.tryParse(filters['datemax']!)),
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
          return Query.orderAsc('nchassi');
        } else {
          return Query.orderDesc('nchassi');
        }
      case 2:
        if (sortedAsc) {
          return Query.orderAsc('vehiculemat');
        } else {
          return Query.orderDesc('vehiculemat');
        }
      case 3:
        if (sortedAsc) {
          return Query.orderAsc('reparationNumero');
        } else {
          return Query.orderDesc('reparationNumero');
        }
      case 4:
        if (sortedAsc) {
          return Query.orderAsc('dateEntre');
        } else {
          return Query.orderDesc('dateEntre');
        }
      case 5:
        if (sortedAsc) {
          return Query.orderAsc('dateSortie');
        } else {
          return Query.orderDesc('dateSortie');
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

  @override
  int Function(
      MapEntry<String, FicheReception> p1, MapEntry<String, FicheReception> p2)?
  getComparisonFunction(int column, bool ascending) {
    int coef = ascending ? 1 : -1;
    switch (column) {
    //numero
      case 0:
        return (d1, d2) => coef * d1.value.numero.compareTo(d2.value.numero);
    //nchassi
      case 1:
        return (d1, d2) {
          if (d1.value.nchassi == null && d2.value.nchassi == null) {
            return 0;
          }
          return coef *
              (d1.value.nchassi ?? '')
                  .compareTo((d2.value.nchassi ?? ''));
        };
      case 2:
        return (d1, d2) {
          if (d1.value.vehiculemat == null && d2.value.vehiculemat == null) {
            return 0;
          }
          return coef *
              (d1.value.vehiculemat ?? '')
                  .compareTo((d2.value.vehiculemat ?? ''));
        };
      case 3:
        return (d1, d2) {
          if (d1.value.reparationNumero == null &&
              d2.value.reparationNumero == null) {
            return 0;
          }
          return coef *
              (d1.value.reparationNumero ?? 0)
                  .compareTo((d2.value.reparationNumero ?? 0));
        };
      case 4:
        return (d1, d2) {
          return coef * d1.value.dateEntre.compareTo(d2.value.dateEntre);
        };
      case 5:
        return (d1, d2) {
          return coef * (d1.value.dateSortie??DateTime.now()).compareTo(d2.value.dateSortie??DateTime.now());
        };
    //date modif
      case 6:
        return (d1, d2) =>
        coef * d1.value.updatedAt!.compareTo(d2.value.updatedAt!);
      default:
        return (d1, d2) => coef * d1.value.numero.compareTo(d2.value.numero);
    }
  }
}
