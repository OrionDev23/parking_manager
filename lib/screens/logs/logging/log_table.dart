import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../theme.dart';
import '../../../../widgets/zone_box.dart';
import '../../../datasources/log_activity/log_datasource.dart';
import '../../../providers/activities.dart';
import '../../../providers/client_database.dart';
import '../../data_table_parcoto.dart';

class LogTable extends StatefulWidget {
  final bool selectD;
  final bool statTable;

  final bool mobile;

  final bool pages;

  final List<String> fieldsToShow;

  final int? numberOfRows;

  final List<int>? typelist;

  final Map<String, String>? filters;

  const LogTable(
      {super.key,
        this.selectD = false,
        this.pages = true,
        this.statTable = false,
        this.filters,
        this.numberOfRows,
        this.mobile=false,
        this.typelist,
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
    if(widget.typelist!=null){
      filters['typelist']=widget.typelist!.join(',');
    }
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

  double large=250.px;
  double medium=150.px;
  double small=80.px;
  int sortColumn = 2;

  double getActWidth(){
    if(widget.mobile){
      return large;
    }
    if(widget.statTable){
      return large;
    }
    else{
      double width=80.w;
      if(widget.fieldsToShow.contains('id')) {
        width-=medium;
      }
      if(widget.fieldsToShow.contains('date')) {
        width-=medium;
      }
      if(widget.fieldsToShow.contains('user')) {
        width-=medium;
      }
      if(widget.fieldsToShow.contains('plus')) {
        width-=small;
      }
      return width;
    }

  }


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
          fixedWidth: getActWidth(),
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
          fixedWidth: medium,
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
          fixedWidth: medium,
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
          fixedWidth: medium,
          onSort: (s, c) {
            sortColumn = widget.fieldsToShow.indexOf('user');
            assending = !assending;
            logDatasource.sort(3, assending);
            setState(() {});
          },
        ),
      if (widget.fieldsToShow.contains('plus'))
        DataColumn2(
          label: Text(
            '',
          ),
          fixedWidth: small,
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
        child: SizedBox(
          width: 350.px,
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
                                Spacer(),
                                filtered
                                    ? Icon(
                                  FluentIcons.filter_solid,
                                  color: appTheme.color,
                                )
                                    : const Icon(FluentIcons.filter),
                              ],
                            ),
                            onPressed: () {
                              filterFlyout.showFlyout(builder: (con) {
                                return getFilterContent(appTheme,con);
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
              Spacer(),
              Flexible(
                child: SizedBox(
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
                    decoration: WidgetStatePropertyAll(BoxDecoration(color: appTheme.fillColor)),
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
              ),
            ],
          ),
        ),
      )
          : null,
      horizontalScroll: true,
      numberOfRows: widget.numberOfRows,
      pages: widget.pages,
      sortAscending: assending,
      sortColumnIndex: sortColumn,
      columns: columns,
      source: logDatasource..filter(filters),
      hidePaginator: !widget.pages,
    );
  }



  Widget getFilterContent(AppTheme appTheme,BuildContext context){
    return FlyoutContent(
        color: appTheme.backGroundColor,
        child: StatefulBuilder(
            builder: (context, setS) {
              return SizedBox(
                width: 340.px,
                height: widget.typelist!=null?200.px:276.px,
                child: Column(
                  children: [
                    SizedBox(
                      height: 110.px,
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
                                      width: 30.px,
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
                                      width: 30.px,
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
                    if(widget.typelist==null)
                      SizedBox(
                        height: 90.px,
                        child: ZoneBox(
                          label: 'activity'.tr(),
                          child: Padding(
                              padding:
                              const EdgeInsets
                                  .all(10.0),
                              child: DropDownButton(
                                  closeAfterClick:
                                  true,
                                  title: SizedBox(
                                    width: 250.px,
                                    child: Text(type ==
                                        null
                                        ? '/'
                                        : DatabaseGetter()
                                        .getActivityType(
                                        type!)
                                        .tr(),overflow: TextOverflow.ellipsis,),
                                  ),
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
                                      activityList.length,
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
                    if(widget.typelist==null)
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
  }

  @override
  void dispose() {
    logDatasource.dispose();
    super.dispose();
  }
}
