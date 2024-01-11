import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';

import 'package:parc_oto/datasources/log_activity/log_datasource.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../theme.dart';
import '../../../../widgets/empty_table_widget.dart';
import '../../../../widgets/zone_box.dart';

class LogTable extends StatefulWidget {
  final bool selectD;
  final bool? statTable;

  final List<String> fieldsToShow;

  final int? numberOfRows;

  final Map<String, String>? filters;
  const LogTable(
      {super.key,
      this.selectD = false,
      this.statTable = false,
      this.filters,
        this.numberOfRows,
      this.fieldsToShow = const ['act', 'id', 'date', 'plus']});

  @override
  State<LogTable> createState() => LogTableState();
}

class LogTableState extends State<LogTable> {
  late LogDatasource logDatasource;

  bool assending = false;

  late List<DataColumn2> columns;

  @override
  void initState() {
    sortColumn=widget.fieldsToShow.length>=2?2:widget.fieldsToShow.length-1;
    logDatasource = LogDatasource(
        current: context,
        collectionID: activityId,
        sortAscending: assending,
        sortColumn: sortColumn,
        selectC: widget.selectD,
        fieldsToShow: widget.fieldsToShow,
        filters: widget.filters);
    initColumns();
    super.initState();
  }

  final tstyle = TextStyle(
    fontSize: 10.sp,
  );

  int sortColumn = 2;

  void initColumns() {
    columns = [
      if (widget.fieldsToShow.contains('act'))
        DataColumn2(
          label: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Text(
              'activity',
              style: tstyle,
            ).tr(),
          ),
          size: ColumnSize.L,
          onSort: (s, c) {
            sortColumn = 0;
            assending = !assending;
            logDatasource.sort(sortColumn, assending);
            setState(() {});
          },
        ),
      if (widget.fieldsToShow.contains('id'))
        DataColumn2(
          label: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Text(
              'ID',
              style: tstyle,
            ).tr(),
          ),
          size: ColumnSize.L,
          onSort: (s, c) {
            sortColumn = widget.fieldsToShow.contains('act') ? 1 : 0;
            assending = !assending;
            logDatasource.sort(1, assending);
            setState(() {});
          },
        ),
      if (widget.fieldsToShow.contains('date'))
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
            sortColumn = widget.fieldsToShow.contains('act') &&
                    widget.fieldsToShow.contains('id')
                ? 2
                : !widget.fieldsToShow.contains('act') &&
                        !widget.fieldsToShow.contains('id')
                    ? 0
                    : 1;
            assending = !assending;
            logDatasource.sort(2, assending);
            setState(() {});
          },
        ),
      if (widget.fieldsToShow.contains('plus'))
        const DataColumn2(
          label: Text(
            '',
          ),
          size: ColumnSize.S,
          onSort: null,
        ),
    ];
  }

  int rowPerPage = 12;

  TextEditingController searchController = TextEditingController();

  bool notEmpty = false;
  bool filtered = false;

  FlyoutController filterFlyout = FlyoutController();
  DateTime? dateMin;
  DateTime? dateMax;
  int? type;
  Map<String, String> filters = {};
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    logDatasource.appTheme = appTheme;
    return AsyncPaginatedDataTable2(
      header: widget.statTable == false
          ? Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 75.px,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: FlyoutTarget(
                            controller: filterFlyout,
                            child: IconButton(
                                icon: Row(
                                  children: [
                                    Text(
                                      'filter',
                                      style: TextStyle(fontSize: 12.sp),
                                    ).tr(),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    filtered
                                        ? Icon(
                                            FluentIcons.filter_solid,
                                            color: appTheme.color,
                                          )
                                        : const Icon(FluentIcons.filter),
                                  ],
                                ),
                                onPressed: () {
                                  filterFlyout.showFlyout(builder: (context) {
                                    return FlyoutContent(
                                        color: appTheme.backGroundColor,
                                        child: StatefulBuilder(
                                            builder: (context, setS) {
                                          return SizedBox(
                                            width: 30.w,
                                            height: 42.h,
                                            child: Column(
                                              children: [
                                                Flexible(
                                                  child: ZoneBox(
                                                    label: 'date'.tr(),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10.0),
                                                      child: Column(
                                                        children: [
                                                          Row(
                                                            children: [
                                                              SizedBox(
                                                                  width: 5.w,
                                                                  child: const Text(
                                                                          'min')
                                                                      .tr()),
                                                              smallSpace,
                                                              smallSpace,
                                                              Flexible(
                                                                child:
                                                                    DatePicker(
                                                                  selected:
                                                                      dateMin,
                                                                  endDate:
                                                                      dateMax,
                                                                  onChanged:
                                                                      (d) {
                                                                    dateMin = d;
                                                                    setState(
                                                                        () {});
                                                                    setS(() {});
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          smallSpace,
                                                          Row(
                                                            children: [
                                                              SizedBox(
                                                                  width: 5.w,
                                                                  child: const Text(
                                                                          'max')
                                                                      .tr()),
                                                              smallSpace,
                                                              smallSpace,
                                                              Flexible(
                                                                child:
                                                                    DatePicker(
                                                                  selected:
                                                                      dateMax,
                                                                  startDate:
                                                                      dateMin,
                                                                  onChanged:
                                                                      (d) {
                                                                    dateMax = d;
                                                                    setState(
                                                                        () {});
                                                                    setS(() {});
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                smallSpace,
                                                Flexible(
                                                  child: ZoneBox(
                                                    label: 'activity'.tr(),
                                                    child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(10.0),
                                                        child: DropDownButton(
                                                            closeAfterClick:
                                                                false,
                                                            title: Text(type ==
                                                                    null
                                                                ? '/'
                                                                : ClientDatabase()
                                                                    .getActivityType(
                                                                        type!)
                                                                    .tr()),
                                                            trailing: type ==
                                                                    null
                                                                ? const Icon(
                                                                    FluentIcons
                                                                        .caret_down8)
                                                                : IconButton(
                                                                    icon: Icon(
                                                                      FluentIcons
                                                                          .cancel,
                                                                      color: Colors
                                                                          .red,
                                                                    ),
                                                                    onPressed:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        type =
                                                                            null;
                                                                      });
                                                                      setS(
                                                                          () {});
                                                                    }),
                                                            items:
                                                                List.generate(
                                                                    35,
                                                                    (index) {
                                                              return MenuFlyoutItem(
                                                                  text: Text(ClientDatabase()
                                                                          .getActivityType(
                                                                              index))
                                                                      .tr(),
                                                                  onPressed:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      type =
                                                                          index;
                                                                    });
                                                                    setS(() {});
                                                                  });
                                                            }))),
                                                  ),
                                                ),
                                                smallSpace,
                                                smallSpace,
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.all(8.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment.end,
                                                    children: [
                                                      FilledButton(
                                                        style: ButtonStyle(
                                                          backgroundColor:
                                                              ButtonState.all<
                                                                      Color>(
                                                                  appTheme.color
                                                                      .lightest),
                                                        ),
                                                        onPressed: filtered
                                                            ? () {
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                                setState(() {
                                                                  dateMax =
                                                                      null;
                                                                  dateMin =
                                                                      null;
                                                                  type = null;
                                                                  filtered =
                                                                      false;
                                                                  filters
                                                                      .clear();
                                                                });
                                                                logDatasource
                                                                    .filter(
                                                                        filters);
                                                              }
                                                            : null,
                                                        child:
                                                            const Text('clear')
                                                                .tr(),
                                                      ),
                                                      const Spacer(),
                                                      Button(
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                          child: const Text(
                                                                  'annuler')
                                                              .tr()),
                                                      smallSpace,
                                                      smallSpace,
                                                      FilledButton(
                                                          style: ButtonStyle(
                                                            backgroundColor:
                                                                ButtonState.all<
                                                                        Color>(
                                                                    appTheme
                                                                        .color
                                                                        .lighter),
                                                          ),
                                                          child: const Text(
                                                                  'confirmer')
                                                              .tr(),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();

                                                            if (dateMin !=
                                                                null) {
                                                              filters['datemin'] = dateMin!
                                                                  .difference(
                                                                      ClientDatabase
                                                                          .ref)
                                                                  .inMilliseconds
                                                                  .toString();
                                                            } else {
                                                              filters.remove(
                                                                  'datemin');
                                                            }
                                                            if (dateMax !=
                                                                null) {
                                                              filters['datemax'] = dateMax!
                                                                  .difference(
                                                                      ClientDatabase
                                                                          .ref)
                                                                  .inMilliseconds
                                                                  .toString();
                                                            } else {
                                                              filters.remove(
                                                                  'datemax');
                                                            }
                                                            if (type != null) {
                                                              filters['type'] =
                                                                  type!
                                                                      .toString();
                                                            } else {
                                                              filters.remove(
                                                                  'type');
                                                            }

                                                            filtered = true;
                                                            setState(() {});
                                                            logDatasource
                                                                .filter(
                                                                    filters);
                                                          }),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }));
                                  });
                                }),
                          ),
                        ),
                        if (filtered)
                          Positioned(
                              bottom: 10,
                              right: 0,
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 2, horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: appTheme.color,
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: kElevationToShadow[2],
                                  ),
                                  child: Text(
                                    '${filters.length}',
                                    style: TextStyle(fontSize: 10.sp),
                                  ))),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  SizedBox(
                    width: 30.w,
                    height: 7.h,
                    child: TextBox(
                      controller: searchController,
                      placeholder: 'search'.tr(),
                      style: appTheme.writingStyle,
                      cursorColor: appTheme.color.darker,
                      placeholderStyle: placeStyle,
                      decoration: BoxDecoration(color: appTheme.fillColor),
                      onSubmitted: (s) {
                        if (s.isNotEmpty) {
                          logDatasource.search(s);
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
                                logDatasource.search('');
                              })
                          : null,
                    ),
                  ),
                ],
              ),
            )
          : null,
      sortAscending: assending,
      empty: NoDataWidget(
        datasource: logDatasource,
      ),
      horizontalMargin: 4,
      columnSpacing: 0,
      dataRowHeight: widget.numberOfRows==null?rowHeight:rowHeight*2,
      onPageChanged: (s) {},
      showCheckboxColumn: false,
      sortColumnIndex: sortColumn,
      rowsPerPage: widget.numberOfRows??rowPerPage,
      onRowsPerPageChanged: (nbr) {
        rowPerPage = nbr ?? 12;
      },
      availableRowsPerPage: widget.numberOfRows==null?const [12, 24, 50, 100, 200]:[
        widget.numberOfRows!
      ],
      showFirstLastButtons: true,
      renderEmptyRowsInTheEnd: false,
      fit: FlexFit.tight,
      columns: columns,
      source: logDatasource,
      sortArrowAlwaysVisible: true,
      hidePaginator: false,
    );
  }

  @override
  void dispose() {
    logDatasource.dispose();
    super.dispose();
  }
}
