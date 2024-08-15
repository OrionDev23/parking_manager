import 'package:appwrite/appwrite.dart';

import '../../../serializables/pieces/brand.dart';
import '../../parcoto_webservice.dart';

class BrandWebservice extends ParcOtoWebService<Brand>{
  BrandWebservice(super.data, super.collectionID, super.columnForSearch);

  @override
  Brand fromJsonFunction(Map<String, dynamic> json) {
    return Brand.fromJson(json);
  }

  @override
  String getAttributeForSearch(int att) {
    return 'search';
  }

  @override
  int Function(MapEntry<String, Brand> p1, MapEntry<String, Brand> p2)? getComparisonFunction(int column, bool ascending){
    int coef = ascending ? 1 : -1;
    switch (column) {
      case 0:
        return (d1, d2) => coef * d1.value.code.compareTo(d2.value.code);
      case 1:
        return (d1, d2) {
          return coef * d1.value.name.compareTo(d2.value.name);
        };

      case 2:
        return (d1, d2) =>
        coef * d1.value.updatedAt!.compareTo(d2.value.updatedAt!);
    }

    return  (d1, d2) =>
    coef * d1.value.id.compareTo(d2.value.id);
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
          return Query.orderAsc('code');
        } else {
          return Query.orderDesc('code');
        }
      case 1:
        if (sortedAsc) {
          return Query.orderAsc('name');
        } else {
          return Query.orderDesc('name');
        }
      case 2:
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