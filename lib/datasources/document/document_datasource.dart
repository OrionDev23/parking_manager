import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart' as f;
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:parc_oto/datasources/document/document_webservice.dart';
import 'package:parc_oto/screens/vehicle/documents/document_form.dart';
import 'package:parc_oto/screens/vehicle/documents/document_tabs.dart';
import 'package:parc_oto/serializables/document_vehicle.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import '../../providers/client_database.dart';
import '../../theme.dart';

class DocumentsDataSource extends AsyncDataTableSource {
  BuildContext current;
  bool? selectD;
  AppTheme? appTheme;
  DocumentsDataSource(
      {required this.current, this.selectD = false, this.appTheme});

  DocumentsDataSource.empty(
      {required this.current, this.selectD = false, this.appTheme}) {
    _empty = true;
  }

  DocumentsDataSource.error(
      {required this.current, this.selectD = false, this.appTheme}) {
    _errorCounter = 0;
  }

  bool _empty = false;
  int? _errorCounter;

  final DocumentWebService _repo = DocumentWebService();

  int _sortColumn = 0;
  bool _sortAscending = true;

  void sort(int column, bool ascending) {
    _sortColumn = column;
    _sortAscending = ascending;
    refreshDatasource();
  }

  String? searchKey;

  void search(String searchKey) {
    this.searchKey = searchKey;
    refreshDatasource();
  }

  void filter(Map<String, String> filters) {
    this.filters = filters;
    refreshDatasource();
  }

  Map<String, String>? filters;

  Future<int> getTotalRecords() {
    return Future<int>.delayed(
        const Duration(milliseconds: 0), () => _empty ? 0 : documents.length);
  }

  @override
  Future<AsyncRowsResponse> getRows(int startIndex, int count) async {
    if (_errorCounter != null) {
      _errorCounter = _errorCounter! + 1;

      if (_errorCounter! % 2 == 1) {
        await Future.delayed(const Duration(milliseconds: 1000));
        throw 'Error #${((_errorCounter! - 1) / 2).round() + 1} has occured';
      }
    }

    final dateFormat = DateFormat('y/M/d HH:mm:ss', 'fr');
    final dateFormat2 = DateFormat('y/M/d', 'fr');
    final tstyle = TextStyle(
      fontSize: 10.sp,
    );

    assert(startIndex >= 0);

    // List returned will be empty is there're fewer items than startingAt
    var x = _empty
        ? await Future.delayed(const Duration(milliseconds: 500),
            () => DocumentWebServiceResponse(0, []))
        : await _repo.getData(startIndex, count, _sortColumn, _sortAscending,
            searchKey: searchKey, filters: filters);

    var r = AsyncRowsResponse(
        x.totalRecords,
        x.data.map((document) {
          return DataRow(
            key: ValueKey<String>(document.value.id),
            onSelectChanged: selectD == true
                ? (value) {
                    if (value == true) {
                      selectDocument(document.value);
                    }
                  }
                : null,
            cells: [
              DataCell(SelectableText(
                document.value.nom,
                style: tstyle,
              )),
              DataCell(SelectableText(document.value.vehicle?.matricule ?? '',
                  style: tstyle)),
              DataCell(SelectableText(
                document.value.dateExpiration!=null?
                  dateFormat2.format(ClientDatabase.ref.add(
                      Duration(milliseconds: document.value.dateExpiration!))):'',
                  style: tstyle)),
              DataCell(SelectableText(
                document.value.dateModif!=null?
                  dateFormat.format(document.value.dateModif!):'',
                  style: tstyle)),
              DataCell(f.FlyoutTarget(
                controller: document.value.controller,
                child: IconButton(
                    splashRadius: 15,
                    onPressed: () {
                      document.value.controller.showFlyout(builder: (context) {
                        return f.MenuFlyout(
                          items: [
                            f.MenuFlyoutItem(
                                text: const Text('mod').tr(),
                                onPressed: () {
                                  Navigator.of(current).pop();
                                  late f.Tab tab;
                                  tab = f.Tab(
                                    key: UniqueKey(),
                                    text: Text(
                                        '${"mod".tr()} ${'document'.tr().toLowerCase()} ${document.value.nom}'),
                                    semanticLabel:
                                        '${'mod'.tr()} ${document.value.nom}',
                                    icon: const Icon(Bootstrap.car_front),
                                    body: DocumentForm(
                                      vd: document.value,
                                    ),
                                    onClosed: () {
                                      DocumentTabsState.tabs.remove(tab);

                                      if (DocumentTabsState.currentIndex.value >
                                          0) {
                                        DocumentTabsState.currentIndex.value--;
                                      }
                                    },
                                  );
                                  final index =
                                      DocumentTabsState.tabs.length + 1;
                                  DocumentTabsState.tabs.add(tab);
                                  DocumentTabsState.currentIndex.value =
                                      index - 1;
                                }),
                            f.MenuFlyoutItem(
                                text: const Text('delete').tr(),
                                onPressed: () {
                                  showDeleteConfirmation(document.value);
                                }),
                          ],
                        );
                      });
                    },
                    icon: const Icon(Icons.more_vert_sharp)),
              )),
            ],
          );
        }).toList());

    return r;
  }

  void selectDocument(DocumentVehicle v) {
    Navigator.of(current).pop(v);
  }

  void showDeleteConfirmation(DocumentVehicle v) {
    f.showDialog(
        context: current,
        builder: (context) {
          return f.ContentDialog(
            content: Text('${'suprdoc'.tr()} ${v.nom} ${v.vehicle?.matricule}'),
            actions: [
              f.FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('annuler').tr()),
              f.Button(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  deleteDocument(v);
                },
                child: const Text('confirmer').tr(),
              )
            ],
          );
        });
  }

  void deleteDocument(DocumentVehicle v) async {
    await ClientDatabase.database!
        .deleteDocument(
            databaseId: databaseId, collectionId: vehiculeid, documentId: v.id)
        .then((value) {
      documents.remove(MapEntry(v.id, v));
      notifyListeners();
    }).onError((error, stackTrace) {
      f.showSnackbar(
        current,
        f.InfoBar(
            title: const Text('erreur').tr(),
            severity: f.InfoBarSeverity.error),
        alignment: Alignment.lerp(Alignment.topCenter, Alignment.center, 0.6)!,
      );
    });
  }
}

List<MapEntry<String, DocumentVehicle>> documents = List.empty(growable: true);
