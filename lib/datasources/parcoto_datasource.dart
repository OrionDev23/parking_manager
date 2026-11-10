// ignore_for_file: use_build_context_synchronously

import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:material_ui/material_ui.dart';
import 'package:parc_oto/datasources/parcoto_webservice.dart';
import 'package:parc_oto/datasources/parcoto_webservice_response.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../providers/client_database.dart';
import '../main.dart' show vehicleServices, legacyStockSyncService;
import '../core/services/legacy_stock_sync_service.dart';
import '../core/sync/sync_operation.dart';
import '../serializables/parc_oto_serializable.dart';
import '../theme.dart';

TextStyle rowTextStyle = TextStyle(fontSize: 10.sp);

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
  final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');

  List<MapEntry<String, T>> data = List.empty(growable: true);

  late final ParcOtoWebService repo;
  bool _localCacheLoaded = false;

  // AsyncPaginatedDataTable2 notifies its source after getRows completes.
  // Keep the ChangeNotifier alive until that final notification has run.
  int _activeRowsRequests = 0;
  bool _disposeRequested = false;
  bool _disposed = false;

  @override
  void dispose() {
    if (_disposeRequested || _disposed) return;
    _disposeRequested = true;
    _disposeWhenIdle();
  }

  void _disposeWhenIdle() {
    if (!_disposeRequested || _activeRowsRequests > 0 || _disposed) return;

    // A zero-duration future runs after pending microtasks, including the
    // table package's continuation that calls notifyListeners().
    Future<void>.delayed(Duration.zero, () {
      if (!_disposeRequested || _activeRowsRequests > 0 || _disposed) return;
      _disposed = true;
      super.dispose();
    });
  }

  String? get _cacheEntity {
    switch (collectionID) {
      case clientsID:
        return 'client';
      case prestataireId:
        return 'provider';
      case partsID:
        return 'part';
      case categoriesID:
        return 'part_category';
      case brandsID:
        return 'part_brand';
      case optionsID:
        return 'part_option';
      case fournsID:
        return 'supplier';
      default:
        return null;
    }
  }

  void _loadLocalCache() {
    if (_localCacheLoaded) return;
    _localCacheLoaded = true;
    final entity = _cacheEntity;
    if (entity == null) return;
    try {
      final rows = vehicleServices.localDatabase.readLegacyCache(
        companyId: vehicleServices.companyId,
        entity: entity,
      );
      for (final payload in rows) {
        final id = payload[r'$id']?.toString();
        if (id == null || id.isEmpty) continue;
        try {
          if (!data.any((entry) => entry.key == id)) {
            data.add(MapEntry(id, repo.fromJsonFunction(payload)));
          }
        } catch (error) {
          debugPrint('[ParcOto] invalid $entity cache row ignored: $error');
        }
      }
    } catch (error) {
      debugPrint('[ParcOto] unable to read $entity cache: $error');
    }
  }

  void _persistRows(List<MapEntry<String, dynamic>> rows) {
    final entity = _cacheEntity;
    if (entity == null) return;
    for (final entry in rows) {
      final value = entry.value;
      if (value is! ParcOtoDefault) continue;
      final payload = <String, dynamic>{
        ...value.toJson(),
        r'$id': entry.key,
        if (value.createdAt != null)
          r'$createdAt': value.createdAt!.toUtc().toIso8601String(),
        if (value.updatedAt != null)
          r'$updatedAt': value.updatedAt!.toUtc().toIso8601String(),
      };
      try {
        vehicleServices.localDatabase.cacheLegacyRow(
          companyId: vehicleServices.companyId,
          entity: entity,
          entityId: entry.key,
          payload: payload,
        );
      } catch (error) {
        debugPrint('[ParcOto] unable to cache $entity row: $error');
      }
    }
  }

  ParcOtoDatasource({
    required this.collectionID,
    required this.current,
    this.selectC = false,
    this.appTheme,
    this.filters,
    this.searchKey,
    this.sortColumn = 0,
    this.sortAscending = false,
  });

  ParcOtoDatasource.empty({
    required this.collectionID,
    required this.current,
    this.selectC = false,
    this.appTheme,
    this.filters,
    this.searchKey,
  }) {
    empty = true;
  }

  ParcOtoDatasource.error({
    required this.collectionID,
    required this.current,
    this.selectC = false,
    this.appTheme,
    this.filters,
    this.searchKey,
  }) {
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
      const Duration(milliseconds: 0),
      () => empty ? 0 : data.length,
    );
  }

  static bool lastPortrait = false;

  List<Map<String, dynamic>> getJsonData(List<dynamic> data) {
    bool isDocument = data.first is Document;
    List<Map<String, dynamic>> result = [];
    for (int i = 0; i < data.length; i++) {
      if (isDocument) {
        result.add(data[i].data);
      } else {
        result.add(data[i].value!.toJson());
      }
    }

    return result;
  }

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
    _activeRowsRequests++;
    try {
      bool portrait = MediaQuery.of(current).orientation == Orientation.portrait;
      if (portrait != lastPortrait) {
        rowTextStyle = TextStyle(fontSize: portrait ? 13.sp : 10.sp);
        lastPortrait = portrait;
      }
      if (errorCounter != null) {
        errorCounter = errorCounter! + 1;

        if (errorCounter! % 2 == 1) {
          await Future.delayed(const Duration(milliseconds: 500));
          throw 'Error #${((errorCounter! - 1) / 2).round() + 1} has occured';
        }
      }

      assert(startIndex >= 0);

      // Populate from SQLite before attempting the remote page.
      _loadLocalCache();

      // List returned will be empty is there're fewer items than startingAt
      var x = empty
          ? await Future.delayed(
              const Duration(milliseconds: 1000),
              () => ParcOtoWebServiceResponse<T>(0, []),
            )
          : await repo.getData(
              startIndex,
              count,
              sortColumn,
              sortAscending,
              searchKey: searchKey,
              filters: filters,
            );
      var visibleData = List<MapEntry<String, T>>.from(x.data);
      var totalRecords = x.totalRecords;

      final entity = _cacheEntity;
      if (entity != null &&
          LegacyStockSyncService.tableByEntity.containsKey(entity)) {
        final pendingOperations = await vehicleServices.syncQueue.pending(
          limit: 5000,
          companyId: vehicleServices.companyId,
        );
        for (final operation in pendingOperations) {
          if (operation.entity != entity) continue;
          final existingIndex = visibleData.indexWhere(
            (entry) => entry.key == operation.entityId,
          );
          switch (operation.type) {
            case SyncOperationType.delete:
              if (existingIndex >= 0) {
                visibleData.removeAt(existingIndex);
                totalRecords = totalRecords > 0 ? totalRecords - 1 : 0;
              }
              break;
            case SyncOperationType.create:
            case SyncOperationType.update:
              try {
                final payload = <String, dynamic>{
                  ...operation.payload,
                  r'$id': operation.entityId,
                };
                final localValue = repo.fromJsonFunction(payload);
                if (existingIndex >= 0) {
                  visibleData[existingIndex] = MapEntry(
                    operation.entityId,
                    localValue,
                  );
                } else if (operation.type == SyncOperationType.create &&
                    startIndex == 0 &&
                    (searchKey == null || searchKey!.isEmpty) &&
                    (filters == null || filters!.isEmpty)) {
                  visibleData.add(MapEntry(operation.entityId, localValue));
                  totalRecords++;
                }
              } catch (error) {
                debugPrint('[ParcOto] pending $entity row ignored: $error');
              }
              break;
          }
        }
        if (visibleData.length > count) {
          visibleData = visibleData.take(count).toList();
        }
      }

      _persistRows(visibleData.cast<MapEntry<String, dynamic>>());

      final r = AsyncRowsResponse(
        totalRecords,
        visibleData.map((element) {
          return rowDisplay(startIndex, count, element);
        }).toList(),
      );

      return r;
    
    } finally {
      _activeRowsRequests--;
      _disposeWhenIdle();
    }
  }

  void longPressing(MapEntry<String, T> element) {}
  DataRow rowDisplay(
    int startIndex,
    int count,
    MapEntry<String, dynamic> element,
  ) {
    return DataRow(
      key: ValueKey<String>(element.value.id),
      onLongPress: () => longPressing(element),
      onSelectChanged: selectC == true
          ? (value) {
              if (value == true) {
                selectRow(element.value);
              }
            }
          : (value) {
              deselectAll();
              element.value.selected = true;
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
    Future.delayed(const Duration(milliseconds: 50)).then(
      (value) => f.showDialog(
        context: current,
        builder: (context) {
          return f.ContentDialog(
            content: Text(deleteConfirmationMessage(c)),
            actions: [
              f.FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('annuler').tr(),
              ),
              f.Button(
                onPressed: () {
                  Navigator.of(context).pop();
                  deleteRow(c);
                },
                child: const Text('confirmer').tr(),
              ),
            ],
          );
        },
      ),
    );
  }

  String deleteConfirmationMessage(T c);

  void deleteRow(dynamic c) async {
    try {
      final entity = _cacheEntity;
      if (entity != null &&
          LegacyStockSyncService.tableByEntity.containsKey(entity)) {
        await legacyStockSyncService.delete(entity: entity, id: c.id);
      } else {
        await DatabaseGetter.database!.deleteRow(
          databaseId: databaseId,
          tableId: collectionID,
          rowId: c.id,
        );
        if (entity != null) {
          vehicleServices.localDatabase.deleteLegacyRow(
            companyId: vehicleServices.companyId,
            entity: entity,
            entityId: c.id,
          );
        }
      }
      data.removeWhere((entry) => entry.key == c.id);
      // Activity logging is secondary to the deletion. If the device is
      // offline, the local tombstone must remain a successful operation.
      try {
        await addToActivity(c);
      } catch (activityError) {
        debugPrint(
          '[ParcOto] deletion activity could not be recorded: $activityError',
        );
      }
      refreshDatasource();
    } catch (error, stackTrace) {
      debugPrint('[ParcOto] row deletion failed: $error');
      if (kDebugMode) debugPrintStack(stackTrace: stackTrace);
      f.displayInfoBar(
        current,
        builder: (context, state) => f.InfoBar(
          title: const Text('erreur').tr(),
          severity: f.InfoBarSeverity.error,
        ),
        alignment: Alignment.lerp(Alignment.topCenter, Alignment.center, 0.6)!,
      );
    }
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

  ParcOtoDatasourceUsers({
    required this.current,
    this.selectC = false,
    this.appTheme,
    this.searchKey,
  });

  ParcOtoDatasourceUsers.empty({
    required this.current,
    this.selectC = false,
    this.appTheme,
    this.searchKey,
  }) {
    empty = true;
  }

  ParcOtoDatasourceUsers.error({
    required this.current,
    this.selectC = false,
    this.appTheme,
    this.searchKey,
  }) {
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
      const Duration(milliseconds: 0),
      () => empty ? 0 : data.length,
    );
  }

  static bool lastPortrait = false;

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
    bool portrait = MediaQuery.of(current).orientation == Orientation.portrait;
    if (portrait != lastPortrait) {
      rowTextStyle = TextStyle(fontSize: portrait ? 13.sp : 10.sp);
      lastPortrait = portrait;
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
        ? await Future.delayed(
            const Duration(milliseconds: 500),
            () => UsersWebServiceResponse<S, T>(0, []),
          )
        : await repo.getData(
            startIndex,
            count,
            sortColumn,
            sortAscending,
            searchKey: searchKey,
          );

    var r = AsyncRowsResponse(
      x.totalRecords,
      x.data.map((element) {
        return rowDisplay(startIndex, count, element);
      }).toList(),
    );

    return r;
  }

  Map<String, f.FlyoutController> controllers = {};

  DataRow rowDisplay(
    int startIndex,
    int count,
    MapEntry<dynamic, dynamic> element,
  ) {
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

  List<Map<String, dynamic>> getJsonData(List<dynamic> data) {
    List<Map<String, dynamic>> result = [];
    for (int i = 0; i < data.length; i++) {
      result.add(data[i].value!.toJson());
    }

    return result;
  }

  void selectRow(T c) {
    Navigator.of(current).pop(c);
  }

  void showDeleteConfirmation(dynamic c, dynamic t) {
    Future.delayed(const Duration(milliseconds: 50)).then(
      (value) => f.showDialog(
        context: current,
        builder: (context) {
          return f.ContentDialog(
            content: Text(deleteConfirmationMessage(t)),
            actions: [
              f.FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('annuler').tr(),
              ),
              f.Button(
                onPressed: () {
                  Navigator.of(context).pop();
                  deleteRow(c, t);
                },
                child: const Text('confirmer').tr(),
              ),
            ],
          );
        },
      ),
    );
  }

  String deleteConfirmationMessage(T c);

  void deleteRow(S c, T t);

  Future<void> addToActivity(T c);
}
