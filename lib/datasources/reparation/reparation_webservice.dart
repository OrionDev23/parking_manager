import 'package:parc_oto/datasources/parcoto_webservice.dart';

class ReparationWebService extends ParcOtoWebService{
  ReparationWebService(super.data, super.collectionID, super.columnForSearch);

  @override
  fromJsonFunction(Map<String, dynamic> json) {
    // TODO: implement fromJsonFunction
    throw UnimplementedError();
  }

  @override
  String getAttributeForSearch(int att) {
    // TODO: implement getAttributeForSearch
    throw UnimplementedError();
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