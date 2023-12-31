import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:parc_oto/serializables/activity.dart';

class LogWebService extends ParcOtoWebService<Activity>{
  LogWebService(super.data, super.collectionID, super.columnForSearch,);

  @override
  Activity fromJsonFunction(Map<String, dynamic> json) {
    return Activity.fromJson(json);
  }

  @override
  String getAttributeForSearch(int att) {
    return 'docName';
  }

  @override
  int Function(MapEntry<String, Activity> p1, MapEntry<String, Activity> p2)? getComparisonFunction(int column, bool ascending) {
    int coef = ascending ? 1 : -1;
    switch (column) {
    //type
      case 0:
        return ( d1, d2) =>
        coef * ClientDatabase().getActivityType(d1.value.type).compareTo(ClientDatabase().getActivityType(d2.value.type));
    //vehicle
      case 1:
        return ( d1, d2) {

            return coef * (d1.value.docName??'').compareTo(d2.value.docName??'');
        };
    //date modif
      case 2:
        return ( d1,  d2) =>
        coef * d1.value.updatedAt!.compareTo(d2.value.updatedAt!);
    }

    return null;
  }



  @override
  List<String> getFilterQueries(Map<String, String> filters, int count, int startingAt, int sortedBy, bool sortedAsc, {int? index}) {
    return [
      if(filters.containsKey('datemin'))
        Query.greaterThanEqual('date_expiration', int.tryParse(filters['datemin']!)),
      if(filters.containsKey('datemax'))
        Query.lessThanEqual('date_expiration', int.tryParse(filters['datemax']!)),
      if(filters.containsKey('createdBy'))
        Query.equal('createdBy', filters['createdBy']),
      if(filters.containsKey('type'))
        Query.equal('type', filters['type']),
    ];
  }


  @override
  String getSortingQuery(int sortedBy, bool sortedAsc) {
    switch (sortedBy) {
      case 0:
        if (sortedAsc) {
          return Query.orderAsc('type');
        } else {
          return Query.orderDesc('type');
        }
      case 1:
        if (sortedAsc) {
          return Query.orderAsc('docName');
        } else {
          return Query.orderDesc('docName');
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

}