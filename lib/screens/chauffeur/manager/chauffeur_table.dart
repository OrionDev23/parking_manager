import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/services.dart';
import 'package:parc_oto/datasources/conducteurs/conducteur_datasource.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../theme.dart';
import '../../../widgets/zone_box.dart';
class ChauffeurTable extends StatefulWidget {
  final bool selectD;
  final bool archive;
  const ChauffeurTable({super.key,this.selectD=false,this.archive=false});

  @override
  State<ChauffeurTable> createState() => ChauffeurTableState();
}

class ChauffeurTableState extends State<ChauffeurTable> {
  late ConducteurDataSource conducteurDataSource;

  bool assending = false;

  late List<DataColumn2> columns;

  @override
  void initState() {
    conducteurDataSource = ConducteurDataSource(current: context, collectionID: chauffeurid,selectC: widget.selectD,archive: widget.archive);
    initColumns();
    super.initState();
  }

  final tstyle = TextStyle(
    fontSize: 10.sp,
  );

  int sortColumn = 4;

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
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 0;
          assending = !assending;

          conducteurDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'email',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.L,
        onSort: (s, c) {
          sortColumn = 1;
          assending = !assending;

          conducteurDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'telephone',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 2;
          assending = !assending;

          conducteurDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'disponibilite',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 3;
          assending = !assending;

          conducteurDataSource.sort(6, assending);
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
          sortColumn = 4;
          assending = !assending;
          conducteurDataSource.sort(5, assending);
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

  int rowPerPage = 12;

  TextEditingController searchController = TextEditingController();

  bool notEmpty = false;
  bool filtered = false;

  FlyoutController filterFlyout = FlyoutController();
  TextEditingController ageMin=TextEditingController();
  TextEditingController ageMax=TextEditingController();
  Map<String,String> filters={};
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    conducteurDataSource.appTheme=appTheme;
    return AsyncPaginatedDataTable2(
      header: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10),
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
                              Text('filter',style: TextStyle(fontSize: 12.sp),).tr(),
                              const SizedBox(width: 5,),
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
                                  child:
                                  StatefulBuilder(builder: (context, setS) {
                                    return SizedBox(
                                      width: 30.w,
                                      height: 42.h,
                                      child: Column(
                                        children: [
                                          Flexible(
                                            child: ZoneBox(
                                              label: 'age'.tr(),
                                              child: Padding(
                                                padding: const EdgeInsets.all(10.0),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      children: [
                                                        SizedBox(
                                                            width:5.w,
                                                            child: const Text('min').tr()),
                                                        smallSpace,
                                                        smallSpace,
                                                        Flexible(
                                                          child: TextBox(
                                                            controller: ageMin,
                                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    smallSpace,
                                                    Row(
                                                      children: [
                                                        SizedBox(
                                                            width:5.w,
                                                            child: const Text('max').tr()),
                                                        smallSpace,
                                                        smallSpace,
                                                        Flexible(
                                                          child: TextBox(
                                                            controller: ageMax,
                                                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                                          smallSpace,
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                FilledButton(
                                                  style:ButtonStyle(
                                                    backgroundColor: ButtonState.all<Color>(
                                                        appTheme.color.lightest
                                                    ),
                                                  ),
                                                  onPressed: filtered?(){

                                                    Navigator.of(context).pop();
                                                    setState(() {
                                                      ageMax.clear();
                                                      ageMin.clear();
                                                      filtered=false;
                                                      filters.clear();
                                                    });
                                                    conducteurDataSource.filter(filters);

                                                  }
                                                      :null,child: const Text('clear').tr(),
                                                ),
                                                const Spacer(),
                                                Button(
                                                    onPressed:(){
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: const Text('annuler').tr()),
                                                smallSpace,


                                                smallSpace,

                                                FilledButton(
                                                    style:ButtonStyle(
                                                      backgroundColor: ButtonState.all<Color>(
                                                          appTheme.color.lighter
                                                      ),
                                                    ),
                                                    child: const Text('confirmer').tr(),
                                                    onPressed: (){
                                                      Navigator.of(context).pop();

                                                      if(ageMin.text.isNotEmpty){
                                                        filters['agemin']=ageMin.text;
                                                      }
                                                      else{
                                                        filters.remove('agemin');
                                                      }
                                                      if(ageMax.text.isNotEmpty){
                                                        filters['ageMax']=ageMax.text;
                                                      }
                                                      else{
                                                        filters.remove('ageMax');
                                                      }

                                                      filtered=true;
                                                      setState((){});
                                                      conducteurDataSource.filter(filters);

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
                decoration: BoxDecoration(
                    color: appTheme.fillColor
                ),
                onSubmitted: (s) {
                  if (s.isNotEmpty) {
                    conducteurDataSource.search(s);
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
                      conducteurDataSource.search('');
                    })
                    : null,
              ),
            ),
          ],
        ),
      ),
      sortAscending: assending,
      horizontalMargin: 8,
      columnSpacing: 0,
      dataRowHeight: 3.5.h,
      onPageChanged: (s) {},
      showCheckboxColumn: false,
      sortColumnIndex: sortColumn,
      rowsPerPage: rowPerPage,
      onRowsPerPageChanged: (nbr) {
        rowPerPage = nbr ?? 12;
      },
      availableRowsPerPage: const [12, 24, 50, 100, 200],
      showFirstLastButtons: true,
      renderEmptyRowsInTheEnd: false,
      fit: FlexFit.tight,
      columns: columns,
      source: conducteurDataSource,
      sortArrowAlwaysVisible: true,
      hidePaginator: false,
    );
  }

  @override
  void dispose() {
    conducteurDataSource.dispose();
    super.dispose();
  }
}
