import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/datasources/reparation/reparation_datasource.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../theme.dart';
import '../../../../widgets/empty_table_widget.dart';
class ReparationTable extends StatefulWidget {
  final bool selectD;
  final bool archive;
  const ReparationTable({super.key,this.selectD=false,this.archive=false});

  @override
  State<ReparationTable> createState() => ReparationTableState();
}

class ReparationTableState extends State<ReparationTable> {
  late ReparationDataSource reparationDataSource;

  late final bool startedWithFiltersOn;

  static ValueNotifier<String?> filterDocument = ValueNotifier(null);


  static bool filterNow = false;

  bool filteredAlready = false;
  bool filtered = false;

  bool assending = false;

  late List<DataColumn2> columns;

  @override
  void initState() {
    if (filterDocument.value != null){
      startedWithFiltersOn = true;
      searchController.text = filterDocument.value!;
      reparationDataSource = ReparationDataSource(
          current: context,
          selectC: widget.selectD, collectionID:reparationId,
          searchKey: filterDocument.value);
      filterDocument.value=null;
    }
    else{
      startedWithFiltersOn = false;

      reparationDataSource = ReparationDataSource(current: context, collectionID: reparationId,selectC: widget.selectD,archive: widget.archive);

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
          child: const Text(
            'num',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 0;
          assending = !assending;

          reparationDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Text(
            'matricule',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 1;
          assending = !assending;

          reparationDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Text(
            'prestataire',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 2;
          assending = !assending;

          reparationDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Text(
            'date',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 3;
          assending = !assending;

          reparationDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Text(
            'montantt',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 4;
          assending = !assending;
          reparationDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: const Text(
            'dateModif',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 5;
          assending = !assending;
          reparationDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      if(widget.selectD!=true)
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
    reparationDataSource.appTheme=appTheme;
    return ValueListenableBuilder(
        valueListenable: filterDocument,
        builder: (context, v, _) {
          if (!startedWithFiltersOn && v != null && filterNow) {
            searchController.text = v;
            reparationDataSource.search(v);
            notEmpty=true;
            filtered = true;
            filterNow = false;
          }
          return AsyncPaginatedDataTable2(
            header: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 30.w,
                    height: 7.h,
                    child: TextBox(
                      controller: searchController,
                      placeholder: 'search'.tr(),
                      style: appTheme.writingStyle,
                      cursorColor: appTheme.color.darker,
                      placeholderStyle: placeStyle,
                      decoration: BoxDecoration(
                          color: appTheme.fillColor
                      ),
                      onSubmitted: (s) {
                        if (s.isNotEmpty) {
                          reparationDataSource.search(s);
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
                            reparationDataSource.search('');
                          })
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            sortAscending: assending,
            headingRowHeight: 25,
            headingRowDecoration: BoxDecoration(
                color: appTheme.color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5))
            ),
            dividerThickness: 0.5,
            autoRowsToHeight: true,

            horizontalMargin: 8,
            columnSpacing: 0,
            dataRowHeight: rowHeight,
            onPageChanged: (s) {},
            showCheckboxColumn: false,
            sortColumnIndex: sortColumn,
            rowsPerPage: rowPerPage,
            onRowsPerPageChanged: (nbr) {
              rowPerPage = nbr ?? 12;
            },
            availableRowsPerPage: const [12, 24, 50, 100, 200],
            empty: NoDataWidget(datasource: reparationDataSource,),
            showFirstLastButtons: true,
            renderEmptyRowsInTheEnd: false,
            fit: FlexFit.tight,
            columns: columns,
            source: reparationDataSource,
            sortArrowAlwaysVisible: true,
            hidePaginator: false,
          );});
  }

  @override
  void dispose() {
    reparationDataSource.dispose();
    super.dispose();
  }
}
