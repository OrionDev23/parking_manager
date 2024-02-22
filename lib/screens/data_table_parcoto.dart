import 'package:data_table_2/data_table_2.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';

import '../theme.dart';
import '../widgets/empty_table_widget.dart';

class DataTableParc extends StatefulWidget {

  final Widget? header;
  final AsyncDataTableSource source;
  final bool sortAscending;
  final int sortColumnIndex;
  final List<DataColumn2> columns;
  final bool hidePaginator;
  final int? numberOfRows;
  final bool pages;
  final double? rowHeight;
  const DataTableParc({super.key,this.rowHeight, this.header, required this
      .source, required
  this.sortAscending, required this.sortColumnIndex, required this.columns,
    this.numberOfRows,
    this.pages=true,
    this.hidePaginator=false});

  @override
  State<DataTableParc> createState() => _DataTableParcState();
}

class _DataTableParcState extends State<DataTableParc> {
  int rowPerPage = 12;

  @override
  Widget build(BuildContext context) {
    var appTheme=context.watch<AppTheme>();
    return AsyncPaginatedDataTable2(
      header: widget.header,
      sortAscending: widget.sortAscending,
      headingRowHeight: 25,
      headingRowDecoration: BoxDecoration(
          color: appTheme.color,
          borderRadius:
          const BorderRadius.vertical(top: Radius.circular(5))),
      dividerThickness: 0.5,
      autoRowsToHeight: true,
      empty: NoDataWidget(
        datasource: widget.source,
      ),
      pageSyncApproach: PageSyncApproach.goToLast,
      horizontalMargin: 8,
      columnSpacing: 0,
      dataRowHeight: widget.rowHeight==null?widget
          .numberOfRows==null?rowHeight:rowHeight*2:widget.rowHeight!,
      onPageChanged: (s) {},
      rowsPerPage: widget.numberOfRows ?? rowPerPage,
      onRowsPerPageChanged: widget.pages
          ? (nbr) {
          rowPerPage = nbr ?? 12;
      }
          : null,
      availableRowsPerPage: widget.numberOfRows == null
          ? const [12, 24, 50, 100, 200]
          : [widget.numberOfRows!],
      showCheckboxColumn: false,
      sortColumnIndex: widget.sortColumnIndex,
      showFirstLastButtons: false,
      renderEmptyRowsInTheEnd: false,
      fit: FlexFit.loose,
      columns: widget.columns,
      source: widget.source,
      sortArrowAlwaysVisible: true,
      hidePaginator: widget.hidePaginator,
    );
  }
}
