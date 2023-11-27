import 'package:data_table_2/data_table_2.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';
import 'package:parc_oto/datasources/parcoto_webservice_response.dart';

import '../theme.dart';

abstract class ParcOtoDatasource<ParcOtoDefault> extends AsyncDataTableSource{
  BuildContext current;
  bool? selectC;
  AppTheme? appTheme;
  Map<String,String>? filters;
  String? searchKey;
  bool empty = false;
  int? errorCounter;
  int sortColumn = 0;
  bool sortAscending = true;

  List<MapEntry<String,ParcOtoDefault>> data = List.empty(growable: true);


  ParcOtoDatasource({required this.current,this.selectC=false,this.appTheme,this.filters,this.searchKey});

  ParcOtoDatasource.empty({required this.current,this.selectC=false,this.appTheme,this.filters,this.searchKey}) {
    empty = true;
  }

  ParcOtoDatasource.error({required this.current,this.selectC=false,this.appTheme,this.filters,this.searchKey}) {
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
  Future<AsyncRowsResponse> getRows(int startIndex, int count);

  void selectColumn(ParcOtoDefault c);

  void showDeleteConfirmation(ParcOtoDefault c);

  void deleteRow(ParcOtoDefault c);
}
