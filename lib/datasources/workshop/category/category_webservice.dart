import 'package:appwrite/appwrite.dart';

import '../../../serializables/pieces/category.dart';
import '../../parcoto_webservice.dart';

class CategoryWebservice extends ParcOtoWebService<Category>{
  CategoryWebservice(super.data, super.collectionID, super.columnForSearch);

  @override
  Category fromJsonFunction(Map<String, dynamic> json) {
    return Category.fromJson(json);
  }

  @override
  String getAttributeForSearch(int att) {
    return 'search';
  }

  @override
  int Function(MapEntry<String, Category> p1, MapEntry<String, Category> p2)? getComparisonFunction(int column, bool ascending){
    int coef = ascending ? 1 : -1;
    switch (column) {
      case 0:
        return (d1, d2) => coef * d1.value.code.compareTo(d2.value.code);
      case 1:
        return (d1, d2) {
          return coef * d1.value.name.compareTo(d2.value.name);
        };

      case 2:
        return (d1, d2) {
          return coef * (d1.value.codeParent??'').compareTo((d2
              .value.codeParent??''));
        };
      case 3:
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
          return Query.orderAsc('codeParent');
        } else {
          return Query.orderDesc('codeParent');
        }
      case 3:
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