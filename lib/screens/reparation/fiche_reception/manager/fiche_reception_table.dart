import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import '../../../../datasources/fiche_reception/fiche_reception_datasource.dart';
import '../../../../providers/client_database.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../theme.dart';
import '../../../data_table_parcoto.dart';

class FicheReceptionTable extends StatefulWidget {
  final bool selectD;
  final bool archive;

  const FicheReceptionTable(
      {super.key, this.selectD = false, this.archive = false});

  @override
  State<FicheReceptionTable> createState() => FicheReceptionTableState();
}

class FicheReceptionTableState extends State<FicheReceptionTable> {
  late FicheReceptionDatasource ficheReceptionDatasource;

  late final bool startedWithFiltersOn;

  static ValueNotifier<String?> filterDocument = ValueNotifier(null);

  static bool filterNow = false;

  bool filteredAlready = false;
  bool filtered = false;

  bool assending = false;

  late List<DataColumn2> columns;

  @override
  void initState() {
    if (filterDocument.value != null) {
      startedWithFiltersOn = true;
      searchController.text = filterDocument.value!;
      ficheReceptionDatasource = FicheReceptionDatasource(
          current: context,
          selectC: widget.selectD,
          collectionID: fichesreceptionId,
          searchKey: filterDocument.value);
      filterDocument.value = null;
    } else {
      startedWithFiltersOn = false;

      ficheReceptionDatasource = FicheReceptionDatasource(
          current: context,
          collectionID: fichesreceptionId,
          selectC: widget.selectD,
          archive: widget.archive);
    }
    initColumns();
    super.initState();
  }

  int sortColumn = 0;

  void initColumns() {
    columns = [
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'num',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 0;
          assending = !assending;

          ficheReceptionDatasource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'nchassi',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 1;
          assending = !assending;

          ficheReceptionDatasource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'matricule',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 2;
          assending = !assending;

          ficheReceptionDatasource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'ordrereparation',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 3;
          assending = !assending;

          ficheReceptionDatasource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'dateentre',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 4;
          assending = !assending;

          ficheReceptionDatasource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'datesortie',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 5;
          assending = !assending;

          ficheReceptionDatasource.sort(sortColumn, assending);
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
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 6;
          assending = !assending;
          ficheReceptionDatasource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      if (widget.selectD != true)
        DataColumn2(
          label: const Text(''),
          size: ColumnSize.S,
          fixedWidth: 2.w,
          onSort: null,
        ),
    ];
  }

  int rowPerPage = 12;

  TextEditingController searchController = TextEditingController();

  bool notEmpty = false;

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    ficheReceptionDatasource.appTheme = appTheme;
    return ValueListenableBuilder(
        valueListenable: filterDocument,
        builder: (context, v, _) {
          if (!startedWithFiltersOn && v != null && filterNow) {
            searchController.text = v;
            ficheReceptionDatasource.search(v);
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
                      onChanged: (s){
                        if(s.isEmpty){
                          notEmpty=false;
                          ficheReceptionDatasource.search('');
                        }
                        else{
                          notEmpty=true;
                        }
                        setState(() {
                        });
                      },
                      controller: searchController,
                      placeholder: 'search'.tr(),


                      style: appTheme.writingStyle,
                      cursorColor: appTheme.color.darker,
                      placeholderStyle: placeStyle,
                      decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),
                      onSubmitted: (s) {
                        if (s.isNotEmpty) {
                          ficheReceptionDatasource.search(s);
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
                            ficheReceptionDatasource.search('');
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
            source: ficheReceptionDatasource,
          );
        });
  }

  @override
  void dispose() {
    ficheReceptionDatasource.dispose();
    super.dispose();
  }
}
