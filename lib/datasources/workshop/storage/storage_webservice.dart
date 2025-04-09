import 'package:appwrite/appwrite.dart' hide Storage;
import '../../parcoto_webservice.dart';
import '../../../utilities/profil_beautifier.dart';

import '../../../serializables/pieces/storage.dart';

class StorageWebservice extends ParcOtoWebService<Storage>{
  StorageWebservice(super.data, super.collectionID, super.columnForSearch);

  @override
  Storage fromJsonFunction(Map<String, dynamic> json) {
   return Storage.fromJson(json);
  }

  @override
  String getAttributeForSearch(int att) {
    return 'search';
  }

  @override
  int Function(MapEntry<String, Storage> p1, MapEntry<String, Storage> p2)? getComparisonFunction(int column, bool ascending) {
    int coef = ascending ? 1 : -1;
    switch (column) {
      case 0:
        return (d1, d2) => coef * d1.value.id.compareTo(d2.value.id);
      case 1:
        return (d1, d2) {
          return coef * (d1.value.pieceName).compareTo(d2.value.pieceName);
        };
      case 2:
        return (d1, d2) {
          return coef *
              (d1.value.fournisseurName ?? '').compareTo(d2.value.fournisseurName ?? '');
        };
      case 3:
        return (d1, d2) {
          return coef * (dlistToString(d1.value.variations)).compareTo(dlistToString(d2.value.variations));
        };

      case 4:
        return (d1, d2) {
          return coef *
              d1.value.qte
                  .compareTo(d2.value.qte);
        };
      case 5:
        return (d1, d2) =>
        coef * d1.value.updatedAt!.compareTo(d2.value.updatedAt!);
    }

    return (d1, d2) => coef * d1.value.id.compareTo(d2.value.id);
  }

  @override
  List<String> getFilterQueries(Map<String, String> filters, int count, int startingAt, int sortedBy, bool sortedAsc, {int? index}) {
    return [];
  }

  @override
  String getSortingQuery(int sortedBy, bool sortedAsc) {
    switch (sortedBy) {
      case 0:
        if (sortedAsc) {
          return Query.orderAsc(r'$id');
        } else {
          return Query.orderDesc(r'$id');
        }
      case 1:
        if (sortedAsc) {
          return Query.orderAsc('pieceName');
        } else {
          return Query.orderDesc('pieceName');
        }
      case 2:
        if (sortedAsc) {
          return Query.orderAsc('fournisseurName');
        } else {
          return Query.orderDesc('fournisseurName');
        }
      case 3:
        if (sortedAsc) {
          return Query.orderAsc('variations');
        } else {
          return Query.orderDesc('variations');
        }

      case 4:
        if (sortedAsc) {
          return Query.orderAsc('qte');
        } else {
          return Query.orderDesc('qte');
        }
      case 5:
        if (sortedAsc) {
          return Query.orderAsc(r'$updatedAt');
        } else {
          return Query.orderDesc(r'$updatedAt');
        }
      default:
        if (sortedAsc) {
          return Query.orderAsc(r'$id');
        } else {
          return Query.orderDesc(r'$id');
        }
    }
  }

}