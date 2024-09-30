import 'package:appwrite/appwrite.dart';
import '../../../serializables/pieces/part.dart';

import '../../parcoto_webservice.dart';

class PartsWebservice extends ParcOtoWebService<VehiclePart> {
  PartsWebservice(super.data, super.collectionID, super.columnForSearch);

  @override
  VehiclePart fromJsonFunction(Map<String, dynamic> json) {
    return VehiclePart.fromJson(json);
  }

  @override
  String getAttributeForSearch(int att) {
    return 'search';
  }

  @override
  int Function(
          MapEntry<String, VehiclePart> p1, MapEntry<String, VehiclePart> p2)?
      getComparisonFunction(int column, bool ascending) {
    int coef = ascending ? 1 : -1;
    switch (column) {
      case 0:
        return (d1, d2) => coef * d1.value.id.compareTo(d2.value.id);
      case 1:
        return (d1, d2) {
          return coef * (d1.value.sku ?? '').compareTo(d2.value.sku ?? '');
        };
      case 2:
        return (d1, d2) {
          return coef *
              (d1.value.barcode ?? '').compareTo(d2.value.barcode ?? '');
        };
      case 3:
        return (d1, d2) {
          return coef * d1.value.name.compareTo(d2.value.name);
        };

      case 4:
        return (d1, d2) {
          return coef *
              (d1.value.variations?.first.name??"")
                  .compareTo((d2.value.variations?.first.name??''));
        };
      case 5:
        return (d1, d2) =>
            coef * d1.value.updatedAt!.compareTo(d2.value.updatedAt!);
    }

    return (d1, d2) => coef * d1.value.id.compareTo(d2.value.id);
  }

  @override
  List<String> getFilterQueries(Map<String, String> filters, int count,
      int startingAt, int sortedBy, bool sortedAsc,
      {int? index}) {
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
          return Query.orderAsc('sku');
        } else {
          return Query.orderDesc('sku');
        }
      case 2:
        if (sortedAsc) {
          return Query.orderAsc('barcode');
        } else {
          return Query.orderDesc('barcode');
        }
      case 3:
        if (sortedAsc) {
          return Query.orderAsc('name');
        } else {
          return Query.orderDesc('name');
        }
      case 4:
        if (sortedAsc) {
          return Query.orderAsc('variations');
        } else {
          return Query.orderDesc('variations');
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
