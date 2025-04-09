import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../../../../datasources/workshop/storage/storage_datasource.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../providers/client_database.dart';
import '../../../../theme.dart';
import '../../../data_table_parcoto.dart';

class StorageTable extends StatefulWidget {
  final bool selectD;

  const StorageTable(
      {super.key, this.selectD = false,});

  @override
  State<StorageTable> createState() => StorageTableState();
}

class StorageTableState extends State<StorageTable> {
  late StorageDatesource storageDataSource;

  late final bool startedWithFiltersOn;

  static ValueNotifier<String?> filterDocument = ValueNotifier(null);

  static bool filterNow = false;

  bool filteredAlready = false;
  bool filtered = false;

  bool assending = false;

  late List<DataColumn2> columns;

  bool initialized = false;
  int sortColumn = 5;
  void initColumns() {
    columns = [
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'code',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.S,
        onSort: (s, c) {
          sortColumn = 0;
          assending = !assending;

          storageDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'piece',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.S,
        onSort: (s, c) {
          sortColumn = 1;
          assending = !assending;

          storageDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'fournisseur',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.S,
        onSort: (s, c) {
          sortColumn = 2;
          assending = !assending;

          storageDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'variations',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.S,
        onSort: (s, c) {
          sortColumn = 3;
          assending = !assending;

          storageDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'qte',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 4;
          assending = !assending;

          storageDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'dateModif',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 5;
          assending = !assending;
          storageDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: const Text(''),
        size: ColumnSize.S,
        fixedWidth: 2.w,
        onSort: null,
      ),
    ];
  }

  int rowPerPage = 6;
  TextEditingController searchController = TextEditingController();

  bool notEmpty = false;
  @override
  void initState() {
    initValues();
    super.initState();
  }

  String getCollectionID() {
    return storageId;
  }
  void initValues() {
    if (!initialized) {
      initialized = true;
      if (filterDocument.value != null) {
        startedWithFiltersOn = true;
        searchController.text = filterDocument.value!;
        storageDataSource = StorageDatesource(
            current: context,
            selectC: widget.selectD,
            collectionID: getCollectionID(),
            searchKey: filterDocument.value);
        filterDocument.value = null;
      } else {
        startedWithFiltersOn = false;

        storageDataSource = StorageDatesource(
          current: context,
          collectionID: getCollectionID(),
          selectC: widget.selectD,);
      }
      initColumns();
    }
  }


  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    storageDataSource.appTheme = appTheme;
    return ValueListenableBuilder(
        valueListenable: filterDocument,
        builder: (context, v, _) {
          if (!startedWithFiltersOn && v != null && filterNow) {
            searchController.text = v;
            storageDataSource.search(v);
            notEmpty = true;
            filtered = true;
            filterNow = false;
          }
          return DataTableParc(
            header: Padding(
              padding:
              const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 350.px,
                    height: 45.px,
                    child: TextBox(
                      onChanged: (s) {
                        if (s.isEmpty) {
                          notEmpty = false;
                          storageDataSource.search('');
                        } else {
                          notEmpty = true;
                        }
                        setState(() {});
                      },
                      controller: searchController,
                      placeholder: 'search'.tr(),
                      style: appTheme.writingStyle,
                      cursorColor: appTheme.color.darker,
                      placeholderStyle: placeStyle,
                      decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),
                      onSubmitted: (s) {
                        if (s.isNotEmpty) {
                          storageDataSource.search(s);
                          if (!notEmpty) {
                            setState(() {
                              notEmpty = true;
                            });
                          }
                        } else {
                          if (notEmpty) {
                            setState(() {
                              notEmpty = false;
                            });
                          }
                        }
                      },
                      suffix: notEmpty
                          ? IconButton(
                          icon: const Icon(FluentIcons.cancel),
                          onPressed: () {
                            searchController.text = "";
                            notEmpty = false;
                            setState(() {});
                            storageDataSource.search('');
                          })
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            sortAscending: assending,
            sortColumnIndex: sortColumn,
            columns: columns,
            source: storageDataSource,
          );
        });
  }

  @override
  void dispose() {
    storageDataSource.dispose();
    super.dispose();
  }

}