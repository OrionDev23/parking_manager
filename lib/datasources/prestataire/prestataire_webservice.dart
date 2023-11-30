import 'package:parc_oto/datasources/parcoto_webservice.dart';
import 'package:parc_oto/serializables/prestataire.dart';

class PrestataireWebservice extends ParcOtoWebService<Prestataire>{
  PrestataireWebservice(super.data, super.collectionID, super.columnForSearch);

  @override
  Prestataire fromJsonFunction(Map<String, dynamic> json) {
    return Prestataire.fromJson(json);
  }

  @override
  String getAttributeForSearch(int att) {
    return 'search';
  }

  @override
  int Function(MapEntry<String, Prestataire> p1, MapEntry<String, Prestataire> p2)? getComparisonFunction(int column, bool ascending) {
    int coef = ascending ? 1 : -1;
    switch (column) {
      case 0:
        return ( d1,  d2) => coef * d1.value.nom.compareTo(d2.value.nom);
      case 1:
        return ( d1, d2) {
          if(d1.value.telephone==null || d2.value.telephone==null){
            return coef;
          }
          else if(d1.value.telephone==d2.value.telephone){
            return 0;
          }
          return  coef * d1.value.telephone!.compareTo(d2.value.telephone!);
        };

      case 2:
        return ( d1, d2) {
          if (d1.value.email == null || d2.value.email == null) {
            return coef;
          } else if (d2.value.email == d1.value.email) {
            return 0;
          } else {
            return coef * d1.value.email!.compareTo(d2.value.email!);
          }
        };
      case 3:
        return ( d1, d2) {
          if (d1.value.nif == null || d2.value.nif == null) {
            return coef;
          } else if (d2.value.nif == d1.value.nif) {
            return 0;
          } else {
            return coef * d1.value.nif!.compareTo(d2.value.nif!);
          }
        };
      case 4:
        return ( d1, d2) {
          if (d1.value.rc == null || d2.value.rc == null) {
            return coef;
          } else if (d2.value.rc == d1.value.rc) {
            return 0;
          } else {
            return coef * d1.value.rc!.compareTo(d2.value.rc!);
          }
        };
      case 5:
        return ( d1,  d2) =>
        coef * d1.value.updatedAt!.compareTo(d2.value.updatedAt!);
    }

    return null;
  }

  @override
  List<String> getFilterQueries(Map<String, String> filters, int count, int startingAt, int sortedBy, bool sortedAsc, {int? index}) {
    return [];
  }

  @override
  String getSortingQuery(int sortedBy, bool sortedAsc) {
    // TODO: implement getSortingQuery
    throw UnimplementedError();
  }

}