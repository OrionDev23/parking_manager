import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/datasources/backup/backup_datasource.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../theme.dart';
import '../../widgets/zone_box.dart';
import '../data_table_parcoto.dart';

class BackupTable extends StatefulWidget {
  final bool selectD;

  const BackupTable({super.key, required this.selectD});

  @override
  State<BackupTable> createState() => _BackupTableState();
}

class _BackupTableState extends State<BackupTable> {
  late BackupDataSource backupDataSource;
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
      backupDataSource = BackupDataSource(
          current: context,
          selectC: widget.selectD,
          collectionID: backupId,
          searchKey: filterDocument.value);
      filterDocument.value = null;
    } else {
      startedWithFiltersOn = false;

      backupDataSource = BackupDataSource(
          current: context,
          collectionID: backupId,
          selectC: widget.selectD,);
    }
    initColumns();
    super.initState();
  }

  int sortColumn = 0;
  double medium=150.px;

  void initColumns() {
    columns = [
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'nom',
            style: tstyle,
          ).tr(),
        ),
        fixedWidth: medium,
        onSort: (s, c) {
          sortColumn = 0;
          assending = !assending;
          backupDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'content',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 1;
          assending = !assending;

          backupDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: const Text(''),
        fixedWidth: medium*0.5,
        onSort: null,
      ),
    ];
  }
  bool notEmpty = false;
  FlyoutController filterFlyout = FlyoutController();
  DateTime dateMin = DateTime.now().subtract(const Duration(days: 31));
  DateTime dateMax = DateTime.now();
  Map<String, String> filters = {};

  final rowPerPageC = 12;
  int rowPerPage = 12;

  void showFilters(AppTheme appTheme){
    filterFlyout.showFlyout(
        builder: (context) {
          return FlyoutContent(
              color: appTheme.backGroundColor,
              child: StatefulBuilder(
                  builder: (context, setS) {
                    return SizedBox(
                      width: 400.px,
                      height: 200.px,
                      child: Column(
                        children: [
                          Flexible(
                            child: ZoneBox(
                              label: 'date'.tr(),
                              child: Padding(
                                padding:
                                const EdgeInsets
                                    .all(10.0),
                                child: Row(
                                  children: [
                                    Flexible(
                                      child:
                                      DatePicker(
                                        selected:
                                        dateMin,
                                        header: 'min'.tr(),
                                        headerStyle: placeStyle,
                                        onChanged: (s){
                                          setState(() {
                                            dateMin=DateTime(s.year,s.month,s
                                                .day,0,0,0);

                                          });
                                          setS((){});

                                        },
                                      ),
                                    ),
                                    smallSpace,
                                    Flexible(
                                      child:
                                      DatePicker(
                                        selected:
                                        dateMax,
                                        header: 'max'.tr(),
                                        headerStyle: placeStyle,
                                        onChanged: (s){
                                          setState(() {
                                            dateMax=DateTime(s.year,s.month,s
                                                .day,23,59,59);
                                          });
                                          setS((){});

                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          smallSpace,
                          smallSpace,
                          Padding(
                            padding:
                            const EdgeInsets
                                .all(8.0),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .end,
                              children: [
                                FilledButton(
                                  style:
                                  ButtonStyle(
                                    backgroundColor:
                                    WidgetStatePropertyAll<
                                        Color>(
                                        appTheme
                                            .color
                                            .lightest),
                                  ),
                                  onPressed:
                                  filtered
                                      ? () {
                                    Navigator.of(context)
                                        .pop();
                                    setState(
                                            () {
                                          filtered =
                                          false;
                                          filters.clear();
                                        });
                                    backupDataSource
                                        .filter(filters);
                                  }
                                      : null,
                                  child: const Text(
                                      'clear')
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
                                    style:
                                    ButtonStyle(
                                      backgroundColor:WidgetStatePropertyAll<
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

                                        filters['datemin'] =
                                            dateMin.difference(DatabaseGetter
                        .ref).inMilliseconds.toString();
                                        filters['datemax'] = dateMax.difference(DatabaseGetter.ref).inMilliseconds.toString();
                                      filtered =
                                      true;
                                      setState(
                                              () {});
                                      backupDataSource
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
  }

  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    backupDataSource.appTheme = appTheme;
    return ValueListenableBuilder(
        valueListenable: filterDocument,
        builder: (context, v, _) {
      if (!startedWithFiltersOn &&  filterNow && v != null ) {
        backupDataSource.filter(filters);
        notEmpty = true;
        filtered = true;
        filterNow = false;
      }
      return DataTableParc(
        horizontalScroll: false,
        header: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 5.0, horizontal: 10),
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
                              showFilters(appTheme);
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
                                borderRadius:
                                BorderRadius.circular(5),
                                boxShadow: kElevationToShadow[2],
                              ),
                              child: Text(
                                '${filters.length}',
                                style: TextStyle(fontSize: 10.sp),
                              ))),
                  ],
                ),
              ),
              smallSpace,
              bigSpace,
              IconButton(
                  icon: const Icon(FluentIcons.refresh),
                  onPressed: () {
                    backupDataSource.refreshDatasource();
                  }),
            ],
          ),
        ),
        sortAscending: assending,
        sortColumnIndex: sortColumn,
        rowHeight: 45,
        columns: columns,
        source: backupDataSource,
      );});
  }

}
