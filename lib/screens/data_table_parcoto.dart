import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../theme.dart';
import '../widgets/empty_table_widget.dart';

/// Shared data-grid surface used by every Parcoto module.
///
/// Module screens keep ownership of their columns, data sources, filtering and
/// business actions. This widget centralizes the table's visual language and
/// common pagination behaviour so a visual change is applied everywhere.
class DataTableParc extends StatefulWidget {
  final Widget? header;
  final AsyncDataTableSource source;
  final bool sortAscending;
  final bool autoRowHeight;
  final int sortColumnIndex;
  final List<DataColumn2> columns;
  final bool hidePaginator;
  final int? numberOfRows;
  final bool pages;
  final double? rowHeight;
  final bool horizontalScroll;

  const DataTableParc({
    super.key,
    this.rowHeight,
    this.header,
    required this.source,
    required this.sortAscending,
    required this.sortColumnIndex,
    required this.columns,
    this.numberOfRows,
    this.horizontalScroll = false,
    this.pages = true,
    this.hidePaginator = false,
    this.autoRowHeight = true,
  });

  @override
  State<DataTableParc> createState() => _DataTableParcState();
}

class _DataTableParcState extends State<DataTableParc> {
  int rowPerPage = 12;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    final accent = appTheme.color;
    final isDark = appTheme.mode == ThemeMode.dark;
    final borderColor = appTheme.writingStyle.color!.withValues(alpha: .10);

    return Container(
      decoration: BoxDecoration(
        color: appTheme.backGroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? .12 : .035),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: AsyncPaginatedDataTable2(
          header: widget.header,
          sortAscending: widget.sortAscending,
          headingRowHeight: 44,
          minWidth: widget.horizontalScroll ? 2000.px : null,
          isHorizontalScrollBarVisible: widget.horizontalScroll,
          headingRowDecoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: isDark ? .24 : .13),
                accent.withValues(alpha: isDark ? .12 : .07),
              ],
              begin: AlignmentDirectional.centerStart,
              end: AlignmentDirectional.centerEnd,
            ),
            border: Border(
              bottom: BorderSide(
                color: accent.withValues(alpha: .24),
                width: 1,
              ),
            ),
          ),
          headingTextStyle: TextStyle(
            color: appTheme.writingStyle.color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: .25,
          ),
          dataTextStyle: TextStyle(
            color: appTheme.writingStyle.color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          border: TableBorder(
            horizontalInside: BorderSide(color: borderColor, width: .6),
          ),
          dividerThickness: .4,
          autoRowsToHeight: widget.autoRowHeight,
          empty: NoDataWidget(datasource: widget.source),
          pageSyncApproach: PageSyncApproach.goToLast,
          horizontalMargin: 16,
          columnSpacing: 14,
          dataRowHeight: widget.autoRowHeight
              ? kMinInteractiveDimension
              : widget.rowHeight ??
                    (widget.numberOfRows == null ? rowHeight : rowHeight * 2),
          onPageChanged: (_) {},
          rowsPerPage: widget.numberOfRows ?? rowPerPage,
          onRowsPerPageChanged: widget.pages
              ? (count) {
                  setState(() => rowPerPage = count ?? 12);
                }
              : null,
          availableRowsPerPage: widget.numberOfRows == null
              ? const [12, 24, 50, 100, 200]
              : [widget.numberOfRows!],
          showCheckboxColumn: false,
          sortColumnIndex: widget.sortColumnIndex,
          showFirstLastButtons: true,
          renderEmptyRowsInTheEnd: false,
          fit: FlexFit.loose,
          columns: widget.columns,
          source: widget.source,
          sortArrowAlwaysVisible: true,
          hidePaginator: widget.hidePaginator,
        ),
      ),
    );
  }
}
