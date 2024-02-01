import 'package:appwrite/appwrite.dart';

import '../../serializables/vehicle/state.dart';
import '../parcoto_webservice.dart';

class VehicleStateWebservice extends ParcOtoWebService<Etat> {
  VehicleStateWebservice(super.data, super.collectionID, super.columnForSearch);

  @override
  Etat fromJsonFunction(Map<String, dynamic> json) {
    return Etat.fromJson(json);
  }

  @override
  String getAttributeForSearch(int att) {
    switch (att) {
      case 0:
        return 'vehicleMat';
      case 1:
        return 'remarque';
      case 2:
        return 'orderNum';
      default:
        return r"$id";
    }
  }

  @override
  int Function(MapEntry<String, Etat> p1, MapEntry<String, Etat> p2)?
      getComparisonFunction(int column, bool ascending) {
    int coef = ascending ? 1 : -1;
    switch (column) {
      case 0:
        return (d1, d2) =>
            coef * (d1.value.vehicleMat).compareTo(d2.value.vehicleMat);
      case 1:
        return (d1, d2) => coef * d1.value.type.compareTo(d2.value.type);

      case 2:
        return (d1, d2) =>
            coef *
            (d1.value.date ?? d1.value.createdAt!)
                .compareTo(d2.value.date ?? d1.value.createdAt!);
      case 3:
        return (d1, d2) =>
            coef * (d1.value.remarque ?? '').compareTo(d2.value.remarque ?? '');
      case 4:
        return (d1, d2) =>
            coef * (d1.value.ordreNum ?? 0).compareTo(d2.value.ordreNum ?? 0);
      case 5:
        return (d1, d2) =>
            coef * d1.value.updatedAt!.compareTo(d2.value.updatedAt!);
    }
    return null;
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
          return Query.orderAsc('vehicleMat');
        } else {
          return Query.orderDesc('vehicleMat');
        }
      case 2:
        if (sortedAsc) {
          return Query.orderAsc('date');
        } else {
          return Query.orderDesc('date');
        }
      case 3:
        if (sortedAsc) {
          return Query.orderAsc('remarque');
        } else {
          return Query.orderDesc('remarque');
        }
      case 4:
        if (sortedAsc) {
          return Query.orderAsc('ordreNum');
        } else {
          return Query.orderDesc('ordreNum');
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
  List<String> getFilterQueries(Map<String, String> filters, int count,
      int startingAt, int sortedBy, bool sortedAsc,
      {int? index}) {
    return [
      if (filters.containsKey('type'))
        Query.equal('type', int.tryParse(filters['type']!)),
      if (filters.containsKey('datemin'))
        Query.greaterThanEqual('date', int.tryParse(filters['datemin']!)),
      if (filters.containsKey('datemax'))
        Query.lessThanEqual('date', int.tryParse(filters['datemax']!)),
      if (filters.containsKey('createdBy'))
        Query.equal('createdBy', filters['createdBy']),
      if (filters.containsKey('vehicle'))
        Query.equal('vehicleMat', filters['vehicle']),
    ];
  }
}
