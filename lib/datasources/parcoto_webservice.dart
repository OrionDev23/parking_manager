import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:parc_oto/datasources/parcoto_webservice_response.dart';

import '../providers/client_database.dart';

abstract class ParcOtoWebService<T> {


  List <MapEntry<String,T>> data;

  String collectionID;

  int columnForSearch;
  ParcOtoWebService(this.data,this.collectionID,this.columnForSearch);
  int Function(MapEntry<String,T>, MapEntry<String,T>)? getComparisonFunction(
      int column, bool ascending);

  Future<ParcOtoWebServiceResponse<T>> getData(int startingAt, int count,
      int sortedBy, bool sortedAsc, {String? searchKey,Map<String,String>?filters}) async {
    if (startingAt == 0) {
      data.clear();
    }
    //  final stopwatch = Stopwatch()..start();
    return getSearchResult(searchKey,filters??{},count,startingAt,sortedBy,sortedAsc).then((value) {

      //stopwatch.stop();
      // print("finished in ${stopwatch.elapsed.inMilliseconds} s");

      for (var element in value.documents) {
        if(!testIfElementContained(element.$id)){
          data.add(MapEntry(element.$id, element.convertTo<T>((p0) {
            return fromJsonFunction(p0 as Map<String,dynamic>);
          })));
        }
      }
      var result = data;

      result.sort(getComparisonFunction(sortedBy, sortedAsc));

      return ParcOtoWebServiceResponse<T>(
          value.total, result.skip(startingAt).take(count).toList());
    }).onError(( error, stackTrace) {

      if(kDebugMode ){
        if(error is AppwriteException){
          print('error.message : ${error.message}');
          print('error.response : ${error.response}');
        }

        print('stacktrace : $stackTrace');

      }

      return Future.value(ParcOtoWebServiceResponse<T>(0, data));
    });
  }



  T fromJsonFunction(Map<String,dynamic> json);
  
  Future<DocumentList> getSearchResult(String? searchKey,Map<String,String>filters,
      int count,int startingAt,int sortedBy,bool sortedAsc,) async{

    if(searchKey!=null && searchKey.isNotEmpty){
      late DocumentList d;
      for(int i=0;i<columnForSearch;i++){
        d=await ClientDatabase.database!.listDocuments(
            databaseId: databaseId,
            collectionId: collectionID,
            queries: getQueriesForSearch(searchKey, filters, count, startingAt, sortedBy, sortedAsc, i));
        if(d.documents.isNotEmpty){
          break;
        }
      }
      return d;
    }
    else{
      return await ClientDatabase.database!.listDocuments(
          databaseId: databaseId,
          collectionId: collectionID,
          queries:getQueries( filters, count, startingAt, sortedBy, sortedAsc));
    }
  }

  List<String> getQueries(Map<String,String>filters,
      int count,int startingAt,int sortedBy,bool sortedAsc,) {
      return [
        ...getFilterQueries( filters, count, startingAt, sortedBy, sortedAsc),
        Query.limit(count),
        Query.offset(startingAt),
        getSortingQuery(sortedBy, sortedAsc),
      ];
  }

  List<String> getFilterQueries(Map<String,String>filters,
      int count,int startingAt,int sortedBy,bool sortedAsc,{int? index});

  List<String> getQueriesForSearch(String searchKey,Map<String,String>filters,
      int count,int startingAt,int sortedBy,bool sortedAsc,int index){
      return [
        getSearchQueryPerIndex(index,searchKey),
        ...getFilterQueries(filters, count, startingAt, sortedBy, sortedAsc),
      ];
  }
  String getSearchQueryPerIndex(int index,String searchKey){
    return Query.search(getAttributeForSearch(index), searchKey);

  }

  String getAttributeForSearch(int att);


  bool testIfElementContained(String id){
    for(int i=0;i<data.length;i++){
      if(data[i].key==id){
        return true;
      }
    }
    return false;
  }

  String getSortingQuery(int sortedBy, bool sortedAsc);
}


abstract class ParcOtoWebServiceUsers<S,T>{
  List <MapEntry<S,T>> data;

  ParcOtoWebServiceUsers(this.data,);
  int Function(MapEntry<S,T>, MapEntry<S,T>)? getComparisonFunction(
      int column, bool ascending);

  Future<UsersWebServiceResponse<S,T>> getData(int startingAt, int count,
      int sortedBy, bool sortedAsc, {String? searchKey,Map<String,String>?filters}) async {
    if (startingAt == 0) {
      data.clear();
    }
    //  final stopwatch = Stopwatch()..start();
    return getSearchResult(searchKey,).then((value) {

      //stopwatch.stop();
      // print("finished in ${stopwatch.elapsed.inMilliseconds} s");

      for (var element in value.entries) {
        if(!testIfContained(data,element)){
          data.add(element);
        }
      }
      var result = data;

      result.sort(getComparisonFunction(sortedBy, sortedAsc));

      return UsersWebServiceResponse<S,T>(
          value.length, result.skip(startingAt).take(count).toList());
    }).onError((error, stackTrace) {
      return Future.value(UsersWebServiceResponse<S,T>(0, data));
    });
  }

  bool testIfContained(List<MapEntry<dynamic,dynamic>> list,dynamic s){
    for(var element in list){
      if(element.key==s.key){
        return true;
      }
    }
    return false;
  }


  Future<Map<S,T>> getSearchResult(String? searchKey);

}