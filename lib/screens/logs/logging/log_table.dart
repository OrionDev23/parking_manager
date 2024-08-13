import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/datasources/log_activity/log_datasource.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../theme.dart';
import '../../../../widgets/zone_box.dart';
import '../../data_table_parcoto.dart';

class LogTable extends StatefulWidget {
  final bool selectD;
  final bool? statTable;

  final bool pages;

  final List<String> fieldsToShow;

  final int? numberOfRows;

  final Map<String, String>? filters;

  const LogTable(
      {super.key,
      this.selectD = false,
      this.pages = true,
      this.statTable = false,
      this.filters,
      this.numberOfRows,
      this.fieldsToShow = const [
        'act',
        'id',
        'date',
        'user',
        'plus',
      ]});

  @override
  State<LogTable> createState() => LogTableState();
}

class LogTableState extends State<LogTable> {
  late LogDatasource logDatasource;

  bool assending = false;

  late List<DataColumn2> columns;

  @override
  void initState() {
    sortColumn = widget.fieldsToShow.indexOf('date');
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
            sortColumn = widget.fieldsToShow.indexOf('id');
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
              'date',
              style: tstyle,
            ).tr(),
          ),
          size: ColumnSize.L,
          onSort: (s, c) {
            sortColumn = widget.fieldsToShow.indexOf('date');
            assending = !assending;
            logDatasource.sort(2, assending);
            setState(() {});
          },
        ),
      if (widget.fieldsToShow.contains('user') && DatabaseGetter().isAdmin())
        DataColumn2(
          label: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5.0),
            child: Text(
              'user',
              style: tstyle,
            ).tr(),
          ),
          size: ColumnSize.L,
          onSort: (s, c) {
            sortColumn = widget.fieldsToShow.indexOf('user');
            assending = !assending;
            logDatasource.sort(3, assending);
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
    return DataTableParc(
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
                                                                  onChanged:
                                                                      (s) {
                                                                    dateMin = DateTime(
                                                                        s.year,
                                                                        s.month,
                                                                        s.day,
                                                                        0,
                                                                        0,
                                                                        0);
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
                                                                  onChanged:
                                                                      (s) {
                                                                    dateMax = DateTime(
                                                                        s.year,
                                                                        s.month,
                                                                        s.day,
                                                                        23,
                                                                        59,
                                                                        59);
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
                                                                : DatabaseGetter()
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
                                                                  text: Text(DatabaseGetter()
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
                                                          WidgetStatePropertyAll<
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
                                                            WidgetStatePropertyAll<
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
                                                              filters['datemin'] = dateMin!.toIso8601String();
                                                            } else {
                                                              filters.remove(
                                                                  'datemin');
                                                            }
                                                            if (dateMax !=
                                                                null) {
                                                              filters['datemax'] = dateMax!.toIso8601String();
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
                    width: 350.px,
                    height: 45.px,
                    child: TextBox(
                      onChanged: (s) {
                        if (s.isEmpty) {
                          notEmpty = false;
                          logDatasource.search('');
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
      numberOfRows: widget.numberOfRows,
      pages: widget.pages,
      sortAscending: assending,
      sortColumnIndex: sortColumn,
      columns: columns,
      source: logDatasource,
      hidePaginator: !widget.pages,
    );
  }

  @override
  void dispose() {
    logDatasource.dispose();
    super.dispose();
  }
}
