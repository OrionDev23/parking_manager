import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/material.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';
import 'package:parc_oto/datasources/parcoto_webservice_response.dart';

import '../providers/client_database.dart';
import '../theme.dart';

abstract class ParcOtoDatasource<ParcOtoDefault,T> extends AsyncDataTableSource{
  BuildContext current;
  bool? selectC;
  AppTheme? appTheme;
  Map<String,String>? filters;
  String? searchKey;
  bool empty = false;
  int? errorCounter;
  int sortColumn = 0;
  bool sortAscending = true;
  final String collectionID;

  List<MapEntry<String,ParcOtoDefault>> data = List.empty(growable: true);

  late final ParcOtoWebService repo;

  ParcOtoDatasource({required this.collectionID,required this.current,this.selectC=false,this.appTheme,this.filters,this.searchKey});

  ParcOtoDatasource.empty({required this.collectionID,required this.current,this.selectC=false,this.appTheme,this.filters,this.searchKey}) {
    empty = true;
  }

  ParcOtoDatasource.error({required this.collectionID,required this.current,this.selectC=false,this.appTheme,this.filters,this.searchKey}) {
    errorCounter = 0;
  }
  void sort(int column, bool ascending) {
    sortColumn = column;
    sortAscending = ascending;
    refreshDatasource();
  }
  void search(String searchKey){
    this.searchKey=searchKey;
    refreshDatasource();
  }
  void filter(Map<String,String> filters){
    this.filters=filters;
    refreshDatasource();

  }

  Future<int> getTotalRecords() {
    return Future<int>.delayed(
        const Duration(milliseconds: 0), () => empty ? 0 : data.length);
  }
  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async{
    if (errorCounter != null) {
      errorCounter = errorCounter! + 1;

      if (errorCounter! % 2 == 1) {
        await Future.delayed(const Duration(milliseconds: 500));
        throw 'Error #${((errorCounter! - 1) / 2).round() + 1} has occured';
      }
    }

    assert(startIndex >= 0);

    // List returned will be empty is there're fewer items than startingAt
    var x = empty
        ? await Future.delayed(const Duration(milliseconds: 500),
            () => ParcOtoWebServiceResponse<T>(0, []))
        : await repo.getData(startIndex, count, sortColumn, sortAscending,searchKey: searchKey,filters: filters);

    var r = AsyncRowsResponse(
    x.totalRecords,
    x.data.map((element) {
    return rowDisplay(startIndex,count,element);
    }).toList());

    return r;
  }


  DataRow rowDisplay(int startIndex,int count,dynamic element);

  void selectRow(ParcOtoDefault c){
    Navigator.of(current).pop(c);
  }

  void showDeleteConfirmation(ParcOtoDefault c);

  void deleteRow(dynamic c) async{
    await ClientDatabase.database!.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionID,
        documentId: c.id).then((value) {
      data.remove(MapEntry(c.id, c));
      notifyListeners();
    }).onError((error, stackTrace) {

      showSnackbar(current,InfoBar(
          title: const Text('erreur').tr(),
          severity: InfoBarSeverity.error
      ),
        alignment: Alignment.lerp(Alignment.topCenter, Alignment.center, 0.6)!,
      );
    });
  }
}
