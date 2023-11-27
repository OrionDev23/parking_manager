import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:parc_oto/datasources/parcoto_webservice_response.dart';

import '../providers/client_database.dart';

abstract class ParcOtoWebService<ParcOtoDefault> {


  List <MapEntry<String,ParcOtoDefault>> data;

  String collectionID;

  int columnForSearch;
  ParcOtoWebService(this.data,this.collectionID,this.columnForSearch);
  num Function(MapEntry<String,dynamic>, MapEntry<String,dynamic>)? getComparisonFunction(
      int column, bool ascending);

  Future<ParcOtoWebServiceResponse<ParcOtoDefault>> getData(int startingAt, int count,
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
          data.add(MapEntry(element.$id, element.convertTo<ParcOtoDefault>((p0) {
            return fromJsonFunction(p0 as Map<String,dynamic>);
          })));
        }
      }
      var result = data;

      result.sort(getComparisonFunction(sortedBy, sortedAsc) as int Function(MapEntry<String, ParcOtoDefault> a, MapEntry<String, ParcOtoDefault> b)?);
      return ParcOtoWebServiceResponse(
          value.total, result.skip(startingAt).take(count).toList());
    }).onError((error, stackTrace) {
      return Future.value(ParcOtoWebServiceResponse(0, data));
    });
  }



  ParcOtoDefault fromJsonFunction(Map<String,dynamic> json);
  
  Future<DocumentList> getSearchResult(String? searchKey,Map<String,String>filters,
      int count,int startingAt,int sortedBy,bool sortedAsc,) async{

    if(searchKey!=null && searchKey.isNotEmpty){
      late DocumentList d;
      for(int i=0;i<columnForSearch;i++){
        d=await ClientDatabase.database!.listDocuments(
            databaseId: databaseId,
            collectionId: vehiculeid,
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