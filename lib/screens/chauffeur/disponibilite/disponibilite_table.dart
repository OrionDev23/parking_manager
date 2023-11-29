import 'package:data_table_2/data_table_2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/datasources/conducteurs/disponibilite_datasource.dart';
import 'package:parc_oto/providers/client_database.dart';
import 'package:provider/provider.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../theme.dart';
import '../../../widgets/zone_box.dart';
class DisponibliteTable extends StatefulWidget {
  final bool selectD;
  const DisponibliteTable({super.key,this.selectD=false});

  @override
  State<DisponibliteTable> createState() => DisponibliteTableState();
}

class DisponibliteTableState extends State<DisponibliteTable> {
  late DisponibiliteDataSource disponibiliteDataSource;

  bool assending = false;

  late List<DataColumn2> columns;

  @override
  void initState() {
    disponibiliteDataSource = DisponibiliteDataSource(current: context, collectionID: chaufDispID,selectC: widget.selectD);
    initColumns();
    super.initState();
  }

  final tstyle = TextStyle(
    fontSize: 10.sp,
  );

  int sortColumn = 2;

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

          disponibiliteDataSource.sort(sortColumn, assending);
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
          sortColumn = 1;
          assending = !assending;

          disponibiliteDataSource.sort(sortColumn, assending);
          setState(() {});
        },
      ),
      DataColumn2(
        label: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Text(
            'dateajout',
            style: tstyle,
          ).tr(),
        ),
        size: ColumnSize.M,
        onSort: (s, c) {
          sortColumn = 2;
          assending = !assending;

          disponibiliteDataSource.sort(sortColumn, assending);
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

  int? type;
  DateTime? dateMin;
  DateTime? dateMax;
  Map<String,String> filters={};
  @override
  Widget build(BuildContext context) {
    var appTheme = context.watch<AppTheme>();
    disponibiliteDataSource.appTheme=appTheme;
    return  AsyncPaginatedDataTable2(
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
                                                label: 'date'.tr(),
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
                                                            child: DatePicker(
                                                              selected: dateMin,
                                                              onChanged: (s){
                                                                setState(() {
                                                                  dateMin=s;
                                                                });
                                                                setS((){});

                                                              },
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
                                                            child: DatePicker(
                                                              selected: dateMax,
                                                              onChanged: (s){
                                                                setState(() {
                                                                  dateMax=s;
                                                                });
                                                                setS((){});
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
                                                label: 'disponibilite'.tr(),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(10.0),
                                                  child:  DropDownButton(
                                                    title: Text(type==null ?'':ClientDatabase.getEtat(type)).tr(),
                                                    placement: FlyoutPlacementMode.bottomLeft,
                                                    items: [
                                                      MenuFlyoutItem(text: const Text('disponible').tr(), onPressed: () {
                                                        setState(() {
                                                          type=0;
                                                        });
                                                        setS((){});

                                                      },
                                                        selected:type==0,
                                                      ),
                                                      const MenuFlyoutSeparator(),
                                                      MenuFlyoutItem(text: const Text('mission').tr(), onPressed: () {
                                                        setState(() {
                                                          type=1;
                                                        });
                                                        setS((){});

                                                      },
                                                        selected:type==1,
                                                      ),
                                                      const MenuFlyoutSeparator(),
                                                      MenuFlyoutItem(text: const Text('absent').tr(), onPressed: () {
                                                        setState(() {
                                                          type=2;
                                                        });
                                                        setS((){});

                                                      },
                                                        selected:type==2,),
                                                      const MenuFlyoutSeparator(),
                                                      MenuFlyoutItem(text: const Text('quitteentre').tr(), onPressed: () {
                                                        setState(() {
                                                          type=3;
                                                        });
                                                        setS((){});

                                                      },
                                                        selected:type==3,),
                                                    ],

                                                  ),
                                                ),
                                              ),
                                            ),
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
                                                        dateMin=null;
                                                        dateMax=null;
                                                        type=null;
                                                        filtered=false;
                                                        filters.clear();
                                                      });
                                                      disponibiliteDataSource.filter(filters);

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

                                                        if(dateMin!=null){
                                                          filters['dateMin']=dateMin!.toIso8601String();
                                                        }
                                                        else{
                                                          filters.remove('dateMin');
                                                        }
                                                        if(dateMax!=null){
                                                          filters['dateMax']=dateMax!.toIso8601String();
                                                        }
                                                        else{
                                                          filters.remove('dateMax');
                                                        }
                                                        if(type!=null){
                                                          filters['type']=type.toString();
                                                        }
                                                        else{
                                                          filters.remove('type');
                                                        }

                                                        filtered=true;
                                                        setState((){});
                                                        disponibiliteDataSource.filter(filters);

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
                      disponibiliteDataSource.search(s);
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
                        disponibiliteDataSource.search('');
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
        source: disponibiliteDataSource,
        sortArrowAlwaysVisible: true,
        hidePaginator: false,
    );
  }
  @override
  void dispose() {
    disponibiliteDataSource.dispose();
    super.dispose();
  }
}
