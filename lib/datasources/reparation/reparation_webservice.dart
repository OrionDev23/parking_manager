import 'package:appwrite/appwrite.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';
import 'package:parc_oto/serializables/reparation.dart';

class ReparationWebService extends ParcOtoWebService<Reparation>{
  ReparationWebService(super.data, super.collectionID, super.columnForSearch);

  @override
  fromJsonFunction(Map<String, dynamic> json) {
    return Reparation.fromJson(json);
  }

  @override
  String getAttributeForSearch(int att) {
    switch(att){
      case 0:return 'vehiculemat';
      case 1:return 'prestatairenom';
      case 2:return 'nchassi';
      case 3:return 'modele';
    }
    return 'remarque';
  }


  @override
  String getSearchQueryPerIndex(int index,String searchKey){
    switch(index){
      case 2: return Query.equal('annee_util', int.tryParse(searchKey)??9999);
      default: return Query.search(getAttributeForSearch(index), searchKey);
    }
  }

  @override
  int Function(MapEntry<String, dynamic> p1, MapEntry<String, dynamic> p2)? getComparisonFunction(int column, bool ascending) {
    // TODO: implement getComparisonFunction
    throw UnimplementedError();
  }

  @override
  List<String> getFilterQueries(Map<String, String> filters, int count, int startingAt, int sortedBy, bool sortedAsc, {int? index}) {
    // TODO: implement getFilterQueries
    throw UnimplementedError();
  }

  @override
  String getSortingQuery(int sortedBy, bool sortedAsc) {
    // TODO: implement getSortingQuery
    throw UnimplementedError();
  }

}