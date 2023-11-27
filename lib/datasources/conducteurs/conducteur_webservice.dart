import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';
import 'package:parc_oto/providers/client_database.dart';

import '../../serializables/conducteur.dart';

class ConducteurWebService extends ParcOtoWebService{
  ConducteurWebService(super.data, super.collectionID, super.columnForSearch);

  @override
  fromJsonFunction(Map<String, dynamic> json) {
    return Conducteur.fromJson(json);
  }

  @override
  String getAttributeForSearch(int att) {
    return 'search';
  }

  @override
  num Function(MapEntry<String, dynamic> p1, MapEntry<String, dynamic> p2)? getComparisonFunction(int column, bool ascending) {
    int coef = ascending ? 1 : -1;
    switch (column) {
    //id
      case 0:
        return ( d1, d2) =>
        coef * '${d1.value.name} ${d1.value.prenom}'.compareTo('${d2.value.name} ${d2.value.prenom}');
    //vehicle
      case 1:
        return ( d1, d2) {
          if (d1.value.email == null || d2.value.email == null) {
            return 0;
          } else if (d2.value.email == d1.value.email) {
            return 0;
          } else {
            return coef * d1.value.email!.id!.compareTo(d2.value.email!.id!);
          }
        };
      case 2:
        return ( d1, d2) {
          if (d1.value.telephone == null || d2.value.telephone == null) {
            return 0;
          } else if (d2.value.telephone == d1.value.telephone) {
            return 0;
          } else {
            return coef * d1.value.telephone!.id!.compareTo(d2.value.telephone!.id!);
          }
        };
      case 3:
        return ( d1, d2) {
          if (d1.value.adresse == null || d2.value.adresse == null) {
            return 0;
          } else if (d2.value.adresse == d1.value.adresse) {
            return 0;
          } else {
            return coef * d1.value.adresse!.id!.compareTo(d2.value.adresse!.id!);
          }
        };
    //date d'expiration
    //date modif
      case 4:
        return ( d1,  d2) =>
        coef * d1.value.updatedAt!.compareTo(d2.value.updatedAt!);
    }

    return null;
  }

  @override
  List<String> getFilterQueries(Map<String, String> filters, int count, int startingAt, int sortedBy, bool sortedAsc, {int? index}) {
    return [
      if(filters.containsKey('agemin'))
        Query.greaterThanEqual('dateNaissance', DateTime.now().add(Duration(days: 365 * int.parse(filters['agemin']!))).difference(ClientDatabase.ref).inMilliseconds),
      if(filters.containsKey('agemax'))
        Query.greaterThanEqual('dateNaissance', DateTime.now().add(Duration(days: 365 * int.parse(filters['agemax']!))).difference(ClientDatabase.ref).inMilliseconds),
    ];
  }

  @override
  String getSortingQuery(int sortedBy, bool sortedAsc) {
    switch (sortedBy) {
      case 0:
        if (sortedAsc) {
          return Query.orderAsc('name');
        } else {
          return Query.orderDesc('name');
        }
      case 1:
        if (sortedAsc) {
          return Query.orderAsc('prenom');
        } else {
          return Query.orderDesc('prenom');
        }
      case 2:if (sortedAsc) {
        return Query.orderAsc('email');
      } else {
        return Query.orderDesc('email');
      }
      case 3:if (sortedAsc) {
        return Query.orderAsc('telephone');
      } else {
        return Query.orderDesc('telephone');
      }
      case 4:if (sortedAsc) {
        return Query.orderAsc('adresse');
      } else {
        return Query.orderDesc('adresse');
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

}