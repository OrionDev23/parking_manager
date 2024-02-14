import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';
import 'package:parc_oto/datasources/parcoto_webservice_response.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../providers/client_database.dart';
import '../serializables/parc_oto_serializable.dart';
import '../theme.dart';
TextStyle rowTextStyle=TextStyle(
  fontSize: 10.sp,
);

abstract class ParcOtoDatasource<T> extends AsyncDataTableSource {
  BuildContext current;
  bool? selectC;
  AppTheme? appTheme;
  Map<String, String>? filters;
  String? searchKey;
  bool empty = false;
  int? errorCounter;
  int sortColumn = 0;
  bool sortAscending = true;
  final String collectionID;

  List<MapEntry<String, T>> data = List.empty(growable: true);

  late final ParcOtoWebService repo;

  ParcOtoDatasource(
      {required this.collectionID,
      required this.current,
      this.selectC = false,
      this.appTheme,
      this.filters,
      this.searchKey,
      this.sortColumn = 0,
      this.sortAscending = false});

  ParcOtoDatasource.empty(
      {required this.collectionID,
      required this.current,
      this.selectC = false,
      this.appTheme,
      this.filters,
      this.searchKey}) {
    empty = true;
  }

  ParcOtoDatasource.error(
      {required this.collectionID,
      required this.current,
      this.selectC = false,
      this.appTheme,
      this.filters,
      this.searchKey}) {
    errorCounter = 0;
  }

  void sort(int column, bool ascending) {
    sortColumn = column;
    sortAscending = ascending;
    refreshDatasource();
  }

  void search(String searchKey) {
    this.searchKey = searchKey;
    refreshDatasource();
  }

  void filter(Map<String, String> filters) {
    this.filters = filters;
    refreshDatasource();
  }

  Future<int> getTotalRecords() {
    return Future<int>.delayed(
        const Duration(milliseconds: 0), () => empty ? 0 : data.length);
  }

  static bool lastPortrait=false;
  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
    bool portrait=MediaQuery.of(current).orientation==Orientation.portrait;
    if(portrait!=lastPortrait){
      rowTextStyle = TextStyle(
        fontSize: portrait?13.sp:10.sp,
      );
    }
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
        ? await Future.delayed(const Duration(milliseconds: 1000),
            () => ParcOtoWebServiceResponse<T>(0, []))
        : await repo.getData(startIndex, count, sortColumn, sortAscending,
            searchKey: searchKey, filters: filters);

    var r = AsyncRowsResponse(
        x.totalRecords,
        x.data.map((element) {
          return rowDisplay(startIndex, count, element);
        }).toList());

    return r;
  }

  DataRow rowDisplay(
      int startIndex, int count, MapEntry<String, dynamic> element) {


    return DataRow(
      key: ValueKey<String>(element.value.id),
      onSelectChanged: selectC == true
          ? (value) {
              if (value == true) {
                selectRow(element.value);
              }
            }
          : (value){
        deselectAll();
        element.value.selected=true;
        notifyListeners();
      },
      selected: element.value.selected,
      cells: getCellsToShow(element as MapEntry<String, T>),
    );
  }

  List<DataCell> getCellsToShow(MapEntry<String, T> element);

  void selectRow(ParcOtoDefault c) {
    Navigator.of(current).pop(c);
  }

  void showDeleteConfirmation(dynamic c) {
    Future.delayed(const Duration(milliseconds: 50))
        .then((value) => f.showDialog(
            context: current,
            builder: (context) {
              return f.ContentDialog(
                content: Text(deleteConfirmationMessage(c)),
                actions: [
                  f.FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('annuler').tr()),
                  f.Button(
                    onPressed: () {
                      Navigator.of(context).pop();
                      deleteRow(c);
                    },
                    child: const Text('confirmer').tr(),
                  )
                ],
              );
            }));
  }

  String deleteConfirmationMessage(T c);

  void deleteRow(dynamic c) async {
    await Future.wait([
      ClientDatabase.database!
          .deleteDocument(
              databaseId: databaseId,
              collectionId: collectionID,
              documentId: c.id)
          .then((value) {
        data.remove(MapEntry(c.id, c));
        refreshDatasource();
      }),
      addToActivity(c),
    ]).onError((error, stackTrace) {
      return [
        f.displayInfoBar(
          current,
          builder: (c, s) {
            return f.InfoBar(
                title: const Text('erreur').tr(),
                severity: f.InfoBarSeverity.error);
          },
          alignment:
              Alignment.lerp(Alignment.topCenter, Alignment.center, 0.6)!,
        )
      ];
    });
  }

  Future<void> addToActivity(T c);
}

abstract class ParcOtoDatasourceUsers<S, T> extends AsyncDataTableSource {
  BuildContext current;
  bool? selectC;
  AppTheme? appTheme;
  String? searchKey;
  bool empty = false;
  int? errorCounter;
  int sortColumn = 0;
  bool sortAscending = true;

  List<MapEntry<S, T>> data = List.empty(growable: true);

  late final ParcOtoWebServiceUsers<S, T> repo;

  ParcOtoDatasourceUsers(
      {required this.current,
      this.selectC = false,
      this.appTheme,
      this.searchKey});

  ParcOtoDatasourceUsers.empty(
      {required this.current,
      this.selectC = false,
      this.appTheme,
      this.searchKey}) {
    empty = true;
  }

  ParcOtoDatasourceUsers.error(
      {required this.current,
      this.selectC = false,
      this.appTheme,
      this.searchKey}) {
    errorCounter = 0;
  }

  void sort(int column, bool ascending) {
    sortColumn = column;
    sortAscending = ascending;
    refreshDatasource();
  }

  void search(String searchKey) {
    this.searchKey = searchKey;
    refreshDatasource();
  }

  Future<int> getTotalRecords() {
    return Future<int>.delayed(
        const Duration(milliseconds: 0), () => empty ? 0 : data.length);
  }

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
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
            () => UsersWebServiceResponse<S, T>(0, []))
        : await repo.getData(startIndex, count, sortColumn, sortAscending,
            searchKey: searchKey);

    var r = AsyncRowsResponse(
        x.totalRecords,
        x.data.map((element) {
          return rowDisplay(startIndex, count, element);
        }).toList());

    return r;
  }

  Map<String, f.FlyoutController> controllers = {};

  DataRow rowDisplay(
      int startIndex, int count, MapEntry<dynamic, dynamic> element) {
    controllers[element.value.key.$id] = f.FlyoutController();
    return DataRow(
      key: ValueKey<String>(element.key),
      onSelectChanged: selectC == true
          ? (value) {
              if (value == true) {
                selectRow(element.value);
              }
            }
          : null,
      cells: getCellsToShow(element as MapEntry<S, T>),
    );
  }

  List<DataCell> getCellsToShow(MapEntry<S, T> element);

  void selectRow(T c) {
    Navigator.of(current).pop(c);
  }

  void showDeleteConfirmation(dynamic c, dynamic t) {
    Future.delayed(const Duration(milliseconds: 50))
        .then((value) => f.showDialog(
            context: current,
            builder: (context) {
              return f.ContentDialog(
                content: Text(deleteConfirmationMessage(t)),
                actions: [
                  f.FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('annuler').tr()),
                  f.Button(
                    onPressed: () {
                      Navigator.of(context).pop();
                      deleteRow(c, t);
                    },
                    child: const Text('confirmer').tr(),
                  )
                ],
              );
            }));
  }

  String deleteConfirmationMessage(T c);

  void deleteRow(S c, T t);

  Future<void> addToActivity(T c);
}
