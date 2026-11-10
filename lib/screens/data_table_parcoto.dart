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
    // GTS has two explicit palettes (gtsDark / gtsLight), represented by
    // AppTheme.mode. Use AppTheme's resolved colors instead of guessing from
    // Fluent's inherited brightness or introducing a separate table palette.
    final isDark = appTheme.mode == ThemeMode.dark;
    final accent = appTheme.color;
    final surfaceColor = appTheme.surfaceColor;
    final primaryText = appTheme.writingStyle.color ??
        (isDark ? Colors.white : Colors.black);
    final secondaryText = appTheme.mutedTextColor;
    final borderColor = appTheme.borderColor;

    // DataTable2 inherits the application-wide Material theme. Explicit row
    // fills prevent the package's default light row from clashing with dark text.
    final materialTheme = appTheme.materialTheme;

    return Theme(
      data: materialTheme,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(appTheme.tableRadius),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? .22 : .045),
              blurRadius: appTheme.palette.shadowBlur,
              offset: Offset(0, appTheme.palette.shadowBlur / 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(appTheme.tableRadius),
          child: AsyncPaginatedDataTable2(
            header: widget.header,
            sortAscending: widget.sortAscending,
            headingRowHeight: 48,
            minWidth: widget.horizontalScroll ? 2000.px : null,
            isHorizontalScrollBarVisible: widget.horizontalScroll,
            dataRowColor: WidgetStatePropertyAll(surfaceColor),
            headingRowDecoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: appTheme.palette.headerAccentOpacity),
                  accent.withValues(alpha: appTheme.palette.headerAccentOpacity * .45),
                ],
                begin: AlignmentDirectional.centerStart,
                end: AlignmentDirectional.centerEnd,
              ),
              border: Border(
                bottom: BorderSide(
                  color: accent.withValues(alpha: isDark ? .42 : .30),
                  width: 1,
                ),
              ),
            ),
            headingTextStyle: TextStyle(
              color: primaryText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: .3,
            ),
            dataTextStyle: TextStyle(
              color: primaryText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            border: TableBorder(
              horizontalInside: BorderSide(
                color: borderColor.withValues(alpha: isDark ? .85 : 1),
                width: .7,
              ),
            ),
            dividerThickness: .4,
            autoRowsToHeight: widget.autoRowHeight,
            empty: NoDataWidget(datasource: widget.source),
            pageSyncApproach: PageSyncApproach.goToLast,
            horizontalMargin: 18,
            columnSpacing: 16,
            dataRowHeight: widget.autoRowHeight
                ? kMinInteractiveDimension
                : widget.rowHeight ??
                      (widget.numberOfRows == null ? rowHeight : rowHeight * 2),
            onPageChanged: (_) {},
            rowsPerPage: widget.numberOfRows ?? rowPerPage,
            onRowsPerPageChanged: widget.pages
                ? (count) {
                    // data_table_2 may normalize rowsPerPage while building.
                    // Defer our state update to avoid setState during build.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      final nextCount = count ?? 12;
                      if (rowPerPage != nextCount) {
                        setState(() => rowPerPage = nextCount);
                      }
                    });
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
      ),
    );
  }
}
